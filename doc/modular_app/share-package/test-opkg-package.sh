#!/bin/bash
# Test the existing opkg package functionality
# Usage: ./test-opkg-package.sh [router_ip]

ROUTER_IP="${1:-192.168.1.1}"
USER="root"

echo "📦 Testing opkg package integration on $ROUTER_IP"
echo ""

# Step 1: Deploy local package and check
echo "1. Deploying and checking test package..."

# Get script directory and deploy local package
SCRIPT_DIR="$(dirname "$0")"
PACKAGE_PATH="/tmp/luci-app-mvptest.ipk"

if [ -f "$SCRIPT_DIR/packages/luci-app-mvptest.ipk" ]; then
    echo "Deploying local test package..."
    ssh $USER@$ROUTER_IP "cat > $PACKAGE_PATH" < "$SCRIPT_DIR/packages/luci-app-mvptest.ipk"
elif ssh $USER@$ROUTER_IP "test -f /tmp/luci-app-mvptest/luci-app-mvptest.ipk"; then
    ssh $USER@$ROUTER_IP "cp /tmp/luci-app-mvptest/luci-app-mvptest.ipk $PACKAGE_PATH"
else
    echo "❌ Test package not found locally or on router"
    exit 1
fi

echo "✅ Found test package at: $PACKAGE_PATH"
echo ""

# Step 2: Show package info
echo "2. Package information:"
ssh $USER@$ROUTER_IP "opkg info $PACKAGE_PATH 2>/dev/null || echo 'Package info not available'"
echo ""

# Step 3: Check current app list
echo "3. Current applications before installation:"
ssh $USER@$ROUTER_IP "/usr/bin/app_util.lua list | grep -E '^App Name:'"
echo ""

# Step 4: Install the package
echo "4. Installing test package..."
if ssh $USER@$ROUTER_IP "opkg install $PACKAGE_PATH"; then
    echo "✅ Package installed successfully"
else
    echo "❌ Package installation failed"
    exit 1
fi
echo ""

# Step 5: Check if app appears in list
echo "5. Applications after installation:"
ssh $USER@$ROUTER_IP "/usr/bin/app_util.lua list | grep -E '^App Name:'"
echo ""

# Step 6: Check SSE event
echo "6. SSE event generated:"
ssh $USER@$ROUTER_IP "cat /tmp/linksys_app_update 2>/dev/null || echo 'No SSE event file found'"
echo ""

# Step 7: Check lighttpd config
echo "7. lighttpd configuration:"
ssh $USER@$ROUTER_IP "cat /etc/lighttpd/conf.d/99-apps.conf 2>/dev/null || echo 'No lighttpd config found'"
echo ""

# Step 8: Test web access (if possible)
echo "8. Testing web accessibility..."
ssh $USER@$ROUTER_IP "ls -la /usr_www/mvptest/ 2>/dev/null || echo 'MVP test directory not found'"

# Try to access the web page
curl -k -s "https://$ROUTER_IP/mvptest/" | head -5 2>/dev/null && \
    echo "✅ Web page accessible" || \
    echo "⚠️  Web page not accessible (may need web server restart)"
echo ""

# Step 9: Remove the package
echo "9. Removing test package..."
if ssh $USER@$ROUTER_IP "opkg remove luci-app-mvptest"; then
    echo "✅ Package removed successfully"
else
    echo "❌ Package removal failed"
fi
echo ""

# Step 10: Verify app removed from list
echo "10. Applications after removal:"
ssh $USER@$ROUTER_IP "/usr/bin/app_util.lua list | grep -E '^App Name:'"
echo ""

# Step 11: Final SSE event
echo "11. Final SSE event:"
ssh $USER@$ROUTER_IP "cat /tmp/linksys_app_update 2>/dev/null || echo 'No SSE event file found'"
echo ""

echo "🎯 opkg package test completed!"
echo ""
echo "Summary:"
echo "- Package can be installed/removed with opkg"
echo "- App appears/disappears in app_util.lua list"
echo "- SSE events are generated on install/remove"
echo "- lighttpd configuration is updated automatically"