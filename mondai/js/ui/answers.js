// 解答・解説センター：教材の正答・解説・採点基準を整え、解答用紙・解答解説集を出す
import { state, getMaterial, saveMaterial, currentMaterialId, log } from '../core/store.js';
import { esc, toast, clone } from '../core/util.js';
import { renderMaterial, pageCss } from '../render/material.js';
import { answerSpaceFor } from '../domain/answersheet.js';
import { checkAnswer } from '../domain/mathcheck.js';
import { renderMath, texClass, R, TYPE_LABEL, printFileName, printAs } from './common.js';
import { editQuestion } from './qeditor.js';

const SPACE_LABEL = { symbol: '記号', symbols: '複数記号', tf: '○×', order: '順序', calc: '計算＋答え', short: '短答', written: '記述', proof: '証明', english: '英文' };

export async function render(root, parts) {
  const id = parts[0] || await currentMaterialId();
  const ms = state.materials.filter(m => m.status !== 'archived');
  root.innerHTML = `
  <div class="page-head no-print"><div class="grow"><h1>解答・解説</h1><p>教材の正答・解説・採点基準を確かめて整えます。問題を直すと問題バンクにも反映され、旧版は残ります。</p></div>
    <select class="input" id="a-mat" style="width:auto;max-width:360px">${ms.map(m => `<option value="${esc(m.id)}"${m.id === id ? ' selected' : ''}>${esc(m.title)}</option>`).join('') || '<option value="">（教材がありません）</option>'}</select></div>
  <div id="a-body"></div>`;
  const sel = /** @type {any} */ (root.querySelector('#a-mat'));
  sel.addEventListener('change', () => { location.hash = '#/answers/' + sel.value; });
  const m0 = getMaterial(sel.value);
  const body = /** @type {HTMLElement} */ (root.querySelector('#a-body'));
  if (!m0) { body.innerHTML = '<div class="card empty">教材がありません。<br><a class="btn primary" href="#/editor/new">教材を作る</a></div>'; return; }
  let m = clone(m0);

  const draw = () => {
    const qbs = m.blocks.filter(b => b.type === 'question');
    const out = renderMaterial({ ...m, print: { ...m.print, answer: 'sheet', key: 'expl' } }, state.stims, { parts: ['questions'] });
    void out;
    const rows = qbs.map((b, i) => {
      const q = b.q;
      const cur = state.byId.get(b.ref);
      const outdated = cur && (cur.rev || 1) > (b.rev || 1);
      const issues = [];
      if (!q.expl) issues.push('解説なし');
      if ((q.type === 'written' || q.type === 'short') && !(q.rubric && q.rubric.length) && q.type === 'written') issues.push('採点基準なし');
      if (q.check) { const r = checkAnswer(q); if (r.status === 'fail') issues.push('検算が合わない'); }
      if (q.status === 'needs_fix') issues.push('要修正');
      const v = R().prepare([{ ...q, __perm: b.perm || undefined }], { labels: m.print.labels, points: 'none' })[0];
      return `<tr data-bid="${esc(b.id)}"><td class="small" style="width:2.5em">${i + 1}</td>
        <td><div class="${texClass(q)}">${R().text((q.stem || '').slice(0, 140))}</div>
          <div class="small" style="margin-top:4px"><b style="color:var(--ok)">答え：</b><span class="${texClass(q)}">${R().text(v.ans)}</span></div>
          ${q.expl ? `<div class="small muted ${texClass(q)}">${R().text(q.expl.slice(0, 200))}</div>` : ''}
          <div class="row small" style="margin-top:4px"><span class="tag">${esc(TYPE_LABEL[q.type] || q.type)}</span><span class="tag">解答欄：${SPACE_LABEL[answerSpaceFor(q).kind] || ''}</span>
            ${issues.map(x => `<span class="chip warn">${x}</span>`).join('')}${outdated ? '<span class="chip danger">バンクの問題が更新されました・要再確認</span>' : ''}</div></td>
        <td style="white-space:nowrap">${outdated ? '<button class="btn sm" data-act="update">最新版にする</button> ' : ''}<button class="btn sm" data-act="edit">解答・解説を編集</button></td></tr>`;
    }).join('');
    const nIssues = qbs.filter(b => !b.q.expl).length;
    const nOut = qbs.filter(b => { const c = state.byId.get(b.ref); return c && (c.rev || 1) > (b.rev || 1); }).length;
    body.innerHTML = `
      <div class="stats no-print">
        <div class="stat"><b>${qbs.length}</b><span>問題</span></div>
        <div class="stat"><b>${nIssues}</b><span>解説がない問題</span></div>
        <div class="stat"><b>${nOut}</b><span>要再確認（バンクで更新）</span></div>
      </div>
      <div class="card no-print">
        <div class="row" style="margin-bottom:8px"><h2 style="margin:0">正答と解説</h2><span class="spacer"></span>
          <button class="btn" data-print="sheet">解答用紙を印刷</button><button class="btn" data-print="key">解答・解説集を印刷</button><a class="btn" href="#/editor/${esc(m.id)}">教材を開く</a></div>
        ${qbs.length ? `<table class="list">${rows}</table>` : '<p class="empty">この教材には問題がありません。</p>'}
      </div>
      <div class="preview-wrap" hidden id="a-print"><div class="preview print-root" id="a-prev"></div></div>`;
    renderMath(body);
  };
  draw();

  body.addEventListener('click', async (e) => {
    const t = /** @type {any} */ (e.target);
    if (t.dataset.print) {
      const out = renderMaterial(m, state.stims, { parts: [t.dataset.print] });
      const prev = /** @type {HTMLElement} */ (body.querySelector('#a-prev'));
      prev.innerHTML = out.html;
      /** @type {HTMLElement} */ (body.querySelector('#a-print')).hidden = false;
      document.getElementById('page-css').textContent = pageCss(m);
      renderMath(prev);
      await log('印刷', m.id, `${m.title}（${t.dataset.print === 'sheet' ? '解答用紙' : '解答・解説集'}）`);
      setTimeout(() => printAs(printFileName(m, [t.dataset.print])), 50);
      return;
    }
    const act = t.dataset.act;
    if (!act) return;
    const b = m.blocks.find(x => x.id === t.closest('tr').dataset.bid);
    if (act === 'update') {
      const cur = state.byId.get(b.ref);
      b.q = clone(cur); b.rev = cur.rev || 1;
      m = clone(await saveMaterial(m));
      toast('最新版にしました', 'ok');
      draw();
    }
    if (act === 'edit') {
      const inBank = state.byId.get(b.ref);
      const saved = inBank ? await editQuestion(inBank, { title: '解答・解説を編集' }) : await editQuestion(b.q, { title: '解答・解説を編集（この教材の中だけ）', onSave: async (q) => q });
      if (!saved) return;
      // この教材にも反映する。同じ問題を使うほかの教材には「要再確認」が表示される
      b.q = clone(saved); b.rev = saved.rev || 1;
      m = clone(await saveMaterial(m));
      const others = state.materials.filter(x => x.id !== m.id && x.blocks.some(y => y.type === 'question' && y.ref === b.ref)).length;
      toast(others ? `保存しました。同じ問題を使う教材が ${others} 件あり、そちらには「要再確認」と表示されます` : '保存しました', 'ok');
      draw();
    }
  });
  return () => { document.getElementById('page-css').textContent = ''; };
}
