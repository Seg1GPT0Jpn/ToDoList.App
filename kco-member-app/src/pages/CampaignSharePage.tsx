import { useEffect, useMemo, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../auth/AuthProvider';
import { CARD_SIZES, canvasToBlob, renderCard, type CardFormat } from '../campaign/card';
import { ErrorNote, Loading, PageTitle } from '../components/Layout';
import { lineShareUrl, shareText, xShareUrl } from '../lib/campaign';
import { useCampaign } from '../lib/data';

export function joinUrl(): string {
  return `${window.location.origin}/join`;
}

/** 団員募集カードを作って、インスタ・LINE などでシェアする（団員みんなが使える） */
export function CampaignSharePage() {
  const { isStaff } = useAuth();
  const campaign = useCampaign();
  const [format, setFormat] = useState<CardFormat>('post');
  const [image, setImage] = useState<{ url: string; blob: Blob } | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const urlRef = useRef<string | null>(null);

  const c = campaign.data;
  const text = useMemo(() => (c ? shareText(c, joinUrl()) : ''), [c]);

  useEffect(() => {
    if (!c?.active) return;
    let cancelled = false;
    setError(null);
    renderCard(c, joinUrl(), format)
      .then(canvasToBlob)
      .then(blob => {
        if (cancelled) return;
        if (urlRef.current) URL.revokeObjectURL(urlRef.current);
        const url = URL.createObjectURL(blob);
        urlRef.current = url;
        setImage({ url, blob });
      })
      .catch(() => !cancelled && setError('画像を作成できませんでした。別のブラウザでお試しください。'));
    return () => {
      cancelled = true;
    };
  }, [c, format]);

  useEffect(() => () => {
    if (urlRef.current) URL.revokeObjectURL(urlRef.current);
  }, []);

  if (campaign.loading) return <Loading />;

  if (!c?.active) {
    return (
      <div className="stack">
        <PageTitle en="Recruit">団員募集をシェア</PageTitle>
        <p className="alert alert--info">現在、募集キャンペーンは行っていません。</p>
        {isStaff && <Link className="btn btn--outline" to="/admin/campaign">募集キャンペーンを設定する</Link>}
      </div>
    );
  }

  const fileName = `kco-recruit-${format}.png`;
  const file = image ? new File([image.blob], fileName, { type: 'image/png' }) : null;
  const canShareFile = !!file && typeof navigator !== 'undefined' && !!navigator.canShare && navigator.canShare({ files: [file] });

  async function shareImage() {
    if (!file) return;
    setNotice(null);
    try {
      await navigator.share({ files: [file], text });
    } catch (e) {
      if ((e as { name?: string }).name !== 'AbortError') setError('シェアできませんでした。「画像を保存」してから各アプリで投稿してください。');
    }
  }

  async function copyText() {
    try {
      await navigator.clipboard.writeText(text);
      setNotice('文章をコピーしました。');
    } catch {
      setError('コピーできませんでした。');
    }
  }

  return (
    <div className="stack">
      <PageTitle en="Recruit">団員募集をシェア</PageTitle>
      <p className="small muted">
        募集カードをインスタや LINE で友だちに届けて、仲間を増やしましょう。
        カードの QR コードは募集ページ（応募フォームへの入口）につながっています。
      </p>

      <div className="segmented" role="group" aria-label="画像のサイズ">
        {(Object.keys(CARD_SIZES) as CardFormat[]).map(f => (
          <button key={f} type="button" className={format === f ? 'active' : undefined} aria-pressed={format === f} onClick={() => setFormat(f)}>
            {CARD_SIZES[f].label}
          </button>
        ))}
      </div>

      <div className={`card-preview card-preview--${format}`}>
        {image ? <img src={image.url} alt={`団員募集カード：${c.headline}`} /> : <p className="muted small" role="status">画像を作成中…</p>}
      </div>

      <ErrorNote message={error} />
      {notice && <p className="alert alert--ok" role="status">{notice}</p>}

      <div className="share-buttons">
        {canShareFile && (
          <button type="button" className="btn btn--gold" onClick={shareImage}>画像をシェア（インスタ・LINE など）</button>
        )}
        {image && (
          <a className="btn btn--outline" href={image.url} download={fileName}>画像を保存</a>
        )}
        <a className="btn btn--line" href={lineShareUrl(text)} target="_blank" rel="noopener noreferrer">LINE で送る（文章とリンク）</a>
        <a className="btn btn--outline" href={xShareUrl(text)} target="_blank" rel="noopener noreferrer">X でポスト</a>
        <button type="button" className="btn btn--outline" onClick={copyText}>文章をコピー</button>
      </div>

      <details className="card">
        <summary>インスタグラムに載せるには</summary>
        <ol className="small">
          <li>「画像をシェア」→ Instagram を選ぶ（または「画像を保存」してからインスタで投稿）</li>
          <li>ストーリーズでは「リンク」スタンプに <strong>{joinUrl()}</strong> を貼ると、押せるリンクになります</li>
          <li>投稿の本文には「文章をコピー」した内容を貼り付けてください</li>
        </ol>
      </details>

      <details className="card">
        <summary>シェアする文章</summary>
        <p className="small pre">{text}</p>
      </details>
    </div>
  );
}
