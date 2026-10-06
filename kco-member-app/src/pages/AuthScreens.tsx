import { useEffect, useState, type FormEvent, type ReactNode } from 'react';
import { useNavigate } from 'react-router-dom';
import { authErrorMessage, useAuth } from '../auth/AuthProvider';

function AuthFrame({ children }: { children: ReactNode }) {
  return (
    <div className="auth-screen">
      <div className="auth-card">
        <div className="auth-logo" aria-hidden="true">KC</div>
        <p className="auth-title">かながわコネクトオーケストラ</p>
        <p className="auth-concept">団員専用ページ</p>
        {children}
      </div>
    </div>
  );
}

export function LoginPage() {
  const { sendEmailLink, signInWithGoogle } = useAuth();
  const [email, setEmail] = useState('');
  const [sent, setSent] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) {
      setError('メールアドレスの形式が正しくありません。');
      return;
    }
    setBusy(true);
    try {
      await sendEmailLink(email);
      setSent(true);
    } catch (err) {
      setError(authErrorMessage(err));
    } finally {
      setBusy(false);
    }
  }

  async function onGoogle() {
    setError(null);
    setBusy(true);
    try {
      await signInWithGoogle();
    } catch (err) {
      setError(authErrorMessage(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <AuthFrame>
      <div className="card stack">
        {sent ? (
          <div className="stack">
            <h1 className="h2">メールを確認してください</h1>
            <p>
              <strong>{email.trim()}</strong> にログイン用のリンクを送りました。
              メール内のリンクを、<strong>このブラウザ</strong>で開くとログインできます。
            </p>
            <p className="small muted">
              数分たっても届かない場合は、迷惑メールフォルダも確認してください。
              学校のメールアドレスは外部からのメールが届かないことがあります。
            </p>
            <button type="button" className="btn btn--outline btn--block" onClick={() => setSent(false)}>
              別のメールアドレスで送る
            </button>
          </div>
        ) : (
          <form className="stack" onSubmit={onSubmit} noValidate>
            <div className="field">
              <label htmlFor="email">メールアドレス</label>
              <p className="field__hint" id="email-hint">参加希望フォームで登録したメールアドレスを入力してください。パスワードは不要です。</p>
              <input
                id="email"
                type="email"
                inputMode="email"
                autoComplete="email"
                aria-describedby="email-hint"
                value={email}
                onChange={e => setEmail(e.target.value)}
                required
              />
            </div>
            <button className="btn btn--block" type="submit" disabled={busy}>
              ログイン用リンクを送る
            </button>
          </form>
        )}

        {error && <p className="alert alert--error" role="alert">{error}</p>}

        <div className="divider">または</div>
        <button type="button" className="btn btn--outline btn--block" onClick={onGoogle} disabled={busy}>
          Google アカウントでログイン
        </button>
        <p className="small muted">
          このページは加入が確定した団員の方専用です。参加をご希望の方は公式サイトの参加希望フォームからお申し込みください。
        </p>
      </div>
    </AuthFrame>
  );
}

export function FinishLoginPage() {
  const { completeEmailLink, state } = useAuth();
  const navigate = useNavigate();
  const [needEmail, setNeedEmail] = useState(false);
  const [email, setEmail] = useState('');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    completeEmailLink()
      .then(r => {
        if (r === 'need-email') setNeedEmail(true);
        else navigate('/', { replace: true });
      })
      .catch(err => setError(authErrorMessage(err)));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (state !== 'signed-out' && state !== 'loading') navigate('/', { replace: true });
  }, [state, navigate]);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    try {
      await completeEmailLink(email);
      navigate('/', { replace: true });
    } catch (err) {
      setError(authErrorMessage(err));
    }
  }

  return (
    <AuthFrame>
      <div className="card stack">
        {needEmail ? (
          <form className="stack" onSubmit={onSubmit}>
            <p>確認のため、ログイン用リンクを受け取ったメールアドレスを入力してください。</p>
            <div className="field">
              <label htmlFor="email2">メールアドレス</label>
              <input id="email2" type="email" autoComplete="email" value={email} onChange={e => setEmail(e.target.value)} required />
            </div>
            <button className="btn btn--block" type="submit">ログイン</button>
          </form>
        ) : (
          !error && <p role="status">ログインしています…</p>
        )}
        {error && (
          <>
            <p className="alert alert--error" role="alert">{error}</p>
            <a className="btn btn--outline btn--block" href="/login">ログイン画面へ戻る</a>
          </>
        )}
      </div>
    </AuthFrame>
  );
}

/** ログインはできたが、団員として利用できない場合の画面 */
export function GateScreen() {
  const { state, user, logout } = useAuth();

  const messages: Record<string, { title: string; body: ReactNode }> = {
    unverified: {
      title: 'メールアドレスが確認できません',
      body: <p>メールアドレスが確認済みのアカウントでログインしてください。</p>
    },
    'not-member': {
      title: '加入確定後にご利用いただけます',
      body: (
        <>
          <p>このページは、加入が確定した団員の方専用です。</p>
          <p>参加希望フォームでお申し込み済みの方は、運営からのご連絡をお待ちください。加入が確定すると、同じメールアドレスでご利用いただけるようになります。</p>
          <p className="small muted">参加希望フォームとは別のメールアドレスでログインしている可能性もあります。</p>
        </>
      )
    },
    inactive: {
      title: '現在ご利用いただけません',
      body: <p>このアカウントは現在、団員専用ページをご利用いただけない状態です。お心当たりがない場合は運営までご連絡ください。</p>
    },
    error: {
      title: '確認できませんでした',
      body: <p>通信状況を確認して、ページを再読み込みしてください。</p>
    }
  };

  const m = messages[state] ?? messages.error;

  return (
    <AuthFrame>
      <div className="card stack">
        <h1 className="h2">{m.title}</h1>
        {m.body}
        {user?.email && <p className="small muted">ログイン中：{user.email}</p>}
        <button type="button" className="btn btn--outline btn--block" onClick={() => logout()}>
          ログアウト
        </button>
      </div>
    </AuthFrame>
  );
}
