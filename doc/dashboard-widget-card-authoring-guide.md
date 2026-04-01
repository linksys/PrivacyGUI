# Dashboard Widget Card Authoring Guide

## 📋 Table of Contents

1. [Overview](#overview)
2. [JSON Structure Basics](#json-structure-basics)
3. [Required Field Specifications](#required-field-specifications)
4. [Layout Constraint System](#layout-constraint-system)
5. [Template Engine](#template-engine)
6. [Action System](#action-system)
7. [Supported UI Components](#supported-ui-components)
8. [Chart Integration](#chart-integration)
9. [Data Binding](#data-binding)
10. [Best Practices](#best-practices)
11. [Common Examples](#common-examples)
12. [Troubleshooting](#troubleshooting)

---

## Overview

Dashboard Widget Card is a JSON-configured dynamic UI component system that integrates the latest **UI Kit v2.16.1** features, supporting:

- 🎯 **Action System**: Complete user interaction handling
- 📊 **Chart Support**: 5 chart types (Line, Bar, Pie, Radar, Heatmap)
- 🎨 **Theme Consistency**: Automatic app theme adaptation
- 📱 **Responsive Layout**: Flexible grid constraint system
- 🔗 **Data Binding**: USP and HTTP data source support

---

## JSON Structure Basics

### Top-Level Structure

```json
{
  "widgetId": "string",          // Required: Unique identifier
  "displayName": "string",       // Required: Display name
  "description": "string",       // Optional: Description
  "constraints": {               // Required: Layout constraints
    "minColumns": 2,
    "maxColumns": 8,
    "preferredColumns": 4,
    "minRows": 2,
    "maxRows": 6,
    "preferredRows": 3
  },
  "template": {                  // Required: UI template
    "type": "ComponentType",
    "props": { ... }
  },
  "subscription": {              // Optional: USP data source
    "paths": ["Device.WiFi.SSID.*.SSID"],
    "interval": 5000
  },
  "dataSource": {                // Optional: HTTP data source
    "url": "/api/network/status",
    "method": "GET",
    "refreshInterval": 10
  }
}
```

### Field Validation Rules

| Field | Type | Required | Validation Rules |
|-------|------|----------|------------------|
| `widgetId` | String | ✅ | Unique, 3-50 characters, alphanumeric with underscores |
| `displayName` | String | ✅ | 1-100 characters |
| `description` | String | ❌ | Maximum 500 characters |
| `constraints` | Object | ✅ | Valid layout constraints |
| `template` | Object | ✅ | Valid UI Kit component tree |

---

## Required Field Specifications

### 1. Widget ID

```json
{
  "widgetId": "network_status_card"
}
```

**Requirements:**
- Unique within the application
- 3-50 characters in length
- Contains only letters, numbers, underscores
- Recommended `snake_case` format

### 2. Display Name

```json
{
  "displayName": "Network Status"
}
```

**Requirements:**
- Friendly name for UI display
- 1-100 characters
- Multi-language support (future version)

### 3. Template

```json
{
  "template": {
    "type": "Column",
    "props": {
      "children": [
        {
          "type": "AppText",
          "props": {
            "text": "Hello World",
            "variant": "titleMedium"
          }
        }
      ]
    }
  }
}
```

**Requirements:**
- Must be a valid UI Kit component
- Supports nested component structures
- Follows UI Kit component API

---

## Layout Constraint System

### Basic Constraints

```json
{
  "constraints": {
    "minColumns": 2,      // Minimum width (grid units)
    "maxColumns": 8,      // Maximum width
    "preferredColumns": 4, // Recommended width
    "minRows": 2,         // Minimum height
    "maxRows": 6,         // Maximum height  
    "preferredRows": 3    // Recommended height
  }
}
```

### Responsive Design Guidelines

| Component Type | Recommended Constraints | Actual Usage | Description |
|----------------|------------------------|--------------|-------------|
| **Text Cards** | 2-4 columns, 2-3 rows | 2-4 columns, 2-3 rows | Simple information display |
| **Chart Components** | 4-8 columns, 4-6 rows | ⚠️ 3-6 columns, 1-4 rows | Speed tests, analytics |
| **Form Components** | 3-6 columns, 3-5 rows | 3-6 columns, 3-5 rows | Interactive elements |
| **Status Gauges** | 2-3 columns, 2-3 rows | 3-4 columns, 2-3 rows | AdGuard, system monitors |
| **QR Code Widgets** | 2-4 columns, 3-4 rows | 3-4 columns, 3-4 rows | WiFi credential sharing |

### Real-World Constraint Patterns

Based on actual implementations, these patterns are commonly used:

```json
// Speed Test Widget (Compact Chart)
{
  "constraints": {
    "minColumns": 3,
    "maxColumns": 6, 
    "preferredColumns": 4,
    "minRows": 1,
    "maxRows": 4,
    "preferredRows": 2
  }
}

// AdGuard Status Widget (Status Display)
{
  "constraints": {
    "minColumns": 3,
    "maxColumns": 4,
    "preferredColumns": 3,
    "minRows": 2,
    "maxRows": 3,
    "preferredRows": 2
  }
}

// WiFi QR Generator (QR Code Display)
{
  "constraints": {
    "minColumns": 3,
    "maxColumns": 4,
    "preferredColumns": 3,
    "minRows": 3,
    "maxRows": 4,
    "preferredRows": 3
  }
}
```

### Constraint Validation

```json
// ❌ Error: minColumns > maxColumns
{
  "constraints": {
    "minColumns": 6,
    "maxColumns": 4  // Invalid
  }
}

// ✅ Correct
{
  "constraints": {
    "minColumns": 2,
    "maxColumns": 6,
    "preferredColumns": 4  // minColumns ≤ preferred ≤ maxColumns
  }
}
```

---

## Template Engine

### Component Hierarchy

```json
{
  "template": {
    "type": "Column",                    // Root component
    "props": {
      "mainAxisAlignment": "start",
      "crossAxisAlignment": "stretch",
      "children": [                      // Child component array
        {
          "type": "AppText",
          "props": {
            "text": "Title",
            "variant": "titleLarge"
          }
        },
        {
          "type": "AppGap",
          "props": {
            "size": "md"
          }
        }
      ]
    }
  }
}
```

### Layout Components

#### Column (Vertical Layout)

```json
{
  "type": "Column",
  "props": {
    "mainAxisAlignment": "start|end|center|spaceBetween|spaceAround|spaceEvenly",
    "crossAxisAlignment": "start|end|center|stretch",
    "children": [...]
  }
}
```

#### Row (Horizontal Layout)

```json
{
  "type": "Row", 
  "props": {
    "mainAxisAlignment": "start|end|center|spaceBetween|spaceAround|spaceEvenly",
    "crossAxisAlignment": "start|end|center|stretch",
    "expandChildren": false,  // true: children auto-expand
    "children": [...]
  }
}
```

#### Stack (Overlay Layout)

```json
{
  "type": "Stack",
  "props": {
    "children": [
      {
        "type": "AppText",
        "props": { "text": "Background" }
      },
      {
        "type": "AppText", 
        "props": { "text": "Foreground" }
      }
    ]
  }
}
```

### Scroll Container

```json
{
  "type": "SingleChildScrollView",
  "props": {
    "physics": "ClampingScrollPhysics",
    "child": {
      "type": "Column",
      "props": {
        "children": [...]
      }
    }
  }
}
```

---

## Action System

### Basic Action Structure

All actions use the `$action` keyword:

```json
{
  "type": "AppButton",
  "props": {
    "label": "Execute Action",
    "onTap": {
      "$action": "action_type",
      "param1": "value1",
      "param2": "value2"
    }
  }
}
```

### Supported Action Types

#### 1. Data Refresh

```json
{
  "$action": "refresh_data"
}
```

#### 2. Settings Save

```json
{
  "$action": "save_settings",
  "section": "network",      // Settings section
  "validate": true,          // Whether to validate
  "showConfirm": true       // Whether to show confirmation
}
```

#### 3. Navigation Action

```json
{
  "$action": "navigate",
  "destination": "advanced_settings",
  "params": {
    "section": "wifi",
    "tab": "security"
  }
}
```

#### 4. Form Change

```json
{
  "$action": "field_changed",
  "field": "deviceName",
  "validation": "required"
}
```

#### 5. Settings Toggle

```json
{
  "$action": "setting_toggled", 
  "setting": "autoConnect",
  "requiresReboot": false
}
```

#### 6. Custom Action

```json
{
  "$action": "custom_action",
  "handler": "networkDiagnostic",
  "timeout": 30000,
  "data": {
    "testType": "connectivity",
    "target": "internet"
  }
}
```

### Action Response Handling

Actions are handled in `PackageWidgetRenderer._handleWidgetAction()`:

```dart
void _handleWidgetAction(Map<String, dynamic> actionData) {
  final actionType = actionData['action'] as String?;
  
  switch (actionType) {
    case 'save_settings':
      _handleSaveSettingsAction(actionData);
      break;
    case 'refresh_data': 
      _handleRefreshDataAction(actionData);
      break;
    // ... more action types
  }
}
```

---

## Supported UI Components

### Text Components

#### AppText

```json
{
  "type": "AppText",
  "props": {
    "text": "Display Text",
    "variant": "displayLarge|headlineMedium|titleLarge|bodyMedium|labelSmall",
    "color": "#FF5722",          // Optional: hex color
    "textAlign": "left|center|right|justify",
    "maxLines": 2,
    "overflow": "ellipsis|fade|clip"
  }
}
```

**Text Variant Descriptions:**
- `displayLarge`: Large title (57sp)
- `headlineMedium`: Main headline (28sp)  
- `titleLarge`: Subtitle (22sp)
- `bodyMedium`: Body text (14sp) - Default
- `labelSmall`: Small label (11sp)

### Spacing Components

#### AppGap

```json
{
  "type": "AppGap",
  "props": {
    "size": "xs|sm|md|lg|xl|xxl",    // Standard sizes
    "height": 16,                     // Or custom height
    "width": 16                       // Or custom width  
  }
}
```

**Spacing Sizes:**
- `xs`: 4dp
- `sm`: 8dp  
- `md`: 16dp (default)
- `lg`: 24dp
- `xl`: 32dp
- `xxl`: 48dp

### Button Components

#### AppButton

```json
{
  "type": "AppButton",
  "props": {
    "label": "Button Text",
    "variant": "highlight|tonal|base",
    "size": "small|medium|large",
    "icon": "icon_name",             // Optional icon
    "iconPosition": "leading|trailing",
    "isLoading": false,
    "isEnabled": true,
    "onTap": { "$action": "..." }
  }
}
```

#### AppIconButton

```json
{
  "type": "AppIconButton", 
  "props": {
    "icon": "refresh|settings|more_vert",
    "variant": "highlight|tonal|base",
    "size": "small|medium|large",
    "onTap": { "$action": "..." }
  }
}
```

### Input Components

#### AppTextField

```json
{
  "type": "AppTextField",
  "props": {
    "label": "Label Text",
    "hintText": "Hint Text",
    "value": "Default Value",
    "required": true,
    "obscureText": false,           // Password field
    "keyboardType": "text|number|email|url",
    "maxLength": 50,
    "onChanged": { "$action": "field_changed", "field": "fieldName" }
  }
}
```

#### AppSwitch

```json
{
  "type": "AppSwitch",
  "props": {
    "value": true,
    "label": "Switch Label",            // Optional
    "onChanged": { "$action": "setting_toggled", "setting": "settingName" }
  }
}
```

#### AppDropdown

```json
{
  "type": "AppDropdown",
  "props": {
    "label": "Select Item",
    "value": "option1",
    "options": [
      { "value": "option1", "label": "Option 1" },
      { "value": "option2", "label": "Option 2" }
    ],
    "onChanged": { "$action": "field_changed", "field": "dropdownField" }
  }
}
```

### Container Components

#### AppCard

```json
{
  "type": "AppCard",
  "props": {
    "padding": 16,                  // Inner padding
    "margin": 8,                    // Outer margin  
    "elevation": 2,                 // Shadow depth
    "onTap": { "$action": "..." },  // Optional: tap action
    "children": [...]               // Child components
  }
}
```

### Icon Components

#### AppIcon

```json
{
  "type": "AppIcon", 
  "props": {
    "name": "wifi|ethernet|security|settings",
    "size": 24,
    "color": "#2196F3"
  }
}
```

**Common Icon Names:**
- Network: `wifi`, `ethernet`, `router`, `signal_strength`, `network-ping`
- System: `settings`, `info`, `warning`, `error`, `check_circle`
- Actions: `refresh`, `edit`, `delete`, `add`, `more_vert`
- Navigation: `arrow_back`, `arrow_forward`, `chevron_right`, `expand_more`
- Directional: `arrow-upward`, `arrow-downward`

### Advanced Components

#### AppQrCode

QR code generator for WiFi credentials and other data:

```json
{
  "type": "AppQrCode",
  "props": {
    "data": {
      "$compute": {
        "op": "template",
        "template": "WIFI:T:{mode};S:{ssid};P:{pass};;",
        "data": {
          "mode": { "$bind": "wifi.security_mode" },
          "ssid": { "$bind": "wifi.ssid" },
          "pass": { "$bind": "wifi.password" }
        }
      }
    },
    "size": 200,
    "backgroundColor": "#FFFFFF"
  }
}
```

**AppQrCode Properties:**
- `data`: QR code content (string or computed value)
- `size`: QR code size in pixels (default: 200)
- `backgroundColor`: Background color (default: white)

**Requirements:** Requires `qr_flutter` dependency in the host application.

#### AppGauge

Circular gauge for displaying metrics and system status:

```json
{
  "type": "AppGauge",
  "props": {
    "value": { "$bind": "system.cpu_usage" },
    "min": 0,
    "max": 100,
    "size": 120,
    "strokeWidth": 12,
    "centerContent": {
      "type": "Column",
      "props": {
        "mainAxisAlignment": "center",
        "children": [
          {
            "type": "AppText",
            "props": {
              "text": { "$bind": "system.cpu_usage" },
              "variant": "titleLarge"
            }
          },
          {
            "type": "AppText",
            "props": {
              "text": "CPU",
              "variant": "bodySmall"
            }
          }
        ]
      }
    }
  }
}
```

**AppGauge Properties:**
- `value`: Current gauge value (number or binding)
- `min`: Minimum value (default: 0)
- `max`: Maximum value (default: 100)
- `size`: Gauge diameter in pixels (default: 100)
- `strokeWidth`: Arc thickness in pixels (default: 8)
- `centerContent`: Widget to display in gauge center
- `color`: Gauge color (automatic based on value if not specified)
- `backgroundColor`: Background arc color

### Component Standards

#### Props vs Properties

**✅ Recommended Standard:**
```json
{
  "type": "AppText",
  "props": {
    "text": "Hello World"
  }
}
```

**⚠️ Legacy Support:**
```json
{
  "type": "AppText", 
  "properties": {    // Automatically converted to "props"
    "text": "Hello World"
  }
}
```

The template engine automatically converts `properties` to `props` for backward compatibility, but new implementations should use `props` consistently.

---

## Chart Integration

### Line Chart (AppLineChart)

```json
{
  "type": "AppLineChart",
  "props": {
    "series": [
      {
        "label": "CPU Usage",
        "data": [10, 25, 40, 30, 50, 35, 60],
        "color": "#2196F3",
        "filled": true,               // Fill area
        "dashed": false,              // Dashed line
        "useSecondaryAxis": false     // Use secondary Y-axis
      }
    ],
    "xLabels": ["00:00", "04:00", "08:00", "12:00", "16:00", "20:00", "24:00"],
    "yAxis": {
      "min": 0,
      "max": 100, 
      "interval": 25
    },
    "secondaryYAxis": {              // Optional: right Y-axis
      "min": 0,
      "max": 500,
      "interval": 100
    },
    "showGrid": true,
    "showDots": true,
    "showTooltip": true,
    "enableZoom": false,
    "height": 200
  }
}
```

### Bar Chart (AppBarChart)

```json
{
  "type": "AppBarChart",
  "props": {
    "series": [
      {
        "label": "Download",
        "data": [100, 150, 200, 175, 220],
        "color": "#4CAF50"
      },
      {
        "label": "Upload", 
        "data": [50, 75, 100, 85, 110],
        "color": "#FF5722"
      }
    ],
    "xLabels": ["Jan", "Feb", "Mar", "Apr", "May"],
    "yAxis": {
      "min": 0,
      "max": 250,
      "interval": 50
    },
    "horizontal": false,            // true: horizontal bar chart
    "stacked": false,               // true: stacked bar chart
    "showValueLabels": false,       // Show value labels
    "height": 200
  }
}
```

### Pie Chart (AppPieChart)

```json
{
  "type": "AppPieChart", 
  "props": {
    "sections": [
      {
        "value": 40,
        "label": "WiFi",
        "color": "#2196F3"
      },
      {
        "value": 30,
        "label": "Ethernet",
        "color": "#4CAF50" 
      },
      {
        "value": 20,
        "label": "Guest",
        "color": "#FF9800"
      },
      {
        "value": 10,
        "label": "Other",
        "color": "#9C27B0"
      }
    ],
    "donut": false,                 // true: donut chart
    "showLabels": true,
    "size": 200                     // Chart size
  }
}
```

### Radar Chart (AppRadarChart)

```json
{
  "type": "AppRadarChart",
  "props": {
    "series": [
      {
        "label": "Current Performance",
        "data": [80, 90, 70, 85, 75],
        "color": "#2196F3",
        "filled": true
      },
      {
        "label": "Target Performance",
        "data": [90, 85, 80, 90, 85], 
        "color": "#FF9800",
        "filled": false
      }
    ],
    "axisLabels": ["Speed", "Stability", "Coverage", "Security", "Usability"],
    "showTicks": true,
    "tickCount": 4,
    "size": 200
  }
}
```

### Heatmap Chart (AppHeatmapChart)

```json
{
  "type": "AppHeatmapChart",
  "props": {
    "rows": 3,
    "columns": 4, 
    "values": [
      [0.1, 0.3, 0.8, 0.6],
      [0.4, 0.9, 0.2, 0.7],
      [0.5, 0.1, 0.6, 0.4]
    ],
    "rowLabels": ["2.4GHz", "5GHz", "6GHz"],
    "columnLabels": ["Channel 1", "Channel 6", "Channel 11", "Channel 36"],
    "showValues": true,
    "height": 150
  }
}
```

### Chart Interactions

All charts support touch interactions, automatically generating action events:

```json
// Auto-generated action when user taps chart
{
  "action": "chart_point_selected",
  "chartType": "line",
  "touchType": "tap", 
  "points": [
    {
      "seriesIndex": 0,
      "dataIndex": 2,
      "value": 45.0,
      "position": { "x": 120.5, "y": 85.2 }
    }
  ]
}
```

---

## Data Binding

### USP Data Source

#### Basic USP Subscription

```json
{
  "subscription": {
    "paths": [
      "Device.WiFi.SSID.*.SSID",
      "Device.WiFi.SSID.*.Status"
    ],
    "interval": 5000,              // Update interval (ms)
    "priority": "high"             // Priority
  }
}
```

#### Advanced USP Subscription

```json
{
  "subscription": {
    "paths": [
      "Device.WiFi.SSID.1.SSID",
      "Device.WiFi.AccessPoint.1.Security.KeyPassphrase"
    ],
    "notifType": "ValueChange"     // Notification type
  }
}
```

**USP Subscription Parameters:**
- `paths`: Array of USP data model paths
- `interval`: Update interval in milliseconds (optional)
- `priority`: Subscription priority (`high`, `medium`, `low`)
- `notifType`: USP notification type (`ValueChange`, `ObjectCreation`, `ObjectDeletion`)

### HTTP Data Source

#### Basic HTTP Configuration

```json
{
  "dataSource": {
    "url": "/api/network/status",
    "method": "GET", 
    "headers": {
      "Authorization": "Bearer {token}"
    },
    "refreshInterval": 10,         // Seconds
    "timeout": 5000               // Milliseconds
  }
}
```

#### Advanced HTTP Configuration

```json
{
  "dataSource": {
    "type": "http",
    "url": "/cgi-bin/adguard-status.cgi",
    "method": "POST",
    "body": { 
      "action": "widget",
      "params": {
        "detailed": true
      }
    },
    "headers": {
      "Content-Type": "application/json",
      "X-API-Key": "{api_key}"
    },
    "refreshInterval": 60,         // Practical intervals: 0, 60, 300
    "timeout": 15000,
    "retryCount": 3,
    "mapping": {                   // Response data transformation
      "blocked_today": "blocked_today",
      "queries_today": "queries_today", 
      "status_text": "status_text",
      "cpu_usage": "system.cpu.usage"
    },
    "errorHandling": {
      "fallbackData": {
        "status_text": "Service Unavailable",
        "blocked_today": "-",
        "queries_today": "-"
      }
    }
  }
}
```

**HTTP Data Source Parameters:**
- `type`: Data source type (`http`, `websocket`) 
- `url`: Request URL
- `method`: HTTP method (`GET`, `POST`, `PUT`, `DELETE`)
- `body`: Request body for POST/PUT requests
- `headers`: HTTP headers object
- `refreshInterval`: Update interval in seconds (0 = no refresh, common: 60, 300)
- `timeout`: Request timeout in milliseconds
- `retryCount`: Number of retry attempts on failure
- `mapping`: Maps response fields to widget data keys
- `errorHandling`: Fallback data and error behavior

#### Real-World Usage Patterns

**Refresh Intervals by Use Case:**
- Real-time monitoring: `0` (manual/event-driven)
- Status checking: `60` seconds
- Statistical data: `300` seconds (5 minutes)
- Background sync: `600` seconds (10 minutes)

### Data Binding Syntax

#### Basic Binding

Use `$bind:` syntax in templates to bind data:

```json
{
  "type": "AppText",
  "props": {
    "text": "$bind:device.name",          // Simple binding
    "color": "$bind:status.color"      // Status color binding
  }
}
```

#### Advanced Binding with $compute

Complex computations using multiple data sources:

```json
{
  "type": "AppText",
  "props": {
    "text": {
      "$compute": {
        "op": "conditional",
        "condition": {
          "$compute": {
            "op": "eq",
            "left": { "$bind": "blocked_today" },
            "right": "-"
          }
        },
        "trueValue": { "$bind": "status_text" },
        "falseValue": {
          "$compute": {
            "op": "template",
            "template": "Blocked: {{blocked}} | Queries: {{queries}}",
            "data": {
              "blocked": { "$bind": "blocked_today" },
              "queries": { "$bind": "queries_today" }
            }
          }
        }
      }
    }
  }
}
```

### Data Transformation

#### Simple Transform (Legacy Syntax)

```json
{
  "type": "AppText", 
  "props": {
    "text": "$transform:bandwidth|formatBytes:precision:2"
  }
}
```

#### Advanced Transform (Object Syntax)

```json
{
  "mode": {
    "$transform": {
      "input": { "$bind": "Device.WiFi.AccessPoint.1.Security.ModeEnabled" },
      "ops": [
        {
          "type": "map",
          "mapping": {
            "WPA2-Personal": "WPA",
            "WPA3-Personal": "WPA",
            "WPA3-Personal-Transition": "WPA",
            "None": "nopass"
          },
          "fallback": "WPA"
        }
      ]
    }
  }
}
```

### Compute Operations

#### Supported $compute Operations

| Operation | Description | Parameters |
|-----------|-------------|------------|
| `percent_used` | Calculate percentage usage | `total`, `free` |
| `template` | String interpolation | `template`, `data` |
| `subtract` | Mathematical subtraction | `a`, `b` |
| `ratio` | Calculate ratio | `numerator`, `denominator` |
| `conditional` | Conditional logic | `condition`, `trueValue`, `falseValue` |
| `eq` / `neq` | Equality comparison | `left`, `right` |

#### Percent Usage Example

```json
{
  "type": "AppText",
  "props": {
    "text": {
      "$compute": {
        "op": "percent_used",
        "total": { "$bind": "Device.Memory.Total" },
        "free": { "$bind": "Device.Memory.Free" }
      }
    }
  }
}
```

#### Template Interpolation Example

```json
{
  "type": "AppQrCode",
  "props": {
    "data": {
      "$compute": {
        "op": "template",
        "template": "WIFI:T:{mode};S:{ssid};P:{pass};;",
        "data": {
          "mode": { "$bind": "Device.WiFi.AccessPoint.1.Security.ModeEnabled" },
          "ssid": { "$bind": "Device.WiFi.SSID.1.SSID" },
          "pass": { "$bind": "Device.WiFi.AccessPoint.1.Security.KeyPassphrase" }
        }
      }
    }
  }
}
```

### Conditional Visibility

#### $visible Directive

Control widget visibility based on data conditions:

```json
{
  "type": "AppText",
  "$visible": {
    "condition": "neq",
    "value": { "$bind": "Device.X.Status" },
    "expected": "Disabled"
  },
  "props": {
    "text": "Device is active"
  }
}
```

#### Complex Visibility Conditions

```json
{
  "type": "AppCard",
  "$visible": {
    "$compute": {
      "op": "conditional",
      "condition": {
        "$compute": {
          "op": "gt",
          "left": { "$bind": "device_count" },
          "right": 0
        }
      },
      "trueValue": true,
      "falseValue": false
    }
  },
  "props": {
    "children": [...]
  }
}
```

**Available Transform Functions:**
- `formatBandwidth`: Bandwidth formatting (Mbps/Gbps)
- `formatBytes`: Byte formatting (KB/MB/GB)  
- `formatDuration`: Duration formatting
- `cidrToNetmask`: CIDR to netmask conversion

---

## Best Practices

### 1. Design Principles

#### Visual Consistency
```json
// ✅ Recommended: Use standard spacing
{
  "type": "AppGap",
  "props": { "size": "md" }  // 16dp standard spacing
}

// ❌ Avoid: Arbitrary custom spacing
{
  "type": "AppGap", 
  "props": { "height": 17 }  // Non-standard spacing
}
```

#### Text Hierarchy
```json
// ✅ Recommended: Clear text hierarchy
{
  "type": "Column",
  "props": {
    "children": [
      {
        "type": "AppText",
        "props": {
          "text": "Network Status",        // Title
          "variant": "titleLarge"
        }
      },
      {
        "type": "AppText", 
        "props": {
          "text": "Connected",         // Content
          "variant": "bodyMedium"
        }
      }
    ]
  }
}
```

### 2. Performance Optimization

#### Reasonable Constraint Settings
```json
// ✅ Recommended: Reasonable constraint range
{
  "constraints": {
    "minColumns": 3,
    "maxColumns": 6,
    "preferredColumns": 4
  }
}

// ❌ Avoid: Excessive constraint range
{
  "constraints": {
    "minColumns": 1,
    "maxColumns": 12,    // Too wide range
    "preferredColumns": 4
  }
}
```

#### Limit Nesting Depth
```json
// ✅ Recommended: Shallow nesting
{
  "type": "Column",
  "props": {
    "children": [
      { "type": "AppText", "props": {...} },
      { "type": "AppButton", "props": {...} }
    ]
  }
}

// ❌ Avoid: Deep nesting (>5 levels)
```

### 3. Maintainability

#### Semantic Naming
```json
// ✅ Recommended: Clear action naming
{
  "$action": "refresh_network_status",
  "component": "wifi_status"
}

// ❌ Avoid: Vague naming
{
  "$action": "do_something",
  "data": "stuff" 
}
```

#### Error Handling
```json
// ✅ Recommended: Include error states
{
  "type": "AppText",
  "props": {
    "text": "$bind:networkStatus|default:'Connecting...'"
  }
}
```

### 4. Accessibility Support

#### Provide Semantic Labels
```json
{
  "type": "AppButton",
  "props": {
    "label": "Refresh Network Status",
    "semanticLabel": "Refresh button, tap to update network status information",
    "onTap": { "$action": "refresh_data" }
  }
}
```

### 5. Internationalization

#### Externalize Text
```json
// ✅ Recommended: Use i18n keys
{
  "type": "AppText",
  "props": {
    "text": "$i18n:network.status.title"
  }
}

// ❌ Avoid: Hard-coded text
{
  "type": "AppText",
  "props": {
    "text": "Network Status"
  }
}
```

---

## Common Examples

### 1. Simple Status Card

```json
{
  "widgetId": "simple_status_card",
  "displayName": "Network Status",
  "description": "Display basic network connection status",
  "constraints": {
    "minColumns": 2,
    "maxColumns": 4,
    "preferredColumns": 3,
    "minRows": 2,
    "maxRows": 3,
    "preferredRows": 2
  },
  "template": {
    "type": "Column",
    "props": {
      "mainAxisAlignment": "center",
      "children": [
        {
          "type": "AppIcon",
          "props": {
            "name": "wifi",
            "size": 32,
            "color": "#4CAF50"
          }
        },
        {
          "type": "AppGap",
          "props": { "size": "sm" }
        },
        {
          "type": "AppText",
          "props": {
            "text": "$bind:network.status",
            "variant": "titleMedium",
            "textAlign": "center"
          }
        },
        {
          "type": "AppText",
          "props": {
            "text": "$bind:network.ssid|default:'Not connected'",
            "variant": "bodySmall",
            "textAlign": "center"
          }
        }
      ]
    }
  },
  "subscription": {
    "paths": ["Device.WiFi.SSID.*.Status", "Device.WiFi.SSID.*.SSID"],
    "interval": 5000
  }
}
```

### 2. Interactive Settings Card

```json
{
  "widgetId": "wifi_settings_card", 
  "displayName": "WiFi Settings",
  "description": "Quick WiFi settings adjustment",
  "constraints": {
    "minColumns": 3,
    "maxColumns": 6,
    "preferredColumns": 4,
    "minRows": 3,
    "maxRows": 5,
    "preferredRows": 4
  },
  "template": {
    "type": "Column",
    "props": {
      "crossAxisAlignment": "stretch",
      "children": [
        {
          "type": "AppText",
          "props": {
            "text": "WiFi Settings",
            "variant": "titleLarge"
          }
        },
        {
          "type": "AppGap",
          "props": { "size": "md" }
        },
        {
          "type": "AppTextField",
          "props": {
            "label": "Network Name (SSID)",
            "value": "$bind:wifi.ssid",
            "onChanged": {
              "$action": "field_changed",
              "field": "ssid"
            }
          }
        },
        {
          "type": "AppGap",
          "props": { "size": "sm" }
        },
        {
          "type": "Row",
          "props": {
            "mainAxisAlignment": "spaceBetween",
            "children": [
              {
                "type": "AppText",
                "props": {
                  "text": "Enable 5GHz",
                  "variant": "bodyMedium"
                }
              },
              {
                "type": "AppSwitch",
                "props": {
                  "value": "$bind:wifi.enable5ghz|default:true",
                  "onChanged": {
                    "$action": "setting_toggled",
                    "setting": "enable5ghz"
                  }
                }
              }
            ]
          }
        },
        {
          "type": "AppGap",
          "props": { "size": "md" }
        },
        {
          "type": "Row",
          "props": {
            "mainAxisAlignment": "end",
            "children": [
              {
                "type": "AppButton",
                "props": {
                  "label": "Apply",
                  "variant": "highlight",
                  "onTap": {
                    "$action": "save_settings",
                    "section": "wifi",
                    "validate": true,
                    "showConfirm": true
                  }
                }
              }
            ]
          }
        }
      ]
    }
  }
}
```

### 3. Chart Dashboard

```json
{
  "widgetId": "network_traffic_dashboard",
  "displayName": "Network Traffic Dashboard", 
  "description": "Real-time network traffic monitoring",
  "constraints": {
    "minColumns": 6,
    "maxColumns": 12,
    "preferredColumns": 8,
    "minRows": 4,
    "maxRows": 8,
    "preferredRows": 6
  },
  "template": {
    "type": "Column",
    "props": {
      "crossAxisAlignment": "stretch",
      "children": [
        {
          "type": "Row",
          "props": {
            "mainAxisAlignment": "spaceBetween",
            "children": [
              {
                "type": "AppText",
                "props": {
                  "text": "Network Traffic",
                  "variant": "titleLarge"
                }
              },
              {
                "type": "AppIconButton",
                "props": {
                  "icon": "refresh",
                  "variant": "base",
                  "onTap": {
                    "$action": "refresh_data"
                  }
                }
              }
            ]
          }
        },
        {
          "type": "AppGap",
          "props": { "size": "md" }
        },
        {
          "type": "AppLineChart",
          "props": {
            "series": [
              {
                "label": "Download",
                "data": "$bind:traffic.download",
                "color": "#4CAF50",
                "filled": true
              },
              {
                "label": "Upload", 
                "data": "$bind:traffic.upload",
                "color": "#FF5722"
              }
            ],
            "xLabels": "$bind:traffic.timestamps",
            "yAxis": {
              "min": 0,
              "max": "$bind:traffic.maxBandwidth|default:100"
            },
            "showGrid": true,
            "showTooltip": true,
            "height": 200
          }
        },
        {
          "type": "AppGap",
          "props": { "size": "md" }
        },
        {
          "type": "Row",
          "props": {
            "mainAxisAlignment": "spaceAround", 
            "children": [
              {
                "type": "Column",
                "props": {
                  "mainAxisSize": "min",
                  "children": [
                    {
                      "type": "AppText",
                      "props": {
                        "text": "$bind:traffic.currentDownload|formatBandwidth",
                        "variant": "titleMedium"
                      }
                    },
                    {
                      "type": "AppText",
                      "props": {
                        "text": "Current Download",
                        "variant": "bodySmall"
                      }
                    }
                  ]
                }
              },
              {
                "type": "Column",
                "props": {
                  "mainAxisSize": "min",
                  "children": [
                    {
                      "type": "AppText",
                      "props": {
                        "text": "$bind:traffic.currentUpload|formatBandwidth", 
                        "variant": "titleMedium"
                      }
                    },
                    {
                      "type": "AppText",
                      "props": {
                        "text": "Current Upload",
                        "variant": "bodySmall"
                      }
                    }
                  ]
                }
              }
            ]
          }
        }
      ]
    }
  },
  "dataSource": {
    "url": "/api/network/traffic",
    "method": "GET", 
    "refreshInterval": 5
  }
}
```

### 4. Real-World Complex Examples

#### AdGuard Home Status Widget

Advanced status widget with conditional logic and complex data binding:

```json
{
  "widgetId": "adguard_home_status",
  "displayName": "AdGuard Home Status",
  "description": "Advanced ad-blocking status with conditional display",
  "constraints": {
    "minColumns": 3,
    "maxColumns": 4, 
    "preferredColumns": 3,
    "minRows": 2,
    "maxRows": 3,
    "preferredRows": 2
  },
  "template": {
    "type": "AppCard",
    "props": {
      "padding": 16,
      "children": [
        {
          "type": "Column",
          "props": {
            "crossAxisAlignment": "stretch",
            "children": [
              {
                "type": "Row",
                "props": {
                  "mainAxisAlignment": "spaceBetween",
                  "children": [
                    {
                      "type": "AppText",
                      "props": {
                        "text": "AdGuard Home",
                        "variant": "titleMedium"
                      }
                    },
                    {
                      "type": "AppIcon",
                      "props": {
                        "name": {
                          "$compute": {
                            "op": "conditional",
                            "condition": {
                              "$compute": {
                                "op": "eq",
                                "left": { "$bind": "status" },
                                "right": "active"
                              }
                            },
                            "trueValue": "check_circle",
                            "falseValue": "error"
                          }
                        },
                        "color": {
                          "$compute": {
                            "op": "conditional",
                            "condition": {
                              "$compute": {
                                "op": "eq",
                                "left": { "$bind": "status" },
                                "right": "active"
                              }
                            },
                            "trueValue": "#4CAF50",
                            "falseValue": "#F44336"
                          }
                        }
                      }
                    }
                  ]
                }
              },
              {
                "type": "AppGap",
                "props": { "size": "sm" }
              },
              {
                "type": "AppText",
                "props": {
                  "text": {
                    "$compute": {
                      "op": "conditional",
                      "condition": {
                        "$compute": {
                          "op": "eq",
                          "left": { "$bind": "blocked_today" },
                          "right": "-"
                        }
                      },
                      "trueValue": { "$bind": "status_text" },
                      "falseValue": {
                        "$compute": {
                          "op": "template",
                          "template": "Blocked: {{blocked}} | Queries: {{queries}}",
                          "data": {
                            "blocked": { "$bind": "blocked_today" },
                            "queries": { "$bind": "queries_today" }
                          }
                        }
                      }
                    }
                  },
                  "variant": "bodySmall"
                }
              }
            ]
          }
        }
      ]
    }
  },
  "dataSource": {
    "type": "http",
    "url": "/cgi-bin/adguard-status.cgi",
    "method": "POST",
    "body": { "action": "widget" },
    "refreshInterval": 60,
    "mapping": {
      "blocked_today": "blocked_today",
      "queries_today": "queries_today",
      "status_text": "status_text",
      "status": "service_status"
    },
    "errorHandling": {
      "fallbackData": {
        "status_text": "Service Unavailable",
        "blocked_today": "-",
        "queries_today": "-",
        "status": "error"
      }
    }
  }
}
```

#### WiFi QR Code Generator

Dynamic QR code generation with USP data and advanced transforms:

```json
{
  "widgetId": "wifi_qr_generator",
  "displayName": "WiFi QR Code",
  "description": "Generate QR code for WiFi credentials",
  "constraints": {
    "minColumns": 3,
    "maxColumns": 4,
    "preferredColumns": 3,
    "minRows": 3,
    "maxRows": 4,
    "preferredRows": 3
  },
  "template": {
    "type": "Column",
    "props": {
      "mainAxisAlignment": "center",
      "crossAxisAlignment": "center",
      "children": [
        {
          "type": "AppText",
          "props": {
            "text": "WiFi Access",
            "variant": "titleMedium",
            "textAlign": "center"
          }
        },
        {
          "type": "AppGap",
          "props": { "size": "sm" }
        },
        {
          "type": "AppQrCode",
          "$visible": {
            "condition": "neq",
            "value": { "$bind": "Device.WiFi.SSID.1.SSID" },
            "expected": "--"
          },
          "props": {
            "data": {
              "$compute": {
                "op": "template",
                "template": "WIFI:T:{mode};S:{ssid};P:{pass};;",
                "data": {
                  "mode": {
                    "$transform": {
                      "input": { "$bind": "Device.WiFi.AccessPoint.1.Security.ModeEnabled" },
                      "ops": [
                        {
                          "type": "map",
                          "mapping": {
                            "WPA2-Personal": "WPA",
                            "WPA3-Personal": "WPA",
                            "WPA3-Personal-Transition": "WPA",
                            "None": "nopass"
                          },
                          "fallback": "WPA"
                        }
                      ]
                    }
                  },
                  "ssid": { "$bind": "Device.WiFi.SSID.1.SSID" },
                  "pass": { "$bind": "Device.WiFi.AccessPoint.1.Security.KeyPassphrase" }
                }
              }
            },
            "size": 160
          }
        },
        {
          "type": "AppText",
          "$visible": {
            "condition": "eq",
            "value": { "$bind": "Device.WiFi.SSID.1.SSID" },
            "expected": "--"
          },
          "props": {
            "text": "WiFi not configured",
            "variant": "bodySmall",
            "textAlign": "center"
          }
        }
      ]
    }
  },
  "subscription": {
    "paths": [
      "Device.WiFi.SSID.1.SSID",
      "Device.WiFi.AccessPoint.1.Security.KeyPassphrase",
      "Device.WiFi.AccessPoint.1.Security.ModeEnabled"
    ],
    "notifType": "ValueChange"
  }
}
```

#### System Performance Gauge

Multi-gauge system monitoring with computed values:

```json
{
  "widgetId": "system_performance_gauges",
  "displayName": "System Performance",
  "description": "CPU, Memory, and Storage usage gauges",
  "constraints": {
    "minColumns": 4,
    "maxColumns": 8,
    "preferredColumns": 6,
    "minRows": 3,
    "maxRows": 4,
    "preferredRows": 3
  },
  "template": {
    "type": "Column",
    "props": {
      "children": [
        {
          "type": "AppText",
          "props": {
            "text": "System Performance",
            "variant": "titleLarge",
            "textAlign": "center"
          }
        },
        {
          "type": "AppGap",
          "props": { "size": "md" }
        },
        {
          "type": "Row",
          "props": {
            "mainAxisAlignment": "spaceEvenly",
            "children": [
              {
                "type": "AppGauge",
                "props": {
                  "value": {
                    "$compute": {
                      "op": "percent_used",
                      "total": { "$bind": "Device.CPU.Total" },
                      "free": { "$bind": "Device.CPU.Idle" }
                    }
                  },
                  "size": 80,
                  "centerContent": {
                    "type": "Column",
                    "props": {
                      "mainAxisAlignment": "center",
                      "children": [
                        {
                          "type": "AppText",
                          "props": {
                            "text": {
                              "$compute": {
                                "op": "percent_used",
                                "total": { "$bind": "Device.CPU.Total" },
                                "free": { "$bind": "Device.CPU.Idle" }
                              }
                            },
                            "variant": "bodySmall"
                          }
                        },
                        {
                          "type": "AppText",
                          "props": {
                            "text": "CPU",
                            "variant": "labelSmall"
                          }
                        }
                      ]
                    }
                  }
                }
              },
              {
                "type": "AppGauge",
                "props": {
                  "value": {
                    "$compute": {
                      "op": "percent_used",
                      "total": { "$bind": "Device.Memory.Total" },
                      "free": { "$bind": "Device.Memory.Free" }
                    }
                  },
                  "size": 80,
                  "centerContent": {
                    "type": "Column",
                    "props": {
                      "mainAxisAlignment": "center",
                      "children": [
                        {
                          "type": "AppText",
                          "props": {
                            "text": {
                              "$compute": {
                                "op": "percent_used",
                                "total": { "$bind": "Device.Memory.Total" },
                                "free": { "$bind": "Device.Memory.Free" }
                              }
                            },
                            "variant": "bodySmall"
                          }
                        },
                        {
                          "type": "AppText",
                          "props": {
                            "text": "Memory",
                            "variant": "labelSmall"
                          }
                        }
                      ]
                    }
                  }
                }
              }
            ]
          }
        }
      ]
    }
  },
  "subscription": {
    "paths": [
      "Device.CPU.Total",
      "Device.CPU.Idle", 
      "Device.Memory.Total",
      "Device.Memory.Free"
    ],
    "notifType": "ValueChange"
  }
}
```

---

## Troubleshooting

### Common Errors

#### 1. JSON Format Errors

**Symptoms**: Widget fails to load, shows parsing error

**Solutions:**
- Use JSON validation tools to check syntax
- Check for missing commas, quotes, brackets
- Ensure all strings are surrounded by double quotes

```json
// ❌ Error: Missing comma
{
  "widgetId": "test"
  "displayName": "Test"
}

// ✅ Correct
{
  "widgetId": "test",
  "displayName": "Test"
}
```

#### 2. Constraint Conflicts

**Symptoms**: Widget displays abnormally or cannot be resized

**Solutions:**
- Ensure `minColumns <= preferredColumns <= maxColumns`
- Ensure `minRows <= preferredRows <= maxRows`
- Check that constraint values are positive integers

```json
// ❌ Error: Constraint conflict
{
  "constraints": {
    "minColumns": 6,
    "maxColumns": 4
  }
}

// ✅ Correct
{
  "constraints": {
    "minColumns": 2,
    "maxColumns": 6,
    "preferredColumns": 4
  }
}
```

#### 3. Component Property Errors

**Symptoms**: Component doesn't display or shows error

**Solutions:**
- Check component type spelling (`AppText` vs `AppTxt`)
- Confirm required properties are provided
- Check property value types are correct

```json
// ❌ Error: Component name misspelled
{
  "type": "AppTxt",
  "props": { "text": "Hello" }
}

// ✅ Correct
{
  "type": "AppText", 
  "props": { "text": "Hello" }
}
```

#### 4. Action Handling Failure

**Symptoms**: Button taps have no response

**Solutions:**
- Confirm action type spelling is correct
- Check required action parameters
- Verify action handler is implemented

```json
// ❌ Error: Action type misspelled
{
  "onTap": {
    "$action": "save_setting"  // Should be save_settings
  }
}

// ✅ Correct
{
  "onTap": {
    "$action": "save_settings",
    "section": "network"
  }
}
```

#### 5. Data Binding Failure

**Symptoms**: Shows `$bind:...` literal text

**Solutions:**
- Check data path is correct
- Confirm data source is properly configured
- Check data has loaded

```json
// ❌ Error: Incorrect binding syntax
{
  "text": "bind:device.name"  // Missing $
}

// ✅ Correct  
{
  "text": "$bind:device.name"
}
```

### Debugging Tools

#### 1. Developer Tools
Check in Flutter DevTools:
- Widget tree structure
- Provider state
- Network requests

#### 2. Log Messages
Check for logs like:
```
[PkgWidget] Loading widget: network_status_card
[PkgWidget] Action triggered: save_settings
[PkgWidget] Data binding failed: device.name
```

#### 3. JSON Validation
Use online JSON validation tools:
- JSONLint: https://jsonlint.com/
- JSONFormatter: https://jsonformatter.org/

### Performance Issues

#### 1. Slow Widget Loading

**Possible Causes:**
- Overly complex UI structure
- Excessive data binding
- Frequent data updates

**Solutions:**
- Simplify UI structure
- Use pagination or virtualization
- Adjust update intervals

#### 2. High Memory Usage

**Possible Causes:**
- Too much chart data
- Unreleased resources
- Memory leaks

**Solutions:**
- Limit chart data point count
- Implement data caching strategy
- Periodically clean unused data

---

## Version Updates

### v2.16.1 New Features

1. **Enhanced Template Engine**: 
   - Added `onAction` callback support
   - Improved error handling and theme consistency

2. **Complete Chart System**:
   - 5 chart types support
   - Touch interaction integration
   - Automated action generation

3. **Improved Component Specs**:
   - All chart components registered
   - 100% test coverage
   - Stable API

### Backward Compatibility

- ✅ Fully compatible with v2.15.x
- ✅ Existing widgets require no changes
- ✅ All APIs remain unchanged

### Upgrade Guide

1. Update `pubspec.yaml`:
```yaml
ui_kit_library:
  git:
    url: https://github.com/linksys/privacyGUI-UI-kit.git
    ref: v2.16.1
```

2. Run `flutter pub get`

3. Optional: Use new chart components and action system

---

## Summary

The Dashboard Widget Card system provides a powerful and flexible way to create dynamic UI components. By following the best practices and specifications in this guide, you can create high-quality, maintainable widget cards.

### Key Points

1. **Structured Design**: Follow JSON structure specifications
2. **Responsive Layout**: Set reasonable constraint parameters
3. **User Experience**: Implement meaningful interactions
4. **Performance Optimization**: Avoid overly complex structures
5. **Maintainability**: Use semantic naming and clear comments

### Next Steps

- Explore advanced features like custom action handlers
- Learn to build reusable widget templates
- Implement complex data transformation and validation logic

For more help, refer to:
- [UI Kit Component Documentation](./ui-kit-components.md)
- [Action System Deep Dive](./package-widget-action-system.md)  
- [Data Binding Guide](./data-binding-guide.md)

---

*Last updated: March 31, 2026*
*Version: v2.16.1*