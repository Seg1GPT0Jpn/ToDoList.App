// 教材（ブロックの並び）を印刷用の HTML にする
// Render（js/render.js、通常の <script> で読み込み）の部品を使う
import { answerSpaceFor } from '../domain/answersheet.js';
import { PAGE_SIZES } from '../domain/material.js';
import { formatOf, integerAnswer, digitLabeler } from '../domain/format.js';
import { toSvg } from '../domain/figure.js';

const R = /** @type {any} */ (globalThis).Render;

/** 教材の設定を Render の設定の形にする */
export function printSettings(m) {
  const fmt = formatOf(m);
  return {
    ...m.print,
    // 入試形式では、選択肢の記号と解答用紙の作りを形式に合わせる（名前は表紙・解答用紙に書く）
    ...(fmt.labels ? { labels: fmt.labels } : {}),
    ...(fmt.sheet && m.print.answer !== 'none' ? { answer: 'sheet' } : {}),
    ...(fmt.cover ? { name: false } : {}),
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
    case 'figure': return b.fig ? R.figure({ svg: toSvg(b.fig).replace(/<svg /, `<svg style="width:${Math.min(100, Number(b.width) || 60)}%;height:auto" `), caption: b.caption }) : '';
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
  const fmt = formatOf(m);
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
  // 入試形式の番号：大問は「問1」「第1問」、小問は「(ア)」「問1」「(1)」。大問がなければ全体を1つの大問にする
  if (fmt.dai) {
    if (!flow.some(f => f.kind === 'dai')) {
      const first = flow.findIndex(f => f.kind === 'q');
      if (first >= 0) flow.splice(first, 0, { kind: 'dai', no: 1, title: '', inst: '次の各問いに答えなさい。' });
    }
    let n = 0, k = 0;
    for (const f of flow) {
      if (f.kind === 'dai') { n++; k = 0; f.no = n; continue; }
      if (f.kind !== 'q') continue;
      const v = f.v;
      v.dai = n || 1;
      v.label = fmt.sub(k);
      v.key = fmt.dai(v.dai) + v.label;
      k++;
    }
  }
  const ordered = flow.filter(f => f.kind === 'q').map(f => /** @type {any} */ (f).v);
  // 解答番号（共通テスト）と、整数の答えを1けたずつマークさせる記号（ア・イ…／あ・い…）
  if (fmt.sheet === 'mark') {
    let no = 0;
    const nextDigits = fmt.digits && fmt.digits !== 'none' ? digitLabeler(fmt.digits) : null;
    for (const v of ordered) {
      const n = nextDigits ? integerAnswer(v.q) : null;
      if (n != null) {
        const str = String(n);
        const labels = nextDigits(str.length);
        v.digitRows = labels.map((l, i) => ({ label: l, digit: str[i] }));
        v.markLabel = labels.join('');
        v.ans = `${v.markLabel} ＝ ${str}` + (/[^\d\s-]/.test(String(v.q.ans).replace(/^-?\d+/, '')) ? `（${v.q.ans}）` : '');
      } else if (['choice', 'multi'].includes(v.q.type) && v.labels) {
        if (fmt.answerNo === 'number') { no++; v.markLabel = String(no); v.ans = `解答番号${no}：${v.ans}`; }
        v.markRow = { label: fmt.answerNo === 'number' ? String(no) : v.key, opts: v.labels.slice(0, v.q.choices.length) };
      }
    }
  }
  s.total = (s.points !== 'none' && ordered.length && ordered.every(v => v.pts != null)) ? ordered.reduce((a, v) => a + v.pts, 0) : 0;

  const [w] = paperSize(m);
  const style = `--fs:${s.font}px;--paper-w:${w}mm`;
  let out = '';

  // 表紙（入試形式）
  if (fmt.cover && parts.includes('questions')) {
    const time = m.exam && m.exam.timeMin ? `試験時間 ${m.exam.timeMin} 分` : '';
    const notes = [...(fmt.notes || []), ...String(m.notes || '').split('\n').map(x => x.trim()).filter(x => x && !/^試験時間/.test(x))];
    out += `<div class="paper cover" style="${style}"><div class="cv-kind">${R.esc(fmt.short || fmt.label)}</div>
      <div class="cv-title">${R.esc(m.title)}</div>${m.subtitle ? `<div class="cv-sub">${R.esc(m.subtitle)}</div>` : ''}
      ${time || s.total ? `<div class="cv-time">${R.esc(time)}${s.total ? `　満点 ${s.total} 点` : ''}</div>` : ''}
      <div class="cv-notes"><b>注意事項</b><ol>${notes.map(x => `<li>${R.esc(x)}</li>`).join('')}</ol></div>
      <div class="cv-id"><div>受${fmt.short === '神奈川県入試' ? '検' : '験'}番号<span></span></div><div>氏名<span></span></div></div></div>`;
  }

  if (parts.includes('questions')) {
    const brk0 = out ? ' break' : '';
    out += `<div class="paper${brk0}" style="${style}">${fmt.cover ? `<div class="ph"><div class="ph-left"><div class="ph-title">${R.esc(m.title)}</div></div></div>` : R.header(s)}`;
    if (s.notes && !fmt.cover) out += `<ul class="pnotes">${s.notes.split('\n').filter(x => x.trim()).map(x => `<li>${R.esc(x)}</li>`).join('')}</ul>`;
    out += `<div class="pbody cols${s.cols}">`;
    let lastSid = null;
    for (let i = 0; i < flow.length; i++) {
      const f = flow[i];
      if (f.kind === 'block') { out += freeBlockHtml(f.b); lastSid = null; continue; }
      if (f.kind === 'dai') {
        out += `<div class="pdai"><span class="pdai-no${fmt.dai ? ' wide' : ''}">${fmt.dai ? R.esc(fmt.dai(f.no)) : f.no}</span><span class="pdai-inst">${R.esc([f.title, f.inst].filter(Boolean).join('　'))}</span></div>`;
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

  if (parts.includes('sheet') && fmt.sheet === 'mark') {
    out += markSheet(ordered, s, fmt, style, out ? ' break' : '', m);
  } else if (parts.includes('sheet') && fmt.sheet === 'perDai') {
    out += perDaiSheet(ordered, s, fmt, style, out ? ' break' : '', m);
  } else if (parts.includes('sheet')) {
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

/** 解答用紙の上の欄（受験番号・氏名・得点） */
function sheetHead(m, s, fmt, sub) {
  return `<div class="ph"><div class="ph-left"><div class="ph-title">${R.esc(m.title)}<span class="ph-kind">${R.esc(sub)}</span></div></div>
    <div class="ph-name"><div class="nm">受${fmt.short === '神奈川県入試' ? '検' : '験'}番号</div><div class="nm">氏名</div>${s.total ? `<div class="score">得点<span>／${s.total}</span></div>` : ''}</div></div>`;
}

/** マークシート形式の解答用紙（神奈川県入試・共通テスト） */
function markSheet(ordered, s, fmt, style, brk, m) {
  // 丸の中は数字だけ（①→1）にして見やすくする
  const plainLabel = (o) => { const i = '①②③④⑤⑥⑦⑧⑨⑩⑪⑫'.indexOf(o); return i >= 0 ? String(i + 1) : o; };
  const bubbles = (opts) => opts.map(o => `<span class="bub">${R.esc(plainLabel(o))}</span>`).join('');
  const digitOpts = fmt.digits === 'kata' ? ['−', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9'] : ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const rows = [];
  const written = [];
  for (const v of ordered) {
    if (v.digitRows) v.digitRows.forEach(r => rows.push(`<div class="mrow"><span class="mlab">${R.esc(r.label)}</span>${bubbles(digitOpts.filter(o => o !== '−' || String(v.q.ans).trim().startsWith('-') || fmt.digits === 'kata'))}</div>`));
    else if (v.markRow) rows.push(`<div class="mrow"><span class="mlab">${R.esc(v.markRow.label)}</span>${bubbles(v.markRow.opts)}</div>`);
    else written.push(v);
  }
  let h = `<div class="paper${brk}" style="${style}">${sheetHead(m, s, fmt, '解答用紙')}
    <p class="small">${fmt.answerNo === 'number' ? '解答番号・記号の欄の、答えにあたるところをマークしなさい。' : '問題の番号の欄の、答えにあたる番号をマークしなさい。数値の答えは、あ・い…の欄に1けたずつマークしなさい。'}</p>
    <div class="msheet">${rows.join('')}</div>`;
  if (written.length) {
    h += `<h3 class="mt">記述の解答欄</h3><table class="asheet">${written.map(v => `<tr class="tall"><th>${R.esc(v.key)}</th><td>${sheetCell(v)}</td>${s.total ? `<td class="pt">${v.pts}</td>` : ''}</tr>`).join('')}</table>`;
  }
  return h + '</div>';
}

/** 大問ごとの記述式解答用紙（二次試験） */
function perDaiSheet(ordered, s, fmt, style, brk, m) {
  const byDai = new Map();
  for (const v of ordered) { if (!byDai.has(v.dai)) byDai.set(v.dai, []); byDai.get(v.dai).push(v); }
  let h = '';
  let first = true;
  for (const [d, vs] of byDai) {
    h += `<div class="paper${first ? brk : ' break'}" style="${style}">${sheetHead(m, s, fmt, `解答用紙　${fmt.dai(d)}`)}`;
    h += vs.map(v => `<div class="pd-q"><b>${R.esc(v.label)}</b>${v.pts != null && s.points !== 'none' ? `<span class="pq-pts">（${v.pts}点）</span>` : ''}
      <div class="lines">${'<div></div>'.repeat(Math.max(v.q.type === 'written' ? 10 : 5, (v.q.lines || 0) * 2))}</div></div>`).join('');
    h += '</div>';
    first = false;
  }
  return h;
}
