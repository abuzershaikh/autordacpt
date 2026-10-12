import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import path from 'path';
import { fileURLToPath } from 'url';
import apiRouter from './routes/api.js';
import adminRouter from './routes/admin.js';
import { VersionController } from './controllers/versionController.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();

// Security Middleware
app.use(
  helmet({
    contentSecurityPolicy: false, // Allow CDNs, FontAwesome, ChartJS and YouTube embeds on dashboard
  })
);

app.use(cors({ origin: '*' }));
app.use(morgan('dev'));

// Body Parser with Raw Body Retention for Razorpay Webhook HMAC Verification
app.use(
  express.json({
    limit: '10mb',
    verify: (req, res, buf) => {
      req.rawBody = buf;
    },
  })
);
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Serve Admin Web Panel Static Files
const publicPath = path.resolve(__dirname, '../public');
app.use(express.static(publicPath));

// API Routes
app.use('/api', apiRouter);
app.use('/api/admin', adminRouter);
app.use('/admin/api', adminRouter);

// Direct APK Download route
app.get('/download/latest.apk', VersionController.downloadLatestApk);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'autoride-vps-enterprise',
    version: '2.0.0',
    timestamp: new Date().toISOString(),
  });
});

// SPA fallback for Admin Panel
app.get('*', (req, res) => {
  res.sendFile(path.join(publicPath, 'index.html'));
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('[Server Error]', err.stack || err.message);
  res.status(500).json({
    success: false,
    error: err.message || 'Internal Server Error',
  });
});

export default app;
