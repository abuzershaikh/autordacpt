import { query } from '../../config/database.js';

export class VersionService {
  /**
   * Check app version, auto-detect new versions from live client apps,
   * and determine whether update or blocking is required.
   */
  static async checkAppVersion({ versionCode, versionName, userId, deviceId }) {
    const vCode = parseInt(versionCode, 10) || 1;
    const vName = String(versionName || '1.0.0').trim();

    // 1. Fetch current version record from database
    const rows = await query('SELECT * FROM app_versions WHERE version_code = ? LIMIT 1', [vCode]);

    let currentVersionRecord = rows && rows.length > 0 ? rows[0] : null;

    // 2. Auto-detect & auto-register new version if not in database
    if (!currentVersionRecord) {
      try {
        await query(
          `INSERT INTO app_versions 
            (version_name, version_code, download_url, is_force_update, is_blocked, update_title, update_message, release_notes, device_count)
           VALUES (?, ?, ?, FALSE, FALSE, 'Auto-detected Version', 'Detected from active driver device', 'Auto-registered by VPS Engine', 1)
           ON DUPLICATE KEY UPDATE device_count = device_count + 1`,
          [vName, vCode, 'http://65.20.77.112:5000/download/latest.apk']
        );
        const recheck = await query('SELECT * FROM app_versions WHERE version_code = ? LIMIT 1', [vCode]);
        if (recheck && recheck.length > 0) {
          currentVersionRecord = recheck[0];
        }
      } catch (err) {
        console.error('Auto-detect version insert error:', err);
      }
    } else {
      // Increment device ping count asynchronously
      query('UPDATE app_versions SET device_count = device_count + 1 WHERE id = ?', [currentVersionRecord.id]).catch(() => {});
    }

    // 3. Fetch global settings
    const settingsRows = await query('SELECT setting_key, setting_value FROM app_settings');
    const settingsMap = {};
    for (const row of settingsRows) {
      settingsMap[row.setting_key] = row.setting_value;
    }

    const minVersionCode = parseInt(settingsMap['min_version_code'] || '1', 10);
    const globalForceUpdate = settingsMap['global_force_update'] === '1' || settingsMap['global_force_update'] === 'true';
    const globalDownloadUrl = settingsMap['global_download_url'] || 'http://65.20.77.112:5000/download/latest.apk';
    const globalTitle = settingsMap['global_update_title'] || '🚀 Naya Update Aaya Hai!';
    const globalMessage = settingsMap['global_update_message'] || 'Purana version band ho gaya hai. Kripya naya version download aur install karein.';

    // 4. Find the latest active release
    const latestRows = await query(
      'SELECT * FROM app_versions WHERE is_blocked = FALSE ORDER BY version_code DESC LIMIT 1'
    );
    const latestRelease = latestRows && latestRows.length > 0 ? latestRows[0] : {
      version_name: settingsMap['latest_version_name'] || '1.0.0',
      version_code: parseInt(settingsMap['latest_version_code'] || '1', 10),
      download_url: globalDownloadUrl,
      update_title: globalTitle,
      update_message: globalMessage,
      release_notes: 'Includes auto-accept enhancements, bug fixes, and speed optimizations.',
      is_force_update: false
    };

    const isCurrentBlocked = currentVersionRecord ? Boolean(currentVersionRecord.is_blocked) : false;
    const isBelowMin = vCode < minVersionCode;
    const isNewerAvailable = latestRelease.version_code > vCode;

    // Force lock screen ONLY when:
    // 1. Version is explicitly marked BLOCKED by admin in panel (isCurrentBlocked)
    // 2. OR global emergency killswitch is active (globalForceUpdate)
    // 3. OR version is below min_version_code AND not explicitly enabled by admin
    let isForceUpdate = false;
    if (isCurrentBlocked || globalForceUpdate) {
      isForceUpdate = true;
    } else if (isNewerAvailable && isBelowMin && (currentVersionRecord ? Boolean(currentVersionRecord.is_blocked) : true)) {
      isForceUpdate = true;
    } else {
      isForceUpdate = false;
    }

    return {
      success: true,
      update_available: isNewerAvailable,
      is_force_update: isForceUpdate,
      is_blocked: isCurrentBlocked,
      current_version_name: vName,
      current_version_code: vCode,
      min_supported_version_code: minVersionCode,
      latest_version_name: latestRelease.version_name,
      latest_version_code: latestRelease.version_code,
      download_url: latestRelease.download_url || globalDownloadUrl,
      update_title: isCurrentBlocked 
        ? '⛔ Version Disabled / Update Required'
        : (latestRelease.update_title || globalTitle),
      update_message: isCurrentBlocked
        ? (currentVersionRecord?.update_message || 'Aapka yeh purana version band kar diya gaya hai. Kripya new version install karein.')
        : (latestRelease.update_message || globalMessage),
      release_notes: latestRelease.release_notes || 'Continuous background auto-accept performance upgrades.'
    };
  }

  /**
   * Get all versions and global configuration for admin panel
   */
  static async getAllVersions() {
    const versions = await query(
      'SELECT id, version_name, version_code, download_url, is_force_update, is_blocked, update_title, update_message, release_notes, device_count, created_at, updated_at FROM app_versions ORDER BY version_code DESC'
    );

    const settingsRows = await query('SELECT setting_key, setting_value FROM app_settings');
    const settingsMap = {};
    for (const row of settingsRows) {
      settingsMap[row.setting_key] = row.setting_value;
    }

    return {
      versions: versions || [],
      config: {
        min_version_code: parseInt(settingsMap['min_version_code'] || '1', 10),
        latest_version_code: parseInt(settingsMap['latest_version_code'] || '1', 10),
        latest_version_name: settingsMap['latest_version_name'] || '1.0.0',
        global_force_update: settingsMap['global_force_update'] === '1' || settingsMap['global_force_update'] === 'true',
        global_download_url: settingsMap['global_download_url'] || 'http://65.20.77.112:5000/download/latest.apk',
        global_update_title: settingsMap['global_update_title'] || '🚀 Naya Update Aaya Hai!',
        global_update_message: settingsMap['global_update_message'] || 'Purana version band ho gaya hai. Auto-accept continue rakhne ke liye abhi naya version install karein.'
      }
    };
  }

  /**
   * Deploy or update an APK release
   */
  static async createOrUpdateRelease({
    versionName,
    versionCode,
    downloadUrl,
    isForceUpdate,
    updateTitle,
    updateMessage,
    releaseNotes
  }) {
    const vCode = parseInt(versionCode, 10);
    if (!vCode || vCode <= 0) {
      throw new Error('Valid integer versionCode is required.');
    }
    const vName = String(versionName || '').trim();
    if (!vName) {
      throw new Error('versionName is required.');
    }

    const dUrl = String(downloadUrl || 'http://65.20.77.112:5000/download/latest.apk').trim();
    const isForce = Boolean(isForceUpdate);
    const title = String(updateTitle || '🚀 Naya Update Aaya Hai!').trim();
    const msg = String(updateMessage || 'Purana version band ho gaya hai. Kripya naya version download aur install karein.').trim();
    const notes = String(releaseNotes || 'Bug fixes and speed improvements.').trim();

    await query(
      `INSERT INTO app_versions 
        (version_name, version_code, download_url, is_force_update, is_blocked, update_title, update_message, release_notes, device_count)
       VALUES (?, ?, ?, ?, FALSE, ?, ?, ?, 0)
       ON DUPLICATE KEY UPDATE 
        version_name = VALUES(version_name),
        download_url = VALUES(download_url),
        is_force_update = VALUES(is_force_update),
        update_title = VALUES(update_title),
        update_message = VALUES(update_message),
        release_notes = VALUES(release_notes)`,
      [vName, vCode, dUrl, isForce, title, msg, notes]
    );

    // Update global latest version settings
    await query(
      `INSERT INTO app_settings (setting_key, setting_value) VALUES 
        ('latest_version_code', ?),
        ('latest_version_name', ?),
        ('global_download_url', ?),
        ('global_update_title', ?),
        ('global_update_message', ?)
       ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)`,
      [String(vCode), vName, dUrl, title, msg]
    );

    if (isForce) {
      // Mark all older versions as is_blocked = TRUE in the database
      // so table accurately reflects 'BLOCKED & DISABLED' and older apps are locked!
      await query('UPDATE app_versions SET is_blocked = TRUE WHERE version_code < ?', [vCode]);
      await query(
        `INSERT INTO app_settings (setting_key, setting_value) VALUES ('min_version_code', ?)
         ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)`,
        [String(vCode)]
      );
    }

    return await this.getAllVersions();
  }

  /**
   * Toggle block status for a specific version
   */
  static async toggleBlockVersion(id) {
    const rows = await query('SELECT id, version_code, is_blocked FROM app_versions WHERE id = ?', [id]);
    if (!rows || rows.length === 0) {
      throw new Error('Version record not found');
    }

    const currentStatus = Boolean(rows[0].is_blocked);
    const newStatus = !currentStatus;
    const vCode = rows[0].version_code;

    await query('UPDATE app_versions SET is_blocked = ? WHERE id = ?', [newStatus, id]);

    // If admin explicitly enabled this version (newStatus === false),
    // ensure min_version_code does not secretly block it
    if (newStatus === false) {
      const minRow = await query("SELECT setting_value FROM app_settings WHERE setting_key = 'min_version_code'");
      const currentMin = parseInt(minRow?.[0]?.setting_value || '1', 10);
      if (currentMin > vCode) {
        await query("UPDATE app_settings SET setting_value = ? WHERE setting_key = 'min_version_code'", [String(vCode)]);
      }
    }

    return { id, is_blocked: newStatus };
  }

  /**
   * Delete a version record
   */
  static async deleteVersion(id) {
    await query('DELETE FROM app_versions WHERE id = ?', [id]);
    return { success: true };
  }

  /**
   * Update global version settings
   */
  static async updateGlobalConfig({
    minSupportedCode,
    globalDownloadUrl,
    globalForceUpdate,
    globalUpdateTitle,
    globalUpdateMessage
  }) {
    if (minSupportedCode !== undefined) {
      await query(
        "INSERT INTO app_settings (setting_key, setting_value) VALUES ('min_version_code', ?) ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)",
        [String(minSupportedCode)]
      );
    }
    if (globalDownloadUrl !== undefined) {
      await query(
        "INSERT INTO app_settings (setting_key, setting_value) VALUES ('global_download_url', ?) ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)",
        [String(globalDownloadUrl)]
      );
    }
    if (globalForceUpdate !== undefined) {
      await query(
        "INSERT INTO app_settings (setting_key, setting_value) VALUES ('global_force_update', ?) ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)",
        [globalForceUpdate ? '1' : '0']
      );
    }
    if (globalUpdateTitle !== undefined) {
      await query(
        "INSERT INTO app_settings (setting_key, setting_value) VALUES ('global_update_title', ?) ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)",
        [String(globalUpdateTitle)]
      );
    }
    if (globalUpdateMessage !== undefined) {
      await query(
        "INSERT INTO app_settings (setting_key, setting_value) VALUES ('global_update_message', ?) ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)",
        [String(globalUpdateMessage)]
      );
    }

    return await this.getAllVersions();
  }
}
