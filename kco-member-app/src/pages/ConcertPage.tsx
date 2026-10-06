import { Empty, ErrorNote, Loading, PageTitle } from '../components/Layout';
import { useConcerts } from '../lib/data';
import { formatDateJa, orTbd } from '../lib/dates';

export function ConcertPage() {
  const concerts = useConcerts();

  if (concerts.loading) return <Loading />;

  return (
    <div>
      <PageTitle en="Concert">演奏会</PageTitle>
      <ErrorNote message={concerts.error} />
      {concerts.data.length === 0 && <Empty>演奏会の情報は準備中です。</Empty>}
      <div className="stack">
        {concerts.data.map(c => (
          <article key={c.id} className="card">
            <h2 className="card__title">{c.title}</h2>
            <dl className="info">
              <div className="info__row"><dt>開催日</dt><dd className={c.date ? '' : 'tbd'}>{formatDateJa(c.date)}</dd></div>
              <div className="info__row"><dt>会場</dt><dd className={c.venue ? '' : 'tbd'}>{orTbd(c.venue)}</dd></div>
              <div className="info__row"><dt>開場</dt><dd className={c.openTime ? '' : 'tbd'}>{orTbd(c.openTime)}</dd></div>
              <div className="info__row"><dt>開演</dt><dd className={c.startTime ? '' : 'tbd'}>{orTbd(c.startTime)}</dd></div>
            </dl>

            <h3 style={{ marginTop: '1.25rem' }}>曲目</h3>
            {c.program.length ? (
              <ul className="list">
                {c.program.map((p, i) => (
                  <li key={i} className="list__item">
                    <span className="list__body">
                      {p.label && <span className="small muted">{p.label}<br /></span>}
                      <span className="list__title">{p.composer}{p.composer && p.work ? '：' : ''}{p.work}</span>
                    </span>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="tbd">未定</p>
            )}

            <h3 style={{ marginTop: '1.25rem' }}>出演者</h3>
            <p className={`pre ${c.performers ? '' : 'tbd'}`}>{orTbd(c.performers)}</p>

            {c.daySchedule && (
              <>
                <h3 style={{ marginTop: '1.25rem' }}>当日のスケジュール</h3>
                <p className="pre">{c.daySchedule}</p>
              </>
            )}

            {c.notes && (
              <>
                <h3 style={{ marginTop: '1.25rem' }}>注意事項</h3>
                <p className="pre">{c.notes}</p>
              </>
            )}
          </article>
        ))}
      </div>
    </div>
  );
}
