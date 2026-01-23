# Research: InstantSafety Service Extraction

**Feature**: 004-instant-safety-service
**Date**: 2025-12-22

## Research Summary

This document consolidates research findings for the InstantSafety service extraction. Since this is a refactoring task following established patterns, most decisions are predetermined by existing codebase conventions.

---

## 1. Service Layer Pattern

**Decision**: Follow `RouterPasswordService` as reference implementation

**Rationale**:
- `RouterPasswordService` is the most recent service extraction (per constitution.md Section 6.6)
- It demonstrates the correct pattern for JNAP communication and ServiceError mapping
- Uses constructor injection for RouterRepository dependency

**Alternatives Considered**:
- `HealthCheckService` - More complex, handles multiple JNAP actions in transactions
- `VPNService` - Located in non-standard path (`vpn/service/` instead of `vpn/services/`)
- Direct implementation without reference - Would risk inconsistency

**Reference Code Pattern**:
```dart
final instantSafetyServiceProvider = Provider<InstantSafetyService>((ref) {
  return InstantSafetyService(ref.watch(routerRepositoryProvider));
});

class InstantSafetyService {
  final RouterRepository _routerRepository;

  InstantSafetyService(this._routerRepository);

  Future<InstantSafetyFetchResult> fetchSettings({bool forceRemote = false}) async {
    try {
      // JNAP communication
    } on JNAPError catch (e) {
      throw mapJnapErrorToServiceError(e);
    }
  }
}
```

---

## 2. State Refactoring Approach

**Decision**: Remove `RouterLANSettings` from `InstantSafetyStatus`, store only derived data

**Rationale**:
- Constitution Section 5.3.1 prohibits JNAP models in Provider/Presentation layers
- Current `InstantSafetyStatus.lanSetting` exposes full `RouterLANSettings` JNAP model
- The Service can hold the raw LAN settings internally for save operations
- Status only needs: `hasFortinet: bool` (already present)

**Alternatives Considered**:
1. **Create UI Model for LAN Settings** - Rejected: Over-engineering per Section 5.3.4, only DNS server data needed
2. **Store DNS servers in Status** - Rejected: Not needed for UI, only for save operation
3. **Pass full settings to save method** - Selected: Service receives minimal data, reconstructs JNAP payload

**Implementation Approach**:
- Service `fetchSettings()` returns: `(InstantSafetySettings, hasFortinet: bool)`
- Service internally caches `RouterLANSettings` for subsequent `saveSettings()` call
- Alternative: Service receives current type, fetches fresh LAN settings before save

**Selected Pattern**: Service holds cached LAN settings
- Avoids extra network call on save
- Matches existing `performSave()` behavior which reads from `state.status.lanSetting`

---

## 3. Error Handling Strategy

**Decision**: Use existing `ServiceError` types from `service_error.dart`

**Rationale**:
- Constitution Article XIII mandates ServiceError for all data layer errors
- Existing `ServiceError` sealed class has sufficient error types
- No new error types needed for this feature

**Relevant Existing Errors**:
- `NetworkError` - For general JNAP communication failures
- `UnexpectedError` - For unmapped JNAP errors
- `InvalidInputError` - For validation failures (e.g., missing LAN settings)

**Error Mapping**:
```dart
ServiceError _mapJnapError(JNAPError error) {
  return switch (error.result) {
    _ => UnexpectedError(originalError: error, message: error.error),
  };
}
```

Note: getLANSettings/setLANSettings have limited error cases; most failures are network-level.

---

## 4. Fortinet Compatibility Check

**Decision**: Move `_hasFortinet()` logic to Service, accept device info as parameter

**Rationale**:
- Current implementation reads from `pollingProvider` which contains device info
- Service should not depend on polling provider directly (state management concern)
- Provider can pass device info to service method

**Implementation Options**:
1. **Pass device info to fetchSettings()** - Clean separation, service is pure
2. **Inject PollingProvider into Service** - Creates coupling to state management
3. **Separate method for Fortinet check** - More flexible, allows independent calls

**Selected**: Option 1 - Pass device info map to `fetchSettings()` or have a separate `checkFortinetCompatibility(deviceInfo)` method

---

## 5. DNS Configuration Constants

**Decision**: Move DNS constants to Service layer

**Rationale**:
- `fortinetSetting` and `openDNSSetting` are implementation details
- Should be encapsulated in Service, not exposed in Provider

**Current Location**: `instant_safety_provider.dart` (lines 28-36)
**Target Location**: `instant_safety_service.dart` (private constants)

---

## 6. Test Data Builder Pattern

**Decision**: Create `InstantSafetyTestData` class in `test/mocks/test_data/`

**Rationale**:
- Constitution Section 1.6.2 mandates Test Data Builders for JNAP mock responses
- Centralizes test data creation for service tests

**Key Methods Needed**:
```dart
class InstantSafetyTestData {
  static JNAPSuccess createLANSettingsSuccess({
    String? dnsServer1,
    String? dnsServer2,
    String? dnsServer3,
  });

  static Map<String, dynamic> createDeviceInfo({
    String modelNumber = 'MR9600',
    String firmwareVersion = '1.0.0',
  });
}
```

---

## Summary of Decisions

| Area | Decision |
|------|----------|
| Service Pattern | Follow RouterPasswordService reference |
| State Changes | Remove RouterLANSettings, store only hasFortinet |
| Error Handling | Use existing ServiceError types |
| Fortinet Check | Move to service, accept device info parameter |
| DNS Constants | Move to service as private constants |
| Test Data | Create InstantSafetyTestData builder class |

All NEEDS CLARIFICATION items resolved. Ready for Phase 1 design.
