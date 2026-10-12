import express from 'express';
import jwt from 'jsonwebtoken';
import { config } from '../../config/env.js';
import { DashboardController } from '../controllers/dashboardController.js';
import { UserController } from '../controllers/userController.js';
import { RideController } from '../controllers/rideController.js';
import { CrashController } from '../controllers/crashController.js';
import { TutorialController } from '../controllers/tutorialController.js';
import { ConfigController } from '../controllers/configController.js';
import { VersionController } from '../controllers/versionController.js';

const router = express.Router();

// Simple JWT Auth Middleware for Admin Routes
const requireAdminAuth = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader) {
    return res.status(401).json({ success: false, error: 'Unauthorized. Admin token required.' });
  }

  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : authHeader;
  try {
    const decoded = jwt.verify(token, config.admin.jwtSecret);
    req.admin = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ success: false, error: 'Invalid or expired admin token.' });
  }
};

// 1. Admin Login
router.post('/login', (req, res) => {
  const { username, password } = req.body;
  if (username === config.admin.username && password === config.admin.password) {
    const token = jwt.sign({ username, role: 'admin' }, config.admin.jwtSecret, { expiresIn: '7d' });
    return res.json({ success: true, token, user: { username, role: 'admin' } });
  }
  return res.status(401).json({ success: false, error: 'Invalid username or password' });
});

// 2. Protected Admin Dashboard Endpoints
router.use(requireAdminAuth);

// Overview & KPIs
router.get('/overview', DashboardController.getOverview);

// User Profiles Dossier & Sync
router.get('/users', UserController.getUsers);
router.get('/users/:id', UserController.getUserDetail);
router.post('/users/sync-firestore', UserController.syncFirestoreUsers);

// Ride Telemetry & Logs
router.get('/rides', RideController.getRides);

// Crashlytics Explorer
router.get('/crashes', CrashController.getCrashes);
router.patch('/crashes/:id/resolve', CrashController.toggleResolve);

// YouTube Tutorials Management
router.get('/tutorials', TutorialController.getAllTutorials);
router.post('/tutorials', TutorialController.createTutorial);
router.put('/tutorials/:id', TutorialController.updateTutorial);
router.delete('/tutorials/:id', TutorialController.deleteTutorial);

// Remote App Config & Free Rides Limit
router.get('/config', ConfigController.getAdminConfig);
router.put('/config', ConfigController.updateAdminConfig);

// Version Control & Fleet Updates
router.get('/versions', VersionController.getAdminVersions);
router.post('/versions', VersionController.createRelease);
router.patch('/versions/:id/toggle', VersionController.toggleBlock);
router.delete('/versions/:id', VersionController.deleteVersion);
router.post('/versions/config', VersionController.updateConfig);

export default router;
