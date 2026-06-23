// 尾上水産 PWA Service Worker
// 方針: 静的UIファイルはキャッシュ優先（オフラインでもシェル表示）
//       Supabase / CDN などの通信はネットワーク優先（常に最新データ）

var CACHE_NAME = 'onoue-shell-v9';
var SHELL_FILES = [
  './',
  './index.html',
  './app.html',
  './admin.html',
  './staff.html',
  './manifest.webmanifest',
  './icon-192.png',
  './icon-512.png'
];

// インストール: シェルをキャッシュ
self.addEventListener('install', function(e) {
  e.waitUntil(
    caches.open(CACHE_NAME).then(function(cache) {
      return cache.addAll(SHELL_FILES);
    }).then(function() { return self.skipWaiting(); })
  );
});

// 有効化: 古いキャッシュを削除
self.addEventListener('activate', function(e) {
  e.waitUntil(
    caches.keys().then(function(keys) {
      return Promise.all(keys.map(function(k) {
        if (k !== CACHE_NAME) return caches.delete(k);
      }));
    }).then(function() { return self.clients.claim(); })
  );
});

// フェッチ
self.addEventListener('fetch', function(e) {
  var req = e.request;
  if (req.method !== 'GET') return;

  var url = new URL(req.url);

  // 同一オリジンのHTML/アイコン/manifest → キャッシュ優先（オフライン対応）
  var isShell = url.origin === self.location.origin;
  if (isShell) {
    e.respondWith(
      caches.match(req).then(function(cached) {
        if (cached) {
          // バックグラウンドで更新（stale-while-revalidate）
          fetch(req).then(function(res) {
            if (res && res.status === 200) {
              caches.open(CACHE_NAME).then(function(c) { c.put(req, res.clone()); });
            }
          }).catch(function() {});
          return cached;
        }
        return fetch(req).then(function(res) {
          if (res && res.status === 200) {
            var clone = res.clone();
            caches.open(CACHE_NAME).then(function(c) { c.put(req, clone); });
          }
          return res;
        }).catch(function() {
          // HTMLナビゲーション失敗時は index にフォールバック
          if (req.mode === 'navigate') return caches.match('./index.html');
        });
      })
    );
    return;
  }

  // 外部（Supabase / CDN）→ ネットワーク優先、失敗時のみキャッシュ
  e.respondWith(
    fetch(req).catch(function() { return caches.match(req); })
  );
});
