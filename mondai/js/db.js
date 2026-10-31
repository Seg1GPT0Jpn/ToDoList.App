// IndexedDB に取り込んだ問題データを保存する（データはこのブラウザの中だけに残る）
const DB = (() => {
  const NAME = 'mondai-db';
  const VERSION = 1;
  let dbp = null;

  function open() {
    if (dbp) return dbp;
    dbp = new Promise((resolve, reject) => {
      const req = indexedDB.open(NAME, VERSION);
      req.onupgradeneeded = () => {
        const db = req.result;
        if (!db.objectStoreNames.contains('datasets')) db.createObjectStore('datasets', { keyPath: 'id' });
      };
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
    return dbp;
  }

  function tx(mode, fn) {
    return open().then(db => new Promise((resolve, reject) => {
      const t = db.transaction('datasets', mode);
      const store = t.objectStore('datasets');
      let result;
      Promise.resolve(fn(store)).then(r => { result = r; });
      t.oncomplete = () => resolve(result);
      t.onerror = () => reject(t.error);
      t.onabort = () => reject(t.error);
    }));
  }

  function reqP(req) {
    return new Promise((resolve, reject) => {
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }

  return {
    putDataset(ds) { return tx('readwrite', s => { s.put(ds); }); },
    getAll() { return open().then(db => reqP(db.transaction('datasets').objectStore('datasets').getAll())); },
    remove(id) { return tx('readwrite', s => { s.delete(id); }); },
    clear() { return tx('readwrite', s => { s.clear(); }); },
  };
})();
