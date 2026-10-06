-- 【廃止】06_accounts.sql（2026-10-06）
-- 古い形式（staff1@…）でアカウントを作るSQLだったため、中身を削除した。
-- 今のアプリは staff01 / kanri01 形式。PINの変更・氏名の設定は 07_accounts_fix.sql を使う。
-- 実行しても、下の1行で止まり何も変わらない。以前の内容が必要な時は git の履歴を見る。
do $$ begin raise exception '06_accounts.sql は廃止です。07_accounts_fix.sql を使ってください'; end $$;
