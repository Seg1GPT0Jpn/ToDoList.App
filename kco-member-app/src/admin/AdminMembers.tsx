import { useState } from 'react';
import { doc, serverTimestamp, updateDoc } from 'firebase/firestore';
import { useAuth } from '../auth/AuthProvider';
import { Empty, ErrorNote, Loading } from '../components/Layout';
import { getServices } from '../firebase';
import { useMembers } from '../lib/data';
import { partLabel, partOrder } from '../lib/parts';
import type { Member } from '../lib/types';

const STATUS_LABELS: Record<Member['status'], string> = { active: '在籍', paused: '活動休止', inactive: '利用停止' };

export function AdminMembers() {
  const { isAdmin } = useAuth();
  const members = useMembers();
  const [showInactive, setShowInactive] = useState(false);

  if (members.loading) return <Loading />;

  const list = members.data
    .filter(m => showInactive || m.status !== 'inactive')
    .sort((a, b) => partOrder(a.part) - partOrder(b.part) || a.displayName.localeCompare(b.displayName, 'ja'));

  return (
    <div className="stack">
      <h2>団員一覧</h2>
      <ErrorNote message={members.error} />
      <p className="small muted">
        加入ステータス・楽器・権限は応募者管理スプレッドシートで変更し、「団員アプリへ同期」で反映してください。
        ここでは不適切な表示名の修正と、役職表示（例：コンサートマスター）の設定だけができます。
      </p>
      <label className="checkbox small">
        <input type="checkbox" checked={showInactive} onChange={e => setShowInactive(e.target.checked)} />
        利用停止（退団・辞退など）も表示
      </label>
      {list.length === 0 ? <Empty>団員はまだ同期されていません。</Empty> : (
        <ul className="roster">
          {list.map(m => <MemberRow key={m.id} m={m} editable={isAdmin} />)}
        </ul>
      )}
    </div>
  );
}

function MemberRow({ m, editable }: { m: Member; editable: boolean }) {
  const [open, setOpen] = useState(false);
  const [name, setName] = useState(m.displayName);
  const [roleLabel, setRoleLabel] = useState(m.roleLabel ?? '');
  const [error, setError] = useState<string | null>(null);

  async function save() {
    setError(null);
    if (!name.trim() || name.trim().length > 30) {
      setError('表示名は1〜30文字です。');
      return;
    }
    try {
      await updateDoc(doc(getServices().db, 'members', m.id), {
        displayName: name.trim(),
        bio: m.bio,
        roleLabel: roleLabel.trim().slice(0, 40),
        updatedAt: serverTimestamp()
      });
      setOpen(false);
    } catch {
      setError('保存できませんでした。');
    }
  }

  return (
    <li>
      <div className="row">
        <span className="roster__name">{m.displayName}</span>
        <span className="small muted">{partLabel(m.part)}（{m.instrumentLabel}）</span>
        {m.roleLabel && <span className="badge badge--navy">{m.roleLabel}</span>}
        <span className={`badge${m.status === 'active' ? '' : ' badge--draft'}`}>{STATUS_LABELS[m.status]}</span>
        <span className="spacer" />
        {editable && <button type="button" className="btn btn--sm btn--outline" onClick={() => setOpen(v => !v)}>{open ? '閉じる' : '編集'}</button>}
      </div>
      {open && (
        <div className="stack" style={{ marginTop: '0.75rem' }}>
          <div className="field"><label htmlFor={`n-${m.id}`}>表示名</label><input id={`n-${m.id}`} type="text" maxLength={30} value={name} onChange={e => setName(e.target.value)} /></div>
          <div className="field"><label htmlFor={`r-${m.id}`}>役職表示（任意）</label><input id={`r-${m.id}`} type="text" maxLength={40} value={roleLabel} onChange={e => setRoleLabel(e.target.value)} /></div>
          <button type="button" className="btn btn--sm" onClick={save}>保存</button>
          <ErrorNote message={error} />
        </div>
      )}
    </li>
  );
}
