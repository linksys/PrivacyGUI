#!/bin/bash
# Test API Endpoints
# Usage: ./test-api-endpoints.sh [target_router_ip]

ROUTER_IP="${1:-192.168.1.1}"

echo "🔌 Testing OpenWrt UI Package Integration API Endpoints"
echo "Target Router: $ROUTER_IP"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

test_endpoint() {
    local endpoint="$1"
    local description="$2"
    local url="https://$ROUTER_IP$endpoint"

    echo -e "${YELLOW}Testing $description${NC}"
    echo "GET $url"

    response=$(curl -k -s -w "HTTPSTATUS:%{http_code}" "$url" 2>/dev/null)
    http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    body=$(echo $response | sed -e 's/HTTPSTATUS:.*//')

    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✅ HTTP $http_code - OK${NC}"

        # Try to parse JSON and show summary
        if command -v jq >/dev/null 2>&1; then
            if [[ "$endpoint" == "/api/apps.json" ]]; then
                apps_count=$(echo "$body" | jq '.userApps | length' 2>/dev/null)
                system_apps_count=$(echo "$body" | jq '.apps | length' 2>/dev/null)
                api_version=$(echo "$body" | jq -r '.api.version' 2>/dev/null)
                echo "   📱 System Apps: $system_apps_count, User Apps: $apps_count"
                echo "   📊 API Version: $api_version"

                # Show sample user app details
                if [ "$apps_count" -gt 0 ]; then
                    sample_app_name=$(echo "$body" | jq -r '.userApps[0].name' 2>/dev/null)
                    sample_app_path=$(echo "$body" | jq -r '.userApps[0].urlPath' 2>/dev/null)
                    sample_app_color=$(echo "$body" | jq -r '.userApps[0].color' 2>/dev/null)
                    echo "   🎯 Sample App: $sample_app_name ($sample_app_path) [$sample_app_color]"
                fi

            elif [[ "$endpoint" == "/api/app-events.json" ]]; then
                event_type=$(echo "$body" | jq -r '.event' 2>/dev/null)
                app_name=$(echo "$body" | jq -r '.app.name' 2>/dev/null)
                app_url_path=$(echo "$body" | jq -r '.app.urlPath' 2>/dev/null)
                app_color=$(echo "$body" | jq -r '.app.color' 2>/dev/null)
                app_icon=$(echo "$body" | jq -r '.app.icon' 2>/dev/null)
                timestamp=$(echo "$body" | jq '.timestamp' 2>/dev/null)
                human_time=$(date -r "$timestamp" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "N/A")
                echo "   📦 Event Type: $event_type"
                echo "   🎯 App Name: $app_name"
                echo "   🔗 URL Path: $app_url_path"
                echo "   🎨 Color/Icon: $app_color / $app_icon"
                echo "   ⏰ Timestamp: $timestamp ($human_time)"
            fi
        else
            # Show first few characters if jq not available
            echo "   📄 Response preview: $(echo "$body" | head -c 100)..."
        fi
    else
        echo -e "${RED}❌ HTTP $http_code - Failed${NC}"
        if [ -n "$body" ]; then
            echo "   Error: $body"
        fi
    fi
    echo ""
}

echo "=== API Endpoints Test ==="

# Test complete app list
test_endpoint "/api/apps.json" "Complete Application List API"

# Test latest event
test_endpoint "/api/app-events.json" "Latest Event API"

# Test a trigger and verify event update
echo -e "${YELLOW}Testing Event Trigger${NC}"
echo "Triggering a test event..."

ssh_result=$(sshpass -p admin ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$ROUTER_IP \
    '/usr/bin/app_util.lua new "{\"name\":\"API Test $(date +%H%M%S)\",\"description\":\"Testing API endpoints\",\"urlPath\":\"apitest$(date +%H%M%S)\"}"' 2>/dev/null)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Test event triggered successfully${NC}"
    echo ""

    # Wait a moment and test the event API again
    sleep 2
    echo "Checking updated event API..."
    test_endpoint "/api/app-events.json" "Updated Event API"
else
    echo -e "${RED}❌ Failed to trigger test event (SSH access required)${NC}"
    echo ""
fi

echo "=== JSON Format Validation ==="

if command -v jq >/dev/null 2>&1; then
    echo "📋 Validating JSON format compliance..."

    # Test apps.json format
    apps_response=$(curl -k -s "https://$ROUTER_IP/api/apps.json" 2>/dev/null)
    if echo "$apps_response" | jq -e '.apps and .userApps and .api' >/dev/null 2>&1; then
        echo -e "${GREEN}✅ /api/apps.json format valid${NC}"
        required_app_fields="name,description,link,color,icon,version"
        required_userapp_fields="name,description,urlPath,link,color,icon,version,subDir,configNum"

        # Check if required fields exist in apps
        apps_valid=$(echo "$apps_response" | jq --arg fields "$required_app_fields" '
            .apps[0] as $app |
            ($fields | split(",")) as $required |
            $required | map(. as $field | $app | has($field)) | all
        ' 2>/dev/null)

        if [ "$apps_valid" = "true" ]; then
            echo "   📱 System apps schema: Valid"
        else
            echo "   ⚠️  System apps schema: Missing required fields"
        fi

        # Check if required fields exist in userApps
        if echo "$apps_response" | jq '.userApps | length' | grep -q '^[1-9]'; then
            userapp_valid=$(echo "$apps_response" | jq --arg fields "$required_userapp_fields" '
                .userApps[0] as $app |
                ($fields | split(",")) as $required |
                $required | map(. as $field | $app | has($field)) | all
            ' 2>/dev/null)

            if [ "$userapp_valid" = "true" ]; then
                echo "   🎯 User apps schema: Valid"
            else
                echo "   ⚠️  User apps schema: Missing required fields"
            fi
        else
            echo "   📭 No user apps to validate"
        fi
    else
        echo -e "${RED}❌ /api/apps.json format invalid${NC}"
    fi

    # Test app-events.json format
    events_response=$(curl -k -s "https://$ROUTER_IP/api/app-events.json" 2>/dev/null)
    if echo "$events_response" | jq -e '.event and .app and .timestamp' >/dev/null 2>&1; then
        echo -e "${GREEN}✅ /api/app-events.json format valid${NC}"

        # Check event type
        event_type=$(echo "$events_response" | jq -r '.event' 2>/dev/null)
        if [[ "$event_type" =~ ^(installed|removed|updated)$ ]]; then
            echo "   📦 Event type: Valid ($event_type)"
        else
            echo "   ⚠️  Event type: Invalid ($event_type)"
        fi

        # Check timestamp
        timestamp=$(echo "$events_response" | jq '.timestamp' 2>/dev/null)
        if [ "$timestamp" -gt 1000000000 ] 2>/dev/null; then
            echo "   ⏰ Timestamp: Valid ($(date -r "$timestamp" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'N/A'))"
        else
            echo "   ⚠️  Timestamp: Invalid ($timestamp)"
        fi
    else
        echo -e "${RED}❌ /api/app-events.json format invalid${NC}"
    fi
else
    echo "⚠️  jq not available - skipping JSON format validation"
fi

echo ""
echo "=== Test Summary ==="
echo "🔌 API Endpoints tested:"
echo "   • https://$ROUTER_IP/api/apps.json - Complete application list"
echo "   • https://$ROUTER_IP/api/app-events.json - Latest event notification"
echo ""
echo "📋 JSON Format Specification:"
echo "   • apps.json: {apps: [...], userApps: [...], api: {...}}"
echo "   • app-events.json: {event: string, app: {...}, timestamp: number}"
echo ""
echo "💡 Usage in your frontend:"
echo "   const apps = await fetch('https://$ROUTER_IP/api/apps.json').then(r => r.json());"
echo "   const event = await fetch('https://$ROUTER_IP/api/app-events.json').then(r => r.json());"
echo ""
echo "🎯 OpenWrt UI Package Integration API testing complete!"