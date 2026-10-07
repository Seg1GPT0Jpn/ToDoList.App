import { lazy, Suspense, type ReactNode } from 'react';
import { Navigate, Route, Routes, useLocation } from 'react-router-dom';
import { useAuth } from './auth/AuthProvider';
import { Layout, Loading } from './components/Layout';
import { FinishLoginPage, GateScreen, LoginPage } from './pages/AuthScreens';
import { ConcertPage } from './pages/ConcertPage';
import { HomePage } from './pages/HomePage';
import { JoinPage } from './pages/JoinPage';
import { MePage } from './pages/MePage';
import { MembersPage } from './pages/MembersPage';
import { NewsPage } from './pages/NewsPage';
import { ProposalsPage } from './pages/ProposalsPage';
import { RehearsalDetailPage, SchedulePage } from './pages/SchedulePage';
import { ScoresPage } from './pages/ScoresPage';
import { SurveyPage } from './pages/SurveyPages';
import { TogetherPage } from './pages/TogetherPage';

// 運営用の画面は必要な人だけが読み込む（団員の初回表示を軽くする）
// 募集カード（画像生成・QRコード）は使うときだけ読み込む
const CampaignSharePage = lazy(() => import('./pages/CampaignSharePage').then(m => ({ default: m.CampaignSharePage })));
const AdminLayout = lazy(() => import('./admin/AdminLayout').then(m => ({ default: m.AdminLayout })));
const AdminDashboard = lazy(() => import('./admin/AdminDashboard').then(m => ({ default: m.AdminDashboard })));
const AdminRehearsals = lazy(() => import('./admin/AdminRehearsals').then(m => ({ default: m.AdminRehearsals })));
const AdminRehearsalEdit = lazy(() => import('./admin/AdminRehearsals').then(m => ({ default: m.AdminRehearsalEdit })));
const AdminNews = lazy(() => import('./admin/AdminNews').then(m => ({ default: m.AdminNews })));
const AdminConcert = lazy(() => import('./admin/AdminConcert').then(m => ({ default: m.AdminConcert })));
const AdminMembers = lazy(() => import('./admin/AdminMembers').then(m => ({ default: m.AdminMembers })));
const AdminSurveys = lazy(() => import('./admin/AdminSurveys').then(m => ({ default: m.AdminSurveys })));
const AdminSurveyEdit = lazy(() => import('./admin/AdminSurveys').then(m => ({ default: m.AdminSurveyEdit })));
const AdminScores = lazy(() => import('./admin/AdminScores').then(m => ({ default: m.AdminScores })));
const AdminNotify = lazy(() => import('./admin/AdminNotify').then(m => ({ default: m.AdminNotify })));
const AdminCampaign = lazy(() => import('./admin/AdminCampaign').then(m => ({ default: m.AdminCampaign })));

function Lazy({ children }: { children: ReactNode }) {
  return <Suspense fallback={<Loading />}>{children}</Suspense>;
}

export function App() {
  const { state } = useAuth();
  const location = useLocation();

  // 団員募集ページは誰でも見られる（ログイン不要）
  if (location.pathname === '/join' || location.pathname.startsWith('/join/')) return <JoinPage />;

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
        <Route path="together" element={<TogetherPage />} />
        <Route path="surveys/:id" element={<SurveyPage />} />
        <Route path="proposals" element={<ProposalsPage />} />
        <Route path="scores" element={<ScoresPage />} />
        <Route path="campaign" element={<Lazy><CampaignSharePage /></Lazy>} />
        <Route path="admin" element={<Lazy><AdminLayout /></Lazy>}>
          <Route index element={<Lazy><AdminDashboard /></Lazy>} />
          <Route path="rehearsals" element={<Lazy><AdminRehearsals /></Lazy>} />
          <Route path="rehearsals/:id" element={<Lazy><AdminRehearsalEdit /></Lazy>} />
          <Route path="news" element={<Lazy><AdminNews /></Lazy>} />
          <Route path="concert" element={<Lazy><AdminConcert /></Lazy>} />
          <Route path="members" element={<Lazy><AdminMembers /></Lazy>} />
          <Route path="surveys" element={<Lazy><AdminSurveys /></Lazy>} />
          <Route path="surveys/:id" element={<Lazy><AdminSurveyEdit /></Lazy>} />
          <Route path="scores" element={<Lazy><AdminScores /></Lazy>} />
          <Route path="notify" element={<Lazy><AdminNotify /></Lazy>} />
          <Route path="campaign" element={<Lazy><AdminCampaign /></Lazy>} />
        </Route>
        <Route path="login/*" element={<Navigate to="/" replace />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
    </Routes>
  );
}
