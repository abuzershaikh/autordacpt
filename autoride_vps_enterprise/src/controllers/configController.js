import { query, execute } from '../../config/database.js';

export class ConfigController {
  /**
   * Mobile app GET /api/config
   * Returns dynamic free rides limit & remote announcements
   */
  static async getMobileConfig(req, res) {
    try {
      const rows = await query('SELECT setting_key, setting_value FROM app_settings');
      const settings = {};
      for (const row of rows) {
        settings[row.setting_key] = row.setting_value;
      }

      return res.json({
        success: true,
        free_rides: parseInt(settings.free_rides_limit || '10', 10),
        freeRidesLimit: parseInt(settings.free_rides_limit || '10', 10),
        announcement: settings.announcement_text || '',
        isAnnouncementActive: settings.announcement_active === '1',
        minAppVersion: settings.min_app_version || '1.0.0',
      });
    } catch (error) {
      console.error('[ConfigController] Error getting mobile config:', error.message);
      // Fallback
      return res.json({
        success: true,
        free_rides: 10,
        freeRidesLimit: 10,
        announcement: '',
        isAnnouncementActive: false,
      });
    }
  }

  /**
   * Admin GET /api/admin/config
   */
  static async getAdminConfig(req, res) {
    try {
      const rows = await query('SELECT setting_key, setting_value, updated_at FROM app_settings');
      const settings = {};
      for (const row of rows) {
        settings[row.setting_key] = row.setting_value;
      }
      return res.json({ success: true, settings });
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  /**
   * Admin PUT /api/admin/config
   */
  static async updateAdminConfig(req, res) {
    try {
      const { free_rides_limit, announcement_text, announcement_active, min_app_version } = req.body;

      const updates = [];
      if (free_rides_limit !== undefined) {
        const parsedLimit = parseInt(free_rides_limit, 10);
        updates.push(['free_rides_limit', String(parsedLimit)]);
        await execute('UPDATE users SET free_rides_limit = ?', [parsedLimit]);
      }
      if (announcement_text !== undefined) {
        updates.push(['announcement_text', String(announcement_text)]);
      }
      if (announcement_active !== undefined) {
        updates.push(['announcement_active', announcement_active ? '1' : '0']);
      }
      if (min_app_version !== undefined) {
        updates.push(['min_app_version', String(min_app_version)]);
      }

      for (const [key, val] of updates) {
        await execute(
          'INSERT INTO app_settings (setting_key, setting_value) VALUES (?, ?) ON DUPLICATE KEY UPDATE setting_value = ?',
          [key, val, val]
        );
      }

      return res.json({ success: true, message: 'Settings updated successfully' });
    } catch (error) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }
}
