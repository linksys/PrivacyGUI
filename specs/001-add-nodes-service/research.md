# Research: AddNodesService Extraction

**Feature**: 001-add-nodes-service
**Date**: 2026-01-06

## Research Questions

### 1. Service Layer Pattern for Stream-Based Operations

**Question**: How should AddNodesService handle stream-based polling operations (pollAutoOnboardingStatus, pollForNodesOnline, pollNodesBackhaulInfo)?

**Decision**: Service returns `Stream<T>` directly, mirroring RouterRepository's `scheduledCommand()` pattern.

**Rationale**:
- RouterRepository.scheduledCommand() already returns Stream<JNAPResult>
- Service transforms the stream using StreamTransformer (pattern already in use)
- Provider consumes stream via `await for` loops (existing pattern works)
- No need for additional abstraction; direct delegation maintains simplicity

**Alternatives Considered**:
- Callback-based polling: Rejected - less idiomatic in Dart, harder to test
- Future-based with internal polling loop: Rejected - loses stream semantics
- Rx streams (rxdart): Rejected - adds dependency, standard Stream sufficient

**Reference**: Existing pattern in `add_nodes_provider.dart` lines 163-223

---

### 2. Error Mapping Strategy for AddNodes Operations

**Question**: Which ServiceError types should AddNodesService use for JNAP errors?

**Decision**: Use existing ServiceError types; no new error types needed.

**Rationale**:
- Current add_nodes operations don't have domain-specific error conditions
- JNAP errors during auto-onboarding are general communication failures
- Existing `UnexpectedError`, `NetworkError` cover the use cases

**Error Mapping**:
| JNAP Error | ServiceError | Context |
|------------|--------------|---------|
| Network timeout | `NetworkError` | Polling fails to reach router |
| Generic JNAP error | `UnexpectedError` | Unexpected response |
| Auth failure | `UnauthorizedError` | Session expired during polling |

**Reference**: `lib/core/errors/service_error.dart` already has all needed types

---

### 3. UI Model for AutoOnboardingStatus

**Question**: Should we create a dedicated UI model for auto-onboarding status, or use primitive types?

**Decision**: No new UI model needed; use Map<String, dynamic> or named parameters.

**Rationale**:
- AutoOnboarding status is transient (used only during polling)
- Status values (Idle, Onboarding, Complete) are simple strings
- deviceOnboardingStatus is a list of maps passed through unchanged
- Per constitution §5.3.4: "State directly holds basic types" when data is flat

**Data Shape Returned by Service**:
```dart
// From pollAutoOnboardingStatus()
{
  'status': 'Onboarding' | 'Idle' | 'Complete',
  'deviceOnboardingStatus': List<Map<String, dynamic>>, // pass-through
}
```

**Alternative Considered**:
- Creating AutoOnboardingStatusUIModel: Rejected - over-engineering for transient polling data

---

### 4. LinksysDevice Model Location Clarification

**Question**: Is LinksysDevice from `core/utils/devices.dart` acceptable for Provider layer?

**Decision**: Yes, LinksysDevice is architecture-compliant.

**Rationale**:
- LinksysDevice resides in `core/utils/` not `core/jnap/models/`
- It's a utility/UI model, not a raw JNAP data model
- Clarified in spec session 2026-01-06

**Import Path**: `package:privacy_gui/core/data/providers/device_manager_state.dart`
(re-exports LinksysDevice from core/utils/devices.dart)

---

### 5. BackHaulInfoData Transformation

**Question**: How should backhaul info be transformed for Provider consumption?

**Decision**: Service extracts relevant fields; Provider receives LinksysDevice with enriched data.

**Rationale**:
- BackHaulInfoData is from `core/jnap/models/` - must not leak to Provider
- Current code merges backhaul info into LinksysDevice via `copyWith()`
- Service will perform this merge and return enriched LinksysDevice list

**Transformation Flow**:
```
JNAP backhaulDevices → BackHaulInfoData.fromMap() → Merge with LinksysDevice → Return List<LinksysDevice>
```

**Reference**: Existing pattern in `collectChildNodeData()` method

---

### 6. Service Provider Dependency Injection

**Question**: How should AddNodesService be provided to AddNodesNotifier?

**Decision**: Use standard Riverpod Provider pattern with constructor injection.

**Pattern**:
```dart
final addNodesServiceProvider = Provider<AddNodesService>((ref) {
  return AddNodesService(ref.watch(routerRepositoryProvider));
});
```

**In Notifier**:
```dart
class AddNodesNotifier extends AutoDisposeNotifier<AddNodesState> {
  AddNodesService get _service => ref.read(addNodesServiceProvider);
  // ...
}
```

**Reference**: `lib/page/instant_admin/services/router_password_service.dart` lines 14-19

---

## Best Practices Applied

### From Reference Implementation (router_password_service.dart)

1. **DartDoc comments** on public methods with parameter descriptions
2. **Throws documentation** specifying ServiceError types
3. **Try-catch with JNAPError** converted via `mapJnapErrorToServiceError()`
4. **Return Maps** for simple multi-value responses (no over-abstraction)
5. **Stateless service** - no instance variables except injected dependencies

### From Constitution

1. **Article VI §6.2**: Service handles JNAP, returns UI models, is stateless
2. **Article XIII §13.3**: Catch JNAPError, throw ServiceError
3. **Article I §1.6.2**: Test data builders in `test/mocks/test_data/`

---

## Scope Extension: AddWiredNodesService (2026-01-07)

### 7. BackhaulInfoUIModel Design

**Question**: How should `BackHaulInfoData` be replaced in AddWiredNodesState?

**Decision**: Create `BackhaulInfoUIModel` as a dedicated UI model in `lib/page/nodes/models/`.

**Rationale**:
- State currently uses `List<BackHaulInfoData>` which violates architecture (JNAP model in State)
- Per constitution §5.3.1: separate models per layer
- UI model only needs fields actually used by Provider/State

**Fields required** (from `add_wired_nodes_state.dart` and `add_wired_nodes_provider.dart` usage):
```dart
class BackhaulInfoUIModel extends Equatable {
  final String deviceUUID;
  final String connectionType;
  final String timestamp;

  // Factory from JNAP model (used by Service)
  factory BackhaulInfoUIModel.fromJnap(BackHaulInfoData data);

  // Equatable, toMap/fromMap, toJson/fromJson
}
```

**Alternatives Considered**:
- Reuse `BackHaulInfoData` directly → Rejected (violates architecture)
- Generic interface → Rejected (over-engineering)

---

### 8. Timestamp Comparison Logic Location

**Question**: Where should the timestamp parsing and comparison logic reside?

**Decision**: Move to `AddWiredNodesService` as a private helper method.

**Rationale**:
- This is data transformation logic, not UI state management
- Current implementation in Provider uses `DateFormat` which is a data concern
- Service can encapsulate the complex comparison logic for detecting new nodes

**Current location**: `add_wired_nodes_provider.dart` lines 165-197
**Target location**: `AddWiredNodesService._isNewBackhaulEntry()` or similar

---

### 9. BackhaulPollResult Structure

**Question**: What should `pollBackhaulChanges()` return through its Stream?

**Decision**: Create a simple result class to carry poll results.

**Rationale**:
- Need to return both the backhaul list AND the "found counting" metric
- Provider uses `foundCounting` to update UI message
- Stream should emit intermediate results during polling

**Structure**:
```dart
class BackhaulPollResult {
  final List<BackhaulInfoUIModel> backhaulList;
  final int foundCounting;
  final bool anyOnboarded;

  BackhaulPollResult({...});
}
```

---

### 10. Service Method Signatures (Wired)

**Question**: What should `AddWiredNodesService` method signatures look like?

**Decision**: Follow same patterns as `AddNodesService` with wired-specific operations.

**Methods**:
```dart
class AddWiredNodesService {
  final RouterRepository _routerRepository;

  AddWiredNodesService(this._routerRepository);

  /// Enable/disable wired auto-onboarding
  Future<void> setAutoOnboardingEnabled(bool enabled);

  /// Get current wired auto-onboarding status
  Future<bool> getAutoOnboardingEnabled();

  /// Poll for backhaul changes compared to snapshot
  Stream<BackhaulPollResult> pollBackhaulChanges(
    List<BackhaulInfoUIModel> snapshot, {
    bool refreshing = false,
  });

  /// Fetch all node devices
  Future<List<LinksysDevice>> fetchNodes();
}
```

---

### 11. Shared vs Separate Test Data Builders

**Question**: Should `AddWiredNodesTestData` be separate from `AddNodesTestData`?

**Decision**: Create separate `AddWiredNodesTestData` for wired-specific JNAP responses.

**Rationale**:
- Different JNAP actions (wired vs Bluetooth)
- Different response structures
- Clearer test organization

**Methods**:
```dart
class AddWiredNodesTestData {
  static JNAPSuccess createWiredAutoOnboardingSettingsSuccess({bool isEnabled = false});
  static JNAPSuccess createBackhaulInfoSuccess({List<Map<String, dynamic>>? devices});
  static JNAPSuccess createDevicesSuccess({List<Map<String, dynamic>>? devices});
  static JNAPError createJNAPError({String result = 'ErrorUnknown'});
}
```

---

## Open Questions Resolved

All research questions resolved. No NEEDS CLARIFICATION items remain.

**AddNodesService (Bluetooth)**: ✅ Implemented
**AddWiredNodesService (Wired)**: Ready for Phase 1 design
