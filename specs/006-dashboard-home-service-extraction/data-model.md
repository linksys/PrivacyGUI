# Data Model: DashboardHome Service Extraction

**Feature**: 006-dashboard-home-service-extraction
**Date**: 2025-12-29

## Overview

This refactoring does not introduce new data models. It relocates transformation logic while preserving existing model structures.

---

## Existing Models (Unchanged)

### DashboardHomeState

**Location**: `lib/page/dashboard/providers/dashboard_home_state.dart`
**Type**: UI State Model
**Changes**: Remove JNAP model imports only (structure unchanged)

| Field | Type | Description |
|-------|------|-------------|
| isFirstPolling | `bool` | Whether this is the first data poll |
| isHorizontalLayout | `bool` | Port layout orientation |
| masterIcon | `String` | Router icon asset path |
| isAnyNodesOffline | `bool` | Whether any mesh nodes are offline |
| uptime | `int?` | Router uptime in seconds |
| wanPortConnection | `String?` | WAN port connection status |
| lanPortConnections | `List<String>` | LAN port connection statuses |
| wifis | `List<DashboardWiFiUIModel>` | WiFi network list |
| wanType | `String?` | WAN connection type |
| detectedWANType | `String?` | Auto-detected WAN type |

---

### DashboardWiFiUIModel

**Location**: `lib/page/dashboard/providers/dashboard_home_state.dart`
**Type**: UI Model
**Changes**: Remove factory methods that accept JNAP models

| Field | Type | Description |
|-------|------|-------------|
| ssid | `String` | Network name |
| password | `String` | Network password |
| radios | `List<String>` | Radio IDs broadcasting this network |
| isGuest | `bool` | Whether this is a guest network |
| isEnabled | `bool` | Whether the network is enabled |
| numOfConnectedDevices | `int` | Count of connected devices |

**Factory Methods to Remove**:
- `fromMainRadios(List<RouterRadio>, int)` → Move to service
- `fromGuestRadios(List<GuestRadioInfo>, int)` → Move to service

---

### DashboardSpeedUIModel

**Location**: `lib/page/dashboard/providers/dashboard_home_state.dart`
**Type**: UI Model
**Changes**: None (no JNAP dependencies)

| Field | Type | Description |
|-------|------|-------------|
| unit | `String` | Speed unit (Mbps, Gbps) |
| value | `String` | Speed value |

---

## Input Models (From JNAP Layer - Read Only)

These models are consumed by the service but defined in `core/jnap/`:

### DashboardManagerState

**Location**: `lib/core/jnap/providers/dashboard_manager_state.dart`

| Field | Type | Used For |
|-------|------|----------|
| mainRadios | `List<RouterRadio>` | Building main WiFi items |
| guestRadios | `List<GuestRadioInfo>` | Building guest WiFi item |
| isGuestNetworkEnabled | `bool` | Guest network enabled flag |
| uptimes | `int` | Router uptime |
| wanConnection | `String?` | WAN port status |
| lanConnections | `List<String>` | LAN port statuses |
| deviceInfo | `NodeDeviceInfo?` | Port layout determination |

### DeviceManagerState

**Location**: `lib/core/jnap/providers/device_manager_state.dart`

| Field | Type | Used For |
|-------|------|----------|
| mainWifiDevices | `List<LinksysDevice>` | Counting main WiFi connections |
| guestWifiDevices | `List<LinksysDevice>` | Counting guest WiFi connections |
| nodeDevices | `List<LinksysDevice>` | Checking node offline status |
| wanStatus | `WANStatus?` | WAN type information |
| lastUpdateTime | `int` | First polling detection |
| deviceList | `List<LinksysDevice>` | Master icon determination |

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        INPUT (JNAP Layer)                       │
├─────────────────────────────────────────────────────────────────┤
│  DashboardManagerState    DeviceManagerState    HealthCheckState│
│  - mainRadios             - mainWifiDevices     (unused)        │
│  - guestRadios            - guestWifiDevices                    │
│  - uptimes                - nodeDevices                         │
│  - wanConnection          - wanStatus                           │
│  - lanConnections         - lastUpdateTime                      │
│  - deviceInfo             - deviceList                          │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DashboardHomeService                         │
│                    (NEW - Transformation)                       │
├─────────────────────────────────────────────────────────────────┤
│  buildDashboardHomeState(...)                                   │
│  ├── _buildMainWiFiItems()   ← Groups radios by band            │
│  ├── _buildGuestWiFiItem()   ← Creates guest network item       │
│  ├── _checkNodesOffline()    ← Checks node status               │
│  ├── _getMasterIcon()        ← Determines router icon           │
│  └── _getPortLayout()        ← Determines port orientation      │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                        OUTPUT (UI Layer)                        │
├─────────────────────────────────────────────────────────────────┤
│  DashboardHomeState                                             │
│  - wifis: List<DashboardWiFiUIModel>                               │
│  - uptime, wanPortConnection, lanPortConnections                │
│  - isFirstPolling, masterIcon, isAnyNodesOffline                │
│  - isHorizontalLayout, wanType, detectedWANType                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Validation Rules

| Rule | Applies To | Validation |
|------|-----------|------------|
| Non-empty SSID | DashboardWiFiUIModel | Extracted from radio.settings.ssid (always present) |
| Valid radio list | DashboardWiFiUIModel | At least one radio required for main/guest |
| Non-negative device count | DashboardWiFiUIModel | Filtered count from device list |

---

## State Transitions

Not applicable - this is a pure transformation service with no state lifecycle.
