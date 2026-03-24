#!/bin/bash
# OpenWrt UI Package Integration - Automated Deployment Script
# Usage: ./deploy-to-router.sh [target_router_ip] [username]

set -e  # Exit on any error

# Configuration
TARGET_ROUTER="${1:-192.168.1.100}"
TARGET_USER="${2:-root}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE} OpenWrt UI Package Integration Deploy${NC}"
echo -e "${BLUE}==========================================${NC}"
echo -e "Target Router: ${GREEN}$TARGET_ROUTER${NC}"
echo -e "Target User:   ${GREEN}$TARGET_USER${NC}"
echo ""

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check connectivity
check_connectivity() {
    log_info "Checking target router connectivity..."
    if ! ping -c 1 -W 3 "$TARGET_ROUTER" > /dev/null 2>&1; then
        log_error "Cannot reach target router $TARGET_ROUTER"
    fi
    log_success "Target router is reachable"
}

# Prepare deployment environment
prepare_deployment() {
    log_info "Preparing deployment environment..."

    # Create local deployment directory with relative path
    DEPLOY_DIR="./deploy-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$DEPLOY_DIR"
    cd "$DEPLOY_DIR"

    log_success "Deployment directory created: $DEPLOY_DIR"
}

# Prepare local files for deployment
prepare_local_files() {
    log_info "Preparing local files for deployment..."

    # Get script directory (relative to where script is run)
    SCRIPT_DIR="$(dirname "$0")"

    # Core application utility script
    if [ -f "${SCRIPT_DIR}/app_util_production.lua" ]; then
        cp "${SCRIPT_DIR}/app_util_production.lua" ./app_util.lua
        log_success "Copied app_util_production.lua"
    else
        log_error "app_util_production.lua not found in script directory"
    fi

    # Copy local packages and test files
    if [ -f "${SCRIPT_DIR}/packages/luci-app-mvptest.ipk" ]; then
        cp "${SCRIPT_DIR}/packages/luci-app-mvptest.ipk" ./luci-app-mvptest.ipk
        log_success "Copied local test package"
    else
        log_warning "Local test package not found in packages/ directory"
    fi

    if [ -f "${SCRIPT_DIR}/test-files/demo.html" ]; then
        cp "${SCRIPT_DIR}/test-files/demo.html" ./demo.html
        log_success "Copied local demo.html"
    else
        log_warning "Local demo.html not found in test-files/ directory"
    fi

    if [ -f "${SCRIPT_DIR}/test-files/mvptest.html" ]; then
        cp "${SCRIPT_DIR}/test-files/mvptest.html" ./mvptest.html
        log_success "Copied local mvptest.html"
    else
        log_warning "Local mvptest.html not found in test-files/ directory"
    fi

    log_success "Local files prepared successfully"
    echo "Files in deployment directory:"
    ls -la
}

# Deploy to target router
deploy_to_target() {
    log_info "Deploying to target router..."

    # 1. Create directory structure
    log_info "Creating directory structure..."
    ssh "$TARGET_USER@$TARGET_ROUTER" "mkdir -p /www/assets/config /usr_www /www/usp-test /etc/lighttpd/conf.d" || \
        log_error "Failed to create directories"

    # 2. Deploy core files
    log_info "Deploying core files..."
    scp app_util.lua "$TARGET_USER@$TARGET_ROUTER:/usr/bin/" || \
        log_error "Failed to deploy app_util.lua"

    # 3. Set file permissions
    log_info "Setting file permissions..."
    ssh "$TARGET_USER@$TARGET_ROUTER" "chmod 755 /usr/bin/app_util.lua" || \
        log_error "Failed to set file permissions"

    # 4. Deploy optional files
    if [ -f "demo.html" ]; then
        log_info "Deploying demo page..."
        scp demo.html "$TARGET_USER@$TARGET_ROUTER:/www/usp-test/"
    fi

    if [ -f "mvptest.html" ]; then
        log_info "Deploying MVP test page..."
        scp mvptest.html "$TARGET_USER@$TARGET_ROUTER:/www/usp-test/"
    fi

    if [ -f "luci-app-mvptest.ipk" ]; then
        log_info "Deploying test package..."
        scp luci-app-mvptest.ipk "$TARGET_USER@$TARGET_ROUTER:/tmp/"
        log_success "Test package deployed to /tmp/luci-app-mvptest.ipk"
    fi

    log_success "File deployment completed"
}

# System check
system_check() {
    log_info "Checking target system..."

    ssh "$TARGET_USER@$TARGET_ROUTER" "
        echo '=== System Component Check ==='
        which lua || echo '⚠️  Missing lua'
        which lighttpd || echo '⚠️  Missing lighttpd'
        which opkg || echo '⚠️  Missing opkg'
        ls /etc/lighttpd/conf.d/ > /dev/null 2>&1 || echo '⚠️  lighttpd conf.d not found'

        echo '=== Checking optional components ==='
        which mosquitto_pub > /dev/null 2>&1 && echo '✅ MQTT client available' || echo '⚠️  MQTT client not available'
        which jq > /dev/null 2>&1 && echo '✅ jq available' || echo '⚠️  jq not available (will use fallback)'
        echo '=== Check completed ==='
    "
}

# Verify deployment functionality
verify_deployment() {
    log_info "Verifying deployment functionality..."

    # Test basic functionality
    log_info "Testing app_util.lua basic functionality..."
    ssh "$TARGET_USER@$TARGET_ROUTER" "/usr/bin/app_util.lua list" || \
        log_error "app_util.lua execution failed"

    # Test app management
    log_info "Testing app management functionality..."
    ssh "$TARGET_USER@$TARGET_ROUTER" "/usr/bin/app_util.lua new '{\"name\":\"Deploy Test\",\"description\":\"Deployment verification test\",\"urlPath\":\"deploytest\"}'" || \
        log_error "Failed to add test application"

    # Check configuration update
    ssh "$TARGET_USER@$TARGET_ROUTER" "cat /www/assets/config/linksys_apps.json | grep 'Deploy Test'" || \
        log_error "Configuration not updated correctly"

    # Check SSE event file
    ssh "$TARGET_USER@$TARGET_ROUTER" "cat /tmp/linksys_app_update 2>/dev/null" || \
        log_warning "SSE event file not generated"

    # Test package installation if available
    if [ -f "luci-app-mvptest.ipk" ]; then
        log_info "Testing opkg package installation..."
        ssh "$TARGET_USER@$TARGET_ROUTER" "
            echo '=== Testing opkg package ==='
            opkg install /tmp/luci-app-mvptest.ipk 2>/dev/null || echo 'Package installation failed'
            /usr/bin/app_util.lua list | grep -i mvp || echo 'MVP app not found in list'
            echo '=== Cleaning up test package ==='
            opkg remove luci-app-mvptest 2>/dev/null || echo 'Package removal failed'
        "
    fi

    # Clean up test application
    log_info "Cleaning up test data..."
    ssh "$TARGET_USER@$TARGET_ROUTER" "/usr/bin/app_util.lua delete 'Deploy Test'" 2>/dev/null || true

    log_success "Functionality verification completed!"
}

# Show completion information
show_completion() {
    echo ""
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN}         Deployment Completed!          ${NC}"
    echo -e "${GREEN}==========================================${NC}"
    echo ""
    echo -e "${YELLOW}Target router now has the following capabilities:${NC}"
    echo -e "✅ ${GREEN}opkg install${NC} → Auto-register apps → Trigger SSE events"
    echo -e "✅ ${GREEN}opkg remove${NC} → Auto-remove apps → Trigger SSE events"
    echo -e "✅ ${GREEN}Dynamic configuration${NC} → JSON updates + auto backup"
    echo -e "✅ ${GREEN}Web routing automation${NC} → lighttpd alias generation"
    echo ""
    echo -e "${YELLOW}Testing commands:${NC}"
    echo -e "ssh $TARGET_USER@$TARGET_ROUTER"
    echo -e "/usr/bin/app_util.lua list"
    echo -e "/usr/bin/app_util.lua new '{\"name\":\"My App\",\"urlPath\":\"myapp\"}'"
    echo ""

    if [ -f "luci-app-mvptest.ipk" ]; then
        echo -e "${YELLOW}Test package installation:${NC}"
        echo -e "ssh $TARGET_USER@$TARGET_ROUTER"
        echo -e "opkg install /tmp/luci-app-mvptest.ipk"
        echo -e "opkg remove luci-app-mvptest"
        echo ""
    fi

    echo -e "${BLUE}Deployment directory: $(pwd)${NC}"
    echo -e "${BLUE}Ready to develop custom application packages! 🚀${NC}"
}

# Main execution flow
main() {
    check_connectivity
    prepare_deployment
    prepare_local_files
    deploy_to_target
    system_check
    verify_deployment
    show_completion
}

# Error handling and cleanup
cleanup() {
    if [ -n "$DEPLOY_DIR" ] && [ -d "$DEPLOY_DIR" ]; then
        cd ..
        log_info "Cleaning up temporary files..."
        rm -rf "$DEPLOY_DIR"
    fi
}

trap cleanup EXIT

# Execute main program
main "$@"