// 分析：学習結果の記録と、問題・単元・難易度・学習者・教材の分析（データがないときは何も作らない）
import { state, getMaterial, currentMaterialId, log, setCurrentMaterial, saveMaterial } from '../core/store.js';
import * as db from '../core/db.js';
import { esc, toast, uid, nowISO, pickFiles, fmtDate } from '../core/util.js';
import { parseCSV } from '../domain/csv.js';
import { newMaterial, questionBlock } from '../domain/material.js';
import { renderMath, texClass, R, TYPE_LABEL } from './common.js';

const pct = (x) => (x == null ? '—' : Math.round(x * 100) + '%');
const bar = (x) => `<div class="bar" title="${pct(x)}"><span style="width:${Math.round((x || 0) * 100)}%"></span></div>`;

export async function render(root, parts) {
  const id = parts[0] || await currentMaterialId();
  const ms = state.materials.filter(m => m.blocks.some(b => b.type === 'question'));
  const results = await db.all('results');
  root.innerHTML = `
  <div class="page-head"><div class="grow"><h1>分析</h1><p>テストやプリントの結果を記録すると、正答率・つまずき・誤答の傾向が分かります。記録はこの端末に保存されます。</p></div></div>
  <div class="grid2">
    <section class="card"><h2>結果を記録する</h2>
      <label class="f">教材<select class="input" id="an-mat">${ms.map(m => `<option value="${esc(m.id)}"${m.id === id ? ' selected' : ''}>${esc(m.title)}</option>`).join('') || '<option value="">（問題の入った教材がありません）</option>'}</select></label>
      <div class="row"><button class="btn primary" id="an-entry" ${ms.length ? '' : 'disabled'}>表に入力する</button><button class="btn" id="an-csv" ${ms.length ? '' : 'disabled'}>CSV を取り込む</button></div>
      <p class="small muted">CSV の形：1行目に「学習者,1,2,3…」（問題番号）、2行目から「名前,○,×,ア…」。○×のほか、選んだ記号（ア・イ…）や得点（0〜1）も書けます。</p>
    </section>
    <section class="card"><h2>記録の状況</h2><div id="an-sum"></div></section>
  </div>
  <div id="an-out"></div>`;
  const $ = (x) => /** @type {any} */ (root.querySelector('#' + x));
  const matSel = () => getMaterial($('an-mat').value);

  // ---------- 集計 ----------
  const learners = new Set(results.map(r => r.learner));
  const mats = new Set(results.map(r => r.materialId));
  $('an-sum').innerHTML = results.length
    ? `<div class="stats"><div class="stat"><b>${results.length.toLocaleString()}</b><span>記録（問題×学習者）</span></div><div class="stat"><b>${learners.size}</b><span>学習者</span></div><div class="stat"><b>${mats.size}</b><span>教材</span></div></div>
       <button class="btn sm danger" id="an-clear">この教材の記録を消す</button>`
    : '<p class="empty">まだ学習結果の記録がありません。左で教材を選んで結果を記録すると、ここに分析が出ます。</p>';
  if ($('an-clear')) $('an-clear').addEventListener('click', async () => {
    const m = matSel();
    if (!m || !confirm(`「${m.title}」の記録を消しますか？`)) return;
    await db.delMany('results', results.filter(r => r.materialId === m.id).map(r => r.id));
    await log('学習結果を削除', m.title);
    render(root, parts);
  });

  $('an-mat').addEventListener('change', () => { location.hash = '#/analytics/' + $('an-mat').value; });
  $('an-entry').addEventListener('click', () => entryGrid(matSel()));
  $('an-csv').addEventListener('click', async () => {
    const m = matSel();
    const [f] = await pickFiles('.csv,text/csv');
    if (!f) return;
    const rows = parseCSV((await f.text()).replace(/^﻿/, ''));
    if (rows.length < 2) { toast('CSV に結果がありません', 'error'); return; }
    const head = rows[0];
    const qbs = m.blocks.filter(b => b.type === 'question');
    const recs = [];
    for (const row of rows.slice(1)) {
      const name = (row[0] || '').trim();
      if (!name) continue;
      for (let c = 1; c < head.length; c++) {
        const no = parseInt(head[c], 10);
        const b = qbs[no - 1];
        if (!b || row[c] == null || String(row[c]).trim() === '') continue;
        recs.push(makeRecord(m, b, name, String(row[c]).trim()));
      }
    }
    await saveRecords(m, recs);
  });

  const saveRecords = async (m, recs) => {
    if (!recs.length) { toast('記録できる結果がありませんでした', 'error'); return; }
    // 同じ教材・学習者・問題の記録は上書き
    const key = (r) => `${r.materialId}|${r.learner}|${r.blockId}`;
    const old = new Map(results.filter(r => r.materialId === m.id).map(r => [key(r), r]));
    recs.forEach(r => { const o = old.get(key(r)); if (o) r.id = o.id; });
    await db.putMany('results', recs);
    await log('学習結果を記録', m.title, `${recs.length}件`);
    toast(`${recs.length} 件を記録しました`, 'ok');
    render(root, ['' + m.id]);
  };

  const entryGrid = (m) => {
    const qbs = m.blocks.filter(b => b.type === 'question');
    const mine = results.filter(r => r.materialId === m.id);
    const names = [...new Set(mine.map(r => r.learner))];
    if (!names.length) names.push('');
    const cell = (name, b) => { const r = mine.find(x => x.learner === name && x.blockId === b.id); return r ? r.raw : ''; };
    $('an-out').innerHTML = `<div class="card"><h2>${esc(m.title)} の結果入力</h2>
      <p class="small muted">○＝正解、×＝不正解、△＝部分点（半分）、0〜1 の数＝得点率、ア・イ…＝選んだ記号（正誤は自動で判定）。空欄は記録しません。</p>
      <div style="overflow-x:auto"><table class="list" id="an-grid"><tr><th>学習者</th>${qbs.map((b, i) => `<th title="${esc((b.q.stem || '').slice(0, 60))}">${i + 1}</th>`).join('')}</tr>
        ${names.map(n => `<tr><td><input class="input" data-name value="${esc(n)}" style="min-width:110px;margin:0"></td>${qbs.map(b => `<td><input class="input" data-b="${b.id}" value="${esc(cell(n, b))}" style="width:46px;margin:0;text-align:center"></td>`).join('')}</tr>`).join('')}</table></div>
      <div class="row mt"><button class="btn" id="an-addrow">＋ 学習者を追加</button><span class="spacer"></span><button class="btn primary" id="an-save">記録する</button></div></div>`;
    const grid = $('an-grid');
    $('an-addrow').addEventListener('click', () => {
      const tr = document.createElement('tr');
      tr.innerHTML = `<td><input class="input" data-name style="min-width:110px;margin:0"></td>${qbs.map(b => `<td><input class="input" data-b="${b.id}" style="width:46px;margin:0;text-align:center"></td>`).join('')}`;
      (grid.tBodies[0] || grid).appendChild(tr);
      tr.querySelector('input').focus();
    });
    $('an-save').addEventListener('click', async () => {
      const recs = [];
      for (const tr of grid.querySelectorAll('tr')) {
        const nameEl = tr.querySelector('[data-name]');
        if (!nameEl) continue;
        const name = nameEl.value.trim();
        if (!name) continue;
        tr.querySelectorAll('[data-b]').forEach(inp => {
          const v = inp.value.trim();
          if (!v) return;
          const b = qbs.find(x => x.id === inp.dataset.b);
          recs.push(makeRecord(m, b, name, v));
        });
      }
      await saveRecords(m, recs);
    });
    grid.querySelector('input').focus();
  };

  // ---------- 分析 ----------
  const m = matSel();
  if (!results.length) return;
  const out = [];
  // 全体：問題（バンクの問題 ID）ごと
  const byQ = new Map();
  for (const r of results) {
    const k = r.questionId;
    if (!byQ.has(k)) byQ.set(k, { q: r.q, scores: [], answers: {} });
    const e = byQ.get(k);
    e.scores.push(r.score);
    if (r.choice) e.answers[r.choice] = (e.answers[r.choice] || 0) + 1;
  }
  const avg = (a) => (a.length ? a.reduce((x, y) => x + y, 0) / a.length : null);
  const group = (keyOf) => {
    const g = new Map();
    for (const r of results) { const k = keyOf(r) || '（なし）'; if (!g.has(k)) g.set(k, []); g.get(k).push(r.score); }
    return [...g].map(([k, a]) => ({ k, n: a.length, rate: avg(a) })).sort((a, b) => a.rate - b.rate);
  };
  const table = (rows, head) => `<table class="list"><tr>${head.map(h => `<th>${h}</th>`).join('')}</tr>${rows.join('')}</table>`;
  const units = group(r => r.q.unit);
  const levels = group(r => r.q.level);
  const learnersRows = group(r => r.learner);

  if (m) {
    const mine = results.filter(r => r.materialId === m.id);
    if (mine.length) {
      const qbs = m.blocks.filter(b => b.type === 'question');
      out.push(`<section class="card"><h2>${esc(m.title)}：問題ごとの正答率と誤答の傾向</h2>${table(qbs.map((b, i) => {
        const rs = mine.filter(r => r.blockId === b.id);
        if (!rs.length) return '';
        const rate = avg(rs.map(r => r.score));
        const ans = {};
        rs.forEach(r => { if (r.choice) ans[r.choice] = (ans[r.choice] || 0) + 1; });
        const wrong = Object.entries(ans).filter(([c]) => !rs.find(r => r.choice === c && r.score === 1)).sort((a, b) => b[1] - a[1]);
        return `<tr><td>${i + 1}</td><td class="${texClass(b.q)}" style="max-width:420px">${R().text((b.q.stem || '').slice(0, 80))}<div class="small muted">${esc([b.q.unit, b.q.level, TYPE_LABEL[b.q.type]].filter(Boolean).join('・'))}</div></td>
          <td style="width:160px">${bar(rate)}<span class="small">${pct(rate)}（${rs.length}人）</span></td><td class="small">${wrong.length ? wrong.map(([c, n]) => `${esc(c)}：${n}人`).join('、') : '—'}</td></tr>`;
      }), ['#', '問題', '正答率', '多かった誤答'])}</section>`);
    } else out.push(`<section class="card"><h2>${esc(m.title)}</h2><p class="empty">この教材の記録はまだありません。</p></section>`);
  }
  out.push(`<div class="grid2">
    <section class="card"><h2>単元別の正答率（低い順）</h2>${table(units.map(u => `<tr><td>${esc(u.k)}</td><td style="width:150px">${bar(u.rate)}</td><td class="small">${pct(u.rate)}（${u.n}件）</td></tr>`), ['単元', '', '正答率'])}</section>
    <section class="card"><h2>難易度別の正答率</h2>${table(levels.map(u => `<tr><td>${esc(u.k)}</td><td style="width:150px">${bar(u.rate)}</td><td class="small">${pct(u.rate)}（${u.n}件）</td></tr>`), ['難易度', '', '正答率'])}
      <h2 class="mt">学習者別の理解度</h2>${table(learnersRows.map(u => `<tr><td>${esc(u.k)}</td><td style="width:150px">${bar(u.rate)}</td><td class="small">${pct(u.rate)}（${u.n}問）</td></tr>`), ['学習者', '', '正答率'])}</section>
  </div>`);
  // 正答率の低い問題（全教材）
  const hard = [...byQ.values()].map(e => ({ ...e, rate: avg(e.scores) })).filter(e => e.scores.length >= 2).sort((a, b) => a.rate - b.rate).slice(0, 10);
  if (hard.length) {
    out.push(`<section class="card"><div class="row"><h2 style="margin:0">つまずきの多い問題</h2><span class="spacer"></span><button class="btn primary" id="an-review">この問題で復習プリントを作る</button><button class="btn" id="an-ai">AI に復習教材を提案してもらう</button></div>
      ${table(hard.map(e => `<tr><td class="${texClass(e.q)}">${R().text((e.q.stem || '').slice(0, 90))}<div class="small muted">${esc(e.q.unit || '')}</div></td><td style="width:150px">${bar(e.rate)}</td><td class="small">${pct(e.rate)}（${e.scores.length}件）</td></tr>`), ['問題', '', '正答率'])}</section>`);
  }
  // 教材・問題の利用状況と品質
  const ratings = await db.all('ratings');
  const hist = await db.all('history');
  const printCount = (mid) => hist.filter(h => h.action === '印刷' && h.target === mid).length;
  out.push(`<div class="grid2"><section class="card"><h2>教材の利用状況</h2>${table(state.materials.slice(0, 15).map(mm => `<tr><td>${esc(mm.title)}</td><td>${printCount(mm.id)} 回</td><td>${results.filter(r => r.materialId === mm.id).length} 件</td><td class="small muted">版 ${mm.rev || 1}</td></tr>`), ['教材', '印刷', '結果', '改訂'])}</section>
    <section class="card"><h2>問題の品質</h2>${ratings.length ? `<p>評価をつけた問題 ${ratings.length} 問・平均 ${(ratings.reduce((a, r) => a + (r.stars || 0), 0) / ratings.length).toFixed(1)} 点（5点満点）</p>` : '<p class="muted">問題の評価はまだありません（問題の編集画面で★をつけられます）。</p>'}
      <p>要修正の問題：${state.questions.filter(q => q.status === 'needs_fix').length} 問／人間承認済み：${state.questions.filter(q => q.status === 'approved').length} 問</p></section></div>`);
  $('an-out').insertAdjacentHTML('beforeend', out.join(''));
  renderMath($('an-out'));

  const btn = $('an-review');
  if (btn) btn.addEventListener('click', async () => {
    const mm = newMaterial('review', { id: uid('M-'), now: nowISO() });
    mm.title = '復習プリント（つまずきの多い問題）';
    mm.blocks = hard.map(e => questionBlock(state.byId.get(e.q.id) || e.q));
    await saveMaterial(mm);
    await setCurrentMaterial(mm.id);
    location.hash = '#/editor/' + mm.id;
  });
  const aiBtn = $('an-ai');
  if (aiBtn) aiBtn.addEventListener('click', async () => {
    const ai = await import('../ai/client.js');
    const av = await ai.availability();
    if (!av.ok) { toast(av.reason, 'error'); return; }
    aiBtn.disabled = true;
    const stats = { units: units.slice(0, 15), levels, hard: hard.map(e => ({ unit: e.q.unit, subunit: e.q.subunit, level: e.q.level, rate: e.rate, stem: (e.q.stem || '').slice(0, 80) })) };
    const r = await ai.callAI('suggest_review', { stats }, '復習教材の提案');
    aiBtn.disabled = false;
    if (!r.ok) { toast('提案を受け取れませんでした：' + r.error.message, 'error'); return; }
    const d = r.data;
    $('an-out').insertAdjacentHTML('beforeend', `<section class="card"><h2>AI の提案</h2><p>${esc(d.summary || '')}</p><ul>${(d.weakPoints || []).map(w => `<li><b>${esc(w.unit || '')}${w.subunit ? '・' + esc(w.subunit) : ''}</b>：${esc(w.reason || '')}${(w.knowledge || []).length ? '（' + esc(w.knowledge.join('、')) + '）' : ''}</li>`).join('')}</ul>
      <p class="small muted">提案はデータの集計にもとづく AI の見立てです。指導の判断は先生が行ってください。</p></section>`);
  });
}

/** 入力値（○×△・得点・選んだ記号）を記録にする */
function makeRecord(m, b, learner, raw) {
  const q = b.q;
  let score = null, choice = null;
  if (/^[○◯〇oO1]$/.test(raw) || raw === '正') score = 1;
  else if (/^[×xX✕0]$/.test(raw) || raw === '誤') score = 0;
  else if (/^[△▲]$/.test(raw)) score = 0.5;
  else if (/^(0?\.\d+|1(\.0+)?)$/.test(raw)) score = Number(raw);
  else if (q.choices && q.choices.length) {
    // 選んだ記号から正誤を判定（教材の選択肢の並びに合わせる）
    const Rr = R();
    const v = Rr.prepare([{ ...q, __perm: b.perm || undefined }], { labels: m.print.labels, shuffle: false, points: 'none' })[0];
    choice = raw.normalize('NFKC');
    score = v.ans.split(/[・→]/).map(s => s.trim()).join('') === choice.replace(/[,、・\s]/g, '') ? 1 : 0;
  }
  if (score == null) score = 0;
  return { id: uid('R-'), materialId: m.id, blockId: b.id, questionId: b.ref, q: { id: b.ref, stem: q.stem, unit: q.unit, subunit: q.subunit, level: q.level, type: q.type }, learner, raw, score, choice, at: nowISO() };
}
