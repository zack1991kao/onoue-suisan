-- 06_accounts.sql
-- 6/26 社長要望：毎日のログインを簡単に → 画面は「ID（番号）＋4桁PIN」。
--   内部変換： ID「1」  → メール staff1@onoue.local
--             PIN「1234」→ パスワード onoue1234（Supabaseの最小6文字を満たすため接頭辞onoue）
-- このSQLは Supabase SQL Editor（service_role）で実行してください。

-- 1) 表示名メモ列を profiles に追加（アカウント管理画面の「表示名」）
alter table public.profiles add column if not exists name text;

-- 2) スタッフPINアカウントの作成
--    pgcrypto を使い、PIN付きパスワードでauth.usersに登録（profilesはトリガで自動作成）。
--    ※ {N} と {PIN} を実際の値に変えて、人数分くり返す。PINは4桁数字。
create extension if not exists pgcrypto;

do $$
declare
  v_id uuid := gen_random_uuid();
  v_email text := 'staff1@onoue.local';   -- ← 番号 N を変える
  v_pass  text := 'onoue1234';            -- ← onoue + 4桁PIN
begin
  if not exists (select 1 from auth.users where email = v_email) then
    insert into auth.users
      (instance_id, id, aud, role, email, encrypted_password,
       email_confirmed_at, created_at, updated_at,
       raw_app_meta_data, raw_user_meta_data)
    values
      ('00000000-0000-0000-0000-000000000000', v_id, 'authenticated', 'authenticated',
       v_email, crypt(v_pass, gen_salt('bf')),
       now(), now(), now(),
       '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb);
  end if;
end $$;
-- → 上の do$$ ブロックを、staff2 / staff3 ... と v_email・v_pass を変えてくり返す。

-- 3) 経営層（社長・家族）を管理者にする。番号や氏名で対象を指定。
--    例：staff1 を管理者にする
-- update public.profiles set role='admin' where email='staff1@onoue.local';

-- 4) 表示名（氏名メモ）の設定（アプリのアカウント管理画面からも可）
-- update public.profiles set name='尾上 洸一朗' where email='staff1@onoue.local';

-- 5) 退職者の無効化（削除せずアクセス不可に）
-- update public.profiles set active=false where email='staffN@onoue.local';

-- 6) 確認
select email, name, role, active from public.profiles order by email;

-- スキーマキャッシュ再読込
notify pgrst, 'reload schema';
