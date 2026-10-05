// Firebase の初期化（曲目候補フォーム・管理画面で共通）
//
// 設定値は Firebase Hosting が自動で提供する /__/firebase/init.json から読み込みます。
// そのため API キーなどをソースコードに書く必要はありません。
// ローカルの Firebase エミュレーター上では、自動的にエミュレーターへ接続します。
import { initializeApp } from "firebase/app";
import { getFirestore, connectFirestoreEmulator } from "firebase/firestore/lite";

export const COLLECTION = "programSuggestions";

export const CATEGORIES = {
  opening: "オープニング",
  submain: "サブメイン",
  encore1: "アンコール1",
  encore2: "アンコール2",
};

export const PARTICIPATION = {
  "": "未回答",
  applied: "参加希望フォーム送信済み",
  considering: "参加を検討中",
  undecided: "まだ分からない",
  other: "その他",
};

export const EMULATOR_PORTS = { firestore: 8085, auth: 9099 };

export const isLocal = ["localhost", "127.0.0.1"].includes(window.location.hostname);

let appPromise;

export function getApp() {
  if (!appPromise) {
    appPromise = fetch("/__/firebase/init.json")
      .then((res) => {
        if (!res.ok) throw new Error("firebase-config-unavailable");
        return res.json();
      })
      .then((config) => initializeApp(config));
  }
  return appPromise;
}

let dbPromise;

export function getDb() {
  if (!dbPromise) {
    dbPromise = getApp().then((app) => {
      const db = getFirestore(app);
      if (isLocal) connectFirestoreEmulator(db, "127.0.0.1", EMULATOR_PORTS.firestore);
      return db;
    });
  }
  return dbPromise;
}
