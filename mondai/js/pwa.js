// アプリとしてのインストール（ホーム画面・デスクトップに追加）とオフライン対応
/** @type {any} */
let deferred = null;
/** @type {Set<() => void>} */
const listeners = new Set();
const notify = () => listeners.forEach(f => { try { f(); } catch (e) { console.error(e); } });

/** インストールして単独の画面で開いているか */
export function isInstalled() {
  return window.matchMedia('(display-mode: standalone)').matches || /** @type {any} */ (navigator).standalone === true;
}

/** iPhone・iPad（Safari）か。ブラウザのボタンではなく「共有 → ホーム画面に追加」で入れる */
export function isIOS() {
  const ua = navigator.userAgent;
  return /iPad|iPhone|iPod/.test(ua) || (ua.includes('Macintosh') && navigator.maxTouchPoints > 1);
}

/** いま「インストール」ボタンで入れられるか（Chrome・Edge など） */
export const canPrompt = () => !!deferred;

/** インストールの確認画面を出す。結果：'accepted' | 'dismissed' | 'unavailable' */
export async function promptInstall() {
  if (!deferred) return 'unavailable';
  const ev = deferred;
  deferred = null;
  notify();
  ev.prompt();
  const { outcome } = await ev.userChoice;
  return outcome;
}

/** インストールできる状態が変わったら呼ぶ @param {() => void} f */
export function onInstallChange(f) { listeners.add(f); return () => listeners.delete(f); }

export function setupPWA() {
  window.addEventListener('beforeinstallprompt', (e) => { e.preventDefault(); deferred = e; notify(); });
  window.addEventListener('appinstalled', () => { deferred = null; notify(); });
  // Service Worker は https（と開発用の localhost）でだけ使える
  if ('serviceWorker' in navigator && window.isSecureContext) {
    navigator.serviceWorker.register('sw.js').catch(e => console.warn('Service Worker を登録できませんでした', e));
  }
  const btn = document.getElementById('install-btn');
  if (btn) {
    const update = () => { btn.hidden = !canPrompt() || isInstalled(); };
    onInstallChange(update);
    update();
    btn.addEventListener('click', () => { promptInstall(); });
  }
}
