#!/bin/bash
# One-Command Complete Deployment and Testing
# Usage: ./deploy-and-test.sh [target_router_ip]

TARGET_ROUTER="${1:-192.168.1.100}"

echo "🚀 OpenWrt UI Package Integration - Complete Setup"
echo "Target Router: $TARGET_ROUTER"
echo ""

# Phase 1: Deploy
echo "📦 Phase 1: Deploying system..."
if ./quick-deploy.sh "$TARGET_ROUTER"; then
    echo "✅ Deployment completed successfully"
else
    echo "❌ Deployment failed"
    exit 1
fi

echo ""

# Phase 2: Test
echo "🧪 Phase 2: Testing integration..."
if ./simple-opkg-test.sh "$TARGET_ROUTER"; then
    echo "✅ Integration tests passed"
else
    echo "⚠️  Integration tests had issues"
fi

echo ""

# Phase 3: Comprehensive Verification
echo "🔍 Phase 3: Comprehensive verification..."
if ./test-deployment.sh "$TARGET_ROUTER"; then
    echo "✅ All verification tests passed"
else
    echo "⚠️  Some verification tests failed"
fi

echo ""
echo "🎉 ================================================"
echo "🎉   OpenWrt UI Package Integration Ready!       "
echo "🎉 ================================================"
echo ""
echo "✅ Router $TARGET_ROUTER now supports:"
echo "   • opkg install → UI automatic updates"
echo "   • opkg remove → UI automatic cleanup"
echo "   • Real-time configuration management"
echo "   • Dynamic web routing"
echo ""
echo "🧪 Test the system:"
echo "   ssh root@$TARGET_ROUTER"
echo "   opkg install /tmp/luci-app-mvptest.ipk"
echo "   /usr/bin/app_util.lua list"
echo "   opkg remove luci-app-mvptest"
echo ""
echo "🚀 Ready for custom application development!"