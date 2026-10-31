// 問題の検索。キーワードの AND・OR・除外・"語句"・項目指定（subj:数学 など）・かっこに対応する。
import { QUESTION_TYPES, STATUSES } from './question.js';

/**
 * @typedef {import('./question.js').Question} Question
 * @typedef {{ type: 'and', children: QueryNode[] }
 *   | { type: 'or', children: QueryNode[] }
 *   | { type: 'not', child: QueryNode }
 *   | { type: 'term', value: string, phrase: boolean }
 *   | { type: 'field', field: string, value: string }} QueryNode
 *
 * @typedef {Object} SearchFilters
 * @property {string} [subj]
 * @property {string} [stage]
 * @property {string} [grade]
 * @property {string} [course]
 * @property {Set<string>|string[]} [units] いずれかに一致（OR）
 * @property {string} [level]
 * @property {string} [type]
 * @property {string} [src]
 * @property {string} [cat]
 * @property {string} [status]
 * @property {string[]} [tags] すべて含む（AND）
 * @property {boolean} [includeDeleted] 論理削除された問題も含める
 */

/** 項目指定で使えるキー（別名 → 正式名） */
const FIELD_ALIASES = {
  subj: 'subj', subject: 'subj', 教科: 'subj',
  course: 'course', 科目: 'course',
  grade: 'grade', 学年: 'grade',
  unit: 'unit', 単元: 'unit',
  subunit: 'subunit', 小単元: 'subunit',
  level: 'level', 難易度: 'level',
  type: 'type', 形式: 'type',
  src: 'src', source: 'src', 出典: 'src',
  tag: 'tag', tags: 'tag', タグ: 'tag',
  status: 'status', 状態: 'status',
  stage: 'stage', 段階: 'stage',
  cat: 'cat', 区分: 'cat',
  id: 'id',
  origin: 'origin',
};
export const FIELD_KEYS = Array.from(new Set(Object.values(FIELD_ALIASES)));

/** 比較用の正規化（全角半角をそろえ、小文字にする） @param {*} s */
export function fold(s) {
  return String(s == null ? '' : s).normalize('NFKC').toLowerCase();
}

// ---------- 字句解析 ----------
/**
 * @typedef {{ t: 'open' } | { t: 'close' } | { t: 'or' } | { t: 'not' } | { t: 'word', v: string, quoted: boolean }} Token
 */
const SPACE = /[\s　]/;
const QUOTE_OPEN = { '"': '"', '“': '”', '「': '」' };

/** @param {string} s @returns {Token[]} */
function tokenize(s) {
  /** @type {Token[]} */
  const out = [];
  let i = 0;
  let depth = 0;
  const n = s.length;
  while (i < n) {
    const c = s[i];
    if (SPACE.test(c)) { i++; continue; }
    if (c === '(') { out.push({ t: 'open' }); depth++; i++; continue; }
    if (c === ')') { if (depth > 0) { out.push({ t: 'close' }); depth--; } i++; continue; }
    if ((c === '-' || c === '－') && i + 1 < n && !SPACE.test(s[i + 1])) { out.push({ t: 'not' }); i++; continue; }
    if (c === '|' || c === '｜') { out.push({ t: 'or' }); i++; continue; }
    // 語（途中に "..." があればその中の空白も語の一部）
    let v = '';
    let quoted = false;
    let inner = 0;
    while (i < n) {
      const ch = s[i];
      const close = QUOTE_OPEN[ch];
      if (close) {
        const j = s.indexOf(close, i + 1);
        const end = j < 0 ? n : j;
        v += s.slice(i + 1, end);
        quoted = true;
        i = end + 1;
        continue;
      }
      if (SPACE.test(ch)) break;
      if (ch === '(') inner++;
      if (ch === ')') {
        if (inner === 0) break;
        inner--;
      }
      v += ch;
      i++;
    }
    if (!quoted && v === 'OR') out.push({ t: 'or' });
    else if (quoted || (v !== '' && v !== '-' && v !== '－')) out.push({ t: 'word', v, quoted });
  }
  return out;
}

// ---------- 構文解析 ----------
/**
 * 検索文字列を構文木にする。空なら null（すべて一致）。
 * 優先順位：除外（-）＞ AND（並べる）＞ OR。
 * @param {string} str
 * @returns {QueryNode|null}
 */
export function parseQuery(str) {
  const tokens = tokenize(String(str == null ? '' : str));
  let pos = 0;
  const peek = () => tokens[pos];

  /** @returns {QueryNode|null} */
  function parseOr() {
    /** @type {QueryNode[]} */
    const parts = [];
    let node = parseAnd();
    if (node) parts.push(node);
    while (peek() && peek().t === 'or') {
      pos++;
      node = parseAnd();
      if (node) parts.push(node);
    }
    if (!parts.length) return null;
    return parts.length === 1 ? parts[0] : { type: 'or', children: parts };
  }
  /** @returns {QueryNode|null} */
  function parseAnd() {
    /** @type {QueryNode[]} */
    const parts = [];
    while (peek() && peek().t !== 'or' && peek().t !== 'close') {
      const node = parseUnary();
      if (node) parts.push(node);
    }
    if (!parts.length) return null;
    return parts.length === 1 ? parts[0] : { type: 'and', children: parts };
  }
  /** @returns {QueryNode|null} */
  function parseUnary() {
    const tk = peek();
    if (!tk) return null;
    if (tk.t === 'not') {
      pos++;
      const child = parseUnary();
      return child ? { type: 'not', child } : null;
    }
    return parsePrimary();
  }
  /** @returns {QueryNode|null} */
  function parsePrimary() {
    const tk = tokens[pos++];
    if (!tk) return null;
    if (tk.t === 'open') {
      const inner = parseOr();
      if (peek() && peek().t === 'close') pos++;
      return inner;
    }
    if (tk.t === 'word') return wordNode(tk.v, tk.quoted);
    return null;
  }
  const ast = parseOr();
  // 余った閉じかっこなどは読み飛ばし、残りを AND でつなぐ
  /** @type {QueryNode[]} */
  const rest = [];
  while (pos < tokens.length) {
    pos++;
    const more = parseOr();
    if (more) rest.push(more);
  }
  if (!rest.length) return ast;
  return { type: 'and', children: (ast ? [ast] : []).concat(rest) };
}

/** @param {string} v @param {boolean} quoted @returns {QueryNode} */
function wordNode(v, quoted) {
  const m = /^([^:：]+)[:：]([\s\S]*)$/.exec(v);
  if (m) {
    const k = m[1].toLowerCase();
    const key = Object.hasOwn(FIELD_ALIASES, k) ? FIELD_ALIASES[k] : '';
    if (key) return { type: 'field', field: key, value: m[2] };
  }
  return { type: 'term', value: v, phrase: quoted };
}

// ---------- 照合 ----------
/** @type {WeakMap<object, {sig: string, text: string}>} */
const hayCache = new WeakMap();

/** @param {Question} q */
function haystack(q) {
  const sig = `${q.rev || ''}|${q.updatedAt || ''}|${(q.stem || '').length}`;
  const c = hayCache.get(q);
  if (c && c.sig === sig) return c.text;
  const parts = [q.stem, q.sentence, (q.choices || []).join('\n'), q.ans, q.expl, q.unit, q.subunit, q.set,
    (q.tags || []).join('\n'), q.course, (q.alts || []).join('\n')];
  for (const s of q.subs || []) parts.push(s.stem, (s.choices || []).join('\n'), s.ans);
  const text = fold(parts.filter(Boolean).join('\n'));
  hayCache.set(q, { sig, text });
  return text;
}

/** 形式は内部名でも日本語名でも指定できる @param {string} v */
function typeKey(v) {
  const f = fold(v);
  for (const [k, d] of Object.entries(QUESTION_TYPES)) if (fold(k) === f || fold(d.label) === f) return k;
  return v;
}
/** @param {string} v */
function statusKey(v) {
  const f = fold(v);
  for (const [k, label] of Object.entries(STATUSES)) if (fold(k) === f || fold(label) === f) return k;
  return v;
}

/** @param {string} field @param {string} value @param {Question} q */
function matchField(field, value, q) {
  const v = fold(value);
  const has = (/** @type {*} */ x) => fold(x).includes(v);
  const eq = (/** @type {*} */ x) => fold(x) === v;
  switch (field) {
    case 'unit': return v === '' ? !(q.unit || q.set) : has(q.unit || q.set);
    case 'subunit': return v === '' ? !q.subunit : has(q.subunit);
    case 'course': return v === '' ? !q.course : has(q.course);
    case 'type': return q.type === typeKey(value);
    case 'status': return (q.status || 'unverified') === statusKey(value);
    case 'tag': {
      const tags = q.tags || [];
      return v === '' ? tags.length === 0 : tags.some(eq);
    }
    case 'id': return has(q.id);
    default: return eq(/** @type {any} */ (q)[field]);
  }
}

/**
 * 構文木と問題を照合する。null（空の検索）はすべて一致。
 * @param {QueryNode|null} ast
 * @param {Question} q
 * @returns {boolean}
 */
export function matchQuery(ast, q) {
  if (!ast) return true;
  switch (ast.type) {
    case 'and': return ast.children.every(c => matchQuery(c, q));
    case 'or': return ast.children.some(c => matchQuery(c, q));
    case 'not': return !matchQuery(ast.child, q);
    case 'term': return ast.value === '' || haystack(q).includes(fold(ast.value));
    case 'field': return matchField(ast.field, ast.value, q);
    default: return true;
  }
}

/** @param {*} x @returns {Set<string>|null} */
function toSet(x) {
  if (!x) return null;
  const s = x instanceof Set ? x : new Set(Array.isArray(x) ? x : [x]);
  return s.size ? s : null;
}

/**
 * 絞り込み（プルダウン）と検索文字列の両方で問題を選ぶ。論理削除された問題は除く。
 * @param {Question[]} list
 * @param {string} [queryString]
 * @param {SearchFilters} [filters]
 * @returns {Question[]}
 */
export function searchQuestions(list, queryString = '', filters = {}) {
  const ast = parseQuery(queryString || '');
  const f = filters || {};
  const units = toSet(f.units);
  const tags = Array.isArray(f.tags) ? f.tags.filter(Boolean) : [];
  /** @type {[string, string][]} */
  const exact = [];
  for (const k of ['subj', 'stage', 'grade', 'course', 'level', 'type', 'src', 'cat']) {
    if (f[k]) exact.push([k, f[k]]);
  }
  return (list || []).filter(q => {
    if (!q) return false;
    if (q.deleted && !f.includeDeleted) return false;
    for (const [k, v] of exact) if ((q[k] || '') !== v) return false;
    if (f.status && (q.status || 'unverified') !== f.status) return false;
    if (units && !units.has(q.unit || q.set)) return false;
    if (tags.length) {
      const qt = q.tags || [];
      if (!tags.every(t => qt.includes(t))) return false;
    }
    return matchQuery(ast, q);
  });
}
