import { describe, expect, it } from 'vitest';
import { aggregate, cleanAnswers, isSurveyOpen, missingRequired, newQuestionId, textAnswers } from './survey';
import type { SurveyQuestion } from './types';

const Q: SurveyQuestion[] = [
  { id: 'q1', type: 'single', label: '参加できる曜日', options: ['土曜', '日曜'], required: true },
  { id: 'q2', type: 'multi', label: 'やってみたい曲', options: ['A', 'B', 'C'], required: false },
  { id: 'q3', type: 'text', label: 'ひとこと', options: [], required: true }
];

const ts = (ms: number) => ({ toMillis: () => ms }) as never;

describe('survey', () => {
  it('受付中の判定', () => {
    const now = new Date(1_000_000);
    expect(isSurveyOpen({ published: true, closed: false, deadline: null }, now)).toBe(true);
    expect(isSurveyOpen({ published: false, closed: false, deadline: null }, now)).toBe(false);
    expect(isSurveyOpen({ published: true, closed: true, deadline: null }, now)).toBe(false);
    expect(isSurveyOpen({ published: true, closed: false, deadline: ts(999_999) }, now)).toBe(false);
    expect(isSurveyOpen({ published: true, closed: false, deadline: ts(1_000_001) }, now)).toBe(true);
  });

  it('必須の未回答を見つける', () => {
    expect(missingRequired(Q, {})).toEqual(['参加できる曜日', 'ひとこと']);
    expect(missingRequired(Q, { q1: 0, q3: '  ' })).toEqual(['ひとこと']);
    expect(missingRequired(Q, { q1: 1, q3: 'よろしく' })).toEqual([]);
  });

  it('回答を整える（範囲外・重複・不明な質問を除く）', () => {
    expect(cleanAnswers(Q, { q1: 5, q2: [2, 0, 2, 9], q3: 'x'.repeat(2000), zz: 'a' })).toEqual({ q2: [0, 2], q3: 'x'.repeat(1000) });
    expect(cleanAnswers(Q, { q1: 1, q2: [], q3: '' })).toEqual({ q1: 1 });
  });

  it('選択式を集計し、自由記述は数えない', () => {
    const r = aggregate(Q, [
      { memberId: 'a', answers: { q1: 0, q2: [0, 1], q3: 'はい' } },
      { memberId: 'b', answers: { q1: 0, q2: [1, 1] } },
      { memberId: 'c', answers: { q1: 1, q2: 7 as never } }
    ]);
    expect(r).toEqual({ respondents: 3, counts: { q1: [2, 1], q2: [1, 2, 0] } });
  });

  it('自由記述は名前なしで返す', () => {
    expect(textAnswers(Q[2], [
      { memberId: 'b', answers: { q3: 'いい' } },
      { memberId: 'a', answers: { q3: ' ' } },
      { memberId: 'c', answers: { q3: 'あ' } }
    ])).toEqual(['あ', 'いい']);
  });

  it('質問IDは重ならない', () => {
    expect(newQuestionId(Q)).toBe('q4');
    expect(newQuestionId([{ ...Q[0], id: 'q2' }])).toBe('q3');
  });
});
