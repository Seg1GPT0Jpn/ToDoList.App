// 設定・データ管理
import { state, importDatasets, removeDataset, restoreHidden, log } from '../core/store.js';
import * as db from '../core/db.js';
import { makeBackup, restoreBackup, validateBackup, summarize } from '../core/backup.js';
import { esc, toast, download, pickFiles, fmtDate } from '../core/util.js';
import { modal } from './common.js';

async function cloudModule() {
  try { return await import('../cloud/supabase.js'); } catch (e) { return null; }
}

export async function render(root) {
  root.innerHTML = `
  <div class="page-head"><div class="grow"><h1>設定・データ</h1><p>問題データの読み込み、バックアップ、接続設定、操作履歴</p></div></div>
  <div class="grid2">
    <div>
      <section class="card" id="sec-import">
        <h2>問題データを読み込む</h2>
        <label class="drop" id="drop">
          <input type="file" id="file-input" multiple accept=".zip,.json">
          <span class="big">⇪</span>
          <b>ここに zip / json ファイルをドラッグ</b>
          <span class="muted small">またはクリックしてファイルを選ぶ（複数まとめて選べます）</span>
        </label>
        <p class="small muted" id="import-status" role="status"></p>
        <p class="small muted">読み込んだデータはこのブラウザの中だけに保存され、インターネットには送られません。内蔵問題（高校5教科 3,840問）は読み込まなくても使えます。</p>
        <div id="datasets"></div>
      </section>
      <section class="card">
        <h2>保存しているデータ</h2>
        <div class="stats" id="stats"></div>
        <div id="storage" class="small muted"></div>
        <div class="row mt"><button class="btn sm" id="persist">消えにくくする（永続保存を申請）</button><button class="btn sm" id="restore-hidden">削除した内蔵・取り込み問題を元に戻す</button></div>
      </section>
      <section class="card">
        <h2>バックアップと復元</h2>
        <p class="small muted">ブラウザのデータ消去や端末の故障に備えて、ときどきバックアップを保存してください。自作の問題・編集・教材・学習結果・設定がまとめて1つのファイルになります。</p>
        <label class="check"><input type="checkbox" id="bk-datasets"> 取り込んだ zip のデータも含める（ファイルが大きくなります）</label>
        <div class="row"><button class="btn primary" id="backup">バックアップを保存</button><button class="btn" id="restore">バックアップから復元…</button></div>
        <p class="small muted" id="last-backup"></p>
      </section>
    </div>
    <div>
      <section class="card">
        <h2>表示</h2>
        <label class="f">画面の明るさ<select class="input" id="theme">
          <option value="auto">端末の設定に合わせる</option><option value="light">ライト</option><option value="dark">ダーク</option>
        </select></label>
        <label class="f">作成者の名前（問題・教材に記録されます）<input class="input" id="author" placeholder="例：佐藤"></label>
      </section>
      <section class="card" id="sec-cloud">
        <h2>クラウド接続（Supabase）<span class="chip" id="cloud-state">未接続</span></h2>
        <p class="small muted">チームでの共有・レビュー・AI 機能を使うには、Supabase（無料枠あり）の設定が必要です。手順は <a href="https://github.com/Seg1GPT0Jpn/ToDoList.App/blob/main/mondai/supabase/README.md" target="_blank" rel="noopener">supabase/README.md</a> を見てください。ここに入れる「anon key」は公開してよい鍵です（権限はサーバー側のルールで守られます）。<b>service_role キーや AI の API キーはここに入れないでください。</b></p>
        <label class="f">Project URL<input class="input mono" id="sb-url" placeholder="https://xxxxx.supabase.co"></label>
        <label class="f">anon key<input class="input mono" id="sb-key" placeholder="eyJhbGciOi..."></label>
        <div class="row"><button class="btn primary" id="sb-save">保存して接続</button><button class="btn" id="sb-clear">接続を解除</button></div>
      </section>
      <section class="card">
        <h2>AI（Claude）</h2>
        <div id="ai-state" class="small"></div>
        <div id="ai-usage" class="small muted mt"></div>
      </section>
      <section class="card">
        <h2>操作履歴・エラー記録</h2>
        <div class="row"><label class="check"><input type="checkbox" id="only-err"> エラーだけ表示</label><span class="spacer"></span><button class="btn sm" id="hist-dl">履歴を書き出す</button></div>
        <div id="history" style="max-height:340px;overflow:auto"></div>
      </section>
    </div>
  </div>`;

  const $ = (id) => /** @type {any} */ (root.querySelector('#' + id));

  // ---------- 取り込み ----------
  const renderDatasets = () => {
    const rows = state.datasets.map(ds => `<tr><td>${esc(ds.name)}</td><td>${ds.questions ? ds.questions.length.toLocaleString() + ' 問' : (ds.lists || []).length + ' 冊'}</td>
      <td>${ds.builtin ? 'アプリに内蔵' : fmtDate(ds.importedAt)}</td><td>${ds.builtin ? '' : `<button class="btn sm danger" data-del="${esc(ds.id)}">削除</button>`}</td></tr>`).join('');
    $('datasets').innerHTML = `<table class="list"><tr><th>データ</th><th>中身</th><th>読み込んだ日</th><th></th></tr>${rows}</table>`;
  };
  renderDatasets();
  const handleFiles = async (files) => {
    if (!files.length) return;
    const st = $('import-status');
    if (!/** @type {any} */ (window).JSZip) { st.textContent = 'zip を開く部品が読み込めていません。インターネットにつないで開き直してください。'; return; }
    try {
      const result = await /** @type {any} */ (window).Importer.importFiles(files, (m) => { st.textContent = m; });
      if (!result.length) { st.textContent = '問題データが見つかりませんでした。もらった zip をそのまま選んでください。'; return; }
      st.textContent = '保存中…';
      await importDatasets(result);
      st.textContent = '読み込みました：' + result.map(d => `${d.name}（${d.questions ? d.questions.length.toLocaleString() + '問' : d.lists.length + '冊'}）`).join('、');
      renderDatasets(); renderStats();
      toast('読み込みました', 'ok');
    } catch (e) {
      st.textContent = '読み込みに失敗しました：' + e.message;
      log('エラー', '取り込み', e.message);
    }
  };
  const drop = $('drop');
  $('file-input').addEventListener('change', (e) => { handleFiles(Array.from(e.target.files)); e.target.value = ''; });
  ['dragenter', 'dragover'].forEach(ev => drop.addEventListener(ev, e => { e.preventDefault(); drop.classList.add('over'); }));
  ['dragleave', 'drop'].forEach(ev => drop.addEventListener(ev, e => { e.preventDefault(); drop.classList.remove('over'); }));
  drop.addEventListener('drop', e => handleFiles(Array.from(e.dataTransfer.files)));
  $('datasets').addEventListener('click', async e => {
    const id = e.target.dataset.del;
    if (!id || !confirm('このデータを削除しますか？（もう一度読み込めば戻せます）')) return;
    await removeDataset(id);
    renderDatasets(); renderStats();
  });

  // ---------- 保存状況 ----------
  const renderStats = async () => {
    const by = { builtin: 0, imported: 0, user: 0, ai: 0 };
    const units = new Set();
    for (const q of state.questions) { by[q.origin] = (by[q.origin] || 0) + 1; if (q.unit) units.add((q.subj || '') + '|' + q.unit); }
    const [results, versions] = await Promise.all([db.count('results'), db.count('versions')]);
    const edited = [...state.user.values()].filter(u => state.base.has(u.id) && !u.deleted).length;
    const hidden = [...state.user.values()].filter(u => u.deleted).length;
    const cells = [
      ['問題（合計）', state.questions.length], ['内蔵', by.builtin], ['取り込み', by.imported], ['自作', by.user], ['AI生成', by.ai],
      ['単元', units.size], ['教材', state.materials.length], ['学習結果', results], ['編集した元データ', edited], ['問題の旧版', versions], ['単語帳・用語カード', state.lists.length],
    ];
    $('stats').innerHTML = cells.map(([l, n]) => `<div class="stat"><b>${Number(n).toLocaleString()}</b><span>${l}</span></div>`).join('');
    $('restore-hidden').textContent = `削除した内蔵・取り込み問題を元に戻す（${hidden}問）`;
    $('restore-hidden').disabled = !hidden;
    try {
      const est = await navigator.storage.estimate();
      const persisted = navigator.storage.persisted ? await navigator.storage.persisted() : false;
      const mb = (n) => (n / 1024 / 1024).toFixed(1) + ' MB';
      $('storage').textContent = `使用量 ${mb(est.usage || 0)}／上限の目安 ${mb(est.quota || 0)}。${persisted ? '永続保存が有効です（ブラウザが自動で消しにくくなっています）。' : '永続保存は未申請です。'}`;
      $('persist').disabled = persisted;
    } catch (e) { $('storage').textContent = ''; }
  };
  renderStats();
  $('persist').addEventListener('click', async () => {
    const ok = navigator.storage.persist ? await navigator.storage.persist() : false;
    toast(ok ? '永続保存が有効になりました' : 'ブラウザが永続保存を許可しませんでした（よく使うサイトになると許可されやすくなります）', ok ? 'ok' : '');
    renderStats();
  });
  $('restore-hidden').addEventListener('click', async () => {
    const n = await restoreHidden();
    toast(`${n} 問を元に戻しました`, 'ok');
    renderStats();
  });

  // ---------- バックアップ ----------
  const showLast = async () => { const t = await db.kvGet('lastBackup'); $('last-backup').textContent = t ? `前回のバックアップ：${fmtDate(t, true)}` : 'まだバックアップしていません。'; };
  showLast();
  $('backup').addEventListener('click', async () => {
    const data = await makeBackup({ includeDatasets: $('bk-datasets').checked });
    const d = new Date();
    const name = `教材バックアップ_${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, '0')}${String(d.getDate()).padStart(2, '0')}.json`;
    download(name, JSON.stringify(data));
    await db.kvSet('lastBackup', new Date().toISOString());
    await log('バックアップを保存', name);
    showLast();
  });
  $('restore').addEventListener('click', async () => {
    const [f] = await pickFiles('.json,application/json');
    if (!f) return;
    let data;
    try { data = JSON.parse(await f.text()); } catch (e) { toast('ファイルを読めませんでした（JSON ではありません）', 'error'); return; }
    const err = validateBackup(data);
    if (err) { toast(err, 'error'); return; }
    const s = summarize(data);
    const m = modal({
      title: 'バックアップから復元', narrow: true,
      body: `<p>${esc(f.name)}（${fmtDate(data.createdAt, true)} 作成）</p>
        <p>問題 ${s.questions}・教材 ${s.materials}・学習結果 ${s.results}・取り込みデータ ${s.datasets}・履歴 ${s.history}</p>
        <label class="check"><input type="radio" name="mode" value="merge" checked> 今のデータに足す（同じものは上書き）</label>
        <label class="check"><input type="radio" name="mode" value="replace"> 今のデータを消して置きかえる</label>`,
      foot: '<button class="btn" data-close>やめる</button><button class="btn primary" id="do-restore">復元する</button>',
    });
    m.el.querySelector('#do-restore').addEventListener('click', async () => {
      const mode = /** @type {any} */ (m.el.querySelector('input[name=mode]:checked')).value;
      if (mode === 'replace' && !confirm('今のデータを消して置きかえます。よろしいですか？')) return;
      await restoreBackup(data, mode);
      await log('バックアップから復元', f.name, mode);
      m.close();
      toast('復元しました。画面を読み込み直します', 'ok');
      setTimeout(() => location.reload(), 800);
    });
  });

  // ---------- 表示・作成者 ----------
  try { $('theme').value = localStorage.getItem('mondai.theme') || 'auto'; } catch (e) { /* 既定のまま */ }
  $('theme').addEventListener('change', () => {
    try { localStorage.setItem('mondai.theme', $('theme').value); } catch (e) { /* 保存できなくても表示は変える */ }
    const t = $('theme').value;
    if (t === 'auto') delete document.documentElement.dataset.theme; else document.documentElement.dataset.theme = t;
    const btn = document.getElementById('theme-btn');
    if (btn) btn.textContent = { auto: '表示：自動', light: '表示：ライト', dark: '表示：ダーク' }[t];
  });
  $('author').value = await db.kvGet('author', '');
  $('author').addEventListener('change', () => db.kvSet('author', $('author').value.trim()));

  // ---------- クラウド・AI ----------
  const cloud = await cloudModule();
  const renderCloud = async () => {
    const chip = $('cloud-state');
    if (!cloud) { chip.textContent = '部品なし'; $('ai-state').innerHTML = '<div class="notice warn">クラウド接続の部品が読み込めませんでした。</div>'; return; }
    const conf = cloud.isConfigured();
    let user = null;
    if (conf) { try { user = await cloud.currentUser(); } catch (e) { /* 未ログイン */ } }
    chip.textContent = conf ? (user ? 'ログイン中' : '接続設定あり（未ログイン）') : '未接続';
    chip.className = 'chip ' + (user ? 'ok' : conf ? 'warn' : '');
    try { const c = JSON.parse(localStorage.getItem('mondai.cloud') || '{}'); $('sb-url').value = c.url || ''; $('sb-key').value = c.anonKey || ''; } catch (e) { /* なし */ }
    $('ai-state').innerHTML = !conf
      ? '<div class="notice">AI は<b>未接続</b>です。上の Supabase 接続を設定し、サーバーに Claude の API キーを登録すると使えます（手順は supabase/README.md）。AI を使わない機能はすべてそのまま使えます。</div>'
      : !user ? '<div class="notice warn">AI を使うには「チーム」画面からログインしてください。</div>'
        : '<div class="notice ok">AI を使える状態です（実際に使えるかは、サーバーに API キーが登録されているかによります）。</div>';
  };
  renderCloud();
  $('sb-save').addEventListener('click', async () => {
    const url = $('sb-url').value.trim(), anonKey = $('sb-key').value.trim();
    if (!/^https:\/\/[a-z0-9-]+\.supabase\.(co|in)\/?$/.test(url)) { toast('Project URL の形が正しくありません（https://xxxx.supabase.co）', 'error'); return; }
    if (anonKey.length < 30) { toast('anon key を正しく貼り付けてください', 'error'); return; }
    if (/service_role/.test(atobSafe(anonKey))) { toast('これは service_role キーです。ブラウザに入れてはいけません。anon key を使ってください', 'error'); return; }
    cloud.configure({ url: url.replace(/\/$/, ''), anonKey });
    await log('クラウド接続を設定', url);
    toast('保存しました', 'ok');
    renderCloud();
  });
  $('sb-clear').addEventListener('click', async () => {
    try { localStorage.removeItem('mondai.cloud'); } catch (e) { /* なし */ }
    toast('接続を解除しました');
    setTimeout(() => location.reload(), 500);
  });
  const jobs = await db.all('aiJobs');
  const today = new Date().toISOString().slice(0, 10), month = today.slice(0, 7);
  const sum = (list) => list.reduce((a, j) => a + (j.tokens || 0), 0);
  $('ai-usage').textContent = jobs.length
    ? `この端末からの AI 利用：今日 ${jobs.filter(j => j.at.startsWith(today)).length} 回（${sum(jobs.filter(j => j.at.startsWith(today))).toLocaleString()} トークン）、今月 ${jobs.filter(j => j.at.startsWith(month)).length} 回（${sum(jobs.filter(j => j.at.startsWith(month))).toLocaleString()} トークン）`
    : 'AI の利用記録はまだありません。';

  // ---------- 履歴 ----------
  const renderHistory = async () => {
    let list = (await db.all('history')).sort((a, b) => b.at.localeCompare(a.at));
    if ($('only-err').checked) list = list.filter(h => h.action === 'エラー');
    $('history').innerHTML = list.length
      ? `<table class="list small">${list.slice(0, 300).map(h => `<tr><td style="white-space:nowrap">${fmtDate(h.at, true)}</td><td>${h.action === 'エラー' ? '<span class="chip danger">エラー</span>' : esc(h.action)}</td><td>${esc(h.target)}<div class="muted">${esc(h.detail)}</div></td></tr>`).join('')}</table>`
      : '<p class="empty">記録はまだありません。</p>';
  };
  renderHistory();
  $('only-err').addEventListener('change', renderHistory);
  $('hist-dl').addEventListener('click', async () => download('操作履歴.json', JSON.stringify(await db.all('history'), null, 1)));
}

function atobSafe(jwt) {
  try { return atob(jwt.split('.')[1].replace(/-/g, '+').replace(/_/g, '/')); } catch (e) { return ''; }
}
