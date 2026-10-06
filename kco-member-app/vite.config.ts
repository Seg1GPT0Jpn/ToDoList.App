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
