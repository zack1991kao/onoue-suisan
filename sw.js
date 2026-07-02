// 尾上水産 PWA Service Worker
// 方針: 静的UIファイルはキャッシュ優先（オフラインでもシェル表示）
//       Supabase / CDN などの通信はネットワーク優先（常に最新データ）

var CACHE_NAME = 'onoue-shell-v37';
var SHELL_FILES = [
  './',
  './index.html',
  './app.html',
  './admin.html',
  './staff.html',
  './manifest.webmanifest',
  './icon-192.png',
  './icon-512.png',
  './logo.png'
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

  var isShell = url.origin === self.location.origin;
  if (isShell) {
    // HTML/ナビゲーションは「ネットワーク優先」＝最新コードを常に取得（オフライン時のみキャッシュ）。
    // これによりリロードで毎回最新版が読まれ、端末間のコード差（カレンダー不一致等）が起きない。
    var isHtml = req.mode === 'navigate'
      || url.pathname === '/' || url.pathname.endsWith('/')
      || url.pathname.endsWith('.html');
    if (isHtml) {
      e.respondWith(
        fetch(req).then(function(res) {
          if (res && res.status === 200) {
            var clone = res.clone();
            caches.open(CACHE_NAME).then(function(c) { c.put(req, clone); });
          }
          return res;
        }).catch(function() {
          return caches.match(req).then(function(cached) {
            return cached || caches.match('./index.html');
          });
        })
      );
      return;
    }
    // アイコン/manifest等の静的資産はキャッシュ優先（高速・オフライン対応）
    e.respondWith(
      caches.match(req).then(function(cached) {
        return cached || fetch(req).then(function(res) {
          if (res && res.status === 200) {
            var clone = res.clone();
            caches.open(CACHE_NAME).then(function(c) { c.put(req, clone); });
          }
          return res;
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
