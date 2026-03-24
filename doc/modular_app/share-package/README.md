# OpenWrt UI Package Integration - Deployment Package

## 🎯 **What This Does**

This package enables **any OpenWrt router** to support dynamic application installation through the UI:

- `opkg install my-app` → **Automatic UI registration** (<3 seconds)
- `opkg remove my-app` → **Automatic UI cleanup**
- **Real-time configuration updates** via file-based events
- **Dynamic web routing** for installed applications
- **RESTful API endpoints** for frontend integration

## 📦 **Package Contents**

```
share-package/
├── app_util_production.lua      # Core integration script with API support (15.6KB)
├── quick-deploy.sh              # 🚀 Quick deployment (recommended)
├── deploy-to-router.sh          # Complete deployment with verification
├── simple-opkg-test.sh          # Basic integration testing
├── test-deployment.sh           # Comprehensive verification
├── test-opkg-package.sh         # Package lifecycle testing
├── test-api-endpoints.sh        # API endpoints verification
├── packages/
│   └── luci-app-mvptest.ipk     # Test package (2.7KB)
├── test-files/
│   ├── demo.html                # Demo web page
│   └── mvptest.html             # MVP test page
└── README.md                    # This file
```

## ⚡ **Quick Start (Recommended)**

### **Method 1: One-Command Deployment**

```bash
# Deploy to target router (replace with your router IP)
./quick-deploy.sh 192.168.1.100

# Test integration
./simple-opkg-test.sh 192.168.1.100
```

**That's it!** Your router now supports dynamic application installation.

---

## 🛠️ **Detailed Setup**

### **Prerequisites**

**Target Router Requirements:**
- ✅ OpenWrt system with SSH access
- ✅ lighttpd web server running
- ✅ opkg package manager
- ✅ lua runtime environment

**Host System Requirements:**
- bash shell with SSH client
- sshpass (for password authentication)

### **Deployment Options**

#### **Option A: Quick Deployment** ⚡ (Recommended)
```bash
# Fast deployment for testing and development
./quick-deploy.sh [target_router_ip]

# Example
./quick-deploy.sh 192.168.1.100
```

#### **Option B: Complete Deployment** 🏭 (Production)
```bash
# Full deployment with comprehensive verification
./deploy-to-router.sh [target_router_ip] [username]

# Example
./deploy-to-router.sh 192.168.1.100 root
```

---

## 🧪 **Testing & Verification**

### **Basic Testing**
```bash
# Quick integration test
./simple-opkg-test.sh [target_router_ip]
```

**Expected Output:**
```
📋 Current apps: Router Admin, File Server
📦 Installing test package... ✅
📋 Apps after installation: + MVP Test App
⚡ Event File: {"event":"installed",...} ✅
🔌 API Endpoints: /api/apps.json, /api/app-events.json ✅
🌐 lighttpd config: /mvptest/ => /usr_www/mvptest/ ✅
🗑️ Removing package... ✅
📋 Apps after removal: MVP Test App removed ✅
```

### **Comprehensive Testing**
```bash
# Full system verification
./test-deployment.sh [target_router_ip]

# Detailed package testing
./test-opkg-package.sh [target_router_ip]

# API endpoints verification
./test-api-endpoints.sh [target_router_ip]
```

---

## ✅ **Success Verification**

### **1. Basic Functionality**
```bash
ssh root@[target_router_ip]
/usr/bin/app_util.lua list
```

### **2. Package Integration Test**
```bash
ssh root@[target_router_ip]
opkg install /tmp/luci-app-mvptest.ipk
/usr/bin/app_util.lua list | grep -i mvp
opkg remove luci-app-mvptest
```

### **3. API Endpoints Verification**
```bash
# Test complete app list API
curl -k https://[target_router_ip]/api/apps.json | head -5

# Test latest event API
curl -k https://[target_router_ip]/api/app-events.json

# Trigger an event and verify API update
ssh root@[target_router_ip]
/usr/bin/app_util.lua new '{"name":"API Test","urlPath":"apitest"}'
curl -k https://[target_router_ip]/api/app-events.json
```

### **4. Files Deployed Successfully**
- ✅ `/usr/bin/app_util.lua` - Core utility script with API support
- ✅ `/www/assets/config/linksys_apps.json` - UI configuration
- ✅ `/www/api/apps.json` - Complete app list API
- ✅ `/www/api/app-events.json` - Latest event API
- ✅ `/tmp/luci-app-mvptest.ipk` - Test package
- ✅ `/www/usp-test/demo.html` - Demo page (optional)

---

## 🔧 **Manual Deployment (Alternative)**

If automated scripts don't work, you can deploy manually:

```bash
# 1. Set target router IP
TARGET_ROUTER="192.168.1.100"

# 2. Create directories
ssh root@$TARGET_ROUTER "mkdir -p /www/assets/config /usr_www /www/usp-test"

# 3. Deploy core script
scp app_util_production.lua root@$TARGET_ROUTER:/usr/bin/app_util.lua

# 4. Deploy test files
scp packages/luci-app-mvptest.ipk root@$TARGET_ROUTER:/tmp/
scp test-files/*.html root@$TARGET_ROUTER:/www/usp-test/

# 5. Set permissions
ssh root@$TARGET_ROUTER "chmod 755 /usr/bin/app_util.lua"

# 6. Test
ssh root@$TARGET_ROUTER "/usr/bin/app_util.lua list"
```

---

## 📊 **System Architecture**

### **Integration Flow**
```
opkg install → postinst script → app_util.lua → JSON config update →
Event files creation → Web API endpoints → Frontend polling → UI update
```

### **Key Files**
- **`app_util.lua`** - Bridge between opkg and UI
- **`linksys_apps.json`** - Application configuration
- **`/tmp/linksys_app_update`** - Internal event trigger
- **`/www/api/app-events.json`** - Web API for latest events
- **`/www/api/apps.json`** - Web API for complete app list
- **`/etc/lighttpd/conf.d/99-apps.conf`** - Dynamic routing

---

## 🔌 **API Endpoints**

The system provides RESTful API endpoints for frontend integration:

### **Available APIs**

| Endpoint | Purpose | Content | Update Frequency |
|----------|---------|---------|------------------|
| `/api/apps.json` | Complete application list | Full router configuration with all apps | On every app change |
| `/api/app-events.json` | Latest event notification | Single event (install/remove/update) | Real-time |

### **API Usage Examples**

#### **1. Get Complete Application List**
```bash
curl -k https://192.168.1.1/api/apps.json
```

**Response Format:**
```json
{
  "apps": [
    {
      "name": "Router Admin",
      "description": "Router Administration Panel",
      "link": "http://192.168.1.1/admin",
      "color": "blueAccent",
      "icon": "settings",
      "version": "1.0.0"
    }
  ],
  "userApps": [
    {
      "name": "Demo App",
      "description": "Demo application for MVP testing",
      "urlPath": "demo",
      "link": "192.168.1.1/demo/",
      "color": "cyanAccent",
      "icon": "app-registration",
      "version": "1.0.0",
      "subDir": "demo",
      "configNum": -1
    }
  ],
  "api": {
    "creator": "Linksys",
    "version": "0.0.1"
  }
}
```

#### **2. Get Latest Event**
```bash
curl -k https://192.168.1.1/api/app-events.json
```

**Response Format:**
```json
{
  "event": "installed",
  "app": {
    "name": "Demo App",
    "description": "Demo application for MVP testing",
    "urlPath": "demo",
    "link": "192.168.1.1/demo/",
    "color": "cyanAccent",
    "icon": "app-registration",
    "version": "1.0.0",
    "subDir": "demo",
    "configNum": -1
  },
  "timestamp": 1774315693
}
```

### **Event Types**

| Event Type | Description | Triggered By |
|------------|-------------|--------------|
| `installed` | New application installed | `opkg install` or `app_util.lua new` |
| `removed` | Application uninstalled | `opkg remove` or `app_util.lua delete` |
| `updated` | Application updated | `app_util.lua update` |

---

## 📋 **JSON Format Reference**

### **Complete Apps List (`/api/apps.json`)**

```json
{
  "apps": [
    {
      "name": "string",           // Required. Display name
      "description": "string",    // Required. App description
      "link": "string",          // Required. Full URL to app
      "color": "string",         // Required. UI color theme
      "icon": "string",          // Required. Icon name/identifier
      "version": "string"        // Required. App version
    }
  ],
  "userApps": [
    {
      "name": "string",           // Required. Display name
      "description": "string",    // Required. App description
      "urlPath": "string",        // Required. URL path segment
      "link": "string",          // Required. Full URL to app
      "color": "string",         // Required. UI color theme
      "icon": "string",          // Required. Icon name/identifier
      "version": "string",       // Required. App version
      "subDir": "string",        // Required. Subdirectory name
      "configNum": number        // Required. Configuration number (-1 for dynamic)
    }
  ],
  "api": {
    "creator": "string",         // API creator identifier
    "version": "string"          // API version
  }
}
```

### **Latest Event (`/api/app-events.json`)**

```json
{
  "event": "string",             // Required. Event type: "installed"|"removed"|"updated"
  "app": {
    "name": "string",           // Required. App display name
    "description": "string",    // Required. App description
    "urlPath": "string",        // Optional. URL path (user apps only)
    "link": "string",          // Required. Full URL to app
    "color": "string",         // Required. UI color theme
    "icon": "string",          // Required. Icon identifier
    "version": "string",       // Required. App version
    "subDir": "string",        // Optional. Subdirectory name
    "configNum": number        // Required. Configuration number
  },
  "timestamp": number            // Required. Unix timestamp (seconds)
}
```

### **Field Descriptions**

#### **App Object Fields**

| Field | Type | Required | Description | Example Values |
|-------|------|----------|-------------|----------------|
| `name` | string | ✅ | Human-readable application name | `"Demo App"`, `"File Server"` |
| `description` | string | ✅ | Brief description of the application | `"Demo application for testing"` |
| `urlPath` | string | ⚠️ | URL path segment (user apps only) | `"demo"`, `"fileserver"` |
| `link` | string | ✅ | Complete URL to access the app | `"http://192.168.1.1/demo/"` |
| `color` | string | ✅ | UI theme color identifier | `"blueAccent"`, `"cyanAccent"`, `"redAccent"` |
| `icon` | string | ✅ | Icon identifier for UI display | `"app-registration"`, `"settings"`, `"psychology"` |
| `version` | string | ✅ | Application version string | `"1.0.0"`, `"2.3.1"` |
| `subDir` | string | ⚠️ | Physical subdirectory name | `"demo"`, `"--"` (none) |
| `configNum` | number | ✅ | Internal configuration number | `90000` (system), `-1` (dynamic) |

#### **Event Object Fields**

| Field | Type | Required | Description | Example Values |
|-------|------|----------|-------------|----------------|
| `event` | string | ✅ | Type of event that occurred | `"installed"`, `"removed"`, `"updated"` |
| `app` | object | ✅ | Application object (see above) | Complete app information |
| `timestamp` | number | ✅ | Unix timestamp in seconds | `1774315693` |

### **Color Theme Values**

| Color ID | Visual Color | Usage |
|----------|--------------|--------|
| `"blueAccent"` | 🔵 Blue | System applications, default |
| `"cyanAccent"` | 🔷 Cyan | User applications, utilities |
| `"redAccent"` | 🔴 Red | Critical applications, admin tools |
| `"greenAccent"` | 🟢 Green | Network applications |
| `"orangeAccent"` | 🟠 Orange | Media applications |
| `"purpleAccent"` | 🟣 Purple | Development tools |

### **Icon Identifier Values**

| Icon ID | Description | Usage |
|---------|-------------|--------|
| `"app-registration"` | Generic app icon | Default for user apps |
| `"settings"` | Settings/gear icon | Admin, configuration |
| `"psychology"` | Brain/AI icon | Smart features, analytics |
| `"folder"` | Folder icon | File management |
| `"wifi"` | WiFi icon | Network applications |
| `"security"` | Shield icon | Security applications |
| `"dashboard"` | Dashboard icon | Monitoring tools |

### **Data Validation Rules**

1. **Required Fields**: All fields marked as ✅ Required must be present
2. **String Lengths**:
   - `name`: 1-50 characters
   - `description`: 1-200 characters
   - `urlPath`: 1-20 characters, alphanumeric + hyphens only
   - `version`: 1-10 characters
3. **URL Format**: `link` must be a valid HTTP/HTTPS URL
4. **Timestamp**: Must be a positive Unix timestamp (seconds since epoch)
5. **ConfigNum**: -1 for dynamic apps, positive integers for system apps

### **Error Handling**

#### **Common HTTP Status Codes**

| Status | Description | Possible Causes |
|--------|-------------|-----------------|
| `200` | OK | Request successful |
| `404` | Not Found | API endpoint doesn't exist, or no events yet |
| `500` | Internal Server Error | File system error, JSON parsing error |
| `503` | Service Unavailable | app_util.lua not deployed |

#### **Invalid JSON Response**

If the API returns invalid JSON, the file may be corrupted or being written. Retry after 1-2 seconds.

#### **Empty Event File**

If `/api/app-events.json` returns empty content or `{}`, no events have been triggered yet.

### **Frontend Integration**

#### **Recommended Polling Strategy**
```javascript
// 1. Initial load: Get complete app list
const appsResponse = await fetch('/api/apps.json');
const appsConfig = await appsResponse.json();

// 2. Poll for events every 2 seconds
setInterval(async () => {
  const eventResponse = await fetch('/api/app-events.json');
  const event = await eventResponse.json();

  if (event.timestamp > lastProcessedTimestamp) {
    handleAppEvent(event);  // Update UI based on event
    lastProcessedTimestamp = event.timestamp;
  }
}, 2000);
```

#### **Event Handling Logic**
```javascript
function handleAppEvent(event) {
  switch (event.event) {
    case 'installed':
      addAppToUI(event.app);
      showNotification(`✅ ${event.app.name} installed`);
      break;
    case 'removed':
      removeAppFromUI(event.app);
      showNotification(`🗑️ ${event.app.name} removed`);
      break;
    case 'updated':
      updateAppInUI(event.app);
      showNotification(`🔄 ${event.app.name} updated`);
      break;
  }
}
```

### **CORS and Security**

- **HTTPS Required**: All APIs are served over HTTPS
- **CORS Headers**: APIs include appropriate CORS headers for web applications
- **No Authentication**: APIs are publicly accessible (same network only)
- **Read-Only**: APIs provide read-only access to application data

---

## 🚨 **Troubleshooting**

### **Common Issues**

#### **1. SSH Connection Failed**
```bash
# Check connectivity
ping [target_router_ip]
telnet [target_router_ip] 22

# Solution: Verify network and SSH service
```

#### **2. Permission Denied**
```bash
# Use sshpass for password authentication
sshpass -p admin ./quick-deploy.sh [router_ip]

# Or set up SSH keys
ssh-copy-id root@[router_ip]
```

#### **3. Script Execution Failed**
```bash
# Check dependencies on target router
ssh root@[router_ip] "which lua opkg lighttpd"

# Install missing packages
ssh root@[router_ip] "opkg update && opkg install lua"
```

#### **4. Package Installation Failed**
```bash
# Check package format and permissions
ssh root@[router_ip] "ls -la /tmp/luci-app-mvptest.ipk"
ssh root@[router_ip] "opkg info /tmp/luci-app-mvptest.ipk"
```

---

## 🎯 **Expected Results**

After successful deployment, your router will have:

✅ **Dynamic Application Management**
- Install packages with UI auto-update
- Remove packages with UI auto-cleanup

✅ **Real-time Configuration**
- JSON configuration automatically updated
- Configuration backup system enabled

✅ **Web Service Integration**
- lighttpd routes auto-generated
- Application web content properly served

✅ **Event System**
- File-based events triggered on app install/remove
- Event format compatible with LinksysNow UI

✅ **RESTful API Integration**
- `/api/apps.json` - Complete application list
- `/api/app-events.json` - Real-time event notifications
- HTTPS endpoints for frontend polling

---

## 📞 **Support**

### **Verification Commands**
```bash
# Check system status
./test-deployment.sh [router_ip]

# Check specific functionality
ssh root@[router_ip] "/usr/bin/app_util.lua list"
ssh root@[router_ip] "cat /www/assets/config/linksys_apps.json"
ssh root@[router_ip] "cat /tmp/linksys_app_update"

# Check API endpoints
curl -k https://[router_ip]/api/apps.json
curl -k https://[router_ip]/api/app-events.json
ssh root@[router_ip] "ls -la /www/api/"
```

### **Log Files**
- **lighttpd**: `/var/log/lighttpd/error.log`
- **opkg**: Command output during install/remove
- **app_util**: Direct command line output

---

## 🚀 **Ready to Go!**

Your partner can now:
1. **Deploy** with a single command
2. **Test** complete integration
3. **Develop** custom application packages
4. **Scale** to multiple routers

**The router will be ready for full OpenWrt UI Package Integration!** 🎉

---

*Package created: 2025-03-24*
*Last updated: 2026-03-24 (Added Web API support)*
*Status: Production Ready with RESTful API*