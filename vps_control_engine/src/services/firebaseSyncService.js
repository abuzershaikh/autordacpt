import { getFirestore, initFirebase, admin } from '../../config/firebase.js';
import { query, execute } from '../../config/database.js';

export class FirebaseSyncService {
  /**
   * Sync a single user profile from Cloud Firestore or Firebase Auth to MySQL
   */
  static async syncUserByUid(uid) {
    initFirebase();
    // 1. Try Firestore
    const firestore = getFirestore();
    if (firestore) {
      try {
        const doc = await firestore.collection('users').doc(uid).get();
        if (doc.exists) {
          return await this.upsertUserToDatabase(doc.id, doc.data());
        }
      } catch (err) {
        console.warn(`[FirebaseSync] Firestore error for ${uid}:`, err.message);
      }
    }

    // 2. Fallback to Firebase Auth user record
    try {
      const fbUser = await admin.auth().getUser(uid);
      if (fbUser) {
        const createdAt = fbUser.metadata?.creationTime ? new Date(fbUser.metadata.creationTime) : new Date();
        const sql = `
          INSERT INTO users (
            id, phone, display_name, email, device_brand, device_model, 
            android_version, plan_id, plan_name, plan_status, joined_at
          ) VALUES (?, ?, ?, ?, 'Samsung', 'SM-M145F', '15', 'free', 'Free Trial', 'active', ?)
          ON DUPLICATE KEY UPDATE
            email = COALESCE(VALUES(email), email),
            display_name = IF(VALUES(display_name) != '' AND VALUES(display_name) != 'Driver Partner', VALUES(display_name), display_name),
            phone = IF(VALUES(phone) != '' AND VALUES(phone) != 'Pending Sync', VALUES(phone), phone);
        `;
        await execute(sql, [
          fbUser.uid,
          fbUser.phoneNumber || 'Pending Sync',
          fbUser.displayName || 'Driver Partner',
          fbUser.email || null,
          createdAt,
        ]);
        return { id: uid, phone: fbUser.phoneNumber, email: fbUser.email, displayName: fbUser.displayName };
      }
    } catch (authErr) {
      console.warn(`[FirebaseSync] Auth lookup failed for ${uid}:`, authErr.message);
    }

    return null;
  }

  /**
   * Sync all users directly from Firebase Authentication into MySQL
   */
  static async syncAllUsersFromFirebaseAuth() {
    try {
      initFirebase();
      const list = await admin.auth().listUsers(100);
      let count = 0;

      for (const u of list.users) {
        const createdAt = u.metadata?.creationTime ? new Date(u.metadata.creationTime) : new Date();
        const sql = `
          INSERT INTO users (
            id, phone, display_name, email, device_brand, device_model, 
            android_version, plan_id, plan_name, plan_status, joined_at
          ) VALUES (?, ?, ?, ?, 'Samsung', 'SM-M145F', '15', 'free', 'Free Trial', 'active', ?)
          ON DUPLICATE KEY UPDATE
            email = COALESCE(VALUES(email), email),
            display_name = IF(VALUES(display_name) != '' AND VALUES(display_name) != 'Driver Partner', VALUES(display_name), display_name),
            phone = IF(VALUES(phone) != '' AND VALUES(phone) != 'Pending Sync', VALUES(phone), phone);
        `;
        await execute(sql, [
          u.uid,
          u.phoneNumber || '9876543210',
          u.displayName || 'Driver Partner',
          u.email || null,
          createdAt,
        ]);
        count++;
      }

      console.log(`[FirebaseSync] Successfully synced ${count} real users from Firebase Auth.`);
      return { synced: count };
    } catch (error) {
      console.error('[FirebaseSync] Error syncing from Firebase Auth:', error.message);
      return { synced: 0, error: error.message };
    }
  }

  /**
   * Sync all users from Firestore to MySQL
   */
  static async syncAllUsersFromFirestore(limit = 100) {
    const firestore = getFirestore();
    if (!firestore) return { synced: 0, error: 'Firestore not initialized' };

    try {
      const snapshot = await firestore.collection('users').limit(limit).get();
      let syncedCount = 0;

      for (const doc of snapshot.docs) {
        const data = doc.data();
        await this.upsertUserToDatabase(doc.id, data);
        syncedCount++;
      }

      console.log(`[FirebaseSync] Successfully synced ${syncedCount} users from Firestore.`);
      return { synced: syncedCount, total: snapshot.size };
    } catch (error) {
      console.error('[FirebaseSync] Error syncing users collection:', error.message);
      return { synced: 0, error: error.message };
    }
  }

  /**
   * Helper to insert or update user in MySQL database
   */
  static async upsertUserToDatabase(uid, data) {
    const activePlan = data.activePlan || {};
    let planExpiresAt = null;

    if (activePlan.expiresAt) {
      if (typeof activePlan.expiresAt.toDate === 'function') {
        planExpiresAt = activePlan.expiresAt.toDate();
      } else if (typeof activePlan.expiresAt === 'string') {
        planExpiresAt = new Date(activePlan.expiresAt);
      }
    }

    let joinedAt = new Date();
    if (data.createdAt) {
      if (typeof data.createdAt.toDate === 'function') {
        joinedAt = data.createdAt.toDate();
      } else if (typeof data.createdAt === 'string') {
        joinedAt = new Date(data.createdAt);
      }
    }

    const sql = `
      INSERT INTO users (
        id, phone, display_name, email, device_brand, device_model, 
        android_version, plan_id, plan_name, plan_status, plan_expires_at, 
        free_rides_used, joined_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE
        phone = VALUES(phone),
        display_name = VALUES(display_name),
        email = VALUES(email),
        device_brand = VALUES(device_brand),
        device_model = VALUES(device_model),
        android_version = VALUES(android_version),
        plan_id = VALUES(plan_id),
        plan_name = VALUES(plan_name),
        plan_status = VALUES(plan_status),
        plan_expires_at = VALUES(plan_expires_at),
        updated_at = NOW();
    `;

    const params = [
      uid,
      data.phoneNumber || data.phone || 'Unknown',
      data.displayName || 'Driver Partner',
      data.email || null,
      data.deviceBrand || 'Samsung',
      data.deviceModel || 'SM-M145F',
      data.androidVersion || '15',
      activePlan.planId || 'none',
      activePlan.planName || 'Free Trial',
      activePlan.status || 'inactive',
      planExpiresAt,
      data.freeRidesUsed || 0,
      joinedAt,
    ];

    try {
      await execute(sql, params);
      return { id: uid, phone: data.phoneNumber, plan: activePlan.planName };
    } catch (err) {
      console.warn(`[FirebaseSync] MySQL upsert failed for ${uid}:`, err.message);
      return null;
    }
  }
}
