-- 08_entered_by_move_uid.sql  （Supabase SQL Editor に全文貼り付け→Run。何度実行してもOK）
-- 2026-10-06 Isaac GO
-- 1) 給餌の記録に「入力した人」を自動で残す（アプリ側の変更なし。ログイン中のメールが入る）
-- 2) 移動の記録に端末で作る一意ID（client_uid）を持たせ、通信が弱い時の再送で二重にならないようにする
-- 既存の行・既存の列には触れない（列の追加と索引だけ）。

-- 1) feed_logs.entered_by：追加時にログイン中のメール（例 staff1@onoue.local）を自動で入れる
alter table public.feed_logs add column if not exists entered_by text;
alter table public.feed_logs alter column entered_by set default (auth.jwt() ->> 'email');

-- 2) move_logs.client_uid：同じIDは1件だけ（空のままの古い行は対象外）
alter table public.move_logs add column if not exists client_uid text;
create unique index if not exists move_logs_client_uid_key
  on public.move_logs (client_uid) where client_uid is not null;

-- 確認用（結果に2行出ればOK）
select table_name, column_name, column_default
from information_schema.columns
where table_schema = 'public'
  and ((table_name = 'feed_logs' and column_name = 'entered_by')
    or (table_name = 'move_logs' and column_name = 'client_uid'));
