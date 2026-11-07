// 公開場所の引っ越し（GitHub Pages → Firebase Hosting）
// - 旧ページで開かれたとき：データがなければすぐ新しいページへ移動。データがあれば「データごと移す」案内を出す
// - 「データごと移す」：新しいページを開き、新しいページの準備ができたら旧ページのデータ（バックアップと同じ形）を
//   postMessage で渡す。新しいページは送り元が旧ページのオリジンであることと合言葉（nonce）を確かめ、
//   利用者が確認してから今のデータに足す（同じ ID は上書き）
import * as db from './db.js';

const OLD_ORIGIN = 'https://seg1gpt0jpn.github.io';
const NEW_URL = 'https://mondai-1a2b3.web.app/';
const MOVED_KEY = 'mondai.movedAt';

/**
 * 引っ越しの設定。テストでは localhost と 127.0.0.1（別のオリジン）を旧・新に見立てる
 * @returns {{ oldOrigin: string, newUrl: string, newOrigin: string }}
 */
export function config() {
  const local = ['localhost', '127.0.0.1'].includes(location.hostname);
  if (local) {
    try {
      const t = JSON.parse(localStorage.getItem('mondai.moveTest') || 'null');
      if (t && t.oldOrigin && t.newUrl) return { oldOrigin: t.oldOrigin, newUrl: t.newUrl, newOrigin: new URL(t.newUrl).origin };
    } catch (e) { /* テスト設定なし */ }
  }
  return { oldOrigin: OLD_ORIGIN, newUrl: NEW_URL, newOrigin: new URL(NEW_URL).origin };
}

/** 旧ページ（引っ越し元）で開かれているか */
export const isOldSite = () => location.origin === config().oldOrigin && location.origin !== config().newOrigin;

/** 移す価値のあるデータ（自作・編集した問題、教材、学習結果、取り込んだデータ、旧版のプリント）があるか */
export async function hasUserData() {
  for (const s of ['materials', 'questions', 'results', 'datasets', 'ratings']) {
    if (await db.count(s) > 0) return true;
  }
  try { return !!(localStorage.getItem('mondai.saved') || localStorage.getItem('mondai.cart')); } catch (e) { return false; }
}

const movedAt = () => { try { return localStorage.getItem(MOVED_KEY); } catch (e) { return null; } };

/** 新しいページの、今と同じ画面の URL */
const target = () => config().newUrl + (/^#\//.test(location.hash) ? location.hash : '');

/**
 * 旧ページで開かれたときの処理。移動するなら true（アプリは起動しない）
 * @param {(html: string) => HTMLElement} show 案内を画面に出す
 */
export async function handleOldSite(show) {
  if (!isOldSite()) return false;
  let data = false;
  try { data = await hasUserData(); } catch (e) { data = false; }
  if (!data || movedAt()) { location.replace(target()); return true; }
  const root = show(`
    <section class="card" style="max-width:640px;margin:40px auto">
      <h1 style="margin-top:0">このアプリは新しいページに移りました</h1>
      <p>新しいページ：<a href="${target()}">${config().newUrl}</a></p>
      <p>この端末には、ここで作った教材や問題などのデータがあります。データは端末のブラウザにページごとに保存されているため、<b>新しいページへ移す</b>と、続きから使えます。</p>
      <div class="row mt"><button class="btn primary" id="mv-go">データごと新しいページへ移す</button></div>
      <p class="small muted" id="mv-status" role="status"></p>
      <details class="mt"><summary>うまく移せないとき</summary>
        <p class="small">「バックアップを保存」でファイルを保存し、新しいページの「設定・データ → バックアップから復元」で読み込んでください。</p>
        <div class="row"><button class="btn" id="mv-backup">バックアップを保存</button><a class="btn ghost" id="mv-skip" href="${target()}">データを移さずに新しいページへ</a></div>
      </details>
    </section>`);
  const status = /** @type {HTMLElement} */ (root.querySelector('#mv-status'));
  root.querySelector('#mv-go').addEventListener('click', () => {
    status.textContent = '新しいページを開いています…（新しいページで「取り込む」を押してください）';
    sendTo(window.open(config().newUrl + '#move=' + nonce(), '_blank'), status);
  });
  root.querySelector('#mv-backup').addEventListener('click', async () => {
    const { makeBackup } = await import('./backup.js');
    const { download } = await import('./util.js');
    download('教材バックアップ_引っ越し用.json', JSON.stringify(await makeBackup({ includeDatasets: true })));
  });
  root.querySelector('#mv-skip').addEventListener('click', () => { try { localStorage.setItem(MOVED_KEY, new Date().toISOString()); } catch (e) { /* なし */ } });
  return true;
}

let currentNonce = '';
const nonce = () => (currentNonce = Array.from(crypto.getRandomValues(new Uint8Array(12)), b => b.toString(16).padStart(2, '0')).join(''));

/** 旧ページ：新しいページの準備ができたらデータを渡す @param {Window|null} w @param {HTMLElement} status */
function sendTo(w, status) {
  if (!w) { status.textContent = '新しいページを開けませんでした（ポップアップが止められています）。下の「うまく移せないとき」の方法で移してください。'; return; }
  const { newOrigin } = config();
  const onMsg = async (/** @type {MessageEvent} */ e) => {
    if (e.origin !== newOrigin || e.source !== w || !e.data || e.data.nonce !== currentNonce) return;
    if (e.data.type === 'mondai-move-ready') {
      const { makeBackup } = await import('./backup.js');
      w.postMessage({ type: 'mondai-move-data', nonce: currentNonce, data: await makeBackup({ includeDatasets: true }) }, newOrigin);
      status.textContent = 'データを渡しました。新しいページで「取り込む」を押してください。';
    } else if (e.data.type === 'mondai-move-done') {
      window.removeEventListener('message', onMsg);
      try { localStorage.setItem(MOVED_KEY, new Date().toISOString()); } catch (err) { /* なし */ }
      status.innerHTML = `<b>移し終わりました。</b>これからは <a href="${config().newUrl}">${config().newUrl}</a> を使ってください（このページを開いても自動で移動します）。`;
    } else if (e.data.type === 'mondai-move-cancel') {
      status.textContent = '取り込みが取り消されました。もう一度ボタンを押すとやり直せます。';
    }
  };
  window.addEventListener('message', onMsg);
}

/**
 * 新しいページ：#move=合言葉 で開かれたら、旧ページからデータを受け取って取り込む。取り込んだら true
 * @param {(summary: {questions: number, materials: number, results: number, datasets: number}) => Promise<boolean>} confirmImport
 */
export async function receiveMove(confirmImport) {
  const m = /^#move=([0-9a-f]{16,64})$/.exec(location.hash);
  if (!m || !window.opener) return false;
  const key = m[1];
  const { oldOrigin } = config();
  history.replaceState(null, '', location.pathname + location.search + '#/home');
  const opener = window.opener;
  const data = await new Promise((resolve) => {
    const onMsg = (/** @type {MessageEvent} */ e) => {
      if (e.origin !== oldOrigin || e.source !== opener || !e.data || e.data.nonce !== key || e.data.type !== 'mondai-move-data') return;
      window.removeEventListener('message', onMsg);
      resolve(e.data.data);
    };
    window.addEventListener('message', onMsg);
    opener.postMessage({ type: 'mondai-move-ready', nonce: key }, oldOrigin);
    setTimeout(() => { window.removeEventListener('message', onMsg); resolve(null); }, 60000);
  });
  if (!data) return false;
  const { validateBackup, summarize, restoreBackup } = await import('./backup.js');
  const err = validateBackup(data);
  if (err) throw new Error(err);
  if (!(await confirmImport(summarize(data)))) {
    opener.postMessage({ type: 'mondai-move-cancel', nonce: key }, oldOrigin);
    return false;
  }
  await restoreBackup(data, 'merge');
  opener.postMessage({ type: 'mondai-move-done', nonce: key }, oldOrigin);
  return true;
}
