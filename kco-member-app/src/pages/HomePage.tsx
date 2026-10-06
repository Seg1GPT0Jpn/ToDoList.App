import { Link } from 'react-router-dom';
import { useAuth } from '../auth/AuthProvider';
import { AttendanceBadge, CategoryBadge } from '../components/Badges';
import { ErrorNote, Loading } from '../components/Layout';
import { useAnnouncements, useConcerts, useMember, useMyAttendance, useRehearsals, useStats } from '../lib/data';
import { formatDateJa, formatTimeRange, orTbd, splitByDate, todayJst } from '../lib/dates';
import { isForMe } from '../lib/parts';

export function HomePage() {
  const { access } = useAuth();
  const stats = useStats();
  const me = useMember(access?.memberId ?? null);
  const rehearsals = useRehearsals();
  const concerts = useConcerts();
  const news = useAnnouncements();

  const today = todayJst();
  const next = splitByDate(rehearsals.data, today).upcoming[0] ?? null;
  const myAttendance = useMyAttendance(next?.id, access?.memberId ?? null);
  const concert = concerts.data[0] ?? null;

  const myPart = me.data?.part ?? null;
  const visibleNews = news.data.filter(a => isForMe(a.audience, myPart));
  const important = visibleNews.filter(a => a.important).slice(0, 3);
  const latest = visibleNews.filter(a => !a.important).slice(0, 3);

  if (stats.loading && rehearsals.loading) return <Loading />;

  const count = stats.data?.memberCount ?? 0;
  const target = stats.data?.targetMembers ?? 80;
  const percent = target > 0 ? Math.min(100, Math.round((count / target) * 100)) : 0;

  return (
    <div className="stack">
      <p className="muted small">
        {me.data ? <>こんにちは、<strong>{me.data.displayName}</strong> さん</> : 'ようこそ'}
      </p>

      <ErrorNote message={stats.error || rehearsals.error || news.error} />

      {important.map(a => (
        <Link key={a.id} to={`/news#${a.id}`} className="card-link">
          <div className="card card--important">
            <div className="row">
              <span className="badge badge--important">重要</span>
              <CategoryBadge category={a.category} />
            </div>
            <p className="list__title" style={{ marginTop: '0.4rem' }}>{a.title}</p>
          </div>
        </Link>
      ))}

      <div className="home-grid">
        <section className="card card--navy span-2" aria-labelledby="count-title">
          <p className="card__eyebrow" id="count-title">現在の団員数</p>
          <p className="member-count" aria-label={`現在の団員数 ${count}人、目標 ${target}人`}>
            <span className="member-count__num">{count}</span>
            <span className="member-count__target">/ {target}</span>
            <span className="member-count__unit">人</span>
          </p>
          <div className="progress" aria-hidden="true">
            <div className="progress__bar" style={{ width: `${percent}%` }} />
          </div>
          <p className="small muted" style={{ marginTop: '0.5rem' }}>
            目標まであと {Math.max(target - count, 0)} 人。一緒にオーケストラをつくっていきましょう。
          </p>
        </section>

        <section className="card" aria-labelledby="next-title">
          <p className="card__eyebrow">Next Rehearsal</p>
          <h2 className="card__title" id="next-title">次回練習</h2>
          {next ? (
            <div className="stack">
              <p className="big-date">{formatDateJa(next.date)}</p>
              <dl className="info">
                <div className="info__row"><dt>時間</dt><dd>{formatTimeRange(next.startTime, next.endTime)}</dd></div>
                <div className="info__row"><dt>会場</dt><dd className={next.venue ? '' : 'tbd'}>{orTbd(next.venue)}</dd></div>
              </dl>
              <div className="row">
                <span className="small">あなたの出欠：</span>
                <AttendanceBadge status={myAttendance.data?.status} />
                <span className="spacer" />
                <Link className="btn btn--sm btn--outline" to={`/schedule/${next.id}`}>詳細・出欠</Link>
              </div>
            </div>
          ) : (
            <p className="muted">次回の練習日程は未定です。決まり次第お知らせします。</p>
          )}
        </section>

        <section className="card" aria-labelledby="concert-title">
          <p className="card__eyebrow">Concert</p>
          <h2 className="card__title" id="concert-title">{concert?.title || '第1回演奏会'}</h2>
          {concert ? (
            <div className="stack">
              <dl className="info">
                <div className="info__row"><dt>日時</dt><dd className={concert.date ? '' : 'tbd'}>{formatDateJa(concert.date)}</dd></div>
                <div className="info__row"><dt>会場</dt><dd className={concert.venue ? '' : 'tbd'}>{orTbd(concert.venue)}</dd></div>
              </dl>
              {concert.program[0] && (
                <p className="small">
                  {concert.program[0].label && <span className="muted">{concert.program[0].label}：</span>}
                  {concert.program[0].composer} {concert.program[0].work}
                </p>
              )}
              <Link className="btn btn--sm btn--outline" to="/concert">演奏会の詳細</Link>
            </div>
          ) : (
            <p className="muted">演奏会の情報は準備中です。</p>
          )}
        </section>
      </div>

      <section aria-labelledby="news-title">
        <div className="section-heading">
          <h2 id="news-title">最新のお知らせ</h2>
          <span className="spacer" />
          <Link className="small" to="/news">すべて見る</Link>
        </div>
        {latest.length ? (
          <ul className="list">
            {latest.map(a => (
              <li key={a.id}>
                <Link className="list__item" to={`/news#${a.id}`}>
                  <div className="list__body">
                    <CategoryBadge category={a.category} />
                    <p className="list__title">{a.title}</p>
                  </div>
                </Link>
              </li>
            ))}
          </ul>
        ) : (
          <p className="empty">新しいお知らせはありません。</p>
        )}
      </section>

      {stats.data && stats.data.byPart.length > 0 && (
        <section aria-labelledby="parts-title">
          <div className="section-heading">
            <h2 id="parts-title">パート編成</h2>
            <span className="spacer" />
            <Link className="small" to="/members">団員一覧</Link>
          </div>
          <div className="part-grid">
            {stats.data.byPart.map(p => (
              <div key={p.part} className="part-chip">
                <span className="part-chip__name">{p.label}</span>
                <span className="part-chip__count">{p.count}</span>
              </div>
            ))}
          </div>
        </section>
      )}
    </div>
  );
}
