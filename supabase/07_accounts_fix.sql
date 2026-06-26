-- 07_accounts_fix.sql  （Supabase SQL Editor に全文貼り付け→Run）
-- 実アカウントは kanri01〜03（管理者）/ staff01〜08（スタッフ）の2桁形式だった。
--  ・06で私が作った余分な staff1〜staff5 を削除
--  ・実アカウントのパスワードを「onoue+4桁PIN」に統一（＝アプリのPINログインで入れる）
--  ・氏名メモを設定
--
-- ★編集するのは下の values(...) の「PIN」と「氏名」だけ★（PINは各人の好きな4桁に）
-- ※このSQLは既存パスワードを上書きします。実行後は新しいPINでログインしてください。

create extension if not exists pgcrypto;

-- 0) 余分なダミーを削除（profiles/identities は連鎖削除）
delete from auth.users
 where email in ('staff1@onoue.local','staff2@onoue.local','staff3@onoue.local',
                 'staff4@onoue.local','staff5@onoue.local');

-- 1) 実アカウントのPIN（パスワード）と氏名を設定
do $$
declare rec record;
begin
  for rec in
    select * from (values
      --  アカウント , PIN(4桁) , 氏名（メモ）
      ('kanri01' , '1221' , '尾上 洸一朗' ),
      ('kanri02' , '1222' , '管理者2'     ),
      ('kanri03' , '1223' , '管理者3'     ),
      ('staff01' , '0101' , 'スタッフ01'  ),
      ('staff02' , '0102' , 'スタッフ02'  ),
      ('staff03' , '0103' , 'スタッフ03'  ),
      ('staff04' , '0104' , 'スタッフ04'  ),
      ('staff05' , '0105' , 'スタッフ05'  ),
      ('staff06' , '0106' , 'スタッフ06'  ),
      ('staff07' , '0107' , 'スタッフ07'  ),
      ('staff08' , '0108' , 'スタッフ08'  )
      -- ↑ PIN・氏名を実際の値に変えるだけ
    ) as t(acct, pin, name)
  loop
    update auth.users
       set encrypted_password = crypt('onoue'||rec.pin, gen_salt('bf')),
           updated_at = now()
     where email = rec.acct||'@onoue.local';
    update public.profiles
       set name = rec.name
     where email = rec.acct||'@onoue.local';
  end loop;
end $$;

notify pgrst, 'reload schema';

-- 2) 確認（kanri→staff の順、氏名・権限・有効）
select email, name, role, active from public.profiles
 order by email;

-- ───────────────────────────────────────────────
-- 【ログイン方法（実アカウント）】
--   ・スタッフ：ID＝番号（例「1」→staff01）／PIN＝上で設定した4桁
--   ・管理者　：ID＝「kanri1」等（→kanri01）／PIN＝上で設定した4桁
-- ───────────────────────────────────────────────
