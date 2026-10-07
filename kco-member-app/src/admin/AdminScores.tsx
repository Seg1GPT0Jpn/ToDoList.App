import { useState, type FormEvent } from 'react';
import { collection, deleteDoc, doc, serverTimestamp, setDoc } from 'firebase/firestore';
import { Empty, ErrorNote, Loading } from '../components/Layout';
import { getServices, getStorageService } from '../firebase';
import { useScores } from '../lib/data';
import { queueNotification } from '../lib/notify';
import { PARTS } from '../lib/parts';
import { SCORE_ACCEPT, checkScoreFile, isHttpsUrl, safeFileName, scorePartsLabel } from '../lib/scores';
import type { Score } from '../lib/types';
import { openScore } from '../pages/ScoresPage';

export function AdminScores() {
  const scores = useScores('', true);
  const [editing, setEditing] = useState<Score | 'new' | null>(null);

  if (scores.loading) return <Loading />;

  return (
    <div className="stack">
      <div className="row">
        <h2 style={{ margin: 0 }}>楽譜の配布</h2>
        <span className="spacer" />
        {!editing && <button className="btn btn--sm" type="button" onClick={() => setEditing('new')}>＋ 楽譜を登録</button>}
      </div>
      <p className="small muted">対象パートの団員だけが見られます（データベースのルールで制限しています）。</p>
      <ErrorNote message={scores.error} />
      {editing && <ScoreForm key={editing === 'new' ? 'new' : editing.id} original={editing === 'new' ? null : editing} onDone={() => setEditing(null)} />}
      {scores.data.length === 0 ? (
        <Empty>登録された楽譜はありません。</Empty>
      ) : (
        <ul className="list">
          {scores.data.map(s => (
            <li key={s.id}>
              <button type="button" className="list__item list__button" onClick={() => setEditing(s)}>
                <span className="list__body">
                  <span className="row" style={{ gap: '0.35rem' }}>
                    <span className="badge">{scorePartsLabel(s.parts)}</span>
                    <span className="badge">{s.kind === 'file' ? 'ファイル' : 'リンク'}</span>
                    {!s.published && <span className="badge badge--draft">非公開</span>}
                  </span>
                  <span className="list__title">{s.title}</span>
                </span>
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

function ScoreForm({ original, onDone }: { original: Score | null; onDone: () => void }) {
  const [title, setTitle] = useState(original?.title ?? '');
  const [composer, setComposer] = useState(original?.composer ?? '');
  const [note, setNote] = useState(original?.note ?? '');
  const [parts, setParts] = useState<string[]>(original?.parts ?? ['all']);
  const [kind, setKind] = useState<Score['kind']>(original?.kind ?? 'file');
  const [url, setUrl] = useState(original?.url ?? '');
  const [file, setFile] = useState<File | null>(null);
  const [published, setPublished] = useState(original?.published ?? true);
  const [notify, setNotify] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const forAll = parts.includes('all');
  const togglePart = (p: string) => setParts(prev => (prev.includes(p) ? prev.filter(x => x !== p) : [...prev.filter(x => x !== 'all'), p]));

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    if (!title.trim()) return setError('曲名・タイトルを入力してください。');
    if (!parts.length) return setError('対象のパートを選んでください。');
    if (kind === 'link' && !isHttpsUrl(url.trim())) return setError('リンクは https:// から始まる URL を入力してください。');
    if (kind === 'file' && !file && !original?.storagePath) return setError('ファイルを選んでください。');
    if (file) {
      const problem = checkScoreFile(file);
      if (problem) return setError(problem);
    }

    setSaving(true);
    const { db } = getServices();
    const ref = original ? doc(db, 'scores', original.id) : doc(collection(db, 'scores'));
    try {
      let storagePath = original?.storagePath ?? '';
      let fileName = original?.fileName ?? '';
      if (kind === 'file' && file) {
        const storage = await getStorageService();
        if (!storage) throw new Error('storage-disabled');
        const { ref: sref, uploadBytes, deleteObject } = await import('firebase/storage');
        fileName = safeFileName(file.name);
        const newPath = `scores/${ref.id}/${Date.now()}-${fileName}`;
        await uploadBytes(sref(storage, newPath), file, { contentType: file.type });
        if (storagePath && storagePath !== newPath) await deleteObject(sref(storage, storagePath)).catch(() => undefined);
        storagePath = newPath;
      }
      const data: Record<string, unknown> = {
        title: title.trim().slice(0, 120),
        composer: composer.trim().slice(0, 100),
        note: note.slice(0, 1000),
        parts: forAll ? ['all'] : parts.slice(0, 20),
        kind,
        url: kind === 'link' ? url.trim() : '',
        storagePath: kind === 'file' ? storagePath : '',
        fileName: kind === 'file' ? fileName : '',
        published,
        updatedAt: serverTimestamp()
      };
      if (kind === 'link') {
        delete data.storagePath;
      } else {
        delete data.url;
      }
      if (original) await setDoc(ref, { ...data, createdAt: original.createdAt }, { merge: false });
      else await setDoc(ref, { ...data, createdAt: serverTimestamp() });
      if (notify && published) {
        await queueNotification({
          title: `楽譜：${data.title as string}`,
          body: '新しい楽譜を配布しました。',
          url: '/scores',
          audience: forAll ? { type: 'all', values: [] } : { type: 'part', values: parts.slice(0, 20) },
          source: 'score'
        }).catch(() => undefined);
      }
      onDone();
    } catch (err) {
      setError((err as Error).message === 'storage-disabled' || (err as { code?: string }).code === 'storage/unknown'
        ? 'ファイルのアップロードには Firebase の Storage の有効化が必要です（README 参照）。Google ドライブなどのリンクでも登録できます。'
        : '保存できませんでした。ファイルの種類・サイズを確認してください。');
    } finally {
      setSaving(false);
    }
  }

  async function onDelete() {
    if (!original || !window.confirm('この楽譜を削除しますか？（アップロードしたファイルも削除されます）')) return;
    try {
      if (original.storagePath) {
        const storage = await getStorageService();
        if (storage) {
          const { ref: sref, deleteObject } = await import('firebase/storage');
          await deleteObject(sref(storage, original.storagePath)).catch(() => undefined);
        }
      }
      await deleteDoc(doc(getServices().db, 'scores', original.id));
      onDone();
    } catch {
      setError('削除できませんでした。');
    }
  }

  return (
    <form className="card stack" onSubmit={onSubmit}>
      <h3 className="card__title">{original ? '楽譜を編集' : '楽譜を登録'}</h3>
      <div className="field">
        <label htmlFor="sc-title">曲名・タイトル</label>
        <input id="sc-title" type="text" maxLength={120} value={title} onChange={e => setTitle(e.target.value)} required />
      </div>
      <div className="field">
        <label htmlFor="sc-comp">作曲者（任意）</label>
        <input id="sc-comp" type="text" maxLength={100} value={composer} onChange={e => setComposer(e.target.value)} />
      </div>
      <div className="field">
        <label htmlFor="sc-note">メモ（任意）</label>
        <textarea id="sc-note" maxLength={1000} value={note} onChange={e => setNote(e.target.value)} placeholder="例：練習番号A〜Dを次回までに" />
      </div>
      <fieldset className="field">
        <legend>対象のパート</legend>
        <label className="checkbox"><input type="checkbox" checked={forAll} onChange={() => setParts(forAll ? [] : ['all'])} />全員（スコア・全体の資料など）</label>
        {!forAll && (
          <div className="row">
            {PARTS.map(p => (
              <label key={p.part} className="checkbox small">
                <input type="checkbox" checked={parts.includes(p.part)} onChange={() => togglePart(p.part)} />{p.label}
              </label>
            ))}
          </div>
        )}
      </fieldset>
      <fieldset className="field">
        <legend>楽譜の渡し方</legend>
        <label className="checkbox"><input type="radio" name="kind" checked={kind === 'file'} onChange={() => setKind('file')} />ファイルをアップロード（PDF・画像、30MBまで）</label>
        <label className="checkbox"><input type="radio" name="kind" checked={kind === 'link'} onChange={() => setKind('link')} />リンク（Google ドライブなど）</label>
      </fieldset>
      {kind === 'file' ? (
        <div className="field">
          <label htmlFor="sc-file">ファイル{original?.fileName && `（いま：${original.fileName}）`}</label>
          <input id="sc-file" type="file" accept={SCORE_ACCEPT} onChange={e => setFile(e.target.files?.[0] ?? null)} />
        </div>
      ) : (
        <div className="field">
          <label htmlFor="sc-url">リンク</label>
          <input id="sc-url" type="url" maxLength={1000} value={url} onChange={e => setUrl(e.target.value)} placeholder="https://drive.google.com/..." />
          <p className="field__hint">リンクの場合、リンク先の共有設定によっては団員以外も開けます。ドライブでは「特定のユーザー」に限定するのが安全です。</p>
        </div>
      )}
      <label className="checkbox"><input type="checkbox" checked={published} onChange={e => setPublished(e.target.checked)} />団員に公開する</label>
      {published && (
        <label className="checkbox"><input type="checkbox" checked={notify} onChange={e => setNotify(e.target.checked)} />保存したら対象パートにプッシュ通知を送る</label>
      )}
      <div className="row">
        <button className="btn" type="submit" disabled={saving}>{saving ? '保存中…' : '保存する'}</button>
        <button className="btn btn--outline btn--sm" type="button" onClick={onDone}>キャンセル</button>
        {original && <button className="btn btn--outline btn--sm" type="button" onClick={() => openScore(original).catch(() => setError('開けませんでした。'))}>開いて確認</button>}
        {original && <button className="btn btn--danger btn--sm" type="button" onClick={onDelete}>削除</button>}
      </div>
      {error && <p className="alert alert--error" role="alert">{error}</p>}
    </form>
  );
}
