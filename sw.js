// 旧アドレスの Service Worker を片付けるだけ（2026-10-20 アプリは https://onoue-suisan.vercel.app/ へ移動）
// 消すのはこのアプリの置き場（onoue-shell-*）だけ。同じアドレスの別のページの置き場には触らない
self.addEventListener('install', function(){ self.skipWaiting(); });
self.addEventListener('activate', function(e){
  e.waitUntil(
    caches.keys().then(function(ks){
      return Promise.all(ks.filter(function(k){ return k.indexOf('onoue-shell-') === 0; })
                           .map(function(k){ return caches.delete(k); }));
    }).then(function(){ return self.registration.unregister(); })
  );
});
