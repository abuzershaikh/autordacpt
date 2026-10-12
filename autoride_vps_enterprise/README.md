# 🚗 AutoRide Enterprise VPS Control Center & Dynamic Razorpay Gateway v2.0

Enterprise-grade Node.js + Express + MariaDB/MySQL control engine, live web dashboard, and dynamic payment gateway for **Ride AutoAccept** (Porter, Rapido, Ola, Uber).

---

## 🌟 Key Architecture Highlights

### 1. 💳 Dynamic Razorpay Multi-Account Switcher (Live at Runtime)
- **Zero App Updates Required:** Change your Razorpay account (Key ID, Key Secret, Webhook Secret) anytime directly from the Web Control Panel.
- **MySQL-Backed Storage:** All gateway credentials are stored securely in MariaDB/MySQL (`payment_gateway_config`).
- **High-Performance In-Memory Caching:** Credentials are cached in memory for 15s to withstand tens of thousands of requests per minute, and **cache-busted instantly** when you save changes in the Control Panel.
- **Unified Webhook:** A single unified webhook URL (`http://YOUR_VPS_IP:5000/api/payment/webhook`) verifies incoming payments using the active webhook secret from MySQL and automatically activates user subscriptions in both MySQL and Firebase Cloud Firestore!

### 2. 🏷️ Dynamic Subscription Plans & Real-Time Price Editor
- Edit prices (e.g. Daily ₹15, Weekly ₹79, Monthly ₹249, Lifetime ₹499) directly from the Web Control Panel.
- Mobile app queries `GET /api/payment/plans` at runtime to fetch the latest active prices and active `razorpay_key_id`.
- Drivers immediately see the updated prices and payments are routed to the new Razorpay account without touching any mobile app code.

### 3. 👥 Telemetry, Crashlytics, Fleet Management & Tutorials
- Live ride click analytics across Porter, Rapido, Ola, and Uber.
- Remote App Crashlytics with full stack traces.
- Remote YouTube tutorial manager.
- Remote APK version control and killswitch.

---

## 🚀 Quick Deployment to VPS

### Option A: 1-Click Automated Script from Local Machine
```bash
cd autoride_vps_enterprise
node deploy/deploy_vps_auto.cjs
```

### Option B: Deploy Directly on VPS (SSH)
```bash
# 1. Copy folder to VPS
scp -r autoride_vps_enterprise root@65.20.77.112:/opt/autoride-enterprise

# 2. SSH into VPS
ssh root@65.20.77.112

# 3. Run deploy script
cd /opt/autoride-enterprise
chmod +x deploy/deploy.sh
./deploy/deploy.sh
```

---

## 🌐 API Reference

### 📱 Mobile App Endpoints (`/api`)
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/payment/plans` | Returns active plans and active `razorpay_key_id` to app |
| `POST` | `/api/payment/create-order` | Creates official Razorpay order with active credentials |
| `POST` | `/api/payment/verify` | Verifies payment signature and activates subscription |
| `POST` | `/api/payment/webhook` | Unified Razorpay Webhook endpoint |
| `GET` | `/api/config` | Remote app configuration & free ride limits |
| `GET` | `/api/tutorials` | Active video tutorials for driver app |
| `POST` | `/api/rides/event` | Log incoming / accepted ride click |
| `POST` | `/api/crashes/report` | Report exception stack trace |

### 🛠️ Admin Control Panel Endpoints (`/api/admin`)
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/admin/login` | Admin authentication (returns JWT token) |
| `GET` | `/api/admin/payment/config` | Retrieve active Razorpay credentials & mode |
| `POST` | `/api/admin/payment/config` | **Save & activate new Razorpay account in MySQL** |
| `POST` | `/api/admin/payment/test-credentials` | Test Razorpay credentials against Razorpay servers |
| `GET` | `/api/admin/payment/plans` | Retrieve all subscription plans |
| `PUT` | `/api/admin/payment/plans/:id` | **Update plan price, validity, features live** |
| `POST` | `/api/admin/payment/plans` | Create a new custom plan tier |
| `GET` | `/api/admin/payment/transactions` | Real-time payment orders & sales ledger |

---

## 🔐 Razorpay Webhook Setup Guide
1. Open your Razorpay Dashboard (`https://dashboard.razorpay.com`).
2. Go to **Settings ➔ Webhooks ➔ Add New Webhook**.
3. **Webhook URL:** `http://65.20.77.112:5000/api/payment/webhook` (or your domain with HTTPS).
4. **Secret:** The unified webhook secret set in your Web Control Panel.
5. **Active Events:**
   - `payment.captured`
   - `order.paid`
6. Click **Save Webhook**.
