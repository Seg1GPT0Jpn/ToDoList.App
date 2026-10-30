// つづりクエストLight の Service Worker：一度開いたら、次からはネットがなくても起動できるようにする。
//
// - アプリ本体（プログラム・描画エンジン・フォントなど）は、版ごとの入れ物に入れて、そこから出す。
//   公開するたびに VERSION が変わる（deploy-web.yml がビルドの中身から決めて書きかえる）。
//   新しい版は裏で入り、次に開いたときに切りかわる（index.html）。
// - 単語帳・問題などのファイル（assets/packages/）は、版をまたいで残す入れ物に入れる。
//   まず手元のものを出し、ネットにつながっていれば裏で新しいかを確かめる（変わっていなければほとんど通信しない）。
// - ほかのサイト（Firebase など）には手を出さない。
const VERSION = '__TSUZURI_LIGHT_VERSION__';
const SHELL = 'light-shell-' + VERSION;
const DATA = 'light-data-v1';
const SCOPE = self.registration.scope;
const DATA_PREFIX = SCOPE + 'assets/packages/';

// 起動に必ず使うもの（入れるときに先に読んでおく）
const CORE = [
  '',
  'flutter_bootstrap.js',
  'manifest.json',
  'favicon.png',
  'assets/FontManifest.json',
  'assets/fonts/MaterialIcons-Regular.otf',
  'assets/assets/fonts/NotoSansJP-Regular.ttf',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(SHELL).then((c) => c.addAll(CORE.map((p) => SCOPE + p))).then(() => {
      // はじめて入れるときは、すぐ使いはじめる（ほかの版が動いていないので）
      if (!self.registration.active) return self.skipWaiting();
    }),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => Promise.all(
      keys.filter((k) => k.startsWith('light-shell-') && k !== SHELL).map((k) => caches.delete(k)),
    )).then(() => self.clients.claim()),
  );
});

self.addEventListener('message', (event) => {
  const m = event.data;
  // 前に開いたときに入った新しい版へ切りかえる（index.html が起動のはじめに送る）
  if (m === 'skipWaiting') self.skipWaiting();
  // はじめて開いたとき（まだ Service Worker を通っていない）に読んだファイルを入れておく
  if (m && Array.isArray(m.loaded)) {
    event.waitUntil(Promise.all(m.loaded.map((u) => remember(u))));
  }
});

function inScope(url) {
  return url.startsWith(SCOPE);
}

function bucket(url) {
  return url.startsWith(DATA_PREFIX) ? DATA : SHELL;
}

async function remember(url) {
  if (typeof url !== 'string' || !inScope(url)) return;
  const key = url.split('#')[0];
  const cache = await caches.open(bucket(key));
  if (await cache.match(key)) return;
  try {
    const res = await fetch(key);
    if (res.ok) await cache.put(key, res);
  } catch (_) {}
}

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET' || !inScope(req.url)) return;
  if (req.mode === 'navigate') {
    event.respondWith(page(req));
  } else if (req.url.startsWith(DATA_PREFIX)) {
    event.respondWith(data(req, event));
  } else {
    event.respondWith(shell(req));
  }
});

// 画面（/light/ と /light/?class=… など）は、いつも同じ index.html
async function page(req) {
  const cache = await caches.open(SHELL);
  const hit = await cache.match(SCOPE);
  if (hit) return hit;
  const res = await fetch(req);
  if (res.ok) await cache.put(SCOPE, res.clone());
  return res;
}

// アプリ本体：入れ物にあればそれを出す。なければ読んで入れる
async function shell(req) {
  const cache = await caches.open(SHELL);
  const key = req.url.split('#')[0];
  const hit = await cache.match(key);
  if (hit) return hit;
  const res = await fetch(req);
  if (res.ok && res.type === 'basic') await cache.put(key, res.clone());
  return res;
}

// 単語帳・問題：手元のものをすぐ出し、裏で新しいかを確かめる
async function data(req, event) {
  const cache = await caches.open(DATA);
  const key = req.url.split('#')[0];
  const hit = await cache.match(key);
  const update = fetch(req).then(async (res) => {
    if (res.ok && res.type === 'basic') await cache.put(key, res.clone());
    return res;
  });
  if (hit) {
    event.waitUntil(update.catch(() => {}));
    return hit;
  }
  return update;
}
