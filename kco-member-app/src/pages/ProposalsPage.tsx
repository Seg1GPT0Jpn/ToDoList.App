import { useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import { addDoc, collection, deleteDoc, doc, increment, serverTimestamp, updateDoc, writeBatch } from 'firebase/firestore';
import { useAuth } from '../auth/AuthProvider';
import { Empty, ErrorNote, Loading, PageTitle } from '../components/Layout';
import { getServices } from '../firebase';
import { useMember, useMySupport, useProposals } from '../lib/data';
import type { Proposal, ProposalCategory, ProposalStatus, ProposalVisibility } from '../lib/types';

export const PROPOSAL_CATEGORIES: Record<ProposalCategory, string> = {
  idea: 'アイデア',
  music: '曲・演奏',
  practice: '練習',
  event: 'イベント・交流',
  other: 'その他'
};

export const PROPOSAL_STATUS: Record<ProposalStatus, { label: string; cls: string }> = {
  open: { label: '受付', cls: 'badge' },
  considering: { label: '検討中', cls: 'badge badge--gold' },
  adopted: { label: '採用', cls: 'badge badge--ok' },
  done: { label: '実現しました', cls: 'badge badge--navy' },
  declined: { label: '見送り', cls: 'badge badge--draft' }
};

export function ProposalsPage() {
  const { access, isStaff, canWrite } = useAuth();
  const memberId = access?.memberId ?? null;
  const proposals = useProposals(memberId, isStaff);
  const [filter, setFilter] = useState<'all' | 'mine'>('all');
  const [creating, setCreating] = useState(false);

  if (proposals.loading) return <Loading />;
  const list = filter === 'mine' ? proposals.data.filter(p => p.authorId === memberId) : proposals.data;

  return (
    <div className="stack">
      <p className="small"><Link to="/together">← みんなで</Link></p>
      <PageTitle en="Proposals">団員からの提案</PageTitle>
      <p className="small muted">
        「こんな曲をやりたい」「練習をこう工夫したい」など、オーケストラをよくするアイデアを気軽に送ってください。
        いいなと思った提案には「賛成」を押しましょう。
      </p>
      <ErrorNote message={proposals.error} />

      {canWrite && memberId && !creating && (
        <button type="button" className="btn" onClick={() => setCreating(true)}>＋ 提案する</button>
      )}
      {creating && <ProposalForm onDone={() => setCreating(false)} />}

      {memberId && (
        <div className="segmented" role="group" aria-label="表示する提案">
          <button type="button" className={filter === 'all' ? 'active' : undefined} aria-pressed={filter === 'all'} onClick={() => setFilter('all')}>すべて</button>
          <button type="button" className={filter === 'mine' ? 'active' : undefined} aria-pressed={filter === 'mine'} onClick={() => setFilter('mine')}>自分の提案</button>
        </div>
      )}

      {list.length === 0 ? (
        <Empty>まだ提案はありません。最初の提案をしてみませんか？</Empty>
      ) : (
        <ul className="stack" style={{ listStyle: 'none', padding: 0, margin: 0 }}>
          {list.map(p => <li key={p.id}><ProposalCard proposal={p} /></li>)}
        </ul>
      )}
    </div>
  );
}

function ProposalForm({ original, onDone }: { original?: Proposal; onDone: () => void }) {
  const { access } = useAuth();
  const me = useMember(access?.memberId ?? null);
  const [title, setTitle] = useState(original?.title ?? '');
  const [body, setBody] = useState(original?.body ?? '');
  const [category, setCategory] = useState<ProposalCategory>(original?.category ?? 'idea');
  const [visibility, setVisibility] = useState<ProposalVisibility>(original?.visibility ?? 'members');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (!title.trim()) return setError('タイトルを入力してください。');
    if (!access?.memberId || !me.data) return setError('団員プロフィールが読み込めていません。');
    setSaving(true);
    setError(null);
    const { db } = getServices();
    const content = { title: title.trim().slice(0, 80), body: body.slice(0, 2000), category, visibility, updatedAt: serverTimestamp() };
    try {
      if (original) {
        await updateDoc(doc(db, 'proposals', original.id), content);
      } else {
        await addDoc(collection(db, 'proposals'), {
          ...content,
          authorId: access.memberId,
          authorName: me.data.displayName,
          status: 'open',
          staffReply: '',
          supportCount: 0,
          createdAt: serverTimestamp()
        });
      }
      onDone();
    } catch {
      setError('送信できませんでした。時間をおいて再度お試しください。');
    } finally {
      setSaving(false);
    }
  }

  return (
    <form className="card stack" onSubmit={onSubmit}>
      <h2 className="card__title">{original ? '提案を編集' : '提案する'}</h2>
      <div className="field">
        <label htmlFor="p-title">タイトル（80文字まで）</label>
        <input id="p-title" type="text" maxLength={80} value={title} onChange={e => setTitle(e.target.value)} required />
      </div>
      <div className="field">
        <label htmlFor="p-body">内容（2000文字まで）</label>
        <textarea id="p-body" maxLength={2000} value={body} onChange={e => setBody(e.target.value)} />
      </div>
      <div className="field">
        <label htmlFor="p-cat">種類</label>
        <select id="p-cat" value={category} onChange={e => setCategory(e.target.value as ProposalCategory)}>
          {(Object.keys(PROPOSAL_CATEGORIES) as ProposalCategory[]).map(c => <option key={c} value={c}>{PROPOSAL_CATEGORIES[c]}</option>)}
        </select>
      </div>
      <fieldset className="field">
        <legend>だれに届けるか</legend>
        <label className="checkbox"><input type="radio" name="vis" checked={visibility === 'members'} onChange={() => setVisibility('members')} />団員みんなに公開（名前も表示されます）</label>
        <label className="checkbox"><input type="radio" name="vis" checked={visibility === 'staff'} onChange={() => setVisibility('staff')} />運営だけに送る（言いにくいことはこちら）</label>
      </fieldset>
      <div className="row">
        <button className="btn" type="submit" disabled={saving}>{original ? '保存する' : '送信する'}</button>
        <button className="btn btn--outline btn--sm" type="button" onClick={onDone}>キャンセル</button>
      </div>
      {error && <p className="alert alert--error" role="alert">{error}</p>}
    </form>
  );
}

function ProposalCard({ proposal: p }: { proposal: Proposal }) {
  const { access, isStaff, isAdmin, canWrite } = useAuth();
  const memberId = access?.memberId ?? null;
  const mySupport = useMySupport(p.id, memberId);
  const [editing, setEditing] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const isMine = !!memberId && p.authorId === memberId;
  const supported = !!mySupport.data;
  const canSupport = canWrite && !!memberId && !isMine && (p.visibility === 'members');

  async function toggleSupport() {
    if (!memberId) return;
    setBusy(true);
    setError(null);
    const { db } = getServices();
    const batch = writeBatch(db);
    const supportRef = doc(db, 'proposals', p.id, 'supports', memberId);
    if (supported) batch.delete(supportRef);
    else batch.set(supportRef, { createdAt: serverTimestamp() });
    batch.update(doc(db, 'proposals', p.id), { supportCount: increment(supported ? -1 : 1) });
    try {
      await batch.commit();
    } catch {
      setError('うまく反映できませんでした。もう一度お試しください。');
    } finally {
      setBusy(false);
    }
  }

  async function onDelete() {
    if (!window.confirm('この提案を削除しますか？')) return;
    try {
      await deleteDoc(doc(getServices().db, 'proposals', p.id));
    } catch {
      setError('削除できませんでした。');
    }
  }

  if (editing) return <ProposalForm original={p} onDone={() => setEditing(false)} />;

  return (
    <article className="card proposal">
      <div className="row" style={{ gap: '0.35rem' }}>
        <span className={PROPOSAL_STATUS[p.status]?.cls ?? 'badge'}>{PROPOSAL_STATUS[p.status]?.label ?? p.status}</span>
        <span className="badge">{PROPOSAL_CATEGORIES[p.category] ?? 'その他'}</span>
        {p.visibility === 'staff' && <span className="badge badge--draft">運営だけに送信</span>}
      </div>
      <h3 className="proposal__title">{p.title}</h3>
      {p.body && <p className="pre small">{p.body}</p>}
      <p className="small muted">{p.authorName || '団員'} さん{isMine && '（あなた）'}</p>

      {p.staffReply && (
        <div className="proposal__reply">
          <p className="small"><strong>運営より</strong></p>
          <p className="small pre">{p.staffReply}</p>
        </div>
      )}

      <div className="row">
        {p.visibility === 'members' && (
          <button type="button" className={`btn btn--sm ${supported ? '' : 'btn--outline'}`} onClick={toggleSupport} disabled={!canSupport || busy} aria-pressed={supported}>
            👏 賛成 {p.supportCount}
          </button>
        )}
        <span className="spacer" />
        {isMine && p.status === 'open' && canWrite && (
          <button type="button" className="btn btn--sm btn--outline" onClick={() => setEditing(true)}>編集</button>
        )}
        {((isMine && p.status === 'open' && canWrite) || isAdmin) && (
          <button type="button" className="btn btn--sm btn--danger" onClick={onDelete}>削除</button>
        )}
      </div>
      {error && <p className="alert alert--error small" role="alert">{error}</p>}
      {isStaff && <StaffReply proposal={p} />}
    </article>
  );
}

function StaffReply({ proposal: p }: { proposal: Proposal }) {
  const [status, setStatus] = useState<ProposalStatus>(p.status);
  const [reply, setReply] = useState(p.staffReply);
  const [msg, setMsg] = useState<string | null>(null);

  async function save() {
    setMsg(null);
    try {
      await updateDoc(doc(getServices().db, 'proposals', p.id), { status, staffReply: reply.slice(0, 2000), updatedAt: serverTimestamp() });
      setMsg('保存しました。');
    } catch {
      setMsg('保存できませんでした。');
    }
  }

  return (
    <details className="proposal__staff">
      <summary className="small">運営として対応する</summary>
      <div className="field">
        <label htmlFor={`st-${p.id}`}>対応状況</label>
        <select id={`st-${p.id}`} value={status} onChange={e => setStatus(e.target.value as ProposalStatus)}>
          {(Object.keys(PROPOSAL_STATUS) as ProposalStatus[]).map(s => <option key={s} value={s}>{PROPOSAL_STATUS[s].label}</option>)}
        </select>
      </div>
      <div className="field">
        <label htmlFor={`rp-${p.id}`}>返信（提案を見られる人に表示されます）</label>
        <textarea id={`rp-${p.id}`} maxLength={2000} value={reply} onChange={e => setReply(e.target.value)} />
      </div>
      <button type="button" className="btn btn--sm" onClick={save}>保存</button>
      {msg && <span className="small" role="status" style={{ marginLeft: '0.5rem' }}>{msg}</span>}
    </details>
  );
}
