import { useAuth } from '../auth/AuthProvider';
import { ErrorNote, Loading } from '../components/Layout';
import { useAdminStats, useStats } from '../lib/data';

function formatUpdated(ts: { toDate(): Date } | undefined): string {
  if (!ts) return '未同期';
  return new Intl.DateTimeFormat('ja-JP', { timeZone: 'Asia/Tokyo', month: 'numeric', day: 'numeric', hour: '2-digit', minute: '2-digit' }).format(ts.toDate());
}

export function AdminDashboard() {
  const { isAdmin } = useAuth();
  const stats = useStats();
  const admin = useAdminStats(isAdmin);

  if (stats.loading) return <Loading />;

  const s = stats.data;
  const a = admin.data;

  return (
    <div className="stack">
      <ErrorNote message={stats.error || admin.error} />

      <div className="stat-tiles">
        {isAdmin && (
          <div className="stat-tile">
            <p className="stat-tile__label">参加希望者（応募）</p>
            <p className="stat-tile__value">{a?.applicantCount ?? '—'}</p>
          </div>
        )}
        <div className="stat-tile">
          <p className="stat-tile__label">加入確定（団員）</p>
          <p className="stat-tile__value">{s?.memberCount ?? 0}</p>
        </div>
        <div className="stat-tile">
          <p className="stat-tile__label">アプリ登録の参加希望者</p>
          <p className="stat-tile__value">{s?.applicantCount ?? 0}</p>
        </div>
        <div className="stat-tile">
          <p className="stat-tile__label">目標</p>
          <p className="stat-tile__value">{s?.targetMembers ?? 80}</p>
        </div>
        {s?.decisionMembers ? (
          <div className="stat-tile">
            <p className="stat-tile__label">演奏会開催判断</p>
            <p className="stat-tile__value">{s.decisionMembers}</p>
          </div>
        ) : null}
      </div>
      <p className="small muted">最終同期：{formatUpdated(s?.updatedAt)}（スプレッドシートの「団員アプリへ同期」で更新されます）</p>

      {isAdmin && a && Object.keys(a.statusCounts).length > 0 && (
        <section className="card">
          <h2 className="card__title">応募者の対応状況（スプレッドシート）</h2>
          <div className="table-wrap">
            <table className="table">
              <tbody>
                {Object.entries(a.statusCounts).map(([k, v]) => (
                  <tr key={k}><th scope="row">{k}</th><td className="num">{v}人</td></tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      )}

      <section className="card">
        <h2 className="card__title">パート別 加入確定人数</h2>
        {s && s.byPart.length ? (
          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr><th>パート</th><th className="num">現在</th><th className="num">目標</th><th className="num">最低</th><th className="num">不足（最低まで）</th></tr>
              </thead>
              <tbody>
                {s.byPart.map(p => {
                  const short = p.min != null ? Math.max(p.min - p.count, 0) : null;
                  return (
                    <tr key={p.part} className={short ? 'is-short' : undefined}>
                      <th scope="row">{p.label}</th>
                      <td className="num">{p.count}</td>
                      <td className="num">{p.target ?? '—'}</td>
                      <td className="num">{p.min ?? '—'}</td>
                      <td className="num">{short == null ? '—' : short === 0 ? '充足' : short}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        ) : (
          <p className="muted">まだ同期されていません。</p>
        )}
      </section>

      <p className="alert alert--info small">
        加入ステータス・楽器・権限の変更は、スプレッドシート（応募者一覧）で行い、「団員アプリへ同期」を実行してください。
        アプリ側からは変更できない仕組みになっています（誤操作・なりすまし防止のため）。
      </p>
    </div>
  );
}
