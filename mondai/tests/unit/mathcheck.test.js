import { describe, it, expect } from 'vitest';
import { evaluate, parseAnswerNumber, checkAnswer, nearlyEqual } from '../../js/domain/mathcheck.js';

describe('evaluate', () => {
  it('arithmetic and precedence', () => {
    expect(evaluate('1+2*3')).toBe(7);
    expect(evaluate('(1+2)*3')).toBe(9);
    expect(evaluate('10/4')).toBe(2.5);
    expect(evaluate('2^3^2')).toBe(512);
    expect(evaluate('2**10')).toBe(1024);
    expect(evaluate('-2^2')).toBe(-4);
    expect(evaluate('(-2)^2')).toBe(4);
    expect(evaluate('2^-1')).toBe(0.5);
    expect(evaluate('--3')).toBe(3);
    expect(evaluate('+3 - -2')).toBe(5);
    expect(evaluate('1.5e3 + .5')).toBe(1500.5);
    expect(evaluate('1.2E-2')).toBeCloseTo(0.012);
    expect(evaluate('6 × 7 ÷ 2')).toBe(21);
  });
  it('functions and constants', () => {
    expect(evaluate('sqrt(16)')).toBe(4);
    expect(evaluate('abs(-3)')).toBe(3);
    expect(evaluate('sin(pi/2)')).toBeCloseTo(1);
    expect(evaluate('cos(0)')).toBe(1);
    expect(evaluate('tan(0)')).toBe(0);
    expect(evaluate('log(e)')).toBeCloseTo(1);
    expect(evaluate('ln(e^2)')).toBeCloseTo(2);
    expect(evaluate('log10(1000)')).toBeCloseTo(3);
    expect(evaluate('exp(0)')).toBe(1);
    expect(evaluate('floor(2.7)+ceil(2.1)')).toBe(5);
    expect(evaluate('min(3,1,2)')).toBe(1);
    expect(evaluate('max(3,1,2)')).toBe(3);
    expect(evaluate('x^2+y', { x: 3, y: 1 })).toBe(10);
  });
  it('rejects anything unsafe or unknown by throwing', () => {
    const bad = ['constructor', 'alert(1)', '__proto__', 'toString', 'process.exit()', 'this', 'globalThis',
      'Function("return 1")()', 'a=1', '1;2', '[1]', '"x"', '`x`', 'x', '2x', 'sqrt', 'sqrt()', 'max()', 'sqrt(1,2)',
      '(1+2', '1+', '', '   ', 'pi(1)', 'eval(1)', 'Math.PI', '1..2', 'hasOwnProperty'];
    for (const s of bad) expect(() => evaluate(s), s).toThrow();
    expect(() => evaluate('constructor', {})).toThrow();
    expect(() => evaluate('x', { x: /** @type {any} */ ('1') })).toThrow();
    expect(() => evaluate('('.repeat(500) + '1' + ')'.repeat(500))).toThrow();
    expect(() => evaluate('1+'.repeat(1500) + '1')).toThrow();
    expect(() => evaluate(/** @type {any} */ (5))).toThrow();
  });
  it('returns non-finite numbers as-is', () => {
    expect(evaluate('1/0')).toBe(Infinity);
    expect(Number.isNaN(evaluate('sqrt(-1)'))).toBe(true);
  });
});

describe('parseAnswerNumber', () => {
  const cases = [
    ['$\\frac{3}{4}$', 0.75], ['x=3', 3], ['-5', -5], ['2\\sqrt{3}', 2 * Math.sqrt(3)], ['1.5 m/s', 1.5], ['3/4', 0.75],
    ['－５', -5], ['３．５', 3.5], ['$-\\frac{\\sqrt{3}}{2}$', -Math.sqrt(3) / 2], ['2\\pi', 2 * Math.PI], ['\\frac12', 0.5],
    ['3 \\times 10^{2}', 300], ['2 \\cdot 3', 6], ['約 3.14', 3.14], ['1,000円', 1000], ['x = \\dfrac{1}{3}', 1 / 3],
    ['−2', -2], ['√2', Math.SQRT2], ['\\sqrt[3]{8}', 2], ['\\frac{1}{\\frac{1}{2}}', 2], ['20種類', 20], ['45°', 45],
    ['$\\left(\\frac{1}{2}\\right)^{2}$', 0.25], [7, 7],
  ];
  for (const [s, v] of cases) {
    it(`parses ${s}`, () => { expect(parseAnswerNumber(s)).toBeCloseTo(/** @type {number} */ (v), 10); });
  }
  it('returns null when there is no number', () => {
    expect(parseAnswerNumber('ア')).toBeNull();
    expect(parseAnswerNumber('')).toBeNull();
    expect(parseAnswerNumber(null)).toBeNull();
    expect(parseAnswerNumber('光合成')).toBeNull();
    expect(parseAnswerNumber(NaN)).toBeNull();
  });
});

describe('nearlyEqual / checkAnswer', () => {
  it('relative tolerance', () => {
    expect(nearlyEqual(1, 1 + 1e-9)).toBe(true);
    expect(nearlyEqual(1e6, 1e6 + 0.5)).toBe(true);
    expect(nearlyEqual(1, 1.001)).toBe(false);
    expect(nearlyEqual(0, 0)).toBe(true);
  });
  it('skip when no check', () => {
    expect(checkAnswer({ id: '1', type: 'short', stem: '', ans: '3' }).status).toBe('skip');
    expect(checkAnswer({ id: '1', type: 'short', stem: '', ans: '3', check: { expr: ' ' } }).status).toBe('skip');
  });
  it('pass/fail against ans', () => {
    const ok = checkAnswer({ id: '1', type: 'short', stem: '', ans: '$\\frac{3}{4}$', check: { expr: '3/4' } });
    expect(ok).toMatchObject({ status: 'pass', expected: 0.75, actual: 0.75 });
    const ng = checkAnswer({ id: '1', type: 'short', stem: '', ans: '0.7', check: { expr: '3/4' } });
    expect(ng.status).toBe('fail');
    expect(ng.message).toMatch(/一致しません/);
  });
  it('uses expect, then the correct choice', () => {
    expect(checkAnswer({ id: '1', type: 'short', stem: '', ans: 'x', check: { expr: '2*3', expect: '6' } }).status).toBe('pass');
    const q = { id: '1', type: 'choice', stem: '', choices: ['$\\sqrt{2}$', '$2\\sqrt{3}$'], ai: [1], check: { expr: 'sqrt(12)' } };
    expect(checkAnswer(q).status).toBe('pass');
    expect(checkAnswer({ ...q, ai: [0] }).status).toBe('fail');
    expect(checkAnswer({ id: '1', type: 'short', stem: '', ans: '', check: { expr: 'a+b', vars: { a: 1, b: 2 }, expect: '3' } }).status).toBe('pass');
  });
  it('fails on bad expression or unreadable answer', () => {
    expect(checkAnswer({ id: '1', type: 'short', stem: '', ans: '1', check: { expr: 'alert(1)' } }).status).toBe('fail');
    expect(checkAnswer({ id: '1', type: 'short', stem: '', ans: '1', check: { expr: '1/0' } }).status).toBe('fail');
    const r = checkAnswer({ id: '1', type: 'short', stem: '', ans: 'わからない', check: { expr: '1' } });
    expect(r.status).toBe('fail');
    expect(r.actual).toBeNull();
  });
});
