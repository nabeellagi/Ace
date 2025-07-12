import { defineConfig } from 'vite'
import path from 'path'

export default defineConfig({
  build: {
    rollupOptions: {
      input: {
        skymap: path.resolve(__dirname, 'skymap/index.html'),
        satelite: path.resolve(__dirname, 'satelite/index.html'),
        radiotelescope: path.resolve(__dirname, 'radiotelescope/index.html'),
      }
    },
    outDir: 'dist',
    emptyOutDir: true
  },
  server: {
    fs: {
      allow: ['.']
    }
  }
})
