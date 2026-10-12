import express from 'express';
import { RideController } from '../controllers/rideController.js';
import { CrashController } from '../controllers/crashController.js';
import { TutorialController } from '../controllers/tutorialController.js';
import { ConfigController } from '../controllers/configController.js';
import { VersionController } from '../controllers/versionController.js';
import { TelemetryService } from '../services/telemetryService.js';

const router = express.Router();

// 1. Telemetry endpoints
router.post('/telemetry/ride', RideController.recordRide);
router.post('/rides/event', RideController.recordRide);
router.post('/telemetry/crash', CrashController.reportCrash);
router.post('/crashes/report', CrashController.reportCrash);
router.post('/telemetry/heartbeat', async (req, res) => {
  try {
    await TelemetryService.recordHeartbeat(req.body);
    return res.json({ success: true, acknowledged: true });
  } catch (err) {
    return res.status(400).json({ success: false, error: err.message });
  }
});

// 2. Tutorial endpoints
router.get('/tutorials', TutorialController.getMobileTutorials);

// 3. Dynamic App Config & Free Rides Endpoint
router.get('/config', ConfigController.getMobileConfig);
router.get('/free-rides', ConfigController.getMobileConfig); // Direct alias for dynamic free rides

// 4. Remote App Version Check & APK Download
router.get('/version/check', VersionController.checkVersion);
router.get('/download/latest.apk', VersionController.downloadLatestApk);

export default router;
