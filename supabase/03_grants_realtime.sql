-- ============================================================
-- 尾上水産 追補マイグレーション 03（Supabase SQL Editor で実行）
-- 目的:
--   (A) SQLで新規作成したテーブル(inventory_adjustments / profiles)への GRANT 付与
--       ※Supabaseの仕様変更により、SQL作成テーブルはAPIに自動公開されない。
--         RLSだけでは不足で、authenticated への GRANT が無いと 42501(permission denied) になる。
--   (B) shipments を Realtime購読対象(publication)へ追加（別端末の入金消込を即時反映）
-- 前提: 01_security_migration.sql / 02_payments.sql 実行済み。
-- 実行は service_role（SQL Editor既定）で。何度実行しても安全（冪等）。
-- 参考: Supabase Docs「Securing your API（Grants と RLS は別レイヤー）」
--       Breaking Change: Tables not exposed to Data API automatically
-- ============================================================

-- ── (A) GRANT（テーブル到達権限。行の可否は各テーブルのRLSが判定）──

-- 在庫修正履歴（01で作成）：ログイン中ユーザーが読み書き（RLSで is_active() 等が判定）
grant select, insert, update, delete on public.inventory_adjustments to authenticated;

-- プロフィール（01で作成）：自分の行を読めれば十分（applyRoleがrole参照）。
-- 行制限は profiles_self_read ポリシー（id = auth.uid()）が担う。書込はトリガ/管理者のみ。
grant select on public.profiles to authenticated;

-- identity列のシーケンス（inventory_adjustments等のinsertに必要）
grant usage, select on all sequences in schema public to authenticated;

-- ── (B) Realtime publication に shipments を追加（payments は02で追加済み）──
-- 既にメンバーだと "is already member of publication" エラーになるため存在チェックして追加。
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'shipments'
  ) then
    execute 'alter publication supabase_realtime add table public.shipments';
  end if;
end $$;

-- 念のため payments も（02未適用環境で03だけ流しても効くように）
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'payments'
  ) then
    execute 'alter publication supabase_realtime add table public.payments';
  end if;
end $$;

-- ── スキーマキャッシュ再読込 ──
notify pgrst, 'reload schema';

-- 確認用（任意）：
--   select tablename from pg_publication_tables
--   where pubname='supabase_realtime' and schemaname='public' order by 1;
--   -- shipments / payments / ponds / orders 等が並べばOK
