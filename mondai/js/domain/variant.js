// 数値替え問題（同じ問題で数値だけを変えた版）を作る
//
// 問題に vary（テンプレート）を持たせる：
//   vary: {
//     vars:  { a: { min: 2, max: 9, step?: 1, not?: [0] }, b: { values: [2, 3, 5] } },
//     where: ['a != b', 'a*b < 30'],           // すべて満たす組だけ使う（== != < <= > >=、and は配列で）
//     integer: ['(a+b)/2'],                    // 整数になる必要がある式
//     stem: '… {{a}} … {{=a*b}} …',            // 置きかえ後の問題文（sentence / choices / ans / expl / steps / alts も同じ書き方）
//     choices: ['{{=a+b}}', …], ans: '{{=a*b}}', expl: '…', steps: ['…'],
//     check: 'a*b'                             // 数値の答えの式（あれば機械検算に使う）
//   }
// 置きかえの書き方：{{a}} 変数の値／{{=式}} 式の値／{{=式|frac}} 分数（LaTeX）／{{=式|2}} 小数第2位まで
//   {{=式|sign}} 符号つき（+3 / -3）／{{=式|coef}} 係数（1→空、-1→-）／{{=式|abs}} 絶対値
// 値は乱数（シードで再現できる）で選び、条件・整数・選択肢の重複を確かめてから使う。
import { evaluate, parseAnswerNumber, nearlyEqual } from './mathcheck.js';

const TEMPLATE_FIELDS = ['stem', 'sentence', 'ans', 'expl', 'explBasic', 'explAdvanced'];
const LIST_FIELDS = ['choices', 'steps', 'alts', 'mistakes'];

/** シードつき乱数 */
export function seeded(seed) {
  let h = 2166136261 >>> 0;
  for (const ch of String(seed)) { h ^= ch.charCodeAt(0); h = Math.imul(h, 16777619); }
  return () => {
    h += 0x6D2B79F5;
    let t = h;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const gcd = (a, b) => { a = Math.abs(a); b = Math.abs(b); while (b) [a, b] = [b, a % b]; return a; };

/** 数を表示用の文字にする */
export function formatNumber(v, fmt = '') {
  if (!Number.isFinite(v)) throw new RangeError('値が数になりません');
  const round = (x) => (Math.abs(x - Math.round(x)) < 1e-9 ? Math.round(x) : x);
  const plain = (x) => {
    const r = round(x);
    if (Number.isInteger(r)) return String(r);
    return String(Number(r.toPrecision(10)));
  };
  if (fmt === 'sign') { const s = plain(v); return v >= 0 ? '+' + s : s; }
  if (fmt === 'abs') return plain(Math.abs(v));
  if (fmt === 'coef') { const r = round(v); return r === 1 ? '' : r === -1 ? '-' : plain(v); }
  if (/^\d+$/.test(fmt)) return v.toFixed(Number(fmt));
  if (fmt === 'frac') {
    const r = round(v);
    if (Number.isInteger(r)) return String(r);
    // 分母 1000 までで近い分数を探す
    for (let d = 2; d <= 1000; d++) {
      const n = Math.round(v * d);
      if (Math.abs(n / d - v) < 1e-9) {
        const g = gcd(n, d);
        const p = n / g, q = d / g;
        return `${p < 0 ? '-' : ''}\\frac{${Math.abs(p)}}{${q}}`;
      }
    }
    return plain(v);
  }
  return plain(v);
}

/** テンプレートの文字に値を入れる */
export function fill(text, vals) {
  if (typeof text !== 'string') return text;
  return text.replace(/\{\{\s*(=)?([^}|]+?)\s*(?:\|\s*([a-z0-9]+)\s*)?\}\}/g, (_, eq, body, fmt) => {
    if (eq) return formatNumber(evaluate(body, vals), fmt || '');
    const name = body.trim();
    if (!Object.hasOwn(vals, name)) throw new ReferenceError(`変数 ${name} がありません`);
    return formatNumber(vals[name], fmt || '');
  });
}

/** 条件式（比較つき）を確かめる */
export function cond(expr, vals) {
  const m = /^(.*?)(==|!=|<=|>=|<|>)(.*)$/.exec(expr);
  if (!m) return evaluate(expr, vals) !== 0;
  const a = evaluate(m[1], vals), b = evaluate(m[3], vals);
  switch (m[2]) {
    case '==': return nearlyEqual(a, b);
    case '!=': return !nearlyEqual(a, b);
    case '<': return a < b - 1e-12;
    case '<=': return a <= b + 1e-12;
    case '>': return a > b + 1e-12;
    default: return a >= b - 1e-12;
  }
}

function pick(spec, rand) {
  let vals;
  if (Array.isArray(spec.values) && spec.values.length) vals = spec.values;
  else {
    const step = spec.step || 1;
    vals = [];
    for (let x = spec.min; x <= spec.max + 1e-9 && vals.length < 2000; x += step) vals.push(Math.round(x * 1e9) / 1e9);
  }
  if (spec.not) vals = vals.filter(v => !spec.not.includes(v));
  if (!vals.length) throw new RangeError('変数の候補がありません');
  return vals[Math.floor(rand() * vals.length)];
}

/** テンプレートの形を確かめる。問題があれば日本語のメッセージ */
export function validateVary(vary) {
  if (!vary || typeof vary !== 'object') return 'vary がありません';
  if (!vary.vars || !Object.keys(vary.vars).length) return '変数（vars）がありません';
  for (const [k, s] of Object.entries(vary.vars)) {
    if (!/^[A-Za-z_]\w*$/.test(k) || ['pi', 'e'].includes(k)) return `変数名 ${k} は使えません`;
    if (!(Array.isArray(s.values) && s.values.length) && !(Number.isFinite(s.min) && Number.isFinite(s.max) && s.min <= s.max)) return `変数 ${k} の範囲が正しくありません`;
  }
  if (!vary.stem) return '問題文のテンプレート（stem）がありません';
  return '';
}

/**
 * 数値替えの版を作る
 * @param {any} q 元の問題（q.vary が必要。なければ autoVary を先に使う）
 * @param {{seed?: any, tries?: number, avoid?: any[]}} [opt] avoid：避ける値の組（元の問題と同じ値を避けるなど）
 * @returns {{ok: boolean, q?: any, values?: Record<string, number>, reason?: string}}
 */
export function makeVariant(q, opt = {}) {
  const vary = q.vary;
  const err = validateVary(vary);
  if (err) return { ok: false, reason: err };
  const rand = seeded(opt.seed ?? Date.now());
  const tries = opt.tries || 200;
  const avoid = (opt.avoid || []).map(v => JSON.stringify(v));
  let lastReason = '条件に合う数値が見つかりませんでした';
  for (let t = 0; t < tries; t++) {
    /** @type {Record<string, number>} */
    const vals = {};
    for (const [k, s] of Object.entries(vary.vars)) vals[k] = pick(s, rand);
    if (avoid.includes(JSON.stringify(vals))) continue;
    try {
      if ((vary.where || []).some(w => !cond(w, vals))) continue;
      if ((vary.integer || []).some(ex => { const v = evaluate(ex, vals); return Math.abs(v - Math.round(v)) > 1e-9; })) continue;
      const out = JSON.parse(JSON.stringify(q));
      for (const f of TEMPLATE_FIELDS) if (vary[f] != null) out[f] = fill(vary[f], vals);
      for (const f of LIST_FIELDS) if (Array.isArray(vary[f])) out[f] = vary[f].map(x => fill(x, vals));
      if (Array.isArray(vary.rubric)) out.rubric = vary.rubric.map(r => ({ ...r, c: fill(r.c, vals) }));
      // 選択肢がすべて違うこと
      if (out.choices && out.choices.length && new Set(out.choices.map(c => String(c).replace(/\s+/g, ''))).size !== out.choices.length) { lastReason = '選択肢が重なりました'; continue; }
      // 機械検算：答えの式と答えの文字が一致すること
      if (vary.check) {
        const v = evaluate(vary.check, vals);
        if (!Number.isFinite(v)) { lastReason = '答えが数になりません'; continue; }
        out.check = { expr: formatNumber(v) };
        const target = out.choices && out.choices.length && out.ai && out.ai.length === 1 ? out.choices[out.ai[0]] : out.ans;
        const got = parseAnswerNumber(target);
        if (got == null || !nearlyEqual(got, v, 1e-6)) { lastReason = `答え（${target}）が式の値（${formatNumber(v)}）と一致しません`; continue; }
      }
      delete out.vary;
      out.variantOf = q.id;
      out.variantValues = vals;
      return { ok: true, q: out, values: vals };
    } catch (e) {
      lastReason = e.message;
    }
  }
  return { ok: false, reason: lastReason };
}

/** 元の問題の値（テンプレートから元の文が作れる値の組）。分からなければ null */
export function originalValues(q) {
  if (!q.vary) return null;
  return q.vary.original || null;
}

/**
 * テンプレートのない問題から、検算の式（q.check）を手がかりにテンプレートを作る
 * 問題文と式の両方に同じ数が出てくるとき、その数を変数にする。べき乗の指数・添字の数は変えない。
 * 作ったテンプレートは自動のもの（auto: true）なので、できた問題は人が確認する
 * @returns {any|null}
 */
export function autoVary(q) {
  if (!q.check || !q.check.expr || q.vary) return null;
  if (!['short', 'choice'].includes(q.type)) return null;
  const expr = String(q.check.expr);
  const nums = [...new Set((expr.match(/\d+(?:\.\d+)?/g) || []).filter(n => Number(n) >= 2 && Number(n) <= 10000))];
  if (!nums.length) return null;
  const stem = String(q.stem || '');
  const vars = {}, used = [];
  let tStem = stem, tExpr = expr;
  const names = 'abcdfghkmnpqrstuvw'.split('');
  for (const n of nums) {
    // 問題文の中で、ほかの数字の一部でなく、^ や _ の直後でもないところ
    const re = new RegExp(`(?<![\\d.^_{])${n.replace('.', '\\.')}(?![\\d.])`, 'g');
    if (!re.test(stem)) continue;
    const name = names[used.length];
    if (!name) break;
    const v = Number(n);
    const isInt = Number.isInteger(v);
    vars[name] = isInt ? { min: Math.max(2, Math.ceil(v / 2)), max: Math.max(v + 3, v * 2), not: [] } : { values: [v * 0.5, v * 0.8, v * 1.2, v * 1.5, v * 2].map(x => Number(x.toFixed(3))) };
    used.push(n);
    tStem = tStem.replace(re, `{{${name}}}`);
    tExpr = tExpr.replace(new RegExp(`(?<![\\d.])${n.replace('.', '\\.')}(?![\\d.])`, 'g'), name);
  }
  if (!used.length) return null;
  const v0 = (() => { try { return evaluate(expr); } catch (e) { return null; } })();
  if (v0 == null) return null;
  const ansIsInt = Number.isInteger(Math.round(v0 * 1e9) / 1e9);
  const vary = { auto: true, vars, stem: tStem, check: tExpr, integer: ansIsInt ? [tExpr] : [] };
  if (q.type === 'short') {
    const a = String(q.ans || '');
    const num = parseAnswerNumber(a);
    if (num == null || !nearlyEqual(num, v0)) return null;
    // 答えの中の数を式に置きかえる（単位などはそのまま）
    const m = /-?\d+(?:\.\d+)?/.exec(a.replace(/[−ー]/g, '-'));
    if (!m) return null;
    vary.ans = a.replace(/[−ー]/g, '-').replace(m[0], `{{=${tExpr}}}`);
  } else {
    // 選択式：正解の選択肢が式の値なら、ほかの選択肢は正解との差を保って作りかえる
    const correct = q.choices[q.ai[0]];
    const cv = parseAnswerNumber(correct);
    if (cv == null || !nearlyEqual(cv, v0)) return null;
    const re = /-?\d+(?:\.\d+)?/;
    vary.choices = q.choices.map((c) => {
      const s = String(c).replace(/[−ー]/g, '-');
      const x = parseAnswerNumber(s);
      const m = re.exec(s);
      if (x == null || !m) return null;
      const d = x - cv;
      return s.replace(m[0], `{{=${tExpr}${d ? (d > 0 ? '+' : '') + formatNumber(d) : ''}}}`);
    });
    if (vary.choices.some(c => c == null)) return null;
  }
  return vary;
}

/** この問題から数値替えが作れるか（テンプレートあり、または自動で作れる） */
export function canVary(q) {
  return !!(q && (q.vary || autoVary(q)));
}

/**
 * 数値替えを作る（テンプレートがなければ自動テンプレートで）。元と同じ値は避ける
 * @returns {{ok: boolean, q?: any, auto?: boolean, reason?: string}}
 */
export function varyQuestion(q, seed) {
  const auto = !q.vary;
  const vary = q.vary || autoVary(q);
  if (!vary) return { ok: false, reason: '数値替えのテンプレートがなく、検算の式からも作れません' };
  const r = makeVariant({ ...q, vary }, { seed, avoid: vary.original ? [vary.original] : [] });
  if (!r.ok) return r;
  // 元の問題文と同じになったら作り直す
  if (r.q.stem === q.stem) {
    const r2 = makeVariant({ ...q, vary }, { seed: String(seed) + 'x' });
    if (!r2.ok || r2.q.stem === q.stem) return { ok: false, reason: '元と違う数値の組が見つかりませんでした' };
    return { ...r2, auto };
  }
  return { ...r, auto };
}
