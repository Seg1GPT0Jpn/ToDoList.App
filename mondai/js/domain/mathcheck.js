// 計算問題の答え合わせ用の安全な式の計算（eval / Function は使わない）。
// 使えるもの：数（小数・1.2e3）、+ - * / ^ **、単項マイナス、かっこ、
// 関数 sqrt abs sin cos tan log(=自然対数) ln log10 exp floor ceil round min max、定数 pi e、
// evaluate の vars で渡した変数。それ以外の名前・記号はすべてエラーになる。

/**
 * @typedef {import('./question.js').Question} Question
 * @typedef {{ status: 'pass'|'fail'|'skip', expected: number|null, actual: number|null, message: string }} CheckResult
 */

const MAX_LEN = 2000;
const MAX_DEPTH = 100;

/** @type {Map<string, {fn: (...a: number[]) => number, min: number, max: number}>} */
const FUNCS = new Map([
  ['sqrt', { fn: Math.sqrt, min: 1, max: 1 }],
  ['abs', { fn: Math.abs, min: 1, max: 1 }],
  ['sin', { fn: Math.sin, min: 1, max: 1 }],
  ['cos', { fn: Math.cos, min: 1, max: 1 }],
  ['tan', { fn: Math.tan, min: 1, max: 1 }],
  ['log', { fn: Math.log, min: 1, max: 1 }],
  ['ln', { fn: Math.log, min: 1, max: 1 }],
  ['log10', { fn: Math.log10, min: 1, max: 1 }],
  ['exp', { fn: Math.exp, min: 1, max: 1 }],
  ['floor', { fn: Math.floor, min: 1, max: 1 }],
  ['ceil', { fn: Math.ceil, min: 1, max: 1 }],
  ['round', { fn: Math.round, min: 1, max: 1 }],
  ['min', { fn: Math.min, min: 1, max: Infinity }],
  ['max', { fn: Math.max, min: 1, max: Infinity }],
]);
/** @type {Map<string, number>} */
const CONSTS = new Map([['pi', Math.PI], ['e', Math.E]]);

/**
 * @typedef {{ t: 'num', v: number } | { t: 'id', v: string } | { t: 'op', v: string }} Tok
 */

/** @param {string} s @returns {Tok[]} */
function tokenize(s) {
  /** @type {Tok[]} */
  const out = [];
  let i = 0;
  while (i < s.length) {
    const c = s[i];
    if (/\s/.test(c)) { i++; continue; }
    const num = /^(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?/.exec(s.slice(i));
    if (num) { out.push({ t: 'num', v: Number(num[0]) }); i += num[0].length; continue; }
    const id = /^[A-Za-z_][A-Za-z0-9_]*/.exec(s.slice(i));
    if (id) { out.push({ t: 'id', v: id[0] }); i += id[0].length; continue; }
    if (s.startsWith('**', i)) { out.push({ t: 'op', v: '^' }); i += 2; continue; }
    const map = { '+': '+', '-': '-', '−': '-', '*': '*', '×': '*', '/': '/', '÷': '/', '^': '^', '(': '(', ')': ')', ',': ',' };
    if (Object.hasOwn(map, c)) { out.push({ t: 'op', v: map[c] }); i++; continue; }
    throw new SyntaxError(`使えない文字があります：「${c}」`);
  }
  return out;
}

/**
 * 式を計算する。
 * @param {string} expr
 * @param {Record<string, number>} [vars]
 * @returns {number}
 */
export function evaluate(expr, vars = {}) {
  if (typeof expr !== 'string') throw new TypeError('式は文字列で指定してください');
  if (expr.length > MAX_LEN) throw new RangeError('式が長すぎます');
  const toks = tokenize(expr);
  let pos = 0;
  let depth = 0;
  const peek = () => toks[pos];
  const isOp = (/** @type {string} */ v) => { const t = toks[pos]; return !!t && t.t === 'op' && t.v === v; };
  const expect = (/** @type {string} */ v) => {
    if (!isOp(v)) throw new SyntaxError(`「${v}」が必要です`);
    pos++;
  };
  const enter = () => { if (++depth > MAX_DEPTH) throw new RangeError('式の入れ子が深すぎます'); };

  /** @returns {number} */
  function add() {
    let v = mul();
    while (isOp('+') || isOp('-')) {
      const op = toks[pos++].v;
      const r = mul();
      v = op === '+' ? v + r : v - r;
    }
    return v;
  }
  /** @returns {number} */
  function mul() {
    let v = unary();
    while (isOp('*') || isOp('/')) {
      const op = toks[pos++].v;
      const r = unary();
      v = op === '*' ? v * r : v / r;
    }
    return v;
  }
  /** @returns {number} */
  function unary() {
    enter();
    let v;
    if (isOp('-')) { pos++; v = -unary(); }
    else if (isOp('+')) { pos++; v = unary(); }
    else v = power();
    depth--;
    return v;
  }
  /** @returns {number} */
  function power() {
    const b = primary();
    if (isOp('^')) {
      pos++;
      return Math.pow(b, unary()); // 右結合：2^3^2 = 2^9、-2^2 = -4
    }
    return b;
  }
  /** @returns {number} */
  function primary() {
    const t = peek();
    if (!t) throw new SyntaxError('式が途中で終わっています');
    if (t.t === 'num') { pos++; return t.v; }
    if (t.t === 'op' && t.v === '(') {
      pos++;
      enter();
      const v = add();
      depth--;
      expect(')');
      return v;
    }
    if (t.t === 'id') {
      pos++;
      const name = t.v;
      if (isOp('(')) {
        const f = FUNCS.get(name);
        if (!f) throw new ReferenceError(`使えない関数です：${name}`);
        pos++;
        /** @type {number[]} */
        const args = [];
        if (!isOp(')')) {
          enter();
          args.push(add());
          while (isOp(',')) { pos++; args.push(add()); }
          depth--;
        }
        expect(')');
        if (args.length < f.min || args.length > f.max) throw new SyntaxError(`${name} の引数の数が正しくありません`);
        return f.fn(...args);
      }
      if (vars && Object.hasOwn(vars, name)) {
        const v = vars[name];
        if (typeof v !== 'number') throw new TypeError(`変数 ${name} が数ではありません`);
        return v;
      }
      if (CONSTS.has(name)) return /** @type {number} */ (CONSTS.get(name));
      throw new ReferenceError(`使えない名前です：${name}`);
    }
    throw new SyntaxError(`予期しない記号です：「${t.v}」`);
  }

  if (!toks.length) throw new SyntaxError('式が空です');
  const v = add();
  if (pos < toks.length) {
    const t = toks[pos];
    throw new SyntaxError(`予期しない記号です：「${t.v}」`);
  }
  return v;
}

/**
 * LaTeX などの答えの表記を、evaluate で計算できる式に直す。
 * @param {string} s
 */
function latexToExpr(s) {
  let t = s.normalize('NFKC');
  t = t.replace(/[−‐–—－]/g, '-');
  t = t.replace(/\$/g, '');
  t = t.replace(/\\(?:left|right|displaystyle|,|;|:|!|quad|qquad)|\\ /g, ' ');
  t = t.replace(/\\(?:times|cdot)|[×・·]/g, '*').replace(/\\div|÷/g, '/');
  t = t.replace(/\\pi|π/g, 'pi');
  t = t.replace(/(\d),(?=\d{3}(?!\d))/g, '$1'); // 1,000 → 1000
  // \frac{a}{b}（入れ子も内側から）・\frac12
  for (let k = 0; k < 20; k++) {
    const before = t;
    t = t.replace(/\\[dt]?frac\s*\{([^{}]*)\}\s*\{([^{}]*)\}/g, '(($1)/($2))');
    t = t.replace(/\\sqrt\s*\[([^\]]*)\]\s*\{([^{}]*)\}/g, '(($2)^(1/($1)))');
    t = t.replace(/\\sqrt\s*\{([^{}]*)\}/g, 'sqrt($1)');
    t = t.replace(/√\s*\{([^{}]*)\}/g, 'sqrt($1)');
    t = t.replace(/\^\s*\{([^{}]*)\}/g, '^($1)');
    if (t === before) break;
  }
  t = t.replace(/\\[dt]?frac\s*(\d)\s*(\d)/g, '(($1)/($2))');
  t = t.replace(/(?:\\sqrt|√)\s*(\d+(?:\.\d+)?|pi)/g, 'sqrt($1)');
  t = t.replace(/[{}]/g, m => (m === '{' ? '(' : ')'));
  // 数字やかっこのすぐ後の sqrt・pi・かっこは掛け算（2\sqrt{3} → 2*sqrt(3)）
  t = t.replace(/((?<![a-z]\d*)\d|\))\s*(?=sqrt\(|pi(?![a-z])|\()/g, '$1*');
  t = t.replace(/(pi)\s*(?=\d|\(|sqrt)/g, '$1*');
  return t;
}

/**
 * 答えの文字列から数を取り出す。読み取れなければ null。
 * 例："$\\frac{3}{4}$" → 0.75、"x=3" → 3、"2\\sqrt{3}" → 3.464…、"1.5 m/s" → 1.5、"3/4" → 0.75
 * @param {*} str
 * @returns {number|null}
 */
export function parseAnswerNumber(str) {
  if (str == null) return null;
  if (typeof str === 'number') return Number.isFinite(str) ? str : null;
  let t = latexToExpr(String(str)).trim();
  // 「x = 3」のような形は = の右側
  const eq = t.lastIndexOf('=');
  if (eq >= 0) t = t.slice(eq + 1);
  // 先頭の「約」「答え：」などを飛ばす
  const start = t.search(/[0-9.+\-(]|(?:sqrt|log10|log|ln|abs|exp|sin|cos|tan)\(|pi(?![a-z])/);
  if (start < 0) return null;
  t = t.slice(start).slice(0, 200);
  // 単位などの後ろの文字を削りながら、計算できる最も長い部分を探す
  for (let end = t.length; end > 0; end--) {
    const part = t.slice(0, end);
    if (!/[0-9]|pi/.test(part)) continue;
    try {
      const v = evaluate(part);
      if (Number.isFinite(v)) return v;
    } catch (e) { /* 短くして試す */ }
  }
  return null;
}

/** @param {number} a @param {number} b @param {number} [rel] */
export function nearlyEqual(a, b, rel = 1e-6) {
  if (a === b) return true;
  const scale = Math.max(Math.abs(a), Math.abs(b));
  return Math.abs(a - b) <= rel * Math.max(scale, 1e-12) || Math.abs(a - b) < 1e-12;
}

/**
 * q.check = { expr, expect? } の式を計算し、正答（expect、なければ選択肢の正解または q.ans）と比べる。
 * @param {Question} q
 * @returns {CheckResult}
 */
export function checkAnswer(q) {
  const chk = q && q.check;
  if (!chk || typeof chk.expr !== 'string' || !chk.expr.trim()) {
    return { status: 'skip', expected: null, actual: null, message: '検証用の式が設定されていません' };
  }
  let expected;
  try {
    expected = evaluate(chk.expr, chk.vars || {});
  } catch (e) {
    return { status: 'fail', expected: null, actual: null, message: `検証用の式を計算できません：${e.message}` };
  }
  if (!Number.isFinite(expected)) {
    return { status: 'fail', expected, actual: null, message: '検証用の式の結果が有限の数になりません' };
  }
  let answer = chk.expect;
  if (answer == null || answer === '') {
    if (Array.isArray(q.choices) && q.choices.length && Array.isArray(q.ai) && q.ai.length) answer = q.choices[q.ai[0]];
    else answer = q.ans;
  }
  const actual = parseAnswerNumber(answer);
  if (actual == null) {
    return { status: 'fail', expected, actual: null, message: `正答「${answer ?? ''}」から数を読み取れません` };
  }
  if (nearlyEqual(expected, actual)) {
    return { status: 'pass', expected, actual, message: '式の計算結果と正答が一致しました' };
  }
  return { status: 'fail', expected, actual, message: `式の計算結果（${expected}）と正答（${actual}）が一致しません` };
}
