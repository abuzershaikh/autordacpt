import { query } from '../../config/database.js';
import { FirebaseSyncService } from '../services/firebaseSyncService.js';
import { RideService } from '../services/rideService.js';

export class UserController {
  /**
   * Get paginated drivers list with search and filters
   */
  static async getUsers(req, res) {
    try {
      const page = parseInt(req.query.page || '1', 10);
      const limit = parseInt(req.query.limit || '15', 10);
      const offset = (page - 1) * limit;
      const search = req.query.search?.trim();
      const planStatus = req.query.planStatus;

      const whereClauses = [];
      const params = [];

      if (search) {
        whereClauses.push('(u.phone LIKE ? OR u.display_name LIKE ? OR u.email LIKE ? OR u.id LIKE ?)');
        const term = `%${search}%`;
        params.push(term, term, term, term);
      }

      if (planStatus && planStatus !== 'all') {
        whereClauses.push('u.plan_status = ?');
        params.push(planStatus);
      }

      const whereSql = whereClauses.length > 0 ? `WHERE ${whereClauses.join(' AND ')}` : '';

      const countSql = `SELECT COUNT(*) as total FROM users u ${whereSql}`;
      let countResult = await query(countSql, params);
      let total = countResult[0]?.total || 0;

      // Auto-sync real users from Firebase Authentication if no real users exist
      if (total === 0 && !search) {
        await FirebaseSyncService.syncAllUsersFromFirebaseAuth();
        countResult = await query(countSql, params);
        total = countResult[0]?.total || 0;
      }

      const dataSql = `
        SELECT 
          u.id, u.phone, u.display_name, u.email,
          u.device_brand, u.device_model, u.android_version,
          u.plan_id, u.plan_name, u.plan_status, u.plan_expires_at,
          u.free_rides_used, u.is_accessibility_enabled, u.is_online,
          u.last_ping_at, u.joined_at, u.updated_at,
          (SELECT COUNT(*) FROM rides r WHERE r.user_id = u.id AND r.status = 'accepted' AND r.created_at >= CURDATE()) as today_accepted,
          (SELECT COUNT(*) FROM rides r WHERE r.user_id = u.id AND r.status = 'missed' AND r.created_at >= CURDATE()) as today_missed,
          (SELECT COUNT(*) FROM crashes c WHERE c.user_id = u.id) as total_crashes
        FROM users u
        ${whereSql}
        ORDER BY u.joined_at DESC
        LIMIT ? OFFSET ?
      `;

      const rows = await query(dataSql, [...params, limit, offset]);

      return res.json({
        success: true,
        data: rows,
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit),
        },
      });
    } catch (error) {
      console.error('[UserController] Error fetching users:', error);
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  /**
   * Get single user full detail dossier including ride breakdown & recent history
   */
  static async getUserDetail(req, res) {
    try {
      const { id } = req.params;

      const userSql = 'SELECT * FROM users WHERE id = ? LIMIT 1';
      const userRows = await query(userSql, [id]);

      if (!userRows || userRows.length === 0) {
        // Try to fetch from Firebase on-demand
        const synced = await FirebaseSyncService.syncUserByUid(id);
        if (!synced) {
          return res.status(404).json({ success: false, error: 'User not found' });
        }
      }

      const user = userRows[0] || (await query(userSql, [id]))[0];

      // Get per-app ride summary
      const rideSummary = await RideService.getUserRideSummary(id);

      // Get missed and rejected/filtered rides with diagnostic limits
      const missedRidesSql = `
        SELECT 
          id, user_id, service, status, fare, pickup_distance, trip_distance,
          user_min_fare, user_max_fare, user_max_pickup, user_max_trip,
          response_time_ms, reason, order_id, created_at
        FROM rides 
        WHERE user_id = ? AND status IN ('missed', 'rejected', 'filtered')
        ORDER BY created_at DESC 
        LIMIT 50
      `;
      const missedRides = await query(missedRidesSql, [id]);

      // Get accepted rides stream
      const acceptedRidesSql = `
        SELECT 
          id, user_id, service, status, fare, pickup_distance, trip_distance,
          user_min_fare, user_max_fare, response_time_ms, order_id, created_at
        FROM rides 
        WHERE user_id = ? AND status = 'accepted'
        ORDER BY created_at DESC 
        LIMIT 50
      `;
      const acceptedRides = await query(acceptedRidesSql, [id]);

      // Get user crashes
      const crashSql = `
        SELECT * FROM crashes 
        WHERE user_id = ? 
        ORDER BY created_at DESC 
        LIMIT 20
      `;
      const recentCrashes = await query(crashSql, [id]);

      return res.json({
        success: true,
        data: {
          profile: user,
          rideSummary,
          missedRides,
          acceptedRides,
          recentCrashes,
        },
      });
    } catch (error) {
      console.error('[UserController] Error fetching user detail:', error);
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  /**
   * Trigger on-demand sync from Cloud Firestore
   */
  static async syncFirestoreUsers(req, res) {
    try {
      const limit = parseInt(req.body.limit || '100', 10);
      const authResult = await FirebaseSyncService.syncAllUsersFromFirebaseAuth();
      const firestoreResult = await FirebaseSyncService.syncAllUsersFromFirestore(limit);
      return res.json({ 
        success: true, 
        synced: (authResult.synced || 0) + (firestoreResult.synced || 0),
        authSynced: authResult.synced || 0,
        firestoreSynced: firestoreResult.synced || 0
      });
    } catch (error) {
      console.error('[UserController] Sync failed:', error);
      return res.status(500).json({ success: false, error: error.message });
    }
  }
}
