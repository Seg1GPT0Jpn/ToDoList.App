import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import { App } from './App';
import { AuthProvider } from './auth/AuthProvider';
import { initFirebase } from './firebase';
import './styles.css';

const root = createRoot(document.getElementById('root')!);

initFirebase()
  .then(() => {
    root.render(
      <StrictMode>
        <BrowserRouter>
          <AuthProvider>
            <App />
          </AuthProvider>
        </BrowserRouter>
      </StrictMode>
    );
  })
  .catch(err => {
    console.error(err);
    root.render(
      <div className="auth-screen">
        <div className="auth-card card">
          <p className="alert alert--error">アプリを起動できませんでした。時間をおいて再読み込みしてください。</p>
        </div>
      </div>
    );
  });
