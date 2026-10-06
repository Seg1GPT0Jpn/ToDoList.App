import { initializeApp, type FirebaseApp, type FirebaseOptions } from 'firebase/app';
import { connectAuthEmulator, getAuth, type Auth } from 'firebase/auth';
import { connectFirestoreEmulator, getFirestore, type Firestore } from 'firebase/firestore';

/*
 * Firebase の初期化
 *
 * ・本番（Firebase Hosting）では、Hosting が自動で配信する /__/firebase/init.json から設定を読みます。
 *   → API キー等をソースコードや GitHub に置く必要がありません。
 *   （Firebase の Web 用設定値は秘密情報ではありませんが、念のためコードに含めない構成にしています）
 * ・ローカル開発では .env の VITE_FIREBASE_* を使います。
 * ・VITE_USE_EMULATORS=true のときはエミュレータに接続します（本番データに触れません）。
 */

export interface FirebaseServices {
  app: FirebaseApp;
  auth: Auth;
  db: Firestore;
}

let services: FirebaseServices | null = null;

async function loadConfig(): Promise<FirebaseOptions> {
  const env = import.meta.env;
  if (env.VITE_FIREBASE_API_KEY) {
    return {
      apiKey: env.VITE_FIREBASE_API_KEY,
      authDomain: env.VITE_FIREBASE_AUTH_DOMAIN,
      projectId: env.VITE_FIREBASE_PROJECT_ID,
      appId: env.VITE_FIREBASE_APP_ID,
      storageBucket: env.VITE_FIREBASE_STORAGE_BUCKET
    };
  }
  const res = await fetch('/__/firebase/init.json');
  if (!res.ok) {
    throw new Error('Firebase の設定を読み込めませんでした。Firebase Hosting で公開しているか確認してください。');
  }
  return (await res.json()) as FirebaseOptions;
}

export async function initFirebase(): Promise<FirebaseServices> {
  if (services) return services;

  const config = await loadConfig();
  const app = initializeApp(config);
  const auth = getAuth(app);
  const db = getFirestore(app);
  auth.languageCode = 'ja';

  if (import.meta.env.VITE_USE_EMULATORS === 'true') {
    connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
    connectFirestoreEmulator(db, '127.0.0.1', 8085);
  }

  services = { app, auth, db };
  return services;
}

export function getServices(): FirebaseServices {
  if (!services) throw new Error('Firebase がまだ初期化されていません');
  return services;
}
