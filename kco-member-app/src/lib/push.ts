import { deleteDoc, doc, serverTimestamp, setDoc } from 'firebase/firestore';
import { getServices } from '../firebase';

/*
 * プッシュ通知（Firebase Cloud Messaging / Web Push）
 *  ・端末ごとに「通知トークン」を pushTokens/{トークン} に保存（本人だけが読める・消せる）
 *  ・送信は運営の操作で notifications に予約 → Apps Script が送る（秘密鍵は使わない）
 */

const TOKEN_KEY = 'kco.pushToken';

export type PushSupport = 'supported' | 'unsupported' | 'ios-install' | 'denied';

function isIos(): boolean {
  return /iPad|iPhone|iPod/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
}

function isStandalone(): boolean {
  return window.matchMedia?.('(display-mode: standalone)').matches || (navigator as Navigator & { standalone?: boolean }).standalone === true;
}

export async function pushSupport(): Promise<PushSupport> {
  if (typeof window === 'undefined' || !('serviceWorker' in navigator)) return isIos() ? 'ios-install' : 'unsupported';
  if (!('Notification' in window) || !('PushManager' in window)) return isIos() && !isStandalone() ? 'ios-install' : 'unsupported';
  try {
    const { isSupported } = await import('firebase/messaging');
    if (!(await isSupported())) return isIos() && !isStandalone() ? 'ios-install' : 'unsupported';
  } catch {
    return 'unsupported';
  }
  if (Notification.permission === 'denied') return 'denied';
  return 'supported';
}

export function savedToken(): string | null {
  try {
    return window.localStorage.getItem(TOKEN_KEY);
  } catch {
    return null;
  }
}

function saveToken(token: string | null) {
  try {
    if (token) window.localStorage.setItem(TOKEN_KEY, token);
    else window.localStorage.removeItem(TOKEN_KEY);
  } catch {
    // 保存できなくても通知は届く（この端末での「オン」表示だけが消える）
  }
}

function platformLabel(): string {
  const ua = navigator.userAgent;
  if (isIos()) return 'iOS';
  if (/Android/.test(ua)) return 'Android';
  if (/Windows/.test(ua)) return 'Windows';
  if (/Mac/.test(ua)) return 'Mac';
  return 'その他';
}

/** この端末で通知を受け取る（許可ダイアログ → トークン登録） */
export async function enablePush(vapidKey: string, emailKey: string): Promise<void> {
  const permission = await Notification.requestPermission();
  if (permission !== 'granted') throw Object.assign(new Error('denied'), { code: 'push/denied' });

  const registration = await navigator.serviceWorker.register('/sw.js');
  await navigator.serviceWorker.ready;

  const { app, auth, db } = getServices();
  const { getMessaging, getToken } = await import('firebase/messaging');
  const token = await getToken(getMessaging(app), { vapidKey, serviceWorkerRegistration: registration });
  if (!token) throw new Error('no-token');

  const uid = auth.currentUser?.uid;
  if (!uid) throw new Error('signed-out');

  const old = savedToken();
  await setDoc(doc(db, 'pushTokens', token), {
    uid,
    accessKey: emailKey,
    token,
    platform: platformLabel(),
    updatedAt: serverTimestamp()
  });
  if (old && old !== token) await deleteDoc(doc(db, 'pushTokens', old)).catch(() => undefined);
  saveToken(token);
}

/** この端末の通知をやめる（ログアウト時にも呼ぶ） */
export async function disablePush(): Promise<void> {
  const token = savedToken();
  if (!token) return;
  const { app, db } = getServices();
  await deleteDoc(doc(db, 'pushTokens', token)).catch(() => undefined);
  try {
    const { getMessaging, deleteToken } = await import('firebase/messaging');
    await deleteToken(getMessaging(app));
  } catch {
    // 端末側のトークン削除に失敗しても、サーバー側の登録は消えているので通知は届かない
  }
  saveToken(null);
}
