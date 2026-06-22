# Sprint 2 手順書：Supabase Auth + RLS（Isaac作業）

この手順は **尾上水産の売上・出荷金額・設定を「管理者だけ」に確実に守る** ための作業です。
所要 約30分。プログラミング不要、画面のクリックとコピペだけです。

> ⚠️ 重要：**手順4でRLSを有効化した瞬間から、ログインしていないアクセスは全て拒否されます。**
> なので「先にアカウントを作る(手順2)」「フロントをAuth対応にする(手順5)」を済ませてから手順4を実行します。
> 順番を守れば、現場のスタッフが使えなくなる時間はほぼゼロです。

プロジェクト: `ssrbmvbcrqrvvgytpirv`

---

## 手順1. ログイン方式を有効化（メール/パスワード）
1. メール認証設定を開く：
   https://supabase.com/dashboard/project/ssrbmvbcrqrvvgytpirv/auth/providers
2. **「Email」** を開き、**Enable** がオンになっていることを確認。
3. （任意・おすすめ）現場スマホで毎回メール確認リンクを踏むのは手間なので、
   **「Confirm email」をオフ**にする（社内利用前提なら可）。オンのままだと初回にメール確認が必要。

## 手順2. スタッフのアカウントを作成（10人弱）
1. ユーザー管理を開く：
   https://supabase.com/dashboard/project/ssrbmvbcrqrvvgytpirv/auth/users
2. 右上 **「Add user」→「Create new user」**。
3. 各スタッフの **メールアドレス** と **初期パスワード** を入力して作成。
   （メールが無いスタッフ用に `tanchi@onoue.local` のような社内用メールでも可）
4. 全員分くり返す。**作成したメール/パスワードを一覧でメモ**しておく（後で配布）。

## 手順3. セキュリティSQLを実行
1. SQL Editor を開く：
   https://supabase.com/dashboard/project/ssrbmvbcrqrvvgytpirv/sql/new
2. リポジトリの **`deploy/supabase/01_security_migration.sql`** の中身を全部コピーして貼り付け、**Run**。
   - これで「ロール表」「在庫修正履歴テーブル」「RLSポリシー」が一括で入ります。
3. **経営者・家族を管理者に昇格**。SQL Editor で下記を実行（メールは実際のものに置換）：
   ```sql
   update public.profiles set role='admin' where email='オーナーのメール@example.com';
   -- 家族分も同様に追加実行
   ```
4. 確認：
   ```sql
   select email, role from public.profiles order by role;
   ```
   → 管理者にしたい人が `admin`、他が `staff` になっていればOK。

## 手順4. （まだ実行しない）RLS有効化のスイッチ
- **`01_security_migration.sql` の中に RLS有効化も含まれています**。手順3を実行した時点でRLSは有効になります。
- そのため、**手順5（フロントのAuth対応）を先に反映してから手順3を実行**してください。
  - もし「先に手順3を実行してしまってアプリが真っ白／データが出ない」場合は、
    フロントがまだ匿名アクセスのままなのが原因。手順5を反映すれば直ります。
  - 緊急で元に戻したいときは `99_rollback.sql` を実行（RLSを一旦無効化）。

## 手順5. フロントのログインをSupabase Authに切替（Claude側で実施）
- これは **Claude（私）がコードを実装** します。Isaacの作業は「手順2でアカウント作成済み」であることだけ。
- 実装後、ログイン画面が **メールアドレス + パスワード** に変わり、
  Supabaseのセッション（自動更新）でPWAでもログインが保持されます。
- 管理者でログインすると売上・出荷金額・設定が見え、スタッフでは見えません（DB層で強制）。

## 手順6. 動作確認
1. スタッフのメール/パスワードでログイン → 給餌・移動・在庫が使える。出荷/売上/設定は見えない。
2. 管理者でログイン → 出荷金額・設定・元帳が見える。
3. （技術確認・任意）ログアウト状態で売上を盗れないこと：
   ターミナルで匿名キーを使って出荷を取得しようとして **0件/拒否** になればRLS成功。

---

## 配布用：スタッフへの連絡文（例）
> 尾上水産アプリのログインが新しくなりました。
> URL: （スマホ）https://zack1991kao.github.io/onoue-suisan/app.html
> ログイン: あなたのメールアドレスと、お渡ししたパスワードでログインしてください。

---

## 退職者が出たとき
- ユーザー管理画面 https://supabase.com/dashboard/project/ssrbmvbcrqrvvgytpirv/auth/users
  で該当ユーザーを **Delete**（または無効化）すれば、その人はログインできなくなります。
