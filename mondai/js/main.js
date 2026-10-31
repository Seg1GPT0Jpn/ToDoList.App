// 起動・画面の切り替え（#/ページ名/引数）
import { loadAll, state, log } from './core/store.js';
import { migrateLegacy } from './core/migrate.js';
import { $, toast, on } from './core/util.js';
import { currentMaterial } from './ui/common.js';

const PAGES = {
  home: ['ホーム', () => import('./ui/home.js')],
  bank: ['問題バンク', () => import('./ui/bank.js')],
  studio: ['AIスタジオ', () => import('./ui/studio.js')],
  editor: ['教材制作', () => import('./ui/editor.js')],
  exam: ['テスト制作', () => import('./ui/exam.js')],
  answers: ['解答・解説', () => import('./ui/answers.js')],
  library: ['ライブラリ', () => import('./ui/library.js')],
  team: ['チーム', () => import('./ui/team.js')],
  analytics: ['分析', () => import('./ui/analytics.js')],
  settings: ['設定・データ', () => import('./ui/settings.js')],
};

/** @type {null | (() => void)} */
let cleanup = null;
let routing = 0;

async function route() {
  const my = ++routing;
  const [path, query = ''] = location.hash.replace(/^#\/?/, '').split('?');
  const parts = path.split('/').map(decodeURIComponent);
  const name = PAGES[parts[0]] ? parts[0] : 'home';
  const [title, load] = PAGES[name];
  document.querySelectorAll('#nav a').forEach(a => a.classList.toggle('active', a.getAttribute('data-page') === name));
  $('shell').classList.remove('nav-open');
  $('top-title').textContent = title;
  document.title = `${title}｜教材制作プラットフォーム`;
  if (cleanup) { try { cleanup(); } catch (e) { console.error(e); } cleanup = null; }
  const view = $('view');
  try {
    const mod = await load();
    if (my !== routing) return;
    view.innerHTML = '';
    const r = await mod.render(view, parts.slice(1), new URLSearchParams(query));
    if (typeof r === 'function') cleanup = r;
    view.focus({ preventScroll: true });
  } catch (e) {
    console.error(e);
    view.innerHTML = `<div class="notice error"><b>画面を表示できませんでした。</b><br>${String(e && e.message || e)}</div>`;
    log('エラー', name, String(e && e.stack || e));
  }
}

async function updateNavCount() {
  const m = await currentMaterial();
  const n = m ? m.blocks.filter(b => b.type === 'question').length : 0;
  const el = $('nav-count');
  el.textContent = String(n);
  el.hidden = !n;
}

function setupTheme() {
  const btn = $('theme-btn');
  const labels = { auto: '表示：自動', light: '表示：ライト', dark: '表示：ダーク' };
  const get = () => { try { return localStorage.getItem('mondai.theme') || 'auto'; } catch (e) { return 'auto'; } };
  const apply = (t) => {
    if (t === 'auto') delete document.documentElement.dataset.theme; else document.documentElement.dataset.theme = t;
    btn.textContent = labels[t];
  };
  apply(get());
  btn.addEventListener('click', () => {
    const next = { auto: 'light', light: 'dark', dark: 'auto' }[get()];
    try { localStorage.setItem('mondai.theme', next); } catch (e) { /* 保存できなくても切り替えだけ行う */ }
    apply(next);
  });
}

function setupErrors() {
  window.addEventListener('error', e => { log('エラー', 'window', `${e.message} @${e.filename}:${e.lineno}`); });
  window.addEventListener('unhandledrejection', e => {
    const msg = String(e.reason && e.reason.message || e.reason);
    log('エラー', 'promise', msg);
    toast('エラーが起きました：' + msg, 'error');
  });
}

async function init() {
  setupTheme();
  setupErrors();
  $('nav-toggle').addEventListener('click', () => $('shell').classList.toggle('nav-open'));
  document.addEventListener('keydown', e => { if (e.key === 'Escape') $('shell').classList.remove('nav-open'); });
  try {
    await loadAll();
    const n = await migrateLegacy();
    if (n) toast(`前の版で保存したプリント ${n} 件を「ライブラリ」に移しました`);
  } catch (e) {
    console.error(e);
    $('view').innerHTML = `<div class="notice error">データを読み込めませんでした：${String(e && e.message || e)}<br>このブラウザのプライベートモードでは保存機能が使えないことがあります。</div>`;
    return;
  }
  // 招待リンク（#invite=…）とログインリンクの戻り（#access_token=…）を受け取ってチーム画面へ
  const h = location.hash;
  if (h.startsWith('#invite=')) {
    try { sessionStorage.setItem('mondai.invite', decodeURIComponent(h.slice(8))); } catch (e) { /* なし */ }
    history.replaceState(null, '', location.pathname + location.search + '#/team');
  } else if (/access_token=|error_description=|[?&]code=/.test(h + location.search)) {
    try {
      const cloud = await import('./cloud/supabase.js');
      if (cloud.isConfigured()) { await cloud.getClient(); await cloud.currentUser(); }
    } catch (e) { console.error(e); }
    history.replaceState(null, '', location.pathname + '#/team');
  }
  on('current', updateNavCount);
  on('materials', updateNavCount);
  updateNavCount();
  window.addEventListener('hashchange', route);
  route();
}

init();
// テストから状態を確かめるため
/** @type {any} */ (window).__mondai = { state };
