# Research: InstantTopology Service Extraction

**Branch**: `001-instant-topology-service`
**Date**: 2026-01-02

## Research Summary

This document captures research findings for extracting `InstantTopologyService` from `InstantTopologyNotifier`.

---

## 1. Existing Service Pattern Analysis

### Decision: Follow RouterPasswordService pattern

**Rationale**:
- `RouterPasswordService` is the reference implementation cited in constitution Article VI Section 6.6
- It demonstrates proper JNAP error mapping using `mapJnapErrorToServiceError()`
- Uses constructor injection for `RouterRepository`
- Stateless design with Provider-based instantiation

**Alternatives Considered**:
- `HealthCheckService`: Similar pattern but more complex with async operations
- `VPNService`: Uses older patterns, less aligned with current constitution

**Reference File**: `lib/page/instant_admin/services/router_password_service.dart`

---

## 2. Error Mapping Strategy

### Decision: Add 3 new ServiceError types to `service_error.dart`

**New Error Types**:
1. `TopologyTimeoutError` - For wait timeout scenarios
2. `NodeOfflineError` - When target node is unreachable
3. `NodeOperationFailedError` - For reboot/reset/blink failures

**Rationale**:
- Constitution Article XIII requires ServiceError for all data layer errors
- Existing `service_error.dart` uses sealed class pattern
- Specific error types enable precise handling in Provider layer

**Alternatives Considered**:
- Reuse `UnexpectedError`: Rejected - loses error specificity
- Single `TopologyError` with enum: Rejected - doesn't follow existing pattern

**Implementation Pattern**:
```dart
// New errors following existing pattern
final class TopologyTimeoutError extends ServiceError {
  final Duration timeout;
  const TopologyTimeoutError({required this.timeout});
}

final class NodeOfflineError extends ServiceError {
  final String deviceId;
  const NodeOfflineError({required this.deviceId});
}

final class NodeOperationFailedError extends ServiceError {
  final String deviceId;
  final String operation; // 'reboot', 'factoryReset', 'blinkStart', 'blinkStop'
  final Object? originalError;
  const NodeOperationFailedError({
    required this.deviceId,
    required this.operation,
    this.originalError,
  });
}
```

---

## 3. JNAP Actions Analysis

### Decision: Extract 7 JNAP actions to service

| JNAP Action | Current Location | Service Method |
|-------------|------------------|----------------|
| `JNAPAction.reboot` | Line 222 | `rebootNodes()` |
| `JNAPAction.reboot2` | Line 217 | `rebootNodes()` |
| `JNAPAction.factoryReset` | Line 283 | `factoryResetNodes()` |
| `JNAPAction.factoryReset2` | Line 276 | `factoryResetNodes()` |
| `JNAPAction.startBlinkNodeLed` | Line 241 | `startBlinkNodeLED()` |
| `JNAPAction.stopBlinkNodeLed` | Line 252 | `stopBlinkNodeLED()` |
| `JNAPAction.getDevices` | Line 305 | `waitForNodesOffline()` |

**Rationale**:
- All JNAP communication must be in Service layer (Article V Section 5.3)
- Polling logic (`_waitForNodesOffline`) is business logic, stays in Service

---

## 4. Transaction Builder Pattern

### Decision: Move JNAPTransactionBuilder construction to Service

**Current Pattern** (in Provider):
```dart
final builder = JNAPTransactionBuilder(
  commands: deviceUUIDs.reversed
      .map((uuid) => MapEntry(JNAPAction.reboot2, {'deviceUUID': uuid}))
      .toList(),
  auth: true,
);
```

**New Pattern** (in Service):
- Service constructs `JNAPTransactionBuilder` internally
- Provider passes only business parameters (`List<String> deviceUUIDs`)
- Service handles empty list case (master node vs child nodes)

**Rationale**:
- Transaction building is JNAP implementation detail
- Provider should not know about JNAP transaction structure

---

## 5. Polling/Retry Logic

### Decision: Keep polling logic in Service with configurable parameters

**Current Implementation**:
- `maxRetry: 20`
- `retryDelayInMilliSec: 3000`
- Total timeout: 60 seconds

**Service Method Signature**:
```dart
Future<void> waitForNodesOffline(
  List<String> deviceUUIDs, {
  int maxRetry = 20,
  int retryDelayMs = 3000,
});
```

**Rationale**:
- Polling is business logic (not UI state management)
- Configurable parameters enable testing without real delays
- Throws `TopologyTimeoutError` on timeout

---

## 6. SharedPreferences Handling

### Decision: Keep SharedPreferences in Provider for blink tracking

**Current Usage** (in `toggleBlinkNode`):
```dart
final prefs = await SharedPreferences.getInstance();
final blinkDevice = prefs.get(pBlinkingNodeId);
prefs.setString(pBlinkingNodeId, deviceId);
```

**Rationale**:
- Blink tracking is UI state (which node is currently blinking)
- Provider manages UI state; Service handles JNAP only
- Follows constitution Article XII: Provider manages state

**Alternative Considered**:
- Move to Service: Rejected - would mix state management with business logic

---

## 7. Test Data Builder Pattern

### Decision: Create `InstantTopologyTestData` class

**Location**: `test/mocks/test_data/instant_topology_test_data.dart`

**Structure**:
```dart
class InstantTopologyTestData {
  /// Create successful reboot response
  static JNAPSuccess createRebootSuccess() => ...;

  /// Create getDevices response with nodes online/offline
  static JNAPSuccess createGetDevicesResponse({
    required List<String> onlineDeviceIds,
    required List<String> offlineDeviceIds,
  }) => ...;

  /// Create transaction response for multi-node operations
  static JNAPTransactionSuccessWrap createMultiNodeRebootSuccess(
    List<String> deviceUUIDs,
  ) => ...;
}
```

**Rationale**:
- Constitution Article I Section 1.6.2 mandates Test Data Builder pattern
- Centralizes mock JNAP responses for consistent testing

---

## 8. Import Removal Verification

### Decision: Use grep commands from constitution Section 5.3.3

**Post-Implementation Checks**:
```bash
# Should return 0 results after refactor
grep -r "import.*jnap/actions" lib/page/instant_topology/providers/
grep -r "import.*jnap/command" lib/page/instant_topology/providers/
grep -r "import.*jnap/result" lib/page/instant_topology/providers/
grep -r "routerRepositoryProvider" lib/page/instant_topology/providers/

# Should return results (Service has JNAP imports)
grep -r "import.*jnap" lib/page/instant_topology/services/
```

---

## Resolved Clarifications

All technical unknowns have been resolved:

| Unknown | Resolution |
|---------|------------|
| Error type strategy | 3 specific ServiceError subtypes |
| Polling location | Service layer |
| SharedPreferences | Provider layer (UI state) |
| Transaction builder | Service layer (JNAP detail) |
| Test data pattern | InstantTopologyTestData class |
