import { query, execute } from '../../config/database.js';

export class RideService {
  /**
   * Ingest a ride event sent by mobile app
   */
  static async recordRide(rideData) {
    const userId = rideData.userId || rideData.uid;
    const service = rideData.service || rideData.platform; // 'porter', 'rapido', 'ola', 'uber'
    const status = rideData.status; // 'accepted', 'missed', 'rejected', 'filtered'
    const fare = parseFloat(rideData.fare) || 0.0;
    const pickupDistance = parseFloat(rideData.pickupDistance) || 0.0;
    const tripDistance = parseFloat(rideData.tripDistance || rideData.distanceKm) || 0.0;
    const userMinFare = parseFloat(rideData.userMinFare || rideData.user_min_fare || rideData.minFare) || 0.0;
    const userMaxFare = parseFloat(rideData.userMaxFare || rideData.user_max_fare || rideData.maxFare) || 0.0;
    const userMaxPickup = parseFloat(rideData.userMaxPickup || rideData.user_max_pickup || rideData.maxPickupDistance) || 0.0;
    const userMaxTrip = parseFloat(rideData.userMaxTrip || rideData.user_max_trip || rideData.maxTripDistance) || 0.0;
    const responseTimeMs = parseInt(rideData.responseTimeMs, 10) || 0;
    const reason = rideData.reason || rideData.failureReason || null;
    const orderId = rideData.orderId || null;

    if (!userId || !service || !status) {
      throw new Error('Missing required ride fields: userId, service, status');
    }

    // Ensure user exists in MySQL (if not yet synced, insert stub)
    const checkUser = await query('SELECT id FROM users WHERE id = ? LIMIT 1', [userId]);
    if (!checkUser || checkUser.length === 0) {
      await execute(
        'INSERT IGNORE INTO users (id, phone, display_name) VALUES (?, ?, ?)',
        [userId, 'Pending Sync', 'Driver Partner']
      );
    }

    const sql = `
      INSERT INTO rides (
        user_id, service, status, fare, pickup_distance, 
        trip_distance, user_min_fare, user_max_fare, user_max_pickup, 
        user_max_trip, response_time_ms, reason, order_id, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
    `;

    const result = await execute(sql, [
      userId,
      service.toLowerCase(),
      status.toLowerCase(),
      fare,
      pickupDistance,
      tripDistance,
      userMinFare,
      userMaxFare,
      userMaxPickup,
      userMaxTrip,
      responseTimeMs,
      reason,
      orderId,
    ]);

    // Update user's last activity
    await execute('UPDATE users SET last_ping_at = NOW(), is_online = TRUE WHERE id = ?', [userId]);

    // BUFFER CAP PROTECTION (Keep max 100 rides per user to avoid VPS bloat/hang)
    try {
      await execute(`
        DELETE FROM rides 
        WHERE user_id = ? 
          AND id NOT IN (
            SELECT id FROM (
              SELECT id FROM rides 
              WHERE user_id = ? 
              ORDER BY id DESC 
              LIMIT 100
            ) AS recent_buffer
          )
      `, [userId, userId]);
    } catch (_) {}

    return { id: result.insertId, status: 'recorded' };
  }

  /**
   * Get paginated rides with extensive filtering
   */
  static async getRides({ page = 1, limit = 20, userId = null, service = null, status = null, search = null }) {
    const offset = (page - 1) * limit;
    const whereClauses = [];
    const params = [];

    if (userId) {
      whereClauses.push('r.user_id = ?');
      params.push(userId);
    }
    if (service && service !== 'all') {
      whereClauses.push('r.service = ?');
      params.push(service.toLowerCase());
    }
    if (status && status !== 'all') {
      whereClauses.push('r.status = ?');
      params.push(status.toLowerCase());
    }
    if (search) {
      whereClauses.push('(u.phone LIKE ? OR u.display_name LIKE ? OR r.order_id LIKE ?)');
      const term = `%${search}%`;
      params.push(term, term, term);
    }

    const whereSql = whereClauses.length > 0 ? `WHERE ${whereClauses.join(' AND ')}` : '';

    const countSql = `
      SELECT COUNT(*) as total 
      FROM rides r 
      LEFT JOIN users u ON r.user_id = u.id 
      ${whereSql}
    `;
    const countResult = await query(countSql, params);
    const total = countResult[0]?.total || 0;

    const dataSql = `
      SELECT 
        r.id, r.user_id, r.service, r.status, r.fare, 
        r.pickup_distance, r.trip_distance, r.response_time_ms, 
        r.reason, r.order_id, r.created_at,
        u.phone as driver_phone, u.display_name as driver_name, u.plan_name
      FROM rides r
      LEFT JOIN users u ON r.user_id = u.id
      ${whereSql}
      ORDER BY r.created_at DESC
      LIMIT ? OFFSET ?
    `;

    const rows = await query(dataSql, [...params, parseInt(limit, 10), parseInt(offset, 10)]);

    return {
      data: rows,
      pagination: {
        page: parseInt(page, 10),
        limit: parseInt(limit, 10),
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Get breakdown of rides for a specific user
   */
  static async getUserRideSummary(userId) {
    const sql = `
      SELECT 
        service,
        COUNT(*) as total_orders,
        SUM(CASE WHEN status = 'accepted' THEN 1 ELSE 0 END) as accepted_count,
        SUM(CASE WHEN status = 'missed' THEN 1 ELSE 0 END) as missed_count,
        SUM(CASE WHEN status = 'rejected' OR status = 'filtered' THEN 1 ELSE 0 END) as rejected_count,
        SUM(CASE WHEN status = 'accepted' THEN fare ELSE 0 END) as total_fare,
        AVG(CASE WHEN status = 'accepted' AND response_time_ms > 0 THEN response_time_ms ELSE NULL END) as avg_response_time_ms
      FROM rides
      WHERE user_id = ?
      GROUP BY service
    `;

    const summary = await query(sql, [userId]);
    return summary;
  }
}
