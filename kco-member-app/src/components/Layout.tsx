import type { ReactNode } from 'react';
import { Link, NavLink, Outlet } from 'react-router-dom';
import { useAuth } from '../auth/AuthProvider';

const ICONS: Record<string, ReactNode> = {
  home: <path d="M3 11.5 12 4l9 7.5M5.5 9.5V20h13V9.5" />,
  schedule: (
    <>
      <rect x="3.5" y="5" width="17" height="15" rx="2" />
      <path d="M3.5 9.5h17M8 3v4M16 3v4" />
    </>
  ),
  news: <path d="M5 4h11l3 3v13H5zM8 9h8M8 13h8M8 17h5" />,
  members: (
    <>
      <circle cx="9" cy="8" r="3.2" />
      <path d="M3.5 19c.8-3.2 3-5 5.5-5s4.7 1.8 5.5 5M15.5 5.2a3 3 0 0 1 0 5.6M17.5 14.3c1.5.7 2.6 2.2 3 4.7" />
    </>
  ),
  together: (
    <>
      <circle cx="8" cy="9" r="2.8" />
      <circle cx="16" cy="9" r="2.8" />
      <path d="M3 19c.6-3 2.6-4.8 5-4.8s4.4 1.8 5 4.8M11 19c.6-3 2.6-4.8 5-4.8s4.4 1.8 5 4.8" />
    </>
  ),
  me: (
    <>
      <circle cx="12" cy="8" r="3.6" />
      <path d="M4.5 20c1-3.6 4-5.6 7.5-5.6s6.5 2 7.5 5.6" />
    </>
  )
};

function Tab({ to, icon, label, end }: { to: string; icon: string; label: string; end?: boolean }) {
  return (
    <NavLink to={to} end={end} className={({ isActive }) => (isActive ? 'active' : undefined)}>
      <svg viewBox="0 0 24 24" aria-hidden="true">{ICONS[icon]}</svg>
      <span>{label}</span>
    </NavLink>
  );
}

export function Layout() {
  const { isStaff, isApplicant, state } = useAuth();

  return (
    <>
      <a className="visually-hidden" href="#main">本文へスキップ</a>
      <header className="app-header">
        <Link className="brand" to="/">
          <span className="brand__mark" aria-hidden="true">KC</span>
          <span className="brand__name">
            かながわコネクトオーケストラ
            <span className="brand__sub">Members</span>
          </span>
        </Link>
        {isStaff && (
          <Link className="header-link" to="/admin">運営</Link>
        )}
      </header>

      <main id="main" className="app-main">
        {state === 'paused' && (
          <p className="alert alert--info paused-banner">
            現在「活動休止中」のため閲覧のみ可能です。出欠の登録などはできません。
          </p>
        )}
        <Outlet />
      </main>

      <nav className="tabbar" aria-label="メインメニュー">
        <Tab to="/" icon="home" label="ホーム" end />
        <Tab to="/schedule" icon="schedule" label="予定" />
        <Tab to="/news" icon="news" label="お知らせ" />
        {!isApplicant && <Tab to="/together" icon="together" label="みんなで" />}
        <Tab to="/me" icon="me" label="マイページ" />
      </nav>
    </>
  );
}

export function PageTitle({ en, children }: { en: string; children: ReactNode }) {
  return (
    <div className="page-title">
      <span className="page-title__en" aria-hidden="true">{en}</span>
      <h1>{children}</h1>
    </div>
  );
}

export function Loading({ label = '読み込み中…' }: { label?: string }) {
  return <div className="loading-screen" role="status">{label}</div>;
}

export function ErrorNote({ message }: { message: string | null }) {
  if (!message) return null;
  return <p className="alert alert--error" role="alert">{message}</p>;
}

export function Empty({ children }: { children: ReactNode }) {
  return <p className="empty">{children}</p>;
}
