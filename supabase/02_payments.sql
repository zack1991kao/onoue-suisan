-- ============================================================
-- 尾上水産 入金確認機能 SQL（Supabase SQL Editor で実行）
-- 目的: payments テーブル新設 + shipments に消込カラム + 管理者限定RLS
-- 前提: 01_security_migration.sql 実行済み（is_admin() が存在すること）
-- 実行は service_role（SQL Editor既定）で。
-- ============================================================

-- 1) 入金テーブル
create table if not exists public.payments (
  id          bigint generated always as identity primary key,
  shipment_id bigint references public.shipments(id),  -- どの出荷に対する入金か
  pay_date    date,            -- 入金日
  buyer       text,            -- 業者名
  amount      numeric,         -- 入金額
  method      text,            -- 入金方法（振込/現金 等、任意）
  memo        text,
  created_at  timestamptz not null default now()
);

-- 2) shipments に消込用カラム
alter table public.shipments add column if not exists paid        boolean default false;  -- 入金済みフラグ
alter table public.shipments add column if not exists paid_amount numeric default 0;      -- 入金済み金額（累計）

-- 3) RLS（payments は売上同様、管理者のみ）
alter table public.payments enable row level security;
drop policy if exists payments_admin on public.payments;
create policy payments_admin on public.payments
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

grant select, insert, update, delete on public.payments to authenticated;
grant usage, select on all sequences in schema public to authenticated;

-- 4) リアルタイム購読対象に追加（既に追加済みならエラーは無視してOK）
alter publication supabase_realtime add table public.payments;

-- 5) スキーマキャッシュ再読込
notify pgrst, 'reload schema';

-- ※ shipments は 01 で既に admin限定RLS（shipments_admin）が付いているため、
--   追加カラム paid/paid_amount も自動的に管理者のみアクセス可。
