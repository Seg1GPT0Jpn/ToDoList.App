// 作図（図形）のデータと SVG への書き出し。DOM を使わない（Node でも動く）。
// 座標は「論理単位」（既定 400×300）。画面と同じく y は下向き。
// 角の印の角度だけは数学の向き（右が 0°、反時計回りが正）で持つ。
// toSvg は入力がどんなに壊れていても <script>・イベント属性・外部リンクを出さない
// （数は検査して丸め、色と選択肢はあらかじめ決めた中からだけ選ぶ）。

import { evaluate } from './mathcheck.js';

/**
 * @typedef {{ id: string, type: string, stroke?: string, width?: number, dash?: string, fill?: string, [k: string]: any }} Shape
 * @typedef {{ w: number, h: number, shapes: Shape[] }} Figure
 * @typedef {{ x: number, y: number, w: number, h: number }} Box
 * @typedef {{ key: string, x: number, y: number }} Handle
 */

export const TYPES = ['line', 'rect', 'ellipse', 'polygon', 'text', 'point', 'angle', 'axes', 'graph'];
export const FILLS = ['none', '#ffffff', '#dddddd', '#888888', '#000000'];
export const STROKES = ['#000000', '#555555', '#888888', '#ffffff', '#d32f2f', '#1e5bc6'];
export const DASHES = ['solid', 'dashed', 'dotted'];
export const ARROWS = ['none', 'end', 'start', 'both'];
export const ANCHORS = ['start', 'middle', 'end'];
export const LABEL_POS = ['ne', 'nw', 'se', 'sw', 'n', 's', 'e', 'w'];
const FONT = 'Times New Roman, Hiragino Mincho ProN, Yu Mincho, YuMincho, serif';
const LIM = 100000;
const MAX_SHAPES = 2000;
const MAX_POINTS = 1000;

// ---------- 値の検査 ----------
/** @param {*} v @param {*} d @param {number} [min] @param {number} [max] @returns {number} */
function num(v, d, min = -LIM, max = LIM) {
  const n = typeof v === 'number' ? v : (typeof v === 'string' && v.trim() !== '' ? Number(v) : NaN);
  return Number.isFinite(n) ? Math.min(max, Math.max(min, n)) : d;
}
/** @template T @param {*} v @param {readonly T[]} list @param {T} d @returns {T} */
function pick(v, list, d) {
  const k = typeof v === 'string' ? v.trim().toLowerCase() : v;
  return list.includes(k) ? k : d;
}
/** @param {*} v */
function color(v) {
  let c = typeof v === 'string' ? v.trim().toLowerCase() : '';
  if (/^#[0-9a-f]{3}$/.test(c)) c = '#' + c[1] + c[1] + c[2] + c[2] + c[3] + c[3];
  if (c === 'black') c = '#000000';
  return STROKES.includes(c) ? c : '#000000';
}
/** @param {*} v */
function fillOf(v, d = 'none') {
  let c = typeof v === 'string' ? v.trim().toLowerCase() : '';
  if (/^#[0-9a-f]{3}$/.test(c)) c = '#' + c[1] + c[1] + c[2] + c[2] + c[3] + c[3];
  if (c === 'white') c = '#ffffff';
  if (c === 'black') c = '#000000';
  return FILLS.includes(c) ? c : d;
}
/** 文字列：XML で使えない文字を取り除き、長さを切る @param {*} v @param {number} max */
function str(v, max) {
  if (v == null) return '';
  return String(v)
    .replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F￾￿]/g, '')
    .replace(/[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?<![\uD800-\uDBFF])[\uDC00-\uDFFF]/g, '')
    .slice(0, max);
}
/** XML の特殊文字を逃がす @param {*} s */
export function escXml(s) {
  return str(s, 100000).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}
/** 数を SVG 用に短く書く @param {number} n */
const f = (n) => { const r = Math.round(n * 100) / 100; return Object.is(r, -0) ? '0' : String(r); };
const bool = (v) => v === true || v === 'true' || v === 1;

let idSeq = 0;
const genId = () => 's' + Date.now().toString(36).slice(-5) + (++idSeq).toString(36);
/** @param {*} v */
const safeId = (v) => (typeof v === 'string' && /^[A-Za-z0-9_-]{1,40}$/.test(v) ? v : '');

// ---------- 図形のデータ ----------
/** @type {Record<string, Record<string, any>>} */
const DEFAULTS = {
  line: { x1: 50, y1: 150, x2: 150, y2: 150, arrow: 'none' },
  rect: { x: 50, y: 50, w: 100, h: 60 },
  ellipse: { cx: 200, cy: 150, rx: 50, ry: 50 },
  polygon: { points: [[100, 200], [300, 200], [200, 80]], closed: true },
  text: { x: 50, y: 50, text: '文字', size: 16, anchor: 'start', italic: false },
  point: { x: 100, y: 100, label: '', r: 2.5, labelPos: 'ne' },
  angle: { cx: 100, cy: 200, r: 18, start: 0, end: 60, label: '', right: false, arcs: 1 },
  axes: { ox: 200, oy: 150, unit: 20, xmin: -9, xmax: 9, ymin: -6, ymax: 6, grid: false, ticks: true, labels: true, xlabel: 'x', ylabel: 'y', step: 0, width: 1 },
  graph: { expr: 'x^2', xmin: null, xmax: null, axesId: '', width: 1.8 },
};

/** @param {number} [w] @param {number} [h] @returns {Figure} */
export function newFigure(w = 400, h = 300) {
  return { w: num(w, 400, 20, 2000), h: num(h, 300, 20, 2000), shapes: [] };
}

/**
 * 新しい図形（既定値つき・検査済み）
 * @param {string} type
 * @param {Record<string, any>} [props]
 * @returns {Shape}
 */
export function newShape(type, props = {}) {
  const s = normalizeShape({ ...(DEFAULTS[type] || {}), ...props, type, id: props.id || genId() });
  if (!s) throw new TypeError('知らない図形の種類です：' + type);
  return s;
}

/**
 * 図形を検査して、決まった形に直す。直せないもの（種類が不明など）は null。
 * @param {*} s
 * @returns {Shape|null}
 */
export function normalizeShape(s) {
  if (!s || typeof s !== 'object') return null;
  const type = typeof s.type === 'string' ? s.type : '';
  if (!TYPES.includes(type)) return null;
  const D = DEFAULTS[type];
  const n = (/** @type {string} */ k, min = -LIM, max = LIM) => num(s[k], D[k], min, max);
  /** @type {Shape} */
  const o = {
    id: safeId(s.id) || genId(),
    type,
    stroke: color(s.stroke),
    width: num(s.width, D.width ?? 1.5, 0.25, 20),
    dash: pick(s.dash, DASHES, 'solid'),
    fill: fillOf(s.fill, type === 'point' ? '#000000' : 'none'),
  };
  switch (type) {
    case 'line':
      Object.assign(o, { x1: n('x1'), y1: n('y1'), x2: n('x2'), y2: n('y2'), arrow: pick(s.arrow, ARROWS, 'none') });
      break;
    case 'rect': {
      let x = n('x'), y = n('y'), w = n('w'), h = n('h');
      if (w < 0) { x += w; w = -w; }
      if (h < 0) { y += h; h = -h; }
      Object.assign(o, { x, y, w, h });
      break;
    }
    case 'ellipse':
      Object.assign(o, { cx: n('cx'), cy: n('cy'), rx: Math.abs(n('rx')), ry: Math.abs(n('ry')) });
      break;
    case 'polygon': {
      const src = Array.isArray(s.points) ? s.points.slice(0, MAX_POINTS) : D.points;
      o.points = src.map(p => Array.isArray(p) ? [num(p[0], 0), num(p[1], 0)] : (p && typeof p === 'object' ? [num(p.x, 0), num(p.y, 0)] : [0, 0]));
      o.closed = s.closed === undefined ? true : bool(s.closed);
      break;
    }
    case 'text':
      Object.assign(o, { x: n('x'), y: n('y'), text: str(s.text ?? D.text, 500), size: n('size', 6, 120), anchor: pick(s.anchor, ANCHORS, 'start'), italic: bool(s.italic) });
      break;
    case 'point':
      Object.assign(o, { x: n('x'), y: n('y'), label: str(s.label, 40), r: n('r', 0.5, 20), labelPos: pick(s.labelPos, LABEL_POS, 'ne') });
      break;
    case 'angle':
      Object.assign(o, {
        cx: n('cx'), cy: n('cy'), r: n('r', 2, 500),
        start: ((n('start') % 360) + 360) % 360, end: ((n('end') % 360) + 360) % 360,
        label: str(s.label, 40), right: bool(s.right), arcs: Math.round(n('arcs', 1, 3)),
      });
      break;
    case 'axes': {
      let xmin = n('xmin', -1000, 1000), xmax = n('xmax', -1000, 1000), ymin = n('ymin', -1000, 1000), ymax = n('ymax', -1000, 1000);
      if (xmax <= xmin) xmax = xmin + 1;
      if (ymax <= ymin) ymax = ymin + 1;
      Object.assign(o, {
        ox: n('ox'), oy: n('oy'), unit: n('unit', 1, 500), xmin, xmax, ymin, ymax,
        grid: bool(s.grid), ticks: s.ticks === undefined ? true : bool(s.ticks), labels: s.labels === undefined ? true : bool(s.labels),
        xlabel: str(s.xlabel ?? 'x', 10), ylabel: str(s.ylabel ?? 'y', 10), step: n('step', 0, 1000),
      });
      break;
    }
    case 'graph': {
      const opt = (/** @type {string} */ k) => (s[k] == null || s[k] === '' ? null : num(s[k], null, -1000, 1000));
      Object.assign(o, { expr: str(s.expr ?? D.expr, 300), xmin: opt('xmin'), xmax: opt('xmax'), axesId: safeId(s.axesId) });
      break;
    }
  }
  return o;
}

/**
 * 図全体を検査して、決まった形に直した写しを返す。
 * @param {*} fig
 * @returns {Figure}
 */
export function normalizeFigure(fig) {
  if (!fig || typeof fig !== 'object') return newFigure();
  const out = newFigure(num(fig.w, 400, 20, 2000), num(fig.h, 300, 20, 2000));
  const seen = new Set();
  for (const raw of (Array.isArray(fig.shapes) ? fig.shapes.slice(0, MAX_SHAPES) : [])) {
    const s = normalizeShape(raw);
    if (!s) continue;
    if (seen.has(s.id)) s.id = genId();
    seen.add(s.id);
    out.shapes.push(s);
  }
  return out;
}

/** @param {Figure} fig @returns {Figure} */
export function cloneFigure(fig) {
  return normalizeFigure(JSON.parse(JSON.stringify(fig || newFigure())));
}

// ---------- 関数の式 ----------
const FUNC_NAMES = ['sqrt', 'abs', 'sin', 'cos', 'tan', 'log', 'ln', 'log10', 'exp', 'floor', 'ceil', 'round', 'min', 'max', 'gcd', 'lcm', 'mod', 'sign'];
const VAR_NAMES = ['x', 'pi', 'e'];

/**
 * 手書きふうの式を evaluate で計算できる形に直す。
 * 「y=」を取る、全角→半角、² → ^2、π → pi、省略された掛け算を補う（2x → 2*x、2(x+1)、(x+1)(x-1)、x(x+1)）。
 * @param {*} src
 * @returns {string}
 */
export function normalizeExpr(src) {
  let s = String(src ?? '').replace(/²/g, '^2').replace(/³/g, '^3').replace(/π/g, 'pi');
  s = s.normalize('NFKC').replace(/[−‐–—]/g, '-').replace(/√\s*\(/g, 'sqrt(').replace(/・|·/g, '*').trim();
  s = s.replace(/^\s*(?:y|f\s*\(\s*x\s*\))\s*=\s*/i, '');
  const re = /(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?|[A-Za-z_][A-Za-z0-9_]*|\*\*|\S/g;
  /** @type {{ k: string, v: string }[]} */
  const toks = [];
  for (const m of s.matchAll(re)) {
    const v = m[0];
    if (/^[\d.]/.test(v)) toks.push({ k: 'num', v });
    else if (/^[A-Za-z_]/.test(v)) {
      if (FUNC_NAMES.includes(v)) toks.push({ k: 'fn', v });
      else if (VAR_NAMES.includes(v)) toks.push({ k: 'var', v });
      else {
        // xx・pix・xsin などを分ける。分けられなければそのまま（計算時にエラー）
        const parts = splitIdent(v);
        if (parts) parts.forEach(p => toks.push({ k: FUNC_NAMES.includes(p) ? 'fn' : 'var', v: p }));
        else toks.push({ k: 'var', v });
      }
    } else toks.push({ k: v === '(' ? '(' : v === ')' ? ')' : 'op', v });
  }
  let out = '';
  for (let i = 0; i < toks.length; i++) {
    const a = toks[i - 1], b = toks[i];
    if (a && (a.k === 'num' || a.k === 'var' || a.k === ')') && (b.k === 'var' || b.k === 'fn' || b.k === '(' || (b.k === 'num' && a.k !== 'num'))) out += '*';
    out += b.v;
  }
  return out;
}
/** @param {string} id @returns {string[]|null} */
function splitIdent(id) {
  const names = [...FUNC_NAMES, ...VAR_NAMES].sort((a, b) => b.length - a.length);
  const out = [];
  let i = 0;
  while (i < id.length) {
    const n = names.find(nm => id.startsWith(nm, i));
    if (!n) return null;
    out.push(n);
    i += n.length;
  }
  return out;
}

/**
 * 式が使えるか調べる。
 * @param {*} src
 * @returns {{ ok: boolean, expr: string, error: string }}
 */
export function checkExpr(src) {
  const expr = normalizeExpr(src);
  if (!expr) return { ok: false, expr, error: '式を入れてください' };
  try {
    evaluate(expr, { x: 0.3137 });
    return { ok: true, expr, error: '' };
  } catch (e) {
    return { ok: false, expr, error: e instanceof Error ? e.message : String(e) };
  }
}

/**
 * y = f(x) を xmin～xmax で調べ、つながった部分ごとの点の列（数学の座標）を返す。
 * 計算できない所（NaN・∞）と、表示範囲の外へ大きく飛ぶ所（漸近線など）で切る。
 * @param {string} expr evaluate で計算できる式（x を使う）
 * @param {number} xmin @param {number} xmax
 * @param {number} ymin @param {number} ymax 表示する y の範囲
 * @param {number} [n] 分割数（200 以上）
 * @returns {number[][][]}
 */
export function sampleGraph(expr, xmin, xmax, ymin, ymax, n = 400) {
  n = Math.max(200, Math.min(4000, Math.round(num(n, 400))));
  if (!(xmax > xmin) || !(ymax > ymin)) return [];
  const e = normalizeExpr(expr);
  try { evaluate(e, { x: (xmin + xmax) / 2 }); } catch (err) {
    if (!(err instanceof RangeError)) return [];
  }
  const span = ymax - ymin, lo = ymin - span, hi = ymax + span;
  /** @type {number[][][]} */
  const segs = [];
  /** @type {number[][]} */
  let cur = [];
  const flush = () => { if (cur.length > 1) segs.push(cur); cur = []; };
  for (let i = 0; i <= n; i++) {
    const x = xmin + (xmax - xmin) * i / n;
    let y;
    try { y = evaluate(e, { x }); } catch { y = NaN; }
    if (!Number.isFinite(y) || y < lo || y > hi) { flush(); continue; }
    if (cur.length && Math.abs(y - cur[cur.length - 1][1]) > span) flush();
    cur.push([x, y]);
  }
  flush();
  return segs;
}

/** グラフが使う座標軸（見つからなければ最初の軸、それもなければ図の中央） @param {Figure} fig @param {Shape} g @returns {Shape} */
export function axesFor(fig, g) {
  const list = (fig && fig.shapes || []).filter(s => s.type === 'axes');
  return list.find(s => s.id === g.axesId) || list[0] || newShape('axes', { id: 'auto', ox: (fig?.w || 400) / 2, oy: (fig?.h || 300) / 2 });
}

/** グラフを画面の座標の線（つながった部分ごと）にする @param {Figure} fig @param {Shape} g @returns {number[][][]} */
export function graphSegments(fig, g) {
  const a = axesFor(fig, g);
  const x0 = g.xmin == null ? a.xmin : Math.max(a.xmin, g.xmin);
  const x1 = g.xmax == null ? a.xmax : Math.min(a.xmax, g.xmax);
  const n = Math.max(200, Math.min(2000, Math.round((x1 - x0) * a.unit / 1.5)));
  return sampleGraph(g.expr, x0, x1, a.ymin, a.ymax, n).map(seg => seg.map(([x, y]) => [a.ox + x * a.unit, a.oy - y * a.unit]));
}

// ---------- SVG ----------
let svgSeq = 0;

/** 目もりの間隔（数字が詰まりすぎないように） @param {Shape} a */
function axisStep(a) {
  if (a.step > 0) return a.step;
  const span = Math.max(a.xmax - a.xmin, a.ymax - a.ymin);
  for (const s of [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000]) if (s * a.unit >= 14 && span / s <= 200) return s;
  return 1000;
}

/** @param {Shape} s */
function strokeAttrs(s) {
  let a = ` stroke="${s.stroke}" stroke-width="${f(s.width)}"`;
  if (s.dash === 'dashed') a += ` stroke-dasharray="${f(s.width * 4 + 2)} ${f(s.width * 2.5 + 1.5)}"`;
  else if (s.dash === 'dotted') a += ` stroke-dasharray="${f(s.width * 0.1)} ${f(s.width * 2.5 + 1)}" stroke-linecap="round"`;
  return a;
}
/** @param {number} cx @param {number} cy @param {number} r @param {number} deg */
const polar = (cx, cy, r, deg) => [cx + r * Math.cos(deg * Math.PI / 180), cy - r * Math.sin(deg * Math.PI / 180)];

/** @param {number} x @param {number} y @param {string} t @param {number} size @param {string} [extra] */
const textEl = (x, y, t, size, extra = '') => `<text x="${f(x)}" y="${f(y)}" font-size="${f(size)}"${extra}>${escXml(t)}</text>`;

/**
 * @param {Shape} s
 * @param {{ p: string, markers: Map<string, string>, clips: string[], fig: Figure }} ctx
 */
function shapeSvg(s, ctx) {
  const marker = (/** @type {'s'|'e'} */ end) => {
    const key = end + s.stroke;
    if (!ctx.markers.has(key)) ctx.markers.set(key, ctx.p + 'm' + ctx.markers.size);
    return `url(#${ctx.markers.get(key)})`;
  };
  switch (s.type) {
    case 'line': {
      let m = '';
      if (s.arrow === 'end' || s.arrow === 'both') m += ` marker-end="${marker('e')}"`;
      if (s.arrow === 'start' || s.arrow === 'both') m += ` marker-start="${marker('s')}"`;
      return `<line x1="${f(s.x1)}" y1="${f(s.y1)}" x2="${f(s.x2)}" y2="${f(s.y2)}" fill="none"${strokeAttrs(s)}${m}/>`;
    }
    case 'rect':
      return `<rect x="${f(s.x)}" y="${f(s.y)}" width="${f(s.w)}" height="${f(s.h)}" fill="${s.fill}"${strokeAttrs(s)}/>`;
    case 'ellipse':
      return `<ellipse cx="${f(s.cx)}" cy="${f(s.cy)}" rx="${f(s.rx)}" ry="${f(s.ry)}" fill="${s.fill}"${strokeAttrs(s)}/>`;
    case 'polygon': {
      if (!s.points.length) return '';
      const pts = s.points.map((/** @type {number[]} */ p) => f(p[0]) + ',' + f(p[1])).join(' ');
      return s.closed
        ? `<polygon points="${pts}" fill="${s.fill}"${strokeAttrs(s)}/>`
        : `<polyline points="${pts}" fill="${s.fill}"${strokeAttrs(s)}/>`;
    }
    case 'text': {
      const lines = String(s.text).split('\n');
      const attrs = ` font-size="${f(s.size)}" text-anchor="${s.anchor}" fill="${s.stroke}"${s.italic ? ' font-style="italic"' : ''}`;
      const body = lines.map((t, i) => i === 0 ? escXml(t) : `<tspan x="${f(s.x)}" dy="${f(s.size * 1.25)}">${escXml(t)}</tspan>`).join('');
      return `<text x="${f(s.x)}" y="${f(s.y)}"${attrs}>${body}</text>`;
    }
    case 'point': {
      const fill = s.fill === 'none' ? '#ffffff' : s.fill;
      let out = `<circle cx="${f(s.x)}" cy="${f(s.y)}" r="${f(s.r)}" fill="${fill}" stroke="${s.stroke}" stroke-width="${f(Math.min(s.width, 1.2))}"/>`;
      if (s.label) {
        const d = s.r + 4, size = 14;
        const pos = /** @type {Record<string, number[]>} */ ({ ne: [d, -d], nw: [-d, -d], se: [d, d + size * 0.75], sw: [-d, d + size * 0.75], n: [0, -d - 1], s: [0, d + size * 0.8], e: [d + 1, size * 0.35], w: [-d - 1, size * 0.35] })[s.labelPos];
        const anchor = pos[0] > 0 ? 'start' : pos[0] < 0 ? 'end' : 'middle';
        out += textEl(s.x + pos[0], s.y + pos[1], s.label, size, ` text-anchor="${anchor}" fill="${s.stroke}"`);
      }
      return out;
    }
    case 'angle': {
      const sweep = ((s.end - s.start) % 360 + 360) % 360;
      let out = '';
      if (s.right) {
        const q = s.r * 0.75;
        const [ax, ay] = polar(0, 0, q, s.start), [bx, by] = polar(0, 0, q, s.end);
        const p1 = [s.cx + ax, s.cy + ay], p2 = [s.cx + ax + bx, s.cy + ay + by], p3 = [s.cx + bx, s.cy + by];
        const d = `M${f(p1[0])},${f(p1[1])} L${f(p2[0])},${f(p2[1])} L${f(p3[0])},${f(p3[1])}`;
        if (s.fill !== 'none') out += `<path d="M${f(s.cx)},${f(s.cy)} ${d.slice(1).replace(/^/, 'L')} Z" fill="${s.fill}" stroke="none"/>`;
        out += `<path d="${d}" fill="none"${strokeAttrs(s)}/>`;
      } else if (sweep > 0) {
        for (let i = 0; i < s.arcs; i++) {
          const r = s.r + i * 3.5;
          const [x1, y1] = polar(s.cx, s.cy, r, s.start), [x2, y2] = polar(s.cx, s.cy, r, s.end);
          const arc = `A${f(r)},${f(r)} 0 ${sweep > 180 ? 1 : 0} 0 ${f(x2)},${f(y2)}`;
          if (i === 0 && s.fill !== 'none') out += `<path d="M${f(s.cx)},${f(s.cy)} L${f(x1)},${f(y1)} ${arc} Z" fill="${s.fill}" stroke="none"/>`;
          out += `<path d="M${f(x1)},${f(y1)} ${arc}" fill="none"${strokeAttrs(s)}/>`;
        }
      }
      if (s.label) {
        const size = 13;
        const [lx, ly] = polar(s.cx, s.cy, s.r + (s.arcs - 1) * 3.5 + 10, s.start + (sweep || 90) / 2);
        out += textEl(lx, ly + size * 0.35, s.label, size, ` text-anchor="middle" fill="${s.stroke}"`);
      }
      return out;
    }
    case 'axes': {
      const X = (/** @type {number} */ x) => s.ox + x * s.unit, Y = (/** @type {number} */ y) => s.oy - y * s.unit;
      const step = axisStep(s);
      const y0 = Y(Math.min(s.ymax, Math.max(s.ymin, 0))), x0 = X(Math.min(s.xmax, Math.max(s.xmin, 0)));
      const over = Math.min(s.unit * 0.7, 14);
      let out = '';
      if (s.grid) {
        const gs = s.unit >= 6 ? 1 : step;
        let g = '';
        for (let k = Math.ceil(s.xmin / gs) * gs; k <= s.xmax + 1e-9; k += gs) g += `M${f(X(k))},${f(Y(s.ymin))}V${f(Y(s.ymax))}`;
        for (let k = Math.ceil(s.ymin / gs) * gs; k <= s.ymax + 1e-9; k += gs) g += `M${f(X(s.xmin))},${f(Y(k))}H${f(X(s.xmax))}`;
        out += `<path d="${g}" fill="none" stroke="#b5b5b5" stroke-width="0.5"/>`;
      }
      const ax = { ...s, dash: 'solid' };
      out += `<line x1="${f(X(s.xmin))}" y1="${f(y0)}" x2="${f(X(s.xmax) + over)}" y2="${f(y0)}"${strokeAttrs(ax)} marker-end="${marker('e')}"/>`;
      out += `<line x1="${f(x0)}" y1="${f(Y(s.ymin))}" x2="${f(x0)}" y2="${f(Y(s.ymax) - over)}"${strokeAttrs(ax)} marker-end="${marker('e')}"/>`;
      let ticks = '', labels = '';
      const minus = (/** @type {number} */ k) => (k < 0 ? '−' + f(-k) : f(k));
      for (let k = Math.ceil(s.xmin / step) * step; k <= s.xmax + 1e-9; k += step) {
        if (Math.abs(k) < 1e-9) continue;
        if (s.ticks) ticks += `M${f(X(k))},${f(y0 - 3)}V${f(y0 + 3)}`;
        if (s.labels) labels += textEl(X(k), y0 + 14, minus(k), 11, ' text-anchor="middle"');
      }
      for (let k = Math.ceil(s.ymin / step) * step; k <= s.ymax + 1e-9; k += step) {
        if (Math.abs(k) < 1e-9) continue;
        if (s.ticks) ticks += `M${f(x0 - 3)},${f(Y(k))}H${f(x0 + 3)}`;
        if (s.labels) labels += textEl(x0 - 5, Y(k) + 4, minus(k), 11, ' text-anchor="end"');
      }
      if (ticks) out += `<path d="${ticks}" fill="none" stroke="${s.stroke}" stroke-width="${f(s.width)}"/>`;
      out += `<g fill="${s.stroke}">${labels}`;
      if (s.labels && s.xmin <= 0 && s.xmax >= 0 && s.ymin <= 0 && s.ymax >= 0) out += textEl(x0 - 4, y0 + 14, 'O', 12, ' text-anchor="end" font-style="italic"');
      if (s.xlabel) out += textEl(X(s.xmax) + over + 3, y0 + 4, s.xlabel, 14, ' font-style="italic"');
      if (s.ylabel) out += textEl(x0 + 6, Y(s.ymax) - over + 6, s.ylabel, 14, ' font-style="italic"');
      return out + '</g>';
    }
    case 'graph': {
      const a = axesFor(ctx.fig, s);
      const segs = graphSegments(ctx.fig, s);
      if (!segs.length) return '';
      const id = ctx.p + 'c' + ctx.clips.length;
      const x1 = a.ox + a.xmin * a.unit, x2 = a.ox + a.xmax * a.unit, y1 = a.oy - a.ymax * a.unit, y2 = a.oy - a.ymin * a.unit;
      ctx.clips.push(`<clipPath id="${id}"><rect x="${f(x1)}" y="${f(y1)}" width="${f(x2 - x1)}" height="${f(y2 - y1)}"/></clipPath>`);
      const d = segs.map(seg => 'M' + seg.map(p => f(p[0]) + ',' + f(p[1])).join('L')).join('');
      return `<path d="${d}" fill="none" clip-path="url(#${id})"${strokeAttrs(s)} stroke-linejoin="round"/>`;
    }
  }
  return '';
}

/**
 * 図を単独で使える SVG の文字列にする。
 * @param {Figure} fig
 * @param {{ scale?: number, background?: boolean }} [opts]
 * @returns {string}
 */
export function toSvg(fig, opts = {}) {
  const fg = normalizeFigure(fig);
  const scale = num(opts && opts.scale, 1, 0.05, 20);
  const ctx = { p: 'fg' + (++svgSeq).toString(36) + Math.random().toString(36).slice(2, 6) + '_', markers: new Map(), clips: [], fig: fg };
  const body = fg.shapes.map(s => shapeSvg(s, ctx)).join('');
  let defs = '';
  for (const [key, id] of ctx.markers) {
    const c = key.slice(1);
    const d = key[0] === 'e' ? 'M0,0 L10,5 L0,10 L2.5,5 Z' : 'M10,0 L0,5 L10,10 L7.5,5 Z';
    defs += `<marker id="${id}" viewBox="0 0 10 10" refX="${key[0] === 'e' ? 9 : 1}" refY="5" markerWidth="7" markerHeight="7" markerUnits="userSpaceOnUse" orient="auto"><path d="${d}" fill="${c}"/></marker>`;
  }
  defs += ctx.clips.join('');
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${f(fg.w)} ${f(fg.h)}" width="${f(fg.w * scale)}" height="${f(fg.h * scale)}" font-family="${FONT}" stroke-linecap="round" stroke-linejoin="round">`
    + (defs ? `<defs>${defs}</defs>` : '')
    + (opts && opts.background ? `<rect x="0" y="0" width="${f(fg.w)}" height="${f(fg.h)}" fill="#ffffff"/>` : '')
    + body + '</svg>';
}

// ---------- 当たり判定・移動 ----------
/** 文字の幅のめやす @param {string} t @param {number} size */
export function textWidth(t, size) {
  let w = 0;
  for (const ch of t) w += (ch.codePointAt(0) || 0) >= 0x2e80 ? size : size * 0.55;
  return w;
}

/**
 * 図形を囲む四角（論理単位）
 * @param {Shape} s
 * @param {Figure} [fig] グラフのときに使う
 * @returns {Box}
 */
export function bounds(s, fig) {
  const box = (/** @type {number} */ x1, /** @type {number} */ y1, /** @type {number} */ x2, /** @type {number} */ y2) => ({ x: Math.min(x1, x2), y: Math.min(y1, y2), w: Math.abs(x2 - x1), h: Math.abs(y2 - y1) });
  switch (s.type) {
    case 'line': return box(s.x1, s.y1, s.x2, s.y2);
    case 'rect': return { x: s.x, y: s.y, w: s.w, h: s.h };
    case 'ellipse': return { x: s.cx - s.rx, y: s.cy - s.ry, w: s.rx * 2, h: s.ry * 2 };
    case 'polygon': {
      if (!s.points.length) return { x: 0, y: 0, w: 0, h: 0 };
      const xs = s.points.map((/** @type {number[]} */ p) => p[0]), ys = s.points.map((/** @type {number[]} */ p) => p[1]);
      return box(Math.min(...xs), Math.min(...ys), Math.max(...xs), Math.max(...ys));
    }
    case 'text': {
      const lines = String(s.text).split('\n');
      const w = Math.max(s.size * 0.5, ...lines.map(t => textWidth(t, s.size)));
      const x = s.anchor === 'middle' ? s.x - w / 2 : s.anchor === 'end' ? s.x - w : s.x;
      return { x, y: s.y - s.size * 0.85, w, h: s.size * (1 + (lines.length - 1) * 1.25) };
    }
    case 'point': return { x: s.x - s.r, y: s.y - s.r, w: s.r * 2, h: s.r * 2 };
    case 'angle': return { x: s.cx - s.r, y: s.cy - s.r, w: s.r * 2, h: s.r * 2 };
    case 'axes': return box(s.ox + s.xmin * s.unit, s.oy - s.ymax * s.unit, s.ox + s.xmax * s.unit, s.oy - s.ymin * s.unit);
    case 'graph': {
      const pts = graphSegments(fig || newFigure(), s).flat();
      if (!pts.length) return { x: 0, y: 0, w: 0, h: 0 };
      const a = axesFor(fig || newFigure(), s);
      const top = a.oy - a.ymax * a.unit, bot = a.oy - a.ymin * a.unit;
      const ys = pts.map(p => Math.min(bot, Math.max(top, p[1])));
      return box(Math.min(...pts.map(p => p[0])), Math.min(...ys), Math.max(...pts.map(p => p[0])), Math.max(...ys));
    }
  }
  return { x: 0, y: 0, w: 0, h: 0 };
}

/** 点と線分の距離 */
function distSeg(/** @type {number} */ px, /** @type {number} */ py, /** @type {number} */ ax, /** @type {number} */ ay, /** @type {number} */ bx, /** @type {number} */ by) {
  const dx = bx - ax, dy = by - ay, L = dx * dx + dy * dy;
  const t = L ? Math.max(0, Math.min(1, ((px - ax) * dx + (py - ay) * dy) / L)) : 0;
  return Math.hypot(px - ax - t * dx, py - ay - t * dy);
}
/** @param {number[][]} pts @param {number} x @param {number} y */
function insidePoly(pts, x, y) {
  let c = false;
  for (let i = 0, j = pts.length - 1; i < pts.length; j = i++) {
    const [xi, yi] = pts[i], [xj, yj] = pts[j];
    if ((yi > y) !== (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi) c = !c;
  }
  return c;
}

/**
 * (x, y) の近くにある図形のうち、いちばん上のものの id。なければ null。
 * @param {Figure} fig
 * @param {number} x @param {number} y
 * @param {number} [tol] 許す距離（論理単位）
 * @returns {string|null}
 */
export function hitTest(fig, x, y, tol = 5) {
  const shapes = (fig && fig.shapes) || [];
  for (let i = shapes.length - 1; i >= 0; i--) if (hitShape(fig, shapes[i], x, y, tol)) return shapes[i].id;
  return null;
}
/** @param {Figure} fig @param {Shape} s @param {number} x @param {number} y @param {number} tol */
function hitShape(fig, s, x, y, tol) {
  switch (s.type) {
    case 'line': return distSeg(x, y, s.x1, s.y1, s.x2, s.y2) <= tol;
    case 'rect': {
      if (s.fill !== 'none' && x >= s.x && x <= s.x + s.w && y >= s.y && y <= s.y + s.h) return true;
      const c = [[s.x, s.y], [s.x + s.w, s.y], [s.x + s.w, s.y + s.h], [s.x, s.y + s.h]];
      return c.some((p, i) => distSeg(x, y, p[0], p[1], c[(i + 1) % 4][0], c[(i + 1) % 4][1]) <= tol);
    }
    case 'ellipse': {
      const rx = Math.max(s.rx, 0.01), ry = Math.max(s.ry, 0.01);
      const d = Math.hypot((x - s.cx) / rx, (y - s.cy) / ry);
      return (s.fill !== 'none' && d <= 1) || Math.abs(d - 1) * Math.min(rx, ry) <= tol || Math.hypot(x - s.cx, y - s.cy) <= tol;
    }
    case 'polygon': {
      const p = s.points;
      if (s.closed && s.fill !== 'none' && insidePoly(p, x, y)) return true;
      const n = s.closed ? p.length : p.length - 1;
      for (let i = 0; i < n; i++) { const a = p[i], b = p[(i + 1) % p.length]; if (distSeg(x, y, a[0], a[1], b[0], b[1]) <= tol) return true; }
      return p.length === 1 && Math.hypot(x - p[0][0], y - p[0][1]) <= tol;
    }
    case 'text': {
      const b = bounds(s);
      return x >= b.x - tol && x <= b.x + b.w + tol && y >= b.y - tol && y <= b.y + b.h + tol;
    }
    case 'point': return Math.hypot(x - s.x, y - s.y) <= s.r + tol;
    case 'angle': return Math.hypot(x - s.cx, y - s.cy) <= s.r + tol;
    case 'axes': {
      const X = (/** @type {number} */ v) => s.ox + v * s.unit, Y = (/** @type {number} */ v) => s.oy - v * s.unit;
      const y0 = Y(Math.min(s.ymax, Math.max(s.ymin, 0))), x0 = X(Math.min(s.xmax, Math.max(s.xmin, 0)));
      return distSeg(x, y, X(s.xmin), y0, X(s.xmax) + 14, y0) <= tol || distSeg(x, y, x0, Y(s.ymin), x0, Y(s.ymax) - 14) <= tol;
    }
    case 'graph': {
      const a = axesFor(fig, s);
      const top = a.oy - a.ymax * a.unit - tol, bot = a.oy - a.ymin * a.unit + tol;
      if (y < top || y > bot) return false;
      for (const seg of graphSegments(fig, s)) {
        for (let i = 1; i < seg.length; i++) if (distSeg(x, y, seg[i - 1][0], seg[i - 1][1], seg[i][0], seg[i][1]) <= tol) return true;
      }
      return false;
    }
  }
  return false;
}

/**
 * 図形を動かした写しを返す（グラフは軸についていくので動かない）。
 * @param {Shape} s @param {number} dx @param {number} dy
 * @returns {Shape}
 */
export function moveShape(s, dx, dy) {
  dx = num(dx, 0); dy = num(dy, 0);
  const o = { ...s };
  switch (s.type) {
    case 'line': o.x1 += dx; o.y1 += dy; o.x2 += dx; o.y2 += dy; break;
    case 'rect': case 'text': case 'point': o.x += dx; o.y += dy; break;
    case 'ellipse': case 'angle': o.cx += dx; o.cy += dy; break;
    case 'polygon': o.points = s.points.map((/** @type {number[]} */ p) => [p[0] + dx, p[1] + dy]); break;
    case 'axes': o.ox += dx; o.oy += dy; break;
  }
  return o;
}

/**
 * 大きさを変えるつまみの位置
 * @param {Shape} s
 * @returns {Handle[]}
 */
export function handles(s) {
  switch (s.type) {
    case 'line': return [{ key: 'p1', x: s.x1, y: s.y1 }, { key: 'p2', x: s.x2, y: s.y2 }];
    case 'rect': case 'ellipse': {
      const b = bounds(s);
      return [{ key: 'nw', x: b.x, y: b.y }, { key: 'ne', x: b.x + b.w, y: b.y }, { key: 'sw', x: b.x, y: b.y + b.h }, { key: 'se', x: b.x + b.w, y: b.y + b.h }];
    }
    case 'polygon': return s.points.map((/** @type {number[]} */ p, /** @type {number} */ i) => ({ key: 'v' + i, x: p[0], y: p[1] }));
    case 'text': { const b = bounds(s); return [{ key: 'size', x: b.x + b.w, y: b.y + b.h }]; }
    case 'point': return [{ key: 'r', x: s.x + s.r + 6, y: s.y }];
    case 'angle': {
      const sweep = ((s.end - s.start) % 360 + 360) % 360 || 90;
      const [x, y] = polar(s.cx, s.cy, s.r, s.start + sweep / 2);
      return [{ key: 'r', x, y }];
    }
    case 'axes': {
      const y0 = s.oy - Math.min(s.ymax, Math.max(s.ymin, 0)) * s.unit, x0 = s.ox + Math.min(s.xmax, Math.max(s.xmin, 0)) * s.unit;
      return [
        { key: 'xmin', x: s.ox + s.xmin * s.unit, y: y0 }, { key: 'xmax', x: s.ox + s.xmax * s.unit, y: y0 },
        { key: 'ymin', x: x0, y: s.oy - s.ymin * s.unit }, { key: 'ymax', x: x0, y: s.oy - s.ymax * s.unit },
      ];
    }
  }
  return [];
}

/**
 * つまみを (x, y) へ動かしたときの図形の写し
 * @param {Shape} s @param {string} key @param {number} x @param {number} y
 * @returns {Shape}
 */
export function applyHandle(s, key, x, y) {
  x = num(x, 0); y = num(y, 0);
  const o = { ...s };
  const corner = (/** @type {Box} */ b) => {
    const fx = key.includes('w') ? b.x + b.w : b.x, fy = key[0] === 'n' ? b.y + b.h : b.y;
    return { x: Math.min(fx, x), y: Math.min(fy, y), w: Math.abs(x - fx), h: Math.abs(y - fy) };
  };
  switch (s.type) {
    case 'line': if (key === 'p1') { o.x1 = x; o.y1 = y; } else if (key === 'p2') { o.x2 = x; o.y2 = y; } break;
    case 'rect': Object.assign(o, corner(bounds(s))); break;
    case 'ellipse': { const b = corner(bounds(s)); Object.assign(o, { cx: b.x + b.w / 2, cy: b.y + b.h / 2, rx: b.w / 2, ry: b.h / 2 }); break; }
    case 'polygon': {
      const i = Number(key.slice(1));
      if (Number.isInteger(i) && i >= 0 && i < s.points.length) o.points = s.points.map((/** @type {number[]} */ p, /** @type {number} */ j) => (j === i ? [x, y] : p));
      break;
    }
    case 'text': { const top = s.y - s.size * 0.85; o.size = Math.round(Math.max(6, Math.min(120, (y - top) / (1 + (String(s.text).split('\n').length - 1) * 1.25)))); break; }
    case 'point': o.r = Math.max(0.5, Math.min(20, Math.round((x - s.x - 6) * 2) / 2)); break;
    case 'angle': o.r = Math.max(4, Math.min(500, Math.round(Math.hypot(x - s.cx, y - s.cy)))); break;
    case 'axes': {
      const ux = Math.round((x - s.ox) / s.unit), uy = Math.round((s.oy - y) / s.unit);
      if (key === 'xmax') o.xmax = Math.max(s.xmin + 1, ux);
      if (key === 'xmin') o.xmin = Math.min(s.xmax - 1, ux);
      if (key === 'ymax') o.ymax = Math.max(s.ymin + 1, uy);
      if (key === 'ymin') o.ymin = Math.min(s.ymax - 1, uy);
      break;
    }
  }
  return o;
}

/**
 * ほかの図形をくっつけるための点（頂点・端点・中心など）
 * @param {Figure} fig @param {string} [exceptId]
 * @returns {number[][]}
 */
export function snapPoints(fig, exceptId) {
  /** @type {number[][]} */
  const out = [];
  for (const s of (fig && fig.shapes) || []) {
    if (s.id === exceptId) continue;
    if (s.type === 'line') out.push([s.x1, s.y1], [s.x2, s.y2]);
    else if (s.type === 'rect') out.push([s.x, s.y], [s.x + s.w, s.y], [s.x, s.y + s.h], [s.x + s.w, s.y + s.h]);
    else if (s.type === 'ellipse') out.push([s.cx, s.cy]);
    else if (s.type === 'polygon') out.push(...s.points);
    else if (s.type === 'point') out.push([s.x, s.y]);
    else if (s.type === 'angle') out.push([s.cx, s.cy]);
    else if (s.type === 'axes') out.push([s.ox, s.oy]);
  }
  return out;
}

// ---------- よく使う図のひな形（400×300 の図に合う位置） ----------
/** 三角形 ABC（頂点の名前つき） @returns {Shape[]} */
export function presetTriangle() {
  const A = [200, 60], B = [90, 240], C = [320, 240];
  return [
    newShape('polygon', { points: [A, B, C], closed: true }),
    newShape('text', { x: A[0], y: A[1] - 8, text: 'A', size: 16, anchor: 'middle' }),
    newShape('text', { x: B[0] - 8, y: B[1] + 14, text: 'B', size: 16, anchor: 'end' }),
    newShape('text', { x: C[0] + 8, y: C[1] + 14, text: 'C', size: 16, anchor: 'start' }),
  ];
}
/** 中心 O の円（半径の線つき） @returns {Shape[]} */
export function presetCircleWithCenter() {
  return [
    newShape('ellipse', { cx: 200, cy: 150, rx: 90, ry: 90 }),
    newShape('point', { x: 200, y: 150, label: 'O', labelPos: 'sw' }),
    newShape('line', { x1: 200, y1: 150, x2: 290, y2: 150 }),
  ];
}
/** 座標軸と y = f(x) のグラフ @param {string} [expr] @returns {Shape[]} */
export function presetAxesWithGraph(expr = 'x^2') {
  const ax = newShape('axes', { ox: 200, oy: 170, unit: 20, xmin: -9, xmax: 8, ymin: -6, ymax: 6, grid: true });
  return [ax, newShape('graph', { expr: normalizeExpr(expr) || 'x', axesId: ax.id })];
}
/** −5 から 5 までの数直線 @returns {Shape[]} */
export function presetNumberLine() {
  const y = 150, x0 = 200, u = 30;
  /** @type {Shape[]} */
  const out = [newShape('line', { x1: x0 - 5.6 * u, y1: y, x2: x0 + 5.8 * u, y2: y, arrow: 'end' })];
  for (let k = -5; k <= 5; k++) {
    out.push(newShape('line', { x1: x0 + k * u, y1: y - (k === 0 ? 7 : 5), x2: x0 + k * u, y2: y + (k === 0 ? 7 : 5), width: 1 }));
    out.push(newShape('text', { x: x0 + k * u, y: y + 22, text: k < 0 ? '−' + -k : String(k), size: 13, anchor: 'middle' }));
  }
  return out;
}
