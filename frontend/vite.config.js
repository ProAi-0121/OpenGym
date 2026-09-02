import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import fs from 'node:fs'
import path from 'node:path'

const backend = process.env.API_TARGET || 'http://127.0.0.1:3000'
const media = process.env.MEDIA_TARGET || 'http://127.0.0.1:8888'

// Serve HTTPS (needed for passkey support over the LAN) whenever mkcert certs exist in ../data.
// Without them the dev server falls back to plain http.
const dataDir = process.env.DATA_DIR || path.resolve(process.cwd(), '../data')
const certFile = path.join(dataDir, 'opengym-cert.pem')
const keyFile = path.join(dataDir, 'opengym-key.pem')
const https = (process.env.DISABLE_HTTPS && /^(1|true|yes|on)$/i.test(process.env.DISABLE_HTTPS))
  ? undefined
  : (fs.existsSync(certFile) && fs.existsSync(keyFile)
      ? { cert: fs.readFileSync(certFile), key: fs.readFileSync(keyFile) }
      : undefined)

export default defineConfig({
  plugins: [react()],
  base: './',
  server: {
    host: '0.0.0.0',
    allowedHosts: ['harsh.run.place'],
    https,
    proxy: {
      '/api': { target: backend, changeOrigin: true },
      '/img': { target: media, changeOrigin: true },
      '/gif': { target: media, changeOrigin: true }
    }
  },
  build: { chunkSizeWarningLimit: 1500 }
})
