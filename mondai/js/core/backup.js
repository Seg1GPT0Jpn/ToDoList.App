// バックアップ（書き出し）と復元
import * as db from './db.js';
import { nowISO } from './util.js';

const USER_STORES = ['questions', 'versions', 'materials', 'materialVersions', 'history', 'aiJobs', 'results', 'ratings', 'kv'];
export const FORMAT = 'mondai-backup';

/** @param {{includeDatasets?: boolean}} opts */
export async function makeBackup({ includeDatasets = false } = {}) {
  const out = { format: FORMAT, version: 2, createdAt: nowISO(), stores: {} };
  const names = includeDatasets ? [...USER_STORES, 'datasets'] : USER_STORES;
  for (const name of names) out.stores[name] = await db.all(name);
  return out;
}

/** バックアップの中身を確かめる。問題があれば日本語のメッセージを返す */
export function validateBackup(data) {
  if (!data || data.format !== FORMAT) return 'このファイルはプリント作成アプリのバックアップではありません。';
  if (!data.stores || typeof data.stores !== 'object') return 'バックアップの中身が読み取れません。';
  for (const [name, rows] of Object.entries(data.stores)) {
    if (!db.STORES.includes(name)) return `知らないデータ（${name}）が含まれています。`;
    if (!Array.isArray(rows)) return `データ（${name}）の形が正しくありません。`;
  }
  return '';
}

export function summarize(data) {
  const s = data.stores || {};
  const n = (k) => (s[k] || []).length;
  return { questions: n('questions'), materials: n('materials'), results: n('results'), datasets: n('datasets'), history: n('history') };
}

/**
 * 復元。mode='merge' は今のデータに足す（同じ ID は上書き）、'replace' は対象データを一度消してから入れる
 * @param {any} data @param {'merge'|'replace'} mode
 */
export async function restoreBackup(data, mode = 'merge') {
  const err = validateBackup(data);
  if (err) throw new Error(err);
  for (const [name, rows] of Object.entries(data.stores)) {
    if (mode === 'replace') await db.clear(name);
    if (rows.length) await db.putMany(name, rows);
  }
}
