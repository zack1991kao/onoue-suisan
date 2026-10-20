// 旧アドレスの Service Worker を片付けるだけ（2026-10-20 アプリは https://onoue-suisan.vercel.app/ へ移動）
self.addEventListener('install', function(){ self.skipWaiting(); });
self.addEventListener('activate', function(e){
  e.waitUntil(
    caches.keys().then(function(ks){ return Promise.all(ks.map(function(k){ return caches.delete(k); })); })
      .then(function(){ return self.registration.unregister(); })
  );
});
