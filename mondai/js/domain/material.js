// 教材（プリント・テスト・問題集など）のデータ構造
// 教材はブロックの並び。問題ブロックは「使った時点の問題のコピー」を持つので、
// 問題バンクを編集しても過去の教材は変わらない（最新版に更新するかは選べる）

/**
 * @typedef {{ id:string, type:'heading', text:string, level?:number }
 *  | { id:string, type:'text', text:string }
 *  | { id:string, type:'section', title:string, inst?:string }
 *  | { id:string, type:'question', ref:string, rev:number, q:any, pts?:number|null, perm?:number[]|null }
 *  | { id:string, type:'pagebreak' }
 *  | { id:string, type:'table', header:string[], rows:string[][], caption?:string }
 *  | { id:string, type:'image', src:string, alt?:string, width?:number }
 *  | { id:string, type:'space', lines:number, label?:string }} Block
 */

export const KINDS = {
  worksheet: { label: '授業プリント', title: '授業プリント', notes: '' },
  summary: { label: '要点まとめ', title: '要点まとめ', notes: '' },
  self: { label: '自習教材', title: '自習プリント', notes: '' },
  review: { label: '復習プリント', title: '復習プリント', notes: '' },
  drill: { label: '演習問題集', title: '演習問題', notes: '' },
  memorize: { label: '暗記教材', title: '暗記プリント', notes: '' },
  wordtest: { label: '単語テスト', title: '単語テスト', notes: '' },
  quiz: { label: '小テスト', title: '小テスト', notes: '' },
  unit: { label: '単元テスト', title: '単元テスト', notes: '' },
  test: { label: '定期テスト', title: '定期テスト', notes: '答えはすべて解答用紙に書きなさい。' },
  ability: { label: '実力テスト', title: '実力テスト', notes: '' },
  mock: { label: '模擬試験', title: '模擬試験', notes: '解答はすべて解答用紙に記入しなさい。' },
  entrance: { label: '入試対策', title: '入試対策演習', notes: '' },
  answers: { label: '解答・解説集', title: '解答・解説集', notes: '' },
  kanagawa: { label: '神奈川県公立高校入試形式', title: '神奈川県公立高校入試 模擬問題', notes: '' },
  kyotsu: { label: '共通テスト形式', title: '共通テスト 模擬問題', notes: '' },
  niji: { label: '二次試験形式（記述）', title: '二次試験 模擬問題', notes: '' },
  material: { label: '授業用資料', title: '授業資料', notes: '' },
};

export const PAGE_SIZES = { A4: [210, 297], B4: [257, 364], A3: [297, 420], B5: [182, 257] };

export const DEFAULT_PAGE = { size: 'A4', orientation: 'portrait', margin: 12, header: '', footer: '', pageNumbers: true, cols: '1', font: '13.5' };
export const DEFAULT_PRINT = {
  labels: 'auto', answer: 'inline', key: 'expl', points: 'data', group: 'none', format: 'standard',
  shuffle: false, name: true, date: false, meta: false, seed: 1,
};

/** テンプレートごとの初期設定 */
const TEMPLATE_PRESETS = {
  test: { print: { answer: 'sheet', key: 'expl', points: 'equal', group: 'type' } },
  mock: { print: { answer: 'sheet', key: 'expl', points: 'equal', group: 'type' }, page: { cols: '1' } },
  quiz: { print: { answer: 'inline', key: 'ans', points: 'equal' } },
  unit: { print: { answer: 'sheet', key: 'expl', points: 'equal', group: 'type' } },
  ability: { print: { answer: 'sheet', key: 'expl', points: 'equal', group: 'unit' } },
  wordtest: { print: { answer: 'inline', key: 'ans', points: 'none' }, page: { cols: '1' } },
  summary: { print: { answer: 'none', key: 'none', points: 'none' }, blocks: [['heading', '今日のポイント'], ['text', ''], ['heading', '確認問題']] },
  worksheet: { print: { answer: 'inline', key: 'ans' }, blocks: [['heading', 'ねらい'], ['text', ''], ['heading', '練習問題']] },
  memorize: { print: { answer: 'inline', key: 'ans', points: 'none' } },
  answers: { print: { answer: 'none', key: 'expl', points: 'data' } },
  kanagawa: { print: { format: 'kanagawa', answer: 'sheet', key: 'expl', points: 'equal', group: 'type' } },
  kyotsu: { print: { format: 'kyotsu', answer: 'sheet', key: 'expl', points: 'equal', group: 'unit' } },
  niji: { print: { format: 'niji', answer: 'sheet', key: 'expl', points: 'equal', group: 'unit' } },
};

let seq = 0;
export function blockId() {
  seq = (seq + 1) % 1e6;
  return 'b' + Date.now().toString(36) + seq.toString(36) + Math.random().toString(36).slice(2, 6);
}

/** @param {string} kind @param {{id:string, now:string}} ids */
export function newMaterial(kind = 'worksheet', { id, now }) {
  const k = KINDS[kind] || KINDS.worksheet;
  const preset = TEMPLATE_PRESETS[kind] || {};
  /** @type {Block[]} */
  const blocks = (preset.blocks || []).map(([type, text]) => (type === 'heading'
    ? { id: blockId(), type: 'heading', text, level: 2 }
    : { id: blockId(), type: 'text', text }));
  return {
    id, kind, title: k.title, subtitle: '', notes: k.notes, tags: [], folder: '',
    createdAt: now, updatedAt: now, rev: 1, status: 'draft',
    page: { ...DEFAULT_PAGE, ...(preset.page || {}) },
    print: { ...DEFAULT_PRINT, ...(preset.print || {}) },
    blocks,
  };
}

/** 問題をブロックにする（使った時点のコピーを持つ） */
export function questionBlock(q) {
  /** @type {Block} */
  const b = { id: blockId(), type: 'question', ref: q.id, rev: q.rev || 1, q: JSON.parse(JSON.stringify(q)), pts: null, perm: null };
  return b;
}

export const questionBlocks = (m) => m.blocks.filter(b => b.type === 'question');

/** 問題バンクの最新版と比べて、古くなっている問題ブロック */
export function outdatedBlocks(m, byId) {
  return questionBlocks(m).filter(b => {
    const cur = byId.get(b.ref);
    return cur && (cur.rev || 1) > (b.rev || 1);
  });
}

/** 古い版のプリント保存（カート＋設定）を教材に変換する */
export function fromLegacy({ name, cart, settings, at }, resolve, { id, now }) {
  const s = settings || {};
  const m = newMaterial('worksheet', { id, now });
  m.title = s.title || name || 'プリント';
  m.subtitle = s.subtitle || '';
  m.notes = s.notes || '';
  m.createdAt = m.updatedAt = at ? new Date(at).toISOString() : now;
  m.page = { ...DEFAULT_PAGE, cols: s.cols || '1', font: s.font || '13.5' };
  m.print = {
    ...DEFAULT_PRINT,
    labels: s.labels || 'auto', answer: s.answer || 'inline', key: s.key || 'expl', points: s.points || 'data',
    group: s.group || 'none', shuffle: !!s.shuffle, name: s.name !== false, date: !!s.date, meta: !!s.meta, seed: s.seed || 1,
  };
  m.blocks = [];
  for (const c of cart || []) {
    const q = c.q || resolve(c.ref);
    if (q) m.blocks.push(questionBlock(q));
  }
  return m;
}
