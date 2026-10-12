import { AnalyticsService } from '../services/analyticsService.js';
import { TelemetryService } from '../services/telemetryService.js';

export class DashboardController {
  /**
   * Admin GET /api/admin/overview
   */
  static async getOverview(req, res) {
    try {
      // Opportunistically cleanup riders who haven't pinged in 4 minutes
      await TelemetryService.cleanupInactiveRiders(4);

      const stats = await AnalyticsService.getOverviewStats();
      return res.json({ success: true, data: stats });
    } catch (error) {
      console.error('[DashboardController] Error fetching overview:', error);
      return res.status(500).json({ success: false, error: error.message });
    }
  }
}
