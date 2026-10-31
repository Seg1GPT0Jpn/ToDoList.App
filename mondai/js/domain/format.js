// 入試の形式（神奈川県公立高校入試・大学入学共通テスト・大学入試 二次試験）
// 番号の付け方、選択肢の記号、数値のマーク欄、表紙、解答用紙の作りを形式ごとに決める

const KATA = 'アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン'.split('');
const HIRA = 'あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん'.split('');
const KANA_SUB = 'アイウエオカキクケコサシスセソ'.split('');

/** 記号の列を n 個作る（足りなければ 2 文字にする） */
function seq(base, n) {
  const out = [];
  for (let i = 0; i < n; i++) out.push(i < base.length ? base[i] : base[Math.floor(i / base.length) - 1] + base[i % base.length]);
  return out;
}

/**
 * @typedef {Object} ExamFormat
 * @property {string} label
 * @property {string} [short]
 * @property {(n:number)=>string} [dai] 大問の見出し
 * @property {(k:number)=>string} [sub] 小問の番号
 * @property {string} [labels] 選択肢の記号（render.js の LABELS のキー）
 * @property {'none'|'number'} [answerNo] 選択問題に解答番号の枠をつける（共通テスト）
 * @property {'none'|'kata'|'hira'} [digits] 整数の答えを1けたずつマークさせる記号
 * @property {'mark'|'written'|'perDai'} [sheet] 解答用紙の作り
 * @property {boolean} [cover] 表紙をつける
 * @property {string[]} [notes] 表紙の注意事項
 * @property {{timeMin:number,total:number,sections:{title:string,count:number,type?:string}[],levelRatio:Record<string,number>,types?:string[]}} [preset] テスト制作の初期値
 */

/** @type {Record<string, ExamFormat>} */
export const FORMATS = {
  standard: { label: '通常（プリント・定期テスト）' },
  kanagawa: {
    label: '神奈川県公立高校入試の形式', short: '神奈川県入試',
    dai: (n) => `問${n}`, sub: (k) => `(${KANA_SUB[k] || k + 1})`,
    labels: 'num', answerNo: 'none', digits: 'hira', sheet: 'mark', cover: true,
    notes: [
      '指示があるまで、この問題用紙を開いてはいけません。',
      '解答用紙に受検番号・氏名を記入し、受検番号をマークしなさい。',
      '答えはすべて解答用紙に記入またはマークしなさい。選択肢から選ぶ問題は、番号をマークしなさい。',
      '数値を答える問題で「あい」などの文字がある場合は、それぞれ1つの数字（0〜9）をマークしなさい。',
      '解答用紙は折ったり、汚したりしてはいけません。',
    ],
    preset: { timeMin: 50, total: 100, sections: [{ title: '', count: 6 }, { title: '', count: 5 }, { title: '', count: 3 }, { title: '', count: 3 }, { title: '', count: 2 }, { title: '', count: 2 }], levelRatio: { 基礎: 4, 標準: 4, 応用: 2 }, types: ['choice', 'short', 'written'] },
  },
  kyotsu: {
    label: '大学入学共通テストの形式', short: '共通テスト',
    dai: (n) => `第${n}問`, sub: (k) => `問${k + 1}`,
    labels: 'circled', answerNo: 'number', digits: 'kata', sheet: 'mark', cover: true,
    notes: [
      '試験開始の合図があるまで、この問題冊子の中を見てはいけません。',
      '解答は、解答用紙の解答欄にマークしなさい。例えば、[ 1 ] と表示のある問いに対して③と解答する場合は、解答番号1の解答欄の③にマークしなさい。',
      '問題の文中の [ ア ]、[ イウ ] などには、符号（−）または数字（0〜9）が入ります。ア、イ、ウ、…の一つ一つは、これらのいずれか一つに対応します。それらを解答用紙のア、イ、ウ、…で示された解答欄にマークしなさい。',
      '分数形で解答する場合は、既約分数で答えなさい。根号を含む形で解答する場合は、根号の中に現れる自然数が最小となる形で答えなさい。',
      '問題冊子の余白等は適宜利用してよいが、どのページも切り離してはいけません。',
    ],
    preset: { timeMin: 70, total: 100, sections: [{ title: '', count: 5 }, { title: '', count: 5 }, { title: '', count: 4 }, { title: '', count: 4 }], levelRatio: { 基礎: 2, 標準: 5, 応用: 3 }, types: ['choice', 'short'] },
  },
  niji: {
    label: '大学入試 二次試験（記述式）の形式', short: '二次試験',
    dai: (n) => `第${n}問`, sub: (k) => `(${k + 1})`,
    labels: 'kana', answerNo: 'none', digits: 'none', sheet: 'perDai', cover: true,
    notes: [
      '試験開始の合図があるまで、この問題冊子を開いてはいけません。',
      '解答はすべて解答用紙の所定の欄に記入しなさい。答えに至る過程も記述すること。',
      '解答用紙の裏面には記入してはいけません。',
      '問題冊子の余白は計算に使用してよい。',
    ],
    preset: { timeMin: 120, total: 100, sections: [{ title: '', count: 3 }, { title: '', count: 3 }, { title: '', count: 3 }, { title: '', count: 3 }], levelRatio: { 基礎: 0, 標準: 2, 応用: 3 }, types: ['short', 'written'] },
  },
};

export const formatOf = (m) => FORMATS[(m && m.print && m.print.format) || 'standard'] || FORMATS.standard;

/** 整数の答え（マークで答えさせられる数）。そうでなければ null */
export function integerAnswer(q) {
  if (!q || q.type !== 'short') return null;
  // 「$-4$」のような数式記号つきの答えも、数だけなら整数の答えとして扱う
  const s = String(q.ans || '').normalize('NFKC').replace(/\$/g, '').replace(/[−ー–]/g, '-').trim();
  const m = /^(-?\d+)(\s*[^\d.\/\\$]*)?$/.exec(s);
  if (!m) return null;
  const n = Number(m[1]);
  return Number.isSafeInteger(n) && Math.abs(n) < 1e6 ? n : null;
}

/** マーク欄の記号を順に配る */
export function digitLabeler(kind) {
  const base = kind === 'hira' ? HIRA : KATA;
  let i = 0;
  return (count) => { const out = seq(base, i + count).slice(i); i += count; return out; };
}

/** テスト制作で、この形式に合う問題か */
export function fitsFormat(q, key) {
  const f = FORMATS[key];
  if (!f || !f.preset) return true;
  if (key === 'kyotsu') return ['choice', 'multi'].includes(q.type) || integerAnswer(q) != null;
  if (key === 'niji') return ['short', 'written'].includes(q.type);
  return ['choice', 'multi', 'short', 'written', 'order'].includes(q.type);
}

export const CIRCLED = ['①', '②', '③', '④', '⑤', '⑥', '⑦', '⑧', '⑨', '⓪'];
