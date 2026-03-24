# OpenWrt UI Package Integration - JSON API Reference

## 🔌 **API Endpoints Overview**

| Endpoint | Purpose | Update Frequency | HTTP Method |
|----------|---------|------------------|-------------|
| `/api/apps.json` | Complete application list | On every app change | GET |
| `/api/app-events.json` | Latest event notification | Real-time | GET |

---

## 📋 **Complete JSON Schemas**

### **1. Complete Apps List (`/api/apps.json`)**

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

### **2. Latest Event (`/api/app-events.json`)**

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

---

## 🏗️ **Field Definitions**

### **App Object (System Apps)**

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `name` | `string` | ✅ | Display name | `"Router Admin"` |
| `description` | `string` | ✅ | Brief description | `"Router Administration Panel"` |
| `link` | `string` | ✅ | Complete URL | `"http://192.168.1.1/admin"` |
| `color` | `string` | ✅ | UI theme color | `"blueAccent"` |
| `icon` | `string` | ✅ | Icon identifier | `"settings"` |
| `version` | `string` | ✅ | Version string | `"1.0.0"` |

### **App Object (User Apps)**

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `name` | `string` | ✅ | Display name | `"Demo App"` |
| `description` | `string` | ✅ | Brief description | `"Demo application"` |
| `urlPath` | `string` | ✅ | URL path segment | `"demo"` |
| `link` | `string` | ✅ | Complete URL | `"192.168.1.1/demo/"` |
| `color` | `string` | ✅ | UI theme color | `"cyanAccent"` |
| `icon` | `string` | ✅ | Icon identifier | `"app-registration"` |
| `version` | `string` | ✅ | Version string | `"1.0.0"` |
| `subDir` | `string` | ✅ | Physical directory | `"demo"` or `"--"` |
| `configNum` | `number` | ✅ | Configuration ID | `-1` (dynamic), `90000` (system) |

### **Event Object**

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `event` | `string` | ✅ | Event type | `"installed"` |
| `app` | `object` | ✅ | App information | Complete app object |
| `timestamp` | `number` | ✅ | Unix timestamp (seconds) | `1774315693` |

---

## 🎨 **Predefined Values**

### **Color Themes**

| Value | Visual | Typical Usage |
|-------|--------|---------------|
| `"blueAccent"` | 🔵 | System apps, default |
| `"cyanAccent"` | 🔷 | User apps, utilities |
| `"redAccent"` | 🔴 | Critical, admin tools |
| `"greenAccent"` | 🟢 | Network apps |
| `"orangeAccent"` | 🟠 | Media apps |
| `"purpleAccent"` | 🟣 | Development tools |

### **Icon Identifiers**

| Value | Description | Typical Usage |
|-------|-------------|---------------|
| `"app-registration"` | Generic app | Default user apps |
| `"settings"` | Gear/settings | Admin, configuration |
| `"psychology"` | Brain/AI | Smart features |
| `"folder"` | Folder | File management |
| `"wifi"` | WiFi signal | Network tools |
| `"security"` | Shield | Security apps |
| `"dashboard"` | Dashboard | Monitoring |

### **Event Types**

| Value | Description | Triggered By |
|-------|-------------|--------------|
| `"installed"` | App installed | `opkg install`, `app_util.lua new` |
| `"removed"` | App removed | `opkg remove`, `app_util.lua delete` |
| `"updated"` | App updated | `app_util.lua update` |

---

## ✅ **Validation Rules**

### **String Constraints**

| Field | Min Length | Max Length | Pattern |
|-------|-----------|------------|---------|
| `name` | 1 | 50 | Any UTF-8 |
| `description` | 1 | 200 | Any UTF-8 |
| `urlPath` | 1 | 20 | `[a-zA-Z0-9-]+` |
| `version` | 1 | 10 | Semantic version preferred |

### **URL Validation**

- `link` must be a valid HTTP/HTTPS URL
- Should be accessible from the same network
- Protocol (`http://` or `https://`) required

### **Timestamp Format**

- Unix timestamp in **seconds** (not milliseconds)
- Must be positive integer
- Represents UTC time

### **Configuration Numbers**

- `-1`: Dynamic user applications
- `> 0`: System applications (usually 90000+)
- Must be integer

---

## 🔍 **Usage Examples**

### **Frontend Integration (JavaScript)**

```javascript
// 1. Load complete app list
async function loadApps() {
  const response = await fetch('/api/apps.json');
  const config = await response.json();

  // System apps
  config.apps.forEach(app => {
    console.log(`System: ${app.name} - ${app.link}`);
  });

  // User apps
  config.userApps.forEach(app => {
    console.log(`User: ${app.name} - /${app.urlPath}/`);
  });
}

// 2. Poll for events
let lastTimestamp = 0;

async function checkEvents() {
  const response = await fetch('/api/app-events.json');
  const event = await response.json();

  if (event.timestamp > lastTimestamp) {
    handleEvent(event);
    lastTimestamp = event.timestamp;
  }
}

function handleEvent(event) {
  switch (event.event) {
    case 'installed':
      console.log(`✅ ${event.app.name} installed`);
      addAppToUI(event.app);
      break;
    case 'removed':
      console.log(`🗑️ ${event.app.name} removed`);
      removeAppFromUI(event.app.name);
      break;
    case 'updated':
      console.log(`🔄 ${event.app.name} updated`);
      updateAppInUI(event.app);
      break;
  }
}

// Start polling
setInterval(checkEvents, 2000);
```

### **Frontend Integration (TypeScript)**

```typescript
interface SystemApp {
  name: string;
  description: string;
  link: string;
  color: string;
  icon: string;
  version: string;
}

interface UserApp extends SystemApp {
  urlPath: string;
  subDir: string;
  configNum: number;
}

interface AppsConfig {
  apps: SystemApp[];
  userApps: UserApp[];
  api: {
    creator: string;
    version: string;
  };
}

interface AppEvent {
  event: 'installed' | 'removed' | 'updated';
  app: UserApp;
  timestamp: number;
}

// Type-safe API calls
async function getAppsConfig(): Promise<AppsConfig> {
  const response = await fetch('/api/apps.json');
  return response.json();
}

async function getLatestEvent(): Promise<AppEvent> {
  const response = await fetch('/api/app-events.json');
  return response.json();
}
```

---

## 🚨 **Error Handling**

### **HTTP Status Codes**

| Status | Meaning | Action |
|--------|---------|--------|
| `200` | Success | Process response |
| `404` | Not Found | API not deployed, or no events yet |
| `500` | Server Error | File system error, retry later |
| `503` | Unavailable | app_util.lua not deployed |

### **Invalid JSON**

```javascript
async function safeApiCall(url) {
  try {
    const response = await fetch(url);

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const data = await response.json();
    return data;
  } catch (error) {
    console.error(`API call failed: ${error.message}`);
    return null;
  }
}
```

### **Missing Fields**

Always validate required fields exist before using:

```javascript
function validateUserApp(app) {
  const required = ['name', 'description', 'urlPath', 'link', 'color', 'icon', 'version', 'subDir', 'configNum'];

  for (const field of required) {
    if (!(field in app)) {
      console.error(`Missing required field: ${field}`);
      return false;
    }
  }
  return true;
}
```

---

## 📊 **Real-World Examples**

### **Sample `/api/apps.json` Response**

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
      "name": "File Server",
      "description": "Enhanced File Server",
      "urlPath": "files",
      "link": "192.168.1.1/files/",
      "color": "cyanAccent",
      "icon": "folder",
      "version": "2.1.0",
      "subDir": "fileserver",
      "configNum": 90000
    },
    {
      "name": "Network Monitor",
      "description": "Real-time network monitoring",
      "urlPath": "netmon",
      "link": "192.168.1.1/netmon/",
      "color": "greenAccent",
      "icon": "wifi",
      "version": "1.3.2",
      "subDir": "netmon",
      "configNum": -1
    }
  ],
  "api": {
    "creator": "Linksys",
    "version": "0.0.1"
  }
}
```

### **Sample `/api/app-events.json` Response**

```json
{
  "event": "installed",
  "app": {
    "name": "Security Scanner",
    "description": "Network security scanning tool",
    "urlPath": "security",
    "link": "192.168.1.1/security/",
    "color": "redAccent",
    "icon": "security",
    "version": "1.0.0",
    "subDir": "security",
    "configNum": -1
  },
  "timestamp": 1774315693
}
```

---

*Reference Document Version: 1.0*
*Compatible with: OpenWrt UI Package Integration v0.0.1*
*Last Updated: 2026-03-24*