# 海水温ウィジェット（テレメーター連携）デプロイ手順

天草テレメーター（熊本県海水養殖組合）の公開CSVを、Supabase Edge Function
`water-temp` がサーバー側で取得・解析し、ダッシュボードの「🌡 海水温」カードに
最新水温を常時表示します。

## なぜEdge Functionが必要か
- CSVはパスワード不要で公開されているが、`Access-Control-Allow-Origin` が無く、
  ブラウザ（GitHub Pages）から直接 fetch するとCORSでブロックされる。
- Edge Function（サーバー側）が代わりに取得し、CORS許可付きJSONで返すことで解決。
- 未デプロイでもアプリは壊れず、カードはテレメーターへのリンク表示にフォールバックする。

## デプロイ（Isaac作業・1回）
前提：Supabase CLI 導入済み（`npm i -g supabase` など）、`supabase login` 済み。

```bash
cd deploy/supabase           # supabase/ ディレクトリ（functions/water-temp/index.ts がある場所）
supabase link --project-ref ssrbmvbcrqrvvgytpirv      # 初回のみ
supabase functions deploy water-temp --no-verify-jwt   # 公開水温データのため認証不要で公開
```

確認：
```
curl "https://ssrbmvbcrqrvvgytpirv.supabase.co/functions/v1/water-temp?loc=yokoshima_1.5"
# {"loc":"yokoshima_1.5","latest":{"t":"2026/06/26 .. ..","temp":24.3,...},"trend":[...]} が返ればOK
```

デプロイ後、ダッシュボードを再読込すると「🌡 海水温」に現在水温が表示されます。

## 地点（loc）一覧
横島: `yokoshima_1.5` / `yokoshima_5` / `yokoshima_10`
大道: `oodou_1.5` / `oodou_5` / `oodou_10`
嵐口: `arakuchi1.5m` / `arakuchi5m` / `arakuchi10m`
大平島: `oohirashima_1.5` ほか　深海: `hukami_1.5m` ほか
（カードのセレクタで横島1.5m/横島5m/大道1.5m/大平島1.5m/深海1.5mを切替可能。
 地点を増やす場合は admin.html の #wtLoc の option を追加）

## 補足
- 30分毎更新のデータ。カードはダッシュボード表示時に取得（必要なら定期更新も追加可）。
- テレメーターのパスワード(1221)は当CSV取得には不要だった（ページ閲覧用途と思われる）。
