# Data Model: InstantTopology Service Extraction

**Branch**: `001-instant-topology-service`
**Date**: 2026-01-02

## Overview

This refactor does not introduce new domain models. It extracts existing JNAP communication logic and adds ServiceError subtypes. The existing `TopologyModel`, `InstantTopologyState`, and tree node classes remain unchanged.

---

## New ServiceError Types

### Location: `lib/core/errors/service_error.dart`

```dart
// ============================================================================
// Topology Operation Errors
// ============================================================================

/// Timeout while waiting for nodes to go offline after reboot/factory reset.
///
/// Thrown when nodes don't reach offline state within the configured timeout
/// (default: 60 seconds = 20 retries × 3 second intervals).
final class TopologyTimeoutError extends ServiceError {
  /// The timeout duration that was exceeded
  final Duration timeout;

  /// Device IDs that were being monitored
  final List<String> deviceIds;

  const TopologyTimeoutError({
    required this.timeout,
    required this.deviceIds,
  });
}

/// Target node is offline and cannot be reached for the requested operation.
///
/// Thrown when attempting LED blink or other operations on an offline node.
final class NodeOfflineError extends ServiceError {
  /// The device ID of the offline node
  final String deviceId;

  const NodeOfflineError({required this.deviceId});
}

/// A node operation (reboot, factory reset, LED blink) failed.
///
/// Contains details about which operation failed and on which device.
final class NodeOperationFailedError extends ServiceError {
  /// The device ID where the operation failed
  final String deviceId;

  /// The operation that failed: 'reboot', 'factoryReset', 'blinkStart', 'blinkStop'
  final String operation;

  /// The underlying error (if available)
  final Object? originalError;

  const NodeOperationFailedError({
    required this.deviceId,
    required this.operation,
    this.originalError,
  });
}
```

---

## Existing Models (Unchanged)

### TopologyModel
**Location**: `lib/page/instant_topology/models/topology_model.dart`

No changes required. Already used for UI representation.

### InstantTopologyState
**Location**: `lib/page/instant_topology/providers/instant_topology_state.dart`

No changes required. State management remains in Provider.

### RouterTreeNode hierarchy
**Location**: `lib/page/instant_topology/models/`

No changes required. Tree structure is UI model, not JNAP model.

---

## Entity Relationships

```
┌─────────────────────────────────────────────────────────────────┐
│                        Provider Layer                            │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  InstantTopologyNotifier                                 │    │
│  │  - Manages: InstantTopologyState                        │    │
│  │  - Uses: TopologyModel, RouterTreeNode                  │    │
│  │  - Delegates to: InstantTopologyService                 │    │
│  │  - Catches: ServiceError subtypes                       │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ calls
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Service Layer                             │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  InstantTopologyService                                  │    │
│  │  - Dependencies: RouterRepository                       │    │
│  │  - Returns: void (operations are side-effects)          │    │
│  │  - Throws: TopologyTimeoutError, NodeOfflineError,      │    │
│  │            NodeOperationFailedError, UnexpectedError    │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ uses
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Data Layer                               │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  RouterRepository                                        │    │
│  │  - JNAP Actions: reboot, reboot2, factoryReset,         │    │
│  │    factoryReset2, startBlinkNodeLed, stopBlinkNodeLed,  │    │
│  │    getDevices                                            │    │
│  │  - Returns: JNAPResult, JNAPSuccess, JNAPError          │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

---

## Data Flow

### Reboot Operation

```
User Action → Provider.reboot(deviceUUIDs)
                    │
                    ▼
           Service.rebootNodes(deviceUUIDs)
                    │
                    ├─► Empty list? → RouterRepository.send(JNAPAction.reboot)
                    │
                    └─► Has UUIDs? → RouterRepository.transaction(reboot2 commands)
                                           │
                                           ▼
                                   Service.waitForNodesOffline(deviceUUIDs)
                                           │
                                           ├─► Success → return
                                           │
                                           └─► Timeout → throw TopologyTimeoutError
```

### LED Blink Operation

```
User Action → Provider.toggleBlinkNode(deviceId)
                    │
                    ├─► Check SharedPreferences for current blink
                    │
                    ├─► If different node blinking → Service.stopBlinkNodeLED()
                    │
                    └─► Service.startBlinkNodeLED(deviceId)
                              │
                              ▼
                    RouterRepository.send(JNAPAction.startBlinkNodeLed)
                              │
                              ├─► Success → Update SharedPreferences
                              │
                              └─► Failure → throw NodeOperationFailedError
```

---

## Validation Rules

| Field | Rule |
|-------|------|
| `deviceUUIDs` | Non-null list; empty means master node operation |
| `deviceId` | Non-empty string for LED operations |
| `timeout` | Must be positive Duration |
| `operation` | One of: 'reboot', 'factoryReset', 'blinkStart', 'blinkStop' |
