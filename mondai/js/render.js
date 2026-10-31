// 問題やプリントを HTML にする部分
const Render = (() => {
  const LABELS = {
    kana: ['ア', 'イ', 'ウ', 'エ', 'オ', 'カ', 'キ', 'ク', 'ケ', 'コ', 'サ', 'シ'],
    num: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'],
    alpha: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'],
  };
  const TYPE_LABEL = { choice: '選択', multi: '複数選択', order: '並べかえ', tf: '正誤', short: '答えのみ', written: '記述', steps: '小問つき' };

  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  }
  // データ内の記法：[[u:語句]] 下線、[[mark:1:語句]] 番号つき傍線、[[blank:A]] 空欄
  function text(s) {
    return esc(s)
      .replace(/\[\[mark:([^:\]]+):(.*?)\]\]/g, '<span class="mk-no">$1</span><u class="ul">$2</u>')
      .replace(/\[\[u:(.*?)\]\]/g, '<u class="ul">$1</u>')
      .replace(/\[\[blank:([^\]]*)\]\]/g, '<span class="blank">$1</span>')
      .replace(/\n/g, '<br>');
  }
  function plain(s) {
    return String(s == null ? '' : s).replace(/\[\[mark:[^:\]]+:(.*?)\]\]/g, '$1').replace(/\[\[u:(.*?)\]\]/g, '$1').replace(/\[\[blank:([^\]]*)\]\]/g, '（$1）');
  }

  // 数式（$...$）を KaTeX で表示する出典。ほかの出典は $ を普通の文字として扱う
  const TEX_SRC = new Set(['かながわ', '内蔵']);
  function isTex(q) { return TEX_SRC.has(q.src); }

  function math(root) {
    if (!window.renderMathInElement) return;
    root.querySelectorAll('.tex').forEach(el => {
      window.renderMathInElement(el, {
        delimiters: [
          { left: '$$', right: '$$', display: true },
          { left: '$', right: '$', display: false },
          { left: '\\(', right: '\\)', display: false },
          { left: '\\[', right: '\\]', display: true },
        ],
        throwOnError: false,
      });
    });
  }

  // データ内の SVG からスクリプトなどを取り除き、id が他の図とぶつからないようにする
  let svgSeq = 0;
  function safeSvg(svg) {
    if (!svg) return '';
    const doc = new DOMParser().parseFromString(svg, 'image/svg+xml');
    const root = doc.documentElement;
    if (!root || root.nodeName.toLowerCase() !== 'svg') return '';
    root.querySelectorAll('script, foreignObject, iframe').forEach(n => n.remove());
    root.querySelectorAll('*').forEach(n => {
      for (const a of Array.from(n.attributes)) {
        if (/^on/i.test(a.name) || (/href$/i.test(a.name) && /^\s*javascript:/i.test(a.value))) n.removeAttribute(a.name);
      }
    });
    const p = 's' + (++svgSeq) + '_';
    return new XMLSerializer().serializeToString(root)
      .replace(/\bid="([^"]+)"/g, `id="${p}$1"`)
      .replace(/url\(#([^)]+)\)/g, `url(#${p}$1)`)
      .replace(/href="#([^"]+)"/g, `href="#${p}$1"`);
  }

  function chart(f) {
    const W = 260, H = 160, L = 34, B = 26, T = 10, R = 10;
    const vals = f.series.flatMap(s => s.values);
    const max = Math.max(1, ...vals), min = Math.min(0, ...vals);
    const n = f.labels.length;
    const x = i => L + (n === 1 ? 0 : i * (W - L - R) / (n - 1));
    const y = v => H - B - (v - min) / (max - min) * (H - B - T);
    let g = `<line x1="${L}" y1="${H - B}" x2="${W - R}" y2="${H - B}" stroke="#000"/><line x1="${L}" y1="${T}" x2="${L}" y2="${H - B}" stroke="#000"/>`;
    for (let k = 0; k <= 4; k++) {
      const v = min + (max - min) * k / 4;
      g += `<line x1="${L}" x2="${W - R}" y1="${y(v)}" y2="${y(v)}" stroke="#ccc" stroke-width=".5"/><text x="${L - 4}" y="${y(v) + 3}" font-size="9" text-anchor="end">${+v.toFixed(2)}</text>`;
    }
    f.labels.forEach((lb, i) => { g += `<text x="${x(i)}" y="${H - B + 13}" font-size="9" text-anchor="middle">${esc(lb)}</text>`; });
    f.series.forEach((s, si) => {
      const dash = si ? ' stroke-dasharray="4 2"' : '';
      if (f.chart === 'bar') {
        const bw = (W - L - R) / n / (f.series.length + 1);
        s.values.forEach((v, i) => { g += `<rect x="${x(i) - bw * f.series.length / 2 + si * bw}" y="${y(v)}" width="${bw}" height="${H - B - y(v)}" fill="${si ? '#999' : '#444'}"/>`; });
      } else {
        g += `<polyline fill="none" stroke="#000"${dash} points="${s.values.map((v, i) => x(i) + ',' + y(v)).join(' ')}"/>`;
        s.values.forEach((v, i) => { g += `<circle cx="${x(i)}" cy="${y(v)}" r="2"/>`; });
      }
    });
    const legend = f.series.filter(s => s.name).map(s => esc(s.name)).join('・');
    return `<svg viewBox="0 0 ${W} ${H}" width="${W}" height="${H}" font-family="sans-serif">${g}</svg>` +
      `<div class="fig-cap">${legend}${f.unit ? '（' + esc(f.unit) + '）' : ''}</div>`;
  }

  function figure(f) {
    if (!f) return '';
    if (f.svg) return `<figure class="fig">${safeSvg(f.svg)}${f.caption ? `<figcaption>${text(f.caption)}</figcaption>` : ''}</figure>`;
    if (f.chart) return `<figure class="fig">${chart(f)}</figure>`;
    if (f.note) return `<div class="fig-note">［${esc(f.note)}］</div>`;
    return '';
  }

  function table(t) {
    if (!t || !Array.isArray(t.rows)) return '';
    const head = t.header ? `<tr>${t.header.map(h => `<th>${text(h)}</th>`).join('')}</tr>` : '';
    const body = t.rows.map(r => `<tr>${(Array.isArray(r) ? r : [r]).map(c => `<td>${text(c)}</td>`).join('')}</tr>`).join('');
    return `<table class="dtable">${t.caption ? `<caption>${text(t.caption)}</caption>` : ''}${head}${body}</table>`;
  }

  function stim(st, tex) {
    if (!st) return '';
    let h = `<div class="pstim${tex ? ' tex' : ''}">`;
    if (st.title) h += `<div class="pstim-title">${text(st.title)}</div>`;
    if (st.content) h += `<div class="pstim-body">${text(st.content)}</div>`;
    h += table(st.table) + figure(st.fig);
    if (Array.isArray(st.glossary) && st.glossary.length) {
      h += `<div class="gloss">（注）${st.glossary.map(g => typeof g === 'string' ? esc(g) : `${esc(g.term || g.word || '')}：${esc(g.meaning || g.gloss || '')}`).join('　')}</div>`;
    }
    if (st.source) h += `<div class="pstim-src">${esc(st.source)}</div>`;
    return h + '</div>';
  }

  // ---------- 印刷用の準備 ----------
  function rng(seed) {
    let h = seed >>> 0 || 1;
    return () => { h ^= h << 13; h ^= h >>> 17; h ^= h << 5; return (h >>> 0) / 4294967296; };
  }
  function shuffled(n, rand) {
    const a = Array.from({ length: n }, (_, i) => i);
    for (let i = n - 1; i > 0; i--) { const j = Math.floor(rand() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; }
    return a;
  }
  function labelsFor(q, style, n) {
    if (style === 'auto' && q.cl && q.cl.length >= n) return q.cl;
    return LABELS[style === 'auto' ? 'kana' : style];
  }

  function answerFor(choices, ai, perm, labels, type) {
    const pos = ai.map(i => labels[perm.indexOf(i)]);
    if (type === 'order') return pos.join(' → ');
    return pos.join('・');
  }

  function prepare(items, s) {
    const rand = rng(s.seed || 1);
    const views = items.map((q, k) => {
      const v = { q, no: k + 1 };
      if (q.choices && q.choices.length) {
        v.labels = labelsFor(q, s.labels, q.choices.length);
        v.perm = (s.shuffle && q.type !== 'order') ? shuffled(q.choices.length, rand) : q.choices.map((_, i) => i);
        v.ans = answerFor(q.choices, q.ai || [], v.perm, v.labels, q.type);
      } else if (q.subs) {
        v.subs = q.subs.map(sq => {
          const labels = labelsFor(sq, s.labels, sq.choices.length);
          const perm = s.shuffle ? shuffled(sq.choices.length, rand) : sq.choices.map((_, i) => i);
          return { sq, labels, perm, ans: answerFor(sq.choices, sq.ai, perm, labels, 'choice') };
        });
        v.ans = v.subs.map((x, i) => `(${i + 1}) ${x.ans}`).join('　');
      } else {
        v.ans = q.ans || '';
      }
      return v;
    });
    // 配点
    if (s.points === 'equal' && views.length) {
      const base = Math.floor(100 / views.length), extra = 100 - base * views.length;
      views.forEach((v, i) => { v.pts = Math.max(1, base + (i < extra ? 1 : 0)); });
    } else if (s.points === 'data') {
      views.forEach(v => { if (v.q.pts != null) v.pts = v.q.pts; });
    }
    return views;
  }

  // ---------- 問題用紙 ----------
  function choicesHtml(choices, perm, labels) {
    const items = perm.map((oi, p) => ({ l: labels[p], t: choices[oi] }));
    const maxLen = Math.max(...items.map(x => String(x.t).replace(/\$[^$]*\$/g, 'xxxx').length));
    const cls = maxLen <= 8 ? 'ch4' : maxLen <= 20 ? 'ch2' : 'ch1';
    return `<ol class="choices ${cls}">${items.map(x => `<li><span class="cl">${esc(x.l)}</span>${text(x.t)}</li>`).join('')}</ol>`;
  }

  function writeArea(q) {
    if (q.grid) {
      const cols = 20, rows = Math.ceil(q.grid / cols);
      return `<div class="grid" style="--cols:${cols}">${'<span></span>'.repeat(rows * cols)}</div><div class="grid-note">${q.grid}字</div>`;
    }
    return `<div class="lines">${'<div></div>'.repeat(q.lines || 4)}</div>`;
  }

  function inlineAnswer(v) {
    const q = v.q;
    switch (q.type) {
      case 'choice': case 'tf': return `<div class="ans-box">答え<span class="box s"></span></div>`;
      case 'multi': return `<div class="ans-box">答え<span class="box m"></span></div>`;
      case 'order': return `<div class="ans-box">答え${q.choices.map(() => '<span class="box xs"></span>').join('→')}</div>`;
      case 'short': return `<div class="ans-box">答え<span class="box l"></span></div>`;
      case 'written': return writeArea(q);
      default: return '';
    }
  }

  function questionHtml(v, s) {
    const q = v.q;
    const tex = isTex(q) ? ' tex' : '';
    let h = `<div class="pq${tex}">`;
    h += `<div class="pq-head"><span class="pq-no">${v.no}</span><div class="pq-stem">${text(q.stem)}`;
    if (v.pts != null && s.points !== 'none') h += `<span class="pq-pts">（${v.pts}点）</span>`;
    h += `</div></div>`;
    if (s.meta) h += `<div class="pq-meta">${esc([q.src, q.course || q.subj, q.grade, q.unit].filter(Boolean).join('｜'))}</div>`;
    if (q.sentence) h += `<div class="pq-sentence">${text(q.sentence)}</div>`;
    h += table(q.table) + figure(q.fig);
    if (q.choices && q.choices.length) h += choicesHtml(q.choices, v.perm, v.labels);
    if (v.subs) {
      h += v.subs.map(x => `<div class="sub"><div>${text(x.sq.stem)}</div>${choicesHtml(x.sq.choices, x.perm, x.labels)}${s.answer === 'inline' ? '<div class="ans-box">答え<span class="box s"></span></div>' : ''}</div>`).join('');
    }
    if (s.answer === 'inline' && !v.subs) h += inlineAnswer(v);
    return h + '</div>';
  }

  function compactTable(views, s) {
    const cells = views.map(v => `<td><span class="pq-no">${v.no}</span> <span class="w-stem">${text(v.q.stem)}</span>${s.answer === 'inline' ? '<span class="w-line"></span>' : ''}</td>`);
    let rows = '';
    for (let i = 0; i < cells.length; i += 2) rows += `<tr>${cells[i]}${cells[i + 1] || '<td></td>'}</tr>`;
    return `<table class="wtable">${rows}</table>`;
  }

  function header(s, sub) {
    const date = s.date ? new Date().toLocaleDateString('ja-JP', { year: 'numeric', month: 'long', day: 'numeric' }) : '';
    let h = `<div class="ph"><div class="ph-left"><div class="ph-title">${esc(s.title || 'プリント')}${sub ? `<span class="ph-kind">${esc(sub)}</span>` : ''}</div>`;
    if (s.subtitle) h += `<div class="ph-sub">${esc(s.subtitle)}</div>`;
    if (date) h += `<div class="ph-sub">${esc(date)}</div>`;
    h += '</div>';
    if (s.name) h += `<div class="ph-name"><div>　　年　　組　　番</div><div class="nm">氏名</div>${s.total ? `<div class="score">得点<span>／${s.total}</span></div>` : ''}</div>`;
    return h + '</div>';
  }

  function sheet(views, s, stims) {
    s.total = (s.points !== 'none' && views.length && views.every(v => v.pts != null)) ? views.reduce((a, v) => a + v.pts, 0) : 0;
    const style = `--fs:${s.font}px`;
    let out = `<div class="paper" style="${style}">${header(s)}`;
    if (s.notes) out += `<ul class="pnotes">${s.notes.split('\n').filter(x => x.trim()).map(x => `<li>${esc(x)}</li>`).join('')}</ul>`;
    out += `<div class="pbody cols${s.cols}">`;
    let lastSid = null;
    for (let i = 0; i < views.length; i++) {
      const v = views[i];
      if (v.q.compact) {
        const run = [];
        while (i < views.length && views[i].q.compact) run.push(views[i++]);
        i--;
        out += compactTable(run, s);
        lastSid = null;
        continue;
      }
      if (v.q.sid && v.q.sid !== lastSid && stims[v.q.sid]) out += stim(stims[v.q.sid], isTex(v.q));
      lastSid = v.q.sid || null;
      out += questionHtml(v, s);
    }
    out += '</div></div>';

    if (s.answer === 'sheet') {
      out += `<div class="paper break" style="${style}">${header(s, '解答用紙')}<table class="asheet">`;
      out += views.map(v => {
        let cell = '';
        if (v.q.type === 'written') cell = writeArea(v.q);
        else if (v.subs) cell = v.subs.map((_, k) => `(${k + 1})<span class="box s"></span>`).join('　');
        else cell = '';
        const tall = v.q.type === 'written' ? ' class="tall"' : '';
        return `<tr${tall}><th>${v.no}</th><td>${cell}</td>${s.total ? `<td class="pt">${v.pts}</td>` : ''}</tr>`;
      }).join('');
      out += '</table></div>';
    }

    if (s.key !== 'none') {
      out += `<div class="paper break key" style="${style}">${header({ ...s, name: false }, '解答・解説')}`;
      if (s.key === 'ans') {
        out += `<ol class="key-grid">${views.map(v => `<li class="${isTex(v.q) ? 'tex' : ''}"><b>${v.no}</b>　${text(v.ans)}</li>`).join('')}</ol>`;
      } else {
        out += views.map(v => {
          const q = v.q;
          let h = `<div class="kq${isTex(q) ? ' tex' : ''}"><div class="kq-ans"><b>${v.no}</b>　<span class="kq-a">${text(v.ans)}</span>${v.pts != null && s.points !== 'none' ? `<span class="pq-pts">（${v.pts}点）</span>` : ''}</div>`;
          if (q.expl) h += `<div class="kq-expl">${text(q.expl)}</div>`;
          if (q.steps && q.steps.length) h += `<ol class="kq-steps">${q.steps.map(x => `<li>${text(x)}</li>`).join('')}</ol>`;
          if (q.rubric && q.rubric.length) h += `<div class="kq-rubric">採点基準：${q.rubric.map(r => `${text(r.c)}（${r.p}点）`).join('／')}</div>`;
          return h + '</div>';
        }).join('');
      }
      out += '</div>';
    }
    return out;
  }

  return { esc, text, plain, isTex, math, figure, table, stim, prepare, sheet, choicesHtml, TYPE_LABEL };
})();
