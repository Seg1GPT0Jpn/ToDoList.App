// 問題（Question）の業務ロジック。DOM を使わないので Node でも動く。
// データ形式は docs/DATABASE_DESIGN.md §1 を参照。既存キーはそのまま残す（後方互換）。

/**
 * @typedef {'indices'|'text'|'subs'} AnswerKind
 * @typedef {{ label: string, hasChoices: boolean, answerKind: AnswerKind }} QuestionTypeDef
 * @typedef {{ c: string, p: number }} RubricItem
 * @typedef {{ stem?: string, choices?: string[], ai?: number[], ans?: string, cl?: string[] }} SubQuestion
 * @typedef {{ expr: string, expect?: string, vars?: Record<string, number> }} CheckSpec
 *
 * @typedef {Object} Question
 * @property {string} id
 * @property {number} [rev]
 * @property {string} type
 * @property {string} stem
 * @property {string} [sentence]
 * @property {string[]} [choices]
 * @property {string[]} [cl]
 * @property {number[]} [ai]
 * @property {string} [ans]
 * @property {string[]} [alts]
 * @property {string} [expl]
 * @property {string} [explBasic]
 * @property {string} [explAdvanced]
 * @property {string[]} [steps]
 * @property {string[]} [mistakes]
 * @property {RubricItem[]} [rubric]
 * @property {number} [pts]
 * @property {number} [time]
 * @property {string} [stage]
 * @property {string} [subj]
 * @property {string} [course]
 * @property {string} [grade]
 * @property {string} [field]
 * @property {string} [unit]
 * @property {string} [subunit]
 * @property {string} [set]
 * @property {string} [cat]
 * @property {string} [level]
 * @property {string[]} [knowledge]
 * @property {string} [intent]
 * @property {string} [src]
 * @property {'builtin'|'imported'|'user'|'ai'} [origin]
 * @property {string} [author]
 * @property {string} [createdAt]
 * @property {string} [updatedAt]
 * @property {string} [status]
 * @property {string[]} [tags]
 * @property {string[]} [related]
 * @property {CheckSpec} [check]
 * @property {SubQuestion[]} [subs]
 * @property {number} [lines]
 * @property {number} [grid]
 * @property {boolean} [compact]
 * @property {boolean} [deleted]
 * @property {*} [fig]
 * @property {*} [table]
 * @property {string} [sid]
 *
 * @typedef {{ field: string, message: string }} ValidationIssue
 * @typedef {{ ok: boolean, errors: ValidationIssue[], warnings: ValidationIssue[] }} ValidationResult
 * @typedef {{ id: string, rev: number, data: Question, savedAt: string, note?: string }} QuestionVersion
 */

/** @type {Record<string, QuestionTypeDef>} */
export const QUESTION_TYPES = {
  choice: { label: '選択', hasChoices: true, answerKind: 'indices' },
  multi: { label: '複数選択', hasChoices: true, answerKind: 'indices' },
  order: { label: '並べかえ', hasChoices: true, answerKind: 'indices' },
  tf: { label: '正誤', hasChoices: false, answerKind: 'text' },
  short: { label: '答えのみ', hasChoices: false, answerKind: 'text' },
  written: { label: '記述', hasChoices: false, answerKind: 'text' },
  steps: { label: '小問つき', hasChoices: false, answerKind: 'subs' },
};

/**
 * 問題形式を追加する（既存の形式を上書きすることもできる）。
 * @param {string} key
 * @param {QuestionTypeDef} def
 */
export function registerQuestionType(key, def) {
  if (!key || typeof key !== 'string') throw new TypeError('形式のキーが必要です');
  if (!def || typeof def.label !== 'string') throw new TypeError('形式の label が必要です');
  const kinds = ['indices', 'text', 'subs'];
  QUESTION_TYPES[key] = {
    label: def.label,
    hasChoices: !!def.hasChoices,
    answerKind: kinds.includes(def.answerKind) ? def.answerKind : 'text',
  };
  return QUESTION_TYPES[key];
}

export const LEVELS = ['基礎', '標準', '応用'];

/** @type {Record<string, string>} */
export const STATUSES = {
  unverified: '未検証',
  verifying: '検証中',
  verified: '検証済み',
  approved: '人間承認済み',
  needs_fix: '要修正',
};

export const CHOICE_LABELS = ['ア', 'イ', 'ウ', 'エ', 'オ', 'カ', 'キ', 'ク', 'ケ', 'コ', 'サ', 'シ', 'ス', 'セ', 'ソ', 'タ'];

// ---------- ID（ULID 形式：時刻順に並ぶランダム ID） ----------
const B32 = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
let lastTime = -1;
/** @type {number[]} */
let lastRand = [];

/** @param {number} n */
function randomDigits(n) {
  const out = new Array(n);
  const c = globalThis.crypto;
  if (c && typeof c.getRandomValues === 'function') {
    const buf = new Uint8Array(n);
    c.getRandomValues(buf);
    for (let i = 0; i < n; i++) out[i] = buf[i] & 31;
  } else {
    for (let i = 0; i < n; i++) out[i] = Math.floor(Math.random() * 32);
  }
  return out;
}

/**
 * ULID（26文字）。同じミリ秒内でも単調増加する。
 * @param {number} [now]
 */
export function ulid(now = Date.now()) {
  let rand;
  if (now <= lastTime) {
    now = lastTime;
    rand = lastRand.slice();
    let i = rand.length - 1;
    while (i >= 0 && rand[i] === 31) { rand[i] = 0; i--; }
    if (i >= 0) rand[i]++;
  } else {
    rand = randomDigits(16);
  }
  lastTime = now;
  lastRand = rand;
  let t = '';
  let x = now;
  for (let i = 0; i < 10; i++) { t = B32[x % 32] + t; x = Math.floor(x / 32); }
  return t + rand.map(d => B32[d]).join('');
}

/** @param {string} [prefix] */
export function newId(prefix = 'U') {
  return `${prefix}-${ulid()}`;
}

function nowIso() { return new Date().toISOString(); }

/** @param {*} v */
function clone(v) {
  if (typeof structuredClone === 'function') return structuredClone(v);
  return JSON.parse(JSON.stringify(v));
}

// ---------- 正規化 ----------
const ARRAY_KEYS = ['choices', 'ai', 'alts', 'steps', 'mistakes', 'rubric', 'tags', 'related', 'knowledge'];
const STRING_KEYS = ['id', 'type', 'stem', 'sentence', 'ans', 'expl', 'explBasic', 'explAdvanced', 'stage', 'subj', 'course',
  'grade', 'field', 'unit', 'subunit', 'set', 'cat', 'level', 'intent', 'src', 'author', 'status', 'sid'];

/** @param {*} v */
function str(v) { return v == null ? '' : String(v).trim(); }

/** @param {*} v */
function strArray(v) {
  if (v == null) return [];
  const a = Array.isArray(v) ? v : [v];
  return a.map(x => (typeof x === 'string' ? x.trim() : x));
}

/** @param {*} v */
function numArray(v) {
  if (v == null) return [];
  const a = Array.isArray(v) ? v : [v];
  return a.map(x => Number(x)).filter(x => Number.isFinite(x));
}

/** @param {string} src */
function originFromSrc(src) {
  if (src === '内蔵') return 'builtin';
  if (src === 'AI') return 'ai';
  if (src === '自作') return 'user';
  return 'imported';
}

/**
 * 足りない配列・項目を補い、文字列の前後の空白を取る。知らないキーはそのまま残す。
 * 元のオブジェクトは変更しない。
 * @param {Partial<Question> & Record<string, any>} q
 * @returns {Question}
 */
export function normalizeQuestion(q) {
  /** @type {any} */
  const out = { ...(q || {}) };
  for (const k of STRING_KEYS) {
    if (out[k] != null && typeof out[k] !== 'object') out[k] = str(out[k]);
  }
  if (!out.type) out.type = (Array.isArray(out.choices) && out.choices.length) ? 'choice' : 'short';
  if (out.stem == null) out.stem = '';
  for (const k of ARRAY_KEYS) {
    if (k === 'ai') out.ai = numArray(out.ai);
    else if (k === 'rubric') {
      out.rubric = (Array.isArray(out.rubric) ? out.rubric : []).filter(Boolean)
        .map(r => ({ ...r, c: str(r.c), p: Number(r.p) || 0 }));
    } else out[k] = strArray(out[k]);
  }
  // render.js は subs があると小問つきとして扱うので、steps 形式のときだけ補う
  if (out.type === 'steps') {
    out.subs = (Array.isArray(out.subs) ? out.subs : []).map(s => ({
      ...s,
      stem: str(s && s.stem),
      choices: strArray(s && s.choices),
      ai: numArray(s && s.ai),
      ...(s && s.ans != null ? { ans: str(s.ans) } : {}),
    }));
  }
  if (out.ans == null) out.ans = '';
  if (out.expl == null) out.expl = '';
  if (out.pts != null && out.pts !== '') {
    const n = Number(out.pts);
    out.pts = Number.isFinite(n) ? n : out.pts;
  } else delete out.pts;
  for (const k of ['lines', 'grid', 'time']) {
    if (out[k] != null && out[k] !== '' && Number.isFinite(Number(out[k]))) out[k] = Number(out[k]);
  }
  if (!Number.isInteger(out.rev) || out.rev < 1) out.rev = 1;
  if (!out.status || !STATUSES[out.status]) out.status = 'unverified';
  if (!out.origin) out.origin = originFromSrc(out.src || '');
  return out;
}

/**
 * 新しい問題を作る（自作）。partial の値が優先される（id・rev・作成日時は自動）。
 * @param {Partial<Question> & Record<string, any>} [partial]
 * @returns {Question}
 */
export function newQuestion(partial = {}) {
  const t = nowIso();
  const origin = partial.origin || 'user';
  const base = {
    type: 'choice', stem: '', sentence: '', choices: [], ai: [], ans: '', alts: [], expl: '',
    steps: [], mistakes: [], rubric: [], tags: [], related: [], knowledge: [],
    stage: '', subj: '', course: '', grade: '', unit: '', subunit: '', level: '標準', intent: '',
    src: origin === 'ai' ? 'AI' : '自作', author: '',
  };
  const q = normalizeQuestion({
    ...base,
    ...partial,
    id: partial.id || newId(origin === 'ai' ? 'AI' : 'U'),
    rev: 1,
    origin,
    status: partial.status && STATUSES[partial.status] ? partial.status : 'unverified',
    createdAt: partial.createdAt || t,
    updatedAt: partial.updatedAt || t,
  });
  if (q.type === 'steps' && !q.subs) q.subs = [];
  return q;
}

// ---------- 検証 ----------
/** @param {*} s */
function isBlank(s) { return s == null || String(s).trim() === ''; }

/** エスケープされていない $ の数 @param {*} s */
function dollarCount(s) {
  if (typeof s !== 'string') return 0;
  const m = s.match(/(?<!\\)\$/g);
  return m ? m.length : 0;
}

/**
 * 選択肢つき（choice/multi/order）の検査。
 * @param {{choices?: any[], ai?: any[]}} q
 * @param {string} type
 * @param {string} prefix
 * @param {ValidationIssue[]} errors
 */
function checkChoices(q, type, prefix, errors) {
  const choices = Array.isArray(q.choices) ? q.choices : [];
  const ai = Array.isArray(q.ai) ? q.ai : [];
  const f = (/** @type {string} */ k) => prefix + k;
  if (choices.length < 2) errors.push({ field: f('choices'), message: '選択肢が2つ以上必要です' });
  choices.forEach((c, i) => { if (isBlank(c)) errors.push({ field: `${f('choices')}[${i}]`, message: `選択肢${i + 1}が空です` }); });
  const seen = new Set();
  choices.forEach((c, i) => {
    if (isBlank(c)) return;
    const k = String(c).trim();
    if (seen.has(k)) errors.push({ field: `${f('choices')}[${i}]`, message: `選択肢${i + 1}が他の選択肢と同じです` });
    seen.add(k);
  });
  const inRange = (/** @type {any} */ i) => Number.isInteger(i) && i >= 0 && i < choices.length;
  if (ai.some(i => !inRange(i))) errors.push({ field: f('ai'), message: '正解の選択肢番号が範囲外です' });
  if (new Set(ai).size !== ai.length) errors.push({ field: f('ai'), message: '正解の選択肢番号が重複しています' });
  if (type === 'choice' && ai.length !== 1) errors.push({ field: f('ai'), message: '正解の選択肢をちょうど1つ指定してください' });
  if (type === 'multi' && ai.length < 1) errors.push({ field: f('ai'), message: '正解の選択肢を1つ以上指定してください' });
  if (type === 'order') {
    const ok = ai.length === choices.length && ai.every(inRange) && new Set(ai).size === ai.length;
    if (!ok) errors.push({ field: f('ai'), message: '並べかえの正解は、すべての選択肢を1回ずつ使う順番にしてください' });
  }
}

/**
 * 問題の検査。errors があると保存できない。warnings は注意のみ。
 * @param {Partial<Question> & Record<string, any>} q
 * @returns {ValidationResult}
 */
export function validateQuestion(q) {
  /** @type {ValidationIssue[]} */
  const errors = [];
  /** @type {ValidationIssue[]} */
  const warnings = [];
  if (!q || typeof q !== 'object') return { ok: false, errors: [{ field: '', message: '問題データがありません' }], warnings };
  if (isBlank(q.stem)) errors.push({ field: 'stem', message: '問題文を入力してください' });
  if (isBlank(q.type)) errors.push({ field: 'type', message: '形式を選んでください' });
  else if (!QUESTION_TYPES[q.type]) errors.push({ field: 'type', message: `「${q.type}」は登録されていない形式です` });

  const def = QUESTION_TYPES[q.type];
  if (def) {
    if (q.type === 'choice' || q.type === 'multi' || q.type === 'order') checkChoices(q, q.type, '', errors);
    else if (def.hasChoices) checkChoices(q, 'multi', '', errors);
    else if (def.answerKind === 'text') {
      if (isBlank(q.ans)) errors.push({ field: 'ans', message: '正答を入力してください' });
    } else if (def.answerKind === 'subs') {
      const subs = Array.isArray(q.subs) ? q.subs : [];
      if (!subs.length) errors.push({ field: 'subs', message: '小問を1つ以上入れてください' });
      subs.forEach((s, i) => {
        const p = `subs[${i}].`;
        if (!s || typeof s !== 'object') { errors.push({ field: `subs[${i}]`, message: `小問${i + 1}が正しくありません` }); return; }
        if (isBlank(s.stem)) warnings.push({ field: p + 'stem', message: `小問${i + 1}の問題文が空です` });
        if (Array.isArray(s.choices) && s.choices.length) checkChoices(s, 'choice', p, errors);
        else if (isBlank(s.ans)) errors.push({ field: p + 'ans', message: `小問${i + 1}に選択肢か正答が必要です` });
      });
    }
  }

  if (q.pts != null && /** @type {any} */ (q.pts) !== '') {
    const n = Number(q.pts);
    if (!Number.isFinite(n) || n < 0) errors.push({ field: 'pts', message: '配点は0以上の数にしてください' });
  }
  if (isBlank(q.level)) warnings.push({ field: 'level', message: '難易度が未設定です' });
  else if (!LEVELS.includes(q.level)) errors.push({ field: 'level', message: `難易度は${LEVELS.join('・')}のどれかにしてください` });
  if (q.status && !STATUSES[q.status]) errors.push({ field: 'status', message: `検証状態「${q.status}」は使えません` });

  // 数式の $ が閉じているか
  /** @type {[string, any][]} */
  const texts = [['stem', q.stem], ['sentence', q.sentence], ['ans', q.ans], ['expl', q.expl]];
  (Array.isArray(q.choices) ? q.choices : []).forEach((c, i) => texts.push([`choices[${i}]`, c]));
  (Array.isArray(q.subs) ? q.subs : []).forEach((s, i) => {
    if (!s) return;
    texts.push([`subs[${i}].stem`, s.stem]);
    (Array.isArray(s.choices) ? s.choices : []).forEach((c, j) => texts.push([`subs[${i}].choices[${j}]`, c]));
  });
  for (const [field, v] of texts) {
    if (dollarCount(v) % 2 === 1) errors.push({ field, message: '数式の $ が閉じていません（$ の数が奇数です）' });
  }

  if (Array.isArray(q.rubric) && q.rubric.length && q.pts != null && Number.isFinite(Number(q.pts))) {
    const sum = q.rubric.reduce((a, r) => a + (Number(r && r.p) || 0), 0);
    if (sum > Number(q.pts)) warnings.push({ field: 'rubric', message: `採点基準の合計（${sum}点）が配点（${q.pts}点）を超えています` });
  }
  return { ok: errors.length === 0, errors, warnings };
}

// ---------- 版・複製 ----------
/**
 * 編集を保存するときに版を上げ、旧版を退避用に返す。
 * @param {Question} prev
 * @param {Partial<Question>} next
 * @param {string} [note]
 * @returns {{ next: Question, version: QuestionVersion }}
 */
export function bumpRevision(prev, next, note) {
  const t = nowIso();
  const prevRev = Number.isInteger(prev && prev.rev) && prev.rev >= 1 ? prev.rev : 1;
  /** @type {QuestionVersion} */
  const version = { id: prev.id, rev: prevRev, data: clone(prev), savedAt: t };
  if (note) version.note = note;
  return {
    next: /** @type {Question} */ ({ ...next, id: prev.id, rev: prevRev + 1, updatedAt: t }),
    version,
  };
}

/**
 * 問題の複製（自作の新しい問題として扱う）。
 * @param {Question} q
 * @returns {Question}
 */
export function duplicateQuestion(q) {
  const t = nowIso();
  /** @type {any} */
  const c = clone(q);
  delete c.deleted;
  const related = Array.isArray(c.related) ? c.related.slice() : [];
  if (q.id && !related.includes(q.id)) related.push(q.id);
  return {
    ...c,
    id: newId('U'),
    rev: 1,
    origin: 'user',
    status: 'unverified',
    related,
    createdAt: t,
    updatedAt: t,
  };
}

// ---------- 正答の文字列 ----------
/**
 * @param {{choices?: string[], ai?: number[], cl?: string[]}} q
 * @param {string[]} [labels]
 */
function labelsOf(q, labels) {
  if (labels && labels.length) return labels;
  const n = (q.choices || []).length;
  if (Array.isArray(q.cl) && q.cl.length >= n && n) return q.cl;
  return CHOICE_LABELS;
}

/**
 * 人が読める正答（例：「イ」「ア・ウ」「ウ → ア → イ」「(1) ア　(2) 3」）。
 * labels を省略すると q.cl（元の記号）があればそれ、なければ ア イ ウ…。
 * @param {Question} q
 * @param {string[]} [labels]
 */
export function answerText(q, labels) {
  if (!q) return '';
  const def = QUESTION_TYPES[q.type];
  const kind = def ? def.answerKind : (q.choices && q.choices.length ? 'indices' : 'text');
  if (kind === 'indices') {
    const lb = labelsOf(q, labels);
    const parts = (q.ai || []).map(i => lb[i] != null ? lb[i] : String(i + 1));
    return parts.join(q.type === 'order' ? ' → ' : '・');
  }
  if (kind === 'subs') {
    return (q.subs || []).map((s, i) => {
      const a = s.choices && s.choices.length
        ? (s.ai || []).map(k => labelsOf(s, labels)[k] ?? String(k + 1)).join('・')
        : (s.ans || '');
      return `(${i + 1}) ${a}`;
    }).join('　');
  }
  return q.ans == null ? '' : String(q.ans);
}
