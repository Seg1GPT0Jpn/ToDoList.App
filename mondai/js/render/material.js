// 教材（ブロックの並び）を印刷用の HTML にする
// Render（js/render.js、通常の <script> で読み込み）の部品を使う
import { answerSpaceFor } from '../domain/answersheet.js';
import { PAGE_SIZES } from '../domain/material.js';

const R = /** @type {any} */ (globalThis).Render;

/** 教材の設定を Render の設定の形にする */
export function printSettings(m) {
  return {
    ...m.print,
    title: m.title, subtitle: m.subtitle, notes: m.notes,
    cols: m.page.cols, font: m.page.font,
    fullMarks: m.exam && m.exam.total ? m.exam.total : 100,
  };
}

/** 問題ブロックを表示用の問題にする（配点・選択肢の並びの指定を付ける） */
function blockQuestion(b, s) {
  const q = { ...b.q };
  if (b.pts != null && b.pts !== '') q.__pts = Number(b.pts);
  if (b.perm) q.__perm = b.perm;
  if (s.points === 'block' && b.pts == null) q.__pts = q.pts != null ? q.pts : null;
  return q;
}

/** 用紙サイズ・余白・ヘッダー・フッター・ページ番号を印刷用 CSS にする */
export function pageCss(m) {
  const p = m.page;
  const cssStr = (t) => '"' + String(t || '').replace(/["\\\n]/g, ' ') + '"';
  let css = `@page { size: ${p.size || 'A4'} ${p.orientation || 'portrait'}; margin: ${Number(p.margin) || 12}mm;`;
  if (p.header) css += ` @top-center { content: ${cssStr(p.header)}; font-size: 9pt; color: #555; }`;
  if (p.footer) css += ` @bottom-left { content: ${cssStr(p.footer)}; font-size: 9pt; color: #555; }`;
  if (p.pageNumbers) css += ' @bottom-center { content: counter(page) " / " counter(pages); font-size: 9pt; }';
  return css + ' }';
}

/** 見本表示の紙の大きさ（mm） */
export function paperSize(m) {
  const [w, h] = PAGE_SIZES[m.page.size] || PAGE_SIZES.A4;
  return m.page.orientation === 'landscape' ? [h, w] : [w, h];
}

function freeBlockHtml(b) {
  switch (b.type) {
    case 'heading': return `<div class="mb-heading lv${b.level || 2}">${R.text(b.text)}</div>`;
    case 'text': return b.text ? `<div class="mb-text tex">${R.text(b.text)}</div>` : '';
    case 'table': return R.table({ header: b.header && b.header.some(Boolean) ? b.header : null, rows: b.rows || [], caption: b.caption });
    case 'image': return b.src ? `<figure class="fig mb-image"><img src="${R.esc(b.src)}" alt="${R.esc(b.alt || '')}" style="max-width:${Number(b.width) || 100}%"></figure>` : '';
    case 'space': return `<div class="mb-space">${b.label ? `<div class="mb-space-label">${R.esc(b.label)}</div>` : ''}<div class="lines">${'<div></div>'.repeat(Number(b.lines) || 4)}</div></div>`;
    case 'pagebreak': return '<div class="mb-pagebreak"></div>';
    default: return '';
  }
}

/** 解答用紙のマス（問題の形式に合わせる） */
function sheetCell(v) {
  const sp = answerSpaceFor(v.q);
  switch (sp.kind) {
    case 'symbol': return '<span class="box s"></span>';
    case 'symbols': return '<span class="box m"></span>';
    case 'tf': return '<span class="tfbox">○ ・ ×</span>';
    case 'order': return Array.from({ length: sp.cells || 4 }, () => '<span class="box xs"></span>').join('→');
    case 'calc': return '<div class="calc-area"><span class="calc-label">計算</span></div><div class="ans-box">答え<span class="box l"></span></div>';
    case 'short': return '<span class="box l wide"></span>';
    case 'english': return `<div class="lines en">${'<div></div>'.repeat(sp.lines || 3)}</div>`;
    case 'proof': case 'written': return R.writeArea({ ...v.q, lines: sp.lines || v.q.lines, grid: sp.chars || v.q.grid });
    default: return '';
  }
}

/**
 * 教材を HTML にする
 * @param {any} m 教材
 * @param {Record<string, any>} stims 共通の本文
 * @param {{parts?: string[]}} opt parts: 'questions' 'sheet' 'key'
 */
export function renderMaterial(m, stims, opt = {}) {
  const s = printSettings(m);
  const parts = opt.parts || ['questions', ...(s.answer === 'sheet' ? ['sheet'] : []), ...(s.key !== 'none' ? ['key'] : [])];
  const qBlocks = m.blocks.filter(b => b.type === 'question');
  const views = R.prepare(qBlocks.map(b => blockQuestion(b, s)), s);
  const viewOf = new Map(qBlocks.map((b, i) => [b.id, views[i]]));
  const explicit = m.blocks.some(b => b.type === 'section');

  // 番号付け：大問ブロックがあればそれに従う。なければ設定の「大問のまとめ方」で、ブロックの区切りごとにまとめる
  /** @type {{kind:'block', b:any}|{kind:'q', v:any}|{kind:'dai', no:number, title:string, inst:string}}[] */
  const flow = [];
  let dai = 0, plain = 0, sub = 0;
  if (explicit) {
    for (const b of m.blocks) {
      if (b.type === 'section') { dai++; sub = 0; flow.push({ kind: 'dai', no: dai, title: b.title || '', inst: b.inst || '' }); continue; }
      if (b.type !== 'question') { flow.push({ kind: 'block', b }); continue; }
      const v = viewOf.get(b.id);
      if (dai) { sub++; v.label = `(${sub})`; v.key = `${dai}(${sub})`; v.dai = dai; } else { plain++; v.label = v.key = String(plain); v.dai = 0; }
      v.daiStart = null;
      flow.push({ kind: 'q', v });
    }
  } else {
    let seg = [];
    const flush = () => {
      if (!seg.length) return;
      const numbered = R.numberViews(seg, s, stims);
      if (!s.group || s.group === 'none') {
        numbered.forEach(v => { plain++; v.label = v.key = String(plain); });
        numbered.forEach(v => flow.push({ kind: 'q', v }));
      } else {
        const base = dai;
        for (const v of numbered) {
          v.dai += base;
          v.key = `${v.dai}${v.label}`;
          if (v.daiStart) flow.push({ kind: 'dai', no: v.dai, title: '', inst: v.daiStart.inst });
          v.daiStart = null;
          flow.push({ kind: 'q', v });
          dai = Math.max(dai, v.dai);
        }
      }
      seg = [];
    };
    for (const b of m.blocks) {
      if (b.type === 'question') seg.push(viewOf.get(b.id));
      else { flush(); flow.push({ kind: 'block', b }); }
    }
    flush();
  }
  const ordered = flow.filter(f => f.kind === 'q').map(f => /** @type {any} */ (f).v);
  s.total = (s.points !== 'none' && ordered.length && ordered.every(v => v.pts != null)) ? ordered.reduce((a, v) => a + v.pts, 0) : 0;

  const [w] = paperSize(m);
  const style = `--fs:${s.font}px;--paper-w:${w}mm`;
  let out = '';

  if (parts.includes('questions')) {
    out += `<div class="paper" style="${style}">${R.header(s)}`;
    if (s.notes) out += `<ul class="pnotes">${s.notes.split('\n').filter(x => x.trim()).map(x => `<li>${R.esc(x)}</li>`).join('')}</ul>`;
    out += `<div class="pbody cols${s.cols}">`;
    let lastSid = null;
    for (let i = 0; i < flow.length; i++) {
      const f = flow[i];
      if (f.kind === 'block') { out += freeBlockHtml(f.b); lastSid = null; continue; }
      if (f.kind === 'dai') {
        out += `<div class="pdai"><span class="pdai-no">${f.no}</span><span class="pdai-inst">${R.esc([f.title, f.inst].filter(Boolean).join('　'))}</span></div>`;
        lastSid = null;
        continue;
      }
      const v = f.v;
      if (v.q.compact) {
        const run = [v];
        while (i + 1 < flow.length && flow[i + 1].kind === 'q' && /** @type {any} */ (flow[i + 1]).v.q.compact) run.push(/** @type {any} */ (flow[++i]).v);
        out += R.compactTable(run, s);
        lastSid = null;
        continue;
      }
      if (v.q.sid && v.q.sid !== lastSid && stims[v.q.sid]) out += R.stim(stims[v.q.sid], R.isTex(v.q));
      lastSid = v.q.sid || null;
      out += R.questionHtml(v, s);
    }
    out += '</div></div>';
  }

  if (parts.includes('sheet')) {
    const brk = out ? ' break' : '';
    out += `<div class="paper${brk}" style="${style}">${R.header(s, '解答用紙')}<table class="asheet">`;
    out += ordered.map(v => {
      const tall = ['written', 'steps'].includes(v.q.type) || /calc|proof|english/.test(answerSpaceFor(v.q).kind) ? ' class="tall"' : '';
      const cell = v.subs ? v.subs.map((_, k) => `(${k + 1})<span class="box s"></span>`).join('　') : sheetCell(v);
      return `<tr${tall}><th>${v.key}</th><td>${cell}</td>${s.total ? `<td class="pt">${v.pts}</td>` : ''}</tr>`;
    }).join('');
    out += '</table></div>';
  }

  if (parts.includes('key')) {
    const brk = out ? ' break' : '';
    const mode = s.key === 'none' ? 'expl' : s.key;
    out += `<div class="paper${brk} key" style="${style}">${R.header({ ...s, name: false }, '解答・解説')}`;
    if (mode === 'ans') {
      out += `<ol class="key-grid">${ordered.map(v => `<li class="${R.isTex(v.q) ? 'tex' : ''}"><b>${v.key}</b>　${R.text(v.ans)}</li>`).join('')}</ol>`;
    } else {
      out += ordered.map(v => {
        const q = v.q;
        let h = `<div class="kq${R.isTex(q) ? ' tex' : ''}"><div class="kq-ans"><b>${v.key}</b>　<span class="kq-a">${R.text(v.ans)}</span>${v.pts != null && s.points !== 'none' ? `<span class="pq-pts">（${v.pts}点）</span>` : ''}</div>`;
        if (q.alts && q.alts.length) h += `<div class="kq-expl">別解・許容：${q.alts.map(a => R.text(a)).join('／')}</div>`;
        if (q.expl) h += `<div class="kq-expl">${R.text(q.expl)}</div>`;
        if (q.steps && q.steps.length) h += `<ol class="kq-steps">${q.steps.map(x => `<li>${R.text(x)}</li>`).join('')}</ol>`;
        if (q.explBasic) h += `<div class="kq-expl"><b>やさしい解説</b>　${R.text(q.explBasic)}</div>`;
        if (q.explAdvanced) h += `<div class="kq-expl"><b>発展</b>　${R.text(q.explAdvanced)}</div>`;
        if (q.mistakes && q.mistakes.length) h += `<div class="kq-expl"><b>よくある誤答</b>　${q.mistakes.map(x => R.text(x)).join('／')}</div>`;
        if (q.rubric && q.rubric.length) h += `<div class="kq-rubric">採点基準：${q.rubric.map(r => `${R.text(r.c)}（${r.p}点）`).join('／')}</div>`;
        return h + '</div>';
      }).join('');
    }
    out += '</div>';
  }
  return { html: out, total: s.total, count: ordered.length };
}
