import { describe, it, expect } from 'vitest';
import { answerSpaceFor, buildAnswerSheet } from '../../js/domain/answersheet.js';

const q = (extra) => ({ id: 'x', stem: '', ...extra });

describe('answerSpaceFor', () => {
  it('maps each type', () => {
    expect(answerSpaceFor(q({ type: 'choice', choices: ['a', 'b'] }))).toEqual({ kind: 'symbol' });
    expect(answerSpaceFor(q({ type: 'multi' }))).toEqual({ kind: 'symbols' });
    expect(answerSpaceFor(q({ type: 'tf' }))).toEqual({ kind: 'tf' });
    expect(answerSpaceFor(q({ type: 'order', choices: ['a', 'b', 'c', 'd'] }))).toEqual({ kind: 'order', cells: 4 });
    expect(answerSpaceFor(q({ type: 'steps', subs: [{}, {}] }))).toEqual({ kind: 'symbols', cells: 2 });
    expect(answerSpaceFor(q({ type: 'unknown' }))).toEqual({ kind: 'short' });
  });
  it('short vs calc', () => {
    expect(answerSpaceFor(q({ type: 'short', subj: '数学', stem: '値を求めよ' })).kind).toBe('calc');
    expect(answerSpaceFor(q({ type: 'short', subj: '理科', stem: '次を計算せよ' })).kind).toBe('calc');
    expect(answerSpaceFor(q({ type: 'short', subj: '国語', stem: '意味を求めよ' })).kind).toBe('short');
    expect(answerSpaceFor(q({ type: 'short', subj: '数学', stem: '名称を答えよ' })).kind).toBe('short');
  });
  it('written / proof / english', () => {
    expect(answerSpaceFor(q({ type: 'written' }))).toEqual({ kind: 'written', lines: 4 });
    expect(answerSpaceFor(q({ type: 'written', lines: 6, grid: 200 }))).toEqual({ kind: 'written', lines: 6, chars: 200 });
    expect(answerSpaceFor(q({ type: 'written', stem: 'これを証明せよ', lines: 4 }))).toEqual({ kind: 'proof', lines: 8 });
    expect(answerSpaceFor(q({ type: 'written', stem: '証明しなさい', lines: 12 }))).toEqual({ kind: 'proof', lines: 12 });
    expect(answerSpaceFor(q({ type: 'written', subj: '英語', stem: 'Write' }))).toEqual({ kind: 'english', lines: 4 });
  });
});

describe('buildAnswerSheet', () => {
  it('numbers rows from 1', () => {
    const rows = buildAnswerSheet([q({ id: 'a', type: 'choice' }), q({ id: 'b', type: 'tf' })]);
    expect(rows).toEqual([{ no: 1, id: 'a', space: { kind: 'symbol' } }, { no: 2, id: 'b', space: { kind: 'tf' } }]);
    expect(buildAnswerSheet([])).toEqual([]);
  });
});
