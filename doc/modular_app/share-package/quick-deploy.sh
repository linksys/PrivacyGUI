#!/bin/bash
# Quick deployment script - core functionality only
# Usage: ./quick-deploy.sh [target_router_ip]

TARGET_ROUTER="${1:-192.168.1.100}"

echo "🚀 Quick deployment to $TARGET_ROUTER"

# Get script directory
SCRIPT_DIR="$(dirname "$0")"

# Check required files
if [ ! -f "$SCRIPT_DIR/app_util_production.lua" ]; then
    echo "❌ Error: app_util_production.lua not found in script directory"
    exit 1
fi

# Deploy to target router
echo "🔧 Deploying to target router..."
ssh root@$TARGET_ROUTER "mkdir -p /www/assets/config /usr_www /www/usp-test"

# Deploy core script
echo "📦 Deploying core script..."
scp "$SCRIPT_DIR/app_util_production.lua" root@$TARGET_ROUTER:/usr/bin/app_util.lua

# Deploy test package if available
if [ -f "$SCRIPT_DIR/packages/luci-app-mvptest.ipk" ]; then
    echo "📦 Deploying test package..."
    scp "$SCRIPT_DIR/packages/luci-app-mvptest.ipk" root@$TARGET_ROUTER:/tmp/
    echo "✅ Test package available at /tmp/luci-app-mvptest.ipk"
fi

# Deploy test files if available
if [ -d "$SCRIPT_DIR/test-files" ]; then
    echo "📄 Deploying test files..."
    scp "$SCRIPT_DIR/test-files/"*.html root@$TARGET_ROUTER:/www/usp-test/
fi

# Set permissions
ssh root@$TARGET_ROUTER "chmod 755 /usr/bin/app_util.lua"

# Test functionality
echo "✅ Testing functionality..."
ssh root@$TARGET_ROUTER "/usr/bin/app_util.lua list"

# Show opkg test instructions
if [ -f "$SCRIPT_DIR/packages/luci-app-mvptest.ipk" ]; then
    echo ""
    echo "🧪 Test opkg integration:"
    echo "ssh root@$TARGET_ROUTER"
    echo "opkg install /tmp/luci-app-mvptest.ipk"
    echo "/usr/bin/app_util.lua list | grep -i mvp"
    echo "opkg remove luci-app-mvptest"
fi

echo "🎉 Deployment completed!"
echo "Target router is ready for OpenWrt UI Package Integration"