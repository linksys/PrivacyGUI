# NodeDetailService Contract

**Date**: 2026-01-02
**Feature**: 001-node-detail-service
**Reference**: constitution.md Article IX (Contract Documentation)

## Overview

This document defines the API contract for `NodeDetailService`. The Service encapsulates JNAP communication for node detail operations and provides transformation helpers for device data.

## Provider Definition

```dart
/// Riverpod provider for NodeDetailService
final nodeDetailServiceProvider = Provider<NodeDetailService>((ref) {
  return NodeDetailService(ref.watch(routerRepositoryProvider));
});
```

## Class Definition

```dart
/// Stateless service for node detail operations
///
/// Encapsulates JNAP communication for LED blinking and provides
/// transformation helpers for converting device data to UI values.
class NodeDetailService {
  /// Constructor injection of RouterRepository dependency
  NodeDetailService(RouterRepository routerRepository);
}
```

## Methods

### startBlinkNodeLED

Starts LED blinking on the specified node device.

**Signature**:
```dart
Future<void> startBlinkNodeLED(String deviceId);
```

**Parameters**:
| Name | Type | Description |
|------|------|-------------|
| `deviceId` | `String` | The device ID of the node to blink |

**Returns**: `Future<void>` - Completes on success

**Throws**:
| Error Type | Condition |
|------------|-----------|
| `UnauthorizedError` | Authentication failed |
| `UnexpectedError` | JNAP communication failure |

**JNAP Action**: `startBlinkNodeLed`

**Example**:
```dart
final service = ref.read(nodeDetailServiceProvider);
try {
  await service.startBlinkNodeLED('device-uuid-123');
} on ServiceError catch (e) {
  // Handle error
}
```

---

### stopBlinkNodeLED

Stops LED blinking on the node.

**Signature**:
```dart
Future<void> stopBlinkNodeLED();
```

**Parameters**: None

**Returns**: `Future<void>` - Completes on success

**Throws**:
| Error Type | Condition |
|------------|-----------|
| `UnauthorizedError` | Authentication failed |
| `UnexpectedError` | JNAP communication failure |

**JNAP Action**: `stopBlinkNodeLed`

**Example**:
```dart
final service = ref.read(nodeDetailServiceProvider);
try {
  await service.stopBlinkNodeLED();
} on ServiceError catch (e) {
  // Handle error
}
```

---

### transformDeviceToUIValues

Transforms a device's JNAP model data into UI-appropriate primitive values.

**Signature**:
```dart
Map<String, dynamic> transformDeviceToUIValues({
  required RawDevice device,
  required RawDevice? masterDevice,
  required WanStatus? wanStatus,
});
```

**Parameters**:
| Name | Type | Description |
|------|------|-------------|
| `device` | `RawDevice` | The device to transform |
| `masterDevice` | `RawDevice?` | The master/authority node (for isMaster comparison) |
| `wanStatus` | `WanStatus?` | WAN status model (for WAN IP) |

**Returns**: `Map<String, dynamic>` with keys:

| Key | Type | Description |
|-----|------|-------------|
| `location` | `String` | Device location name |
| `isMaster` | `bool` | Whether device is the master node |
| `isOnline` | `bool` | Whether device is online |
| `isWiredConnection` | `bool` | Whether device is wired |
| `signalStrength` | `int` | Signal strength in dB (0 if wired) |
| `serialNumber` | `String` | Device serial number |
| `modelNumber` | `String` | Device model number |
| `firmwareVersion` | `String` | Current firmware version |
| `hardwareVersion` | `String` | Hardware version |
| `lanIpAddress` | `String` | LAN IP address |
| `wanIpAddress` | `String` | WAN IP address (master only) |
| `upstreamDevice` | `String` | Upstream device location or 'INTERNET' |
| `isMLO` | `bool` | Whether using Multi-Link Operation |
| `macAddress` | `String` | Device MAC address |

**Example**:
```dart
final service = ref.read(nodeDetailServiceProvider);
final values = service.transformDeviceToUIValues(
  device: rawDevice,
  masterDevice: master,
  wanStatus: wanStatus,
);
final state = NodeDetailState(
  location: values['location'] as String,
  isMaster: values['isMaster'] as bool,
  // ... other fields
);
```

---

### transformConnectedDevices

Transforms connected device list from JNAP model to UI model.

**Signature**:
```dart
List<DeviceListItem> transformConnectedDevices({
  required List<RawDevice> devices,
  required DeviceListNotifier deviceListNotifier,
});
```

**Parameters**:
| Name | Type | Description |
|------|------|-------------|
| `devices` | `List<RawDevice>` | Connected devices from JNAP |
| `deviceListNotifier` | `DeviceListNotifier` | Notifier for creating DeviceListItem |

**Returns**: `List<DeviceListItem>` - UI-ready device list

**Note**: This method delegates to `DeviceListNotifier.createItem()` for each device, maintaining existing transformation logic.

## Error Handling

All JNAP errors are mapped to `ServiceError` subtypes using `mapJnapErrorToServiceError()`:

```dart
try {
  await _routerRepository.send(...);
} on JNAPError catch (e) {
  throw mapJnapErrorToServiceError(e);
}
```

## Dependencies

| Dependency | Injected Via | Purpose |
|------------|--------------|---------|
| `RouterRepository` | Constructor | JNAP communication |

## Usage in Provider

```dart
class NodeDetailNotifier extends Notifier<NodeDetailState> {
  NodeDetailState createState(DeviceManagerState deviceManagerState, String targetId) {
    final service = ref.read(nodeDetailServiceProvider);

    // Find target device and master
    final device = deviceManagerState.deviceList.firstWhereOrNull(
      (d) => d.deviceID == targetId,
    );
    final master = deviceManagerState.deviceList.firstWhereOrNull(
      (d) => d.isAuthority,
    );

    if (device == null) return const NodeDetailState();

    // Use service for transformation
    final values = service.transformDeviceToUIValues(
      device: device,
      masterDevice: master,
      wanStatus: deviceManagerState.wanStatus,
    );

    final connectedDevices = service.transformConnectedDevices(
      devices: device.connectedDevices,
      deviceListNotifier: ref.read(deviceListProvider.notifier),
    );

    return NodeDetailState(
      deviceId: targetId,
      location: values['location'] as String,
      // ... other fields from values map
      connectedDevices: connectedDevices,
    );
  }

  Future<void> toggleBlinkNode([bool stopOnly = false]) async {
    final service = ref.read(nodeDetailServiceProvider);
    try {
      if (!stopOnly && blinkDevice == null) {
        await service.startBlinkNodeLED(deviceId);
        // ... handle success
      } else {
        await service.stopBlinkNodeLED();
        // ... handle success
      }
    } on ServiceError catch (e) {
      // Handle error, update state
    }
  }
}
```
