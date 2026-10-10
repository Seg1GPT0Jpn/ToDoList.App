import { Link } from 'react-router-dom';
import { useCampaign } from '../lib/data';
import { normalizeHashtags } from '../lib/campaign';
import { OFFICIAL_RECRUIT, OFFICIAL_SITE } from '../lib/links';

/*
 * 団員募集ページ（一般公開・ログイン不要）
 * 募集カードの QR コード・LINE のリンクからここに来る。
 * 表示するのは運営が「募集キャンペーン」で入力した内容だけ（個人情報なし）。
 */
export function JoinPage() {
  const campaign = useCampaign();
  const c = campaign.data;
  const urgent = c?.parts.filter(p => p.level === 'urgent') ?? [];
  const wanted = c?.parts.filter(p => p.level === 'wanted') ?? [];

  return (
    <div className="join">
      <header className="join__hero">
        <p className="join__en">KANAGAWA CONNECT ORCHESTRA</p>
        <p className="join__org">かながわコネクトオーケストラ</p>
        <h1 className="join__title">{c?.active ? c.headline : '団員募集'}</h1>
      </header>

      <main className="join__body">
        {campaign.loading && <p className="muted" role="status">読み込み中…</p>}

        {!campaign.loading && (!c || !c.active) && (
          <div className="card">
            <p>現在、このページでの募集は行っていません。</p>
            <p className="small muted">最新の情報は公式サイト・SNS をご確認ください。</p>
          </div>
        )}

        {c?.active && (
          <div className="stack">
            {c.message && <p className="join__message pre">{c.message}</p>}

            {urgent.length > 0 && (
              <section className="card">
                <h2 className="card__title">急募のパート</h2>
                <div className="row">
                  {urgent.map(p => <span key={p.part} className="chip chip--gold">{p.label}</span>)}
                </div>
              </section>
            )}
            {wanted.length > 0 && (
              <section className="card">
                <h2 className="card__title">募集中のパート</h2>
                <div className="row">
                  {wanted.map(p => <span key={p.part} className="chip">{p.label}</span>)}
                </div>
              </section>
            )}
            {!urgent.length && !wanted.length && (
              <section className="card"><p>全パートで団員を募集しています。</p></section>
            )}

            {(c.showMemberCount && c.targetMembers > 0) || c.deadlineText ? (
              <dl className="info card">
                {c.showMemberCount && c.targetMembers > 0 && (
                  <div className="info__row"><dt>団員数</dt><dd>現在 {c.memberCount}人 ／ 目標 {c.targetMembers}人</dd></div>
                )}
                {c.deadlineText && <div className="info__row"><dt>締切</dt><dd>{c.deadlineText}</dd></div>}
              </dl>
            ) : null}

            {c.formUrl ? (
              <a className="btn btn--gold join__cta" href={c.formUrl} target="_blank" rel="noopener noreferrer">応募フォームを開く</a>
            ) : (
              <p className="alert alert--info">応募フォームは準備中です。公開までしばらくお待ちください。</p>
            )}

            {normalizeHashtags(c.hashtags).length > 0 && (
              <p className="small muted">{normalizeHashtags(c.hashtags).join(' ')}</p>
            )}
          </div>
        )}

        <p className="small join__member-link">
          活動内容・募集要項は <a href={OFFICIAL_RECRUIT} target="_blank" rel="noopener noreferrer">公式サイトの団員募集ページ</a>（<a href={OFFICIAL_SITE} target="_blank" rel="noopener noreferrer">公式サイト</a>）
        </p>
        <p className="small join__member-link" style={{ marginTop: '0.5rem' }}>
          団員の方は <Link to="/">団員ページにログイン</Link>
        </p>
      </main>
    </div>
  );
}
