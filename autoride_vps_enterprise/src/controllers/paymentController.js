import { PaymentService } from '../services/paymentService.js';

export class PaymentController {
  /**
   * GET /api/payment/plans
   * Mobile app calls this to get active subscription plans & the current active Razorpay Key ID
   */
  static async getPlans(req, res) {
    try {
      const plans = await PaymentService.getActivePlans();
      const gateway = await PaymentService.getActiveGatewayConfig();

      return res.json({
        success: true,
        currency: 'INR',
        razorpay_key_id: gateway.key_id,
        is_live_mode: Boolean(gateway.is_live_mode),
        account_label: gateway.account_label,
        plans,
      });
    } catch (err) {
      console.error('[PaymentController.getPlans Error]', err.message);
      return res.status(500).json({ success: false, error: err.message });
    }
  }

  /**
   * POST /api/payment/create-order
   * Mobile app calls this to generate an official Razorpay order with the active live credentials
   */
  static async createOrder(req, res) {
    try {
      const { userId, planId, userPhone, userEmail } = req.body;

      if (!userId || !planId) {
        return res.status(400).json({
          success: false,
          error: 'userId and planId are required',
        });
      }

      const orderData = await PaymentService.createOrder({
        userId,
        planId,
        userPhone,
        userEmail,
      });

      return res.json({
        success: true,
        order: orderData,
      });
    } catch (err) {
      console.error('[PaymentController.createOrder Error]', err.message);
      return res.status(400).json({ success: false, error: err.message });
    }
  }

  /**
   * POST /api/payment/verify
   * Mobile app submits paymentId, orderId, signature to verify and activate plan
   */
  static async verifyPayment(req, res) {
    try {
      const { orderId, paymentId, signature, userId } = req.body;

      if (!orderId || !paymentId || !signature) {
        return res.status(400).json({
          success: false,
          error: 'orderId, paymentId, and signature are required',
        });
      }

      const result = await PaymentService.verifyPayment({
        orderId,
        paymentId,
        signature,
        userId,
      });

      return res.json(result);
    } catch (err) {
      console.error('[PaymentController.verifyPayment Error]', err.message);
      return res.status(400).json({ success: false, error: err.message });
    }
  }

  /**
   * POST /api/payment/webhook
   * Unified Razorpay Webhook listener (verifies with dynamic webhook secret from MySQL)
   */
  static async handleWebhook(req, res) {
    try {
      const signature = req.headers['x-razorpay-signature'];
      // Raw body buffer is passed from express.raw or string
      const rawBody = req.rawBody || JSON.stringify(req.body);

      const result = await PaymentService.processWebhook(rawBody, signature);
      return res.json({ success: true, ...result });
    } catch (err) {
      console.error('[PaymentController.handleWebhook Error]', err.message);
      return res.status(400).json({ success: false, error: err.message });
    }
  }
}
