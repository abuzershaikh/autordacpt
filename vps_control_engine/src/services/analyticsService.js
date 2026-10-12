import { query } from '../../config/database.js';

export class AnalyticsService {
  /**
   * Compute comprehensive dashboard KPIs
   */
  static async getOverviewStats() {
    // 1. User metrics
    const userStatsSql = `
      SELECT 
        COUNT(*) as total_riders,
        SUM(CASE WHEN is_online = TRUE THEN 1 ELSE 0 END) as online_riders,
        SUM(CASE WHEN is_accessibility_enabled = TRUE THEN 1 ELSE 0 END) as accessibility_enabled_riders,
        SUM(CASE WHEN plan_status = 'active' THEN 1 ELSE 0 END) as active_subscriptions
      FROM users
    `;
    const userStats = (await query(userStatsSql))[0] || {};

    // 2. Ride metrics
    const rideStatsSql = `
      SELECT 
        COUNT(*) as total_rides_detected,
        SUM(CASE WHEN status = 'accepted' THEN 1 ELSE 0 END) as total_accepted,
        SUM(CASE WHEN status = 'missed' THEN 1 ELSE 0 END) as total_missed,
        SUM(CASE WHEN status = 'rejected' OR status = 'filtered' THEN 1 ELSE 0 END) as total_filtered,
        SUM(CASE WHEN status = 'accepted' THEN fare ELSE 0 END) as total_accepted_fare,
        AVG(CASE WHEN status = 'accepted' AND response_time_ms > 0 THEN response_time_ms ELSE NULL END) as avg_response_time_ms
      FROM rides
    `;
    const rideStats = (await query(rideStatsSql))[0] || {};

    // 3. Platform breakdown (Porter, Rapido, Ola, Uber)
    const platformBreakdownSql = `
      SELECT 
        service,
        COUNT(*) as total,
        SUM(CASE WHEN status = 'accepted' THEN 1 ELSE 0 END) as accepted,
        SUM(CASE WHEN status = 'missed' THEN 1 ELSE 0 END) as missed,
        SUM(CASE WHEN status = 'rejected' OR status = 'filtered' THEN 1 ELSE 0 END) as filtered
      FROM rides
      GROUP BY service
    `;
    const platformBreakdown = await query(platformBreakdownSql);

    // 4. Crash metrics
    const crashStatsSql = `
      SELECT 
        COUNT(*) as total_crashes,
        SUM(CASE WHEN is_resolved = FALSE THEN 1 ELSE 0 END) as unresolved_crashes,
        SUM(CASE WHEN created_at >= CURDATE() THEN 1 ELSE 0 END) as crashes_today
      FROM crashes
    `;
    const crashStats = (await query(crashStatsSql))[0] || {};

    // Calculate acceptance rate
    const totalDetected = parseInt(rideStats.total_rides_detected || 0, 10);
    const totalAccepted = parseInt(rideStats.total_accepted || 0, 10);
    const acceptanceRate = totalDetected > 0 ? ((totalAccepted / totalDetected) * 100).toFixed(1) : '0.0';

    return {
      riders: {
        total: parseInt(userStats.total_riders || 0, 10),
        online: parseInt(userStats.online_riders || 0, 10),
        accessibilityActive: parseInt(userStats.accessibility_enabled_riders || 0, 10),
        activePlans: parseInt(userStats.active_subscriptions || 0, 10),
      },
      rides: {
        total: totalDetected,
        accepted: totalAccepted,
        missed: parseInt(rideStats.total_missed || 0, 10),
        filtered: parseInt(rideStats.total_filtered || 0, 10),
        totalAcceptedFare: parseFloat(rideStats.total_accepted_fare || 0).toFixed(2),
        avgResponseTimeMs: Math.round(rideStats.avg_response_time_ms || 0),
        acceptanceRate: parseFloat(acceptanceRate),
      },
      platforms: platformBreakdown,
      crashes: {
        total: parseInt(crashStats.total_crashes || 0, 10),
        unresolved: parseInt(crashStats.unresolved_crashes || 0, 10),
        today: parseInt(crashStats.crashes_today || 0, 10),
      },
    };
  }
}
