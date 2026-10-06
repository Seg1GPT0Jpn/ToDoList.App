import { lazy, Suspense, type ReactNode } from 'react';
import { Navigate, Route, Routes } from 'react-router-dom';
import { useAuth } from './auth/AuthProvider';
import { Layout, Loading } from './components/Layout';
import { FinishLoginPage, GateScreen, LoginPage } from './pages/AuthScreens';
import { ConcertPage } from './pages/ConcertPage';
import { HomePage } from './pages/HomePage';
import { MePage } from './pages/MePage';
import { MembersPage } from './pages/MembersPage';
import { NewsPage } from './pages/NewsPage';
import { RehearsalDetailPage, SchedulePage } from './pages/SchedulePage';

// 運営用の画面は必要な人だけが読み込む（団員の初回表示を軽くする）
const AdminLayout = lazy(() => import('./admin/AdminLayout').then(m => ({ default: m.AdminLayout })));
const AdminDashboard = lazy(() => import('./admin/AdminDashboard').then(m => ({ default: m.AdminDashboard })));
const AdminRehearsals = lazy(() => import('./admin/AdminRehearsals').then(m => ({ default: m.AdminRehearsals })));
const AdminRehearsalEdit = lazy(() => import('./admin/AdminRehearsals').then(m => ({ default: m.AdminRehearsalEdit })));
const AdminNews = lazy(() => import('./admin/AdminNews').then(m => ({ default: m.AdminNews })));
const AdminConcert = lazy(() => import('./admin/AdminConcert').then(m => ({ default: m.AdminConcert })));
const AdminMembers = lazy(() => import('./admin/AdminMembers').then(m => ({ default: m.AdminMembers })));

function Lazy({ children }: { children: ReactNode }) {
  return <Suspense fallback={<Loading />}>{children}</Suspense>;
}

export function App() {
  const { state } = useAuth();

  if (state === 'loading') return <Loading label="確認しています…" />;

  if (state === 'signed-out') {
    return (
      <Routes>
        <Route path="/login/finish" element={<FinishLoginPage />} />
        <Route path="*" element={<LoginPage />} />
      </Routes>
    );
  }

  if (state !== 'active' && state !== 'paused') {
    return <GateScreen />;
  }

  return (
    <Routes>
      <Route element={<Layout />}>
        <Route index element={<HomePage />} />
        <Route path="schedule" element={<SchedulePage />} />
        <Route path="schedule/:id" element={<RehearsalDetailPage />} />
        <Route path="news" element={<NewsPage />} />
        <Route path="concert" element={<ConcertPage />} />
        <Route path="members" element={<MembersPage />} />
        <Route path="me" element={<MePage />} />
        <Route path="admin" element={<Lazy><AdminLayout /></Lazy>}>
          <Route index element={<Lazy><AdminDashboard /></Lazy>} />
          <Route path="rehearsals" element={<Lazy><AdminRehearsals /></Lazy>} />
          <Route path="rehearsals/:id" element={<Lazy><AdminRehearsalEdit /></Lazy>} />
          <Route path="news" element={<Lazy><AdminNews /></Lazy>} />
          <Route path="concert" element={<Lazy><AdminConcert /></Lazy>} />
          <Route path="members" element={<Lazy><AdminMembers /></Lazy>} />
        </Route>
        <Route path="login/*" element={<Navigate to="/" replace />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
    </Routes>
  );
}
