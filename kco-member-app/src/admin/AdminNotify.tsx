import { useEffect, useState, type FormEvent } from 'react';
import { doc, serverTimestamp, setDoc } from 'firebase/firestore';
import { useAuth } from '../auth/AuthProvider';
import { Empty, ErrorNote, Loading } from '../components/Layout';
import { getServices } from '../firebase';
import { useAppConfig, useNotifications } from '../lib/data';
import { NOTIFY_LINKS, queueNotification } from '../lib/notify';
import { PARTS, SECTIONS, audienceLabel } from '../lib/parts';
import type { Audience, NotificationRequest } from '../lib/types';

const STATUS_LABEL: Record<NotificationRequest['status'], string> = {
  pending: '送信待ち',
  sending: '送信中',
  sent: '送信済み',
  failed: '失敗'
};

export function AdminNotify() {
  const { isAdmin } = useAuth();
  const list = useNotifications(true);
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [url, setUrl] = useState('/');
  const [audience, setAudience] = useState<Audience>({ type: 'all', values: [] });
  const [includeApplicants, setIncludeApplicants] = useState(false);
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(null);
  const [sending, setSending] = useState(false);

  const toggle = (v: string) =>
    setAudience(a => ({ ...a, values: a.values.includes(v) ? a.values.filter(x => x !== v) : [...a.values, v] }));

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setMessage(null);
    if (!title.trim()) return setMessage({ ok: false, text: 'タイトルを入力してください。' });
    if (audience.type !== 'all' && !audience.values.length) return setMessage({ ok: false, text: '対象を1つ以上選んでください。' });
    if (!window.confirm(`「${title.trim()}」を${audienceLabel(audience)}に通知します。よろしいですか？`)) return;
    setSending(true);
    try {
      await queueNotification({ title, body, url, audience, source: 'manual', includeApplicants });
      setTitle('');
      setBody('');
      setMessage({ ok: true, text: '送信を予約しました。数分以内に届きます。' });
    } catch {
      setMessage({ ok: false, text: '予約できませんでした。' });
    } finally {
      setSending(false);
    }
  }

  return (
    <div className="stack">
      <h2 style={{ margin: 0 }}>プッシュ通知</h2>
      <p className="small muted">
        通知をオンにした団員の端末に届きます（マイページでオン・オフできます）。
        送信は応募者管理スプレッドシートの Apps Script が数分ごとに行います。練習の前日にも自動でお知らせします（設定した場合）。
      </p>

      <form className="card stack" onSubmit={onSubmit}>
        <h3 className="card__title">通知を送る</h3>
        <div className="field">
          <label htmlFor="nt-title">タイトル（60文字まで）</label>
          <input id="nt-title" type="text" maxLength={60} value={title} onChange={e => setTitle(e.target.value)} required />
        </div>
        <div className="field">
          <label htmlFor="nt-body">本文（200文字まで）</label>
          <textarea id="nt-body" maxLength={200} value={body} onChange={e => setBody(e.target.value)} />
        </div>
        <div className="field">
          <label htmlFor="nt-url">タップしたときに開く画面</label>
          <select id="nt-url" value={url} onChange={e => setUrl(e.target.value)}>
            {NOTIFY_LINKS.map(l => <option key={l.path} value={l.path}>{l.label}</option>)}
          </select>
        </div>
        <fieldset className="field">
          <legend>対象</legend>
          <select aria-label="対象の種類" value={audience.type} onChange={e => setAudience({ type: e.target.value as Audience['type'], values: [] })}>
            <option value="all">全員</option>
            <option value="section">セクション</option>
            <option value="part">パート</option>
          </select>
          {audience.type !== 'all' && (
            <div className="row" style={{ marginTop: '0.5rem' }}>
              {(audience.type === 'section' ? SECTIONS.map(s => ({ id: s.id, label: s.label })) : PARTS.map(p => ({ id: p.part, label: p.label }))).map(o => (
                <label key={o.id} className="checkbox small">
                  <input type="checkbox" checked={audience.values.includes(o.id)} onChange={() => toggle(o.id)} />{o.label}
                </label>
              ))}
            </div>
          )}
        </fieldset>
        <label className="checkbox">
          <input type="checkbox" checked={includeApplicants} onChange={e => setIncludeApplicants(e.target.checked)} />
          参加希望者（応募しただけの人）にも送る
        </label>
        <p className="field__hint">通知はロック画面にも表示されます。個人的な内容や秘密の連絡には使わないでください。</p>
        <div className="row"><button className="btn" type="submit" disabled={sending}>送信を予約する</button></div>
        {message && <p className={`alert ${message.ok ? 'alert--ok' : 'alert--error'}`} role="status">{message.text}</p>}
      </form>

      <section>
        <h3>送信履歴（最新30件）</h3>
        <ErrorNote message={list.error} />
        {list.loading ? <Loading /> : list.data.length === 0 ? <Empty>まだ通知はありません。</Empty> : (
          <ul className="list">
            {list.data.map(n => (
              <li key={n.id} className="list__item">
                <div className="list__body">
                  <span className="row" style={{ gap: '0.35rem' }}>
                    <span className={`badge ${n.status === 'sent' ? 'badge--ok' : n.status === 'failed' ? 'badge--important' : ''}`}>{STATUS_LABEL[n.status] ?? n.status}</span>
                    <span className="badge">{audienceLabel(n.audience)}</span>
                    {n.source === 'reminder' && <span className="badge">自動（前日）</span>}
                  </span>
                  <p className="list__title">{n.title}</p>
                  {n.status === 'sent' && <p className="small muted">{n.sentCount ?? 0} 台に送信{n.failedCount ? `（届かなかった端末 ${n.failedCount}）` : ''}</p>}
                  {n.error && <p className="small muted">{n.error}</p>}
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>

      {isAdmin && <VapidSetting />}
    </div>
  );
}

/** Web Push の公開鍵（Firebase コンソール → プロジェクトの設定 → Cloud Messaging → ウェブプッシュ証明書） */
function VapidSetting() {
  const config = useAppConfig();
  const [key, setKey] = useState('');
  const [msg, setMsg] = useState<{ ok: boolean; text: string } | null>(null);

  useEffect(() => {
    if (config.data) setKey(config.data.vapidKey);
  }, [config.data]);

  async function save(e: FormEvent) {
    e.preventDefault();
    setMsg(null);
    const v = key.trim();
    if (v && !/^[A-Za-z0-9_-]{80,100}$/.test(v)) return setMsg({ ok: false, text: '鍵の形式が正しくありません（「鍵ペア」の長い文字列をそのまま貼ってください）。' });
    try {
      // 正式加入確認フォームの URL（同期が書き込む）は残す
      await setDoc(doc(getServices().db, 'appConfig', 'public'), { vapidKey: v, updatedAt: serverTimestamp() }, { merge: true });
      setMsg({ ok: true, text: '保存しました。団員はマイページから通知をオンにできます。' });
    } catch {
      setMsg({ ok: false, text: '保存できませんでした。' });
    }
  }

  return (
    <form className="card stack" onSubmit={save}>
      <h3 className="card__title">通知の設定（管理者のみ・最初に1回）</h3>
      <p className="small">
        Firebase コンソール →「プロジェクトの設定」→「Cloud Messaging」→「ウェブプッシュ証明書」で
        「鍵ペアを生成」し、表示された<strong>公開鍵</strong>を貼り付けてください（秘密鍵ではないので、ここに保存して問題ありません）。
      </p>
      <div className="field">
        <label htmlFor="vapid">ウェブプッシュ証明書（鍵ペア）</label>
        <input id="vapid" type="text" value={key} onChange={e => setKey(e.target.value)} autoComplete="off" spellCheck={false} />
      </div>
      <div className="row"><button className="btn btn--sm" type="submit">保存</button></div>
      {msg && <p className={`alert ${msg.ok ? 'alert--ok' : 'alert--error'}`} role="status">{msg.text}</p>}
    </form>
  );
}
