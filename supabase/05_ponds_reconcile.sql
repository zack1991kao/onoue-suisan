-- 05_ponds_reconcile.sql
-- 魚群リスト_.xlsx（2026-06-26）と ponds の差分の最終解消。
-- 【6/26 打ち合わせで社長が証言】「瀬後の浦-09 → 太喜-08 へ魚を移動した。でも瀬後09が赤いまま」。
--   → DBが正しい（魚は太喜-08=マダイ12,300）。瀬後の浦-09 を「空き」にすればよい。
--   → 移動で在庫0→自動で空き化する処理はアプリ側(saveMove)に実装済み。以後は自動。
-- Supabase SQL Editor で実行（superuser権限＝RLSをバイパス）。

-- 1) 瀬後の浦-09：移動済みで空 → 空き(skip)に統一（赤→グレー）
update public.ponds
   set species='', stock=0, status='skip', yr=null, updated_at=now()
 where id='瀬後の浦-09';

-- 2) 空きいけすに年魚が残存していたら掃除（団地-16 など）
update public.ponds
   set yr=null
 where status='skip' and yr is not null;

-- 確認：太喜-08 に魚がいて、瀬後の浦-09 が空きになっていること
select id, species, stock, status, yr
  from public.ponds
 where id in ('太喜-08','瀬後の浦-09')
 order by id;
