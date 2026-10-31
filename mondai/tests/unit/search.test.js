import { describe, it, expect } from 'vitest';
import { parseQuery, matchQuery, searchQuestions } from '../../js/domain/search.js';

const Q = [
  { id: 'a', type: 'choice', stem: '二次関数のグラフの頂点を求めよ', choices: ['(1,2)', '(2,1)'], ai: [0], subj: '数学', course: '数学Ⅰ', grade: '高1', unit: '二次関数', subunit: 'グラフ', level: '標準', src: '内蔵', tags: ['頻出'], status: 'approved' },
  { id: 'b', type: 'short', stem: '三角比 sin 30° の値', ans: '1/2', subj: '数学', course: '数学Ⅰ', grade: '高1', unit: '図形と計量', level: '基礎', src: '自作', tags: [] },
  { id: 'c', type: 'written', stem: 'Explain the Photosynthesis process', ans: '光合成', subj: '理科', course: '生物', grade: '高2', unit: '代謝', level: '応用', src: '内蔵', tags: ['頻出', '記述'], status: 'verified' },
  { id: 'd', type: 'choice', stem: '「枕草子」の作者は誰か', choices: ['清少納言', '紫式部'], ai: [0], subj: '国語', course: '古典', grade: '高1', set: '古文 随筆', level: '基礎', src: '内蔵' },
  { id: 'e', type: 'short', stem: '削除済みの二次関数', ans: 'x', subj: '数学', unit: '二次関数', level: '基礎', deleted: true },
];
const ids = (list) => list.map(q => q.id);
const run = (s) => ids(Q.filter(q => matchQuery(parseQuery(s), q)));

describe('parseQuery', () => {
  it('empty → null', () => {
    expect(parseQuery('')).toBeNull();
    expect(parseQuery('   　 ')).toBeNull();
  });
  it('AND of words, full-width space', () => {
    expect(parseQuery('a　b c')).toEqual({ type: 'and', children: [
      { type: 'term', value: 'a', phrase: false }, { type: 'term', value: 'b', phrase: false }, { type: 'term', value: 'c', phrase: false }] });
  });
  it('OR has lower precedence than AND', () => {
    expect(parseQuery('a b OR c')).toEqual({ type: 'or', children: [
      { type: 'and', children: [{ type: 'term', value: 'a', phrase: false }, { type: 'term', value: 'b', phrase: false }] },
      { type: 'term', value: 'c', phrase: false }] });
  });
  it('exclusion, phrase, fields, nested parens', () => {
    const ast = parseQuery('(subj:数学 OR -(unit:代謝 | tag:記述)) "a b" -level:基礎');
    expect(ast).toEqual({ type: 'and', children: [
      { type: 'or', children: [
        { type: 'field', field: 'subj', value: '数学' },
        { type: 'not', child: { type: 'or', children: [{ type: 'field', field: 'unit', value: '代謝' }, { type: 'field', field: 'tag', value: '記述' }] } },
      ] },
      { type: 'term', value: 'a b', phrase: true },
      { type: 'not', child: { type: 'field', field: 'level', value: '基礎' } },
    ] });
  });
  it('quoted field value and full-width colon', () => {
    expect(parseQuery('unit:"二次 関数"')).toEqual({ type: 'field', field: 'unit', value: '二次 関数' });
    expect(parseQuery('教科：数学')).toEqual({ type: 'field', field: 'subj', value: '数学' });
    expect(parseQuery('subunit:')).toEqual({ type: 'field', field: 'subunit', value: '' });
  });
  it('unknown key stays a term; parens inside words stay', () => {
    expect(parseQuery('foo:bar')).toEqual({ type: 'term', value: 'foo:bar', phrase: false });
    expect(parseQuery('constructor:x')).toEqual({ type: 'term', value: 'constructor:x', phrase: false });
    expect(parseQuery('f(x)')).toEqual({ type: 'term', value: 'f(x)', phrase: false });
    expect(parseQuery('(f(x) OR g)')).toEqual({ type: 'or', children: [{ type: 'term', value: 'f(x)', phrase: false }, { type: 'term', value: 'g', phrase: false }] });
  });
  it('tolerates unbalanced parens and dangling operators', () => {
    expect(() => parseQuery('((a OR')).not.toThrow();
    expect(parseQuery('((a OR')).toEqual({ type: 'term', value: 'a', phrase: false });
    expect(parseQuery('a)) b')).toEqual({ type: 'and', children: [{ type: 'term', value: 'a', phrase: false }, { type: 'term', value: 'b', phrase: false }] });
    expect(parseQuery('OR')).toBeNull();
    expect(parseQuery('- a')).toEqual({ type: 'term', value: 'a', phrase: false });
    expect(parseQuery('a -')).toEqual({ type: 'term', value: 'a', phrase: false });
  });
  it('lowercase or is a word', () => {
    expect(parseQuery('a or b').type).toBe('and');
  });
});

describe('matchQuery', () => {
  it('null matches all', () => { expect(matchQuery(null, Q[0])).toBe(true); });
  it('substring on stem/choices/ans/unit/tags/course, case-insensitive', () => {
    expect(run('二次関数')).toEqual(['a', 'e']);
    expect(run('photosynthesis')).toEqual(['c']);
    expect(run('清少納言')).toEqual(['d']);
    expect(run('1/2')).toEqual(['b']);
    expect(run('随筆')).toEqual(['d']);
    expect(run('頻出')).toEqual(['a', 'c']);
    expect(run('数学I')).toEqual(['a', 'b']); // 全角Ⅰ と半角 I を同じに扱う
    expect(run('ＳＩＮ')).toEqual(['b']);
  });
  it('AND / OR / NOT', () => {
    expect(run('二次関数 頂点')).toEqual(['a']);
    expect(run('頂点 OR 枕草子')).toEqual(['a', 'd']);
    expect(run('頻出 -記述')).toEqual(['a']);
    expect(run('(subj:数学 OR subj:国語) -level:基礎')).toEqual(['a']);
    expect(run('-(subj:数学 | subj:理科)')).toEqual(['d']);
    expect(run('"グラフの頂点"')).toEqual(['a']);
    expect(run('"頂点 グラフ"')).toEqual([]);
  });
  it('field filters', () => {
    expect(run('subj:数学')).toEqual(['a', 'b', 'e']);
    expect(run('course:数学Ⅰ')).toEqual(['a', 'b']);
    expect(run('grade:高1')).toEqual(['a', 'b', 'd']);
    expect(run('unit:二次')).toEqual(['a', 'e']);
    expect(run('unit:古文')).toEqual(['d']);
    expect(run('subunit:グラフ')).toEqual(['a']);
    expect(run('subunit:')).toEqual(['b', 'c', 'd', 'e']);
    expect(run('level:応用')).toEqual(['c']);
    expect(run('type:choice')).toEqual(['a', 'd']);
    expect(run('type:記述')).toEqual(['c']);
    expect(run('src:内蔵')).toEqual(['a', 'c', 'd']);
    expect(run('tag:頻出')).toEqual(['a', 'c']);
    expect(run('tag:頻')).toEqual([]);
    expect(run('status:approved')).toEqual(['a']);
    expect(run('status:検証済み')).toEqual(['c']);
    expect(run('status:unverified')).toEqual(['b', 'd', 'e']);
    expect(run('id:a')).toEqual(['a']);
  });
});

describe('searchQuestions', () => {
  it('filters + query, excludes deleted', () => {
    expect(ids(searchQuestions(Q, ''))).toEqual(['a', 'b', 'c', 'd']);
    expect(ids(searchQuestions(Q, '', { includeDeleted: true }))).toEqual(['a', 'b', 'c', 'd', 'e']);
    expect(ids(searchQuestions(Q, '二次関数'))).toEqual(['a']);
    expect(ids(searchQuestions(Q, '', { subj: '数学', level: '基礎' }))).toEqual(['b']);
    expect(ids(searchQuestions(Q, '', { units: new Set(['二次関数', '代謝']) }))).toEqual(['a', 'c']);
    expect(ids(searchQuestions(Q, '', { units: ['古文 随筆'] }))).toEqual(['d']);
    expect(ids(searchQuestions(Q, '', { units: [] }))).toEqual(['a', 'b', 'c', 'd']);
    expect(ids(searchQuestions(Q, '', { tags: ['頻出', '記述'] }))).toEqual(['c']);
    expect(ids(searchQuestions(Q, '', { status: 'unverified' }))).toEqual(['b', 'd']);
    expect(ids(searchQuestions(Q, '', { type: 'choice', src: '内蔵', grade: '高1', stage: '' }))).toEqual(['a', 'd']);
    expect(ids(searchQuestions(Q, 'OR', { cat: 'none' }))).toEqual([]);
    expect(searchQuestions(null, 'x')).toEqual([]);
  });
});
