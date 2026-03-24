#!/bin/bash
# Simple opkg test with sshpass authentication
ROUTER="${1:-192.168.1.1}"
PASS="admin"
PKG_PATH="/tmp/luci-app-mvptest.ipk"

# Get script directory and deploy local package
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/packages/luci-app-mvptest.ipk" ]; then
    echo "📦 Deploying local test package to $ROUTER..."
    sshpass -p "$PASS" ssh root@$ROUTER "cat > $PKG_PATH" < "$SCRIPT_DIR/packages/luci-app-mvptest.ipk"
    echo "✅ Test package deployed to router"
fi

echo "🧪 Simple opkg integration test on $ROUTER"

# Current apps
echo "📋 Current apps:"
sshpass -p "$PASS" ssh root@$ROUTER "/usr/bin/app_util.lua list | grep '^App Name:'"

echo ""
echo "📦 Installing test package..."
sshpass -p "$PASS" ssh root@$ROUTER "opkg install $PKG_PATH"

echo ""
echo "📋 Apps after installation:"
sshpass -p "$PASS" ssh root@$ROUTER "/usr/bin/app_util.lua list | grep '^App Name:'"

echo ""
echo "⚡ SSE Event:"
sshpass -p "$PASS" ssh root@$ROUTER "cat /tmp/linksys_app_update 2>/dev/null || echo 'No event file'"

echo ""
echo "🌐 lighttpd config:"
sshpass -p "$PASS" ssh root@$ROUTER "cat /etc/lighttpd/conf.d/99-apps.conf 2>/dev/null || echo 'No config file'"

echo ""
echo "🗑️ Removing package..."
sshpass -p "$PASS" ssh root@$ROUTER "opkg remove luci-app-mvptest"

echo ""
echo "📋 Apps after removal:"
sshpass -p "$PASS" ssh root@$ROUTER "/usr/bin/app_util.lua list | grep '^App Name:'"

echo ""
echo "⚡ Final SSE Event:"
sshpass -p "$PASS" ssh root@$ROUTER "cat /tmp/linksys_app_update 2>/dev/null || echo 'No event file'"

echo ""
echo "✅ Test completed!"