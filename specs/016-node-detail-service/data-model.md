# Data Model: NodeDetail Service Extraction

**Date**: 2026-01-02
**Feature**: 001-node-detail-service

## Overview

This document defines the data models involved in the NodeDetail service extraction. Since this is a refactoring task, most models already exist. This document clarifies which models belong to which layer and any modifications needed.

## Model Layer Classification

### Data Layer Models (JNAP - lib/core/jnap/models/)

These models are used by the Service layer only. They must NOT appear in Provider or UI layers.

| Model | Location | Usage |
|-------|----------|-------|
| `RawDevice` | `core/jnap/models/device.dart` | Device data from JNAP |
| `DeviceConnectionType` | `core/jnap/models/device.dart` | Enum for connection type |
| `WanStatus` | `core/jnap/providers/device_manager_state.dart` | WAN connection status |
| `NodeLightSettings` | `core/jnap/models/node_light_settings.dart` | Light configuration |

### Application Layer Models (Service/Provider)

#### NodeDetailState (EXISTING - lib/page/nodes/providers/node_detail_state.dart)

UI state model. Already compliant with constitution Article XI (Equatable, toJson/fromJson).

```dart
class NodeDetailState extends Equatable {
  final String deviceId;
  final String location;
  final bool isMaster;
  final bool isOnline;
  final List<DeviceListItem> connectedDevices;
  final String upstreamDevice;
  final bool isWiredConnection;
  final int signalStrength;
  final String serialNumber;
  final String modelNumber;
  final String firmwareVersion;
  final String hardwareVersion;
  final String lanIpAddress;
  final String wanIpAddress;
  final BlinkingStatus blinkingStatus;
  final bool isMLO;
  final String macAddress;
}
```

**Modification Required**: Remove import of `NodeLightSettings` from state file (currently imported but not used in state fields).

#### BlinkingStatus (EXISTING - lib/page/nodes/providers/node_detail_state.dart)

Enum for LED blinking UI states. No changes needed.

```dart
enum BlinkingStatus {
  blinkNode('Blink Node'),
  blinking('Blinking'),
  stopBlinking('Stop Blink');
}
```

#### DeviceListItem (EXISTING - lib/page/instant_device/providers/device_list_state.dart)

UI model for connected devices. Already a UI-layer model, no changes needed.

### Error Models (lib/core/errors/)

#### ServiceError (EXISTING - lib/core/errors/service_error.dart)

Base error type for service layer errors. The existing hierarchy is sufficient for NodeDetail operations.

**Relevant Error Types**:
- `UnauthorizedError` - For auth failures
- `UnexpectedError` - Fallback for unmapped errors

No new error types needed for this feature.

## Data Transformation Flow

```
┌─────────────────────────────────────────────────────────────┐
│  Data Layer (JNAP)                                          │
│  RawDevice, DeviceConnectionType, WanStatus                 │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          │ Service transforms to primitives
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  Service Layer                                              │
│  NodeDetailService.transformDeviceToUIValues()              │
│  Returns: Map<String, dynamic> with UI-ready values         │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          │ Provider creates state
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  Provider Layer                                             │
│  NodeDetailNotifier.createState()                           │
│  Uses: NodeDetailState (UI state model)                     │
└─────────────────────────────────────────────────────────────┘
```

## Field Mapping (RawDevice → NodeDetailState)

| RawDevice Property | NodeDetailState Field | Transformation |
|-------------------|----------------------|----------------|
| `deviceID` | `deviceId` | Direct copy |
| `getDeviceLocation()` | `location` | Method call |
| `isAuthority` comparison | `isMaster` | `device.deviceID == master?.deviceID` |
| `isOnline()` | `isOnline` | Method call |
| `getConnectionType()` | `isWiredConnection` | `== DeviceConnectionType.wired` |
| `signalDecibels` | `signalStrength` | `?? 0` fallback |
| `unit.serialNumber` | `serialNumber` | `?? ''` fallback |
| `model.modelNumber` | `modelNumber` | `?? ''` fallback |
| `unit.firmwareVersion` | `firmwareVersion` | `?? ''` fallback |
| `model.hardwareVersion` | `hardwareVersion` | `?? ''` fallback |
| `connections.firstOrNull?.ipAddress` | `lanIpAddress` | `?? ''` fallback |
| WanStatus.wanConnection?.ipAddress | `wanIpAddress` | `?? ''` fallback |
| `upstream?.getDeviceLocation()` | `upstreamDevice` | With 'INTERNET' for master |
| `connectedDevices` | `connectedDevices` | Transform via deviceListProvider |
| `wirelessConnectionInfo?.isMultiLinkOperation` | `isMLO` | `?? false` fallback |
| `getMacAddress()` | `macAddress` | Method call |

## Entities Summary

| Entity | Layer | Responsibility |
|--------|-------|----------------|
| `NodeDetailService` | Service | JNAP communication, data transformation |
| `NodeDetailNotifier` | Provider | State management, user interaction |
| `NodeDetailState` | Provider | UI state container |
| `BlinkingStatus` | Provider | UI enum for blink states |
| `ServiceError` | Core | Error contract |
