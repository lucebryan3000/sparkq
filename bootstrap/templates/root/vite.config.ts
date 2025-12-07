import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tsconfigPaths from 'vite-tsconfig-paths'
import { resolve } from 'path'

export default defineConfig({
  plugins: [
    react(),
    tsconfigPaths(),
  ],

  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
    },
  },

  server: {
    port: 3000,
    host: true,
    open: false,
    cors: true,
  },

  preview: {
    port: 3000,
  },

  build: {
    outDir: 'dist',
    sourcemap: true,
    minify: 'terser',
    target: 'esnext',
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
        },
      },
    },
  },

  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./testing/setup.ts'],
    include: ['src/**/*.{test,spec}.{ts,tsx}'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov', 'html'],
      exclude: [
        'node_modules/',
        'testing/',
        '**/*.d.ts',
        '**/*.config.*',
      ],
    },
  },

  optimizeDeps: {
    include: ['react', 'react-dom'],
  },

  esbuild: {
    logOverride: { 'this-is-undefined-in-esm': 'silent' },
  },
})
