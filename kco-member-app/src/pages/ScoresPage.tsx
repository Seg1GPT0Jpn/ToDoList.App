import { useState } from 'react';
import { useAuth } from '../auth/AuthProvider';
import { Empty, ErrorNote, Loading, PageTitle } from '../components/Layout';
import { getStorageService } from '../firebase';
import { useScores } from '../lib/data';
import { partLabel } from '../lib/parts';
import { scorePartsLabel } from '../lib/scores';
import type { Score } from '../lib/types';

/**
 * 楽譜を開く。
 * ファイルは Storage のルールで「対象パートの団員だけ」に制限したうえで取得する。
 */
export async function openScore(score: Score): Promise<void> {
  if (score.kind === 'link') {
    window.open(score.url, '_blank', 'noopener,noreferrer');
    return;
  }
  // 先に新しいタブを開いておく（待ち時間のあとに開くとポップアップとしてブロックされるため）
  const win = window.open('', '_blank');
  try {
    const storage = await getStorageService();
    if (!storage) throw new Error('storage-disabled');
    const { ref, getBlob, getDownloadURL } = await import('firebase/storage');
    const r = ref(storage, score.storagePath);
    let url: string;
    try {
      url = URL.createObjectURL(await getBlob(r));
      setTimeout(() => URL.revokeObjectURL(url), 10 * 60 * 1000);
    } catch (e) {
      // ブラウザから直接取得できない設定（CORS 未設定）のときはダウンロード用 URL で開く
      if ((e as { code?: string }).code === 'storage/unauthorized' || (e as { code?: string }).code === 'storage/object-not-found') throw e;
      url = await getDownloadURL(r);
    }
    if (win) win.location.href = url;
    else window.location.href = url;
  } catch (e) {
    win?.close();
    throw e;
  }
}

export function ScoresPage() {
  const { access, isStaff } = useAuth();
  const myPart = access?.part ?? '';
  const scores = useScores(myPart, isStaff);
  const [error, setError] = useState<string | null>(null);

  if (scores.loading) return <Loading />;

  async function onOpen(s: Score) {
    setError(null);
    try {
      await openScore(s);
    } catch {
      setError('楽譜を開けませんでした。時間をおいて再度お試しください。');
    }
  }

  return (
    <div className="stack">
      <PageTitle en="Scores">楽譜</PageTitle>
      <p className="small muted">
        {myPart ? <>あなたのパート（<strong>{partLabel(myPart)}</strong>）と全員向けの楽譜が表示されます。</> : '全員向けの楽譜が表示されます。'}
        楽譜は団員以外に転送しないでください。
      </p>
      <ErrorNote message={scores.error || error} />
      {scores.data.length === 0 ? (
        <Empty>配布中の楽譜はまだありません。</Empty>
      ) : (
        <ul className="list">
          {scores.data.map(s => (
            <li key={s.id}>
              <button type="button" className="list__item list__button" onClick={() => onOpen(s)}>
                <span className="list__body">
                  <span className="row" style={{ gap: '0.35rem' }}>
                    <span className="badge">{scorePartsLabel(s.parts)}</span>
                    {s.kind === 'link' && <span className="badge">リンク</span>}
                    {!s.published && <span className="badge badge--draft">非公開</span>}
                  </span>
                  <span className="list__title">{s.title}</span>
                  {s.composer && <span className="small muted">{s.composer}</span>}
                  {s.note && <span className="small pre">{s.note}</span>}
                </span>
                <span className="list__action" aria-hidden="true">開く ›</span>
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
