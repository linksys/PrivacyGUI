# Data Model: Device Manager Service Extraction

**Feature**: 001-device-manager-service-extraction
**Date**: 2025-12-28

## Overview

This feature extracts JNAP logic from `DeviceManagerNotifier` to `DeviceManagerService`. No new data models are created - existing models are preserved.

## Existing Entities (No Changes)

### DeviceManagerState

**Location**: `lib/core/jnap/providers/device_manager_state.dart`
**Status**: UNCHANGED - continues to be the public API

```dart
class DeviceManagerState extends Equatable {
  final Map<String, WirelessConnection> wirelessConnections;
  final Map<String, RouterRadio> radioInfos;
  final GuestRadioSettings? guestRadioSettings;
  final List<LinksysDevice> deviceList;
  final RouterWANStatus? wanStatus;
  final List<BackHaulInfoData> backhaulInfoData;
  final int lastUpdateTime;

  // Computed properties
  List<LinksysDevice> get nodeDevices;
  List<LinksysDevice> get externalDevices;
  List<LinksysDevice> get mainWifiDevices;
  List<LinksysDevice> get guestWifiDevices;
  LinksysDevice get masterDevice;
  List<LinksysDevice> get slaveDevices;
}
```

### LinksysDevice

**Location**: `lib/core/jnap/providers/device_manager_state.dart`
**Status**: UNCHANGED

```dart
class LinksysDevice extends RawDevice {
  final List<LinksysDevice> connectedDevices;
  final WifiConnectionType connectedWifiType;
  final int? signalDecibels;
  final LinksysDevice? upstream;
  final String connectionType;
  final WirelessConnectionInfo? wirelessConnectionInfo;
  final String speedMbps;
  final List<String> mloList;
}
```

## JNAP Models Used (Service Layer Only)

These models are imported ONLY in `DeviceManagerService`, NOT in the provider:

| Model | JNAP Action | Purpose |
|-------|-------------|---------|
| `Layer2Connection` | getNetworkConnections | Network connection data |
| `NodeWirelessConnections` | getNodesWirelessNetworkConnections | Mesh node connections |
| `RouterRadio` | getRadioInfo | Radio settings |
| `GuestRadioSettings` | getGuestRadioSettings | Guest network settings |
| `RawDevice` | getDevices | Device list from router |
| `RouterWANStatus` | getWANStatus | WAN connection status |
| `BackHaulInfoData` | getBackhaulInfo | Mesh backhaul info |
| `WirelessConnection` | (derived) | Connection details |

## Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    pollingProvider                          │
│              (CoreTransactionData)                          │
└─────────────────────┬───────────────────────────────────────┘
                      │ Raw JNAP responses
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                DeviceManagerService                         │
│  transformPollingData(CoreTransactionData?) →               │
│                                                             │
│  Imports: jnap/models/*, jnap/result/*                      │
│  Transforms: JNAP models → DeviceManagerState               │
└─────────────────────┬───────────────────────────────────────┘
                      │ DeviceManagerState
                      ▼
┌─────────────────────────────────────────────────────────────┐
│               DeviceManagerNotifier                         │
│                                                             │
│  NO imports from jnap/models/ or jnap/result/               │
│  Delegates all JNAP ops to Service                          │
└─────────────────────┬───────────────────────────────────────┘
                      │ DeviceManagerState
                      ▼
┌─────────────────────────────────────────────────────────────┐
│              Feature Providers                              │
│  (device_filtered_list_provider, etc.)                      │
│                                                             │
│  ref.watch(deviceManagerProvider)                           │
└─────────────────────────────────────────────────────────────┘
```

## Entity Relationships

```
DeviceManagerState
├── deviceList: List<LinksysDevice>
│   ├── nodeDevices (computed)
│   └── externalDevices (computed)
├── wirelessConnections: Map<String, WirelessConnection>
├── radioInfos: Map<String, RouterRadio>
├── guestRadioSettings: GuestRadioSettings?
├── wanStatus: RouterWANStatus?
└── backhaulInfoData: List<BackHaulInfoData>

LinksysDevice
├── connectedDevices: List<LinksysDevice>  (nested for nodes)
├── upstream: LinksysDevice?               (parent reference)
└── [inherited from RawDevice]
```

## Validation Rules

| Field | Rule | Enforced In |
|-------|------|-------------|
| deviceList | Can be empty (factory default) | Service |
| wirelessConnections | Can be empty | Service |
| radioInfos | Can be empty | Service |
| lastUpdateTime | Defaults to 0 | State constructor |

## State Transitions

This is a **reactive state** driven by polling. No explicit state machine.

| Trigger | State Change |
|---------|--------------|
| Polling data received | Full state replacement via `transformPollingData()` |
| Device name updated | Partial update to `deviceList` |
| Device deleted | Remove from `deviceList` |
| Client deauthenticated | Triggers polling refresh |
