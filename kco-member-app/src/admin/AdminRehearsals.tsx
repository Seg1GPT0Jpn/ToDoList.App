import { useMemo, useState, type FormEvent } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { Timestamp, addDoc, collection, deleteDoc, doc, serverTimestamp, setDoc } from 'firebase/firestore';
import { useAuth } from '../auth/AuthProvider';
import { AttendanceBadge } from '../components/Badges';
import { Empty, ErrorNote, Loading } from '../components/Layout';
import { getServices } from '../firebase';
import { summarizeAttendance } from '../lib/attendance';
import { useAllAttendance, useApplicants, useMembers, useRehearsal, useRehearsals } from '../lib/data';
import { endOfDayJst, formatDateJa, formatTimeRange, orTbd, toDateInput } from '../lib/dates';
import type { Rehearsal } from '../lib/types';

export function AdminRehearsals() {
  const rehearsals = useRehearsals(true);

  if (rehearsals.loading) return <Loading />;

  const sorted = [...rehearsals.data].sort((a, b) => (a.date || '9999').localeCompare(b.date || '9999'));

  return (
    <div className="stack">
      <div className="row">
        <h2 style={{ margin: 0 }}>練習予定</h2>
        <span className="spacer" />
        <Link className="btn btn--sm" to="/admin/rehearsals/new">＋ 練習を追加</Link>
      </div>
      <ErrorNote message={rehearsals.error} />
      {sorted.length === 0 ? (
        <Empty>練習予定はまだありません。日程・会場が未定でも「未定」のまま登録できます。</Empty>
      ) : (
        <ul className="list">
          {sorted.map(r => (
            <li key={r.id}>
              <Link className="list__item" to={`/admin/rehearsals/${r.id}`}>
                <span className="list__date">{r.date ? formatDateJa(r.date, false) : '未定'}</span>
                <span className="list__body">
                  <span className="list__title">{r.title}</span> {!r.published && <span className="badge badge--draft">下書き</span>}
                  <br />
                  <span className="small muted">{formatTimeRange(r.startTime, r.endTime)}／{orTbd(r.venue)}</span>
                </span>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

interface FormState {
  title: string;
  date: string;
  startTime: string;
  endTime: string;
  venue: string;
  content: string;
  notes: string;
  target: string;
  scoreNote: string;
  deadline: string;
  published: boolean;
}

function toForm(r: Rehearsal | null): FormState {
  return {
    title: r?.title ?? '合奏練習',
    date: r?.date ?? '',
    startTime: r?.startTime ?? '',
    endTime: r?.endTime ?? '',
    venue: r?.venue ?? '',
    content: r?.content ?? '',
    notes: r?.notes ?? '',
    target: r?.target ?? '',
    scoreNote: r?.scoreNote ?? '',
    deadline: r?.attendanceDeadline ? toDateInput(r.attendanceDeadline.toDate()) : '',
    published: r?.published ?? false
  };
}

export function AdminRehearsalEdit() {
  const { id } = useParams();
  const isNew = id === 'new';
  const existing = useRehearsal(isNew ? undefined : id);

  if (!isNew && existing.loading) return <Loading />;
  if (!isNew && !existing.data) return <Empty>この練習は見つかりませんでした。</Empty>;

  return (
    <div className="stack">
      <p><Link to="/admin/rehearsals" className="small">← 練習予定一覧</Link></p>
      <RehearsalForm key={id} id={isNew ? null : id!} initial={toForm(isNew ? null : existing.data)} />
      {!isNew && existing.data && <AttendanceSummary rehearsalId={id!} />}
    </div>
  );
}

function RehearsalForm({ id, initial }: { id: string | null; initial: FormState }) {
  const navigate = useNavigate();
  const [f, setF] = useState<FormState>(initial);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(null);

  const set = <K extends keyof FormState>(k: K, v: FormState[K]) => setF(prev => ({ ...prev, [k]: v }));

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (!f.title.trim()) {
      setMessage({ ok: false, text: 'タイトルを入力してください。' });
      return;
    }
    setSaving(true);
    setMessage(null);
    const deadline = endOfDayJst(f.deadline);
    const data = {
      title: f.title.trim().slice(0, 100),
      date: f.date,
      startTime: f.startTime,
      endTime: f.endTime,
      venue: f.venue.trim().slice(0, 200),
      content: f.content.slice(0, 3000),
      notes: f.notes.slice(0, 3000),
      target: f.target.trim().slice(0, 200),
      scoreNote: f.scoreNote.slice(0, 1000),
      attendanceDeadline: deadline ? Timestamp.fromDate(deadline) : null,
      published: f.published,
      updatedAt: serverTimestamp()
    };
    try {
      const { db } = getServices();
      if (id) {
        await setDoc(doc(db, 'rehearsals', id), data, { merge: true });
        setMessage({ ok: true, text: '保存しました。' });
      } else {
        const ref = await addDoc(collection(db, 'rehearsals'), { ...data, createdAt: serverTimestamp() });
        navigate(`/admin/rehearsals/${ref.id}`, { replace: true });
      }
    } catch {
      setMessage({ ok: false, text: '保存できませんでした。入力内容を確認してください。' });
    } finally {
      setSaving(false);
    }
  }

  async function onDelete() {
    if (!id || !window.confirm('この練習予定を削除しますか？（出欠の記録は残りますが表示されなくなります）')) return;
    try {
      await deleteDoc(doc(getServices().db, 'rehearsals', id));
      navigate('/admin/rehearsals', { replace: true });
    } catch {
      setMessage({ ok: false, text: '削除できませんでした。' });
    }
  }

  return (
    <form className="card" onSubmit={onSubmit}>
      <h2 className="card__title">{id ? '練習予定を編集' : '練習予定を追加'}</h2>
      <p className="small muted">決まっていない項目は空欄のままで大丈夫です（団員には「未定」と表示されます）。</p>

      <div className="field">
        <label htmlFor="r-title">タイトル</label>
        <input id="r-title" type="text" maxLength={100} value={f.title} onChange={e => set('title', e.target.value)} required />
      </div>
      <div className="field">
        <label htmlFor="r-date">日付</label>
        <input id="r-date" type="date" value={f.date} onChange={e => set('date', e.target.value)} />
      </div>
      <div className="row" style={{ marginTop: '1rem' }}>
        <div className="field" style={{ flex: 1 }}>
          <label htmlFor="r-start">開始時刻</label>
          <input id="r-start" type="time" value={f.startTime} onChange={e => set('startTime', e.target.value)} />
        </div>
        <div className="field" style={{ flex: 1, marginTop: 0 }}>
          <label htmlFor="r-end">終了時刻</label>
          <input id="r-end" type="time" value={f.endTime} onChange={e => set('endTime', e.target.value)} />
        </div>
      </div>
      <div className="field">
        <label htmlFor="r-venue">会場</label>
        <input id="r-venue" type="text" maxLength={200} value={f.venue} onChange={e => set('venue', e.target.value)} />
      </div>
      <div className="field">
        <label htmlFor="r-target">対象</label>
        <input id="r-target" type="text" maxLength={200} placeholder="例：全員／弦楽器のみ" value={f.target} onChange={e => set('target', e.target.value)} />
      </div>
      <div className="field">
        <label htmlFor="r-content">内容</label>
        <textarea id="r-content" maxLength={3000} value={f.content} onChange={e => set('content', e.target.value)} />
      </div>
      <div className="field">
        <label htmlFor="r-score">楽譜・持ち物</label>
        <textarea id="r-score" maxLength={1000} value={f.scoreNote} onChange={e => set('scoreNote', e.target.value)} />
      </div>
      <div className="field">
        <label htmlFor="r-notes">注意事項</label>
        <textarea id="r-notes" maxLength={3000} value={f.notes} onChange={e => set('notes', e.target.value)} />
      </div>
      <div className="field">
        <label htmlFor="r-deadline">出欠締切</label>
        <p className="field__hint">この日の23:59まで回答できます。空欄なら締切なし。</p>
        <input id="r-deadline" type="date" value={f.deadline} onChange={e => set('deadline', e.target.value)} />
      </div>
      <label className="checkbox" style={{ marginTop: '1rem' }}>
        <input type="checkbox" checked={f.published} onChange={e => set('published', e.target.checked)} />
        団員に公開する（オフの間は運営だけが見られる下書き）
      </label>

      <div className="row" style={{ marginTop: '1rem' }}>
        <button className="btn" type="submit" disabled={saving}>保存する</button>
        {id && <button className="btn btn--danger btn--sm" type="button" onClick={onDelete}>削除</button>}
      </div>
      {message && <p className={`alert ${message.ok ? 'alert--ok' : 'alert--error'}`} role="status" style={{ marginTop: '0.75rem' }}>{message.text}</p>}
    </form>
  );
}

function AttendanceSummary({ rehearsalId }: { rehearsalId: string }) {
  const { isStaff } = useAuth();
  const members = useMembers();
  const applicants = useApplicants(isStaff);
  const records = useAllAttendance(rehearsalId, isStaff);
  const [showList, setShowList] = useState(false);

  const summary = useMemo(() => summarizeAttendance(members.data, records.data), [members.data, records.data]);
  const byId = useMemo(() => new Map(records.data.map(r => [r.memberId, r])), [records.data]);

  if (members.loading || records.loading) return <Loading />;

  const active = members.data.filter(m => m.status === 'active');
  // 参加希望者（見学・体験）は団員の集計とは分けて、回答した人だけ表示
  const guests = applicants.data.filter(a => a.status === 'active' && byId.has(a.id));

  return (
    <section className="card" aria-labelledby="att-sum">
      <h2 className="card__title" id="att-sum">出欠状況</h2>
      <ErrorNote message={members.error || records.error} />
      <div className="stat-tiles">
        <div className="stat-tile"><p className="stat-tile__label">出席</p><p className="stat-tile__value">{summary.present}</p></div>
        <div className="stat-tile"><p className="stat-tile__label">遅刻</p><p className="stat-tile__value">{summary.late}</p></div>
        <div className="stat-tile"><p className="stat-tile__label">欠席</p><p className="stat-tile__value">{summary.absent}</p></div>
        <div className="stat-tile"><p className="stat-tile__label">未回答</p><p className="stat-tile__value">{summary.none}</p></div>
      </div>

      {summary.byPart.length > 0 && (
        <div className="table-wrap" style={{ marginTop: '1rem' }}>
          <table className="table">
            <thead><tr><th>パート</th><th className="num">出席</th><th className="num">遅刻</th><th className="num">欠席</th><th className="num">未回答</th></tr></thead>
            <tbody>
              {summary.byPart.map(p => (
                <tr key={p.part}><th scope="row">{p.label}</th><td className="num">{p.present}</td><td className="num">{p.late}</td><td className="num">{p.absent}</td><td className="num">{p.none}</td></tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <button type="button" className="btn btn--sm btn--outline" style={{ marginTop: '1rem' }} onClick={() => setShowList(v => !v)} aria-expanded={showList}>
        {showList ? '一覧を閉じる' : '団員ごとの回答を見る'}
      </button>
      {showList && (
        <ul className="roster" style={{ marginTop: '0.75rem' }}>
          {active.map(m => {
            const r = byId.get(m.id);
            return (
              <li key={m.id}>
                <div className="row">
                  <span className="roster__name">{m.displayName}</span>
                  <span className="small muted">{m.instrumentLabel}</span>
                  <span className="spacer" />
                  <AttendanceBadge status={r?.status} />
                </div>
                {r?.comment && <p className="small" style={{ marginTop: '0.25rem' }}>{r.comment}</p>}
              </li>
            );
          })}
        </ul>
      )}

      {guests.length > 0 && (
        <div style={{ marginTop: '1rem' }}>
          <h3 className="h3">参加希望者（見学・体験）{guests.length}人</h3>
          <p className="small muted">団員の出欠集計には含めていません。</p>
          <ul className="roster">
            {guests.map(a => {
              const r = byId.get(a.id);
              return (
                <li key={a.id}>
                  <div className="row">
                    <span className="roster__name">{a.displayName}</span>
                    <span className="small muted">{a.instrumentLabel}</span>
                    <span className="badge">参加希望</span>
                    <span className="spacer" />
                    <AttendanceBadge status={r?.status} />
                  </div>
                  {r?.comment && <p className="small" style={{ marginTop: '0.25rem' }}>{r.comment}</p>}
                </li>
              );
            })}
          </ul>
        </div>
      )}
    </section>
  );
}
