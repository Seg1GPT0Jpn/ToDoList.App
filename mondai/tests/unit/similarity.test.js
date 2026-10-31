import { describe, it, expect } from 'vitest';
import {
  normalizeText, skeleton, compare, findSimilar, buildIndex, findSimilarIndexed, findDuplicateGroups,
} from '../../js/domain/similarity.js';

const mk = (id, stem, extra = {}) => ({ id, type: 'choice', subj: '数学', unit: '二次関数', stem, choices: [], ai: [], ...extra });

describe('normalizeText / skeleton', () => {
  it('NFKC, removes spaces and punctuation, keeps numbers and LaTeX commands', () => {
    expect(normalizeText('ＡＢＣ　１２３、です。')).toBe('abc123です');
    expect(normalizeText('$\\frac{1}{2}$ を求めよ。')).toBe('\\frac12を求めよ');
    expect(normalizeText('x = 1.5, y = -3')).toBe('x=1.5y=-3');
    expect(normalizeText('3/4 と 50%')).toBe('3/4と50%');
    expect(normalizeText('[[u:下線]]の語')).toBe('下線の語');
    expect(normalizeText(null)).toBe('');
    expect(normalizeText('Hello, World!')).toBe('helloworld');
  });
  it('skeleton replaces numbers with #', () => {
    expect(skeleton('y = 2x^2 + 3.5x - 10 の頂点')).toBe('y=#x^#+#x-#の頂点');
    expect(skeleton('数字なし')).toBe('数字なし');
  });
});

describe('compare', () => {
  it('exact (choice order ignored, spacing ignored)', () => {
    const a = mk('a', '1+1 は？', { choices: ['1', '2'] });
    const b = mk('b', '1 + 1 は?', { choices: ['2', '1'] });
    const r = compare(a, b);
    expect(r.kind).toBe('exact');
    expect(r.score).toBe(1);
    expect(r.reasons[0]).toMatch(/一致/);
  });
  it('numeric variant', () => {
    const r = compare(mk('a', '$y=x^2-4x+3$ の頂点を求めよ。'), mk('b', '$y=x^2-6x+5$ の頂点を求めよ。'));
    expect(r.kind).toBe('numeric_variant');
    expect(r.score).toBeGreaterThanOrEqual(0.9);
    expect(r.reasons[0]).toMatch(/数値/);
  });
  it('similar with bonuses and reasons', () => {
    const a = mk('a', '二次関数のグラフの頂点の座標を答えなさい', { subunit: 'グラフ', knowledge: ['平方完成'], intent: '頂点' });
    const b = mk('b', '二次関数のグラフの頂点の座標と軸を答えなさい', { subunit: 'グラフ', knowledge: ['平方完成'], intent: '頂点' });
    const r = compare(a, b);
    expect(r.kind).toBe('similar');
    expect(r.score).toBeGreaterThan(0.55);
    expect(r.score).toBeLessThanOrEqual(1);
    for (const s of ['同じ単元', '同じ小単元', '同じ形式', '必要な知識が共通', '出題意図が同じ']) expect(r.reasons).toContain(s);
  });
  it('different', () => {
    const r = compare(mk('a', '光合成の反応式を書け', { subj: '理科', unit: '代謝' }), mk('b', '枕草子の作者は誰か', { subj: '国語', unit: '古文', type: 'short' }));
    expect(r.kind).toBe('different');
    expect(r.score).toBeLessThan(0.55);
  });
});

describe('findSimilar', () => {
  const list = [
    mk('t', '二次関数 y=x^2-4x+3 の頂点の座標を求めなさい'),
    mk('n', '二次関数 y=x^2-6x+8 の頂点の座標を求めなさい'),
    mk('s', '二次関数 y=x^2-4x+3 の軸の方程式と頂点の座標を求めなさい'),
    mk('x', '二次関数 y=x^2-4x+3 の頂点の座標を求めなさい', { subj: '理科' }),
    mk('d', '三角形の内角の和は何度か'),
    mk('e', '二次関数 y=x^2-4x+3 の頂点の座標を求めなさい'),
  ];
  it('ranks exact > numeric > similar, excludes self and other subjects', () => {
    const r = findSimilar(list[0], list);
    expect(r.map(c => c.q.id)).toEqual(['e', 'n', 's']);
    expect(r.map(c => c.kind)).toEqual(['exact', 'numeric_variant', 'similar']);
    expect(findSimilar(list[0], list, { limit: 1 })).toHaveLength(1);
    expect(findSimilar(list[0], list, { sameSubj: false }).map(c => c.q.id)).toContain('x');
    expect(findSimilar(list[0], list, { minScore: 0.99 }).map(c => c.q.id)).toEqual(['e']);
  });
  it('indexed matches unindexed', () => {
    const idx = buildIndex(list);
    expect(findSimilarIndexed(idx, list[0]).map(c => c.q.id)).toEqual(findSimilar(list[0], list).map(c => c.q.id));
    expect(findSimilarIndexed(buildIndex([]), list[0])).toEqual([]);
  });
  it('handles 40,000 questions in under 2 seconds', () => {
    const units = ['二次関数', '三角比', '数列', '確率', '微分', '積分', 'ベクトル', '図形'];
    const words = ['求めよ', '答えなさい', '計算せよ', '説明しなさい', '示せ', '選びなさい'];
    let s = 12345;
    const r = () => { s = (s * 1103515245 + 12345) % 2147483648; return s / 2147483648; };
    const big = [];
    for (let i = 0; i < 40000; i++) {
      const u = units[i % units.length];
      big.push(mk('p' + i, `${u}について、値 ${Math.floor(r() * 1000)} と ${Math.floor(r() * 100)} を使って${words[Math.floor(r() * words.length)]}。条件${Math.floor(r() * 50)}の場合`, {
        subj: ['数学', '理科', '国語', '英語', '社会'][i % 5], unit: u,
      }));
    }
    const target = big[123];
    const t0 = performance.now();
    const res = findSimilar(target, big);
    const t1 = performance.now();
    expect(t1 - t0).toBeLessThan(2000);
    expect(res.length).toBeGreaterThan(0);
    expect(res.every(c => c.q !== target && c.q.subj === target.subj)).toBe(true);

    const t2 = performance.now();
    const idx = buildIndex(big);
    for (let k = 0; k < 5; k++) findSimilarIndexed(idx, big[k * 1000]);
    expect(performance.now() - t2).toBeLessThan(2000);
  }, 20000);
});

describe('findDuplicateGroups', () => {
  it('groups exact and numeric variants without changing input', () => {
    const list = [
      mk('a', '1+2 を計算せよ'),
      mk('b', '1 + 2 を計算せよ。'),
      mk('c', '3+4 を計算せよ'),
      mk('d', '日本の首都はどこか'),
      mk('e', '日本の首都はどこか', { subj: '社会' }),
      mk('f', '5+6 を計算せよ', { deleted: true }),
    ];
    const before = JSON.stringify(list);
    const g = findDuplicateGroups(list);
    expect(g.filter(x => x.kind === 'exact').map(x => x.ids)).toEqual([['a', 'b']]);
    expect(g.filter(x => x.kind === 'numeric_variant').map(x => x.ids)).toEqual([['a', 'b', 'c']]);
    expect(JSON.stringify(list)).toBe(before);
    expect(list).toHaveLength(6);
    const all = findDuplicateGroups(list, { sameSubj: false, includeDeleted: true });
    expect(all.filter(x => x.kind === 'exact').map(x => x.ids)).toContainEqual(['d', 'e']);
    expect(all.find(x => x.kind === 'numeric_variant').ids).toContain('f');
    expect(findDuplicateGroups(list, { kinds: ['exact'] }).every(x => x.kind === 'exact')).toBe(true);
    expect(findDuplicateGroups([])).toEqual([]);
  });
});
