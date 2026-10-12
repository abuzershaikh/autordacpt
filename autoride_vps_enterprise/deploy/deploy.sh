#!/bin/bash
# ========================================================
# AutoRide Acceptor - Enterprise VPS Deployment Script
# ========================================================

set -e

echo "🚀 Starting Enterprise Deployment on VPS..."

APP_DIR="/opt/autoride-enterprise"

# 1. Ensure Directory
mkdir -p "$APP_DIR"
cd "$APP_DIR"

# 2. Install Node Dependencies
echo "📦 Installing production dependencies..."
npm install --production

# 3. Run Database Migrations
echo "🗄️ Running MySQL migrations..."
npm run migrate

# 4. Ensure Port 5000 is open in firewall
if command -v firewall-cmd >/dev/null 2>&1; then
    echo "🛡️ Configuring firewalld for port 5000..."
    firewall-cmd --add-port=5000/tcp --permanent || true
    firewall-cmd --reload || true
elif command -v ufw >/dev/null 2>&1; then
    echo "🛡️ Configuring ufw for port 5000..."
    ufw allow 5000/tcp || true
fi

# 5. Restart with PM2
echo "🔄 Reloading application via PM2..."
if pm2 list | grep -q "autoride-vps-engine"; then
    pm2 reload deploy/ecosystem.config.cjs --update-env
else
    pm2 start deploy/ecosystem.config.cjs
fi

pm2 save

echo "===================================================="
echo "✅ Deployment Successful!"
echo "🌐 Control Panel: http://$(curl -s ifconfig.me):5000"
echo "📡 Webhook URL:   http://$(curl -s ifconfig.me):5000/api/payment/webhook"
echo "===================================================="
