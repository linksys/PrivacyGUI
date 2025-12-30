# Contract: DeviceManagerService

**Feature**: 001-device-manager-service-extraction
**Date**: 2025-12-28
**Location**: `lib/core/jnap/services/device_manager_service.dart`

## Overview

`DeviceManagerService` encapsulates all JNAP communication and data transformation logic for device management. It receives raw JNAP responses and returns `DeviceManagerState`.

## Provider Definition

```dart
final deviceManagerServiceProvider = Provider<DeviceManagerService>((ref) {
  return DeviceManagerService(ref.watch(routerRepositoryProvider));
});
```

## Class Contract

```dart
/// Service for device management operations.
///
/// Handles JNAP communication and transforms raw API responses
/// into DeviceManagerState. This isolates JNAP protocol details
/// from the DeviceManagerNotifier.
class DeviceManagerService {
  final RouterRepository _routerRepository;

  DeviceManagerService(this._routerRepository);

  // === Data Transformation ===

  /// Transforms polling data into DeviceManagerState.
  ///
  /// [pollingResult] - Raw JNAP transaction data from pollingProvider.
  ///                   Can be null during initial load.
  ///
  /// Returns: Complete DeviceManagerState with all device information.
  ///
  /// Behavior:
  /// - If [pollingResult] is null, returns empty default state
  /// - Processes all available JNAP action results
  /// - Skips failed actions gracefully (partial state)
  /// - Never throws - always returns valid state
  DeviceManagerState transformPollingData(CoreTransactionData? pollingResult);

  // === Write Operations ===

  /// Updates device name and/or icon.
  ///
  /// [targetId] - Device ID to update
  /// [newName] - New display name for the device
  /// [isLocation] - If true, also updates userDeviceLocation
  /// [icon] - Optional icon category to set
  ///
  /// Returns: List of updated device properties
  ///
  /// Throws: [ServiceError] on JNAP failure
  Future<List<RawDeviceProperty>> updateDeviceNameAndIcon({
    required String targetId,
    required String newName,
    required bool isLocation,
    IconDeviceCategory? icon,
  });

  /// Deletes devices from the network.
  ///
  /// [deviceIds] - List of device IDs to delete
  ///
  /// Returns: Map of deviceId → success/failure status
  ///
  /// Behavior:
  /// - Empty list returns empty map immediately (no-op)
  /// - Processes deletions in bulk
  /// - Partial failures are reflected in return map
  ///
  /// Throws: [ServiceError] only on complete failure
  Future<Map<String, bool>> deleteDevices(List<String> deviceIds);

  /// Deauthenticates a client device.
  ///
  /// [macAddress] - MAC address of device to disconnect
  ///
  /// Throws: [ServiceError] on JNAP failure
  Future<void> deauthClient(String macAddress);
}
```

## Method Details

### transformPollingData

**Input**: `CoreTransactionData?`
```dart
// CoreTransactionData contains:
final Map<JNAPAction, JNAPResult>? data;
final int? lastUpdate;
```

**Output**: `DeviceManagerState`

**JNAP Actions Consumed**:
| Action | Field Updated |
|--------|--------------|
| `getNetworkConnections` | wirelessConnections |
| `getNodesWirelessNetworkConnections` | wirelessConnections (mesh) |
| `getRadioInfo` | radioInfos |
| `getGuestRadioSettings` | guestRadioSettings |
| `getDevices` | deviceList |
| `getWANStatus` | wanStatus |
| `getBackhaulInfo` | backhaulInfoData |

**Processing Order** (important):
1. Extract wireless connections (needed for device processing)
2. Build device list with wireless info
3. Process WAN status
4. Process backhaul info (updates device IPs and signal)
5. Check upstream relationships

### updateDeviceNameAndIcon

**JNAP Actions**:
1. `setDeviceProperties` - Set name/location/icon
2. `getDevices` - Refresh device list after update

**Error Mapping**:
```dart
// JNAP errors → ServiceError
'OK' → success
_ → UnexpectedError(originalError: jnapError)
```

### deleteDevices

**JNAP Actions**:
- Uses `RouterRepository.deleteDevices()` for bulk operation

**Return Value**:
```dart
{
  'device-id-1': true,   // deleted successfully
  'device-id-2': false,  // deletion failed
}
```

### deauthClient

**JNAP Actions**:
- `clientDeauth` with `macAddress` parameter

## Usage Example

```dart
// In DeviceManagerNotifier
class DeviceManagerNotifier extends Notifier<DeviceManagerState> {
  @override
  DeviceManagerState build() {
    final coreTransactionData = ref.watch(pollingProvider).value;
    final service = ref.read(deviceManagerServiceProvider);
    return service.transformPollingData(coreTransactionData);
  }

  Future<void> updateDeviceNameAndIcon({
    required String targetId,
    required String newName,
    required bool isLocation,
    IconDeviceCategory? icon,
  }) async {
    final service = ref.read(deviceManagerServiceProvider);
    try {
      final updatedProps = await service.updateDeviceNameAndIcon(
        targetId: targetId,
        newName: newName,
        isLocation: isLocation,
        icon: icon,
      );
      // Update local state
      _updateDeviceInState(targetId, updatedProps);
    } on ServiceError catch (e) {
      // Handle error appropriately
      logger.e('Failed to update device', error: e);
      rethrow;
    }
  }
}
```

## Dependencies

**Required Imports** (Service only):
```dart
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/back_haul_info.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/layer2_connection.dart';
import 'package:privacy_gui/core/jnap/models/node_wireless_connection.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart';
import 'package:privacy_gui/core/jnap/models/wirless_connection.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
```

**Prohibited Imports** (Notifier):
```dart
// ❌ None of the above should appear in device_manager_provider.dart
```
