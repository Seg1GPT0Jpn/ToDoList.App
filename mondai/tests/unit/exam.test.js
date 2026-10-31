import { describe, it, expect } from 'vitest';
import { buildExam, allocatePoints, validatePoints, makeVersions, apportion, seededRandom } from '../../js/domain/exam.js';

const LV = ['基礎', '標準', '応用'];
const UNITS = ['二次関数', '三角比', '数と式', 'データ'];
const TYPES = ['choice', 'short', 'written'];
function makePool(n = 300) {
  const out = [];
  for (let i = 0; i < n; i++) {
    out.push({
      id: 'q' + i, stem: '問' + i, type: TYPES[i % 3], level: LV[Math.floor(i / 3) % 3], unit: UNITS[Math.floor(i / 9) % 4],
      choices: i % 3 === 0 ? ['a', 'b', 'c', 'd'] : [], ai: i % 3 === 0 ? [i % 4] : [], ans: 'x', tags: i % 10 === 0 ? ['古い'] : [],
    });
  }
  return out;
}

describe('seededRandom / apportion', () => {
  it('is deterministic', () => {
    const a = seededRandom(5), b = seededRandom(5), c = seededRandom('abc');
    const xs = [a(), a(), a()];
    expect([b(), b(), b()]).toEqual(xs);
    expect(xs.every(x => x >= 0 && x < 1)).toBe(true);
    expect(c()).not.toBe(xs[0]);
  });
  it('apportion sums exactly', () => {
    expect(apportion({ 基礎: 3, 標準: 5, 応用: 2 }, 10)).toEqual({ 基礎: 3, 標準: 5, 応用: 2 });
    expect(apportion({ a: 1, b: 1, c: 1 }, 10)).toEqual({ a: 4, b: 3, c: 3 });
    expect(apportion({ a: 0, b: 1 }, 3)).toEqual({ a: 0, b: 3 });
    expect(apportion({}, 3)).toEqual({});
  });
});

describe('buildExam', () => {
  const pool = makePool();
  it('is deterministic for a seed and differs across seeds', () => {
    const spec = { count: 20, levelRatio: { 基礎: 3, 標準: 5, 応用: 2 } };
    const a = buildExam(pool, spec, { seed: 42 });
    const b = buildExam(pool, spec, { seed: 42 });
    const c = buildExam(pool, spec, { seed: 43 });
    expect(a.questions.map(q => q.id)).toEqual(b.questions.map(q => q.id));
    expect(a.questions.map(q => q.id)).not.toEqual(c.questions.map(q => q.id));
    expect(new Set(a.questions.map(q => q.id)).size).toBe(20);
  });
  it('respects level ratio exactly when possible', () => {
    for (const seed of [1, 2, 3, 4, 5]) {
      const r = buildExam(pool, { count: 20, levelRatio: { 基礎: 3, 標準: 5, 応用: 2 } }, { seed });
      expect(r.stats.byLevel).toEqual({ 基礎: 6, 標準: 10, 応用: 4 });
      expect(r.shortfalls).toEqual([]);
      // 大問の中は易しい順
      const lv = r.questions.map(q => LV.indexOf(q.level));
      expect(lv.slice().sort((x, y) => x - y)).toEqual(lv);
    }
  });
  it('respects level + unit + type ratios together', () => {
    const r = buildExam(pool, { count: 24, levelRatio: { 基礎: 1, 標準: 1, 応用: 1 }, unitRatio: { 二次関数: 1, 三角比: 1, 数と式: 1, データ: 1 }, typeRatio: { choice: 1, short: 1, written: 1 } }, { seed: 9 });
    expect(r.stats.byLevel).toEqual({ 基礎: 8, 標準: 8, 応用: 8 });
    expect(Object.values(r.stats.byUnit)).toEqual([6, 6, 6, 6]);
    expect(r.stats.byType).toEqual({ choice: 8, short: 8, written: 8 });
  });
  it('sections with type, units filter, exclusions, total points', () => {
    const r = buildExam(pool, {
      total: 100,
      sections: [{ title: '選択', count: 5, type: 'choice' }, { title: '記述', count: 3, type: 'written' }],
      units: ['二次関数', '三角比'],
      exclude: { ids: ['q0', 'q3'], tags: ['古い'], units: ['三角比'] },
    }, { seed: 7 });
    expect(r.sections.map(s => s.title)).toEqual(['選択', '記述']);
    expect(r.sections[0].questionIds).toHaveLength(5);
    expect(r.sections[1].questionIds).toHaveLength(3);
    const qs = r.questions;
    expect(qs.slice(0, 5).every(q => q.type === 'choice')).toBe(true);
    expect(qs.slice(5).every(q => q.type === 'written')).toBe(true);
    expect(qs.every(q => q.unit === '二次関数')).toBe(true);
    expect(qs.some(q => q.id === 'q0' || q.id === 'q3' || q.tags.includes('古い'))).toBe(false);
    expect(Object.values(r.points).reduce((a, b) => a + b, 0)).toBe(100);
    expect(r.shortfalls.some(s => /三角比/.test(s))).toBe(true); // 単元の均等配分が満たせない
  });
  it('reports shortfalls when the pool is too small', () => {
    const r = buildExam(pool.slice(0, 9), { count: 20, levelRatio: { 応用: 1 } }, { seed: 1 });
    expect(r.questions).toHaveLength(9);
    expect(r.shortfalls.some(s => /20問必要/.test(s))).toBe(true);
    expect(r.shortfalls.some(s => /応用/.test(s))).toBe(true);
    expect(buildExam(pool, {}, { seed: 1 }).shortfalls[0]).toMatch(/問題数/);
    expect(buildExam([], { count: 3 }).questions).toEqual([]);
  });
  it('prefers unused questions, without breaking ratio', () => {
    const used = new Set(pool.slice(0, 280).map(q => q.id));
    const r = buildExam(pool, { count: 6, preferUnused: used, levelRatio: { 基礎: 1, 標準: 1, 応用: 1 } }, { seed: 3 });
    expect(r.questions.every(q => !used.has(q.id))).toBe(true);
    expect(r.stats.byLevel).toEqual({ 基礎: 2, 標準: 2, 応用: 2 });
    const r2 = buildExam(pool, { count: 30, preferUnused: used }, { seed: 3 });
    expect(r2.questions.filter(q => !used.has(q.id))).toHaveLength(20);
    expect(r2.shortfalls.some(s => /使用済み/.test(s))).toBe(true);
  });
  it('skips deleted questions', () => {
    const p = pool.slice(0, 5).map((q, i) => ({ ...q, deleted: i < 3 }));
    expect(buildExam(p, { count: 5 }).questions).toHaveLength(2);
  });
});

describe('allocatePoints / validatePoints', () => {
  const qs = (n) => Array.from({ length: n }, (_, i) => ({ id: 'x' + i, stem: '', type: i % 4 === 0 ? 'written' : 'choice', level: LV[i % 3] }));
  it('always sums exactly to total', () => {
    for (const mode of ['equal', 'weighted']) {
      for (let n = 1; n <= 40; n++) {
        for (const total of [0, 1, 7, 10, 50, 99, 100, 101, 150, 200, 1000]) {
          const p = allocatePoints(qs(n), total, { mode });
          expect(p).toHaveLength(n);
          expect(p.reduce((a, b) => a + b, 0)).toBe(total);
          expect(p.every(x => Number.isInteger(x) && x >= 0)).toBe(true);
          if (total >= n) expect(p.every(x => x >= 1)).toBe(true);
        }
      }
    }
  });
  it('equal and weighted shapes', () => {
    expect(allocatePoints(qs(3), 100)).toEqual([34, 33, 33]);
    const w = allocatePoints([
      { id: 'a', stem: '', type: 'choice', level: '基礎' },
      { id: 'b', stem: '', type: 'choice', level: '応用' },
      { id: 'c', stem: '', type: 'written', level: '応用' },
    ], 60, { mode: 'weighted' });
    expect(w).toEqual([10, 20, 30]);
    expect(allocatePoints([], 100)).toEqual([]);
    expect(() => allocatePoints(qs(2), -1)).toThrow();
    expect(() => allocatePoints(qs(2), 1.5)).toThrow();
  });
  it('validatePoints', () => {
    expect(validatePoints([50, 50], 100)).toMatchObject({ ok: true, sum: 100 });
    const r = validatePoints([{ pts: 40 }, { pts: 58 }], 100);
    expect(r).toMatchObject({ ok: false, sum: 98 });
    expect(r.message).toMatch(/あと2点/);
    expect(validatePoints([60, 50], 100).message).toMatch(/10点多い/);
    expect(validatePoints([1.5, 98.5], 100).ok).toBe(false);
    expect(validatePoints([{}], 0).ok).toBe(false);
    expect(validatePoints([], 0).ok).toBe(true);
  });
});

describe('makeVersions', () => {
  const pool = makePool(60);
  const exam = buildExam(pool, { sections: [{ title: 'A', count: 6, type: 'choice' }, { title: 'B', count: 4, type: 'short' }] }, { seed: 1 });
  it('shuffles within sections and choices, deterministic, stems unchanged', () => {
    const before = JSON.stringify(exam.questions);
    const v = makeVersions(exam, 3, { seed: 5 });
    expect(v.map(x => x.label)).toEqual(['A', 'B', 'C']);
    for (const ver of v) {
      expect(ver.order.slice(0, 6).sort()).toEqual(exam.sections[0].questionIds.slice().sort());
      expect(ver.order.slice(6).sort()).toEqual(exam.sections[1].questionIds.slice().sort());
      for (const q of exam.questions.filter(x => x.type === 'choice')) {
        const perm = ver.choicePerm[q.id];
        expect(perm.slice().sort()).toEqual([0, 1, 2, 3]);
        expect(ver.answers[q.id]).toBe(['ア', 'イ', 'ウ', 'エ'][perm.indexOf(q.ai[0])]);
      }
    }
    expect(JSON.stringify(exam.questions)).toBe(before);
    expect(makeVersions(exam, 3, { seed: 5 })).toEqual(v);
    expect(v[0].order.join() !== v[1].order.join() || JSON.stringify(v[0].choicePerm) !== JSON.stringify(v[1].choicePerm)).toBe(true);
  });
  it('accepts a plain array, keeps order-type choices, labels beyond Z', () => {
    const qs = [
      { id: 'o', stem: '', type: 'order', choices: ['a', 'b', 'c'], ai: [2, 0, 1] },
      { id: 's', stem: '', type: 'short', ans: '5' },
    ];
    const v = makeVersions(qs, 28, { seed: 1 });
    expect(v[25].label).toBe('Z');
    expect(v[26].label).toBe('AA');
    expect(v[0].choicePerm.o).toEqual([0, 1, 2]);
    expect(v[0].answers.o).toBe('ウ → ア → イ');
    expect(v[0].answers.s).toBe('5');
    expect(makeVersions(qs, 0)).toEqual([]);
  });
});
