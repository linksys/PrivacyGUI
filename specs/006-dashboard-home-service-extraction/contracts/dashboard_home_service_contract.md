# Service Contract: DashboardHomeService

**Feature**: 006-dashboard-home-service-extraction
**Date**: 2025-12-29
**Location**: `lib/page/dashboard/services/dashboard_home_service.dart`

---

## Overview

`DashboardHomeService` is a stateless service responsible for transforming JNAP-layer state data into UI-layer `DashboardHomeState`. It encapsulates all JNAP model dependencies, keeping the Provider layer architecture-compliant.

---

## Provider Definition

```dart
/// Riverpod provider for DashboardHomeService
final dashboardHomeServiceProvider = Provider<DashboardHomeService>((ref) {
  return DashboardHomeService();
});
```

---

## Class Definition

```dart
/// Stateless service for dashboard home state transformation
///
/// Encapsulates JNAP model transformations, separating data layer
/// concerns from state management (DashboardHomeNotifier).
class DashboardHomeService {
  const DashboardHomeService();

  // ... methods defined below
}
```

---

## Public Methods

### buildDashboardHomeState

Transforms JNAP-layer state data into a complete `DashboardHomeState`.

**Signature**:
```dart
DashboardHomeState buildDashboardHomeState({
  required DashboardManagerState dashboardManagerState,
  required DeviceManagerState deviceManagerState,
  required String Function(LinksysDevice device) getBandForDevice,
  required List<LinksysDevice> deviceList,
});
```

**Parameters**:

| Parameter | Type | Description |
|-----------|------|-------------|
| dashboardManagerState | `DashboardManagerState` | State containing radio info, uptime, port connections |
| deviceManagerState | `DeviceManagerState` | State containing device list, WAN status, node info |
| getBandForDevice | `String Function(LinksysDevice)` | Callback to get band for a device (from DeviceManagerNotifier) |
| deviceList | `List<LinksysDevice>` | Sorted device list for master icon determination |

**Returns**: `DashboardHomeState` - Complete UI state for dashboard home

**Example Usage**:
```dart
final service = ref.read(dashboardHomeServiceProvider);
final state = service.buildDashboardHomeState(
  dashboardManagerState: ref.watch(dashboardManagerProvider),
  deviceManagerState: ref.watch(deviceManagerProvider),
  getBandForDevice: (device) =>
      ref.read(deviceManagerProvider.notifier).getBandConnectedBy(device),
  deviceList: ref.read(deviceManagerProvider).deviceList,
);
```

**Behavior**:
1. Groups main radios by band and creates WiFi items with connected device counts
2. Creates guest WiFi item if guest radios exist
3. Determines node offline status
4. Extracts WAN type and detected WAN type
5. Determines if this is the first polling cycle
6. Gets master node icon based on model number
7. Determines port layout orientation

---

## Private Methods (Internal Contract)

These methods are implementation details but documented for completeness.

### _buildMainWiFiItems

```dart
List<DashboardWiFiUIModel> _buildMainWiFiItems({
  required List<RouterRadio> mainRadios,
  required List<LinksysDevice> mainWifiDevices,
  required String Function(LinksysDevice) getBandForDevice,
});
```

Groups radios by band and creates `DashboardWiFiUIModel` for each band.

### _buildGuestWiFiItem

```dart
DashboardWiFiUIModel? _buildGuestWiFiItem({
  required List<GuestRadioInfo> guestRadios,
  required List<LinksysDevice> guestWifiDevices,
  required bool isGuestNetworkEnabled,
});
```

Creates guest network WiFi item if guest radios exist.

### _createWiFiItemFromMainRadios

```dart
DashboardWiFiUIModel _createWiFiItemFromMainRadios(
  List<RouterRadio> radios,
  int connectedDevices,
);
```

Creates `DashboardWiFiUIModel` from main radio list (replaces factory method).

### _createWiFiItemFromGuestRadios

```dart
DashboardWiFiUIModel _createWiFiItemFromGuestRadios(
  List<GuestRadioInfo> radios,
  int connectedDevices,
);
```

Creates `DashboardWiFiUIModel` from guest radio list (replaces factory method).

---

## Dependencies

### Required Imports (Service Layer Only)

```dart
// JNAP models (allowed in service layer)
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';

// JNAP state (allowed in service layer)
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';

// Utility functions
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/nodes.dart';

// UI models (service returns these)
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
```

### External Dependencies

| Dependency | Purpose |
|------------|---------|
| `collection` | `groupFoldBy` for radio grouping |
| `routerIconTestByModel()` | Icon determination utility |
| `isHorizontalPorts()` | Port layout determination utility |

---

## Error Handling

This service performs pure data transformation with no external I/O. No exceptions are thrown.

**Edge Cases Handled**:
| Case | Behavior |
|------|----------|
| Empty mainRadios | Returns empty WiFi list |
| Empty guestRadios | Does not add guest WiFi item |
| Null deviceInfo | Uses default values for port layout |
| All nodes offline | Sets `isAnyNodesOffline = true` |
| First polling (lastUpdateTime == 0) | Sets `isFirstPolling = true` |

---

## Testing Contract

### Unit Test Requirements

```dart
group('DashboardHomeService - buildDashboardHomeState', () {
  test('returns correct state with main WiFi networks grouped by band', () {});
  test('returns correct state with guest WiFi when guest radios exist', () {});
  test('returns empty WiFi list when no radios exist', () {});
  test('correctly counts connected devices per band', () {});
  test('sets isAnyNodesOffline true when nodes are offline', () {});
  test('sets isFirstPolling true when lastUpdateTime is zero', () {});
  test('handles null deviceInfo for port layout', () {});
});
```

### Mock Requirements

- Mock `DashboardManagerState` with various radio configurations
- Mock `DeviceManagerState` with various device states
- Mock `getBandForDevice` callback to return predictable bands
