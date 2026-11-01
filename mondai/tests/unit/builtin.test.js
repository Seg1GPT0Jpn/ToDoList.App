import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { validateQuestion, normalizeQuestion } from '../../js/domain/question.js';
import { findDuplicateGroups, findSimilar } from '../../js/domain/similarity.js';
import { searchQuestions } from '../../js/domain/search.js';
import { buildExam } from '../../js/domain/exam.js';
import { questionsToCSV, csvToQuestions } from '../../js/domain/csv.js';
import { buildAnswerSheet } from '../../js/domain/answersheet.js';

import { fitsFormat, integerAnswer } from '../../js/domain/format.js';

const load = (f) => JSON.parse(readFileSync(fileURLToPath(new URL('../../builtin/' + f, import.meta.url)), 'utf8'));

for (const file of ['hs.json', 'jh.json']) {
const data = load(file);
const questions = data.questions;

describe('builtin/' + file, () => {
  it('has questions', () => { expect(questions.length).toBeGreaterThan(1000); });

  it('every question passes validateQuestion (raw and normalized)', () => {
    const failures = [];
    for (const q of questions) {
      const r = validateQuestion(q);
      if (!r.ok) failures.push(`${q.id}: ${r.errors.map(e => `${e.field} ${e.message}`).join(' / ')}`);
      expect(validateQuestion(normalizeQuestion(q)).ok, q.id).toBe(r.ok);
    }
    if (failures.length) console.warn('内蔵問題の検証エラー:\n' + failures.slice(0, 50).join('\n'));
    expect(failures).toEqual([]);
  });

  it('findDuplicateGroups runs', () => {
    const t0 = performance.now();
    const groups = findDuplicateGroups(questions);
    expect(performance.now() - t0).toBeLessThan(3000);
    for (const g of groups) {
      expect(['exact', 'numeric_variant']).toContain(g.kind);
      expect(g.ids.length).toBeGreaterThanOrEqual(2);
    }
  });

  it('other modules work on real data', () => {
    expect(searchQuestions(questions, 'subj:数学 level:応用').every(q => q.subj === '数学' && q.level === '応用')).toBe(true);
    expect(findSimilar(questions[0], questions).every(c => c.q.id !== questions[0].id)).toBe(true);
    const ex = buildExam(questions, { count: 20, total: 100, include: { subj: '数学' }, levelRatio: { 基礎: 3, 標準: 5, 応用: 2 } }, { seed: 1 });
    expect(ex.questions).toHaveLength(20);
    expect(ex.stats.byLevel).toEqual({ 基礎: 6, 標準: 10, 応用: 4 });
    expect(buildAnswerSheet(ex.questions)).toHaveLength(20);
    const sample = questions.slice(0, 200).map(normalizeQuestion);
    const back = csvToQuestions(questionsToCSV(sample));
    expect(back.errors).toEqual([]);
    expect(back.questions.map(q => q.stem)).toEqual(sample.map(q => q.stem));
  });
});
}

describe('builtin/jh.json（中学・神奈川県入試形式）', () => {
  const data = load('jh.json');
  const qs = data.questions;
  const units = new Set(qs.map(q => q.uord));

  it('全単元に 基礎10・標準20・応用10', () => {
    expect(units.size).toBe(88);
    for (const u of units) {
      const lv = { 基礎: 0, 標準: 0, 応用: 0 };
      for (const q of qs) if (q.uord === u) lv[q.level]++;
      expect(lv, u).toEqual({ 基礎: 10, 標準: 20, 応用: 10 });
    }
  });

  it('中学・神奈川県入試の形式に合う', () => {
    expect(qs.every(q => q.stage === '中学' && /^中[123]$/.test(q.grade) && q.src === '内蔵')).toBe(true);
    expect(qs.every(q => fitsFormat(q, 'kanagawa'))).toBe(true);
    for (const q of qs.filter(q => q.type === 'choice')) expect(q.choices, q.id).toHaveLength(4);
    // 数学の答えのみの問題は、多くが整数（マーク式で答えられる）
    const mathShort = qs.filter(q => q.subj === '数学' && q.type === 'short');
    expect(mathShort.filter(q => integerAnswer(q) != null).length / mathShort.length).toBeGreaterThan(0.5);
  });

  it('資料（stimulus）と図がそろっている', () => {
    for (const q of qs) {
      if (q.sid) expect(data.stims[q.sid], q.id).toBeTruthy();
      if (q.fig) expect(q.fig.svg, q.id).toMatch(/^<svg /);
      if (q.grid) expect(q.grid).toBeGreaterThanOrEqual(10);
    }
    for (const st of Object.values(data.stims)) if (st.fig) expect(st.fig.svg).toMatch(/^<svg /);
    expect(qs.filter(q => q.sid).length).toBeGreaterThan(100);
    expect(qs.filter(q => q.fig).length + Object.values(data.stims).filter(st => st.fig).length).toBeGreaterThan(50);
  });

  it('高校の内蔵問題と id が重ならない', () => {
    const hs = new Set(load('hs.json').questions.map(q => q.id));
    expect(qs.filter(q => hs.has(q.id))).toEqual([]);
  });
});
