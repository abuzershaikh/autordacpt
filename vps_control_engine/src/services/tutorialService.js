import { query, execute } from '../../config/database.js';

export class TutorialService {
  /**
   * Helper to parse YouTube video ID from various link formats
   */
  static extractYouTubeId(url) {
    if (!url) return '';
    const cleanUrl = url.trim();
    const regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|&v=|shorts\/)([^#&?]*).*/;
    const match = cleanUrl.match(regExp);
    return match && match[2].length === 11 ? match[2] : cleanUrl;
  }

  /**
   * Get all active tutorials for mobile app
   */
  static async getMobileTutorials(category = null) {
    let sql = `
      SELECT id, title, description, youtube_url, youtube_id, thumbnail_url, category, order_index
      FROM tutorials
      WHERE is_active = TRUE
    `;
    const params = [];

    if (category && category !== 'all') {
      sql += ' AND category = ?';
      params.push(category.toLowerCase());
    }

    sql += ' ORDER BY order_index ASC, id ASC';

    const rows = await query(sql, params);
    return rows;
  }

  /**
   * Admin: Get all tutorials (active and inactive)
   */
  static async getAllTutorials() {
    const sql = `
      SELECT * FROM tutorials 
      ORDER BY order_index ASC, id DESC
    `;
    return await query(sql);
  }

  /**
   * Admin: Create a new tutorial video
   */
  static async createTutorial({ title, description, youtubeUrl, category = 'general', orderIndex = 0 }) {
    const youtubeId = this.extractYouTubeId(youtubeUrl);
    const thumbnailUrl = `https://img.youtube.com/vi/${youtubeId}/hqdefault.jpg`;

    const sql = `
      INSERT INTO tutorials (title, description, youtube_url, youtube_id, thumbnail_url, category, order_index, is_active)
      VALUES (?, ?, ?, ?, ?, ?, ?, TRUE)
    `;

    const result = await execute(sql, [
      title,
      description || '',
      youtubeUrl,
      youtubeId,
      thumbnailUrl,
      category.toLowerCase(),
      parseInt(orderIndex, 10) || 0,
    ]);

    return { id: result.insertId, title, youtubeId, thumbnailUrl };
  }

  /**
   * Admin: Update an existing tutorial
   */
  static async updateTutorial(id, { title, description, youtubeUrl, category, orderIndex, isActive }) {
    const updates = [];
    const params = [];

    if (title !== undefined) {
      updates.push('title = ?');
      params.push(title);
    }
    if (description !== undefined) {
      updates.push('description = ?');
      params.push(description);
    }
    if (youtubeUrl !== undefined) {
      const youtubeId = this.extractYouTubeId(youtubeUrl);
      const thumbnailUrl = `https://img.youtube.com/vi/${youtubeId}/hqdefault.jpg`;
      updates.push('youtube_url = ?', 'youtube_id = ?', 'thumbnail_url = ?');
      params.push(youtubeUrl, youtubeId, thumbnailUrl);
    }
    if (category !== undefined) {
      updates.push('category = ?');
      params.push(category.toLowerCase());
    }
    if (orderIndex !== undefined) {
      updates.push('order_index = ?');
      params.push(parseInt(orderIndex, 10));
    }
    if (isActive !== undefined) {
      updates.push('is_active = ?');
      params.push(isActive ? 1 : 0);
    }

    if (updates.length === 0) return { id, updated: false };

    const sql = `UPDATE tutorials SET ${updates.join(', ')}, updated_at = NOW() WHERE id = ?`;
    params.push(id);

    await execute(sql, params);
    return { id, updated: true };
  }

  /**
   * Admin: Delete tutorial
   */
  static async deleteTutorial(id) {
    const sql = 'DELETE FROM tutorials WHERE id = ?';
    await execute(sql, [id]);
    return { id, deleted: true };
  }
}
