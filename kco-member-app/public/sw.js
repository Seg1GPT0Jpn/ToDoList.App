/*
 * かながわコネクトオーケストラ 団員アプリ  サービスワーカー（プッシュ通知の表示だけを行う）
 * 通知の中身は運営が送ったタイトル・本文・アプリ内のリンクだけです。
 */
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', event => event.waitUntil(self.clients.claim()));

self.addEventListener('push', event => {
  let payload = {};
  try {
    payload = event.data ? event.data.json() : {};
  } catch (e) {
    payload = {};
  }
  const data = payload.data || {};
  const n = payload.notification || {};
  const title = data.title || n.title || 'かながわコネクトオーケストラ';
  const body = data.body || n.body || '';
  const url = typeof data.url === 'string' && data.url.charAt(0) === '/' ? data.url : '/';
  event.waitUntil(
    self.registration.showNotification(title, {
      body,
      icon: '/icon-192.png',
      badge: '/icon-192.png',
      tag: data.tag || undefined,
      data: { url }
    })
  );
});

self.addEventListener('notificationclick', event => {
  event.notification.close();
  const path = (event.notification.data && event.notification.data.url) || '/';
  const target = new URL(path, self.location.origin).href;
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(list => {
      for (const client of list) {
        if (client.url.indexOf(self.location.origin) === 0 && 'focus' in client) {
          client.navigate(target).catch(() => undefined);
          return client.focus();
        }
      }
      return self.clients.openWindow(target);
    })
  );
});
