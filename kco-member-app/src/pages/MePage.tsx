import { useEffect, useState, type FormEvent } from 'react';
import { doc, serverTimestamp, updateDoc } from 'firebase/firestore';
import { useAuth } from '../auth/AuthProvider';
import { ErrorNote, Loading, PageTitle } from '../components/Layout';
import { PushCard } from '../components/PushCard';
import { getServices } from '../firebase';
import { useMember } from '../lib/data';

export function MePage() {
  const { user, access, canWrite, logout, isAdmin, isStaff } = useAuth();
  const me = useMember(access?.memberId ?? null);
  const [displayName, setDisplayName] = useState('');
  const [bio, setBio] = useState('');
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(null);

  useEffect(() => {
    if (me.data) {
      setDisplayName(me.data.displayName);
      setBio(me.data.bio);
    }
  }, [me.data]);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (!access?.memberId) return;
    const name = displayName.trim();
    if (!name || name.length > 30) {
      setMessage({ ok: false, text: '呼ばれたい名前は1〜30文字で入力してください。' });
      return;
    }
    setSaving(true);
    setMessage(null);
    try {
      await updateDoc(doc(getServices().db, 'members', access.memberId), {
        displayName: name,
        bio: bio.slice(0, 500),
        updatedAt: serverTimestamp()
      });
      setMessage({ ok: true, text: '保存しました。' });
    } catch {
      setMessage({ ok: false, text: '保存できませんでした。時間をおいて再度お試しください。' });
    } finally {
      setSaving(false);
    }
  }

  if (me.loading) return <Loading />;

  return (
    <div className="stack">
      <PageTitle en="My Page">マイページ</PageTitle>
      <ErrorNote message={me.error} />

      {me.data ? (
        <form className="card" onSubmit={onSubmit}>
          <h2 className="card__title">プロフィール</h2>
          <p className="small muted">ここで設定した内容は、団員一覧で他の団員に表示されます。本名や連絡先は書かないでください。</p>
          <div className="field">
            <label htmlFor="displayName">呼ばれたい名前</label>
            <input id="displayName" type="text" maxLength={30} value={displayName} onChange={e => setDisplayName(e.target.value)} disabled={!canWrite} required />
          </div>
          <div className="field">
            <span className="field__hint">楽器・パート</span>
            <p><strong>{me.data.instrumentLabel || '未設定'}</strong></p>
            <p className="field__hint">楽器・パートの変更は運営にご連絡ください。</p>
          </div>
          <div className="field">
            <label htmlFor="bio">自己紹介（任意・500文字まで）</label>
            <textarea id="bio" maxLength={500} value={bio} onChange={e => setBio(e.target.value)} disabled={!canWrite} />
          </div>
          {canWrite && (
            <button className="btn" type="submit" disabled={saving} style={{ marginTop: '1rem' }}>保存する</button>
          )}
          {message && <p className={`alert ${message.ok ? 'alert--ok' : 'alert--error'}`} role="status" style={{ marginTop: '0.75rem' }}>{message.text}</p>}
        </form>
      ) : (
        <p className="alert alert--info">
          {isStaff ? '運営アカウントとしてログインしています（団員プロフィールはありません）。' : 'プロフィールを準備中です。'}
        </p>
      )}

      <PushCard />

      <div className="card">
        <h2 className="card__title">アカウント</h2>
        <dl className="info">
          <div className="info__row"><dt>ログイン中</dt><dd>{user?.email}</dd></div>
          <div className="info__row"><dt>権限</dt><dd>{isAdmin ? '管理者' : isStaff ? '運営補助' : '団員'}</dd></div>
        </dl>
        <p className="small muted" style={{ marginTop: '0.5rem' }}>メールアドレスは他の団員には表示されません。</p>
        <button type="button" className="btn btn--outline" onClick={() => logout()} style={{ marginTop: '0.75rem' }}>ログアウト</button>
      </div>
    </div>
  );
}
