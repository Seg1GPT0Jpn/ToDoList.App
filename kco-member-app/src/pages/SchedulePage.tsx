import { useState, type FormEvent } from 'react';
import { Link, useParams } from 'react-router-dom';
import { doc, serverTimestamp, setDoc } from 'firebase/firestore';
import { useAuth } from '../auth/AuthProvider';
import { AttendanceBadge } from '../components/Badges';
import { Empty, ErrorNote, Loading, PageTitle } from '../components/Layout';
import { getServices } from '../firebase';
import { ATTENDANCE_LABELS } from '../lib/attendance';
import { useMyAttendance, useRehearsal, useRehearsals } from '../lib/data';
import { formatDateJa, formatDeadline, formatTimeRange, orTbd, splitByDate, todayJst } from '../lib/dates';
import type { AttendanceStatus, Rehearsal } from '../lib/types';

function RehearsalRow({ r }: { r: Rehearsal }) {
  return (
    <li>
      <Link className="list__item" to={`/schedule/${r.id}`}>
        <span className="list__date">{r.date ? formatDateJa(r.date, false) : '日程未定'}</span>
        <span className="list__body">
          <span className="list__title">{r.title}</span>
          <br />
          <span className="small muted">{formatTimeRange(r.startTime, r.endTime)}／{orTbd(r.venue)}</span>
        </span>
      </Link>
    </li>
  );
}

export function SchedulePage() {
  const rehearsals = useRehearsals();
  const [showPast, setShowPast] = useState(false);

  if (rehearsals.loading) return <Loading />;

  const { upcoming, undecided, past } = splitByDate(rehearsals.data, todayJst());

  return (
    <div>
      <PageTitle en="Schedule">練習・予定</PageTitle>
      <ErrorNote message={rehearsals.error} />

      {upcoming.length ? <ul className="list">{upcoming.map(r => <RehearsalRow key={r.id} r={r} />)}</ul> : <Empty>予定されている練習はまだありません。</Empty>}

      {undecided.length > 0 && (
        <>
          <div className="section-heading"><h2>日程未定</h2></div>
          <ul className="list">{undecided.map(r => <RehearsalRow key={r.id} r={r} />)}</ul>
        </>
      )}

      {past.length > 0 && (
        <div style={{ marginTop: '1.5rem' }}>
          <button type="button" className="btn btn--sm btn--outline" onClick={() => setShowPast(v => !v)} aria-expanded={showPast}>
            {showPast ? '過去の練習を隠す' : `過去の練習（${past.length}件）`}
          </button>
          {showPast && <ul className="list" style={{ marginTop: '0.75rem' }}>{past.map(r => <RehearsalRow key={r.id} r={r} />)}</ul>}
        </div>
      )}
    </div>
  );
}

export function RehearsalDetailPage() {
  const { id } = useParams();
  const { access, canWrite } = useAuth();
  const rehearsal = useRehearsal(id);
  const mine = useMyAttendance(id, access?.memberId ?? null);
  const [comment, setComment] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(null);

  if (rehearsal.loading) return <Loading />;
  if (!rehearsal.data) return <Empty>この練習は見つかりませんでした。</Empty>;

  const r = rehearsal.data;
  const deadline = r.attendanceDeadline ? r.attendanceDeadline.toDate() : null;
  const closed = deadline ? Date.now() > deadline.getTime() : false;
  const canAnswer = canWrite && !!access?.memberId && !closed;
  const currentComment = comment ?? mine.data?.comment ?? '';

  async function save(status: AttendanceStatus, e?: FormEvent) {
    e?.preventDefault();
    if (!access?.memberId || !id) return;
    setSaving(true);
    setMessage(null);
    try {
      await setDoc(doc(getServices().db, 'rehearsals', id, 'attendance', access.memberId), {
        status,
        comment: currentComment.slice(0, 200),
        updatedAt: serverTimestamp()
      });
      setMessage({ ok: true, text: `「${ATTENDANCE_LABELS[status]}」で登録しました。` });
    } catch {
      setMessage({ ok: false, text: '登録できませんでした。締切を過ぎていないか確認してください。' });
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="stack">
      <p><Link to="/schedule" className="small">← 予定一覧</Link></p>
      <PageTitle en="Rehearsal">{r.title}</PageTitle>

      <div className="card">
        <p className="big-date">{formatDateJa(r.date)}</p>
        <dl className="info" style={{ marginTop: '0.5rem' }}>
          <div className="info__row"><dt>時間</dt><dd>{formatTimeRange(r.startTime, r.endTime)}</dd></div>
          <div className="info__row"><dt>会場</dt><dd className={r.venue ? '' : 'tbd'}>{orTbd(r.venue)}</dd></div>
          {r.target && <div className="info__row"><dt>対象</dt><dd>{r.target}</dd></div>}
          {r.content && <div className="info__row"><dt>内容</dt><dd className="pre">{r.content}</dd></div>}
          {r.scoreNote && <div className="info__row"><dt>楽譜</dt><dd className="pre">{r.scoreNote}</dd></div>}
          {r.notes && <div className="info__row"><dt>注意事項</dt><dd className="pre">{r.notes}</dd></div>}
          <div className="info__row"><dt>出欠締切</dt><dd>{formatDeadline(deadline)}</dd></div>
        </dl>
      </div>

      <section className="card" aria-labelledby="att-title">
        <h2 className="card__title" id="att-title">出欠</h2>
        <p className="row">
          <span>現在：</span>
          <AttendanceBadge status={mine.data?.status} />
        </p>
        {canAnswer ? (
          <form className="stack" onSubmit={e => e.preventDefault()}>
            <div className="choice-group" role="group" aria-label="出欠を選ぶ">
              {(['present', 'late', 'absent'] as AttendanceStatus[]).map(s => (
                <button
                  key={s}
                  type="button"
                  className="choice"
                  aria-pressed={mine.data?.status === s}
                  disabled={saving}
                  onClick={() => save(s)}
                >
                  {ATTENDANCE_LABELS[s]}
                </button>
              ))}
            </div>
            <div className="field">
              <label htmlFor="att-comment">ひとこと（任意・200文字まで）</label>
              <p className="field__hint">遅刻・早退の時間など。運営だけが見られます。</p>
              <input id="att-comment" type="text" maxLength={200} value={currentComment} onChange={e => setComment(e.target.value)} />
            </div>
            {mine.data && (
              <button type="button" className="btn btn--sm btn--outline" disabled={saving} onClick={() => save(mine.data!.status)}>
                ひとことを保存
              </button>
            )}
          </form>
        ) : (
          <p className="muted small">
            {closed ? '出欠の締切を過ぎました。変更がある場合は運営に連絡してください。' : 'この画面では出欠を登録できません。'}
          </p>
        )}
        {message && <p className={`alert ${message.ok ? 'alert--ok' : 'alert--error'}`} role="status" style={{ marginTop: '0.75rem' }}>{message.text}</p>}
      </section>
    </div>
  );
}
