import { Link } from 'react-router-dom';
import { PageTitle } from '../components/Layout';
import { useCampaign } from '../lib/data';
import { SurveyList } from './SurveyPages';

/** 「みんなで」：アンケート・提案・団員募集のシェアなど、団員が参加する機能のまとめ */
export function TogetherPage() {
  const campaign = useCampaign();
  return (
    <div className="stack">
      <PageTitle en="Together">みんなで</PageTitle>
      <p className="small muted">オーケストラは団員みんなでつくるもの。意見やアイデアを気軽に届けてください。</p>

      <div className="tile-grid">
        <Link className="tile" to="/proposals">
          <span className="tile__icon" aria-hidden="true">💡</span>
          <span className="tile__title">提案する・見る</span>
          <span className="tile__desc">やりたい曲、練習のアイデアなど</span>
        </Link>
        {campaign.data?.active && (
          <Link className="tile tile--gold" to="/campaign">
            <span className="tile__icon" aria-hidden="true">📣</span>
            <span className="tile__title">団員募集をシェア</span>
            <span className="tile__desc">インスタ・LINE で仲間を誘う</span>
          </Link>
        )}
        <Link className="tile" to="/members">
          <span className="tile__icon" aria-hidden="true">🎻</span>
          <span className="tile__title">団員一覧</span>
          <span className="tile__desc">パートごとのメンバー</span>
        </Link>
      </div>

      <section aria-labelledby="survey-title">
        <div className="section-heading">
          <h2 id="survey-title">アンケート</h2>
        </div>
        <SurveyList />
      </section>
    </div>
  );
}
