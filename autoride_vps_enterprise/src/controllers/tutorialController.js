import { TutorialService } from '../services/tutorialService.js';

export class TutorialController {
  /**
   * Mobile app GET /api/tutorials
   */
  static async getMobileTutorials(req, res) {
    try {
      const { category } = req.query;
      const tutorials = await TutorialService.getMobileTutorials(category);
      return res.json({ success: true, count: tutorials.length, data: tutorials });
    } catch (error) {
      console.error('[TutorialController] Error fetching tutorials for mobile:', error.message);
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  /**
   * Admin GET /api/admin/tutorials
   */
  static async getAllTutorials(req, res) {
    try {
      const tutorials = await TutorialService.getAllTutorials();
      return res.json({ success: true, count: tutorials.length, data: tutorials });
    } catch (error) {
      console.error('[TutorialController] Error fetching all tutorials:', error.message);
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  /**
   * Admin POST /api/admin/tutorials
   */
  static async createTutorial(req, res) {
    try {
      const title = req.body.title;
      const youtubeUrl = req.body.youtubeUrl || req.body.youtube_url;
      const description = req.body.description;
      const category = req.body.category;
      const orderIndex = req.body.orderIndex || req.body.order_index;

      if (!title || !youtubeUrl) {
        return res.status(400).json({ success: false, error: 'Title and YouTube URL are required' });
      }

      const result = await TutorialService.createTutorial({
        title,
        description,
        youtubeUrl,
        category,
        orderIndex,
      });

      return res.status(201).json({ success: true, ...result });
    } catch (error) {
      console.error('[TutorialController] Error creating tutorial:', error.message);
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  /**
   * Admin PUT /api/admin/tutorials/:id
   */
  static async updateTutorial(req, res) {
    try {
      const { id } = req.params;
      const result = await TutorialService.updateTutorial(id, req.body);
      return res.json({ success: true, ...result });
    } catch (error) {
      console.error('[TutorialController] Error updating tutorial:', error.message);
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  /**
   * Admin DELETE /api/admin/tutorials/:id
   */
  static async deleteTutorial(req, res) {
    try {
      const { id } = req.params;
      const result = await TutorialService.deleteTutorial(id);
      return res.json({ success: true, ...result });
    } catch (error) {
      console.error('[TutorialController] Error deleting tutorial:', error.message);
      return res.status(500).json({ success: false, error: error.message });
    }
  }
}
