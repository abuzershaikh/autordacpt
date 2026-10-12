import { execute, query } from '../../config/database.js';
import { initFirebase, admin } from '../../config/firebase.js';
import { FirebaseSyncService } from './firebaseSyncService.js';

export class TelemetryService {
  /**
   * Record periodic heartbeat from mobile app
   */
  static async recordHeartbeat(payload) {
    const userId = payload.userId || payload.uid;
    if (!userId) return false;

    const isA11y = payload.isAccessibilityActive ?? payload.isAccessibilityEnabled ?? false;
    const minFare = parseFloat(payload.minFare) || 40.0;
    const maxFare = parseFloat(payload.maxFare) || 2000.0;
    const maxPickup = parseFloat(payload.pickupDistance || payload.maxPickupDistance) || 5.0;
    const maxTrip = parseFloat(payload.tripDistance || payload.maxTripDistance) || 30.0;
    const autoAccept = payload.autoAccept ?? payload.autoAcceptEnabled ?? true;
    const clickSpeed = payload.clickSpeed || 'instant';
    const freeUsed = parseInt(payload.freeRidesUsed, 10) || 0;
    const freeLimit = parseInt(payload.freeRidesLimit, 10) || 2;
    let phone = (payload.phoneNumber || payload.phone || '').trim();
    let displayName = (payload.displayName || '').trim();
    let email = (payload.email || '').trim() || null;
    const deviceBrand = payload.deviceBrand || 'Android Device';
    const deviceModel = payload.deviceModel || 'Unknown';
    const androidVersion = payload.androidVersion || 'Android';

    // Auto-enrich user email & displayName from Firebase Auth if missing/default
    if (!email || !displayName || displayName === 'Driver Partner' || displayName === 'Rider Partner') {
      try {
        initFirebase();
        const fbUser = await admin.auth().getUser(userId);
        if (fbUser) {
          if (!email && fbUser.email) email = fbUser.email;
          if ((!displayName || displayName === 'Driver Partner' || displayName === 'Rider Partner') && fbUser.displayName) {
            displayName = fbUser.displayName;
          }
          if ((!phone || phone === 'Pending Sync') && fbUser.phoneNumber) {
            phone = fbUser.phoneNumber;
          }
        }
      } catch (_) {
        // Firebase lookup fallback
      }
    }

    if (!displayName) displayName = 'Driver Partner';
    if (!phone) phone = 'Pending Sync';

    const sql = `
      INSERT INTO users (
        id, phone, display_name, email, device_brand, device_model, 
        android_version, is_accessibility_enabled, is_online, 
        min_fare, max_fare, max_pickup_distance, max_trip_distance, 
        auto_accept_enabled, click_speed, free_rides_used, free_rides_limit,
        last_ping_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, TRUE, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
      ON DUPLICATE KEY UPDATE
        phone = IF(VALUES(phone) != '' AND VALUES(phone) != 'Pending Sync', VALUES(phone), phone),
        display_name = IF(VALUES(display_name) != '' AND VALUES(display_name) != 'Driver Partner', VALUES(display_name), display_name),
        email = COALESCE(VALUES(email), email),
        device_brand = VALUES(device_brand),
        device_model = VALUES(device_model),
        android_version = VALUES(android_version),
        is_accessibility_enabled = VALUES(is_accessibility_enabled),
        is_online = TRUE,
        min_fare = VALUES(min_fare),
        max_fare = VALUES(max_fare),
        max_pickup_distance = VALUES(max_pickup_distance),
        max_trip_distance = VALUES(max_trip_distance),
        auto_accept_enabled = VALUES(auto_accept_enabled),
        click_speed = VALUES(click_speed),
        free_rides_used = VALUES(free_rides_used),
        free_rides_limit = VALUES(free_rides_limit),
        last_ping_at = NOW(),
        updated_at = NOW()
    `;

    await execute(sql, [
      userId, phone, displayName, email, deviceBrand, deviceModel,
      androidVersion, isA11y ? 1 : 0, minFare, maxFare, maxPickup,
      maxTrip, autoAccept ? 1 : 0, clickSpeed, freeUsed, freeLimit
    ]);

    // Also sync real-time state to Cloud Firestore via Admin SDK
    FirebaseSyncService.syncUserToFirestore(userId, {
      email,
      displayName,
      phoneNumber: phone,
      deviceBrand,
      deviceModel,
      androidVersion,
      isOnline: true,
      isAccessibilityActive: isA11y,
      minFare,
      maxFare,
      autoAccept,
      clickSpeed,
    }).catch(err => console.warn('[TelemetryService] Firestore sync error:', err.message));

    return true;
  }

  /**
   * Run background cleanup to mark inactive riders offline
   */
  static async cleanupInactiveRiders(inactiveMinutes = 4) {
    const sql = `
      UPDATE users 
      SET is_online = FALSE 
      WHERE is_online = TRUE 
        AND (last_ping_at IS NULL OR last_ping_at < DATE_SUB(NOW(), INTERVAL ? MINUTE))
    `;
    const result = await execute(sql, [inactiveMinutes]);
    return result.affectedRows;
  }
}
