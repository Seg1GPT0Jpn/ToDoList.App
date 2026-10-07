import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import {
  GoogleAuthProvider,
  isSignInWithEmailLink,
  onAuthStateChanged,
  sendSignInLinkToEmail,
  signInWithEmailLink,
  signInWithPopup,
  signInWithRedirect,
  signOut,
  type User
} from 'firebase/auth';
import { doc, onSnapshot } from 'firebase/firestore';
import { getServices } from '../firebase';
import { disablePush } from '../lib/push';
import type { MemberAccess } from '../lib/types';

/*
 * ログイン状態と「団員としてのアクセス権」をまとめて管理する。
 *
 * 画面の出し分けはここで行うが、これは表示のためだけ。
 * 実際に読める・書けるかは Firestore のルール（サーバー側）が判定する。
 */

export type AccessState =
  | 'loading'        // 確認中
  | 'signed-out'     // 未ログイン
  | 'unverified'     // メール未確認
  | 'not-member'     // ログインしたが団員として登録されていない（加入確定前など）
  | 'inactive'       // 退団・辞退などで利用停止
  | 'paused'         // 活動休止中（閲覧のみ）
  | 'active'         // 利用可能
  | 'error';

interface AuthValue {
  user: User | null;
  access: MemberAccess | null;
  state: AccessState;
  isStaff: boolean;
  isAdmin: boolean;
  canWrite: boolean;
  sendEmailLink: (email: string) => Promise<void>;
  completeEmailLink: (email?: string) => Promise<'done' | 'need-email' | 'not-link'>;
  signInWithGoogle: () => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthValue | null>(null);
const EMAIL_KEY = 'kco.emailForSignIn';

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [access, setAccess] = useState<MemberAccess | null>(null);
  const [state, setState] = useState<AccessState>('loading');

  useEffect(() => {
    const { auth } = getServices();
    return onAuthStateChanged(auth, u => {
      setUser(u);
      setAccess(null);
      if (!u) setState('signed-out');
      else if (!u.email || !u.emailVerified) setState('unverified');
      else setState('loading');
    });
  }, []);

  // 自分の memberAccess を監視（運営が状態を変えると即座に反映）
  useEffect(() => {
    if (!user || !user.email || !user.emailVerified) return;
    const { db } = getServices();
    return onSnapshot(
      doc(db, 'memberAccess', user.email.toLowerCase()),
      snap => {
        if (!snap.exists()) {
          setAccess(null);
          setState('not-member');
          return;
        }
        const d = snap.data();
        const a: MemberAccess = {
          email: user.email!.toLowerCase(),
          status: d.status === 'active' || d.status === 'paused' ? d.status : 'inactive',
          role: d.role === 'admin' || d.role === 'staff' ? d.role : 'member',
          memberId: typeof d.memberId === 'string' ? d.memberId : null,
          part: typeof d.part === 'string' ? d.part : ''
        };
        setAccess(a);
        setState(a.status);
      },
      () => setState('error')
    );
  }, [user]);

  const sendEmailLink = useCallback(async (email: string) => {
    const { auth } = getServices();
    const normalized = email.trim().toLowerCase();
    await sendSignInLinkToEmail(auth, normalized, {
      url: `${window.location.origin}/login/finish`,
      handleCodeInApp: true
    });
    try {
      window.localStorage.setItem(EMAIL_KEY, normalized);
    } catch {
      // 保存できなくても、リンクを開いたときにメールアドレスを再入力すれば続行できる
    }
  }, []);

  const completeEmailLink = useCallback(async (email?: string) => {
    const { auth } = getServices();
    const href = window.location.href;
    if (!isSignInWithEmailLink(auth, href)) return 'not-link' as const;
    let saved: string | null = null;
    try {
      saved = window.localStorage.getItem(EMAIL_KEY);
    } catch {
      saved = null;
    }
    const target = (email || saved || '').trim().toLowerCase();
    if (!target) return 'need-email' as const;
    await signInWithEmailLink(auth, target, href);
    try {
      window.localStorage.removeItem(EMAIL_KEY);
    } catch {
      // 無視
    }
    return 'done' as const;
  }, []);

  const signInWithGoogle = useCallback(async () => {
    const { auth } = getServices();
    const provider = new GoogleAuthProvider();
    provider.setCustomParameters({ prompt: 'select_account' });
    try {
      await signInWithPopup(auth, provider);
    } catch (e) {
      const code = (e as { code?: string }).code;
      if (code === 'auth/popup-blocked' || code === 'auth/operation-not-supported-in-this-environment') {
        await signInWithRedirect(auth, provider);
        return;
      }
      throw e;
    }
  }, []);

  const logout = useCallback(async () => {
    // この端末の通知登録を消してからログアウト（他の人が同じ端末を使っても届かないように）
    try {
      await disablePush();
    } catch {
      // 通知を使っていない・失敗してもログアウトは続ける
    }
    await signOut(getServices().auth);
  }, []);

  const value = useMemo<AuthValue>(() => {
    const role = access?.role ?? 'member';
    const active = state === 'active';
    return {
      user,
      access,
      state,
      isStaff: active && (role === 'staff' || role === 'admin'),
      isAdmin: active && role === 'admin',
      canWrite: active,
      sendEmailLink,
      completeEmailLink,
      signInWithGoogle,
      logout
    };
  }, [user, access, state, sendEmailLink, completeEmailLink, signInWithGoogle, logout]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthValue {
  const v = useContext(AuthContext);
  if (!v) throw new Error('AuthProvider の外で useAuth が呼ばれました');
  return v;
}

export function authErrorMessage(e: unknown): string {
  const code = (e as { code?: string })?.code ?? '';
  switch (code) {
    case 'auth/invalid-email':
      return 'メールアドレスの形式が正しくありません。';
    case 'auth/invalid-action-code':
    case 'auth/expired-action-code':
      return 'ログイン用リンクの有効期限が切れているか、すでに使用されています。もう一度リンクを送信してください。';
    case 'auth/too-many-requests':
      return '短時間に何度も試行されました。しばらく待ってから再度お試しください。';
    case 'auth/popup-closed-by-user':
    case 'auth/cancelled-popup-request':
      return 'ログインがキャンセルされました。';
    case 'auth/network-request-failed':
      return '通信できません。電波の良い場所で再度お試しください。';
    case 'auth/unauthorized-domain':
      return 'このアドレスからはログインできません（運営側の設定が必要です）。';
    default:
      return 'ログインに失敗しました。時間をおいて再度お試しください。';
  }
}
