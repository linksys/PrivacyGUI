# Data Model: AddNodesService Extraction

**Feature**: 001-add-nodes-service
**Date**: 2026-01-06

## Entities Overview

This refactoring does not introduce new data models. It restructures how existing models flow between layers.

## Existing Entities (No Changes)

### AddNodesState

**Location**: `lib/page/nodes/providers/add_nodes_state.dart`
**Status**: Architecture-compliant (no changes needed)

| Field | Type | Description |
|-------|------|-------------|
| `onboardingProceed` | `bool?` | Indicates onboarding process started |
| `anyOnboarded` | `bool?` | At least one device was onboarded |
| `nodesSnapshot` | `List<LinksysDevice>?` | Snapshot of nodes before onboarding |
| `addedNodes` | `List<LinksysDevice>?` | Newly onboarded devices |
| `childNodes` | `List<LinksysDevice>?` | All child nodes with backhaul info |
| `isLoading` | `bool` | Loading state indicator |
| `loadingMessage` | `String?` | Current loading phase message |
| `onboardedMACList` | `List<String>?` | MAC addresses of onboarded devices |

### LinksysDevice

**Location**: `lib/core/utils/devices.dart` (re-exported from `device_manager_state.dart`)
**Status**: Architecture-compliant (in `core/utils/`, not `core/jnap/models/`)

Used as the UI model for device representation. Contains:
- Device identification (deviceID, friendlyName)
- Network info (knownInterfaces, connections)
- Node type (Master/Slave)
- Optional backhaul info (wirelessConnectionInfo, connectionType)

## Data Flow Changes

### Before (Violates Architecture)

```
┌─────────────────────────────────────────────────────────────┐
│ AddNodesNotifier                                            │
│                                                             │
│  ┌─────────────────┐    ┌────────────────────────────────┐ │
│  │ RouterRepository│───►│ JNAPResult (raw)               │ │
│  └─────────────────┘    │ BackHaulInfoData (JNAP model)  │ │
│                         │ JNAPSuccess checks in Provider │ │
│                         └────────────────────────────────┘ │
│                                     ↓                       │
│                         ┌────────────────────────────────┐ │
│                         │ AddNodesState                  │ │
│                         └────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
❌ Provider imports: jnap/models, jnap/result, jnap/actions
```

### After (Architecture-Compliant)

```
┌────────────────────────────────────────────────────────────────────┐
│ AddNodesService (NEW)                                              │
│                                                                    │
│  ┌─────────────────┐    ┌────────────────────────────────────────┐│
│  │ RouterRepository│───►│ JNAPResult processing                  ││
│  └─────────────────┘    │ BackHaulInfoData transformation        ││
│                         │ JNAPError → ServiceError mapping       ││
│                         └─────────────────┬──────────────────────┘│
└───────────────────────────────────────────┼────────────────────────┘
                                            │ Returns:
                                            │ - Stream<Map<String,dynamic>>
                                            │ - Stream<List<LinksysDevice>>
                                            │ - bool, void
                                            ↓
┌────────────────────────────────────────────────────────────────────┐
│ AddNodesNotifier (REFACTORED)                                      │
│                                                                    │
│  ┌─────────────────┐    ┌────────────────────────────────────────┐│
│  │ AddNodesService │───►│ UI-friendly data only                  ││
│  └─────────────────┘    │ No JNAP model imports                  ││
│                         │ ServiceError handling only             ││
│                         └─────────────────┬──────────────────────┘│
│                                           ↓                        │
│                         ┌────────────────────────────────────────┐│
│                         │ AddNodesState (unchanged)              ││
│                         └────────────────────────────────────────┘│
└────────────────────────────────────────────────────────────────────┘
✅ Provider imports: Only core/utils, core/errors/service_error
```

## Service Method Signatures

### AddNodesService

```dart
class AddNodesService {
  final RouterRepository _routerRepository;

  AddNodesService(this._routerRepository);

  /// Enable Bluetooth auto-onboarding
  Future<void> setAutoOnboardingSettings();

  /// Check if auto-onboarding is enabled
  Future<bool> getAutoOnboardingSettings();

  /// Poll auto-onboarding status until Idle or Complete
  /// Returns stream of status maps: {status, deviceOnboardingStatus}
  Stream<Map<String, dynamic>> pollAutoOnboardingStatus({bool oneTake = false});

  /// Start Bluetooth auto-onboarding process
  Future<void> startBluetoothAutoOnboarding();

  /// Poll for nodes coming online after onboarding
  /// Returns stream of device lists
  Stream<List<LinksysDevice>> pollForNodesOnline(
    List<String> onboardedMACList, {
    bool refreshing = false,
  });

  /// Poll for backhaul info and merge into devices
  /// Returns stream of enriched device lists
  Stream<List<LinksysDevice>> pollNodesBackhaulInfo(
    List<LinksysDevice> nodes, {
    bool refreshing = false,
  });
}
```

## Validation Rules

| Rule | Enforcement |
|------|-------------|
| Provider no JNAP imports | grep check in CI |
| Service throws ServiceError only | Code review |
| LinksysDevice from core/utils only | Import path check |

## State Transitions

No changes to state transitions. AddNodesState lifecycle remains unchanged.

---

## Scope Extension: AddWiredNodesService (2026-01-07)

### New Entity: BackhaulInfoUIModel

**Location**: `lib/page/nodes/models/backhaul_info_ui_model.dart`
**Status**: NEW - Required for architecture compliance

| Field | Type | Description |
|-------|------|-------------|
| `deviceUUID` | `String` | Unique identifier for the device |
| `connectionType` | `String` | Connection type (e.g., "Wired", "Wireless") |
| `timestamp` | `String` | ISO 8601 timestamp of the connection |

**Implementation Requirements**:
- Extends `Equatable`
- Provides `toMap()` / `fromMap()` methods
- Provides `toJson()` / `fromJson()` methods
- Factory constructor `fromJnap(BackHaulInfoData data)` for Service layer use only

```dart
class BackhaulInfoUIModel extends Equatable {
  final String deviceUUID;
  final String connectionType;
  final String timestamp;

  const BackhaulInfoUIModel({
    required this.deviceUUID,
    required this.connectionType,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [deviceUUID, connectionType, timestamp];

  Map<String, dynamic> toMap() => {
    'deviceUUID': deviceUUID,
    'connectionType': connectionType,
    'timestamp': timestamp,
  };

  factory BackhaulInfoUIModel.fromMap(Map<String, dynamic> map) => BackhaulInfoUIModel(
    deviceUUID: map['deviceUUID'] ?? '',
    connectionType: map['connectionType'] ?? '',
    timestamp: map['timestamp'] ?? '',
  );

  String toJson() => json.encode(toMap());
  factory BackhaulInfoUIModel.fromJson(String source) => BackhaulInfoUIModel.fromMap(json.decode(source));
}
```

---

### New Entity: BackhaulPollResult

**Location**: `lib/page/nodes/models/backhaul_poll_result.dart` (or inline in service file)
**Status**: NEW - Used by pollBackhaulChanges() stream

| Field | Type | Description |
|-------|------|-------------|
| `backhaulList` | `List<BackhaulInfoUIModel>` | Current backhaul entries |
| `foundCounting` | `int` | Number of new nodes detected |
| `anyOnboarded` | `bool` | Whether any new node was onboarded |

```dart
class BackhaulPollResult {
  final List<BackhaulInfoUIModel> backhaulList;
  final int foundCounting;
  final bool anyOnboarded;

  const BackhaulPollResult({
    required this.backhaulList,
    required this.foundCounting,
    required this.anyOnboarded,
  });
}
```

---

### Modified Entity: AddWiredNodesState

**Location**: `lib/page/nodes/providers/add_wired_nodes_state.dart`
**Status**: MODIFY - Replace BackHaulInfoData with BackhaulInfoUIModel

| Field | Type | Before | After |
|-------|------|--------|-------|
| `backhaulSnapshot` | List type | `List<BackHaulInfoData>?` | `List<BackhaulInfoUIModel>?` |

Other fields remain unchanged:
- `isLoading` (bool)
- `forceStop` (bool)
- `loadingMessage` (String?)
- `onboardingProceed` (bool?)
- `anyOnboarded` (bool?)
- `nodes` (List<LinksysDevice>?)

---

### AddWiredNodesService Method Signatures

**Location**: `lib/page/nodes/services/add_wired_nodes_service.dart`

```dart
class AddWiredNodesService {
  final RouterRepository _routerRepository;

  AddWiredNodesService(this._routerRepository);

  /// Enable or disable wired auto-onboarding
  /// Sends JNAPAction.setWiredAutoOnboardingSettings
  Future<void> setAutoOnboardingEnabled(bool enabled);

  /// Check if wired auto-onboarding is enabled
  /// Sends JNAPAction.getWiredAutoOnboardingSettings
  Future<bool> getAutoOnboardingEnabled();

  /// Poll for backhaul changes compared to snapshot
  /// Sends JNAPAction.getBackhaulInfo repeatedly
  /// Returns stream of BackhaulPollResult with found counting
  Stream<BackhaulPollResult> pollBackhaulChanges(
    List<BackhaulInfoUIModel> snapshot, {
    bool refreshing = false,
  });

  /// Fetch all node devices
  /// Sends JNAPAction.getDevices
  Future<List<LinksysDevice>> fetchNodes();
}
```

---

### Data Flow: AddWiredNodesService

```
┌────────────────────────────────────────────────────────────────────┐
│ AddWiredNodesService (NEW)                                         │
│                                                                    │
│  ┌─────────────────┐    ┌────────────────────────────────────────┐│
│  │ RouterRepository│───►│ JNAPResult processing                  ││
│  └─────────────────┘    │ BackHaulInfoData → BackhaulInfoUIModel ││
│                         │ DateFormat timestamp comparison        ││
│                         │ JNAPError → ServiceError mapping       ││
│                         └─────────────────┬──────────────────────┘│
└───────────────────────────────────────────┼────────────────────────┘
                                            │ Returns:
                                            │ - void (setAutoOnboardingEnabled)
                                            │ - bool (getAutoOnboardingEnabled)
                                            │ - Stream<BackhaulPollResult>
                                            │ - List<LinksysDevice>
                                            ↓
┌────────────────────────────────────────────────────────────────────┐
│ AddWiredNodesNotifier (REFACTORED)                                 │
│                                                                    │
│  ┌──────────────────────┐    ┌─────────────────────────────────┐  │
│  │ AddWiredNodesService │───►│ UI-friendly data only           │  │
│  └──────────────────────┘    │ No JNAP model imports           │  │
│                              │ ServiceError handling only      │  │
│                              └─────────────────┬───────────────┘  │
│                                                ↓                   │
│                              ┌─────────────────────────────────┐  │
│                              │ AddWiredNodesState              │  │
│                              │ - backhaulSnapshot: List<BackhaulInfoUIModel>│
│                              └─────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────┘
✅ Provider imports: Only core/utils, core/errors/service_error, nodes/models
```

---

### Validation Rules (Extended)

| Rule | Enforcement |
|------|-------------|
| AddWiredNodesNotifier no JNAP imports | grep check: `grep -r "jnap/models\|jnap/result\|jnap/actions" lib/page/nodes/providers/add_wired*` |
| AddWiredNodesState no JNAP imports | grep check: same pattern |
| Service throws ServiceError only | Code review |
| BackhaulInfoUIModel implements Equatable | Test coverage |
| BackhaulInfoUIModel has toMap/fromMap | Test coverage |
