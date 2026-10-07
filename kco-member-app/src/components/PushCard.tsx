import { useEffect, useState } from 'react';
import { useAuth } from '../auth/AuthProvider';
import { useAppConfig } from '../lib/data';
import { disablePush, enablePush, pushSupport, savedToken, type PushSupport } from '../lib/push';

/** マイページ：この端末で通知を受け取る */
export function PushCard() {
  const { user } = useAuth();
  const config = useAppConfig();
  const [support, setSupport] = useState<PushSupport | null>(null);
  const [on, setOn] = useState(!!savedToken());
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(null);

  useEffect(() => {
    pushSupport().then(setSupport).catch(() => setSupport('unsupported'));
  }, []);

  const vapidKey = config.data?.vapidKey ?? '';

  async function turnOn() {
    if (!user?.email) return;
    setBusy(true);
    setMessage(null);
    try {
      await enablePush(vapidKey, user.email.toLowerCase());
      setOn(true);
      setMessage({ ok: true, text: 'この端末で通知を受け取れるようになりました。' });
    } catch (e) {
      const code = (e as { code?: string }).code;
      setMessage({ ok: false, text: code === 'push/denied' || code === 'messaging/permission-blocked'
        ? '通知が許可されませんでした。端末の設定でこのアプリ（ブラウザ）の通知を許可してください。'
        : '通知をオンにできませんでした。時間をおいて再度お試しください。' });
    } finally {
      setBusy(false);
    }
  }

  async function turnOff() {
    setBusy(true);
    setMessage(null);
    try {
      await disablePush();
      setOn(false);
      setMessage({ ok: true, text: 'この端末の通知をオフにしました。' });
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="card">
      <h2 className="card__title">通知</h2>
      {support === null || config.loading ? (
        <p className="small muted">確認中…</p>
      ) : !vapidKey ? (
        <p className="small muted">通知機能は準備中です。</p>
      ) : support === 'ios-install' ? (
        <p className="small">iPhone・iPad で通知を受け取るには、Safari の共有ボタン →「ホーム画面に追加」をして、ホーム画面のアイコンからこのアプリを開いてください（iOS 16.4 以降）。</p>
      ) : support === 'unsupported' ? (
        <p className="small muted">このブラウザは通知に対応していません。Chrome・Safari の最新版でお試しください。</p>
      ) : support === 'denied' && !on ? (
        <p className="small">通知がブロックされています。端末（ブラウザ）の設定でこのサイトの通知を許可してください。</p>
      ) : (
        <>
          <p className="small">練習の前日や大事なお知らせを、この端末に通知します。</p>
          {on ? (
            <button type="button" className="btn btn--outline" onClick={turnOff} disabled={busy}>この端末の通知をオフにする</button>
          ) : (
            <button type="button" className="btn" onClick={turnOn} disabled={busy}>この端末で通知を受け取る</button>
          )}
        </>
      )}
      {message && <p className={`alert ${message.ok ? 'alert--ok' : 'alert--error'}`} role="status" style={{ marginTop: '0.75rem' }}>{message.text}</p>}
    </div>
  );
}
