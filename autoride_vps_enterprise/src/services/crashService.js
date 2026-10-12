import { query, execute } from '../../config/database.js';

export class CrashService {
  /**
   * Log an application crash report from mobile app
   */
  static async recordCrash(crashData) {
    const userId = crashData.userId || crashData.uid || null;
    const errorMessage = crashData.errorMessage || crashData.error;
    const stackTrace = crashData.stackTrace || null;
    const screenName = crashData.screenName || null;
    const deviceBrand = crashData.deviceBrand || null;
    const deviceModel = crashData.deviceModel || null;
    const osVersion = crashData.osVersion || crashData.androidVersion || null;
    const appVersion = crashData.appVersion || '1.0.0';

    if (!errorMessage) {
      throw new Error('Error message is required for crash logging');
    }

    const sql = `
      INSERT INTO crashes (
        user_id, error_message, stack_trace, screen_name, 
        device_brand, device_model, os_version, app_version, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())
    `;

    const result = await execute(sql, [
      userId,
      errorMessage,
      stackTrace,
      screenName,
      deviceBrand,
      deviceModel,
      osVersion,
      appVersion,
    ]);

    return { id: result.insertId, logged: true };
  }

  /**
   * Get paginated crashes for admin inspector
   */
  static async getCrashes({ page = 1, limit = 20, isResolved = null, search = null }) {
    const offset = (page - 1) * limit;
    const whereClauses = [];
    const params = [];

    if (isResolved !== null && isResolved !== 'all') {
      whereClauses.push('c.is_resolved = ?');
      params.push(isResolved === 'true' || isResolved === 1 ? 1 : 0);
    }
    if (search) {
      whereClauses.push('(c.error_message LIKE ? OR c.screen_name LIKE ? OR c.device_model LIKE ? OR u.phone LIKE ?)');
      const term = `%${search}%`;
      params.push(term, term, term, term);
    }

    const whereSql = whereClauses.length > 0 ? `WHERE ${whereClauses.join(' AND ')}` : '';

    const countSql = `
      SELECT COUNT(*) as total 
      FROM crashes c 
      LEFT JOIN users u ON c.user_id = u.id 
      ${whereSql}
    `;
    const countResult = await query(countSql, params);
    const total = countResult[0]?.total || 0;

    const dataSql = `
      SELECT 
        c.id, c.user_id, c.error_message, c.stack_trace, c.screen_name, 
        c.device_brand, c.device_model, c.os_version, c.app_version, 
        c.is_resolved, c.created_at,
        u.phone as driver_phone, u.display_name as driver_name
      FROM crashes c
      LEFT JOIN users u ON c.user_id = u.id
      ${whereSql}
      ORDER BY c.created_at DESC
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
   * Toggle crash resolution state
   */
  static async toggleResolve(crashId, isResolved) {
    const sql = 'UPDATE crashes SET is_resolved = ? WHERE id = ?';
    await execute(sql, [isResolved ? 1 : 0, crashId]);
    return { id: crashId, isResolved };
  }
}
