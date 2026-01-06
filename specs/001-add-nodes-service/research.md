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

## Open Questions Resolved

All research questions resolved. No NEEDS CLARIFICATION items remain.
