import { useState, type FormEvent } from 'react';
import { doc, serverTimestamp, setDoc } from 'firebase/firestore';
import { useAuth } from '../auth/AuthProvider';
import { ErrorNote, Loading } from '../components/Layout';
import { getServices } from '../firebase';
import { useConcerts } from '../lib/data';
import type { Concert, ProgramItem } from '../lib/types';

/*
 * 第1回演奏会について、現時点で確定している情報だけを初期値にする。
 * （公式サイト・計画書に記載：メインプログラムはドヴォルザーク交響曲第7番。日時・会場などは未定）
 */
const FIRST_CONCERT: Omit<Concert, 'id'> = {
  title: '第1回演奏会',
  date: '',
  venue: '',
  openTime: '',
  startTime: '',
  program: [{ label: 'メインプログラム', composer: 'ドヴォルザーク', work: '交響曲第7番 ニ短調 作品70' }],
  performers: '',
  notes: '',
  daySchedule: '',
  order: 1,
  published: true
};

export function AdminConcert() {
  const { isAdmin } = useAuth();
  const concerts = useConcerts(true);
  const [editingId, setEditingId] = useState<string | null>(null);

  if (!isAdmin) return <p className="alert alert--error">演奏会情報の編集は管理者のみ可能です。</p>;
  if (concerts.loading) return <Loading />;

  const first = concerts.data.find(c => c.id === 'first');

  return (
    <div className="stack">
      <h2>演奏会情報</h2>
      <ErrorNote message={concerts.error} />
      {!first && !editingId && (
        <div className="card">
          <p>第1回演奏会の情報がまだありません。現在確定している内容（メインプログラムのみ。日時・会場などは「未定」）で作成できます。</p>
          <button className="btn" type="button" onClick={() => setEditingId('first')}>第1回演奏会の情報を作成</button>
        </div>
      )}
      {concerts.data.map(c => (
        <div key={c.id} className="card">
          <div className="row">
            <h3 style={{ margin: 0 }}>{c.title}</h3>
            {!c.published && <span className="badge badge--draft">非公開</span>}
            <span className="spacer" />
            {editingId !== c.id && <button className="btn btn--sm btn--outline" type="button" onClick={() => setEditingId(c.id)}>編集</button>}
          </div>
          {editingId === c.id && <ConcertForm id={c.id} initial={c} onDone={() => setEditingId(null)} />}
        </div>
      ))}
      {editingId === 'first' && !first && (
        <div className="card"><ConcertForm id="first" initial={{ id: 'first', ...FIRST_CONCERT }} onDone={() => setEditingId(null)} /></div>
      )}
    </div>
  );
}

function ConcertForm({ id, initial, onDone }: { id: string; initial: Concert; onDone: () => void }) {
  const [c, setC] = useState<Concert>(initial);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const set = <K extends keyof Concert>(k: K, v: Concert[K]) => setC(prev => ({ ...prev, [k]: v }));
  const setProgram = (i: number, k: keyof ProgramItem, v: string) =>
    set('program', c.program.map((p, j) => (j === i ? { ...p, [k]: v } : p)));

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError(null);
    try {
      await setDoc(doc(getServices().db, 'concerts', id), {
        title: c.title.trim().slice(0, 120) || '演奏会',
        date: c.date,
        venue: c.venue.trim().slice(0, 200),
        openTime: c.openTime,
        startTime: c.startTime,
        program: c.program
          .filter(p => p.composer.trim() || p.work.trim())
          .slice(0, 20)
          .map(p => ({ label: p.label.slice(0, 40), composer: p.composer.slice(0, 80), work: p.work.slice(0, 160) })),
        performers: c.performers.slice(0, 2000),
        notes: c.notes.slice(0, 5000),
        daySchedule: c.daySchedule.slice(0, 5000),
        order: Number.isInteger(c.order) ? c.order : 1,
        published: c.published,
        updatedAt: serverTimestamp()
      });
      onDone();
    } catch {
      setError('保存できませんでした。入力内容を確認してください。');
    } finally {
      setSaving(false);
    }
  }

  return (
    <form onSubmit={onSubmit} style={{ marginTop: '1rem' }}>
      <p className="small muted">決まっていない項目は空欄のまま保存してください（団員には「未定」と表示されます）。</p>
      <div className="field"><label htmlFor="c-title">名称</label><input id="c-title" type="text" value={c.title} onChange={e => set('title', e.target.value)} /></div>
      <div className="field"><label htmlFor="c-date">開催日</label><input id="c-date" type="date" value={c.date} onChange={e => set('date', e.target.value)} /></div>
      <div className="field"><label htmlFor="c-venue">会場</label><input id="c-venue" type="text" value={c.venue} onChange={e => set('venue', e.target.value)} /></div>
      <div className="row" style={{ marginTop: '1rem' }}>
        <div className="field" style={{ flex: 1 }}><label htmlFor="c-open">開場</label><input id="c-open" type="time" value={c.openTime} onChange={e => set('openTime', e.target.value)} /></div>
        <div className="field" style={{ flex: 1, marginTop: 0 }}><label htmlFor="c-start">開演</label><input id="c-start" type="time" value={c.startTime} onChange={e => set('startTime', e.target.value)} /></div>
      </div>
      <fieldset className="field">
        <legend>曲目</legend>
        {c.program.map((p, i) => (
          <div key={i} className="card" style={{ padding: '0.75rem', marginTop: '0.5rem' }}>
            <input aria-label={`曲目${i + 1}の区分`} type="text" placeholder="区分（例：メインプログラム）" value={p.label} onChange={e => setProgram(i, 'label', e.target.value)} />
            <input aria-label={`曲目${i + 1}の作曲者`} type="text" placeholder="作曲者" value={p.composer} onChange={e => setProgram(i, 'composer', e.target.value)} style={{ marginTop: '0.4rem' }} />
            <input aria-label={`曲目${i + 1}の曲名`} type="text" placeholder="曲名" value={p.work} onChange={e => setProgram(i, 'work', e.target.value)} style={{ marginTop: '0.4rem' }} />
            <button type="button" className="btn btn--danger btn--sm" style={{ marginTop: '0.4rem' }} onClick={() => set('program', c.program.filter((_, j) => j !== i))}>この曲を削除</button>
          </div>
        ))}
        <button type="button" className="btn btn--outline btn--sm" style={{ marginTop: '0.5rem' }} onClick={() => set('program', [...c.program, { label: '', composer: '', work: '' }])}>＋ 曲を追加</button>
      </fieldset>
      <div className="field"><label htmlFor="c-perf">出演者</label><textarea id="c-perf" value={c.performers} onChange={e => set('performers', e.target.value)} /></div>
      <div className="field"><label htmlFor="c-day">当日のスケジュール</label><textarea id="c-day" value={c.daySchedule} onChange={e => set('daySchedule', e.target.value)} /></div>
      <div className="field"><label htmlFor="c-notes">注意事項</label><textarea id="c-notes" value={c.notes} onChange={e => set('notes', e.target.value)} /></div>
      <label className="checkbox"><input type="checkbox" checked={c.published} onChange={e => set('published', e.target.checked)} />団員に公開する</label>
      <div className="row" style={{ marginTop: '1rem' }}>
        <button className="btn" type="submit" disabled={saving}>保存する</button>
        <button className="btn btn--outline btn--sm" type="button" onClick={onDone}>キャンセル</button>
      </div>
      {error && <p className="alert alert--error" role="alert" style={{ marginTop: '0.75rem' }}>{error}</p>}
    </form>
  );
}
