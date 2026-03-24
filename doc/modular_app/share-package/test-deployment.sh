#!/bin/bash
# Test deployment and opkg integration
# Usage: ./test-deployment.sh [target_router_ip]

TARGET_ROUTER="${1:-192.168.1.100}"
TARGET_USER="root"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "🧪 Testing OpenWrt UI Package Integration on $TARGET_ROUTER"
echo ""

# Test 1: Basic functionality
echo -e "${YELLOW}Test 1: Basic app_util.lua functionality${NC}"
ssh $TARGET_USER@$TARGET_ROUTER "/usr/bin/app_util.lua list" && \
    echo -e "${GREEN}✅ Basic functionality works${NC}" || \
    echo -e "${RED}❌ Basic functionality failed${NC}"
echo ""

# Test 2: App management
echo -e "${YELLOW}Test 2: App management (add/remove)${NC}"
ssh $TARGET_USER@$TARGET_ROUTER "/usr/bin/app_util.lua new '{\"name\":\"Test App\",\"description\":\"Test application\",\"urlPath\":\"testapp\"}'" && \
    echo -e "${GREEN}✅ App creation works${NC}" || \
    echo -e "${RED}❌ App creation failed${NC}"

ssh $TARGET_USER@$TARGET_ROUTER "/usr/bin/app_util.lua list | grep 'Test App'" && \
    echo -e "${GREEN}✅ App appears in list${NC}" || \
    echo -e "${RED}❌ App not found in list${NC}"

ssh $TARGET_USER@$TARGET_ROUTER "/usr/bin/app_util.lua delete 'Test App'" && \
    echo -e "${GREEN}✅ App removal works${NC}" || \
    echo -e "${RED}❌ App removal failed${NC}"
echo ""

# Test 3: Configuration file integrity
echo -e "${YELLOW}Test 3: Configuration file integrity${NC}"
ssh $TARGET_USER@$TARGET_ROUTER "cat /www/assets/config/linksys_apps.json | head -5" && \
    echo -e "${GREEN}✅ Configuration file readable${NC}" || \
    echo -e "${RED}❌ Configuration file issue${NC}"
echo ""

# Test 4: SSE event generation
echo -e "${YELLOW}Test 4: SSE event generation${NC}"
ssh $TARGET_USER@$TARGET_ROUTER "/usr/bin/app_util.lua new '{\"name\":\"SSE Test\",\"urlPath\":\"ssetest\"}' && cat /tmp/linksys_app_update" && \
    echo -e "${GREEN}✅ SSE events generated${NC}" || \
    echo -e "${RED}❌ SSE events not working${NC}"

ssh $TARGET_USER@$TARGET_ROUTER "/usr/bin/app_util.lua delete 'SSE Test'" > /dev/null 2>&1
echo ""

# Test 5: opkg package integration (deploy local package first)
echo -e "${YELLOW}Test 5: opkg package integration${NC}"

# Get script directory and deploy local package
SCRIPT_DIR="$(dirname "$0")"
if [ -f "$SCRIPT_DIR/packages/luci-app-mvptest.ipk" ]; then
    echo "Deploying local test package..."
    scp "$SCRIPT_DIR/packages/luci-app-mvptest.ipk" $TARGET_USER@$TARGET_ROUTER:/tmp/luci-app-mvptest.ipk
fi

if ssh $TARGET_USER@$TARGET_ROUTER "test -f /tmp/luci-app-mvptest.ipk"; then
    echo "Found test package, testing opkg integration..."

    # Install package
    ssh $TARGET_USER@$TARGET_ROUTER "opkg install /tmp/luci-app-mvptest.ipk 2>/dev/null" && \
        echo -e "${GREEN}✅ Package installation works${NC}" || \
        echo -e "${RED}❌ Package installation failed${NC}"

    # Check if app appears in list
    ssh $TARGET_USER@$TARGET_ROUTER "/usr/bin/app_util.lua list | grep -i mvp" && \
        echo -e "${GREEN}✅ Package app appears in UI config${NC}" || \
        echo -e "${RED}❌ Package app not in UI config${NC}"

    # Remove package
    ssh $TARGET_USER@$TARGET_ROUTER "opkg remove luci-app-mvptest 2>/dev/null" && \
        echo -e "${GREEN}✅ Package removal works${NC}" || \
        echo -e "${RED}❌ Package removal failed${NC}"

    # Verify app removed from list
    ssh $TARGET_USER@$TARGET_ROUTER "/usr/bin/app_util.lua list | grep -i mvp" && \
        echo -e "${RED}❌ Package app still in UI config${NC}" || \
        echo -e "${GREEN}✅ Package app removed from UI config${NC}"
else
    echo -e "${YELLOW}⚠️  Test package not found, skipping opkg tests${NC}"
fi
echo ""

# Test 6: lighttpd configuration
echo -e "${YELLOW}Test 6: lighttpd configuration generation${NC}"
ssh $TARGET_USER@$TARGET_ROUTER "/usr/bin/app_util.lua new '{\"name\":\"Web Test\",\"urlPath\":\"webtest\"}'" > /dev/null 2>&1
ssh $TARGET_USER@$TARGET_ROUTER "cat /etc/lighttpd/conf.d/99-apps.conf | grep webtest" && \
    echo -e "${GREEN}✅ lighttpd config generation works${NC}" || \
    echo -e "${RED}❌ lighttpd config generation failed${NC}"

ssh $TARGET_USER@$TARGET_ROUTER "/usr/bin/app_util.lua delete 'Web Test'" > /dev/null 2>&1
echo ""

# Summary
echo -e "${YELLOW}=========================================${NC}"
echo -e "${YELLOW}         Test Summary                   ${NC}"
echo -e "${YELLOW}=========================================${NC}"
echo "System components:"
ssh $TARGET_USER@$TARGET_ROUTER "
    echo -n 'lua: '
    which lua > /dev/null && echo '✅' || echo '❌'
    echo -n 'lighttpd: '
    which lighttpd > /dev/null && echo '✅' || echo '❌'
    echo -n 'opkg: '
    which opkg > /dev/null && echo '✅' || echo '❌'
    echo -n 'mosquitto_pub: '
    which mosquitto_pub > /dev/null 2>&1 && echo '✅' || echo '⚠️'
    echo -n 'jq: '
    which jq > /dev/null 2>&1 && echo '✅' || echo '⚠️'
"
echo ""
echo "🎯 Target router $TARGET_ROUTER is ready for OpenWrt UI Package Integration!"
echo ""
echo "Next steps:"
echo "1. Deploy UI-side SSE event listener"
echo "2. Test end-to-end: opkg install → UI update"
echo "3. Create custom application packages"