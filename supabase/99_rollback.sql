-- ============================================================
-- 緊急ロールバック：RLSを一旦無効化して元の動作（匿名アクセス）に戻す
-- ※セキュリティは下がります。アプリが使えなくなった等の緊急時のみ。
-- Supabase SQL Editor で実行。
-- ============================================================
alter table public.ponds                  disable row level security;
alter table public.feed_logs              disable row level security;
alter table public.move_logs              disable row level security;
alter table public.orders                 disable row level security;
alter table public.shipments              disable row level security;
alter table public.settings               disable row level security;
alter table public.inventory_adjustments  disable row level security;
alter table public.profiles               disable row level security;
notify pgrst, 'reload schema';
