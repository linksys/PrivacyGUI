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
