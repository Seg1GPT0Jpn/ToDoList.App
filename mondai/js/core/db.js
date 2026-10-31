// IndexedDB（このブラウザの中だけの保存場所）
// v1: datasets（取り込みデータ）
// v2: questions（自作・編集した問題）, versions（問題の旧版）, materials（教材）, materialVersions,
//     history（操作履歴）, aiJobs（AI 実行履歴）, results（学習結果）, ratings（問題評価）, kv（設定など）

const NAME = 'mondai-db';
const VERSION = 2;
export const STORES = ['datasets', 'questions', 'versions', 'materials', 'materialVersions', 'history', 'aiJobs', 'results', 'ratings', 'kv'];

/** @type {Promise<IDBDatabase>|null} */
let dbp = null;

export function open() {
  if (dbp) return dbp;
  dbp = new Promise((resolve, reject) => {
    const req = indexedDB.open(NAME, VERSION);
    req.onupgradeneeded = () => {
      const db = req.result;
      const make = (name, opts, indexes = []) => {
        if (db.objectStoreNames.contains(name)) return;
        const s = db.createObjectStore(name, opts);
        for (const [ix, key] of indexes) s.createIndex(ix, key);
      };
      make('datasets', { keyPath: 'id' });
      make('questions', { keyPath: 'id' }, [['updatedAt', 'updatedAt']]);
      make('versions', { keyPath: ['id', 'rev'] }, [['id', 'id']]);
      make('materials', { keyPath: 'id' }, [['updatedAt', 'updatedAt']]);
      make('materialVersions', { keyPath: ['id', 'rev'] }, [['id', 'id']]);
      make('history', { keyPath: 'id' }, [['at', 'at']]);
      make('aiJobs', { keyPath: 'id' }, [['at', 'at']]);
      make('results', { keyPath: 'id' }, [['materialId', 'materialId'], ['questionId', 'questionId']]);
      make('ratings', { keyPath: 'questionId' });
      make('kv', { keyPath: 'key' });
    };
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
    req.onblocked = () => reject(new Error('データベースが別のタブで使われています。ほかのタブを閉じてから開き直してください。'));
  });
  return dbp;
}

function reqP(req) {
  return new Promise((resolve, reject) => {
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
}

/** @param {string} store @param {'readonly'|'readwrite'} mode @param {(s: IDBObjectStore) => any} fn */
async function run(store, mode, fn) {
  const db = await open();
  return new Promise((resolve, reject) => {
    const t = db.transaction(store, mode);
    let out;
    Promise.resolve(fn(t.objectStore(store))).then(r => { out = r; }, reject);
    t.oncomplete = () => resolve(out);
    t.onerror = () => reject(t.error);
    t.onabort = () => reject(t.error || new Error('保存が中断されました'));
  });
}

export const get = (store, key) => run(store, 'readonly', s => reqP(s.get(key)));
export const all = (store) => run(store, 'readonly', s => reqP(s.getAll()));
export const put = (store, value) => run(store, 'readwrite', s => { s.put(value); });
export const del = (store, key) => run(store, 'readwrite', s => { s.delete(key); });
export const clear = (store) => run(store, 'readwrite', s => { s.clear(); });
export const count = (store) => run(store, 'readonly', s => reqP(s.count()));

/** 複数件をまとめて保存 */
export const putMany = (store, values) => run(store, 'readwrite', s => { for (const v of values) s.put(v); });
export const delMany = (store, keys) => run(store, 'readwrite', s => { for (const k of keys) s.delete(k); });

/** インデックスで検索 */
export const byIndex = (store, index, key) => run(store, 'readonly', s => reqP(s.index(index).getAll(key)));

export async function kvGet(key, def = null) {
  const r = await get('kv', key);
  return r ? r.value : def;
}
export const kvSet = (key, value) => put('kv', { key, value });
