import crypto from 'crypto';
import Razorpay from 'razorpay';
import { pool } from '../../config/database.js';
import { config } from '../../config/env.js';
import { db as firestore, firebaseReady } from '../../config/firebase.js';

let cachedGatewayConfig = null;
let cacheExpiryTime = 0;
const CACHE_TTL_MS = 15000; // 15 seconds cache

export class PaymentService {
  /**
   * Fetch active Razorpay credentials dynamically from MySQL (with auto-cache)
   */
  static async getActiveGatewayConfig(forceRefresh = false) {
    const now = Date.now();
    if (!forceRefresh && cachedGatewayConfig && now < cacheExpiryTime) {
      return cachedGatewayConfig;
    }

    try {
      const [rows] = await pool.query(
        'SELECT * FROM payment_gateway_config WHERE is_active = TRUE ORDER BY id DESC LIMIT 1'
      );

      if (rows && rows.length > 0) {
        cachedGatewayConfig = rows[0];
        cacheExpiryTime = now + CACHE_TTL_MS;
        return cachedGatewayConfig;
      }
    } catch (err) {
      console.error('[PaymentService] Error querying payment_gateway_config from MySQL:', err.message);
    }

    // Fallback if DB empty or error
    return {
      id: 0,
      gateway_name: 'razorpay',
      is_active: 1,
      is_live_mode: config.razorpayFallback.mode === 'live' ? 1 : 0,
      key_id: config.razorpayFallback.keyId,
      key_secret: config.razorpayFallback.keySecret,
      webhook_secret: config.razorpayFallback.webhookSecret,
      account_label: 'Fallback Config',
      currency: 'INR',
    };
  }

  /**
   * Invalidate cached credentials (called whenever admin saves settings)
   */
  static invalidateCache() {
    cachedGatewayConfig = null;
    cacheExpiryTime = 0;
  }

  /**
   * Instantiate on-demand Razorpay SDK client with active credentials
   */
  static async getRazorpayClient() {
    const gateway = await this.getActiveGatewayConfig();
    return new Razorpay({
      key_id: gateway.key_id,
      key_secret: gateway.key_secret,
    });
  }

  /**
   * Fetch active subscription plans for mobile app / web
   */
  static async getActivePlans() {
    const [rows] = await pool.query(
      'SELECT * FROM subscription_plans WHERE is_active = TRUE ORDER BY order_index ASC'
    );

    return rows.map((plan) => {
      let features = [];
      try {
        features = plan.features_json ? JSON.parse(plan.features_json) : [];
      } catch (e) {
        features = [];
      }
      return {
        id: plan.id,
        title: plan.title,
        price: parseFloat(plan.price),
        original_price: plan.original_price ? parseFloat(plan.original_price) : null,
        duration_text: plan.duration_text,
        validity_days: plan.validity_days,
        badge: plan.badge,
        is_lifetime: Boolean(plan.is_lifetime),
        is_popular: Boolean(plan.is_popular),
        is_active: Boolean(plan.is_active),
        order_index: plan.order_index,
        features,
      };
    });
  }

  /**
   * Fetch all subscription plans for Admin Control Panel
   */
  static async getAllAdminPlans() {
    const [rows] = await pool.query('SELECT * FROM subscription_plans ORDER BY order_index ASC');

    return rows.map((plan) => {
      let features = [];
      try {
        features = plan.features_json ? JSON.parse(plan.features_json) : [];
      } catch (e) {
        features = [];
      }
      return {
        ...plan,
        price: parseFloat(plan.price),
        original_price: plan.original_price ? parseFloat(plan.original_price) : null,
        is_lifetime: Boolean(plan.is_lifetime),
        is_popular: Boolean(plan.is_popular),
        is_active: Boolean(plan.is_active),
        features,
      };
    });
  }

  /**
   * Create Razorpay Order with active live credentials
   */
  static async createOrder({ userId, planId, userPhone, userEmail }) {
    if (!userId || !planId) {
      throw new Error('userId and planId are required to create an order');
    }

    // 1. Fetch Plan details from MySQL
    const [plans] = await pool.query('SELECT * FROM subscription_plans WHERE id = ? AND is_active = TRUE LIMIT 1', [
      planId,
    ]);

    if (!plans || plans.length === 0) {
      throw new Error(`Plan with ID '${planId}' not found or inactive`);
    }

    const plan = plans[0];
    const amountInRupees = parseFloat(plan.price);
    const amountInPaise = Math.round(amountInRupees * 100);

    // 2. Fetch Active Gateway
    const gateway = await this.getActiveGatewayConfig();
    const rzp = await this.getRazorpayClient();

    // 3. Create Order via Razorpay API
    const receiptId = `rcpt_${Date.now()}_${userId.slice(0, 6)}`;
    const orderOptions = {
      amount: amountInPaise,
      currency: 'INR',
      receipt: receiptId,
      notes: {
        userId,
        planId: plan.id,
        planTitle: plan.title,
        validityDays: String(plan.validity_days),
      },
    };

    const razorpayOrder = await rzp.orders.create(orderOptions);

    // 4. Log Transaction in MySQL
    await pool.query(
      `INSERT INTO payment_transactions 
        (order_id, user_id, user_phone, user_email, plan_id, plan_title, amount, currency, status, razorpay_key_id)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'INR', 'created', ?)`,
      [
        razorpayOrder.id,
        userId,
        userPhone || null,
        userEmail || null,
        plan.id,
        plan.title,
        amountInRupees,
        gateway.key_id,
      ]
    );

    return {
      orderId: razorpayOrder.id,
      amount: amountInRupees,
      amountInPaise,
      currency: 'INR',
      keyId: gateway.key_id,
      planId: plan.id,
      planTitle: plan.title,
      isLiveMode: Boolean(gateway.is_live_mode),
    };
  }

  /**
   * Verify HMAC-SHA256 signature from Client SDK & Activate Access
   */
  static async verifyPayment({ orderId, paymentId, signature, userId }) {
    if (!orderId || !paymentId || !signature) {
      throw new Error('orderId, paymentId and signature are required for verification');
    }

    const gateway = await this.getActiveGatewayConfig();
    const generatedSignature = crypto
      .createHmac('sha256', gateway.key_secret)
      .update(`${orderId}|${paymentId}`)
      .digest('hex');

    const isValid = crypto.timingSafeEqual(Buffer.from(generatedSignature), Buffer.from(signature));

    if (!isValid) {
      // Mark transaction failed
      await pool.query('UPDATE payment_transactions SET status = "failed", error_reason = "Signature mismatch" WHERE order_id = ?', [
        orderId,
      ]);
      throw new Error('Invalid payment signature verification failed');
    }

    // 1. Fetch transaction details
    const [txRows] = await pool.query('SELECT * FROM payment_transactions WHERE order_id = ? LIMIT 1', [orderId]);
    const tx = txRows[0];
    const finalUserId = userId || (tx ? tx.user_id : null);
    const planId = tx ? tx.plan_id : 'daily';

    // 2. Mark transaction paid
    await pool.query(
      'UPDATE payment_transactions SET status = "paid", payment_id = ?, signature = ?, updated_at = NOW() WHERE order_id = ?',
      [paymentId, signature, orderId]
    );

    // 3. Activate plan in MySQL & Firebase
    await this.activateSubscription({
      userId: finalUserId,
      planId,
      paymentId,
      orderId,
      amount: tx ? tx.amount : 0,
    });

    return {
      success: true,
      message: 'Payment verified and plan activated successfully!',
      orderId,
      paymentId,
    };
  }

  /**
   * Unified Webhook Processor (Verifies against MySQL webhook_secret)
   */
  static async processWebhook(rawBody, signatureHeader) {
    const gateway = await this.getActiveGatewayConfig();
    const webhookSecret = gateway.webhook_secret;

    if (!webhookSecret || webhookSecret === 'rzp_webhook_secret_placeholder') {
      console.warn('[Webhook] Warning: Webhook secret not configured in MySQL');
    }

    // Verify webhook signature
    const expectedSignature = crypto
      .createHmac('sha256', webhookSecret)
      .update(rawBody)
      .digest('hex');

    if (expectedSignature !== signatureHeader) {
      console.error('[Webhook] Signature mismatch! Received:', signatureHeader, 'Expected:', expectedSignature);
      throw new Error('Invalid webhook signature');
    }

    const event = JSON.parse(rawBody.toString());
    console.log(`[Webhook Event Received] ${event.event} at ${new Date().toISOString()}`);

    if (event.event === 'payment.captured' || event.event === 'order.paid') {
      const paymentEntity = event.payload.payment ? event.payload.payment.entity : null;
      const orderId = paymentEntity ? paymentEntity.order_id : null;
      const paymentId = paymentEntity ? paymentEntity.id : null;
      const notes = paymentEntity ? paymentEntity.notes || {} : {};

      const userId = notes.userId;
      const planId = notes.planId;

      if (orderId) {
        await pool.query(
          'UPDATE payment_transactions SET status = "paid", payment_id = ?, updated_at = NOW() WHERE order_id = ?',
          [paymentId, orderId]
        );
      }

      if (userId && planId) {
        await this.activateSubscription({
          userId,
          planId,
          paymentId,
          orderId,
          amount: paymentEntity ? paymentEntity.amount / 100 : 0,
        });
      }
    }

    return { received: true, event: event.event };
  }

  /**
   * Activate Subscription in both MySQL and Cloud Firestore
   */
  static async activateSubscription({ userId, planId, paymentId, orderId, amount }) {
    if (!userId) return;

    // Fetch plan details to calculate expiry
    const [plans] = await pool.query('SELECT * FROM subscription_plans WHERE id = ? LIMIT 1', [planId]);
    const plan = plans[0] || { validity_days: 1, title: 'Subscription', is_lifetime: 0 };

    let expiresAt = null;
    if (plan.validity_days > 0) {
      const d = new Date();
      d.setDate(d.getDate() + plan.validity_days);
      expiresAt = d;
    } else {
      // Lifetime (100 years ahead)
      const d = new Date();
      d.setFullYear(d.getFullYear() + 100);
      expiresAt = d;
    }

    // 1. Update MySQL users table
    await pool.query(
      `UPDATE users 
       SET plan_id = ?, 
           plan_name = ?, 
           plan_status = 'active', 
           plan_expires_at = ?,
           updated_at = NOW() 
       WHERE id = ?`,
      [plan.id, plan.title, expiresAt, userId]
    );

    // 2. Sync to Firebase Cloud Firestore
    if (firebaseReady && firestore) {
      try {
        const userRef = firestore.collection('users').doc(userId);
        const expiresIso = expiresAt.toISOString();

        await userRef.set(
          {
            planId: plan.id,
            planName: plan.title,
            planStatus: 'active',
            planExpiresAt: expiresIso,
            isSubscribed: true,
            lastPaymentId: paymentId || '',
            lastOrderId: orderId || '',
            lastPaymentAmount: amount || 0,
            updatedAt: new Date().toISOString(),
          },
          { merge: true }
        );

        // Also update subcollection billing/timed_access
        const billingRef = userRef.collection('billing').doc('timed_access');
        await billingRef.set(
          {
            status: 'active',
            planId: plan.id,
            planTitle: plan.title,
            expiresAt: expiresIso,
            activatedAt: new Date().toISOString(),
            paymentId: paymentId || '',
            orderId: orderId || '',
          },
          { merge: true }
        );

        console.log(`✅ [PaymentService] User ${userId} activated in Firestore until ${expiresIso}`);
      } catch (err) {
        console.error('⚠️ [PaymentService] Firestore sync warning:', err.message);
      }
    }
  }

  /**
   * Admin: Save or Update Live Razorpay Config in MySQL
   */
  static async updateGatewayConfig({ key_id, key_secret, webhook_secret, is_live_mode, account_label }) {
    if (!key_id || !key_secret) {
      throw new Error('key_id and key_secret are required');
    }

    const liveModeInt = is_live_mode ? 1 : 0;
    const label = account_label || (is_live_mode ? 'Production Live Account' : 'Test Sandbox Account');
    const whSecret = webhook_secret || 'whsec_' + crypto.randomBytes(8).toString('hex');

    // Deactivate old configs
    await pool.query('UPDATE payment_gateway_config SET is_active = FALSE');

    // Insert new active config
    const [res] = await pool.query(
      `INSERT INTO payment_gateway_config 
        (gateway_name, is_active, is_live_mode, key_id, key_secret, webhook_secret, account_label)
       VALUES ('razorpay', TRUE, ?, ?, ?, ?, ?)`,
      [liveModeInt, key_id, key_secret, whSecret, label]
    );

    // Invalidate memory cache immediately
    this.invalidateCache();

    console.log(`💳 [Payment Gateway Updated] Switched to Key: ${key_id.slice(0, 12)}... (Live: ${Boolean(is_live_mode)})`);
    return {
      id: res.insertId,
      key_id,
      is_live_mode: Boolean(is_live_mode),
      account_label: label,
      webhook_secret: whSecret,
    };
  }

  /**
   * Admin: Update Plan Details & Price
   */
  static async updatePlan(planId, data) {
    const fields = [];
    const values = [];

    if (data.price !== undefined) {
      fields.push('price = ?');
      values.push(parseFloat(data.price));
    }
    if (data.original_price !== undefined) {
      fields.push('original_price = ?');
      values.push(data.original_price ? parseFloat(data.original_price) : null);
    }
    if (data.title !== undefined) {
      fields.push('title = ?');
      values.push(data.title);
    }
    if (data.duration_text !== undefined) {
      fields.push('duration_text = ?');
      values.push(data.duration_text);
    }
    if (data.validity_days !== undefined) {
      fields.push('validity_days = ?');
      values.push(parseInt(data.validity_days, 10));
    }
    if (data.badge !== undefined) {
      fields.push('badge = ?');
      values.push(data.badge);
    }
    if (data.is_popular !== undefined) {
      fields.push('is_popular = ?');
      values.push(data.is_popular ? 1 : 0);
    }
    if (data.is_active !== undefined) {
      fields.push('is_active = ?');
      values.push(data.is_active ? 1 : 0);
    }
    if (data.order_index !== undefined) {
      fields.push('order_index = ?');
      values.push(parseInt(data.order_index, 10));
    }
    if (data.features !== undefined) {
      fields.push('features_json = ?');
      values.push(JSON.stringify(data.features));
    }

    if (fields.length === 0) return false;

    values.push(planId);
    await pool.query(`UPDATE subscription_plans SET ${fields.join(', ')}, updated_at = NOW() WHERE id = ?`, values);
    return true;
  }

  /**
   * Admin: Create New Plan
   */
  static async createPlan(data) {
    const id = data.id || `plan_${Date.now()}`;
    const title = data.title || 'New Subscription';
    const price = parseFloat(data.price || 0);
    const origPrice = data.original_price ? parseFloat(data.original_price) : null;
    const durationText = data.duration_text || 'Access';
    const validityDays = parseInt(data.validity_days || 1, 10);
    const badge = data.badge || null;
    const isPopular = data.is_popular ? 1 : 0;
    const isLifetime = data.is_lifetime || validityDays === -1 ? 1 : 0;
    const isActive = data.is_active !== undefined ? (data.is_active ? 1 : 0) : 1;
    const orderIndex = parseInt(data.order_index || 99, 10);
    const featuresJson = JSON.stringify(data.features || []);

    await pool.query(
      `INSERT INTO subscription_plans 
        (id, title, price, original_price, duration_text, validity_days, badge, is_lifetime, is_popular, is_active, order_index, features_json)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [id, title, price, origPrice, durationText, validityDays, badge, isLifetime, isPopular, isActive, orderIndex, featuresJson]
    );

    return { id, title, price };
  }

  /**
   * Admin: Get Transactions History
   */
  static async getTransactions({ page = 1, limit = 20, status = '' } = {}) {
    const offset = (page - 1) * limit;
    let query = 'SELECT * FROM payment_transactions';
    const params = [];

    if (status) {
      query += ' WHERE status = ?';
      params.push(status);
    }

    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit, 10), parseInt(offset, 10));

    const [rows] = await pool.query(query, params);

    const [countRows] = await pool.query(
      status
        ? 'SELECT COUNT(*) as total FROM payment_transactions WHERE status = ?'
        : 'SELECT COUNT(*) as total FROM payment_transactions',
      status ? [status] : []
    );

    const [revenueRows] = await pool.query(
      'SELECT SUM(amount) as total_revenue, COUNT(*) as total_sales FROM payment_transactions WHERE status = "paid"'
    );

    return {
      transactions: rows,
      total: countRows[0].total,
      page,
      limit,
      revenueStats: {
        totalRevenue: parseFloat(revenueRows[0].total_revenue || 0),
        totalSales: parseInt(revenueRows[0].total_sales || 0, 10),
      },
    };
  }
}
