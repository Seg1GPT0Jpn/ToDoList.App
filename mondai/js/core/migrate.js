// 旧版（localStorage のカート・保存プリント）から新しい保存形式への移行。1回だけ行い、元のデータは消さない
import * as db from './db.js';
import { state, saveMaterial, setCurrentMaterial, log } from './store.js';
import { fromLegacy } from '../domain/material.js';
import { uid, nowISO } from './util.js';

function lsGet(key) {
  try { const v = localStorage.getItem(key); return v ? JSON.parse(v) : null; } catch (e) { return null; }
}

export async function migrateLegacy() {
  if (await db.kvGet('migrated.v2', false)) return 0;
  const resolve = (id) => state.byId.get(id);
  let n = 0;
  const saved = lsGet('mondai.saved') || [];
  for (const s of saved) {
    await saveMaterial(fromLegacy({ name: s.name, cart: s.cart, settings: s.settings, at: s.at }, resolve, { id: uid('M-'), now: nowISO() }));
    n++;
  }
  const cart = lsGet('mondai.cart') || [];
  if (cart.length) {
    const m = await saveMaterial(fromLegacy({ name: '作業中のプリント', cart, settings: lsGet('mondai.settings'), at: Date.now() }, resolve, { id: uid('M-'), now: nowISO() }));
    await setCurrentMaterial(m.id);
    n++;
  }
  await db.kvSet('migrated.v2', true);
  if (n) await log('旧版のプリントを移行', `${n}件`);
  return n;
}
