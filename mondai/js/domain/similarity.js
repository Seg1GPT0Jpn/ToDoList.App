// 類似問題・重複問題の検出。削除は一切しない（候補を返すだけ）。

/**
 * @typedef {import('./question.js').Question} Question
 * @typedef {'exact'|'numeric_variant'|'similar'|'different'} SimilarityKind
 * @typedef {{ kind: SimilarityKind, score: number, reasons: string[] }} Comparison
 * @typedef {{ q: Question, kind: SimilarityKind, score: number, reasons: string[] }} SimilarCandidate
 * @typedef {{ limit?: number, minScore?: number, sameSubj?: boolean }} SimilarOptions
 *
 * @typedef {Object} Features
 * @property {string} norm 正規化した問題文（本文つき）
 * @property {string} exactKey 問題文＋選択肢（並びは無視）
 * @property {string} skelKey exactKey の数字を # にしたもの
 * @property {boolean} hasNumber
 * @property {string[]} grams 問題文の文字バイグラム（重複なし）
 * @property {string} shape 解答の形
 *
 * @typedef {Object} SimilarityIndex
 * @property {Question[]} list
 * @property {Features[]} feats
 * @property {Map<string, number[]>} postings バイグラム → 問題番号
 * @property {Map<string, number[]>} byExact
 * @property {Map<string, number[]>} bySkel
 */

export const DEFAULT_MIN_SCORE = 0.55;
const MAX_BONUS = 0.25;

/**
 * 比較用に文字列をそろえる：NFKC・小文字・空白と句読点を除く。
 * LaTeX のコマンド（\frac など）と数字・小数点・演算記号は残す。
 * @param {*} s
 */
export function normalizeText(s) {
  let t = String(s == null ? '' : s).normalize('NFKC').toLowerCase();
  // 下線・空欄の記法は中身だけにする
  t = t.replace(/\[\[mark:[^:\]]+:(.*?)\]\]/g, '$1').replace(/\[\[u:(.*?)\]\]/g, '$1').replace(/\[\[blank:[^\]]*\]\]/g, '□');
  t = t.replace(/[−–—‐]/g, '-');
  t = t.replace(/(?<=\d)\.(?=\d)/g, '\u0001');
  t = t.replace(/\\(?![a-z])/g, '');
  t = t.replace(/[\s$]|(?![\\\-\/%'_\u0001])\p{P}/gu, '');
  return t.replace(/\u0001/g, '.');
}

/**
 * 数字をすべて # にした骨格（数値替え問題の判定用）。
 * @param {*} s
 */
export function skeleton(s) {
  return normalizeText(s).replace(/\d+(?:\.\d+)?/g, '#');
}

/** @param {string} s @returns {string[]} */
function bigrams(s) {
  if (!s) return [];
  if (s.length === 1) return [s];
  const set = new Set();
  for (let i = 0; i < s.length - 1; i++) set.add(s.slice(i, i + 2));
  return Array.from(set);
}

/** @param {Question} q @returns {Features} */
function features(q) {
  const norm = normalizeText([q.stem, q.sentence].filter(Boolean).join(' '));
  const ch = (q.choices || []).map(normalizeText).sort().join('|');
  const exactKey = norm + '||' + ch;
  const skelKey = exactKey.replace(/\d+(?:\.\d+)?/g, '#');
  return { norm, exactKey, skelKey, hasNumber: skelKey !== exactKey, grams: bigrams(norm), shape: answerShape(q) };
}

/** @param {string[]} a @param {string[]} b */
function jaccard(a, b) {
  if (!a.length || !b.length) return 0;
  const sb = new Set(b);
  let inter = 0;
  for (const g of a) if (sb.has(g)) inter++;
  return inter / (a.length + b.length - inter);
}

/** @param {*} a @param {*} b */
function sameNonEmpty(a, b) { return !!a && !!b && String(a) === String(b); }

/** 解答の形（形式・選択肢数・正解数・正答の骨格） @param {Question} q */
function answerShape(q) {
  if (q.choices && q.choices.length) return `${q.type}:${q.choices.length}:${(q.ai || []).length}`;
  if (q.subs && q.subs.length) return `${q.type}:subs${q.subs.length}`;
  return `${q.type}:${skeleton(q.ans || '').replace(/[^#]+/g, 'a')}`;
}

/**
 * 特徴量が計算済みのときの比較。
 * @param {Question} a @param {Question} b @param {Features} fa @param {Features} fb @param {number} [base] 計算済みの Jaccard
 * @param {number} [minScore]
 * @returns {Comparison}
 */
function compareWith(a, b, fa, fb, base, minScore = DEFAULT_MIN_SCORE) {
  if (fa.exactKey === fb.exactKey) {
    return { kind: 'exact', score: 1, reasons: ['問題文と選択肢が完全に一致しています（重複）'] };
  }
  /** @type {string[]} */
  const reasons = [];
  const j = base != null ? base : jaccard(fa.grams, fb.grams);
  let bonus = 0;
  if (sameNonEmpty(a.unit || a.set, b.unit || b.set)) { bonus += 0.05; reasons.push('同じ単元'); }
  if (sameNonEmpty(a.subunit, b.subunit)) { bonus += 0.05; reasons.push('同じ小単元'); }
  if (sameNonEmpty(a.type, b.type)) { bonus += 0.03; reasons.push('同じ形式'); }
  const ka = a.knowledge || [], kb = b.knowledge || [];
  if (ka.length && kb.length && ka.some(k => kb.includes(k))) { bonus += 0.05; reasons.push('必要な知識が共通'); }
  if (sameNonEmpty(a.intent, b.intent)) { bonus += 0.04; reasons.push('出題意図が同じ'); }
  if (fa.shape === fb.shape) { bonus += 0.03; reasons.push('解答の形が同じ'); }

  if (fa.hasNumber && fa.skelKey === fb.skelKey) {
    return { kind: 'numeric_variant', score: Math.max(0.9, Math.min(0.99, j + bonus)), reasons: ['数値だけが異なります（数値替え問題）', ...reasons] };
  }
  const score = Math.min(1, j + bonus);
  reasons.unshift(`問題文の文字の重なり ${Math.round(j * 100)}%`);
  return { kind: score >= minScore ? 'similar' : 'different', score: Math.round(score * 1000) / 1000, reasons };
}

/**
 * 2問を比べる。
 * @param {Question} a
 * @param {Question} b
 * @returns {Comparison}
 */
export function compare(a, b) {
  return compareWith(a, b, features(a), features(b));
}

/**
 * 類似検索用の索引を作る（4万問で数百ミリ秒程度）。
 * @param {Question[]} list
 * @returns {SimilarityIndex}
 */
export function buildIndex(list) {
  const items = list || [];
  /** @type {Features[]} */
  const feats = new Array(items.length);
  /** @type {Map<string, number[]>} */
  const postings = new Map();
  /** @type {Map<string, number[]>} */
  const byExact = new Map();
  /** @type {Map<string, number[]>} */
  const bySkel = new Map();
  const push = (/** @type {Map<string, number[]>} */ m, /** @type {string} */ k, /** @type {number} */ i) => {
    const a = m.get(k);
    if (a) a.push(i); else m.set(k, [i]);
  };
  for (let i = 0; i < items.length; i++) {
    const f = features(items[i]);
    feats[i] = f;
    for (const g of f.grams) push(postings, g, i);
    push(byExact, f.exactKey, i);
    if (f.hasNumber) push(bySkel, f.skelKey, i);
  }
  return { list: items, feats, postings, byExact, bySkel };
}

/** @param {Question} a @param {Question} b */
function sameItem(a, b) { return a === b || (!!a.id && a.id === b.id); }

/**
 * 索引を使って似ている問題を探す。同じ教科（両方に教科があるとき）に限る。
 * @param {SimilarityIndex} index
 * @param {Question} target
 * @param {SimilarOptions} [opts]
 * @returns {SimilarCandidate[]}
 */
export function findSimilarIndexed(index, target, opts = {}) {
  const limit = opts.limit ?? 10;
  const minScore = opts.minScore ?? DEFAULT_MIN_SCORE;
  const sameSubj = opts.sameSubj !== false;
  const { list, feats, postings } = index;
  const ft = features(target);
  const okSubj = (/** @type {Question} */ q) => !sameSubj || !target.subj || !q.subj || q.subj === target.subj;

  // 共通するバイグラムの数を数える
  const counts = new Uint16Array(list.length);
  /** @type {number[]} */
  const touched = [];
  for (const g of ft.grams) {
    const p = postings.get(g);
    if (!p) continue;
    for (const i of p) {
      if (counts[i] === 0) touched.push(i);
      if (counts[i] < 65535) counts[i]++;
    }
  }
  /** @type {Set<number>} */
  const cand = new Set();
  const need = minScore - MAX_BONUS;
  const na = ft.grams.length;
  for (const i of touched) {
    const inter = counts[i];
    const j = inter / (na + feats[i].grams.length - inter);
    if (j >= need) cand.add(i);
  }
  for (const i of index.byExact.get(ft.exactKey) || []) cand.add(i);
  if (ft.hasNumber) for (const i of index.bySkel.get(ft.skelKey) || []) cand.add(i);

  /** @type {SimilarCandidate[]} */
  const out = [];
  for (const i of cand) {
    const q = list[i];
    if (!q || !okSubj(q) || sameItem(q, target)) continue;
    const inter = counts[i];
    const base = na ? inter / (na + feats[i].grams.length - inter) : 0;
    const c = compareWith(target, q, ft, feats[i], base, minScore);
    if (c.kind === 'different' || c.score < minScore) continue;
    out.push({ q, kind: c.kind, score: c.score, reasons: c.reasons });
  }
  const rank = { exact: 0, numeric_variant: 1, similar: 2, different: 3 };
  out.sort((x, y) => (y.score - x.score) || (rank[x.kind] - rank[y.kind]) || String(x.q.id).localeCompare(String(y.q.id)));
  return out.slice(0, limit);
}

/**
 * 似ている問題を探す（索引をその場で作る。何度も探すなら buildIndex を使う）。
 * @param {Question} target
 * @param {Question[]} list
 * @param {SimilarOptions} [opts]
 * @returns {SimilarCandidate[]}
 */
export function findSimilar(target, list, opts = {}) {
  const sameSubj = opts.sameSubj !== false;
  const pool = sameSubj && target && target.subj ? (list || []).filter(q => q && (!q.subj || q.subj === target.subj)) : (list || []);
  return findSimilarIndexed(buildIndex(pool), target, opts);
}

/**
 * @typedef {{ kind: 'exact'|'numeric_variant', key: string, ids: string[], questions: Question[] }} DuplicateGroup
 */

/**
 * 一括チェック用：完全一致・数値替えのグループを返す（2問以上のものだけ）。何も削除しない。
 * 数値替えのグループは、完全一致しか含まないものは除く。
 * @param {Question[]} list
 * @param {{ sameSubj?: boolean, kinds?: ('exact'|'numeric_variant')[], includeDeleted?: boolean }} [opts]
 * @returns {DuplicateGroup[]}
 */
export function findDuplicateGroups(list, opts = {}) {
  const sameSubj = opts.sameSubj !== false;
  const kinds = opts.kinds || ['exact', 'numeric_variant'];
  /** @type {Map<string, {f: Features, q: Question}[]>} */
  const ex = new Map();
  /** @type {Map<string, {f: Features, q: Question}[]>} */
  const sk = new Map();
  for (const q of list || []) {
    if (!q || (q.deleted && !opts.includeDeleted)) continue;
    const f = features(q);
    if (!f.norm) continue;
    const pre = sameSubj ? (q.subj || '') + '\u0002' : '';
    const e = pre + f.exactKey;
    (ex.get(e) || ex.set(e, []).get(e)).push({ f, q });
    if (f.hasNumber) {
      const s = pre + f.skelKey;
      (sk.get(s) || sk.set(s, []).get(s)).push({ f, q });
    }
  }
  /** @type {DuplicateGroup[]} */
  const groups = [];
  const mk = (/** @type {'exact'|'numeric_variant'} */ kind, /** @type {string} */ key, /** @type {{q: Question}[]} */ items) => ({
    kind, key, ids: items.map(x => x.q.id), questions: items.map(x => x.q),
  });
  if (kinds.includes('exact')) {
    for (const [k, items] of ex) if (items.length > 1) groups.push(mk('exact', k, items));
  }
  if (kinds.includes('numeric_variant')) {
    for (const [k, items] of sk) {
      if (items.length < 2) continue;
      if (new Set(items.map(x => x.f.exactKey)).size < 2) continue;
      groups.push(mk('numeric_variant', k, items));
    }
  }
  return groups;
}
