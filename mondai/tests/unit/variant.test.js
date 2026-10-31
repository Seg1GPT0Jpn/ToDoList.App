import { describe, it, expect } from 'vitest';
import { fill, formatNumber, cond, makeVariant, autoVary, varyQuestion, validateVary } from '../../js/domain/variant.js';
import { parseAnswerNumber } from '../../js/domain/mathcheck.js';

describe('fill / formatNumber', () => {
  it('変数と式を置きかえる', () => {
    expect(fill('{{a}} と {{=a*b}}', { a: 3, b: 4 })).toBe('3 と 12');
  });
  it('LaTeX の { の直後でも置きかえられる', () => {
    expect(fill('\\dfrac{{{=x*2}}}{{{y}}}', { x: 3, y: 7 })).toBe('\\dfrac{6}{7}');
    expect(fill('10^{{{=k}}}', { k: -3 })).toBe('10^{-3}');
  });
  it('書式（分数・符号・係数・小数・絶対値）', () => {
    expect(formatNumber(0.75, 'frac')).toBe('\\frac{3}{4}');
    expect(formatNumber(-1.5, 'frac')).toBe('-\\frac{3}{2}');
    expect(formatNumber(3, 'sign')).toBe('+3');
    expect(formatNumber(-3, 'sign')).toBe('-3');
    expect(formatNumber(1, 'coef')).toBe('');
    expect(formatNumber(-1, 'coef')).toBe('-');
    expect(formatNumber(1 / 3, '2')).toBe('0.33');
    expect(formatNumber(-4, 'abs')).toBe('4');
    expect(formatNumber(0.1 + 0.2)).toBe('0.3');
  });
  it('知らない変数はエラー', () => {
    expect(() => fill('{{z}}', { a: 1 })).toThrow();
  });
});

describe('cond', () => {
  it('比較', () => {
    expect(cond('a != b', { a: 1, b: 2 })).toBe(true);
    expect(cond('a*b >= 6', { a: 2, b: 3 })).toBe(true);
    expect(cond('a < b', { a: 3, b: 2 })).toBe(false);
  });
});

const quadratic = {
  id: 'q1', type: 'short', stem: '二次関数 $y=x^2-6x+5$ の最小値を求めなさい。', ans: '-4', expl: '$y=(x-3)^2-4$ より -4。',
  vary: {
    vars: { p: { min: 1, max: 6 }, q: { min: -5, max: 9, not: [0] } },
    stem: '二次関数 $y=x^2-{{=2*p}}x{{=q|sign}}$ の最小値を求めなさい。', ans: '{{=q-p^2}}', check: 'q-p^2',
    expl: '$y=(x-{{p}})^2{{=q-p^2|sign}}$ より {{=q-p^2}}。', original: { p: 3, q: 5 },
  },
};

describe('makeVariant', () => {
  it('テンプレートと元の値で元の問題が再現できる', () => {
    expect(fill(quadratic.vary.stem, quadratic.vary.original)).toBe(quadratic.stem);
    expect(fill(quadratic.vary.ans, quadratic.vary.original)).toBe(quadratic.ans);
  });
  it('数値を変えた問題の答えは式の値と一致し、シードで再現できる', () => {
    for (let s = 1; s <= 30; s++) {
      const r = makeVariant(quadratic, { seed: s });
      expect(r.ok).toBe(true);
      const { p, q } = r.values;
      expect(parseAnswerNumber(r.q.ans)).toBe(q - p * p);
      expect(r.q.vary).toBeUndefined();
      expect(r.q.variantOf).toBe('q1');
    }
    expect(makeVariant(quadratic, { seed: 7 }).q.stem).toBe(makeVariant(quadratic, { seed: 7 }).q.stem);
  });
  it('答えと式が合わないテンプレートは使わない', () => {
    const bad = { ...quadratic, vary: { ...quadratic.vary, ans: '{{=q+p}}' } };
    expect(makeVariant(bad, { seed: 1, tries: 20 }).ok).toBe(false);
  });
  it('選択肢が重なる値は避ける', () => {
    const q = { id: 'c', type: 'choice', stem: '{{a}}', choices: [], ai: [0], vary: { vars: { a: { min: 0, max: 3 } }, stem: '{{a}}+{{a}}', choices: ['{{=2*a}}', '{{=a*a}}'], check: '2*a' } };
    for (let s = 1; s <= 20; s++) {
      const r = makeVariant(q, { seed: s });
      if (r.ok) expect(new Set(r.q.choices).size).toBe(2);
    }
  });
  it('テンプレートの形の検査', () => {
    expect(validateVary({})).not.toBe('');
    expect(validateVary({ vars: { pi: { min: 1, max: 2 } }, stem: 'x' })).not.toBe('');
    expect(validateVary(quadratic.vary)).toBe('');
  });
});

describe('autoVary / varyQuestion', () => {
  it('検算の式から自動でテンプレートを作る（短答）', () => {
    const q = { id: 'a', type: 'short', stem: '1個 120 円のりんごを 7 個買うと代金はいくらか。', ans: '840円', check: { expr: '120*7' } };
    const v = autoVary(q);
    expect(v && v.auto).toBe(true);
    const r = varyQuestion(q, 5);
    expect(r.ok).toBe(true);
    expect(r.q.stem).not.toBe(q.stem);
    const [, x, y] = r.q.stem.match(/\d+/g).map(Number); // 先頭の「1個」の 1 は除く
    expect(parseAnswerNumber(r.q.ans)).toBe(x * y);
  });
  it('指数の数は変えない', () => {
    const q = { id: 'b', type: 'short', stem: '$3^2$ の値を求めなさい。', ans: '9', check: { expr: '3^2' } };
    const v = autoVary(q);
    if (v) expect(v.stem).toContain('^2');
  });
  it('テンプレートも検算の式もない問題は作れない', () => {
    expect(varyQuestion({ id: 'n', type: 'short', stem: '用語を答えよ', ans: '光合成' }, 1).ok).toBe(false);
  });
});

describe('内蔵問題の数値替えテンプレート', () => {
  it('すべてのテンプレートで、元の問題が再現でき、数値替えが作れる', async () => {
    const fs = await import('node:fs');
    const url = new URL('../../builtin/hs.json', import.meta.url);
    const qs = JSON.parse(fs.readFileSync(url, 'utf8')).questions.filter(q => q.vary);
    expect(qs.length).toBeGreaterThan(600);
    const bad = [];
    for (const q of qs) {
      const v = q.vary;
      if (fill(v.stem, v.original) !== q.stem) { bad.push(q.id + ' 問題文'); continue; }
      const r = varyQuestion(q, 'test-' + q.id);
      if (!r.ok) bad.push(q.id + ' ' + r.reason);
    }
    expect(bad).toEqual([]);
  });
});
