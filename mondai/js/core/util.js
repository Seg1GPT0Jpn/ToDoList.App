// どの画面からも使う小さな道具

/** @param {string} id */
export const $ = (id) => /** @type {HTMLElement} */ (document.getElementById(id));

/** HTML として安全な文字列にする */
export function esc(s) {
  return String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

const B32 = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
/** 時刻順に並ぶ一意 ID（ULID 風）。prefix をつけられる */
export function uid(prefix = '') {
  let t = Date.now(), time = '';
  for (let i = 0; i < 10; i++) { time = B32[t % 32] + time; t = Math.floor(t / 32); }
  let rand = '';
  const bytes = crypto.getRandomValues(new Uint8Array(16));
  for (const b of bytes) rand += B32[b % 32];
  return prefix + time + rand;
}

export const nowISO = () => new Date().toISOString();

/** @template {(...a:any[])=>any} F @param {F} fn @param {number} ms */
export function debounce(fn, ms) {
  let t;
  return /** @type {F} */ ((...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms); });
}

/** ファイルとしてダウンロードさせる */
export function download(name, text, type = 'application/json') {
  const blob = new Blob([text], { type: type + ';charset=utf-8' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = name;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(a.href), 1000);
}

/** ユーザーにファイルを選ばせて File[] を返す */
export function pickFiles(accept, multiple = false) {
  return new Promise(resolve => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = accept;
    input.multiple = multiple;
    input.onchange = () => resolve(Array.from(input.files || []));
    input.click();
  });
}

export function fmtDate(iso, withTime = false) {
  if (!iso) return '';
  const d = new Date(iso);
  return withTime ? d.toLocaleString('ja-JP', { dateStyle: 'short', timeStyle: 'short' }) : d.toLocaleDateString('ja-JP');
}

export function shuffle(a, rand = Math.random) {
  for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(rand() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; }
  return a;
}

/** 深いコピー（JSON で表せるデータ用） */
export const clone = (o) => (o == null ? o : JSON.parse(JSON.stringify(o)));

let toastTimer;
export function toast(msg, kind = '') {
  const t = $('toast');
  if (!t) return;
  t.textContent = msg;
  t.className = 'toast show ' + kind;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { t.className = 'toast'; }, kind === 'error' ? 5000 : 2400);
}

/** 簡単な確認ダイアログ（confirm の代わりに使える Promise 版） */
export function confirmBox(message) {
  return Promise.resolve(window.confirm(message));
}

/** 小さな変更通知の仕組み */
const listeners = new Map();
export function on(ev, fn) {
  if (!listeners.has(ev)) listeners.set(ev, new Set());
  listeners.get(ev).add(fn);
  return () => listeners.get(ev).delete(fn);
}
export function emit(ev, data) {
  for (const fn of listeners.get(ev) || []) {
    try { fn(data); } catch (e) { console.error(e); }
  }
}
