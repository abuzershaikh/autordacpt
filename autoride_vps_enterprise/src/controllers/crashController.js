import { CrashService } from '../services/crashService.js';

export class CrashController {
  /**
   * Mobile app POST /api/telemetry/crash
   */
  static async reportCrash(req, res) {
    try {
      const result = await CrashService.recordCrash(req.body);
      return res.status(201).json({ success: true, ...result });
    } catch (error) {
      console.error('[CrashController] Error logging crash:', error.message);
      return res.status(400).json({ success: false, error: error.message });
    }
  }

  /**
   * Admin GET /api/admin/crashes
   */
  static async getCrashes(req, res) {
    try {
      const { page, limit, isResolved, search } = req.query;
      const result = await CrashService.getCrashes({ page, limit, isResolved, search });
      return res.json({ success: true, ...result });
    } catch (error) {
      console.error('[CrashController] Error fetching crashes:', error.message);
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  /**
   * Admin PATCH /api/admin/crashes/:id/resolve
   */
  static async toggleResolve(req, res) {
    try {
      const { id } = req.params;
      const { isResolved } = req.body;
      const result = await CrashService.toggleResolve(id, isResolved !== false);
      return res.json({ success: true, ...result });
    } catch (error) {
      console.error('[CrashController] Error updating crash resolve status:', error.message);
      return res.status(500).json({ success: false, error: error.message });
    }
  }
}
