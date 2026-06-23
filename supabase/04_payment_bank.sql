-- ============================================================
-- 尾上水産 追補マイグレーション 04（Supabase SQL Editor で実行）
-- 目的: 入金(payments)に「入金先口座コード(bank)」列を追加。
--       会計CSVの入金仕訳の借方を口座別（111現金/131〜135各銀行）に出し分けるため。
--       会計担当(堤様)のご指摘：入金の借方は口座ごとに区分が必要。
-- 前提: 02_payments.sql 実行済み（payments テーブルが存在すること）。
-- 実行は service_role（SQL Editor既定）で。何度実行しても安全（冪等）。
-- ※未実行でも入金機能は動作します（borrow列が無い間は既定の肥後銀行134で出力）。
-- ============================================================

alter table public.payments add column if not exists bank text;  -- 借方口座コード（111/131/132/133/134/135）

-- スキーマキャッシュ再読込
notify pgrst, 'reload schema';

-- 確認用（任意）：
--   select id, pay_date, buyer, amount, method, bank from public.payments order by id desc limit 20;
