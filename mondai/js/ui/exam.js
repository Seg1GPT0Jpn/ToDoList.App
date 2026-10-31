// テスト制作：条件から問題を自動で選び、配点をそろえ、複数の版を作る
import { state, saveMaterial, setCurrentMaterial, log } from '../core/store.js';
import { esc, uid, nowISO, toast } from '../core/util.js';
import { buildExam, allocatePoints, validatePoints, makeVersions } from '../domain/exam.js';
import { newMaterial, questionBlock, blockId } from '../domain/material.js';
import { LEVELS } from '../domain/question.js';
import { renderMath, texClass, R, TYPE_LABEL } from './common.js';

const KINDS = { quiz: '小テスト', unit: '単元テスト', test: '定期テスト', ability: '実力テスト', mock: '模擬試験', entrance: '入試形式', ability2: '総合確認テスト' };
const mem = {
  subj: '', course: '', units: new Set(), src: '', kind: 'test', title: '', time: 50, total: 100, count: 20,
  sections: [], level: { 基礎: 3, 標準: 5, 応用: 2 }, type: { choice: 0, short: 0, written: 0 }, excludeTags: '', preferUnused: true, versions: 1, pointsMode: 'weighted', seed: 1,
};

export async function render(root) {
  root.innerHTML = `
  <div class="page-head"><div class="grow"><h1>テスト制作</h1><p>範囲と条件を決めると、問題バンクから自動で問題を選びます。選んだあとは教材制作で自由に直せます。</p></div></div>
  <div class="side-layout">
    <aside class="card">
      <h2>出題範囲</h2>
      <label class="f">教科<select class="input" id="x-subj"></select></label>
      <label class="f">科目<select class="input" id="x-course"></select></label>
      <div class="f">単元（複数可） <button class="btn ghost sm" id="x-unit-all">すべて解除</button><div class="checklist" id="x-units"></div></div>
      <label class="f">出典<select class="input" id="x-src"></select></label>
      <label class="f">除外するタグ（読点区切り）<input class="input" id="x-extags"></label>
      <label class="check"><input type="checkbox" id="x-unused"> ほかの教材で使っていない問題を優先</label>
      <p class="small muted" id="x-pool"></p>
    </aside>
    <div>
      <section class="card">
        <h2>テストの条件</h2>
        <div class="form-grid">
          <label class="f">種類<select class="input" id="x-kind">${Object.entries(KINDS).map(([k, l]) => `<option value="${k}">${l}</option>`).join('')}</select></label>
          <label class="f">タイトル<input class="input" id="x-title" placeholder="例：1学期中間テスト"></label>
          <label class="f">試験時間（分）<input class="input" type="number" min="1" id="x-time"></label>
          <label class="f">満点<input class="input" type="number" min="1" id="x-total"></label>
          <label class="f">問題数（大問を使わないとき）<input class="input" type="number" min="1" id="x-count"></label>
          <label class="f">版の数（A・B…）<select class="input" id="x-versions"><option>1</option><option>2</option><option>3</option><option>4</option></select></label>
          <label class="f">配点の付け方<select class="input" id="x-pmode"><option value="weighted">難易度・記述に重み</option><option value="equal">すべて同じ</option></select></label>
        </div>
        <h3>難易度の割合（基礎・標準・応用）</h3>
        <div class="form-grid">${LEVELS.map(l => `<label class="f">${l}<input class="input" type="number" min="0" data-lv="${l}"></label>`).join('')}</div>
        <h3>形式の割合（すべて0なら指定なし。記述を増やすと思考力問題が増えます）</h3>
        <div class="form-grid"><label class="f">選択<input class="input" type="number" min="0" data-ty="choice"></label><label class="f">答えのみ<input class="input" type="number" min="0" data-ty="short"></label><label class="f">記述<input class="input" type="number" min="0" data-ty="written"></label></div>
        <h3>大問の構成（任意）</h3>
        <div id="x-sections"></div>
        <button class="btn sm" id="x-add-sec">＋ 大問を追加</button>
        <div class="row mt"><button class="btn primary" id="x-build">問題を選ぶ</button><button class="btn" id="x-reroll" hidden>選び直す</button></div>
      </section>
      <section id="x-result"></section>
    </div>
  </div>`;
  const $ = (id) => /** @type {any} */ (root.querySelector('#' + id));

  const allowed = (q) => !(q.origin === 'ai' && q.status !== 'approved') && !q.compact;
  const facet = (key, filter) => {
    const c = new Map();
    for (const q of state.questions) if (allowed(q) && filter(q) && q[key]) c.set(q[key], (c.get(q[key]) || 0) + 1);
    return [...c].sort((a, b) => String(a[0]).localeCompare(String(b[0]), 'ja'));
  };
  const opts = (list, label, cur) => `<option value="">すべての${label}</option>` + list.map(([v, n]) => `<option value="${esc(v)}"${v === cur ? ' selected' : ''}>${esc(v)}（${n}）</option>`).join('');
  const inScope = (q, ignoreUnits = false) => allowed(q) && (!mem.subj || q.subj === mem.subj) && (!mem.course || q.course === mem.course) && (!mem.src || q.src === mem.src)
    && (ignoreUnits || !mem.units.size || mem.units.has(q.unit || q.set));

  const renderScope = () => {
    $('x-subj').innerHTML = opts(facet('subj', () => true), '教科', mem.subj);
    $('x-course').innerHTML = opts(facet('course', q => !mem.subj || q.subj === mem.subj), '科目', mem.course);
    $('x-src').innerHTML = opts(facet('src', q => (!mem.subj || q.subj === mem.subj) && (!mem.course || q.course === mem.course)), '出典', mem.src);
    const uc = new Map(), uord = new Map();
    for (const q of state.questions) {
      if (!inScope(q, true)) continue;
      const u = q.unit || q.set;
      if (!u) continue;
      uc.set(u, (uc.get(u) || 0) + 1);
      if (q.uord && (!uord.has(u) || q.uord < uord.get(u))) uord.set(u, q.uord);
    }
    for (const u of [...mem.units]) if (!uc.has(u)) mem.units.delete(u);
    const units = [...uc.keys()].sort((a, b) => ((uord.get(a) || '~' + a) < (uord.get(b) || '~' + b) ? -1 : 1)).slice(0, 600);
    $('x-units').innerHTML = units.map(u => `<label class="uc${mem.units.has(u) ? ' on' : ''}"><input type="checkbox" value="${esc(u)}"${mem.units.has(u) ? ' checked' : ''}><span>${esc(u)}</span><span class="n">${uc.get(u)}</span></label>`).join('') || '<p class="small muted">（該当なし）</p>';
    const pool = poolList();
    const byLv = LEVELS.map(l => `${l} ${pool.filter(q => q.level === l).length}`).join('・');
    $('x-pool').textContent = `対象の問題：${pool.length.toLocaleString()} 問（${byLv}）`;
  };
  const exTags = () => mem.excludeTags.split(/[,、，]/).map(s => s.trim()).filter(Boolean);
  const poolList = () => state.questions.filter(q => inScope(q) && !(q.tags || []).some(t => exTags().includes(t)));

  const fill = () => {
    $('x-kind').value = mem.kind; $('x-title').value = mem.title; $('x-time').value = mem.time; $('x-total').value = mem.total; $('x-count').value = mem.count;
    $('x-versions').value = String(mem.versions); $('x-pmode').value = mem.pointsMode; $('x-extags').value = mem.excludeTags; $('x-unused').checked = mem.preferUnused;
    root.querySelectorAll('[data-lv]').forEach(el => { el.value = mem.level[el.dataset.lv]; });
    root.querySelectorAll('[data-ty]').forEach(el => { el.value = mem.type[el.dataset.ty]; });
    renderSections();
  };
  const renderSections = () => {
    $('x-sections').innerHTML = mem.sections.map((s, i) => `<div class="row" style="margin-bottom:6px" data-i="${i}">
      <b>${i + 1}</b><input class="input grow" data-sf="title" value="${esc(s.title)}" placeholder="大問の見出し（例：計算問題）" style="margin:0">
      <input class="input" type="number" min="1" data-sf="count" value="${s.count}" style="width:70px;margin:0" title="問題数">問
      <select class="input" data-sf="type" style="width:auto;margin:0"><option value="">形式は指定なし</option>${Object.entries(TYPE_LABEL).map(([k, l]) => `<option value="${k}"${s.type === k ? ' selected' : ''}>${l}</option>`).join('')}</select>
      <button class="btn sm danger" data-rm-sec="${i}">✕</button></div>`).join('') || '<p class="small muted">大問を指定しないと、上の「問題数」だけ選びます（教材制作の「大問のまとめ方」で形式ごとにまとめられます）。</p>';
  };
  renderScope();
  fill();

  $('x-subj').addEventListener('change', () => { mem.subj = $('x-subj').value; mem.course = ''; renderScope(); });
  $('x-course').addEventListener('change', () => { mem.course = $('x-course').value; renderScope(); });
  $('x-src').addEventListener('change', () => { mem.src = $('x-src').value; renderScope(); });
  $('x-units').addEventListener('change', (e) => { if (e.target.checked) mem.units.add(e.target.value); else mem.units.delete(e.target.value); renderScope(); });
  $('x-unit-all').addEventListener('click', () => { mem.units.clear(); renderScope(); });
  $('x-extags').addEventListener('change', () => { mem.excludeTags = $('x-extags').value; renderScope(); });
  $('x-unused').addEventListener('change', () => { mem.preferUnused = $('x-unused').checked; });
  for (const [id, key, num] of [['x-kind', 'kind'], ['x-title', 'title'], ['x-time', 'time', 1], ['x-total', 'total', 1], ['x-count', 'count', 1], ['x-versions', 'versions', 1], ['x-pmode', 'pointsMode']]) {
    $(id).addEventListener('change', () => { mem[key] = num ? Number($(id).value) || 0 : $(id).value; });
  }
  root.querySelectorAll('[data-lv]').forEach(el => el.addEventListener('change', () => { mem.level[el.dataset.lv] = Math.max(0, Number(el.value) || 0); }));
  root.querySelectorAll('[data-ty]').forEach(el => el.addEventListener('change', () => { mem.type[el.dataset.ty] = Math.max(0, Number(el.value) || 0); }));
  $('x-add-sec').addEventListener('click', () => { mem.sections.push({ title: '', count: 5, type: '' }); renderSections(); });
  $('x-sections').addEventListener('input', (e) => {
    const i = +e.target.closest('[data-i]').dataset.i;
    const f = e.target.dataset.sf;
    if (f) mem.sections[i][f] = f === 'count' ? Math.max(1, Number(e.target.value) || 1) : e.target.value;
  });
  $('x-sections').addEventListener('change', (e) => { const f = e.target.dataset.sf; if (f === 'type') mem.sections[+e.target.closest('[data-i]').dataset.i].type = e.target.value; });
  $('x-sections').addEventListener('click', (e) => { const i = e.target.dataset.rmSec; if (i != null) { mem.sections.splice(+i, 1); renderSections(); } });

  // ---------- 作成 ----------
  let result = null;
  const used = () => new Set(state.materials.flatMap(m => m.blocks.filter(b => b.type === 'question').map(b => b.ref)));
  const build = () => {
    const pool = poolList();
    if (!pool.length) { toast('出題範囲に問題がありません', 'error'); return; }
    if (!Number.isInteger(mem.total) || mem.total < 1) { toast('満点は1以上の整数にしてください', 'error'); return; }
    const typeRatio = Object.values(mem.type).some(v => v > 0) ? mem.type : undefined;
    const spec = {
      total: mem.total,
      ...(mem.sections.length ? { sections: mem.sections.map(s => ({ title: s.title || '', count: s.count, ...(s.type ? { type: s.type } : {}) })) } : { count: mem.count }),
      levelRatio: mem.level, ...(typeRatio ? { typeRatio } : {}),
      exclude: { tags: exTags() }, preferUnused: mem.preferUnused ? used() : undefined, pointsMode: mem.pointsMode,
    };
    result = buildExam(pool, spec, { seed: mem.seed });
    result.pts = allocatePoints(result.questions, mem.total, { mode: mem.pointsMode });
    showResult();
    $('x-reroll').hidden = false;
  };
  $('x-build').addEventListener('click', () => { mem.seed = 1; build(); });
  $('x-reroll').addEventListener('click', () => { mem.seed = Math.floor(Math.random() * 1e9); build(); });

  const showResult = () => {
    const r = result;
    const check = validatePoints(r.pts, mem.total);
    const pos = new Map(r.questions.map((q, i) => [q.id, i]));
    const fmt = (o) => Object.entries(o).map(([k, n]) => `${esc(TYPE_LABEL[k] || k)} ${n}`).join('・');
    $('x-result').innerHTML = `<div class="card">
      <h2>選んだ問題（${r.questions.length} 問）</h2>
      ${r.shortfalls.length ? `<div class="notice warn">${r.shortfalls.map(esc).join('<br>')}</div>` : ''}
      <div class="notice ${check.ok ? 'ok' : 'error'}">${esc(check.message)}</div>
      <p class="small">難易度：${fmt(r.stats.byLevel)}<br>形式：${fmt(r.stats.byType)}<br>単元：${fmt(r.stats.byUnit)}</p>
      ${(r.sections.length ? r.sections : [{ title: '', questionIds: r.questions.map(q => q.id) }]).map((s, si) => `
        <h3>${r.sections.length > 1 || s.title ? `大問${si + 1}　${esc(s.title)}` : ''}</h3>
        <table class="list">${s.questionIds.map(id => { const i = pos.get(id), q = r.questions[i]; return `<tr><td class="small" style="width:3em">${i + 1}</td>
          <td class="${texClass(q)}">${R().text((q.stem || '').slice(0, 120))}<div class="small muted">${esc([q.unit, q.level, TYPE_LABEL[q.type]].filter(Boolean).join('・'))}</div></td>
          <td style="width:90px"><input class="input" type="number" min="0" data-pt="${i}" value="${r.pts[i]}" style="margin:0"></td></tr>`; }).join('')}</table>`).join('')}
      <div class="row mt"><button class="btn primary" id="x-save" ${check.ok ? '' : 'disabled'}>教材として作成${mem.versions > 1 ? `（${mem.versions}版）` : ''}</button><span class="small muted">作成後、教材制作で問題の差し替え・並べかえ・見出しの追加ができます。</span></div></div>`;
    renderMath($('x-result'));
  };
  $('x-result').addEventListener('change', (e) => {
    const i = e.target.dataset.pt;
    if (i == null) return;
    result.pts[+i] = Math.max(0, Math.round(Number(e.target.value) || 0));
    showResult();
  });
  $('x-result').addEventListener('click', async (e) => {
    if (e.target.id !== 'x-save') return;
    const check = validatePoints(result.pts, mem.total);
    if (!check.ok) { toast(check.message, 'error'); return; }
    const ptsOf = new Map(result.questions.map((q, i) => [q.id, result.pts[i]]));
    const byId = new Map(result.questions.map(q => [q.id, q]));
    const versions = mem.versions > 1 ? makeVersions(result, mem.versions, { seed: mem.seed }) : [{ label: '', order: result.questions.map(q => q.id), choicePerm: {} }];
    const title = mem.title || `${KINDS[mem.kind] || 'テスト'}（${[mem.course || mem.subj, ...[...mem.units].slice(0, 2)].filter(Boolean).join('・') || '問題バンク'}）`;
    let first = null;
    for (const v of versions) {
      const m = newMaterial(KINDS[mem.kind] ? (mem.kind === 'ability2' ? 'ability' : mem.kind) : 'test', { id: uid('M-'), now: nowISO() });
      m.title = title + (v.label ? `（${v.label}版）` : '');
      m.notes = [`試験時間 ${mem.time} 分`, ...(m.notes ? [m.notes] : [])].join('\n');
      m.print.points = 'block';
      m.print.group = 'none';
      m.exam = { total: mem.total, timeMin: mem.time, levelRatio: mem.level, typeRatio: mem.type, units: [...mem.units], subj: mem.subj, course: mem.course, version: v.label || null, seed: mem.seed };
      const secOf = new Map();
      result.sections.forEach((s, si) => s.questionIds.forEach(id => secOf.set(id, si)));
      let lastSec = -1;
      for (const id of v.order) {
        const si = secOf.has(id) ? secOf.get(id) : -1;
        if (result.sections.length > 1 && si !== lastSec) {
          m.blocks.push({ id: blockId(), type: 'section', title: result.sections[si].title || '', inst: '次の各問いに答えなさい。' });
          lastSec = si;
        }
        const b = questionBlock(byId.get(id));
        b.pts = ptsOf.get(id);
        if (v.choicePerm && v.choicePerm[id]) b.perm = v.choicePerm[id];
        m.blocks.push(b);
      }
      const saved = await saveMaterial(m);
      first = first || saved;
    }
    await setCurrentMaterial(first.id);
    await log('テストを作成', first.id, `${title}（${versions.length}版）`);
    toast(`${versions.length} 件の教材を作りました`, 'ok');
    location.hash = '#/editor/' + first.id;
  });
}
