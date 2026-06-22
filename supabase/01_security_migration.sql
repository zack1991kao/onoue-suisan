-- ============================================================
-- 尾上水産 Sprint2 セキュリティ移行 SQL（Supabase SQL Editor で実行）
-- 目的: RLS有効化 + ロール(staff/admin) + 売上/出荷金額の管理者限定
-- 前提: Supabase Auth でメール/パスワードのユーザーを作成済みであること
-- 実行は「service_role（SQL Editor既定）」で。anon では実行不可。
-- ============================================================

-- 0) 在庫修正履歴テーブル（無ければ作成）
create table if not exists public.inventory_adjustments (
  id          bigint generated always as identity primary key,
  pond_id     text not null,
  before_qty  integer,
  after_qty   integer,
  reason      text,
  memo        text,
  user_email  text,
  created_at  timestamptz not null default now()
);

-- 1) プロフィール（ロール保持）テーブル
--    role は 'staff' か 'admin'。既定は staff。admin は後でIsaacがUPDATEで付与。
create table if not exists public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  email      text,
  role       text not null default 'staff',   -- 'staff' か 'admin'
  active     boolean not null default true,    -- false にすると即ログイン後アクセス不可（退職者の無効化用）
  created_at timestamptz not null default now()
);
-- 既存 profiles に active 列が無い場合に追加（再実行時の互換）
alter table public.profiles add column if not exists active boolean not null default true;

-- 新規 auth ユーザー作成時に profiles を自動作成するトリガ
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, role)
  values (new.id, new.email, 'staff')
  on conflict (id) do nothing;
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 既に作成済みのユーザーを profiles に取り込む（初回のみ）
insert into public.profiles (id, email, role)
select id, email, 'staff' from auth.users
on conflict (id) do nothing;

-- 有効ユーザー判定（active=true のログイン済みユーザーか）
create or replace function public.is_active()
returns boolean language sql stable security definer set search_path = public as $$
  select exists(
    select 1 from public.profiles p
    where p.id = auth.uid() and p.active = true
  );
$$;

-- 管理者判定ヘルパー（RLSポリシーから呼ぶ。無効化された管理者は不可）
create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists(
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin' and p.active = true
  );
$$;

-- 2) RLS 有効化
alter table public.ponds                  enable row level security;
alter table public.feed_logs              enable row level security;
alter table public.move_logs              enable row level security;
alter table public.orders                 enable row level security;
alter table public.shipments              enable row level security;
alter table public.settings               enable row level security;
alter table public.inventory_adjustments  enable row level security;
alter table public.profiles               enable row level security;

-- 3) ポリシー
-- 運用データ（現場業務）: ログイン済みなら読み書き可
-- ponds
drop policy if exists ponds_rw on public.ponds;
create policy ponds_rw on public.ponds
  for all to authenticated using (public.is_active()) with check (public.is_active());
-- feed_logs
drop policy if exists feed_logs_rw on public.feed_logs;
create policy feed_logs_rw on public.feed_logs
  for all to authenticated using (public.is_active()) with check (public.is_active());
-- move_logs
drop policy if exists move_logs_rw on public.move_logs;
create policy move_logs_rw on public.move_logs
  for all to authenticated using (public.is_active()) with check (public.is_active());
-- orders（受注は現場でも入力する）
drop policy if exists orders_rw on public.orders;
create policy orders_rw on public.orders
  for all to authenticated using (public.is_active()) with check (public.is_active());
-- inventory_adjustments
drop policy if exists inv_adj_rw on public.inventory_adjustments;
create policy inv_adj_rw on public.inventory_adjustments
  for all to authenticated using (public.is_active()) with check (public.is_active());

-- 機微データ（管理者のみ）: 出荷（金額あり）・設定
-- shipments（price/amount を含むため管理者限定）
drop policy if exists shipments_admin on public.shipments;
create policy shipments_admin on public.shipments
  for all to authenticated using (public.is_admin()) with check (public.is_admin());
-- settings
drop policy if exists settings_admin on public.settings;
create policy settings_admin on public.settings
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- profiles: 本人は自分の行を読める／管理者は全件読める
drop policy if exists profiles_self_read on public.profiles;
create policy profiles_self_read on public.profiles
  for select to authenticated using (id = auth.uid() or public.is_admin());
-- ロール変更は管理者のみ（または Supabase ダッシュボードで service_role 実行）
drop policy if exists profiles_admin_write on public.profiles;
create policy profiles_admin_write on public.profiles
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- 4) スキーマキャッシュ再読込
notify pgrst, 'reload schema';

-- ============================================================
-- 実行後にやること（Isaac）:
--   ・経営層アカウントをまとめて管理者にする（kanri で始まるメール）:
--       update public.profiles set role='admin' where email like 'kanri%@onoue.local';
--   ・個別に管理者化する場合:
--       update public.profiles set role='admin' where email='オーナーのメール';
--   ・退職者などを無効化（削除せずログイン後アクセス不可にする）:
--       update public.profiles set active=false where email='退職者のメール';
--   ・確認:
--       select email, role, active from public.profiles order by role, email;
-- ============================================================
