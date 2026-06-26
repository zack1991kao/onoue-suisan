-- 05_ponds_reconcile.sql （確認専用・破壊的更新なし）
-- 魚群リスト_.xlsx（2026-06-26）と ponds の差分は既にほぼ解消済み。
-- DBには魚種・年魚が反映済みで、在庫はその後の給餌/出荷で正しく増減している。
-- ブランケット上書き（旧 05_seed）は done状態や実減算を巻き戻すため廃止。
-- 残る要確認（人による判断が必要なものだけ）を可視化する。

-- 1) 12,300尾の所在違い（移動記録の食い違い）：太喜-08 ⇄ 瀬後の浦-09
--    DB: 太喜-08=マダイ12300 / 瀬後の浦-09=0  ・  リスト: 太喜-08=空 / 瀬後の浦-09=12300
select id, species, stock, status, yr
from public.ponds
where id in ('太喜-08','瀬後の浦-09');

-- 2) 空きいけすに年魚が残存（軽微なデータごみ）：団地-16
select id, species, stock, status, yr
from public.ponds
where status = 'skip' and yr is not null;

-- ↑1 の判断後に、正しい側へ手動更新してください（例：瀬後の浦-09 に移動が正なら）
-- update public.ponds set species='マダイ', stock=12300, status='todo', yr=2, updated_at=now() where id='瀬後の浦-09';
-- update public.ponds set species='',       stock=0,     status='skip', yr=null, updated_at=now() where id='太喜-08';

-- ↓2 のデータごみ掃除（安全）：
-- update public.ponds set yr=null where status='skip';
