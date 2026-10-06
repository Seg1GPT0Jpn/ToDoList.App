import { useState, type FormEvent } from 'react';
import { addDoc, collection, deleteDoc, doc, serverTimestamp, setDoc } from 'firebase/firestore';
import { CATEGORY_LABELS, CategoryBadge } from '../components/Badges';
import { Empty, ErrorNote, Loading } from '../components/Layout';
import { getServices } from '../firebase';
import { useAnnouncements } from '../lib/data';
import { PARTS, SECTIONS, audienceLabel } from '../lib/parts';
import type { Announcement, AnnouncementCategory, Audience } from '../lib/types';

interface FormState {
  title: string;
  body: string;
  important: boolean;
  category: AnnouncementCategory;
  audience: Audience;
  published: boolean;
}

const EMPTY: FormState = {
  title: '',
  body: '',
  important: false,
  category: 'general',
  audience: { type: 'all', values: [] },
  published: true
};

export function AdminNews() {
  const news = useAnnouncements(true);
  const [editing, setEditing] = useState<Announcement | 'new' | null>(null);

  if (news.loading) return <Loading />;

  return (
    <div className="stack">
      <div className="row">
        <h2 style={{ margin: 0 }}>お知らせ</h2>
        <span className="spacer" />
        {!editing && <button className="btn btn--sm" type="button" onClick={() => setEditing('new')}>＋ お知らせを作成</button>}
      </div>
      <ErrorNote message={news.error} />

      {editing && (
        <NewsForm
          key={editing === 'new' ? 'new' : editing.id}
          original={editing === 'new' ? null : editing}
          onDone={() => setEditing(null)}
        />
      )}

      {news.data.length === 0 ? (
        <Empty>お知らせはまだありません。</Empty>
      ) : (
        <ul className="list">
          {news.data.map(a => (
            <li key={a.id}>
              <button type="button" className="list__item" style={{ width: '100%', background: 'none', border: 0, textAlign: 'left', font: 'inherit', cursor: 'pointer' }} onClick={() => setEditing(a)}>
                <span className="list__body">
                  <span className="row">
                    {a.important && <span className="badge badge--important">重要</span>}
                    <CategoryBadge category={a.category} />
                    <span className="badge">{audienceLabel(a.audience)}</span>
                    {!a.published && <span className="badge badge--draft">下書き</span>}
                  </span>
                  <span className="list__title">{a.title}</span>
                </span>
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

function NewsForm({ original, onDone }: { original: Announcement | null; onDone: () => void }) {
  const [f, setF] = useState<FormState>(original ? {
    title: original.title,
    body: original.body,
    important: original.important,
    category: original.category,
    audience: original.audience,
    published: original.published
  } : EMPTY);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const set = <K extends keyof FormState>(k: K, v: FormState[K]) => setF(prev => ({ ...prev, [k]: v }));

  function toggleValue(v: string) {
    const values = f.audience.values.includes(v) ? f.audience.values.filter(x => x !== v) : [...f.audience.values, v];
    set('audience', { ...f.audience, values });
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (!f.title.trim()) {
      setError('タイトルを入力してください。');
      return;
    }
    if (f.audience.type !== 'all' && f.audience.values.length === 0) {
      setError('対象を1つ以上選んでください。');
      return;
    }
    setSaving(true);
    setError(null);
    const { db } = getServices();
    // 公開した時点の日時を残す（下書き→公開のときに設定。非公開に戻したら消す）
    const publishedAt = f.published ? (original?.publishedAt ?? serverTimestamp()) : null;
    const data = {
      title: f.title.trim().slice(0, 120),
      body: f.body.slice(0, 5000),
      important: f.important,
      category: f.category,
      audience: { type: f.audience.type, values: f.audience.type === 'all' ? [] : f.audience.values },
      published: f.published,
      publishedAt,
      updatedAt: serverTimestamp()
    };
    try {
      if (original) await setDoc(doc(db, 'announcements', original.id), data, { merge: true });
      else await addDoc(collection(db, 'announcements'), { ...data, createdAt: serverTimestamp() });
      onDone();
    } catch {
      setError('保存できませんでした。入力内容を確認してください。');
    } finally {
      setSaving(false);
    }
  }

  async function onDelete() {
    if (!original || !window.confirm('このお知らせを削除しますか？')) return;
    try {
      await deleteDoc(doc(getServices().db, 'announcements', original.id));
      onDone();
    } catch {
      setError('削除できませんでした。');
    }
  }

  return (
    <form className="card" onSubmit={onSubmit}>
      <h3 className="card__title">{original ? 'お知らせを編集' : 'お知らせを作成'}</h3>
      <div className="field">
        <label htmlFor="n-title">タイトル</label>
        <input id="n-title" type="text" maxLength={120} value={f.title} onChange={e => set('title', e.target.value)} required />
      </div>
      <div className="field">
        <label htmlFor="n-body">本文</label>
        <textarea id="n-body" maxLength={5000} value={f.body} onChange={e => set('body', e.target.value)} />
      </div>
      <div className="field">
        <label htmlFor="n-cat">種類</label>
        <select id="n-cat" value={f.category} onChange={e => set('category', e.target.value as AnnouncementCategory)}>
          {(Object.keys(CATEGORY_LABELS) as AnnouncementCategory[]).map(c => <option key={c} value={c}>{CATEGORY_LABELS[c]}</option>)}
        </select>
      </div>
      <fieldset className="field">
        <legend>対象</legend>
        <select aria-label="対象の種類" value={f.audience.type} onChange={e => set('audience', { type: e.target.value as Audience['type'], values: [] })}>
          <option value="all">全員</option>
          <option value="section">セクション（弦楽器・木管など）</option>
          <option value="part">パート（ヴァイオリン・チェロなど）</option>
        </select>
        {f.audience.type !== 'all' && (
          <div className="row" style={{ marginTop: '0.5rem' }}>
            {(f.audience.type === 'section' ? SECTIONS.map(s => ({ id: s.id, label: s.label })) : PARTS.map(p => ({ id: p.part, label: p.label }))).map(o => (
              <label key={o.id} className="checkbox small">
                <input type="checkbox" checked={f.audience.values.includes(o.id)} onChange={() => toggleValue(o.id)} />
                {o.label}
              </label>
            ))}
          </div>
        )}
        <p className="field__hint">対象は団員の画面での絞り込み用です（他の団員も「すべて表示」で見られます）。秘密の連絡には使わないでください。</p>
      </fieldset>
      <label className="checkbox">
        <input type="checkbox" checked={f.important} onChange={e => set('important', e.target.checked)} />
        重要なお知らせ（ホームの一番上に目立つ形で表示）
      </label>
      <label className="checkbox">
        <input type="checkbox" checked={f.published} onChange={e => set('published', e.target.checked)} />
        団員に公開する
      </label>
      <div className="row" style={{ marginTop: '1rem' }}>
        <button className="btn" type="submit" disabled={saving}>保存する</button>
        <button className="btn btn--outline btn--sm" type="button" onClick={onDone}>キャンセル</button>
        {original && <button className="btn btn--danger btn--sm" type="button" onClick={onDelete}>削除</button>}
      </div>
      {error && <p className="alert alert--error" role="alert" style={{ marginTop: '0.75rem' }}>{error}</p>}
    </form>
  );
}
