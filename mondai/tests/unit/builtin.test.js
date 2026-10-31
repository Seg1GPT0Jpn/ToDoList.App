import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { validateQuestion, normalizeQuestion } from '../../js/domain/question.js';
import { findDuplicateGroups, findSimilar } from '../../js/domain/similarity.js';
import { searchQuestions } from '../../js/domain/search.js';
import { buildExam } from '../../js/domain/exam.js';
import { questionsToCSV, csvToQuestions } from '../../js/domain/csv.js';
import { buildAnswerSheet } from '../../js/domain/answersheet.js';

const data = JSON.parse(readFileSync(fileURLToPath(new URL('../../builtin/hs.json', import.meta.url)), 'utf8'));
const questions = data.questions;

describe('builtin/hs.json', () => {
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
