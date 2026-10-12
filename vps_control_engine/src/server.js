import app from './app.js';
import { config } from '../config/env.js';
import { runMigrations } from '../database/migrate.js';
import { initFirebase } from '../config/firebase.js';
import { TelemetryService } from './services/telemetryService.js';
import { FirebaseSyncService } from './services/firebaseSyncService.js';

async function bootstrap() {
  console.log('====================================================');
  console.log('🚀 Starting Ride AutoAccept VPS Control Engine...');
  console.log('====================================================');

  // 1. Run database migrations
  try {
    await runMigrations();
  } catch (err) {
    console.warn('[Startup] Migration skipped or failed, continuing server startup:', err.message);
  }

  // 2. Initialize Firebase Admin SDK & Sync Auth Users
  try {
    initFirebase();
    await FirebaseSyncService.syncAllUsersFromFirebaseAuth();
  } catch (err) {
    console.warn('[Startup] Firebase init/sync skipped:', err.message);
  }

  // 3. Start Express HTTP Server
  const server = app.listen(config.port, '0.0.0.0', () => {
    console.log(`✓ VPS Control Engine listening on http://0.0.0.0:${config.port}`);
    console.log(`✓ Admin Web Dashboard: http://localhost:${config.port}`);
    console.log(`✓ Mobile Telemetry API: http://localhost:${config.port}/api/telemetry/ride`);
    console.log(`✓ Dynamic Free Rides API: http://localhost:${config.port}/api/free-rides`);
    console.log('====================================================');
  });

  // 4. Background Scheduled Tasks (Cleanup & Sync)
  setInterval(async () => {
    try {
      await TelemetryService.cleanupInactiveRiders(4);
    } catch (_) {}
  }, 60 * 1000); // Every 60s

  setInterval(async () => {
    try {
      await FirebaseSyncService.syncAllUsersFromFirebaseAuth();
      await FirebaseSyncService.syncAllUsersFromFirestore(50);
    } catch (_) {}
  }, 5 * 60 * 1000); // Every 5 mins

  // Graceful Shutdown
  const shutdown = () => {
    console.log('\n[Shutdown] Closing HTTP server and database pool...');
    server.close(() => {
      console.log('[Shutdown] Server successfully terminated.');
      process.exit(0);
    });
  };

  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

bootstrap();
