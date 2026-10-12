#!/usr/bin/env bash
set -e

# ==============================================================================
# AutoRide VPS Control Engine - Enterprise Auto-Deployment Script
# Target OS: Ubuntu 20.04 / 22.04 / 24.04 LTS or Debian 11 / 12
# ==============================================================================

echo "=========================================================="
echo "🚀 AutoRide VPS Control Engine - Initializing Deployment"
echo "=========================================================="

# Check root / sudo
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run this script with sudo or as root: sudo bash deploy.sh"
  exit 1
fi

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$APP_DIR"

echo "📂 Application Directory: $APP_DIR"

# 1. Update OS packages
echo "📦 Updating system packages..."
apt-get update -y && apt-get upgrade -y
apt-get install -y curl wget git build-essential ufw nginx

# 2. Install Node.js 20 LTS (if not installed)
if ! command -v node >/dev/null 2>&1 || [[ $(node -v | cut -d'.' -f1 | tr -d 'v') -lt 18 ]]; then
  echo "📦 Installing Node.js 20 LTS..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y nodejs
fi
echo "✅ Node.js version: $(node -v)"
echo "✅ NPM version: $(npm -v)"

# 3. Install PM2 globally
if ! command -v pm2 >/dev/null 2>&1; then
  echo "📦 Installing PM2 process manager globally..."
  npm install -g pm2
fi

# 4. Install & Configure MySQL 8 (if not installed)
if ! command -v mysql >/dev/null 2>&1; then
  echo "📦 Installing MySQL Server 8..."
  apt-get install -y mysql-server
  systemctl enable mysql
  systemctl start mysql
fi

echo "✅ MySQL Service is running."

# 5. Check .env configuration
if [ ! -f "$APP_DIR/.env" ]; then
  echo "⚠️ .env file not found. Creating from .env.example..."
  cp "$APP_DIR/.env.example" "$APP_DIR/.env"
  echo "⚠️ Please review $APP_DIR/.env and set your database passwords & JWT secret!"
fi

# 6. Install Node.js Application Dependencies
echo "📦 Installing Node.js application dependencies..."
npm install --omit=dev

# 7. Run Database Schema Migrations
echo "🗄️ Running MySQL Database Migrations..."
npm run db:migrate

# 8. Start / Reload with PM2
echo "⚡ Starting AutoRide VPS Control Engine with PM2..."
pm2 start deploy/ecosystem.config.cjs || pm2 reload deploy/ecosystem.config.cjs
pm2 save
pm2 startup systemd -u $(whoami) --hp $HOME || true

# 9. Firewall rules
echo "🛡️ Configuring UFW Firewall..."
ufw allow 22/tcp || true
ufw allow 80/tcp || true
ufw allow 443/tcp || true
ufw allow 5000/tcp || true

echo "=========================================================="
echo "🎉 DEPLOYMENT COMPLETE!"
echo "🌐 API Server & Admin Dashboard: http://YOUR_VPS_IP:5000"
echo "📊 PM2 Status: pm2 status"
echo "📜 Live Logs:  pm2 logs autoride-vps-engine"
echo "=========================================================="
