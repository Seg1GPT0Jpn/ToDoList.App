// 画面どうしで共有する部品
import { state, saveMaterial, getMaterial, currentMaterialId, setCurrentMaterial } from '../core/store.js';
import { esc, uid, nowISO, toast, emit } from '../core/util.js';
import { newMaterial, questionBlock, KINDS } from '../domain/material.js';
import { STATUSES } from '../domain/question.js';

export const R = () => /** @type {any} */ (globalThis).Render;

export const TYPE_LABEL = { choice: '選択', multi: '複数選択', order: '並べかえ', tf: '正誤', short: '答えのみ', written: '記述', steps: '小問つき' };
export const ORIGIN_LABEL = { builtin: '内蔵', imported: '取り込み', user: '自作', ai: 'AI生成' };

/**
 * 印刷・PDF のファイル名（＝ページのタイトル）：【試験名】【問題／問題+解答／問題+解答・解説】
 * @param {any} m 教材 @param {string[]} [parts] 印刷する部分（'questions' 'sheet' 'key'）。省略時は教材の設定どおり
 */
export function printFileName(m, parts) {
  const p = parts || ['questions', ...(m.print.answer === 'sheet' ? ['sheet'] : []), ...(m.print.key !== 'none' ? ['key'] : [])];
  const keyKind = m.print.key === 'ans' ? '解答' : '解答・解説';
  let kind;
  if (p.includes('questions')) kind = p.includes('key') ? `問題+${keyKind}` : '問題';
  else if (p.includes('key')) kind = keyKind;
  else kind = '解答用紙';
  // ファイル名に使えない文字は全角にする
  const safe = String(m.title || '無題').replace(/[\\/:*?"<>|]/g, (c) => String.fromCharCode(c.charCodeAt(0) + 0xFEE0)).trim();
  return `【${safe}】【${kind}】`;
}

/** タイトルをファイル名にして印刷し、終わったら元に戻す */
export function printAs(name) {
  const old = document.title;
  document.title = name;
  const restore = () => { document.title = old; window.removeEventListener('afterprint', restore); };
  window.addEventListener('afterprint', restore);
  window.print();
}

/** 見本の紙を、表示している枠の幅に合わせて縮める（印刷には影響しない） */
export function fitPreview(preview) {
  const wrap = preview && preview.parentElement;
  const paper = preview && preview.querySelector('.paper');
  if (!wrap || !paper) return;
  /** @type {any} */ (preview.style).zoom = '';
  const avail = wrap.clientWidth - 24;
  const w = paper.offsetWidth;
  if (w > avail && avail > 100) /** @type {any} */ (preview.style).zoom = String(Math.max(0.35, avail / w));
}

/** 数式を表示する */
export function renderMath(el) { if (R()) R().math(el); }

/** 問題の分類タグ（一覧用） */
export function questionTags(q) {
  const t = [q.src, q.stage, q.course || q.subj, q.grade, TYPE_LABEL[q.type], q.level].filter(Boolean).map(x => `<span class="tag">${esc(x)}</span>`);
  if (q.origin === 'ai' || (q.status && q.status !== 'unverified')) {
    const cls = { approved: 'ok', verified: 'accent', needs_fix: 'danger', verifying: 'warn', unverified: '' }[q.status] || '';
    t.push(`<span class="chip ${cls}">${esc(STATUSES[q.status] || q.status || '未検証')}</span>`);
  }
  if (state.base.has(q.id) && state.user.has(q.id)) t.push('<span class="chip warn">編集済み</span>');
  if (q.vary) t.push('<span class="chip ok" title="数値だけを変えた版を作れます">数値替え可</span>');
  (q.tags || []).forEach(x => t.push(`<span class="chip accent">#${esc(x)}</span>`));
  return t.join('');
}

/** 問題の中身（選択肢・答え・解説）を見せる HTML */
export function questionDetail(q, { answer = true } = {}) {
  const Rr = R();
  const v = Rr.prepare([q], { labels: 'auto', shuffle: false, points: 'none' })[0];
  let h = '';
  if (q.sid && state.stims[q.sid]) h += `<div class="small muted">［共通の本文：${esc(state.stims[q.sid].title || 'あり')}］</div>`;
  if (q.sentence) h += `<div class="pq-sentence">${Rr.text(q.sentence)}</div>`;
  h += Rr.table(q.table) + Rr.figure(q.fig);
  if (q.choices && q.choices.length) h += Rr.choicesHtml(q.choices, v.perm, v.labels);
  if (v.subs) h += v.subs.map(x => `<div>${Rr.text(x.sq.stem)}</div>` + Rr.choicesHtml(x.sq.choices, x.perm, x.labels)).join('');
  if (answer) {
    h += `<div class="answer">答え：${Rr.text(v.ans)}</div>`;
    if (q.expl) h += `<div class="expl">${Rr.text(q.expl)}</div>`;
  }
  return h;
}

export const texClass = (q) => (R() && R().isTex(q) ? 'tex' : '');

// ---------- モーダル ----------
/**
 * @param {{title:string, body:string, foot?:string, narrow?:boolean, onClose?:()=>void}} o
 */
export function modal(o) {
  const back = document.createElement('div');
  back.className = 'modal-back';
  back.innerHTML = `<div class="modal${o.narrow ? ' narrow' : ''}" role="dialog" aria-modal="true" aria-label="${esc(o.title)}">
    <div class="modal-head"><h2>${esc(o.title)}</h2><button class="btn ghost sm" data-close aria-label="閉じる">✕</button></div>
    <div class="modal-body">${o.body}</div>${o.foot ? `<div class="modal-foot">${o.foot}</div>` : ''}</div>`;
  document.body.appendChild(back);
  const close = () => {
    back.remove();
    document.removeEventListener('keydown', onKey);
    if (o.onClose) o.onClose();
  };
  const onKey = (e) => { if (e.key === 'Escape') close(); };
  document.addEventListener('keydown', onKey);
  back.addEventListener('click', e => { if (e.target === back || /** @type {HTMLElement} */ (e.target).closest('[data-close]')) close(); });
  const first = back.querySelector('input, select, textarea, button:not([data-close])');
  if (first) /** @type {HTMLElement} */ (first).focus();
  return { el: /** @type {HTMLElement} */ (back.querySelector('.modal')), close };
}

// ---------- 作業中の教材 ----------
export async function currentMaterial() {
  const id = await currentMaterialId();
  return id ? getMaterial(id) : null;
}

/** 作業中の教材がなければ作る */
export async function ensureCurrentMaterial(kind = 'worksheet') {
  let m = await currentMaterial();
  if (!m) {
    m = await saveMaterial(newMaterial(kind, { id: uid('M-'), now: nowISO() }));
    await setCurrentMaterial(m.id);
  }
  return m;
}

/** 問題を作業中の教材に追加。すでに入っている問題は飛ばす */
export async function addToCurrentMaterial(questions) {
  const m = await ensureCurrentMaterial();
  const have = new Set(m.blocks.filter(b => b.type === 'question').map(b => b.ref));
  let n = 0;
  for (const q of questions) {
    if (have.has(q.id)) continue;
    m.blocks.push(questionBlock(q));
    have.add(q.id);
    n++;
  }
  await saveMaterial(m);
  emit('current');
  return { added: n, material: m };
}

export async function removeFromCurrentMaterial(id) {
  const m = await currentMaterial();
  if (!m) return;
  m.blocks = m.blocks.filter(b => !(b.type === 'question' && b.ref === id));
  await saveMaterial(m);
  emit('current');
}

export async function currentRefs() {
  const m = await currentMaterial();
  return new Set(m ? m.blocks.filter(b => b.type === 'question').map(b => b.ref) : []);
}

export const kindLabel = (k) => (KINDS[k] ? KINDS[k].label : k);

export function notify(msg, kind = '') { toast(msg, kind); }

/** 単語帳・用語カードのテスト問題を作る（旧「単語・用語テスト」） */
export function makeWordQuestions(list, { from, to, count, mode, order }) {
  const shuffle = (a) => { for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };
  const blankOut = (w) => {
    if (!w.ex) return null;
    let s = w.ex, ok = false;
    const words = (w.blanks && w.blanks.length) ? w.blanks : [w.term.replace(/[～~].*$/, '').replace(/\s*\(.*?\)\s*/g, ' ').trim()];
    for (const b of words) {
      if (!b) continue;
      const re = new RegExp('\\b' + b.replace(/[.*+?^${}()|[\]\\]/g, '\\$&').replace(/\s+/g, '\\s+') + '\\w*', 'i');
      if (re.test(s)) { s = s.replace(re, m => '（' + '　'.repeat(Math.min(6, Math.max(3, Math.ceil(m.length / 2)))) + '）'); ok = true; }
    }
    return ok ? { stem: (w.exJa ? w.exJa + '\n' : '') + s, ans: words.join(' … ') } : null;
  };
  let pool = list.items.filter(w => w.n >= from && w.n <= to);
  if (mode === 'cloze') pool = pool.filter(w => blankOut(w));
  let picked = order === 'random' ? shuffle(pool.slice()).slice(0, count) : pool.slice(0, count);
  if (order === 'random') picked.sort((a, b) => a.n - b.n);
  const isTerm = list.group === '用語カード';
  return picked.map(w => {
    const base = { id: `w:${list.id}:${w.n}:${mode}`, src: '単語帳', subj: isTerm ? '' : '英語', unit: list.title, set: list.title, level: '', origin: 'user', expl: w.ex ? w.ex + (w.exJa ? '（' + w.exJa + '）' : '') : (w.sec || '') };
    const others = shuffle(list.items.filter(x => x !== w && x.meaning !== w.meaning)).slice(0, 3);
    if (mode === 'meaning') return { ...base, type: 'short', compact: true, stem: w.term, ans: w.meaning };
    if (mode === 'term') return { ...base, type: 'short', compact: !isTerm, stem: w.meaning, ans: w.term };
    if (mode === 'cloze') { const b = blankOut(w); return { ...base, type: 'short', stem: '（　）に入る語句を書きなさい。\n' + b.stem, ans: b.ans }; }
    const opts = shuffle([w, ...others]);
    const rev = mode === 'mcr';
    return { ...base, type: 'choice', stem: rev ? w.meaning : w.term, choices: opts.map(o => rev ? o.term : o.meaning), ai: [opts.indexOf(w)] };
  });
}
