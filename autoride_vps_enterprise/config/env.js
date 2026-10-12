import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config({ path: path.resolve(__dirname, '../.env') });

export const config = {
  port: parseInt(process.env.PORT || '5000', 10),
  nodeEnv: process.env.NODE_ENV || 'production',
  serverBaseUrl: process.env.SERVER_BASE_URL || 'http://139.84.158.149:5000',
  db: {
    host: process.env.DB_HOST || '127.0.0.1',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'autoride_control_db',
    connectionLimit: parseInt(process.env.DB_CONNECTION_LIMIT || '25', 10),
  },
  admin: {
    username: process.env.ADMIN_USERNAME || 'admin',
    password: process.env.ADMIN_PASSWORD || 'admin123',
    jwtSecret: process.env.JWT_SECRET || 'autoride_enterprise_jwt_secure_key_2026_x89',
  },
  firebase: {
    serviceAccountPath: process.env.FIREBASE_SERVICE_ACCOUNT_PATH || path.resolve(__dirname, 'serviceAccountKey.json'),
  },
  razorpayFallback: {
    keyId: process.env.FALLBACK_RAZORPAY_KEY_ID || 'rzp_test_1DP5mmOlF5G5ag',
    keySecret: process.env.FALLBACK_RAZORPAY_KEY_SECRET || 'secret_placeholder',
    webhookSecret: process.env.FALLBACK_RAZORPAY_WEBHOOK_SECRET || 'webhook_secret_placeholder',
    mode: process.env.FALLBACK_RAZORPAY_MODE || 'test',
  },
  defaultFreeRidesLimit: parseInt(process.env.DEFAULT_FREE_RIDES_LIMIT || '10', 10),
};
