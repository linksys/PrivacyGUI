# Research: Device Manager Service Extraction

**Feature**: 001-device-manager-service-extraction
**Date**: 2025-12-28

## Research Summary

This document captures technical decisions and research findings for the DeviceManagerService extraction.

---

## Decision 1: Service Location

**Question**: Where should `DeviceManagerService` be located?

**Decision**: `lib/core/jnap/services/device_manager_service.dart`

**Rationale**:
- `DeviceManagerNotifier` is infrastructure code in `lib/core/jnap/providers/`, not feature-specific
- Following the pattern where related code stays in the same domain (`core/jnap`)
- Creating a new `services/` directory under `core/jnap/` maintains cohesion
- Constitution Article VI Section 6.3 specifies `lib/page/[feature]/services/` for feature code, but this is infrastructure

**Alternatives Considered**:
- `lib/core/services/device_manager_service.dart` - Rejected: Too far from related JNAP code
- `lib/page/components/services/` - Rejected: Not a feature, it's infrastructure

---

## Decision 2: State Class Location

**Question**: Should `DeviceManagerState` move or stay?

**Decision**: Keep in `lib/core/jnap/providers/device_manager_state.dart`

**Rationale**:
- State class is the public API consumed by 10+ feature providers
- Moving it would break all downstream consumers
- Constitution doesn't mandate state class location for infrastructure code
- The state class acts as the "UI model" for this infrastructure provider

**Alternatives Considered**:
- Move to `lib/core/jnap/services/` - Rejected: Would require updating all consumers
- Create new UI model class - Rejected: Over-engineering per Article V Section 5.4

---

## Decision 3: JNAP Model Handling in State

**Question**: `DeviceManagerState` imports JNAP models (e.g., `LinksysDevice`, `RouterRadio`). Is this a violation?

**Decision**: No violation - `DeviceManagerState` is infrastructure, not presentation layer

**Rationale**:
- Constitution Article V Section 5.3 specifically prohibits JNAP models in `lib/page/*/providers/` and `lib/page/*/views/`
- `DeviceManagerState` lives in `lib/core/jnap/providers/` (infrastructure layer)
- The state class effectively IS the application-layer model for device management
- Feature providers watch `deviceManagerProvider` and receive `DeviceManagerState`, not JNAP models

**Verification**:
```bash
# Check that feature providers don't import JNAP models
grep -r "import.*jnap/models" lib/page/*/providers/
# Should not include device_manager_state.dart imports
```

---

## Decision 4: Helper Methods in Notifier

**Question**: Methods like `getSsidConnectedBy()`, `getBandConnectedBy()`, `findParent()` - should they move to Service?

**Decision**: Keep in `DeviceManagerNotifier`

**Rationale**:
- These methods query **cached state**, not JNAP
- They don't make API calls or use RouterRepository
- Moving them to Service would add unnecessary complexity
- Notifier is appropriate for state-derived calculations

**Methods to KEEP in Notifier**:
- `getSsidConnectedBy(LinksysDevice)` - queries radioInfos from state
- `getBandConnectedBy(LinksysDevice)` - queries wirelessConnections from state
- `findParent(String deviceID)` - navigates cached device list
- `isEmptyState()` - simple state check

**Methods to MOVE to Service**:
- `createState()` - JNAP data transformation
- `updateDeviceNameAndIcon()` - JNAP API call
- `deleteDevices()` - JNAP API call
- `deauthClient()` - JNAP API call

---

## Decision 5: Error Handling Strategy

**Question**: What ServiceError types are needed for device operations?

**Decision**: Use existing `UnexpectedError` for most cases; add specific types only if needed

**Rationale**:
- Current code doesn't have specific error handling for device operations
- Device update/delete failures are rare and generic error handling suffices
- Following YAGNI principle - add specific error types when UX requires them

**Error Mapping**:
```dart
ServiceError _mapJnapError(JNAPError error) {
  return switch (error.result) {
    // Add specific mappings only if UX requires differentiated handling
    _ => UnexpectedError(originalError: error, message: error.result),
  };
}
```

---

## Decision 6: Test Data Builder Pattern

**Question**: How to structure test data for the complex polling response?

**Decision**: Create `DeviceManagerTestData` class with factory methods for each JNAP action

**Rationale**:
- Constitution Article I Section 1.6.2 mandates Test Data Builder pattern
- Polling response contains 7 different JNAP action results
- Centralized test data enables consistent testing across Service and Provider tests

**Structure**:
```dart
class DeviceManagerTestData {
  // Individual action responses
  static JNAPSuccess createGetDevicesSuccess({...});
  static JNAPSuccess createGetNetworkConnectionsSuccess({...});
  static JNAPSuccess createGetRadioInfoSuccess({...});
  // ... etc for each action

  // Complete transaction
  static CoreTransactionData createCompletePollingData({...});

  // Error scenarios
  static CoreTransactionData createPartialErrorData({...});
}
```

---

## Decision 7: Provider-Service Dependency Direction

**Question**: How should `DeviceManagerNotifier` access `DeviceManagerService`?

**Decision**: Use `ref.read(deviceManagerServiceProvider)` in methods

**Rationale**:
- Service is stateless, so `ref.read()` is appropriate (not `ref.watch()`)
- Constitution Article XII Section 12.2 shows this pattern
- Service doesn't change, only provides methods

**Pattern**:
```dart
class DeviceManagerNotifier extends Notifier<DeviceManagerState> {
  @override
  DeviceManagerState build() {
    final coreTransactionData = ref.watch(pollingProvider).value;
    final service = ref.read(deviceManagerServiceProvider);
    return service.transformPollingData(coreTransactionData);
  }
}
```

---

## Resolved Research Items

| Item | Status | Decision |
|------|--------|----------|
| Service location | ✅ Resolved | `lib/core/jnap/services/` |
| State class location | ✅ Resolved | Keep in current location |
| JNAP models in state | ✅ Resolved | Allowed for infrastructure |
| Helper methods | ✅ Resolved | Keep state queries in Notifier |
| Error types | ✅ Resolved | Use existing ServiceError types |
| Test data pattern | ✅ Resolved | Test Data Builder pattern |
| Dependency injection | ✅ Resolved | ref.read() for service access |

---

## References

- Constitution Article V: Simplicity and Minimal Structure
- Constitution Article VI: The Service Layer Principle
- Constitution Article XIII: Error Handling Strategy
- Reference Implementation: `lib/page/advanced_settings/firewall/services/firewall_settings_service.dart`
