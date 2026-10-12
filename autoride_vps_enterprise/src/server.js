import http from 'http';
import app from './app.js';
import { config } from '../config/env.js';
import { testDbConnection } from '../config/database.js';
import { PaymentService } from './services/paymentService.js';

const server = http.createServer(app);

async function startServer() {
  console.log('====================================================');
  console.log('🚗 AutoRide Acceptor - Enterprise VPS Control Engine');
  console.log('💳 Dynamic Multi-Account Razorpay & Live Pricing v2.0');
  console.log('====================================================');

  // 1. Verify Database Connection
  const isDbOk = await testDbConnection();
  if (!isDbOk) {
    console.warn('⚠️ Server will attempt to boot, but MySQL connection is pending.');
  }

  // 2. Pre-load active Razorpay gateway configuration
  try {
    const activeGateway = await PaymentService.getActiveGatewayConfig();
    console.log(`[Payment Gateway] Active Key ID: ${activeGateway.key_id} (Live Mode: ${Boolean(activeGateway.is_live_mode)})`);
  } catch (err) {
    console.warn('[Payment Gateway] Warning preloading config:', err.message);
  }

  // 3. Start HTTP Server
  server.listen(config.port, '0.0.0.0', () => {
    console.log(`🚀 [Server Ready] Listening on http://0.0.0.0:${config.port}`);
    console.log(`🌐 [Admin Web Panel] ${config.serverBaseUrl}`);
    console.log(`📡 [Unified Webhook Endpoint] ${config.serverBaseUrl}/api/payment/webhook`);
  });
}

// Graceful Shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
    process.exit(0);
  });
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

startServer();
