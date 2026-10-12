import Razorpay from 'razorpay';
import { PaymentService } from '../services/paymentService.js';

export class AdminPaymentController {
  /**
   * GET /api/admin/payment/config
   * Fetch current active Razorpay configuration
   */
  static async getConfig(req, res) {
    try {
      const config = await PaymentService.getActiveGatewayConfig(true);
      return res.json({
        success: true,
        gateway: {
          id: config.id,
          key_id: config.key_id,
          // Show preview of secret for security
          key_secret_masked: config.key_secret
            ? config.key_secret.slice(0, 4) + '••••••••••••' + config.key_secret.slice(-4)
            : '',
          key_secret: config.key_secret,
          webhook_secret: config.webhook_secret,
          is_live_mode: Boolean(config.is_live_mode),
          account_label: config.account_label,
          currency: config.currency || 'INR',
          updated_at: config.updated_at,
        },
      });
    } catch (err) {
      console.error('[AdminPaymentController.getConfig Error]', err.message);
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  /**
   * POST /api/admin/payment/config
   * Live Update Razorpay account keys & webhook secret in MySQL
   */
  static async updateConfig(req, res) {
    try {
      const { key_id, key_secret, webhook_secret, is_live_mode, account_label } = req.body;

      if (!key_id || !key_secret) {
        return res.status(400).json({
          success: false,
          error: 'Razorpay Key ID and Key Secret are required',
        });
      }

      const result = await PaymentService.updateGatewayConfig({
        key_id: key_id.trim(),
        key_secret: key_secret.trim(),
        webhook_secret: (webhook_secret || '').trim(),
        is_live_mode: Boolean(is_live_mode),
        account_label: (account_label || '').trim(),
      });

      return res.json({
        success: true,
        message: 'Razorpay gateway configuration updated and activated successfully!',
        gateway: result,
      });
    } catch (err) {
      console.error('[AdminPaymentController.updateConfig Error]', err.message);
      return res.status(400).json({ success: false, error: err.message });
    }
  }

  /**
   * POST /api/admin/payment/test-credentials
   * Validates Razorpay credentials by calling Razorpay API directly
   */
  static async testCredentials(req, res) {
    try {
      const { key_id, key_secret } = req.body;
      const testKeyId = key_id || (await PaymentService.getActiveGatewayConfig()).key_id;
      const testKeySecret = key_secret || (await PaymentService.getActiveGatewayConfig()).key_secret;

      if (!testKeyId || !testKeySecret) {
        return res.status(400).json({
          success: false,
          error: 'Key ID and Key Secret are required to test',
        });
      }

      const rzp = new Razorpay({ key_id: testKeyId, key_secret: testKeySecret });

      // Fetch 1 payment to test auth
      await rzp.payments.all({ count: 1 });

      const isLive = testKeyId.startsWith('rzp_live_');

      return res.json({
        success: true,
        message: `Credentials are VALID! Connected to Razorpay ${isLive ? 'LIVE' : 'TEST'} account.`,
        mode: isLive ? 'live' : 'test',
      });
    } catch (err) {
      return res.status(400).json({
        success: false,
        error: `Razorpay connection failed: ${err.error ? err.error.description : err.message}`,
      });
    }
  }

  /**
   * GET /api/admin/payment/plans
   * Fetch all plans for administration & pricing editing
   */
  static async getPlans(req, res) {
    try {
      const plans = await PaymentService.getAllAdminPlans();
      return res.json({ success: true, plans });
    } catch (err) {
      console.error('[AdminPaymentController.getPlans Error]', err.message);
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  /**
   * PUT /api/admin/payment/plans/:id
   * Update plan price, duration, features, or active status
   */
  static async updatePlan(req, res) {
    try {
      const { id } = req.params;
      const data = req.body;

      const updated = await PaymentService.updatePlan(id, data);
      if (!updated) {
        return res.status(404).json({ success: false, error: 'Plan not found or no changes supplied' });
      }

      return res.json({
        success: true,
        message: `Plan '${id}' updated successfully!`,
      });
    } catch (err) {
      console.error('[AdminPaymentController.updatePlan Error]', err.message);
      return res.status(400).json({ success: false, error: err.message });
    }
  }

  /**
   * POST /api/admin/payment/plans
   * Create new plan
   */
  static async createPlan(req, res) {
    try {
      const plan = await PaymentService.createPlan(req.body);
      return res.json({
        success: true,
        message: 'New subscription plan created successfully!',
        plan,
      });
    } catch (err) {
      console.error('[AdminPaymentController.createPlan Error]', err.message);
      return res.status(400).json({ success: false, error: err.message });
    }
  }

  /**
   * GET /api/admin/payment/transactions
   * View live payment feed & stats
   */
  static async getTransactions(req, res) {
    try {
      const page = parseInt(req.query.page || '1', 10);
      const limit = parseInt(req.query.limit || '20', 10);
      const status = req.query.status || '';

      const data = await PaymentService.getTransactions({ page, limit, status });
      return res.json({ success: true, ...data });
    } catch (err) {
      console.error('[AdminPaymentController.getTransactions Error]', err.message);
      return res.status(500).json({ success: false, error: err.message });
    }
  }
}
