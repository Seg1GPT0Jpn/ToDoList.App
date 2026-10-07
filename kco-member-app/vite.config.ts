import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  build: {
    outDir: 'dist',
    sourcemap: false,
    chunkSizeWarningLimit: 700,
    rolldownOptions: {
      output: {
        // Firebase SDK を別ファイルにしてキャッシュを効かせる
        advancedChunks: {
          groups: [
            // 楽譜・通知の画面でだけ使う部分は別ファイル（団員の初回表示を軽くする）
            { name: 'firebase-storage', test: /node_modules[\\/]@firebase[\\/]storage/ },
            { name: 'firebase-messaging', test: /node_modules[\\/]@firebase[\\/](messaging|installations)/ },
            { name: 'firebase', test: /node_modules[\\/](@firebase|firebase)/ },
            { name: 'react', test: /node_modules[\\/](react|react-dom|react-router|react-router-dom|scheduler)[\\/]/ }
          ]
        }
      }
    }
  },
  test: {
    environment: 'node',
    testTimeout: 20000,
    hookTimeout: 30000
  }
});
