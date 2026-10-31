import { describe, it, expect } from 'vitest';
import { toCSV, parseCSV, questionsToCSV, csvToQuestions, QUESTION_CSV_HEADERS } from '../../js/domain/csv.js';
import { newQuestion } from '../../js/domain/question.js';

describe('toCSV / parseCSV', () => {
  it('quotes commas, quotes, newlines; CRLF', () => {
    const csv = toCSV([{ a: 'x,y', b: 'say "hi"' }, { a: '改行\nあり', b: '' }], [{ key: 'a', header: '列A' }, 'b']);
    expect(csv).toBe('列A,b\r\n"x,y","say ""hi"""\r\n"改行\nあり",\r\n');
    expect(parseCSV(csv)).toEqual([['列A', 'b'], ['x,y', 'say "hi"'], ['改行\nあり', '']]);
  });
  it('arrays without columns, BOM option', () => {
    const csv = toCSV([[1, 2], [null, 'a']], undefined, { bom: true });
    expect(csv.charCodeAt(0)).toBe(0xFEFF);
    expect(parseCSV(csv)).toEqual([['1', '2'], ['', 'a']]);
    expect(toCSV([{ a: 1 }], ['a'], { header: false })).toBe('1\r\n');
    expect(toCSV([])).toBe('');
  });
  it('parses BOM, CRLF, LF, CR, blank lines, trailing newline, empty quoted', () => {
    expect(parseCSV('﻿a,b\r\n1,2\r\n')).toEqual([['a', 'b'], ['1', '2']]);
    expect(parseCSV('a,b\n1,2')).toEqual([['a', 'b'], ['1', '2']]);
    expect(parseCSV('a\r1\r')).toEqual([['a'], ['1']]);
    expect(parseCSV('a\n\n\nb\n')).toEqual([['a'], ['b']]);
    expect(parseCSV('""\n')).toEqual([['']]);
    expect(parseCSV('a,,\n')).toEqual([['a', '', '']]);
    expect(parseCSV('"a\r\nb",c')).toEqual([['a\r\nb', 'c']]);
    expect(parseCSV('')).toEqual([]);
    expect(parseCSV(null)).toEqual([]);
    expect(parseCSV('"unterminated')).toEqual([['unterminated']]);
  });
  it('round-trips arbitrary values', () => {
    const rows = [['日本語', 'カンマ,入り', '"引用"', '改\r\n行', ' 前後空白 ', ''], ['$\\frac{1}{2}$', 'a""b', '\n', ',', '"', 'x']];
    expect(parseCSV(toCSV(rows))).toEqual(rows);
  });
});

describe('questionsToCSV / csvToQuestions', () => {
  const list = [
    newQuestion({ id: 'Q1', type: 'choice', subj: '数学', course: '数学Ⅰ', grade: '高1', unit: '二次関数', subunit: 'グラフ', level: '基礎',
      stem: '頂点は、どれか。\n"正しい"ものを選べ', choices: ['(1,2)', '(2,1)', 'なし, ある'], ai: [1], expl: '平方完成する。\n以上', pts: 5, tags: ['頻出', '計算'], src: '内蔵', status: 'approved' }),
    newQuestion({ id: 'Q2', type: 'multi', stem: '素数を選べ', choices: ['2', '3', '4', '5'], ai: [0, 1, 3], level: '標準' }),
    newQuestion({ id: 'Q3', type: 'order', stem: '並べよ', choices: ['c', 'a', 'b'], ai: [1, 2, 0], level: '応用' }),
    newQuestion({ id: 'Q4', type: 'short', stem: '$x^2=4$ の正の解', ans: '$2$', level: '標準' }),
    newQuestion({ id: 'Q5', type: 'written', stem: '説明せよ', ans: '理由は、\n「A」だから。', level: '応用', status: 'needs_fix' }),
    newQuestion({ id: 'Q6', type: 'tf', stem: '地球は丸い', ans: '○', level: '基礎' }),
  ];
  it('uses the Japanese headers', () => {
    const csv = questionsToCSV(list);
    const rows = parseCSV(csv);
    expect(rows[0]).toEqual(QUESTION_CSV_HEADERS);
    expect(rows[0].slice(0, 9)).toEqual(['ID', '形式', '教科', '科目', '学年', '単元', '小単元', '難易度', '問題文']);
    expect(rows[0].slice(-6)).toEqual(['正解', '解説', '配点', 'タグ', '出典', '検証状態']);
    expect(rows[1][1]).toBe('選択');
    expect(rows[1][QUESTION_CSV_HEADERS.indexOf('正解')]).toBe('2');
    expect(rows[2][QUESTION_CSV_HEADERS.indexOf('正解')]).toBe('1,2,4');
    expect(rows[1][QUESTION_CSV_HEADERS.indexOf('検証状態')]).toBe('人間承認済み');
  });
  it('round-trips', () => {
    const { questions, errors } = csvToQuestions(questionsToCSV(list));
    expect(errors).toEqual([]);
    expect(questions).toHaveLength(list.length);
    const keys = ['id', 'type', 'subj', 'course', 'grade', 'unit', 'subunit', 'level', 'stem', 'choices', 'ai', 'ans', 'expl', 'pts', 'tags', 'src', 'status'];
    questions.forEach((q, i) => {
      for (const k of keys) {
        const want = list[i][k];
        if (k === 'ans' && list[i].choices.length) continue;
        expect(q[k], `${list[i].id}.${k}`).toEqual(want);
      }
    });
  });
  it('accepts kana / letter answers, any column order, type keys', () => {
    const csv = '問題文,正解,選択肢1,選択肢2,選択肢3,形式\nどれ,イ,a,b,c,choice\nどれ2,c,a,b,c,選択\nどれ3,ア・ウ,a,b,c,複数選択\n答え,42,,,,\n';
    const { questions, errors } = csvToQuestions(csv);
    expect(errors).toEqual([]);
    expect(questions.map(q => q.ai)).toEqual([[1], [2], [0, 2], []]);
    expect(questions[3].type).toBe('short');
    expect(questions[3].ans).toBe('42');
    expect(questions[0].id).toMatch(/^U-/);
    expect(questions[0].origin).toBe('imported');
  });
  it('reports row errors', () => {
    const csv = '問題文,形式,正解,選択肢1,選択肢2,検証状態,難易度\n'
      + 'ok,選択,1,a,b,,基礎\n'
      + ',答えのみ,3,,,,\n'
      + 'q,選択,9,a,b,,\n'
      + 'q,ないよ,1,,,,\n'
      + 'q,小問つき,1,,,,\n'
      + 'q,答えのみ,1,,,変な状態,\n'
      + 'q,答えのみ,1,,,,激ムズ\n';
    const { questions, errors } = csvToQuestions(csv);
    expect(questions).toHaveLength(1);
    expect(errors.map(e => e.row)).toEqual([3, 4, 5, 6, 7, 8]);
    expect(errors[0].message).toMatch(/^3行目：/);
    expect(csvToQuestions('').errors[0].message).toMatch(/空/);
    expect(csvToQuestions('a,b\n1,2').errors[0].message).toMatch(/問題文/);
  });
});
