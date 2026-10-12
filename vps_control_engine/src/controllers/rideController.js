import { RideService } from '../services/rideService.js';

export class RideController {
  /**
   * Mobile app POST /api/telemetry/ride
   */
  static async recordRide(req, res) {
    try {
      const result = await RideService.recordRide(req.body);
      return res.status(201).json({ success: true, ...result });
    } catch (error) {
      console.error('[RideController] Error recording ride:', error.message);
      return res.status(400).json({ success: false, error: error.message });
    }
  }

  /**
   * Admin GET /api/admin/rides with pagination & filters
   */
  static async getRides(req, res) {
    try {
      const { page, limit, userId, service, status, search } = req.query;
      const result = await RideService.getRides({ page, limit, userId, service, status, search });
      return res.json({ success: true, ...result });
    } catch (error) {
      console.error('[RideController] Error fetching rides:', error.message);
      return res.status(500).json({ success: false, error: error.message });
    }
  }
}
