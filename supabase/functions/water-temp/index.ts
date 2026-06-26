// Supabase Edge Function: water-temp
// 天草テレメーター（熊本県海水養殖組合 観測データ）の公開CSVをサーバー側で取得・解析し、
// 最新水温と直近トレンドをJSONで返す。ブラウザはCORSで直接取得できないためサーバー側で代行。
//
// デプロイ:
//   supabase functions deploy water-temp --no-verify-jwt
// 呼び出し:
//   GET {SUPABASE_URL}/functions/v1/water-temp?loc=yokoshima_1.5
//
// loc の例（末尾に "now.csv" を付けて当月CSVを取得）:
//   yokoshima_1.5 / yokoshima_5 / yokoshima_10（横島）
//   oodou_1.5 / oodou_5 / oodou_10（大道）
//   arakuchi1.5m / arakuchi5m / arakuchi10m（嵐口）
//   oohirashima_1.5 / hukami_1.5m（大平島 / 深海）

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const BASE = "https://telemeter-area.jp/amakusa/csv/";
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  const url = new URL(req.url);
  const loc = (url.searchParams.get("loc") || "yokoshima_1.5").replace(/[^a-zA-Z0-9_.]/g, "");
  // CSVを取得して水温行(列index3が水温)を配列化
  async function readCsv(suffix: string) {
    const res = await fetch(`${BASE}${loc}${suffix}`, { headers: { "User-Agent": "onoue-suisan/1.0" } });
    if (!res.ok) throw new Error("csv status " + res.status);
    const buf = await res.arrayBuffer();
    let text: string;
    try { text = new TextDecoder("shift_jis").decode(buf); }
    catch { text = new TextDecoder("utf-8").decode(buf); }
    const lines = text.trim().split(/\r?\n/).slice(1).filter((l) => l.trim());
    return lines
      .map((l) => { const c = l.split(","); return { t: c[0], temp: parseFloat(c[3]), sal: parseFloat(c[4]) }; })
      .filter((r) => !isNaN(r.temp));
  }
  try {
    // 当月(now)を優先。空（停止中のセンサー等）なら通年ファイルにフォールバックして最後の値を返す
    let rows = await readCsv("now.csv");
    let stale = false;
    if (!rows.length) {
      try { const hist = await readCsv(".csv"); if (hist.length) { rows = hist; stale = true; } } catch (_) { /* noop */ }
    }
    const latest = rows.length ? rows[rows.length - 1] : null;
    const trend = rows.slice(-48).map((r) => r.temp); // 直近24時間（30分×48）
    return new Response(JSON.stringify({ loc, latest, trend, count: rows.length, stale }), {
      headers: { ...CORS, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 502,
      headers: { ...CORS, "Content-Type": "application/json" },
    });
  }
});
