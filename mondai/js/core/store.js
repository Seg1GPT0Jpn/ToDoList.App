// アプリ全体のデータ（問題・教材・単語帳など）を持ち、保存と変更通知を受け持つ
import * as db from './db.js';
import { emit, uid, nowISO, clone } from './util.js';
import { bumpRevision, normalizeQuestion } from '../domain/question.js';
import { applyUnitNames } from '../data/units.js';

export const state = {
  /** @type {any[]} 取り込みデータ（＋内蔵） */
  datasets: [],
  /** @type {Map<string, any>} 元データ（内蔵・取り込み）の問題 */
  base: new Map(),
  /** @type {Map<string, any>} ユーザー版（自作・編集・AI・削除印） */
  user: new Map(),
  /** @type {any[]} 表示する問題（元データをユーザー版で上書きしたもの。削除印は除く） */
  questions: [],
  /** @type {Map<string, any>} */
  byId: new Map(),
  stims: {},
  /** @type {any[]} 単語帳・用語カード */
  lists: [],
  /** @type {any[]} 教材（新しい順） */
  materials: [],
  builtinLoaded: false,
};

// ---------- 読み込み ----------
async function loadBuiltin() {
  try {
    const res = await fetch('builtin/hs.json');
    if (!res.ok) return null;
    const d = await res.json();
    d.questions.forEach(q => { q.origin = 'builtin'; });
    return { id: 'builtin', name: '内蔵問題（高校5教科・オリジナル）', builtin: true, questions: d.questions, stims: {}, importedAt: null };
  } catch (e) {
    return null;
  }
}

export async function loadAll() {
  const [builtin, datasets, userQs, materials] = await Promise.all([
    loadBuiltin(), db.all('datasets'), db.all('questions'), db.all('materials'),
  ]);
  state.builtinLoaded = !!builtin;
  state.datasets = builtin ? [builtin, ...datasets] : datasets;
  state.user = new Map(userQs.map(q => [q.id, q]));
  state.materials = materials.sort((a, b) => (b.updatedAt || '').localeCompare(a.updatedAt || ''));
  rebuild();
}

/** 元データとユーザー版から、表示する問題の一覧を作り直す */
export function rebuild() {
  state.base = new Map();
  state.stims = {};
  state.lists = [];
  for (const ds of state.datasets) {
    for (const q of ds.questions || []) {
      if (!q.origin) q.origin = ds.builtin ? 'builtin' : 'imported';
      applyUnitNames(q);
      state.base.set(q.id, q);
    }
    Object.assign(state.stims, ds.stims || {});
    state.lists.push(...(ds.lists || []));
  }
  const out = [];
  const byId = new Map();
  for (const [id, q] of state.base) {
    const u = state.user.get(id);
    if (u && u.deleted) continue;
    const v = u || q;
    out.push(v);
    byId.set(id, v);
  }
  for (const [id, u] of state.user) {
    if (state.base.has(id) || u.deleted) continue;
    out.push(u);
    byId.set(id, u);
  }
  state.questions = out;
  state.byId = byId;
  emit('questions');
}

// ---------- 操作履歴 ----------
export async function log(action, target = '', detail = '') {
  try {
    await db.put('history', { id: uid('H-'), at: nowISO(), action, target, detail: String(detail).slice(0, 500) });
  } catch (e) { /* 履歴が残せなくても本体の操作は続ける */ }
}

// ---------- 問題 ----------
/** 問題を保存する。既存の問題なら旧版を versions に残して版番号を上げる */
export async function saveQuestion(q, note = '') {
  const prev = state.byId.get(q.id);
  let next = normalizeQuestion(clone(q));
  if (prev) {
    const r = bumpRevision(prev, next);
    next = r.next;
    await db.put('versions', { ...r.version, note });
  }
  await db.put('questions', next);
  state.user.set(next.id, next);
  rebuild();
  await log(prev ? '問題を編集' : '問題を作成', next.id, note || (next.stem || '').slice(0, 40));
  return next;
}

/** 複数の問題を一度に保存（一括編集・一括登録） */
export async function saveQuestions(list, note = '') {
  const versions = [], nexts = [];
  for (const q of list) {
    const prev = state.byId.get(q.id);
    let next = normalizeQuestion(clone(q));
    if (prev) {
      const r = bumpRevision(prev, next);
      next = r.next;
      versions.push({ ...r.version, note });
    }
    nexts.push(next);
  }
  if (versions.length) await db.putMany('versions', versions);
  await db.putMany('questions', nexts);
  nexts.forEach(n => state.user.set(n.id, n));
  rebuild();
  await log('問題を一括保存', `${nexts.length}問`, note);
  return nexts;
}

/** 削除。自作の問題は消し、内蔵・取り込みの問題は「削除印」をつけて非表示にする（元データは残る） */
export async function deleteQuestions(ids) {
  const putList = [], delList = [];
  for (const id of ids) {
    if (state.base.has(id)) putList.push({ id, deleted: true, updatedAt: nowISO() });
    else delList.push(id);
  }
  if (putList.length) await db.putMany('questions', putList);
  if (delList.length) await db.delMany('questions', delList);
  putList.forEach(t => state.user.set(t.id, t));
  delList.forEach(id => state.user.delete(id));
  rebuild();
  await log('問題を削除', `${ids.length}問`);
}

/** 非表示にした元データの問題を元に戻す */
export async function restoreHidden() {
  const ids = [...state.user.values()].filter(u => u.deleted).map(u => u.id);
  await db.delMany('questions', ids);
  ids.forEach(id => state.user.delete(id));
  rebuild();
  await log('削除した元データの問題を戻す', `${ids.length}問`);
  return ids.length;
}

/** 編集した元データの問題を元の内容に戻す */
export async function revertToOriginal(id) {
  if (!state.base.has(id)) return false;
  await db.del('questions', id);
  state.user.delete(id);
  rebuild();
  await log('問題を元に戻す', id);
  return true;
}

export const questionVersions = (id) => db.byIndex('versions', 'id', id).then(v => v.sort((a, b) => b.rev - a.rev));

// ---------- 取り込みデータ ----------
export async function importDatasets(result) {
  for (const ds of result) {
    const old = state.datasets.find(d => d.id === ds.id);
    if (old && ds.questions) {
      const m = new Map(old.questions.map(q => [q.id, q]));
      ds.questions.forEach(q => m.set(q.id, q));
      ds.questions = Array.from(m.values());
      ds.stims = Object.assign({}, old.stims, ds.stims);
    }
    if (old && ds.lists) {
      const m = new Map(old.lists.map(l => [l.id, l]));
      ds.lists.forEach(l => m.set(l.id, l));
      ds.lists = Array.from(m.values());
    }
    await db.put('datasets', ds);
    state.datasets = state.datasets.filter(d => d.id !== ds.id).concat(ds);
  }
  rebuild();
  await log('データを取り込み', result.map(d => d.name).join('、'));
}

export async function removeDataset(id) {
  await db.del('datasets', id);
  state.datasets = state.datasets.filter(d => d.id !== id);
  rebuild();
  await log('取り込みデータを削除', id);
}

// ---------- 教材 ----------
export const getMaterial = (id) => state.materials.find(m => m.id === id) || null;

/** 教材を保存。snapshot=true なら旧版を残す（手動保存・状態変更時） */
export async function saveMaterial(m, { snapshot = false, note = '' } = {}) {
  const prev = getMaterial(m.id);
  const next = clone(m);
  next.updatedAt = nowISO();
  if (!next.createdAt) next.createdAt = next.updatedAt;
  if (!next.rev) next.rev = 1;
  if (snapshot && prev) {
    await db.put('materialVersions', { id: prev.id, rev: prev.rev, data: clone(prev), savedAt: nowISO(), note });
    next.rev = prev.rev + 1;
  }
  await db.put('materials', next);
  state.materials = [next, ...state.materials.filter(x => x.id !== next.id)];
  emit('materials');
  if (!prev) await log('教材を作成', next.id, next.title);
  else if (snapshot) await log('教材を保存', next.id, note || next.title);
  return next;
}

export async function deleteMaterial(id) {
  await db.del('materials', id);
  state.materials = state.materials.filter(m => m.id !== id);
  emit('materials');
  await log('教材を削除', id);
}

export const materialVersions = (id) => db.byIndex('materialVersions', 'id', id).then(v => v.sort((a, b) => b.rev - a.rev));

// ---------- 現在作業中の教材 ----------
export async function currentMaterialId() { return db.kvGet('currentMaterial', null); }
export async function setCurrentMaterial(id) { await db.kvSet('currentMaterial', id); emit('current'); }
