-- 06_accounts.sql  （Supabase SQL Editor に全文貼り付け→Run）
-- 6/26 社長要望：ログインは「ID（番号）＋4桁PIN」。内部変換は
--   ID「1」→ メール staff1@onoue.local ／ PIN「1234」→ パスワード onoue1234
--
-- ★編集するのは下の「values(...)」の表だけ★ 番号・PIN・氏名・管理者かを人数分並べる。
-- 既に作成済みのアカウントは自動スキップ（何度実行してもOK）。

create extension if not exists pgcrypto;

-- 1) 表示名メモ列を profiles に追加
alter table public.profiles add column if not exists name text;

-- 2) スタッフ／管理者アカウントを一括作成＋氏名・権限を設定
do $$
declare
  rec record;
  v_id uuid;
begin
  for rec in
    select * from (values
      --  番号 ,  PIN  ,  氏名（メモ）   , 管理者か
      ( 1 , '1221' , '尾上 洸一朗' , true  ),
      ( 2 , '0002' , 'スタッフ2'   , false ),
      ( 3 , '0003' , 'スタッフ3'   , false ),
      ( 4 , '0004' , 'スタッフ4'   , false ),
      ( 5 , '0005' , 'スタッフ5'   , false )
      -- ↑ 行を増やす／番号・PIN・氏名・管理者(true/false)を変えるだけ
    ) as t(no, pin, name, is_admin)
  loop
    select id into v_id from auth.users where email = 'staff'||rec.no||'@onoue.local';
    if v_id is null then
      v_id := gen_random_uuid();
      insert into auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, created_at, updated_at,
        confirmation_token, recovery_token, email_change, email_change_token_new,
        raw_app_meta_data, raw_user_meta_data
      ) values (
        '00000000-0000-0000-0000-000000000000', v_id, 'authenticated', 'authenticated',
        'staff'||rec.no||'@onoue.local', crypt('onoue'||rec.pin, gen_salt('bf')),
        now(), now(), now(),
        '', '', '', '',
        '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb
      );
      insert into auth.identities (
        provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at
      ) values (
        'staff'||rec.no||'@onoue.local', v_id,
        json_build_object('sub', v_id::text, 'email', 'staff'||rec.no||'@onoue.local', 'email_verified', true),
        'email', now(), now(), now()
      );
    end if;
    -- profiles（トリガで自動作成済み）の氏名・権限・有効を設定
    update public.profiles
       set name   = rec.name,
           role   = case when rec.is_admin then 'admin' else 'staff' end,
           active = true
     where id = v_id;
  end loop;
end $$;

-- 3) スキーマキャッシュ再読込
notify pgrst, 'reload schema';

-- 4) 確認（番号順に出ます）
select email, name, role, active from public.profiles order by email;

-- ───────────────────────────────────────────────
-- 【ログイン方法】アプリの画面で：ID=番号（例「1」）／PIN=4桁（例「1221」）
-- 【もしエラーが出たら】Supabaseの版差で auth.users/identities の列が違う場合があります。
--   その時は Dashboard → Authentication → Add user で
--   Email: staff1@onoue.local ／ Password: onoue1221 ／ Auto Confirm User: ON
--   を人数分作成し、上の do$$ ブロックを飛ばして alter/select だけ実行してください。
-- ───────────────────────────────────────────────
