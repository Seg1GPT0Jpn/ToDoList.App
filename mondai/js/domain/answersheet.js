// 解答用紙の解答欄の種類と大きさを決める。

/**
 * @typedef {import('./question.js').Question} Question
 * @typedef {{ kind: 'symbol'|'symbols'|'tf'|'calc'|'written'|'proof'|'english'|'order'|'short', cells?: number, lines?: number, chars?: number }} AnswerSpace
 */

const CALC_SUBJ = new Set(['数学', '理科']);

/**
 * 問題に合った解答欄。
 * @param {Question} q
 * @returns {AnswerSpace}
 */
export function answerSpaceFor(q) {
  const stem = String((q && q.stem) || '');
  switch (q && q.type) {
    case 'choice': return { kind: 'symbol' };
    case 'multi': return { kind: 'symbols' };
    case 'tf': return { kind: 'tf' };
    case 'order': return { kind: 'order', cells: (q.choices || []).length };
    case 'steps': return { kind: 'symbols', cells: (q.subs || []).length };
    case 'short':
      if (CALC_SUBJ.has(q.subj) && /求め|計算/.test(stem)) return { kind: 'calc', lines: q.lines || 3 };
      return { kind: 'short' };
    case 'written': {
      /** @type {AnswerSpace} */
      let sp;
      if (/証明/.test(stem)) sp = { kind: 'proof', lines: Math.max(8, q.lines || 0) };
      else if (q.subj === '英語') sp = { kind: 'english', lines: q.lines || 4 };
      else sp = { kind: 'written', lines: q.lines || 4 };
      if (q.grid) sp.chars = q.grid;
      return sp;
    }
    default: return { kind: 'short' };
  }
}

/**
 * 解答用紙の行（番号は1から）。
 * @param {Question[]} questions
 * @returns {{ no: number, id: string, space: AnswerSpace }[]}
 */
export function buildAnswerSheet(questions) {
  return (questions || []).map((q, i) => ({ no: i + 1, id: q.id, space: answerSpaceFor(q) }));
}
