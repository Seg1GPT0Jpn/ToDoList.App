import { Empty, ErrorNote, Loading, PageTitle } from '../components/Layout';
import { useMembers, useStats } from '../lib/data';
import { partLabel, partOrder } from '../lib/parts';
import type { Member } from '../lib/types';

/** 団員一覧：表示名・楽器・役職表示・自己紹介だけ（連絡先などは表示しない） */
export function MembersPage() {
  const members = useMembers();
  const stats = useStats();

  if (members.loading) return <Loading />;

  const active = members.data.filter(m => m.status !== 'inactive');
  const groups = new Map<string, Member[]>();
  for (const m of active) {
    const list = groups.get(m.part) ?? [];
    list.push(m);
    groups.set(m.part, list);
  }
  const parts = [...groups.keys()].sort((a, b) => partOrder(a) - partOrder(b));

  return (
    <div>
      <PageTitle en="Members">団員</PageTitle>
      <ErrorNote message={members.error} />
      <p className="muted small">
        現在 {stats.data?.memberCount ?? active.length} 人の団員が在籍しています。
        連絡先などの個人情報は表示されません。
      </p>

      {parts.length === 0 && <Empty>団員はまだ登録されていません。</Empty>}

      {parts.map(part => (
        <section key={part} className="roster-part" aria-label={partLabel(part)}>
          <h3>
            {partLabel(part)}
            <span className="badge">{groups.get(part)!.length}人</span>
          </h3>
          <ul className="roster">
            {groups.get(part)!
              .sort((a, b) => a.displayName.localeCompare(b.displayName, 'ja'))
              .map(m => (
                <li key={m.id}>
                  <span className="roster__name">{m.displayName}</span>{' '}
                  <span className="small muted">{m.instrumentLabel}</span>
                  {m.roleLabel && <> <span className="badge badge--navy">{m.roleLabel}</span></>}
                  {m.status === 'paused' && <> <span className="badge badge--draft">休止中</span></>}
                  {m.bio && <p className="small pre" style={{ marginTop: '0.3rem' }}>{m.bio}</p>}
                </li>
              ))}
          </ul>
        </section>
      ))}
    </div>
  );
}
