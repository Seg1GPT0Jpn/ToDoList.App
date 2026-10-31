// 教材制作：ブロック編集・用紙設定・見本・印刷
import { state, getMaterial, saveMaterial, setCurrentMaterial, currentMaterialId, materialVersions, log } from '../core/store.js';
import { esc, uid, nowISO, toast, debounce, clone, emit, fmtDate, download } from '../core/util.js';
import { KINDS, PAGE_SIZES, newMaterial, blockId, questionBlock, outdatedBlocks } from '../domain/material.js';
import { renderMaterial, pageCss } from '../render/material.js';
import { FORMATS } from '../domain/format.js';
import { canVary, varyQuestion } from '../domain/variant.js';
import { modal, renderMath, texClass, makeWordQuestions, kindLabel, R, fitPreview, printFileName, printAs } from './common.js';
import { editQuestion } from './qeditor.js';

const BLOCK_LABEL = { heading: '見出し', text: '文章', section: '大問', question: '問題', pagebreak: '改ページ', table: '表', image: '画像', space: '解答・メモ欄' };
const STATUS_LABEL = { draft: '下書き', review: 'レビュー中', approved: '承認済み', published: '公開・配布', archived: 'アーカイブ' };

export async function render(root, parts, params) {
  // #/editor/new[/種類] → 新しい教材、#/editor/<id> → その教材、#/editor → 作業中の教材
  if (parts[0] === 'new') return newDialog(root, parts[1]);
  let id = parts[0] || await currentMaterialId();
  let m = id ? getMaterial(id) : null;
  if (!m) {
    root.innerHTML = `<div class="page-head"><div class="grow"><h1>教材制作</h1></div></div>
      <div class="card empty">作業中の教材はありません。<br><a class="btn primary" href="#/editor/new">新しい教材を作る</a> <a class="btn" href="#/library">ライブラリから開く</a></div>`;
    return;
  }
  m = clone(m);
  await setCurrentMaterial(m.id);

  // ---------- 元に戻す・やり直し ----------
  const undo = [], redo = [];
  let lastSnap = JSON.stringify(m);
  const snapshot = () => {
    const s = JSON.stringify(m);
    if (s === lastSnap) return;
    undo.push(lastSnap);
    if (undo.length > 100) undo.shift();
    redo.length = 0;
    lastSnap = s;
  };

  // ---------- 自動保存 ----------
  let dirty = false;
  const setState = (txt, cls = '') => { const el = root.querySelector('#savestate'); if (el) { el.textContent = txt; el.className = 'savestate ' + cls; } };
  const autosave = debounce(async () => {
    setState('保存中…', 'dirty');
    await saveMaterial(m);
    dirty = false;
    setState('保存済み ' + new Date().toLocaleTimeString('ja-JP', { hour: '2-digit', minute: '2-digit' }));
    emit('current');
  }, 700);
  const changed = (structural = false) => {
    snapshot();
    dirty = true;
    setState('未保存の変更', 'dirty');
    autosave();
    if (structural) renderBlocks();
    renderPreview();
  };
  const beforeUnload = (e) => { if (dirty) { e.preventDefault(); e.returnValue = ''; } };
  window.addEventListener('beforeunload', beforeUnload);

  const outdated = outdatedBlocks(m, state.byId);

  root.innerHTML = `
  <div class="page-head no-print">
    <div class="grow"><h1 style="display:flex;gap:8px;align-items:center;flex-wrap:wrap"><input class="input" id="m-title" style="font-size:20px;font-weight:700;max-width:520px"> <span class="chip">${esc(kindLabel(m.kind))}</span> <span class="chip" id="m-status"></span></h1>
      <p><span class="savestate" id="savestate">保存済み</span> ・ <span id="m-count"></span></p></div>
    <button class="btn" id="undo" title="元に戻す（Ctrl+Z）">↶ 元に戻す</button><button class="btn" id="redo" title="やり直し（Ctrl+Y）">↷ やり直し</button>
    <button class="btn" id="save-ver" title="この時点の版を残す">版を保存</button>
    <button class="btn" id="vary-all" title="数値だけを変えた別の版（B版など）を作る">数値替え版を作る</button>
    <div class="btn-group" role="group" aria-label="印刷">
      <button class="btn primary" data-print="all">印刷／PDF</button>
      <button class="btn" data-print="questions">問題用紙</button>
      <button class="btn" data-print="sheet">解答用紙</button>
      <button class="btn" data-print="key">解答・解説</button>
    </div>
  </div>
  ${outdated.length ? `<div class="notice warn no-print">問題バンクで更新された問題が ${outdated.length} 問あります（この教材には使った時点の内容が入っています）。<button class="btn sm" id="update-all">最新版に更新</button></div>` : ''}
  <div class="editor-layout">
    <div class="editor-side no-print">
      <div class="card">
        <div class="tabs-inline btn-group" id="side-tabs">
          <button class="btn sm on" data-tab="blocks">構成</button><button class="btn sm" data-tab="page">用紙・印刷</button><button class="btn sm" data-tab="info">情報</button>
        </div>
        <div data-pane="blocks">
          <div class="add-row">
            <button class="btn sm" data-add="heading">＋見出し</button><button class="btn sm" data-add="text">＋文章</button><button class="btn sm" data-add="section">＋大問</button>
            <a class="btn sm" href="#/bank">＋問題（バンク）</a><button class="btn sm" data-add="newq">＋問題を作る</button>
            <button class="btn sm" data-add="table">＋表</button><button class="btn sm" data-add="image">＋画像</button><button class="btn sm" data-add="space">＋解答欄</button><button class="btn sm" data-add="pagebreak">＋改ページ</button>
            <button class="btn sm" data-add="words">＋単語・用語テスト</button>
          </div>
          <ol class="blocks" id="blocks"></ol>
        </div>
        <div data-pane="page" hidden>
          <div class="form-grid two">
            <label class="f">用紙<select class="input" data-pg="size">${Object.keys(PAGE_SIZES).map(s => `<option>${s}</option>`).join('')}</select></label>
            <label class="f">向き<select class="input" data-pg="orientation"><option value="portrait">縦</option><option value="landscape">横</option></select></label>
            <label class="f">余白（mm）<input class="input" type="number" min="5" max="30" data-pg="margin"></label>
            <label class="f">段組<select class="input" data-pg="cols"><option value="1">1段</option><option value="2">2段</option></select></label>
            <label class="f">文字の大きさ<select class="input" data-pg="font"><option value="11">とても小</option><option value="12">小</option><option value="13.5">ふつう</option><option value="15">大</option><option value="17">とても大</option></select></label>
            <label class="f">ページ番号<select class="input" data-pg="pageNumbers"><option value="true">つける</option><option value="false">つけない</option></select></label>
          </div>
          <label class="f">ヘッダー（各ページの上）<input class="input" data-pg="header" placeholder="例：〇〇高校 2年 数学"></label>
          <label class="f">フッター（各ページの左下）<input class="input" data-pg="footer"></label>
          <div class="form-grid two">
            <label class="f">選択肢の記号<select class="input" data-pr="labels"><option value="auto">元のまま（なければア・イ…）</option><option value="kana">ア・イ・ウ・エ</option><option value="num">1・2・3・4</option><option value="alpha">A・B・C・D</option></select></label>
            <label class="f">解答欄<select class="input" data-pr="answer"><option value="inline">問題の下</option><option value="sheet">別紙の解答用紙</option><option value="none">つけない</option></select></label>
            <label class="f">解答・解説<select class="input" data-pr="key"><option value="expl">解答と解説</option><option value="ans">解答だけ</option><option value="none">つけない</option></select></label>
            <label class="f">配点<select class="input" data-pr="points"><option value="data">問題の配点</option><option value="block">問題ごとに指定</option><option value="equal">均等（満点に合わせる）</option><option value="none">表示しない</option></select></label>
            <label class="f">大問のまとめ方<select class="input" data-pr="group"><option value="none">まとめない</option><option value="type">同じ形式で</option><option value="unit">同じ単元で</option></select></label>
            <label class="f">満点<input class="input" type="number" min="1" id="full-marks"></label>
          </div>
          <label class="f">形式（入試の形に合わせる）<select class="input" data-pr="format">${Object.entries(FORMATS).map(([k, f]) => `<option value="${k}">${esc(f.label)}</option>`).join('')}</select></label>
          <p class="small muted" id="fmt-note"></p>
          <label class="check"><input type="checkbox" data-pr="shuffle"> 選択肢の順番を入れかえる <button class="btn sm ghost" id="reshuffle" type="button">入れかえ直す</button></label>
          <label class="check"><input type="checkbox" data-pr="name"> 名前欄・得点欄</label>
          <label class="check"><input type="checkbox" data-pr="date"> 日付</label>
          <label class="check"><input type="checkbox" data-pr="meta"> 問題に出典・単元を小さく表示</label>
          <p class="small muted">「大問」ブロックを置くと、そのブロックで大問が分かれます（まとめ方の設定より優先）。</p>
        </div>
        <div data-pane="info" hidden>
          <label class="f">サブタイトル<input class="input" data-mt="subtitle"></label>
          <label class="f">注意書き（1行に1つ）<textarea class="input" data-mt="notes" rows="3"></textarea></label>
          <label class="f">種類<select class="input" data-mt="kind">${Object.entries(KINDS).map(([k, d]) => `<option value="${k}">${esc(d.label)}</option>`).join('')}</select></label>
          <label class="f">フォルダ<input class="input" data-mt="folder" placeholder="例：2年1学期"></label>
          <label class="f">タグ（読点区切り）<input class="input" id="m-tags"></label>
          <label class="f">状態<select class="input" data-mt="status">${Object.entries(STATUS_LABEL).map(([k, l]) => `<option value="${k}">${l}</option>`).join('')}</select></label>
          <div class="small muted">作成 ${fmtDate(m.createdAt, true)}・更新 <span id="m-updated"></span>・版 ${m.rev || 1}</div>
          <div class="row mt"><button class="btn sm" id="ver-list">保存した版</button><button class="btn sm" id="export-m">JSON で書き出す</button></div>
        </div>
      </div>
    </div>
    <div class="preview-wrap" id="pw"><div class="preview print-root" id="preview"></div></div>
  </div>`;

  const $ = (sel) => /** @type {any} */ (root.querySelector(sel));
  const tabs = $('#side-tabs');
  tabs.addEventListener('click', (e) => {
    const t = e.target.dataset.tab;
    if (!t) return;
    tabs.querySelectorAll('.btn').forEach(b => b.classList.toggle('on', b.dataset.tab === t));
    root.querySelectorAll('[data-pane]').forEach(p => { p.hidden = p.getAttribute('data-pane') !== t; });
  });

  // ---------- 設定の入力欄 ----------
  const fillForm = () => {
    $('#m-title').value = m.title;
    root.querySelectorAll('[data-pg]').forEach(el => { el.value = String(m.page[el.dataset.pg]); });
    root.querySelectorAll('[data-pr]').forEach(el => { if (el.type === 'checkbox') el.checked = !!m.print[el.dataset.pr]; else el.value = m.print[el.dataset.pr]; });
    root.querySelectorAll('[data-mt]').forEach(el => { el.value = m[el.dataset.mt] || ''; });
    $('#m-tags').value = (m.tags || []).join('、');
    $('#full-marks').value = (m.exam && m.exam.total) || 100;
    $('#m-status').textContent = STATUS_LABEL[m.status] || m.status;
    if (!m.print.format) m.print.format = 'standard';
    const fm = FORMATS[m.print.format];
    $('#fmt-note').textContent = fm && fm.cover ? `${fm.label}：表紙・番号の付け方・選択肢の記号・解答用紙（${fm.sheet === 'mark' ? 'マークシート' : '大問ごとの記述欄'}）が形式に合わせて変わります。` : '';
    $('#m-updated').textContent = fmtDate(m.updatedAt, true);
  };
  fillForm();
  $('#m-title').addEventListener('input', () => { m.title = $('#m-title').value; changed(); });
  root.querySelectorAll('[data-pg]').forEach(el => el.addEventListener('change', () => {
    const k = el.dataset.pg;
    m.page[k] = k === 'pageNumbers' ? el.value === 'true' : k === 'margin' ? Number(el.value) : el.value;
    changed();
  }));
  root.querySelectorAll('[data-pg="header"],[data-pg="footer"]').forEach(el => el.addEventListener('input', () => { m.page[el.dataset.pg] = el.value; changed(); }));
  root.querySelectorAll('[data-pr]').forEach(el => el.addEventListener('change', () => { m.print[el.dataset.pr] = el.type === 'checkbox' ? el.checked : el.value; if (el.dataset.pr === 'format') fillForm(); changed(); }));
  root.querySelectorAll('[data-mt]').forEach(el => el.addEventListener('change', () => { m[el.dataset.mt] = el.value; $('#m-status').textContent = STATUS_LABEL[m.status] || m.status; changed(); }));
  root.querySelectorAll('[data-mt="notes"],[data-mt="subtitle"]').forEach(el => el.addEventListener('input', () => { m[el.dataset.mt] = el.value; changed(); }));
  $('#m-tags').addEventListener('change', () => { m.tags = $('#m-tags').value.split(/[,、，]/).map(s => s.trim()).filter(Boolean); changed(); });
  $('#full-marks').addEventListener('change', () => { m.exam = { ...(m.exam || {}), total: Math.max(1, Number($('#full-marks').value) || 100) }; changed(); });
  $('#reshuffle').addEventListener('click', () => { m.print.seed = Math.floor(Math.random() * 1e9) + 1; m.print.shuffle = true; fillForm(); changed(); });

  // ---------- ブロック一覧 ----------
  const blockBody = (b) => {
    switch (b.type) {
      case 'heading': return `<div class="row"><input class="input grow" data-f="text" value="${esc(b.text)}" placeholder="見出し"><select class="input" style="width:auto" data-f="level"><option value="1">大</option><option value="2">中</option><option value="3">小</option></select></div>`;
      case 'text': return `<textarea class="input" data-f="text" rows="3" placeholder="文章（数式は $...$、下線は [[u:語句]]）">${esc(b.text)}</textarea>`;
      case 'section': return `<input class="input" data-f="title" value="${esc(b.title || '')}" placeholder="大問の見出し（任意）"><input class="input mt" data-f="inst" value="${esc(b.inst || '')}" placeholder="指示文（例：次の各問いに答えなさい。）">`;
      case 'question': {
        const cur = state.byId.get(b.ref);
        const old = cur && (cur.rev || 1) > (b.rev || 1);
        return `<div class="qtext ${texClass(b.q)}">${R().text((b.q.stem || '').slice(0, 160))}</div>
          <div class="row small mt"><span class="tag">${esc(b.q.level || '')}</span><span class="tag">${esc(b.q.unit || '')}</span>
          ${old ? '<span class="chip warn">バンクに新しい版あり</span><button class="btn sm" data-upd>更新</button>' : ''}
          ${b.q.variantOf ? '<span class="chip accent">数値替え</span>' : ''}${canVary(cur || b.q) || canVary(b.q) ? '<button class="btn sm" data-vary title="同じ問題で数値だけ変える">数値替え</button>' : ''}
          <span class="spacer"></span>配点 <input class="input" style="width:64px;display:inline-block" type="number" min="0" data-f="pts" value="${b.pts ?? ''}" placeholder="${b.q.pts ?? ''}"></div>`;
      }
      case 'table': {
        const cols = Math.max(1, (b.header || []).length);
        return `<input class="input" data-f="caption" value="${esc(b.caption || '')}" placeholder="表のタイトル（任意）">
          <textarea class="input mono mt" data-f="tsv" rows="4" placeholder="1行目が見出し。列は「｜」かタブで区切る">${esc([(b.header || []).join('｜'), ...(b.rows || []).map(r => r.join('｜'))].join('\n'))}</textarea><div class="small muted">${cols}列</div>`;
      }
      case 'image': return `${b.src ? `<img src="${esc(b.src)}" alt="" style="max-width:100%;max-height:120px">` : ''}<div class="row mt"><input type="file" accept="image/*" data-img><label class="small">幅 <input class="input" style="width:70px;display:inline-block" type="number" min="10" max="100" data-f="width" value="${b.width || 80}">%</label></div><input class="input mt" data-f="alt" value="${esc(b.alt || '')}" placeholder="画像の説明（読み上げ用）">`;
      case 'space': return `<div class="row"><input class="input grow" data-f="label" value="${esc(b.label || '')}" placeholder="欄の名前（任意。例：メモ）"><label class="small">行数 <input class="input" style="width:64px;display:inline-block" type="number" min="1" max="40" data-f="lines" value="${b.lines || 4}"></label></div>`;
      case 'pagebreak': return '<div class="small muted">ここで改ページします</div>';
      default: return '';
    }
  };
  const renderBlocks = () => {
    const ol = $('#blocks');
    ol.innerHTML = m.blocks.map((b, i) => `<li class="blk${b.type === 'question' ? ' q' : ''}" data-id="${b.id}" draggable="true">
      <div class="blk-head"><span class="handle" title="ドラッグで並べかえ">⠿</span><b>${BLOCK_LABEL[b.type] || b.type}</b>
        <span class="spacer"></span>
        ${b.type === 'question' ? '<button data-edit title="問題を編集">編集</button>' : ''}
        <button data-up title="上へ" ${i === 0 ? 'disabled' : ''}>↑</button><button data-down title="下へ" ${i === m.blocks.length - 1 ? 'disabled' : ''}>↓</button>
        <button data-dup title="複製">⧉</button><button data-del title="削除">✕</button></div>
      <div class="blk-body">${blockBody(b)}</div></li>`).join('') || '<li class="empty">まだ何もありません。上のボタンで見出し・文章・問題を足してください。</li>';
    ol.querySelectorAll('[data-f="level"]').forEach((sel) => { const b = m.blocks.find(x => x.id === sel.closest('.blk').dataset.id); sel.value = String(b.level || 2); });
    renderMath(ol);
    const n = m.blocks.filter(b => b.type === 'question').length;
    $('#m-count').textContent = `問題 ${n} 問・ブロック ${m.blocks.length} 個`;
  };
  renderBlocks();

  const blockOf = (el) => { const li = el.closest('.blk'); return li ? m.blocks.find(b => b.id === li.dataset.id) : null; };
  const ol = $('#blocks');
  ol.addEventListener('input', (e) => {
    const b = blockOf(e.target);
    const f = e.target.dataset.f;
    if (!b || !f) return;
    if (f === 'tsv') {
      const rows = e.target.value.split('\n').filter(l => l.trim()).map(l => l.split(/[｜|\t]/).map(c => c.trim()));
      b.header = rows[0] || [];
      b.rows = rows.slice(1);
    } else if (['lines', 'width', 'level'].includes(f)) b[f] = Number(e.target.value);
    else if (f === 'pts') b.pts = e.target.value === '' ? null : Number(e.target.value);
    else b[f] = e.target.value;
    changed();
  });
  ol.addEventListener('change', async (e) => {
    if (e.target.dataset.f === 'level') { const b = blockOf(e.target); b.level = Number(e.target.value); changed(); }
    if (e.target.matches('[data-img]')) {
      const file = e.target.files[0];
      if (!file) return;
      if (file.size > 2 * 1024 * 1024) { toast('画像は 2MB 以下にしてください', 'error'); return; }
      if (!/^image\/(png|jpeg|gif|webp|svg\+xml)$/.test(file.type)) { toast('PNG・JPEG・GIF・WebP・SVG の画像を選んでください', 'error'); return; }
      const b = blockOf(e.target);
      b.src = await new Promise(res => { const r = new FileReader(); r.onload = () => res(r.result); r.readAsDataURL(file); });
      changed(true);
    }
  });
  ol.addEventListener('click', async (e) => {
    const t = e.target;
    const b = blockOf(t);
    if (!b) return;
    const i = m.blocks.indexOf(b);
    if (t.matches('[data-del]')) { m.blocks.splice(i, 1); changed(true); }
    else if (t.matches('[data-up]') && i > 0) { [m.blocks[i - 1], m.blocks[i]] = [m.blocks[i], m.blocks[i - 1]]; changed(true); }
    else if (t.matches('[data-down]') && i < m.blocks.length - 1) { [m.blocks[i + 1], m.blocks[i]] = [m.blocks[i], m.blocks[i + 1]]; changed(true); }
    else if (t.matches('[data-dup]')) { m.blocks.splice(i + 1, 0, { ...clone(b), id: blockId() }); changed(true); }
    else if (t.matches('[data-vary]')) { varyOne(b); }
    else if (t.matches('[data-upd]')) { const cur = state.byId.get(b.ref); if (cur) { b.q = clone(cur); b.rev = cur.rev || 1; changed(true); } }
    else if (t.matches('[data-edit]')) {
      // バンクにある問題ならバンクの問題を編集してこの教材にも反映。単語テストなどバンク外の問題は教材の中だけで編集
      const inBank = state.byId.get(b.ref);
      const saved = inBank
        ? await editQuestion(inBank)
        : await editQuestion(b.q, { title: '問題を編集（この教材の中だけ）', onSave: async (q) => q });
      if (saved) { b.q = clone(saved); b.rev = saved.rev || 1; changed(true); }
    }
  });
  // ドラッグで並べかえ
  let dragId = null;
  ol.addEventListener('dragstart', (e) => {
    const li = e.target.closest('.blk');
    if (!li || ['INPUT', 'TEXTAREA', 'SELECT'].includes(document.activeElement.tagName)) { e.preventDefault(); return; }
    dragId = li.dataset.id;
    li.classList.add('dragging');
    e.dataTransfer.effectAllowed = 'move';
  });
  ol.addEventListener('dragover', (e) => {
    e.preventDefault();
    ol.querySelectorAll('.drop-before').forEach(x => x.classList.remove('drop-before'));
    const li = e.target.closest('.blk');
    if (li && li.dataset.id !== dragId) li.classList.add('drop-before');
  });
  ol.addEventListener('dragend', () => { ol.querySelectorAll('.dragging,.drop-before').forEach(x => x.classList.remove('dragging', 'drop-before')); });
  ol.addEventListener('drop', (e) => {
    e.preventDefault();
    const li = e.target.closest('.blk');
    if (!dragId) return;
    const from = m.blocks.findIndex(b => b.id === dragId);
    const [moved] = m.blocks.splice(from, 1);
    const to = li ? m.blocks.findIndex(b => b.id === li.dataset.id) : m.blocks.length;
    m.blocks.splice(to < 0 ? m.blocks.length : to, 0, moved);
    dragId = null;
    changed(true);
  });

  // ---------- ブロックを足す ----------
  root.querySelector('.add-row').addEventListener('click', async (e) => {
    const type = e.target.dataset.add;
    if (!type) return;
    if (type === 'words') { wordDialog(); return; }
    if (type === 'newq') {
      const saved = await editQuestion(undefined, { title: '問題を作って教材に追加' });
      if (saved) { m.blocks.push(questionBlock(saved)); changed(true); }
      return;
    }
    const nb = { id: blockId(), type };
    if (type === 'heading') Object.assign(nb, { text: '', level: 2 });
    if (type === 'text') nb.text = '';
    if (type === 'section') Object.assign(nb, { title: '', inst: '次の各問いに答えなさい。' });
    if (type === 'table') Object.assign(nb, { header: ['項目', '内容'], rows: [['', '']], caption: '' });
    if (type === 'image') Object.assign(nb, { src: '', alt: '', width: 80 });
    if (type === 'space') Object.assign(nb, { lines: 4, label: '' });
    m.blocks.push(/** @type {any} */ (nb));
    changed(true);
    const last = ol.lastElementChild;
    if (last) { last.scrollIntoView({ block: 'nearest' }); const inp = last.querySelector('input, textarea'); if (inp) inp.focus(); }
  });

  const wordDialog = () => {
    if (!state.lists.length) { toast('単語帳・用語カードのデータがありません。「設定・データ」で zip を読み込んでください', 'error'); return; }
    const groups = {};
    state.lists.forEach((l, i) => { (groups[l.group] = groups[l.group] || []).push({ l, i }); });
    const md = modal({
      title: '単語・用語テストを追加', narrow: true,
      body: `<label class="f">単語帳・用語カード<select class="input" id="w-list">${Object.entries(groups).map(([g, arr]) => `<optgroup label="${esc(g)}">${arr.map(({ l, i }) => `<option value="${i}">${esc(l.title)}（${l.items.length}）</option>`).join('')}</optgroup>`).join('')}</select></label>
        <div class="form-grid two"><label class="f">番号（から）<input class="input" type="number" id="w-from"></label><label class="f">番号（まで）<input class="input" type="number" id="w-to"></label>
        <label class="f">問題数<input class="input" type="number" id="w-count" value="20" min="1"></label>
        <label class="f">順番<select class="input" id="w-order"><option value="random">ランダム</option><option value="seq">番号順</option></select></label></div>
        <label class="f">出し方<select class="input" id="w-mode"><option value="meaning">見出し → 意味を書く</option><option value="term">意味 → 見出しを書く</option><option value="mc">見出し → 意味を4択</option><option value="mcr">意味 → 見出しを4択</option><option value="cloze">例文の空所補充</option></select></label>`,
      foot: '<button class="btn" data-close>やめる</button><button class="btn primary" id="w-go">追加する</button>',
    });
    const g = (id) => /** @type {any} */ (md.el.querySelector('#' + id));
    const setRange = () => { const l = state.lists[+g('w-list').value]; g('w-from').value = l.items[0].n; g('w-to').value = Math.min(l.items[l.items.length - 1].n, l.items[0].n + 49); };
    setRange();
    g('w-list').addEventListener('change', setRange);
    g('w-go').addEventListener('click', () => {
      const l = state.lists[+g('w-list').value];
      const qs = makeWordQuestions(l, { from: +g('w-from').value, to: +g('w-to').value, count: +g('w-count').value || 20, mode: g('w-mode').value, order: g('w-order').value });
      if (!qs.length) { toast('この範囲に使える語がありません', 'error'); return; }
      qs.forEach(q => m.blocks.push(questionBlock(q)));
      if (m.title === KINDS[m.kind]?.title) { m.title = l.title + ' テスト'; $('#m-title').value = m.title; }
      md.close();
      changed(true);
      toast(`${qs.length} 問を追加しました`, 'ok');
    });
  };

  // ---------- 見本 ----------
  const renderPreview = debounce(() => {
    const out = renderMaterial(m, state.stims);
    $('#preview').innerHTML = out.html || '<div class="paper empty-paper">ここに見本が出ます</div>';
    document.getElementById('page-css').textContent = pageCss(m);
    renderMath($('#preview'));
    fitPreview($('#preview'));
    const cnt = $('#m-count');
    if (cnt) cnt.textContent = `問題 ${out.count} 問・ブロック ${m.blocks.length} 個${out.total ? `・合計 ${out.total} 点` : ''}${m.exam && m.exam.total && out.total && out.total !== m.exam.total ? `（満点 ${m.exam.total} と一致しません）` : ''}`;
  }, 120);
  renderPreview();

  // ---------- 操作 ----------
  const doUndo = () => { if (!undo.length) return; redo.push(JSON.stringify(m)); m = JSON.parse(undo.pop()); lastSnap = JSON.stringify(m); fillForm(); renderBlocks(); renderPreview(); dirty = true; autosave(); };
  const doRedo = () => { if (!redo.length) return; undo.push(JSON.stringify(m)); m = JSON.parse(redo.pop()); lastSnap = JSON.stringify(m); fillForm(); renderBlocks(); renderPreview(); dirty = true; autosave(); };
  $('#undo').addEventListener('click', doUndo);
  $('#redo').addEventListener('click', doRedo);
  const onKey = (e) => {
    if (!(e.ctrlKey || e.metaKey)) return;
    if (['INPUT', 'TEXTAREA'].includes(document.activeElement.tagName)) return;
    if (e.key === 'z' && !e.shiftKey) { e.preventDefault(); doUndo(); }
    if (e.key === 'y' || (e.key === 'z' && e.shiftKey)) { e.preventDefault(); doRedo(); }
    if (e.key === 'p') { e.preventDefault(); doPrint('all'); }
  };
  document.addEventListener('keydown', onKey);

  const doPrint = async (part) => {
    const parts2 = part === 'all' ? undefined : [part];
    if (!m.blocks.some(b => b.type === 'question') && part !== 'questions' && part !== 'all') { toast('問題が入っていません', 'error'); return; }
    if (part !== 'all') { $('#preview').innerHTML = renderMaterial(m, state.stims, { parts: parts2 }).html; renderMath($('#preview')); }
    if (dirty) await saveMaterial(m);
    await log('印刷', m.id, `${m.title}（${part}）`);
    setTimeout(() => { printAs(printFileName(m, parts2)); if (part !== 'all') renderPreview(); }, 50);
  };
  root.querySelectorAll('[data-print]').forEach(b => b.addEventListener('click', () => doPrint(b.dataset.print)));

  $('#save-ver').addEventListener('click', async () => {
    const note = prompt('この版のメモ（任意）', '') ?? null;
    if (note === null) return;
    m = clone(await saveMaterial(m, { snapshot: true, note }));
    lastSnap = JSON.stringify(m);
    dirty = false;
    setState('版を保存しました（版 ' + m.rev + '）');
  });
  $('#ver-list').addEventListener('click', async () => {
    const vs = await materialVersions(m.id);
    const md = modal({
      title: '保存した版', narrow: true,
      body: vs.length ? `<table class="list">${vs.map(v => `<tr><td>版 ${v.rev}</td><td class="small">${fmtDate(v.savedAt, true)}<div class="muted">${esc(v.note || '')}</div></td><td><button class="btn sm" data-rv="${v.rev}">この版に戻す</button></td></tr>`).join('')}</table>` : '<p class="empty">まだ保存した版はありません。「版を保存」で残せます。</p>',
    });
    md.el.addEventListener('click', async (e) => {
      const rv = /** @type {any} */ (e.target).dataset.rv;
      if (!rv) return;
      const v = vs.find(x => String(x.rev) === rv);
      snapshot();
      m = { ...clone(v.data), rev: m.rev, id: m.id };
      fillForm(); renderBlocks(); renderPreview(); changed();
      md.close();
      toast('戻しました（元に戻すボタンで取り消せます）');
    });
  });
  $('#export-m').addEventListener('click', () => download(`${m.title}.json`, JSON.stringify({ format: 'mondai-material', version: 1, material: m }, null, 1)));
  const upAll = $('#update-all');
  if (upAll) upAll.addEventListener('click', () => {
    let n = 0;
    for (const b of outdatedBlocks(m, state.byId)) { const cur = state.byId.get(b.ref); b.q = clone(cur); b.rev = cur.rev || 1; n++; }
    upAll.closest('.notice').remove();
    changed(true);
    toast(`${n} 問を最新版にしました`, 'ok');
  });

  // ---------- 数値替え ----------
  const baseOf = (b) => { const cur = state.byId.get(b.ref); return cur && canVary(cur) ? cur : b.q; };
  const varyOne = (b) => {
    let r = varyQuestion(baseOf(b), Math.random());
    if (!r.ok) { toast('数値替えできませんでした：' + r.reason, 'error'); return; }
    const show = () => {
      const Rr = R();
      const ans = (q) => Rr.prepare([q], { labels: m.print.labels, points: 'none' })[0].ans;
      return `<div class="grid2"><div><div class="small muted">いまの問題</div><div class="notice ${texClass(b.q)}">${Rr.text(b.q.stem)}<div class="small mt">答え：${Rr.text(ans(b.q))}</div></div></div>
        <div><div class="small muted">数値替え${r.auto ? '（検算の式から自動で作成・内容を確認してください）' : '（テンプレートから作成・答えは機械で検算済み）'}</div><div class="notice ok ${texClass(r.q)}">${Rr.text(r.q.stem)}<div class="small mt">答え：${Rr.text(ans(r.q))}</div>
        ${r.q.expl ? `<div class="small muted mt">${Rr.text(r.q.expl)}</div>` : ''}</div></div></div>`;
    };
    const md = modal({ title: '数値替え', body: `<div id="vy-body">${show()}</div>`, foot: '<button class="btn" data-close>やめる</button><button class="btn" id="vy-again">別の数値で</button><button class="btn primary" id="vy-use">この問題にする</button>' });
    renderMath(md.el);
    md.el.querySelector('#vy-again').addEventListener('click', () => {
      const r2 = varyQuestion(baseOf(b), Math.random());
      if (!r2.ok) { toast(r2.reason, 'error'); return; }
      r = r2;
      md.el.querySelector('#vy-body').innerHTML = show();
      renderMath(md.el);
    });
    md.el.querySelector('#vy-use').addEventListener('click', () => {
      b.q = r.q;
      b.variant = { auto: !!r.auto, values: r.values || null };
      md.close();
      changed(true);
    });
  };
  $('#vary-all').addEventListener('click', async () => {
    const qbs = m.blocks.filter(x => x.type === 'question');
    if (!qbs.length) { toast('問題が入っていません', 'error'); return; }
    const able = qbs.filter(x => canVary(baseOf(x)));
    const ai = await import('../ai/client.js');
    const av = await ai.availability();
    const rest = qbs.length - able.length;
    const md = modal({
      title: '数値替え版を作る', narrow: true,
      body: `<p>この教材をコピーして、数値だけを変えた版を作ります（元の教材はそのまま残ります）。</p>
        <ul><li>テンプレートや検算の式から機械で作れる問題：<b>${able.length}</b> 問（答えは計算し直して確認します）</li>
        <li>機械では作れない問題：<b>${rest}</b> 問 ${av.ok ? '' : '（そのまま残します）'}</li></ul>
        ${rest && av.ok ? '<label class="check"><input type="checkbox" id="va-ai" checked> 機械で作れない問題も AI で数値替えする（独立解答・校閲で検証し、合格したものだけ使う）</label>' : ''}
        ${!av.ok && rest ? `<p class="small muted">AI を使うと、ほかの問題も数値替えできます（${esc(av.reason)}）</p>` : ''}
        <label class="f">版の名前<input class="input" id="va-label" value="B"></label>`,
      foot: '<button class="btn" data-close>やめる</button><button class="btn primary" id="va-go">作る</button>',
    });
    md.el.querySelector('#va-go').addEventListener('click', async () => {
      const label = /** @type {any} */ (md.el.querySelector('#va-label')).value.trim() || 'B';
      const useAI = !!(md.el.querySelector('#va-ai') && /** @type {any} */ (md.el.querySelector('#va-ai')).checked);
      const go = /** @type {any} */ (md.el.querySelector('#va-go'));
      go.disabled = true;
      const copy = clone(m);
      Object.assign(copy, { id: uid('M-'), title: `${m.title}（${label}版・数値替え）`, rev: 1, status: 'draft', createdAt: nowISO() });
      copy.blocks = copy.blocks.map(x => ({ ...x, id: blockId() }));
      let byRule = 0, byAI = 0, kept = 0;
      const seed = Date.now();
      for (const x of copy.blocks) {
        if (x.type !== 'question') continue;
        const r = varyQuestion(baseOf(x), `${seed}:${x.ref}`);
        if (r.ok) { x.q = r.q; x.variant = { auto: !!r.auto }; byRule++; continue; }
        if (useAI) {
          go.textContent = `AI で作成中…（${byAI + kept + 1}問目）`;
          const res = await ai.callAI('vary', { question: x.q }, '数値替え：' + (x.q.stem || '').slice(0, 30));
          if (res.ok && res.data && res.data.question) {
            const nq = { ...x.q, ...res.data.question, id: x.q.id, variantOf: x.ref };
            const v = await ai.verifyQuestion(nq, state.questions.filter(q => q.subj === x.q.subj));
            if (v.status === 'verified') { x.q = nq; x.variant = { ai: true }; byAI++; continue; }
          }
        }
        kept++;
      }
      await saveMaterial(copy);
      await log('数値替え版を作成', copy.id, `${copy.title}（機械 ${byRule}・AI ${byAI}・そのまま ${kept}）`);
      md.close();
      toast(`数値替え版を作りました（機械で ${byRule} 問${byAI ? `・AI で ${byAI} 問` : ''}・そのまま ${kept} 問）`, 'ok');
      location.hash = '#/editor/' + copy.id;
    });
  });

  if (params.get('words')) setTimeout(wordDialog, 0);
  const onResize = debounce(() => fitPreview($('#preview')), 150);
  window.addEventListener('resize', onResize);
  // 印刷のときは縮小をやめ、終わったら戻す
  let titleBeforePrint = null;
  const beforePrint = () => {
    $('#preview').style.zoom = '';
    if (!/^【/.test(document.title)) { titleBeforePrint = document.title; document.title = printFileName(m); }
  };
  const afterPrint = () => {
    fitPreview($('#preview'));
    if (titleBeforePrint) { document.title = titleBeforePrint; titleBeforePrint = null; }
  };
  window.addEventListener('beforeprint', beforePrint);
  window.addEventListener('afterprint', afterPrint);

  return () => {
    window.removeEventListener('beforeunload', beforeUnload);
    window.removeEventListener('resize', onResize);
    window.removeEventListener('beforeprint', beforePrint);
    window.removeEventListener('afterprint', afterPrint);
    document.removeEventListener('keydown', onKey);
    if (dirty) saveMaterial(m);
    document.getElementById('page-css').textContent = '';
  };
}

/** 新しい教材：テンプレートを選ぶ */
function newDialog(root, preset) {
  const make = async (kind) => {
    const m = newMaterial(kind, { id: uid('M-'), now: nowISO() });
    await saveMaterial(m);
    await setCurrentMaterial(m.id);
    location.replace('#/editor/' + m.id + (kind === 'wordtest' ? '?words=1' : ''));
  };
  if (preset && KINDS[preset]) { make(preset); return; }
  root.innerHTML = `<div class="page-head"><div class="grow"><h1>新しい教材</h1><p>種類（テンプレート）を選ぶと、用紙や解答欄の初期設定が入ります。あとから変えられます。</p></div></div>
    <div class="stats">${Object.entries(KINDS).map(([k, d]) => `<button class="stat" style="text-align:left;cursor:pointer" data-kind="${k}"><b style="font-size:16px">${esc(d.label)}</b><span>${esc(KIND_DESC[k] || '')}</span></button>`).join('')}</div>`;
  root.addEventListener('click', (e) => { const k = /** @type {any} */ (e.target).closest('[data-kind]'); if (k) make(k.dataset.kind); });
}

const KIND_DESC = {
  worksheet: 'ねらい・説明・練習問題の授業用', summary: '要点を整理するまとめプリント', self: '解答つきで自分で進める', review: '苦手な単元のふり返り',
  drill: '問題をたくさん並べる演習', memorize: '用語・語句の確認', wordtest: '単語帳から自動で作る', quiz: '10〜20分の確認テスト',
  unit: '単元の理解度テスト', test: '定期テスト（別紙解答用紙つき）', ability: '複数単元の実力テスト', mock: '本番形式の模擬試験',
  entrance: '入試の形式に合わせた演習', answers: '解答と解説をまとめた冊子', material: '授業で配る資料',
  kanagawa: '問1・(ア)の番号、番号の選択肢、あいうの数値マーク、マークシート、表紙つき', kyotsu: '第1問・問1、①〜の選択肢、解答番号とアイウの数値マーク、マークシート、表紙つき',
  niji: '第1問・(1)の記述式、大問ごとの解答用紙、表紙つき',
};
