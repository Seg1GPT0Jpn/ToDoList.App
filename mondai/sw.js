// オフラインでも使えるようにするための Service Worker。
// - 同じサイトのファイル：まずネットから取り（新しい版がすぐ届く）、つながらないときは保存した版を使う
// - CDN のライブラリ（KaTeX・JSZip・supabase-js。URL に版が入っている）：保存した版を使い、なければネットから取って保存
// - そのほか（Supabase・AI の通信など）：何もしない
// PRECACHE は scripts/update-sw.mjs で作る（tests/unit/sw.test.js で実際のファイルと一致を確認）
const CACHE = 'mondai-v1';
const CDN_HOSTS = ['cdnjs.cloudflare.com', 'cdn.jsdelivr.net'];
const PRECACHE = [
  "./",
  "index.html",
  "manifest.webmanifest",
  "builtin/hs.json",
  "builtin/jh.json",
  "css/app.css",
  "css/paper.css",
  "icons/apple-touch-icon.png",
  "icons/favicon-32.png",
  "icons/icon-192.png",
  "icons/icon-512.png",
  "icons/icon-maskable-512.png",
  "icons/icon-maskable.svg",
  "icons/icon.svg",
  "js/ai/client.js",
  "js/cloud/supabase.js",
  "js/core/backup.js",
  "js/core/db.js",
  "js/core/migrate.js",
  "js/core/store.js",
  "js/core/util.js",
  "js/data/units.js",
  "js/domain/answersheet.js",
  "js/domain/csv.js",
  "js/domain/exam.js",
  "js/domain/figure.js",
  "js/domain/format.js",
  "js/domain/material.js",
  "js/domain/mathcheck.js",
  "js/domain/question.js",
  "js/domain/search.js",
  "js/domain/similarity.js",
  "js/domain/variant.js",
  "js/importer.js",
  "js/main.js",
  "js/pwa.js",
  "js/render.js",
  "js/render/material.js",
  "js/ui/analytics.js",
  "js/ui/answers.js",
  "js/ui/bank.js",
  "js/ui/common.js",
  "js/ui/drawing.js",
  "js/ui/editor.js",
  "js/ui/exam.js",
  "js/ui/home.js",
  "js/ui/library.js",
  "js/ui/qeditor.js",
  "js/ui/settings.js",
  "js/ui/studio.js",
  "js/ui/team.js",
  "js/unit-groups.js",
  "js/unit-names.js",
];

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    // 1つ失敗しても残りは保存する（オフライン対応は「できる範囲で」）
    await Promise.all(PRECACHE.map(u => cache.add(new Request(u, { cache: 'reload' })).catch(() => {})));
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    for (const k of await caches.keys()) if (k.startsWith('mondai-') && k !== CACHE) await caches.delete(k);
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin === self.location.origin) {
    if (!url.pathname.startsWith(new URL('./', self.location).pathname)) return;
    event.respondWith(networkFirst(req));
  } else if (CDN_HOSTS.includes(url.hostname)) {
    event.respondWith(cacheFirst(req));
  }
});

async function networkFirst(req) {
  const cache = await caches.open(CACHE);
  try {
    const res = await fetch(req);
    if (res.ok && res.type === 'basic') cache.put(req, res.clone());
    return res;
  } catch (e) {
    const hit = await cache.match(req, { ignoreSearch: true });
    if (hit) return hit;
    // 画面の読み込み（#/… の URL）は index.html を返す
    if (req.mode === 'navigate') {
      const index = await cache.match('index.html') || await cache.match('./');
      if (index) return index;
    }
    throw e;
  }
}

async function cacheFirst(req) {
  const cache = await caches.open(CACHE);
  const hit = await cache.match(req);
  if (hit) return hit;
  const res = await fetch(req);
  if (res.ok || res.type === 'opaque') cache.put(req, res.clone());
  return res;
}
