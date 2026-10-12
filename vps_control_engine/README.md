# 🚗 AutoRide Enterprise VPS Control Engine

Enterprise-grade Node.js + Express + MySQL control engine & live admin dashboard for **AutoRide Acceptor** (Porter, Rapido, Ola, Uber).

---

## 🌟 Key Features

1. **Live Admin Dashboard UI**:
   - Built with dark glassmorphic UI, real-time KPI cards, and responsive charts.
   - **Rider Directory & Dossier Modal**: View rider phone number, email, join date, device brand/model, OS version, active plan status, and live accessibility service state (🟢 Active / 🔴 Inactive).
   - **Ride Intelligence Stream**: Track accepted vs. rejected/missed rides across **Rapido, Porter, Ola, and Uber** with fare, distance, and acceptance latency metrics.
   - **Crashlytics Center**: Full stack traces, error causes, device info, and one-click "Mark Resolved".
   - **Tutorial Studio**: Add, edit, reorder, and remove YouTube tutorials dynamically displayed in the rider mobile app.
   - **Remote Settings**: Adjust default free rides quota, minimum accepted fare, and emergency broadcast banners.

2. **Strict Hybrid Partitioning Architecture**:
   - **Firebase Cloud Firestore**: Strictly reserved for core user profiles (`users/{uid}`) and subscription payment transactions.
   - **VPS MySQL Database**: High-frequency operational data: telemetry heartbeats, ride acceptance logs, crash dumps, and tutorials.

3. **Firebase Admin SDK Auto-Sync**:
   - Integrated with service account key (`autoride-accept`).
   - Syncs user profiles and Razorpay payment history from Firestore into MySQL.

4. **Production Ready**:
   - MySQL 8.0 connection pool with index-optimized pagination (`LIMIT` / `OFFSET`).
   - PM2 cluster mode config (`deploy/ecosystem.config.cjs`).
   - Docker & Docker Compose setup (`docker-compose.yml`).
   - Automated Linux deployment script (`deploy/deploy.sh`).

---

## 🚀 Quick Deployment Guide on VPS

### Option 1: Automated Script (Ubuntu / Debian)
```bash
# 1. Copy the vps_control_engine folder to your VPS
scp -r vps_control_engine root@YOUR_VPS_IP:/var/www/autoride-engine

# 2. SSH into your VPS
ssh root@YOUR_VPS_IP

# 3. Enter directory and run automated deploy script
cd /var/www/autoride-engine
chmod +x deploy/deploy.sh
sudo bash deploy/deploy.sh
```

### Option 2: Docker Compose (Any OS)
```bash
cd vps_control_engine
docker compose up -d --build
```

### Option 3: Manual Node.js + MySQL Setup
```bash
cd vps_control_engine
npm install
npm run db:migrate
npm start
```

---

## 🌐 Endpoints Reference

### 📱 Mobile App APIs (`/api`)
- `POST /api/telemetry/heartbeat` - Send 60s rider heartbeat with battery, network & accessibility status.
- `POST /api/rides/event` - Record ride incoming, accepted, or missed event for Porter, Rapido, Ola, or Uber.
- `POST /api/crashes/report` - Log app unhandled exception / crash trace.
- `GET  /api/tutorials?category=all` - Retrieve active YouTube video tutorials for mobile app.
- `GET  /api/config` - Retrieve remote app config (free ride allowance, banners).

### 🛠️ Admin Management APIs (`/admin/api`)
- `GET  /admin/api/dashboard/overview` - Aggregated KPIs and platform breakdowns.
- `GET  /admin/api/users?page=1&limit=20` - Paginated riders directory.
- `GET  /admin/api/users/:uid` - Full rider dossier with ride stats and crash history.
- `POST /admin/api/users/sync-firebase` - Trigger manual Firestore user profile sync.
- `GET  /admin/api/rides?platform=rapido&status=accepted&page=1` - Paginated ride stream.
- `GET  /admin/api/crashes?status=unresolved&page=1` - Paginated crash reports.
- `POST /admin/api/tutorials` - Create new YouTube tutorial.
- `PUT  /admin/api/tutorials/:id` - Update tutorial.
- `DELETE /admin/api/tutorials/:id` - Delete tutorial.
- `GET  /admin/api/config` - Get remote settings.
- `POST /admin/api/config` - Update remote settings (e.g. default free rides).

---

## 🔐 Credentials & Security
- Place your `serviceAccountKey.json` inside `config/serviceAccountKey.json`.
- Configure `ADMIN_API_KEY` in `.env` to protect administrative REST endpoints.
