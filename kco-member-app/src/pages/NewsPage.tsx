import { useEffect, useState } from 'react';
import { useAuth } from '../auth/AuthProvider';
import { CategoryBadge } from '../components/Badges';
import { Empty, ErrorNote, Loading, PageTitle } from '../components/Layout';
import { useAnnouncements, useMember } from '../lib/data';
import { audienceLabel, isForMe } from '../lib/parts';

function formatPublished(ts: { toDate(): Date } | null): string {
  if (!ts) return '';
  return new Intl.DateTimeFormat('ja-JP', { timeZone: 'Asia/Tokyo', year: 'numeric', month: 'numeric', day: 'numeric' }).format(ts.toDate());
}

export function NewsPage() {
  const { access } = useAuth();
  const me = useMember(access?.memberId ?? null);
  const news = useAnnouncements();
  const [onlyMine, setOnlyMine] = useState(true);

  useEffect(() => {
    if (!news.loading && window.location.hash) {
      document.getElementById(window.location.hash.slice(1))?.scrollIntoView({ block: 'start' });
    }
  }, [news.loading]);

  if (news.loading) return <Loading />;

  const myPart = me.data?.part ?? null;
  const items = onlyMine ? news.data.filter(a => isForMe(a.audience, myPart)) : news.data;
  const sorted = [...items.filter(a => a.important), ...items.filter(a => !a.important)];

  return (
    <div>
      <PageTitle en="News">お知らせ</PageTitle>
      <ErrorNote message={news.error} />
      <label className="checkbox small">
        <input type="checkbox" checked={onlyMine} onChange={e => setOnlyMine(e.target.checked)} />
        自分のパート向けと全員向けだけ表示
      </label>

      {sorted.length === 0 ? (
        <Empty>お知らせはまだありません。</Empty>
      ) : (
        <div className="stack" style={{ marginTop: '0.75rem' }}>
          {sorted.map(a => (
            <article key={a.id} id={a.id} className={`card${a.important ? ' card--important' : ''}`}>
              <div className="row">
                {a.important && <span className="badge badge--important">重要</span>}
                <CategoryBadge category={a.category} />
                <span className="badge">{audienceLabel(a.audience)}</span>
                <span className="spacer" />
                <span className="small muted">{formatPublished(a.publishedAt)}</span>
              </div>
              <h2 style={{ marginTop: '0.5rem' }}>{a.title}</h2>
              <p className="pre">{a.body}</p>
            </article>
          ))}
        </div>
      )}
    </div>
  );
}
