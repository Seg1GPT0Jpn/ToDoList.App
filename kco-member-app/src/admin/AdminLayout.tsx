import { NavLink, Outlet } from 'react-router-dom';
import { useAuth } from '../auth/AuthProvider';
import { PageTitle } from '../components/Layout';

/*
 * 運営用の画面。
 * 表示の出し分けはここで行うが、実際の読み書きの可否は Firestore ルールが判定する
 * （ここを書き換えても、管理者以外はデータを読めない・書けない）。
 */
export function AdminLayout() {
  const { isStaff, isAdmin } = useAuth();

  if (!isStaff) {
    return <p className="alert alert--error">この画面は運営メンバー専用です。</p>;
  }

  const tab = ({ isActive }: { isActive: boolean }) => (isActive ? 'active' : undefined);

  return (
    <div>
      <PageTitle en="Admin">運営</PageTitle>
      <nav className="admin-tabs" aria-label="運営メニュー">
        <NavLink to="/admin" end className={tab}>概要</NavLink>
        <NavLink to="/admin/rehearsals" className={tab}>練習・出欠</NavLink>
        <NavLink to="/admin/news" className={tab}>お知らせ</NavLink>
        {isAdmin && <NavLink to="/admin/concert" className={tab}>演奏会</NavLink>}
        <NavLink to="/admin/surveys" className={tab}>アンケート</NavLink>
        <NavLink to="/admin/scores" className={tab}>楽譜</NavLink>
        <NavLink to="/admin/notify" className={tab}>通知</NavLink>
        <NavLink to="/admin/campaign" className={tab}>募集</NavLink>
        <NavLink to="/admin/members" className={tab}>団員</NavLink>
      </nav>
      <Outlet />
    </div>
  );
}
