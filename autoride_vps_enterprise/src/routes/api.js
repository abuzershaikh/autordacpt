import express from 'express';
import { PaymentController } from '../controllers/paymentController.js';
import { RideController } from '../controllers/rideController.js';
import { CrashController } from '../controllers/crashController.js';
import { TutorialController } from '../controllers/tutorialController.js';
import { ConfigController } from '../controllers/configController.js';
import { VersionController } from '../controllers/versionController.js';
import { TelemetryService } from '../services/telemetryService.js';
import { query } from '../../config/database.js';

const router = express.Router();

// ==========================================
// 1. Dynamic Payment & Subscription Endpoints
// ==========================================
// Public endpoint for mobile app to get dynamic plans and active Razorpay Key ID
router.get('/payment/plans', PaymentController.getPlans);
router.get('/plans', PaymentController.getPlans); // Shortcut alias

// Create Razorpay Order via active live credentials
router.post('/payment/create-order', PaymentController.createOrder);

// Verify payment signature & activate subscription
router.post('/payment/verify', PaymentController.verifyPayment);
router.post('/checkout/verify', PaymentController.verifyPayment); // Backward compatibility alias

// Unified Razorpay Webhook (configured in Razorpay dashboard)
router.post('/payment/webhook', PaymentController.handleWebhook);
router.post('/webhooks/razorpay', PaymentController.handleWebhook); // Backward compatibility alias

// ==========================================
// 2. Telemetry & Heartbeat Endpoints
// ==========================================
router.post('/telemetry/ride', RideController.recordRide);
router.post('/rides/event', RideController.recordRide);
router.post('/telemetry/crash', CrashController.reportCrash);
router.post('/crashes/report', CrashController.reportCrash);
router.post('/telemetry/heartbeat', async (req, res) => {
  try {
    await TelemetryService.recordHeartbeat(req.body);
    const rows = await query("SELECT setting_value FROM app_settings WHERE setting_key = 'free_rides_limit' LIMIT 1");
    const freeLimit = parseInt(rows[0]?.setting_value || '10', 10);
    return res.json({ success: true, acknowledged: true, free_rides_limit: freeLimit });
  } catch (err) {
    return res.status(400).json({ success: false, error: err.message });
  }
});

// ==========================================
// 3. YouTube Tutorial Endpoints
// ==========================================
router.get('/tutorials', TutorialController.getMobileTutorials);

// ==========================================
// 4. Dynamic Remote App Config & Free Rides
// ==========================================
router.get('/config', ConfigController.getMobileConfig);
router.get('/free-rides', ConfigController.getMobileConfig);

// ==========================================
// 5. Remote Version Control & APK Updates
// ==========================================
router.get('/version/check', VersionController.checkVersion);
router.get('/download/latest.apk', VersionController.downloadLatestApk);

export default router;
