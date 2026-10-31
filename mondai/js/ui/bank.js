// 問題バンク：検索・登録・編集・削除・複製・一括操作・入出力・類似検出・版管理
import { state, saveQuestion, saveQuestions, deleteQuestions, questionVersions, revertToOriginal, log } from '../core/store.js';
import { esc, toast, download, pickFiles, fmtDate, on, shuffle, clone } from '../core/util.js';
import { duplicateQuestion, normalizeQuestion, newQuestion, validateQuestion, LEVELS, STATUSES } from '../domain/question.js';
import { parseQuery, matchQuery } from '../domain/search.js';
import { buildIndex, findSimilarIndexed, findDuplicateGroups } from '../domain/similarity.js';
import { questionsToCSV, csvToQuestions } from '../domain/csv.js';
import { modal, questionTags, questionDetail, texClass, renderMath, addToCurrentMaterial, removeFromCurrentMaterial, currentRefs, TYPE_LABEL } from './common.js';
import { editQuestion } from './qeditor.js';

const PAGE_SIZE = 30;
const FACETS = [
  ['subj', '教科'], ['stage', '段階'], ['grade', '学年'], ['course', '科目'],
  ['level', '難易度'], ['type', '形式'], ['src', '出典'], ['cat', '区分'],
];
const ORDER = {
  stage: ['小学', '中学', '高校'],
  grade: ['小1', '小2', '小3', '小4', '小5', '小6', '小3-4', '中1', '中2', '中3', '中1-2', '中1-3', '高1', '高2', '高3'],
  level: LEVELS,
  subj: ['国語', '数学', '英語', '理科', '社会', '情報', '音楽', '教科横断'],
};
const VIEWS = {
  normal: '通常（承認待ちの AI 生成を除く）', all: 'すべて', mine: '自作・編集した問題', pending: '承認待ちの AI 生成', needs_fix: '要修正', approved: '人間承認済み',
};

/** 画面をまたいで条件を覚えておく */
const mem = { f: {}, units: new Set(), q: '', view: 'normal', page: 0 };

export async function render(root, _parts, params) {
  if (params.get('status') === 'pending') mem.view = 'pending';
  if (params.get('status') === 'needs_fix') mem.view = 'needs_fix';
  let selected = new Set();
  let filtered = [];
  let inMat = await currentRefs();

  root.innerHTML = `
  <div class="page-head"><div class="grow"><h1>問題バンク</h1><p id="bank-sub"></p></div>
    <button class="btn primary" id="new-q">＋ 問題を登録</button>
    <button class="btn" id="import-q">取り込み（JSON / CSV）</button>
    <button class="btn" id="export-q">書き出し</button>
    <button class="btn" id="dup-check">重複チェック</button>
  </div>
  <div class="side-layout">
    <aside class="card">
      <h2>しぼりこみ <span class="chip accent" id="f-count"></span></h2>
      <label class="f">キーワード・検索式<input class="input" id="f-q" placeholder="例：二次関数 最大 -証明 level:標準"></label>
      <details class="small muted" style="margin:-4px 0 8px"><summary>検索式の書き方</summary>
        <div>・スペース区切り＝すべて含む（AND）<br>・<code>A OR B</code>＝どちらか<br>・<code>-語</code>＝含まない<br>・<code>"語句"</code>＝そのままの並び<br>・<code>subj:数学 course:数学Ⅰ grade:高1 unit:二次関数 level:標準 type:choice src:内蔵 tag:頻出 status:approved</code><br>・かっこでまとめられます</div></details>
      <label class="f">表示<select class="input" id="f-view">${Object.entries(VIEWS).map(([k, l]) => `<option value="${k}">${esc(l)}</option>`).join('')}</select></label>
      ${FACETS.slice(0, 4).map(([k, l]) => `<label class="f">${l}<select class="input" data-facet="${k}"></select></label>`).join('')}
      <div class="f">単元 <span class="muted" id="unit-sum">すべての単元</span> <button class="btn ghost sm" id="unit-clear" hidden>解除</button><div class="checklist" id="f-unit"></div></div>
      ${FACETS.slice(4).map(([k, l]) => `<label class="f">${l}<select class="input" data-facet="${k}"></select></label>`).join('')}
      <label class="f">タグ<select class="input" id="f-tag"></select></label>
      <button class="btn sm" id="f-reset">条件をリセット</button>
      <h2 class="mt">ランダムに追加</h2>
      <p class="small muted">いまの条件から、作業中の教材にまだ入っていない問題を選びます。</p>
      <div class="form-grid two">
        <label class="f">基礎<input class="input" type="number" min="0" value="0" id="r-基礎"></label>
        <label class="f">標準<input class="input" type="number" min="0" value="0" id="r-標準"></label>
        <label class="f">応用<input class="input" type="number" min="0" value="0" id="r-応用"></label>
        <label class="f">指定なし<input class="input" type="number" min="0" value="10" id="r-any"></label>
      </div>
      <button class="btn primary" id="r-add">ランダムに追加</button>
    </aside>
    <div>
      <div class="bulkbar row" id="bulk" hidden>
        <b id="bulk-n"></b><span class="spacer"></span>
        <button class="btn sm primary" data-bulk="add">教材に追加</button>
        <button class="btn sm" data-bulk="edit">一括編集</button>
        <button class="btn sm" data-bulk="approve">承認</button>
        <button class="btn sm" data-bulk="export">書き出し</button>
        <button class="btn sm danger" data-bulk="delete">削除</button>
        <button class="btn sm ghost" data-bulk="clear">選択を解除</button>
      </div>
      <div class="row" style="margin-bottom:8px"><b id="result-count"></b><span class="spacer"></span>
        <label class="check" style="margin:0"><input type="checkbox" id="sel-page"> このページを選択</label>
        <button class="btn sm" id="add-page">このページを教材に追加</button></div>
      <ol class="qlist" id="qlist"></ol>
      <div class="pager" id="pager"></div>
    </div>
  </div>`;

  const $ = (id) => /** @type {any} */ (root.querySelector('#' + id));
  $('f-q').value = mem.q;
  $('f-view').value = mem.view;

  // ---------- しぼりこみ ----------
  const viewOk = (q) => {
    switch (mem.view) {
      case 'normal': return !(q.origin === 'ai' && q.status !== 'approved');
      case 'mine': return q.origin === 'user' || q.origin === 'ai' || (state.base.has(q.id) && state.user.has(q.id));
      case 'pending': return q.origin === 'ai' && q.status !== 'approved';
      case 'needs_fix': return q.status === 'needs_fix';
      case 'approved': return q.status === 'approved';
      default: return true;
    }
  };
  let ast = null;
  const parse = () => { try { ast = mem.q.trim() ? parseQuery(mem.q) : null; } catch (e) { ast = null; } };
  parse();
  const unitOf = (q) => q.unit || q.set || '';
  const matches = (q, except) => {
    if (!viewOk(q)) return false;
    for (const [k] of FACETS) if (k !== except && mem.f[k] && (q[k] || '') !== mem.f[k]) return false;
    if (except !== 'tag' && mem.f.tag && !(q.tags || []).includes(mem.f.tag)) return false;
    if (except !== 'unit' && mem.units.size && !mem.units.has(unitOf(q))) return false;
    if (ast && !matchQuery(ast, q)) return false;
    return true;
  };

  const buildFacets = () => {
    for (const [key, label] of FACETS) {
      const sel = root.querySelector(`[data-facet="${key}"]`);
      const counts = new Map();
      for (const q of state.questions) {
        if (!matches(q, key)) continue;
        const v = q[key];
        if (v) counts.set(v, (counts.get(v) || 0) + 1);
      }
      const vals = [...counts.keys()].sort((a, b) => {
        const o = ORDER[key];
        if (o) { const ia = o.indexOf(a), ib = o.indexOf(b); if (ia !== ib) return (ia < 0 ? 99 : ia) - (ib < 0 ? 99 : ib); }
        return String(a).localeCompare(String(b), 'ja', { numeric: true });
      });
      const show = (v) => (key === 'type' ? TYPE_LABEL[v] || v : v);
      sel.innerHTML = `<option value="">すべての${label}</option>` + vals.map(v => `<option value="${esc(v)}">${esc(show(v))}（${counts.get(v)}）</option>`).join('');
      if (mem.f[key] && !counts.has(mem.f[key])) delete mem.f[key];
      sel.value = mem.f[key] || '';
    }
    // タグ
    const tagCounts = new Map();
    for (const q of state.questions) if (matches(q, 'tag')) (q.tags || []).forEach(t => tagCounts.set(t, (tagCounts.get(t) || 0) + 1));
    $('f-tag').innerHTML = '<option value="">すべてのタグ</option>' + [...tagCounts].sort((a, b) => b[1] - a[1]).map(([t, n]) => `<option value="${esc(t)}">${esc(t)}（${n}）</option>`).join('');
    $('f-tag').value = tagCounts.has(mem.f.tag) ? mem.f.tag : '';
    // 単元（複数選択）
    const uc = new Map(), uord = new Map();
    for (const q of state.questions) {
      if (!matches(q, 'unit')) continue;
      const u = unitOf(q);
      if (!u) continue;
      uc.set(u, (uc.get(u) || 0) + 1);
      if (q.uord && (!uord.has(u) || q.uord < uord.get(u))) uord.set(u, q.uord);
    }
    for (const u of [...mem.units]) if (!uc.has(u)) mem.units.delete(u);
    const units = [...uc.keys()].sort((a, b) => { const oa = uord.get(a) || '~' + a, ob = uord.get(b) || '~' + b; return oa < ob ? -1 : oa > ob ? 1 : 0; }).slice(0, 800);
    const box = $('f-unit'), top = box.scrollTop;
    box.innerHTML = units.map(u => `<label class="uc${mem.units.has(u) ? ' on' : ''}"><input type="checkbox" value="${esc(u)}"${mem.units.has(u) ? ' checked' : ''}><span>${esc(u)}</span><span class="n">${uc.get(u)}</span></label>`).join('') || '<p class="small muted">（該当なし）</p>';
    box.scrollTop = top;
    $('unit-sum').textContent = mem.units.size ? `${mem.units.size}個えらび中` : 'すべての単元';
    $('unit-clear').hidden = !mem.units.size;
  };

  const apply = (keepPage = false) => {
    filtered = state.questions.filter(q => matches(q));
    if (!keepPage) mem.page = 0;
    renderList();
  };

  // ---------- 一覧 ----------
  const renderList = () => {
    const total = filtered.length;
    const pages = Math.max(1, Math.ceil(total / PAGE_SIZE));
    mem.page = Math.min(mem.page, pages - 1);
    const rows = filtered.slice(mem.page * PAGE_SIZE, (mem.page + 1) * PAGE_SIZE);
    $('bank-sub').textContent = `全 ${state.questions.length.toLocaleString()} 問`;
    $('result-count').textContent = `${total.toLocaleString()} 問`;
    $('f-count').textContent = `${total.toLocaleString()} 問`;
    $('qlist').innerHTML = rows.map(q => {
      const on = inMat.has(q.id);
      return `<li class="qrow${on ? ' on' : ''}" data-id="${esc(q.id)}">
        <input type="checkbox" class="sel" data-sel="${esc(q.id)}" ${selected.has(q.id) ? 'checked' : ''} aria-label="選択">
        <div class="qmain">
          <div class="tags">${questionTags(q)}<span class="unit">${esc([unitOf(q), q.subunit].filter(Boolean).join(' › '))}</span></div>
          <div class="qstem ${texClass(q)}">${/** @type {any} */ (globalThis).Render.text(q.stem)}</div>
          <details><summary>選択肢・答え・解説</summary><div class="${texClass(q)}">${questionDetail(q)}</div></details>
        </div>
        <div class="qactions">
          <button class="btn sm ${on ? '' : 'primary'}" data-act="toggle">${on ? '✓ 追加済み' : '＋ 追加'}</button>
          <button class="btn sm" data-act="edit">編集</button>
          <button class="btn sm" data-act="dup">複製</button>
          <button class="btn sm" data-act="similar">類似</button>
          <button class="btn sm" data-act="history">履歴</button>
          <button class="btn sm danger" data-act="delete">削除</button>
        </div></li>`;
    }).join('') || `<li class="empty">条件に合う問題がありません。${mem.view === 'pending' ? '<br>AI で作った問題で、まだ承認していないものがここに出ます。' : ''}</li>`;
    renderMath($('qlist'));
    let p = '';
    if (pages > 1) p = `<button class="btn sm" ${mem.page === 0 ? 'disabled' : ''} data-page="${mem.page - 1}">← 前</button><span>${mem.page + 1} / ${pages}</span><button class="btn sm" ${mem.page >= pages - 1 ? 'disabled' : ''} data-page="${mem.page + 1}">次 →</button>`;
    $('pager').innerHTML = p;
    $('sel-page').checked = rows.length > 0 && rows.every(q => selected.has(q.id));
    renderBulk();
  };
  const renderBulk = () => {
    $('bulk').hidden = !selected.size;
    $('bulk-n').textContent = `${selected.size} 問を選択中`;
  };

  buildFacets();
  apply(true);

  // ---------- イベント ----------
  let qTimer;
  $('f-q').addEventListener('input', () => { clearTimeout(qTimer); qTimer = setTimeout(() => { mem.q = $('f-q').value; parse(); buildFacets(); apply(); }, 250); });
  $('f-view').addEventListener('change', () => { mem.view = $('f-view').value; buildFacets(); apply(); });
  root.querySelectorAll('[data-facet]').forEach(sel => sel.addEventListener('change', () => { mem.f[sel.getAttribute('data-facet')] = /** @type {any} */ (sel).value; buildFacets(); apply(); }));
  $('f-tag').addEventListener('change', () => { mem.f.tag = $('f-tag').value; buildFacets(); apply(); });
  $('f-unit').addEventListener('change', (e) => { const v = e.target.value; if (e.target.checked) mem.units.add(v); else mem.units.delete(v); buildFacets(); apply(); });
  $('unit-clear').addEventListener('click', () => { mem.units.clear(); buildFacets(); apply(); });
  $('f-reset').addEventListener('click', () => { mem.f = {}; mem.units.clear(); mem.q = ''; $('f-q').value = ''; mem.view = 'normal'; $('f-view').value = 'normal'; parse(); buildFacets(); apply(); });
  $('pager').addEventListener('click', (e) => { const p = e.target.dataset.page; if (p == null) return; mem.page = +p; renderList(); window.scrollTo(0, 0); });

  $('qlist').addEventListener('change', (e) => {
    const id = e.target.dataset.sel;
    if (!id) return;
    if (e.target.checked) selected.add(id); else selected.delete(id);
    renderBulk();
  });
  $('sel-page').addEventListener('change', () => {
    const rows = filtered.slice(mem.page * PAGE_SIZE, (mem.page + 1) * PAGE_SIZE);
    rows.forEach(q => { if ($('sel-page').checked) selected.add(q.id); else selected.delete(q.id); });
    renderList();
  });

  $('qlist').addEventListener('click', async (e) => {
    const btn = e.target.closest('[data-act]');
    if (!btn) return;
    const id = btn.closest('.qrow').getAttribute('data-id');
    const q = state.byId.get(id);
    if (!q) return;
    switch (btn.dataset.act) {
      case 'toggle':
        if (inMat.has(id)) { await removeFromCurrentMaterial(id); inMat.delete(id); toast('教材からはずしました'); }
        else { await addToCurrentMaterial([q]); inMat.add(id); toast('作業中の教材に追加しました'); }
        renderList();
        break;
      case 'edit': {
        const saved = await editQuestion(q);
        if (saved) { toast('保存しました（版 ' + saved.rev + '）', 'ok'); buildFacets(); apply(true); }
        break;
      }
      case 'dup': {
        const copy = duplicateQuestion(q);
        const saved = await editQuestion(copy, { title: '問題を複製', saveLabel: '複製を保存' });
        if (saved) { toast('複製しました', 'ok'); buildFacets(); apply(true); }
        break;
      }
      case 'similar': showSimilar(q); break;
      case 'history': showHistory(q); break;
      case 'delete':
        if (!confirm(state.base.has(id) ? 'この問題を非表示にしますか？（内蔵・取り込みの問題は「設定・データ」から元に戻せます）' : 'この問題を削除しますか？（旧版の記録は残ります）')) return;
        await deleteQuestions([id]);
        selected.delete(id);
        toast('削除しました');
        buildFacets(); apply(true);
        break;
    }
  });

  $('add-page').addEventListener('click', async () => {
    const rows = filtered.slice(mem.page * PAGE_SIZE, (mem.page + 1) * PAGE_SIZE);
    const r = await addToCurrentMaterial(rows);
    inMat = await currentRefs();
    toast(`${r.added} 問を追加しました`, 'ok');
    renderList();
  });

  $('r-add').addEventListener('click', async () => {
    const pool = shuffle(filtered.filter(q => !inMat.has(q.id)));
    const want = { 基礎: +$('r-基礎').value || 0, 標準: +$('r-標準').value || 0, 応用: +$('r-応用').value || 0 };
    let any = +$('r-any').value || 0;
    const picked = [], used = new Set();
    for (const lv of LEVELS) for (const q of pool) { if (want[lv] <= 0) break; if (q.level === lv && !used.has(q.id)) { picked.push(q); used.add(q.id); want[lv]--; } }
    for (const q of pool) { if (any <= 0) break; if (!used.has(q.id)) { picked.push(q); used.add(q.id); any--; } }
    const rank = { 基礎: 0, 標準: 1, 応用: 2 };
    picked.sort((a, b) => (rank[a.level] ?? 1) - (rank[b.level] ?? 1));
    const r = await addToCurrentMaterial(picked);
    inMat = await currentRefs();
    const short = Object.values(want).reduce((a, b) => a + b, 0) + any;
    toast(`${r.added} 問を追加しました` + (short > 0 ? `（条件に合う問題が足りず ${short} 問少なめ）` : ''), 'ok');
    renderList();
  });

  // ---------- 一括操作 ----------
  $('bulk').addEventListener('click', async (e) => {
    const act = e.target.dataset.bulk;
    if (!act) return;
    const list = [...selected].map(id => state.byId.get(id)).filter(Boolean);
    if (act === 'clear') { selected.clear(); renderList(); return; }
    if (act === 'add') { const r = await addToCurrentMaterial(list); inMat = await currentRefs(); toast(`${r.added} 問を追加しました`, 'ok'); renderList(); return; }
    if (act === 'export') { exportDialog(list); return; }
    if (act === 'approve') {
      if (!confirm(`${list.length} 問を「人間承認済み」にします。内容を確認しましたか？`)) return;
      await saveQuestions(list.map(q => ({ ...q, status: 'approved' })), '一括承認');
      toast('承認しました', 'ok'); buildFacets(); apply(true); return;
    }
    if (act === 'delete') {
      if (!confirm(`${list.length} 問を削除（内蔵・取り込みの問題は非表示）しますか？`)) return;
      await deleteQuestions(list.map(q => q.id));
      selected.clear(); toast('削除しました'); buildFacets(); apply(true); return;
    }
    if (act === 'edit') bulkEdit(list);
  });

  const bulkEdit = (list) => {
    const m = modal({
      title: `${list.length} 問を一括編集`, narrow: true,
      body: `<p class="small muted">入力した項目だけを書きかえます（空欄の項目は変えません）。</p>
        <div class="form-grid two">
          <label class="f">難易度<select class="input" name="level"><option value="">（変えない）</option>${LEVELS.map(l => `<option>${l}</option>`).join('')}</select></label>
          <label class="f">検証状態<select class="input" name="status"><option value="">（変えない）</option>${Object.entries(STATUSES).map(([k, l]) => `<option value="${k}">${esc(l)}</option>`).join('')}</select></label>
          <label class="f">教科<input class="input" name="subj"></label><label class="f">科目<input class="input" name="course"></label>
          <label class="f">学年<input class="input" name="grade"></label><label class="f">単元<input class="input" name="unit"></label>
          <label class="f">小単元<input class="input" name="subunit"></label><label class="f">配点<input class="input" type="number" name="pts" min="0"></label>
        </div>
        <label class="f">タグを追加（読点区切り）<input class="input" name="addTags"></label>
        <label class="f">タグを削除（読点区切り）<input class="input" name="rmTags"></label>`,
      foot: '<button class="btn" data-close>やめる</button><button class="btn primary" id="be-save">書きかえる</button>',
    });
    m.el.querySelector('#be-save').addEventListener('click', async () => {
      const g = (n) => /** @type {any} */ (m.el.querySelector(`[name=${n}]`)).value.trim();
      const split = (s) => s.split(/[,、，]/).map(x => x.trim()).filter(Boolean);
      const add = split(g('addTags')), rm = split(g('rmTags'));
      const next = list.map(q => {
        const n = clone(q);
        for (const k of ['level', 'status', 'subj', 'course', 'grade', 'unit', 'subunit']) if (g(k)) n[k] = g(k);
        if (g('pts') !== '') n.pts = Number(g('pts'));
        n.tags = [...new Set([...(n.tags || []).filter(t => !rm.includes(t)), ...add])];
        return n;
      });
      await saveQuestions(next, '一括編集');
      m.close();
      toast(`${next.length} 問を書きかえました`, 'ok');
      buildFacets(); apply(true);
    });
  };

  // ---------- 書き出し・取り込み ----------
  const exportDialog = (list) => {
    const m = modal({
      title: `${list.length.toLocaleString()} 問を書き出す`, narrow: true,
      body: '<p>形式を選んでください。JSON はすべての項目を含み、そのまま取り込み直せます。CSV は表計算ソフトで編集できます。</p>',
      foot: '<button class="btn" data-close>やめる</button><button class="btn" id="ex-csv">CSV</button><button class="btn primary" id="ex-json">JSON</button>',
    });
    m.el.querySelector('#ex-json').addEventListener('click', () => { download('問題.json', JSON.stringify({ format: 'mondai-questions', version: 1, questions: list }, null, 1)); log('問題を書き出し', `${list.length}問`, 'JSON'); m.close(); });
    m.el.querySelector('#ex-csv').addEventListener('click', () => { download('問題.csv', '﻿' + questionsToCSV(list), 'text/csv'); log('問題を書き出し', `${list.length}問`, 'CSV'); m.close(); });
  };
  $('export-q').addEventListener('click', () => exportDialog(filtered));

  $('import-q').addEventListener('click', async () => {
    const [f] = await pickFiles('.json,.csv,application/json,text/csv');
    if (!f) return;
    const text = (await f.text()).replace(/^﻿/, '');
    let qs = [], errors = [];
    try {
      if (/\.csv$/i.test(f.name)) ({ questions: qs, errors } = csvToQuestions(text));
      else {
        const d = JSON.parse(text);
        qs = Array.isArray(d) ? d : d.questions || [];
      }
    } catch (e) { toast('ファイルを読めませんでした：' + e.message, 'error'); return; }
    const ok = [], bad = [...errors.map(e => `${e.row}行目：${e.message}`)];
    qs.forEach((q, i) => {
      const n = normalizeQuestion({ ...newQuestion({}), ...q, origin: q.origin === 'ai' ? 'ai' : 'user' });
      if (!q.id || state.base.has(q.id) === false) n.id = q.id || n.id;
      const v = validateQuestion(n);
      if (v.ok) ok.push(n); else bad.push(`${i + 1}問目：${v.errors[0].message}`);
    });
    const m = modal({
      title: '問題の取り込み', narrow: true,
      body: `<p>${esc(f.name)}：取り込める問題 <b>${ok.length}</b> 問、取り込めない問題 ${bad.length} 問</p>
        ${bad.length ? `<details><summary>取り込めない理由</summary><ul class="err-list">${bad.slice(0, 50).map(b => `<li>${esc(b)}</li>`).join('')}</ul></details>` : ''}
        <p class="small muted">同じ ID の問題があるときは、旧版を残して上書きします。</p>`,
      foot: `<button class="btn" data-close>やめる</button><button class="btn primary" id="im-go" ${ok.length ? '' : 'disabled'}>取り込む</button>`,
    });
    m.el.querySelector('#im-go').addEventListener('click', async () => {
      await saveQuestions(ok, `取り込み：${f.name}`);
      m.close();
      toast(`${ok.length} 問を取り込みました`, 'ok');
      buildFacets(); apply();
    });
  });

  // ---------- 類似・重複 ----------
  let index = null;
  const getIndex = () => (index = index || buildIndex(state.questions));
  const showSimilar = (q) => {
    const res = findSimilarIndexed(getIndex(), q, { limit: 15, minScore: 0.5 });
    const kindLabel = { exact: '完全一致', numeric_variant: '数値だけ違う', similar: '似ている' };
    const m = modal({
      title: '似ている問題',
      body: `<div class="notice small">文字の一致・数値を除いた形・単元・形式などから候補を出しています。<b>自動では削除しません</b>。必要なら各問題を編集・削除してください。</div>
        <div class="qrow"><div class="qmain"><div class="small muted">対象</div><div class="${texClass(q)}">${/** @type {any} */ (globalThis).Render.text(q.stem)}</div></div></div>
        ${res.length ? res.map(r => `<div class="qrow"><div class="qmain"><div class="tags"><span class="chip ${r.kind === 'exact' ? 'danger' : r.kind === 'numeric_variant' ? 'warn' : 'accent'}">${kindLabel[r.kind] || r.kind}</span><span class="tag">類似度 ${(r.score * 100).toFixed(0)}%</span>${questionTags(r.q)}</div>
          <div class="${texClass(r.q)}">${/** @type {any} */ (globalThis).Render.text(r.q.stem)}</div><div class="small muted">${esc((r.reasons || []).join('・'))}</div></div>
          <div class="qactions"><button class="btn sm" data-edit="${esc(r.q.id)}">編集</button></div></div>`).join('') : '<p class="empty">似ている問題は見つかりませんでした。</p>'}`,
    });
    renderMath(m.el);
    m.el.addEventListener('click', async (e) => {
      const id = /** @type {any} */ (e.target).dataset.edit;
      if (!id) return;
      m.close();
      const saved = await editQuestion(state.byId.get(id));
      if (saved) { buildFacets(); apply(true); }
    });
  };
  $('dup-check').addEventListener('click', () => {
    if (filtered.length > 6000 && !confirm(`${filtered.length.toLocaleString()} 問を調べます。少し時間がかかります。続けますか？（教科などでしぼると速くなります）`)) return;
    const groups = findDuplicateGroups(filtered, {});
    const kindLabel = { exact: '完全一致', numeric_variant: '数値だけ違う' };
    const m = modal({
      title: `重複の候補（${groups.length} 組）`,
      body: `<div class="notice small">いまの条件の ${filtered.length.toLocaleString()} 問を調べました。<b>自動では削除しません</b>。残す問題を決めて、不要なものだけ削除してください。</div>
        ${groups.slice(0, 100).map((g, gi) => `<div class="card"><h3>${gi + 1}. ${kindLabel[g.kind] || g.kind}（${g.questions.length}問）</h3>
          ${g.questions.map(q => `<div class="row" style="align-items:flex-start;margin-bottom:6px"><div class="grow ${texClass(q)}"><span class="tag">${esc(q.src || '')}</span> ${/** @type {any} */ (globalThis).Render.text((q.stem || '').slice(0, 140))}</div><button class="btn sm danger" data-del="${esc(q.id)}">削除</button></div>`).join('')}</div>`).join('') || '<p class="empty">重複の候補はありませんでした。</p>'}`,
    });
    renderMath(m.el);
    m.el.addEventListener('click', async (e) => {
      const t = /** @type {any} */ (e.target);
      if (!t.dataset.del) return;
      if (!confirm('この問題を削除しますか？')) return;
      await deleteQuestions([t.dataset.del]);
      t.closest('.row').remove();
      toast('削除しました');
      buildFacets(); apply(true);
    });
  });

  // ---------- 版の履歴 ----------
  const showHistory = async (q) => {
    const versions = await questionVersions(q.id);
    const edited = state.base.has(q.id) && state.user.has(q.id);
    const m = modal({
      title: '変更の履歴',
      body: `<p>現在：版 ${q.rev || 1}${q.updatedAt ? '（' + fmtDate(q.updatedAt, true) + '）' : ''}${edited ? '　<span class="chip warn">元データから編集済み</span>' : ''}</p>
        ${versions.length ? `<table class="list">${versions.map(v => `<tr><td>版 ${v.rev}</td><td class="small">${fmtDate(v.savedAt, true)}<div class="muted">${esc(v.note || '')}</div></td>
          <td class="${texClass(v.data)}" style="max-width:420px">${/** @type {any} */ (globalThis).Render.text((v.data.stem || '').slice(0, 120))}</td><td><button class="btn sm" data-restore="${v.rev}">この版に戻す</button></td></tr>`).join('')}</table>` : '<p class="empty">旧版はありません。</p>'}`,
      foot: edited ? '<button class="btn danger" id="revert">元データの内容に戻す</button>' : '',
    });
    renderMath(m.el);
    m.el.addEventListener('click', async (e) => {
      const t = /** @type {any} */ (e.target);
      if (t.dataset.restore) {
        const v = versions.find(x => String(x.rev) === t.dataset.restore);
        await saveQuestion({ ...v.data, id: q.id }, `版 ${v.rev} に戻す`);
        m.close(); toast('戻しました', 'ok'); buildFacets(); apply(true);
      }
      if (t.id === 'revert') {
        if (!confirm('編集を取り消して、内蔵・取り込み時の内容に戻しますか？')) return;
        await revertToOriginal(q.id);
        m.close(); toast('元に戻しました', 'ok'); buildFacets(); apply(true);
      }
    });
  };

  // ---------- 登録 ----------
  $('new-q').addEventListener('click', async () => {
    const preset = { subj: mem.f.subj, course: mem.f.course, grade: mem.f.grade, unit: mem.units.size === 1 ? [...mem.units][0] : '' };
    const base = newQuestion({ ...preset, type: 'choice', choices: ['', '', '', ''], ai: [0], level: mem.f.level || '標準' });
    const saved = await editQuestion(base, { title: '問題を登録' });
    if (saved) { toast('登録しました', 'ok'); index = null; buildFacets(); apply(true); }
  });

  // 他画面からの指定（#/bank?id=… / ?new=1）
  if (params.get('new')) $('new-q').click();
  if (params.get('id')) { const q = state.byId.get(params.get('id')); if (q) editQuestion(q).then(s => { if (s) { buildFacets(); apply(true); } }); }

  const off = on('questions', () => { index = null; });
  return () => off();
}
