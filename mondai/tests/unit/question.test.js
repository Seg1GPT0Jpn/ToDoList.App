import { describe, it, expect } from 'vitest';
import {
  QUESTION_TYPES, registerQuestionType, LEVELS, STATUSES, newQuestion, validateQuestion,
  normalizeQuestion, bumpRevision, duplicateQuestion, answerText, ulid, newId,
} from '../../js/domain/question.js';

const fields = (r) => r.errors.map(e => e.field);

describe('QUESTION_TYPES / LEVELS / STATUSES', () => {
  it('has the seven built-in types', () => {
    expect(Object.keys(QUESTION_TYPES).sort()).toEqual(['choice', 'multi', 'order', 'short', 'steps', 'tf', 'written']);
    expect(QUESTION_TYPES.choice).toEqual({ label: '選択', hasChoices: true, answerKind: 'indices' });
    expect(QUESTION_TYPES.steps.answerKind).toBe('subs');
    expect(QUESTION_TYPES.written.hasChoices).toBe(false);
  });
  it('registers a new type', () => {
    registerQuestionType('essay2', { label: '小論文', hasChoices: false, answerKind: 'text' });
    expect(QUESTION_TYPES.essay2.label).toBe('小論文');
    const q = newQuestion({ type: 'essay2', stem: '書け', ans: '模範' });
    expect(validateQuestion(q).ok).toBe(true);
    delete QUESTION_TYPES.essay2;
    expect(() => registerQuestionType('', { label: 'x', hasChoices: false, answerKind: 'text' })).toThrow();
  });
  it('levels and statuses', () => {
    expect(LEVELS).toEqual(['基礎', '標準', '応用']);
    expect(STATUSES.approved).toBe('人間承認済み');
    expect(STATUSES.needs_fix).toBe('要修正');
  });
});

describe('ids', () => {
  it('ulid is 26 chars and sortable', () => {
    const a = [];
    for (let i = 0; i < 200; i++) a.push(ulid());
    expect(a.every(x => /^[0-9A-HJKMNP-TV-Z]{26}$/.test(x))).toBe(true);
    expect(a.slice().sort()).toEqual(a);
    expect(new Set(a).size).toBe(200);
    expect(newId('AI').startsWith('AI-')).toBe(true);
  });
});

describe('newQuestion', () => {
  it('fills defaults', () => {
    const q = newQuestion({ stem: ' 問題 ' });
    expect(q.id).toMatch(/^U-[0-9A-Z]{26}$/);
    expect(q.rev).toBe(1);
    expect(q.status).toBe('unverified');
    expect(q.origin).toBe('user');
    expect(q.src).toBe('自作');
    expect(q.stem).toBe('問題');
    expect(new Date(q.createdAt).toISOString()).toBe(q.createdAt);
    expect(q.updatedAt).toBe(q.createdAt);
    expect(q.choices).toEqual([]);
    expect(q.tags).toEqual([]);
    expect(q.level).toBe('標準');
  });
  it('ids are unique and time sortable', () => {
    const ids = Array.from({ length: 50 }, () => newQuestion().id);
    expect(new Set(ids).size).toBe(50);
    expect(ids.slice().sort()).toEqual(ids);
  });
  it('AI origin uses AI- prefix', () => {
    const q = newQuestion({ origin: 'ai' });
    expect(q.id.startsWith('AI-')).toBe(true);
    expect(q.src).toBe('AI');
  });
  it('steps gets subs', () => {
    expect(newQuestion({ type: 'steps' }).subs).toEqual([]);
  });
});

describe('validateQuestion', () => {
  const base = { stem: '問', level: '基礎' };
  it('accepts a valid choice', () => {
    const r = validateQuestion({ ...base, type: 'choice', choices: ['a', 'b', 'c'], ai: [1] });
    expect(r).toEqual({ ok: true, errors: [], warnings: [] });
  });
  it('requires stem and type', () => {
    const r = validateQuestion({ type: '', stem: '  ' });
    expect(fields(r)).toContain('stem');
    expect(fields(r)).toContain('type');
    expect(validateQuestion({ stem: 'x', type: 'nope' }).ok).toBe(false);
    expect(validateQuestion(null).ok).toBe(false);
  });
  it('choice rules', () => {
    expect(fields(validateQuestion({ ...base, type: 'choice', choices: ['a'], ai: [0] }))).toContain('choices');
    expect(fields(validateQuestion({ ...base, type: 'choice', choices: ['a', ''], ai: [0] }))).toContain('choices[1]');
    expect(fields(validateQuestion({ ...base, type: 'choice', choices: ['a', 'a'], ai: [0] }))).toContain('choices[1]');
    expect(fields(validateQuestion({ ...base, type: 'choice', choices: ['a', 'b'], ai: [] }))).toContain('ai');
    expect(fields(validateQuestion({ ...base, type: 'choice', choices: ['a', 'b'], ai: [0, 1] }))).toContain('ai');
    expect(fields(validateQuestion({ ...base, type: 'choice', choices: ['a', 'b'], ai: [2] }))).toContain('ai');
    expect(fields(validateQuestion({ ...base, type: 'choice', choices: ['a', 'b'], ai: [-1] }))).toContain('ai');
  });
  it('multi rules', () => {
    expect(validateQuestion({ ...base, type: 'multi', choices: ['a', 'b', 'c'], ai: [0, 2] }).ok).toBe(true);
    expect(validateQuestion({ ...base, type: 'multi', choices: ['a', 'b', 'c'], ai: [] }).ok).toBe(false);
    expect(validateQuestion({ ...base, type: 'multi', choices: ['a', 'b', 'c'], ai: [0, 0] }).ok).toBe(false);
  });
  it('order must be a permutation', () => {
    expect(validateQuestion({ ...base, type: 'order', choices: ['a', 'b', 'c'], ai: [2, 0, 1] }).ok).toBe(true);
    expect(validateQuestion({ ...base, type: 'order', choices: ['a', 'b', 'c'], ai: [2, 0] }).ok).toBe(false);
    expect(validateQuestion({ ...base, type: 'order', choices: ['a', 'b', 'c'], ai: [0, 0, 1] }).ok).toBe(false);
    expect(validateQuestion({ ...base, type: 'order', choices: ['a', 'b', 'c'], ai: [0, 1, 3] }).ok).toBe(false);
  });
  it('text answers required', () => {
    for (const type of ['tf', 'short', 'written']) {
      expect(fields(validateQuestion({ ...base, type, ans: '' }))).toContain('ans');
      expect(validateQuestion({ ...base, type, ans: '○' }).ok).toBe(true);
    }
  });
  it('steps validates subs', () => {
    expect(fields(validateQuestion({ ...base, type: 'steps', subs: [] }))).toContain('subs');
    const ok = { ...base, type: 'steps', subs: [{ stem: '(1)', choices: ['a', 'b'], ai: [0] }, { stem: '(2)', ans: '3' }] };
    expect(validateQuestion(ok).ok).toBe(true);
    const bad = { ...base, type: 'steps', subs: [{ stem: '(1)', choices: ['a', 'b'], ai: [5] }, { stem: '(2)' }] };
    const f = fields(validateQuestion(bad));
    expect(f).toContain('subs[0].ai');
    expect(f).toContain('subs[1].ans');
  });
  it('pts and level', () => {
    expect(fields(validateQuestion({ ...base, type: 'short', ans: '1', pts: -1 }))).toContain('pts');
    expect(validateQuestion({ ...base, type: 'short', ans: '1', pts: 0 }).ok).toBe(true);
    expect(fields(validateQuestion({ stem: 'x', type: 'short', ans: '1', level: '難しい' }))).toContain('level');
    const r = validateQuestion({ stem: 'x', type: 'short', ans: '1' });
    expect(r.ok).toBe(true);
    expect(r.warnings.map(w => w.field)).toContain('level');
  });
  it('odd $ count is an error, escaped \\$ ignored', () => {
    expect(fields(validateQuestion({ ...base, type: 'short', ans: '1', stem: '$x^2 を' }))).toContain('stem');
    expect(fields(validateQuestion({ ...base, type: 'choice', choices: ['$a$', '$b'], ai: [0] }))).toContain('choices[1]');
    expect(validateQuestion({ ...base, type: 'short', ans: '$1$', stem: '$x$ と \\$5' }).ok).toBe(true);
  });
  it('rubric sum over pts is a warning', () => {
    const r = validateQuestion({ ...base, type: 'written', ans: 'a', pts: 5, rubric: [{ c: 'x', p: 3 }, { c: 'y', p: 3 }] });
    expect(r.ok).toBe(true);
    expect(r.warnings.map(w => w.field)).toContain('rubric');
    expect(r.warnings[0].message).toMatch(/6点/);
  });
  it('messages are Japanese', () => {
    const r = validateQuestion({ type: 'choice', stem: '' });
    expect(r.errors.every(e => /[ぁ-んァ-ン一-龥]/.test(e.message))).toBe(true);
  });
});

describe('normalizeQuestion', () => {
  it('fills arrays, trims, keeps unknown keys, does not mutate', () => {
    const raw = { id: ' X1 ', stem: ' 問 ', type: 'short', ans: ' 3 ', src: '内蔵', weird: { a: 1 }, uord: 'HS-1', ai: ['1'] };
    const n = normalizeQuestion(raw);
    expect(n.id).toBe('X1');
    expect(n.stem).toBe('問');
    expect(n.ans).toBe('3');
    expect(n.weird).toEqual({ a: 1 });
    expect(n.uord).toBe('HS-1');
    expect(n.choices).toEqual([]);
    expect(n.tags).toEqual([]);
    expect(n.ai).toEqual([1]);
    expect(n.rev).toBe(1);
    expect(n.status).toBe('unverified');
    expect(n.origin).toBe('builtin');
    expect(n.subs).toBeUndefined();
    expect(raw.stem).toBe(' 問 ');
  });
  it('infers type and normalizes subs for steps', () => {
    expect(normalizeQuestion({ stem: 'a', choices: ['x', 'y'] }).type).toBe('choice');
    expect(normalizeQuestion({ stem: 'a' }).type).toBe('short');
    const s = normalizeQuestion({ stem: 'a', type: 'steps', subs: [{ stem: ' (1) ', choices: [' a '], ai: [0] }] });
    expect(s.subs[0]).toEqual({ stem: '(1)', choices: ['a'], ai: [0] });
    expect(normalizeQuestion({ stem: 'a', pts: '5' }).pts).toBe(5);
    expect(normalizeQuestion({}).stem).toBe('');
  });
});

describe('bumpRevision / duplicateQuestion', () => {
  it('bumps rev and stores the previous version', () => {
    const prev = newQuestion({ stem: 'a', type: 'short', ans: '1' });
    const { next, version } = bumpRevision(prev, { ...prev, stem: 'b' }, '修正');
    expect(next.rev).toBe(2);
    expect(next.id).toBe(prev.id);
    expect(next.stem).toBe('b');
    expect(next.updatedAt >= prev.updatedAt).toBe(true);
    expect(version).toMatchObject({ id: prev.id, rev: 1, note: '修正' });
    expect(version.data.stem).toBe('a');
    expect(version.data).not.toBe(prev);
    const r3 = bumpRevision(next, { ...next, stem: 'c' });
    expect(r3.next.rev).toBe(3);
    expect(r3.version.rev).toBe(2);
  });
  it('duplicates with new id and related link', () => {
    const q = normalizeQuestion({ id: 'BI-1', src: '内蔵', stem: 'a', type: 'choice', choices: ['x', 'y'], ai: [0], rev: 4, status: 'approved', related: ['Z'], deleted: true });
    const d = duplicateQuestion(q);
    expect(d.id).not.toBe('BI-1');
    expect(d.id.startsWith('U-')).toBe(true);
    expect(d.rev).toBe(1);
    expect(d.origin).toBe('user');
    expect(d.status).toBe('unverified');
    expect(d.related).toEqual(['Z', 'BI-1']);
    expect(d.deleted).toBeUndefined();
    d.choices.push('z');
    expect(q.choices).toHaveLength(2);
  });
});

describe('answerText', () => {
  it('formats each kind', () => {
    expect(answerText({ id: '1', type: 'choice', stem: '', choices: ['a', 'b', 'c'], ai: [2] })).toBe('ウ');
    expect(answerText({ id: '1', type: 'multi', stem: '', choices: ['a', 'b', 'c'], ai: [0, 2] })).toBe('ア・ウ');
    expect(answerText({ id: '1', type: 'order', stem: '', choices: ['a', 'b', 'c'], ai: [2, 0, 1] })).toBe('ウ → ア → イ');
    expect(answerText({ id: '1', type: 'choice', stem: '', choices: ['a', 'b'], ai: [1] }, ['1', '2'])).toBe('2');
    expect(answerText({ id: '1', type: 'choice', stem: '', choices: ['a', 'b'], ai: [1], cl: ['A', 'B'] })).toBe('B');
    expect(answerText({ id: '1', type: 'short', stem: '', ans: '3' })).toBe('3');
    expect(answerText({ id: '1', type: 'tf', stem: '' })).toBe('');
    expect(answerText({ id: '1', type: 'steps', stem: '', subs: [{ choices: ['a', 'b'], ai: [1] }, { ans: '5' }] })).toBe('(1) イ　(2) 5');
    expect(answerText(null)).toBe('');
  });
});
