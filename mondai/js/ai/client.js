// AI の呼び出し（Supabase Edge Function 経由）と、AI が作った問題の品質検証
import * as db from '../core/db.js';
import { uid, nowISO } from '../core/util.js';
import { validateQuestion } from '../domain/question.js';
import { checkAnswer, parseAnswerNumber, nearlyEqual } from '../domain/mathcheck.js';
import { findSimilar } from '../domain/similarity.js';

async function cloud() {
  try { return await import('../cloud/supabase.js'); } catch (e) { return null; }
}

/** AI が使えるか。使えないときは理由を返す */
export async function availability() {
  const c = await cloud();
  if (!c) return { ok: false, reason: 'クラウド接続の部品を読み込めませんでした。' };
  if (!c.isConfigured()) return { ok: false, reason: 'クラウド（Supabase）に接続していません。「設定・データ」で接続を設定してください。' };
  let user = null;
  try { user = await c.currentUser(); } catch (e) { /* 未ログイン */ }
  if (!user) return { ok: false, reason: 'ログインしていません。「チーム」画面でログインしてください。' };
  return { ok: true, reason: '' };
}

/**
 * AI に作業を頼む。結果は端末の AI 利用履歴にも記録する
 * @param {string} action @param {any} payload @param {string} label 履歴に出す説明
 * @returns {Promise<{ok:boolean, data?:any, error?:{code:string, message:string}}>}
 */
export async function callAI(action, payload, label = action, wsId = null) {
  const c = await cloud();
  /** @type {any} */
  const res = c ? await c.callAI(/** @type {any} */ (action), payload, wsId) : { ok: false, error: { code: 'not_configured', message: 'クラウド接続がありません' } };
  try {
    await db.put('aiJobs', {
      id: uid('J-'), at: nowISO(), action, label: label.slice(0, 80),
      status: res.ok ? 'ok' : (res.error && res.error.code) || 'error',
      tokens: res.ok && res.job ? res.job.tokens || 0 : 0, model: res.ok && res.job ? res.job.model : null,
      error: res.ok ? null : res.error && res.error.message,
    });
  } catch (e) { /* 履歴が書けなくても結果は返す */ }
  return res;
}

const normText = (s) => String(s || '').normalize('NFKC').replace(/[\s　。、．，,.$\\{}]/g, '').toLowerCase();

/** 独立に解いた答えと正答を比べる */
export function compareSolution(q, sol) {
  if (!sol) return { ok: false, note: '独立解答が得られませんでした' };
  if (['choice', 'multi', 'order'].includes(q.type)) {
    const a = (sol.ai || []).map(Number);
    const exp = q.ai || [];
    const same = q.type === 'multi' ? a.length === exp.length && a.every(x => exp.includes(x)) : a.length === exp.length && a.every((x, i) => x === exp[i]);
    return same ? { ok: true, note: '独立解答と正答が一致' } : { ok: false, note: `独立解答（${a.map(i => i + 1).join(',') || '不明'}）が正答（${exp.map(i => i + 1).join(',')}）と一致しません` };
  }
  const x = parseAnswerNumber(sol.answer), y = parseAnswerNumber(q.ans);
  if (x != null && y != null) return nearlyEqual(x, y) ? { ok: true, note: '独立解答と正答の数値が一致' } : { ok: false, note: `独立解答の数値（${x}）が正答（${y}）と一致しません` };
  const s = normText(sol.answer), t = normText(q.ans);
  if (s && t && (s === t || s.includes(t) || t.includes(s))) return { ok: true, note: '独立解答と正答が一致' };
  if (q.type === 'written') return { ok: true, note: '記述問題のため、独立解答は参考（人が確認してください）', soft: true };
  return { ok: false, note: `独立解答「${String(sol.answer).slice(0, 40)}」と正答が一致しません（表記ゆれの可能性あり。要確認）` };
}

/**
 * AI が作った問題を検証する（AI の自己評価だけで正しいとはしない）
 * @param {any} q @param {any[]} bank 重複確認に使う問題 @param {(msg:string)=>void} [progress]
 * @returns {Promise<{status:'verified'|'needs_fix', notes:string[], fixed:any|null}>}
 */
export async function verifyQuestion(q, bank, progress = () => {}) {
  const notes = [];
  let bad = false;
  let fixed = null;
  // 1. 形式
  const v = validateQuestion(q);
  if (!v.ok) { notes.push('形式：' + v.errors.map(e => e.message).join('、')); bad = true; }
  // 2. 機械検算
  if (q.check) {
    const r = checkAnswer(q);
    if (r.status === 'pass') notes.push('検算：式の値と正答が一致');
    else if (r.status === 'fail') { notes.push('検算：' + (r.message || '式の値と正答が一致しません')); bad = true; }
  }
  // 3. 独立解答（正答は伏せて送る）
  progress('独立に解き直しています…');
  const sol = await callAI('solve', { question: q }, '独立解答：' + (q.stem || '').slice(0, 30));
  if (sol.ok) {
    const c = compareSolution(q, sol.data);
    notes.push(c.note);
    if (!c.ok) bad = true;
  } else { notes.push('独立解答：実行できませんでした（' + (sol.error ? sol.error.message : '') + '）'); bad = true; }
  // 4. 校閲
  progress('校閲しています…');
  const rev = await callAI('review', { question: q }, '校閲：' + (q.stem || '').slice(0, 30));
  if (rev.ok) {
    const issues = rev.data.issues || [];
    const high = issues.filter(i => i.severity === 'high');
    issues.forEach(i => notes.push(`校閲（${i.severity === 'high' ? '重大' : i.severity === 'medium' ? '中' : '軽'}）：${i.message}`));
    if (!issues.length) notes.push('校閲：指摘なし');
    if (high.length) bad = true;
    if (rev.data.fixed) fixed = rev.data.fixed;
  } else { notes.push('校閲：実行できませんでした（' + (rev.error ? rev.error.message : '') + '）'); bad = true; }
  // 5. 重複
  const sim = findSimilar(q, bank, { limit: 3, minScore: 0.6 });
  sim.forEach(s => notes.push(`重複の可能性：${s.kind === 'exact' ? '完全一致' : s.kind === 'numeric_variant' ? '数値だけ違う' : '似ている'}「${(s.q.stem || '').slice(0, 30)}…」`));
  if (sim.some(s => s.kind === 'exact')) bad = true;
  return { status: bad ? 'needs_fix' : 'verified', notes, fixed };
}
