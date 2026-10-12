import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { VersionService } from '../services/versionService.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export class VersionController {
  /**
   * Mobile app version check & auto-detection endpoint
   * GET /api/version/check?version_code=1&version_name=1.0.0&user_id=...
   */
  static async checkVersion(req, res) {
    try {
      const versionCode = req.query.version_code || req.query.versionCode || 1;
      const versionName = req.query.version_name || req.query.versionName || '1.0.0';
      const userId = req.query.user_id || req.query.userId || 'guest';
      const deviceId = req.query.device_id || req.query.deviceId || '';

      const result = await VersionService.checkAppVersion({
        versionCode,
        versionName,
        userId,
        deviceId
      });

      return res.json(result);
    } catch (err) {
      console.error('checkVersion error:', err);
      return res.status(500).json({
        success: false,
        error: err.message,
        is_force_update: false,
        is_blocked: false
      });
    }
  }

  /**
   * Serve latest APK file directly or redirect to external download URL
   * GET /download/latest.apk
   */
  static async downloadLatestApk(req, res) {
    try {
      // Check if local APK exists in uploads/releases
      const localApkPath = path.resolve(__dirname, '../../uploads/RideAutoAccept_latest.apk');
      if (fs.existsSync(localApkPath)) {
        res.setHeader('Content-Type', 'application/vnd.android.package-archive');
        res.setHeader('Content-Disposition', 'attachment; filename="RideAutoAccept_latest.apk"');
        return fs.createReadStream(localApkPath).pipe(res);
      }

      // Otherwise fetch latest download URL from settings
      const data = await VersionService.getAllVersions();
      const targetUrl = data.config.global_download_url;
      if (targetUrl && targetUrl.startsWith('http') && !targetUrl.includes('/download/latest.apk')) {
        return res.redirect(targetUrl);
      }

      // If no external URL, return informational download instruction page
      return res.status(404).send(`
        <html>
          <body style="font-family:sans-serif; text-align:center; padding:50px; background:#0f172a; color:#f8fafc;">
            <h2>🚀 Ride AutoAccept APK Release</h2>
            <p>Please configure the direct APK download URL in the VPS Control Panel under <strong>Version Control</strong>.</p>
          </body>
        </html>
      `);
    } catch (err) {
      return res.status(500).send('Error serving APK: ' + err.message);
    }
  }

  /**
   * Admin: Get all registered versions and config
   * GET /api/admin/versions
   */
  static async getAdminVersions(req, res) {
    try {
      const data = await VersionService.getAllVersions();
      return res.json({ success: true, ...data });
    } catch (err) {
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  /**
   * Admin: Publish or update an APK release
   * POST /api/admin/versions
   */
  static async createRelease(req, res) {
    try {
      const data = await VersionService.createOrUpdateRelease(req.body);
      return res.json({ success: true, message: 'Release published successfully', ...data });
    } catch (err) {
      return res.status(400).json({ success: false, error: err.message });
    }
  }

  /**
   * Admin: Toggle block / disable status for a version
   * PATCH /api/admin/versions/:id/toggle
   */
  static async toggleBlock(req, res) {
    try {
      const id = req.params.id;
      const result = await VersionService.toggleBlockVersion(id);
      return res.json({ success: true, ...result });
    } catch (err) {
      return res.status(400).json({ success: false, error: err.message });
    }
  }

  /**
   * Admin: Delete a version
   * DELETE /api/admin/versions/:id
   */
  static async deleteVersion(req, res) {
    try {
      const id = req.params.id;
      await VersionService.deleteVersion(id);
      return res.json({ success: true, message: 'Version deleted' });
    } catch (err) {
      return res.status(400).json({ success: false, error: err.message });
    }
  }

  /**
   * Admin: Update global version control config
   * POST /api/admin/versions/config
   */
  static async updateConfig(req, res) {
    try {
      const data = await VersionService.updateGlobalConfig(req.body);
      return res.json({ success: true, message: 'Global version config updated', ...data });
    } catch (err) {
      return res.status(400).json({ success: false, error: err.message });
    }
  }
}
