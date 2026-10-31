// CSV（RFC 4180）の読み書きと、問題の CSV 入出力。
import { QUESTION_TYPES, STATUSES, CHOICE_LABELS, newQuestion, validateQuestion, answerText } from './question.js';

/**
 * @typedef {import('./question.js').Question} Question
 * @typedef {string | { key: string, header?: string }} CsvColumn
 */

/** @param {*} v */
function cell(v) {
  const s = v == null ? '' : String(v);
  return /[",\r\n]|^\s|\s$/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s;
}

/**
 * 行を CSV にする。rows が配列の配列なら columns は省略可（そのまま出力）。
 * rows がオブジェクトの配列なら columns の key の値を、header（なければ key）を見出しにして出力する。
 * 改行は CRLF。
 * @param {Array<Record<string, any>|any[]>} rows
 * @param {CsvColumn[]} [columns]
 * @param {{ bom?: boolean, header?: boolean }} [opts]
 * @returns {string}
 */
export function toCSV(rows, columns, opts = {}) {
  /** @type {string[]} */
  const lines = [];
  const list = rows || [];
  if (columns && columns.length) {
    const cols = columns.map(c => (typeof c === 'string' ? { key: c, header: c } : { key: c.key, header: c.header ?? c.key }));
    if (opts.header !== false) lines.push(cols.map(c => cell(c.header)).join(','));
    for (const r of list) {
      lines.push(cols.map((c, i) => cell(Array.isArray(r) ? r[i] : r[c.key])).join(','));
    }
  } else {
    for (const r of list) lines.push((Array.isArray(r) ? r : Object.values(r)).map(cell).join(','));
  }
  return (opts.bom ? '﻿' : '') + lines.map(l => l + '\r\n').join('');
}

/**
 * CSV を読む（引用符・"" の escape・欄内の改行・BOM・CRLF/LF/CR に対応）。空行は飛ばす。
 * @param {string} text
 * @returns {string[][]}
 */
export function parseCSV(text) {
  const s = String(text == null ? '' : text).replace(/^﻿/, '');
  /** @type {string[][]} */
  const rows = [];
  /** @type {string[]} */
  let row = [];
  let field = '';
  let i = 0;
  let quoted = false;
  let wasQuoted = false;
  const endField = () => { row.push(field); field = ''; wasQuoted = false; };
  const endRow = () => {
    endField();
    if (!(row.length === 1 && row[0] === '' && !rowHadQuote)) rows.push(row);
    row = [];
    rowHadQuote = false;
  };
  let rowHadQuote = false;
  while (i < s.length) {
    const c = s[i];
    if (quoted) {
      if (c === '"') {
        if (s[i + 1] === '"') { field += '"'; i += 2; continue; }
        quoted = false; i++; continue;
      }
      field += c; i++; continue;
    }
    if (c === '"' && field === '' && !wasQuoted) { quoted = true; wasQuoted = true; rowHadQuote = true; i++; continue; }
    if (c === ',') { endField(); i++; continue; }
    if (c === '\r' || c === '\n') {
      endRow();
      i += (c === '\r' && s[i + 1] === '\n') ? 2 : 1;
      continue;
    }
    field += c; i++;
  }
  if (field !== '' || row.length || wasQuoted) endRow();
  return rows;
}

// ---------- 問題の CSV ----------
export const MAX_CSV_CHOICES = 6;
export const QUESTION_CSV_HEADERS = ['ID', '形式', '教科', '科目', '学年', '単元', '小単元', '難易度', '問題文',
  ...Array.from({ length: MAX_CSV_CHOICES }, (_, i) => `選択肢${i + 1}`), '正解', '解説', '配点', 'タグ', '出典', '検証状態'];

/** @param {Question} q */
function correctCell(q) {
  const def = QUESTION_TYPES[q.type];
  if (def && def.answerKind === 'indices') return (q.ai || []).map(i => i + 1).join(',');
  if (def && def.answerKind === 'subs') return answerText(q);
  return q.ans || '';
}

/**
 * 問題一覧を CSV にする（Excel で開けるよう BOM つき）。選択肢は6つまで。
 * @param {Question[]} list
 * @returns {string}
 */
export function questionsToCSV(list) {
  const rows = (list || []).map(q => {
    const ch = q.choices || [];
    return [
      q.id, (QUESTION_TYPES[q.type] && QUESTION_TYPES[q.type].label) || q.type, q.subj, q.course, q.grade, q.unit, q.subunit, q.level, q.stem,
      ...Array.from({ length: MAX_CSV_CHOICES }, (_, i) => ch[i] ?? ''),
      correctCell(q), q.expl, q.pts ?? '', (q.tags || []).join('、'), q.src, STATUSES[q.status || 'unverified'] || q.status,
    ];
  });
  return toCSV([QUESTION_CSV_HEADERS, ...rows], undefined, { bom: true });
}

/** @param {string} v */
function typeFrom(v) {
  const s = (v || '').trim();
  if (!s) return '';
  if (QUESTION_TYPES[s]) return s;
  for (const [k, d] of Object.entries(QUESTION_TYPES)) if (d.label === s) return k;
  return s;
}
/** @param {string} v */
function statusFrom(v) {
  const s = (v || '').trim();
  if (!s) return 'unverified';
  if (STATUSES[s]) return s;
  for (const [k, label] of Object.entries(STATUSES)) if (label === s) return k;
  return s;
}

/**
 * 正解欄（1始まりの番号、またはア・イ…の記号、A・B…）を選択肢番号の配列にする。
 * @param {string} v
 * @param {number} n 選択肢の数
 * @returns {number[]|null}
 */
function parseIndices(v, n) {
  const parts = String(v || '').normalize('NFKC').split(/[\s,、・→>;]+/).filter(Boolean);
  if (!parts.length) return null;
  /** @type {number[]} */
  const out = [];
  for (const p of parts) {
    let i = -1;
    if (/^\d+$/.test(p)) i = Number(p) - 1;
    else if (CHOICE_LABELS.includes(p)) i = CHOICE_LABELS.indexOf(p);
    else if (/^[A-Za-z]$/.test(p)) i = p.toUpperCase().charCodeAt(0) - 65;
    if (i < 0 || i >= n) return null;
    out.push(i);
  }
  return out;
}

/**
 * CSV から問題を作る。見出し行の名前で列を決める（列の順番は自由）。
 * 正しくない行は questions に入れず、errors に行番号（見出しを1行目とする）と理由を入れる。
 * @param {string} text
 * @returns {{ questions: Question[], errors: { row: number, message: string }[] }}
 */
export function csvToQuestions(text) {
  const rows = parseCSV(text);
  /** @type {Question[]} */
  const questions = [];
  /** @type {{ row: number, message: string }[]} */
  const errors = [];
  if (!rows.length) return { questions, errors: [{ row: 0, message: 'CSV が空です' }] };
  const head = rows[0].map(h => h.trim());
  const col = (/** @type {string} */ name) => head.indexOf(name);
  if (col('問題文') < 0) return { questions, errors: [{ row: 1, message: '見出し行に「問題文」の列がありません' }] };
  const choiceCols = head.map((h, i) => [h, i]).filter(([h]) => /^選択肢\d+$/.test(String(h)))
    .sort((a, b) => Number(String(a[0]).slice(3)) - Number(String(b[0]).slice(3))).map(([, i]) => Number(i));

  for (let r = 1; r < rows.length; r++) {
    const line = r + 1;
    const row = rows[r];
    const get = (/** @type {string} */ name) => { const i = col(name); return i >= 0 && row[i] != null ? row[i] : ''; };
    if (row.every(c => c.trim() === '')) continue;
    const choices = choiceCols.map(i => row[i] ?? '');
    while (choices.length && choices[choices.length - 1].trim() === '') choices.pop();
    const type = typeFrom(get('形式')) || (choices.length ? 'choice' : 'short');
    if (type === 'steps') { errors.push({ row: line, message: `${line}行目：小問つきの問題は CSV から取り込めません` }); continue; }
    if (!QUESTION_TYPES[type]) { errors.push({ row: line, message: `${line}行目：形式「${type}」は使えません` }); continue; }
    /** @type {Record<string, any>} */
    const partial = {
      type,
      subj: get('教科'), course: get('科目'), grade: get('学年'), unit: get('単元'), subunit: get('小単元'),
      level: get('難易度'), stem: get('問題文'), expl: get('解説'),
      tags: get('タグ').split(/[、,;|]/).map(t => t.trim()).filter(Boolean),
      status: statusFrom(get('検証状態')),
      origin: 'imported',
    };
    if (get('ID').trim()) partial.id = get('ID').trim();
    if (get('出典').trim()) partial.src = get('出典').trim();
    const pts = get('配点').trim();
    if (pts !== '') partial.pts = Number(pts);
    const correct = get('正解');
    if (QUESTION_TYPES[type].hasChoices) {
      partial.choices = choices;
      const ai = parseIndices(correct, choices.length);
      if (!ai) { errors.push({ row: line, message: `${line}行目：正解「${correct}」を選択肢の番号として読めません` }); continue; }
      partial.ai = ai;
    } else {
      partial.ans = correct;
      partial.choices = [];
    }
    if (!STATUSES[partial.status]) { errors.push({ row: line, message: `${line}行目：検証状態「${partial.status}」は使えません` }); continue; }
    const q = newQuestion(partial);
    const v = validateQuestion(q);
    if (!v.ok) {
      errors.push({ row: line, message: `${line}行目：${v.errors.map(e => e.message).join('／')}` });
      continue;
    }
    questions.push(q);
  }
  return { questions, errors };
}
