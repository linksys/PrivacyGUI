# Data Model: Dashboard Manager Service Extraction

**Date**: 2025-12-29
**Status**: Complete

## Overview

This refactoring does not introduce new data models. It reorganizes existing data flow between layers.

---

## Existing Entities (Unchanged)

### DashboardManagerState

**Location**: `lib/core/jnap/providers/dashboard_manager_state.dart`
**Role**: UI state for dashboard, consumed by views

```dart
class DashboardManagerState extends Equatable {
  final NodeDeviceInfo? deviceInfo;
  final List<RouterRadio> mainRadios;
  final List<GuestRadioInfo> guestRadios;
  final bool isGuestNetworkEnabled;
  final int uptimes;
  final String? wanConnection;
  final List<String> lanConnections;
  final String? skuModelNumber;
  final int localTime;
  final String? cpuLoad;
  final String? memoryLoad;
}
```

**Decision**: No UI Model needed per Article V Section 5.3.4:
- ❌ Not a collection type requiring separate items
- ❌ Not reused across multiple features
- ❌ Not deeply nested (flat structure with ~10 fields)
- ❌ No complex computed properties needed

---

## JNAP Models (Referenced by Service Only)

These models are imported by `DashboardManagerService` but NOT by `DashboardManagerNotifier`:

| Model | Source | Used For |
|-------|--------|----------|
| `NodeDeviceInfo` | `jnap/models/device_info.dart` | Device identification, serial number |
| `RouterRadio` | `jnap/models/radio_info.dart` | Main WiFi radio settings |
| `GuestRadioInfo` | `jnap/models/guest_radio_settings.dart` | Guest network radio settings |
| `GuestRadioSettings` | `jnap/models/guest_radio_settings.dart` | Guest network enabled state |
| `GetRadioInfo` | `jnap/models/radio_info.dart` | Radio info response parsing |
| `SoftSKUSettings` | `jnap/models/soft_sku_settings.dart` | SKU model number |

---

## Data Flow

### Before Refactoring (Current)

```
┌─────────────────┐     ┌────────────────────────────┐     ┌──────────────┐
│ pollingProvider │────▶│ DashboardManagerNotifier   │────▶│ UI Views     │
│                 │     │ - imports jnap/models      │     │              │
│                 │     │ - imports jnap/result      │     │              │
│                 │     │ - transforms data          │     │              │
└─────────────────┘     └────────────────────────────┘     └──────────────┘
```

### After Refactoring (Target)

```
┌─────────────────┐     ┌─────────────────────────┐     ┌────────────────────────────┐     ┌──────────────┐
│ pollingProvider │────▶│ DashboardManagerService │────▶│ DashboardManagerNotifier   │────▶│ UI Views     │
│                 │     │ - imports jnap/models   │     │ - NO jnap imports          │     │              │
│                 │     │ - imports jnap/result   │     │ - delegates to service     │     │              │
│                 │     │ - transforms data       │     │ - manages state lifecycle  │     │              │
└─────────────────┘     └─────────────────────────┘     └────────────────────────────┘     └──────────────┘
```

---

## State Transitions

### DashboardManagerState Lifecycle

```
┌─────────────────────┐
│ Initial (empty)     │
│ - deviceInfo: null  │
│ - mainRadios: []    │
│ - uptimes: 0        │
└──────────┬──────────┘
           │ transformPollingData(valid data)
           ▼
┌─────────────────────┐
│ Populated           │
│ - deviceInfo: {...} │
│ - mainRadios: [...] │
│ - uptimes: N        │
└──────────┬──────────┘
           │ transformPollingData(partial failure)
           ▼
┌─────────────────────┐
│ Partial             │
│ - deviceInfo: {...} │  ← successful action
│ - mainRadios: []    │  ← failed action (default)
│ - uptimes: N        │
└─────────────────────┘
```

---

## Validation Rules

### transformPollingData()

| Field | Validation | Default |
|-------|------------|---------|
| `deviceInfo` | Optional | `null` |
| `mainRadios` | List, can be empty | `[]` |
| `guestRadios` | List, can be empty | `[]` |
| `isGuestNetworkEnabled` | Boolean | `false` |
| `uptimes` | Integer >= 0 | `0` |
| `wanConnection` | Optional string | `null` |
| `lanConnections` | List of strings | `[]` |
| `skuModelNumber` | Optional string | `null` |
| `localTime` | Integer (milliseconds) | Current device time |
| `cpuLoad` | Optional string | `null` |
| `memoryLoad` | Optional string | `null` |

### checkRouterIsBack()

| Condition | Behavior |
|-----------|----------|
| Router accessible, SN matches | Returns `NodeDeviceInfo` |
| Router accessible, SN mismatch | Throws `SerialNumberMismatchError` |
| Router not accessible | Throws `ConnectivityError` |

### checkDeviceInfo()

| Condition | Behavior |
|-----------|----------|
| State has deviceInfo | Returns cached value |
| State deviceInfo is null | Makes API call, returns fresh value |
| API call fails | Throws `ServiceError` |
