// テストの自動作成（ExamSpec → 問題の組み合わせ）・配点・複数版（A・B…）。
// docs/DATABASE_DESIGN.md §3 を参照。
import { LEVELS, QUESTION_TYPES, CHOICE_LABELS } from './question.js';

/**
 * @typedef {import('./question.js').Question} Question
 * @typedef {{ title?: string, count: number, type?: string }} SectionSpec
 * @typedef {Object} ExamSpec
 * @property {number} [total] 満点（指定すると points を返す）
 * @property {number} [count] 問題数（sections がないとき）
 * @property {SectionSpec[]} [sections]
 * @property {Record<string, number>} [levelRatio] 例 {基礎:3, 標準:5, 応用:2}（重み）
 * @property {string[]} [units] この単元から出す
 * @property {Record<string, number>} [unitRatio]
 * @property {Record<string, number>} [typeRatio]
 * @property {{ subj?: string, course?: string, units?: string[] }} [include]
 * @property {{ ids?: string[], tags?: string[], units?: string[] }} [exclude]
 * @property {Set<string>|string[]} [preferUnused] 使用済みの問題 ID（未使用の問題を優先する）
 * @property {'equal'|'weighted'} [pointsMode]
 *
 * @typedef {Object} ExamResult
 * @property {Question[]} questions
 * @property {{ title: string, questionIds: string[] }[]} sections
 * @property {string[]} shortfalls
 * @property {{ byLevel: Record<string, number>, byUnit: Record<string, number>, byType: Record<string, number> }} stats
 * @property {Record<string, number>} [points]
 *
 * @typedef {{ label: string, order: string[], choicePerm: Record<string, number[]>, answers: Record<string, string> }} ExamVersion
 */

// ---------- 乱数（シードで再現できる） ----------
/** @param {number|string} seed */
function seedNum(seed) {
  if (typeof seed === 'number' && Number.isFinite(seed)) return (seed >>> 0) || 1;
  let h = 2166136261;
  for (const ch of String(seed ?? '1')) { h ^= ch.charCodeAt(0); h = Math.imul(h, 16777619); }
  return (h >>> 0) || 1;
}
/** mulberry32 @param {number|string} seed */
export function seededRandom(seed) {
  let a = seedNum(seed);
  return () => {
    a = (a + 0x6D2B79F5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
/** @template T @param {T[]} arr @param {() => number} rand @returns {T[]} */
function shuffle(arr, rand) {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(rand() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; }
  return a;
}

/**
 * 重みから整数の目標数を作る（最大剰余法。合計はちょうど count）。
 * @param {Record<string, number>} weights
 * @param {number} count
 * @returns {Record<string, number>}
 */
export function apportion(weights, count) {
  const keys = Object.keys(weights || {}).filter(k => Number(weights[k]) > 0);
  /** @type {Record<string, number>} */
  const out = {};
  for (const k of Object.keys(weights || {})) out[k] = 0;
  const sum = keys.reduce((a, k) => a + Number(weights[k]), 0);
  if (!sum || count <= 0) return out;
  const raw = keys.map((k, i) => ({ k, i, v: count * Number(weights[k]) / sum }));
  let used = 0;
  for (const r of raw) { out[r.k] = Math.floor(r.v); used += out[r.k]; }
  raw.sort((a, b) => ((b.v - Math.floor(b.v)) - (a.v - Math.floor(a.v))) || (a.i - b.i));
  for (let j = 0; used < count; j++, used++) out[raw[j % raw.length].k]++;
  return out;
}

/** @param {Question} q */
const unitOf = q => q.unit || q.set || '';

/** @param {*} x @returns {Set<string>} */
function toSet(x) { return x instanceof Set ? x : new Set(Array.isArray(x) ? x : []); }

/**
 * 条件に合わせて問題を選ぶ。同じ seed・同じ pool なら同じ結果になる。
 * 難易度・単元・形式の比率にできるだけ近づける（足りないときは shortfalls に理由）。
 * @param {Question[]} pool
 * @param {ExamSpec} spec
 * @param {{ seed?: number|string }} [opts]
 * @returns {ExamResult}
 */
export function buildExam(pool, spec, opts = {}) {
  const rand = seededRandom(opts.seed ?? 1);
  /** @type {string[]} */
  const shortfalls = [];
  const ex = spec.exclude || {};
  const exIds = toSet(ex.ids), exTags = toSet(ex.tags), exUnits = toSet(ex.units);
  const inc = spec.include || {};
  const incUnits = toSet(spec.units && spec.units.length ? spec.units : inc.units);
  const used = toSet(spec.preferUnused);

  const cands = (pool || []).filter(q => q && !q.deleted
    && !exIds.has(q.id)
    && !(q.tags || []).some(t => exTags.has(t))
    && !exUnits.has(unitOf(q))
    && (!incUnits.size || incUnits.has(unitOf(q)))
    && (!inc.subj || q.subj === inc.subj)
    && (!inc.course || q.course === inc.course));

  /** @type {SectionSpec[]} */
  const sections = spec.sections && spec.sections.length
    ? spec.sections.map((s, i) => ({ title: s.title ?? `第${i + 1}問`, count: Math.max(0, Math.floor(Number(s.count) || 0)), type: s.type }))
    : [{ title: '', count: Math.max(0, Math.floor(Number(spec.count) || 0)) }];
  const total = sections.reduce((a, s) => a + s.count, 0);
  if (!total) shortfalls.push('問題数が指定されていません');

  // 比率 → 全体の目標数
  /** @type {{ key: (q: Question) => string, name: string, target: Record<string, number>, picked: Record<string, number> }[]} */
  const dims = [];
  if (spec.levelRatio && Object.values(spec.levelRatio).some(v => v > 0)) {
    dims.push({ key: q => q.level || '', name: '難易度', target: apportion(spec.levelRatio, total), picked: {} });
  }
  const unitW = spec.unitRatio && Object.values(spec.unitRatio).some(v => v > 0)
    ? spec.unitRatio
    : (incUnits.size > 1 ? Object.fromEntries(Array.from(incUnits).map(u => [u, 1])) : null);
  if (unitW) dims.push({ key: unitOf, name: '単元', target: apportion(unitW, total), picked: {} });
  const typed = sections.some(s => s.type);
  if (spec.typeRatio && !typed && Object.values(spec.typeRatio).some(v => v > 0)) {
    dims.push({ key: q => q.type || '', name: '形式', target: apportion(spec.typeRatio, total), picked: {} });
  }

  // 同じ（難易度・単元・形式）の問題をまとめ、未使用→乱数順に並べておく
  const ranked = shuffle(cands, rand).map((q, r) => ({ q, r, unused: !used.has(q.id) }));
  ranked.sort((a, b) => (Number(b.unused) - Number(a.unused)) || (a.r - b.r));

  const picked = new Set();
  /** @type {ExamResult['sections']} */
  const outSections = [];
  /** @type {Question[]} */
  const outQs = [];
  const poolIndex = new Map((pool || []).map((q, i) => [q, i]));
  const lvOrder = (/** @type {Question} */ q) => { const i = LEVELS.indexOf(q.level || ''); return i < 0 ? 1 : i; };

  for (const sec of sections) {
    /** @type {Map<string, {q: Question, r: number, unused: boolean}[]>} */
    const buckets = new Map();
    for (const it of ranked) {
      if (picked.has(it.q)) continue;
      if (sec.type && it.q.type !== sec.type) continue;
      const k = dims.map(d => d.key(it.q)).join('\u0001');
      (buckets.get(k) || buckets.set(k, []).get(k)).push(it);
    }
    /** @type {Map<string, number>} */
    const heads = new Map();
    /** @type {Question[]} */
    const chosen = [];
    for (let n = 0; n < sec.count; n++) {
      let best = null, bestScore = -Infinity, bestHead = null;
      for (const [k, arr] of buckets) {
        const h = heads.get(k) || 0;
        if (h >= arr.length) continue;
        const it = arr[h];
        let score = 0;
        for (const d of dims) {
          const v = d.key(it.q);
          score += (d.target[v] || 0) - (d.picked[v] || 0);
        }
        const better = score > bestScore + 1e-9
          || (Math.abs(score - bestScore) <= 1e-9 && bestHead && (
            (it.unused && !bestHead.unused) || (it.unused === bestHead.unused && it.r < bestHead.r)));
        if (better) { best = k; bestScore = score; bestHead = it; }
      }
      if (best == null) break;
      heads.set(best, (heads.get(best) || 0) + 1);
      picked.add(bestHead.q);
      chosen.push(bestHead.q);
      for (const d of dims) { const v = d.key(bestHead.q); d.picked[v] = (d.picked[v] || 0) + 1; }
    }
    if (chosen.length < sec.count) {
      const name = sec.title ? `「${sec.title}」` : 'テスト';
      const tl = sec.type && QUESTION_TYPES[sec.type] ? `（${QUESTION_TYPES[sec.type].label}）` : '';
      shortfalls.push(`${name}${tl}は${sec.count}問必要ですが、条件に合う問題が${chosen.length}問しかありません`);
    }
    // 大問の中は易しい順（同じ難易度は元の並び順）
    chosen.sort((a, b) => (lvOrder(a) - lvOrder(b)) || ((poolIndex.get(a) ?? 0) - (poolIndex.get(b) ?? 0)));
    outQs.push(...chosen);
    outSections.push({ title: sec.title || '', questionIds: chosen.map(q => q.id) });
  }

  for (const d of dims) {
    for (const [v, t] of Object.entries(d.target)) {
      const got = d.picked[v] || 0;
      if (got < t) shortfalls.push(`${d.name}「${v}」：目標${t}問に対し${got}問です（該当する問題が足りません）`);
    }
  }
  if (used.size && outQs.some(q => used.has(q.id))) {
    shortfalls.push(`未使用の問題が足りないため、使用済みの問題を${outQs.filter(q => used.has(q.id)).length}問使いました`);
  }

  /** @type {ExamResult['stats']} */
  const stats = { byLevel: {}, byUnit: {}, byType: {} };
  for (const q of outQs) {
    const lv = q.level || '（未設定）', u = unitOf(q) || '（未設定）', t = q.type || '（未設定）';
    stats.byLevel[lv] = (stats.byLevel[lv] || 0) + 1;
    stats.byUnit[u] = (stats.byUnit[u] || 0) + 1;
    stats.byType[t] = (stats.byType[t] || 0) + 1;
  }
  /** @type {ExamResult} */
  const result = { questions: outQs, sections: outSections, shortfalls, stats };
  if (spec.total != null && outQs.length) {
    const pts = allocatePoints(outQs, Number(spec.total), { mode: spec.pointsMode || 'equal' });
    result.points = Object.fromEntries(outQs.map((q, i) => [q.id, pts[i]]));
  }
  return result;
}

// ---------- 配点 ----------
const LEVEL_WEIGHT = { 基礎: 1, 標準: 1.5, 応用: 2 };

/** @param {Question} q */
function weightOf(q) {
  let w = LEVEL_WEIGHT[q && q.level] ?? 1.5;
  if (q && q.type === 'written') w *= 1.5;
  return w;
}

/**
 * 整数の配点を決める。合計は必ず total になる（最大剰余法）。
 * equal：均等（端数は前の問題から1点ずつ）。weighted：基礎1・標準1.5・応用2、記述は×1.5 の比。
 * total が問題数以上なら、どの問題も1点以上になる。
 * @param {Question[]} questions
 * @param {number} total
 * @param {{ mode?: 'equal'|'weighted' }} [opts]
 * @returns {number[]}
 */
export function allocatePoints(questions, total, opts = {}) {
  const n = (questions || []).length;
  if (!Number.isInteger(total) || total < 0) throw new RangeError('満点は0以上の整数にしてください');
  if (!n) return [];
  const w = opts.mode === 'weighted' ? questions.map(weightOf) : questions.map(() => 1);
  const W = w.reduce((a, b) => a + b, 0);
  const raw = w.map(x => total * x / W);
  const pts = raw.map(Math.floor);
  let rest = total - pts.reduce((a, b) => a + b, 0);
  const order = raw.map((v, i) => ({ i, f: v - Math.floor(v) })).sort((a, b) => (b.f - a.f) || (a.i - b.i));
  for (let j = 0; rest > 0; j++, rest--) pts[order[j % n].i]++;
  // 0点の問題があれば、いちばん多い問題から1点ずつ回す
  if (total >= n) {
    for (let i = 0; i < n; i++) {
      if (pts[i] > 0) continue;
      let m = 0;
      for (let k = 1; k < n; k++) if (pts[k] > pts[m]) m = k;
      pts[m]--; pts[i]++;
    }
  }
  return pts;
}

/**
 * 配点の合計が満点と一致するか確かめる。items は数か {pts} の配列。
 * @param {Array<number|{pts?: number}>} items
 * @param {number} total
 * @returns {{ ok: boolean, sum: number, message: string }}
 */
export function validatePoints(items, total) {
  const vals = (items || []).map(x => (typeof x === 'number' ? x : Number(x && x.pts)));
  const bad = vals.findIndex(v => !Number.isFinite(v) || v < 0 || !Number.isInteger(v));
  const sum = vals.reduce((a, v) => a + (Number.isFinite(v) ? v : 0), 0);
  if (bad >= 0) return { ok: false, sum, message: `${bad + 1}問目の配点が正しくありません（0以上の整数にしてください）` };
  if (sum === total) return { ok: true, sum, message: `配点の合計が満点（${total}点）と一致しています` };
  const diff = total - sum;
  return { ok: false, sum, message: `配点の合計（${sum}点）が満点（${total}点）と一致しません（${diff > 0 ? `あと${diff}点` : `${-diff}点多い`}）` };
}

// ---------- 複数版（A・B…） ----------
/** @param {number} i */
function versionLabel(i) {
  let s = '';
  let n = i;
  do { s = String.fromCharCode(65 + (n % 26)) + s; n = Math.floor(n / 26) - 1; } while (n >= 0);
  return s;
}

/**
 * 問題の順番（大問の中だけ）と選択肢の順番を入れかえた版を n 個作る。
 * 問題文の数値は変えない。数値を変えた版（数値替え問題）が必要なときは、
 * AI で問題を作り直し、計算の検証（mathcheck）と人の確認をやり直すこと。
 * choicePerm[id][p] は p 番目に表示する元の選択肢番号（render.js の perm と同じ意味）。
 * 並べかえ（order）の選択肢は入れかえない。
 * @param {ExamResult|Question[]} examQuestions buildExam の結果、または問題の配列（1つの大問として扱う）
 * @param {number} n
 * @param {{ seed?: number|string, labels?: string[] }} [opts]
 * @returns {ExamVersion[]}
 */
export function makeVersions(examQuestions, n, opts = {}) {
  const isResult = !Array.isArray(examQuestions);
  /** @type {Question[]} */
  const qs = isResult ? /** @type {ExamResult} */ (examQuestions).questions : /** @type {Question[]} */ (examQuestions);
  const byId = new Map(qs.map(q => [q.id, q]));
  const sections = isResult && /** @type {ExamResult} */ (examQuestions).sections.length
    ? /** @type {ExamResult} */ (examQuestions).sections.map(s => s.questionIds)
    : [qs.map(q => q.id)];
  const labels = opts.labels || CHOICE_LABELS;
  /** @type {ExamVersion[]} */
  const out = [];
  const count = Math.max(0, Math.floor(n || 0));
  for (let v = 0; v < count; v++) {
    const rand = seededRandom(`${opts.seed ?? 1}:${v}`);
    const order = sections.flatMap(ids => shuffle(ids, rand));
    /** @type {Record<string, number[]>} */
    const choicePerm = {};
    /** @type {Record<string, string>} */
    const answers = {};
    for (const id of order) {
      const q = byId.get(id);
      if (!q) continue;
      const nch = (q.choices || []).length;
      if (nch && q.type !== 'order') {
        const perm = shuffle(Array.from({ length: nch }, (_, i) => i), rand);
        choicePerm[id] = perm;
        answers[id] = (q.ai || []).map(i => labels[perm.indexOf(i)]).join('・');
      } else if (nch) {
        choicePerm[id] = Array.from({ length: nch }, (_, i) => i);
        answers[id] = (q.ai || []).map(i => labels[i]).join(' → ');
      } else {
        answers[id] = q.ans || '';
      }
    }
    out.push({ label: versionLabel(v), order, choicePerm, answers });
  }
  return out;
}
