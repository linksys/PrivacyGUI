# Research: Instant Admin Service Extraction

**Feature**: 003-instant-admin-service
**Date**: 2025-12-22

## Research Summary

This document captures research findings for extracting JNAP communication logic from TimezoneNotifier and PowerTableNotifier into dedicated Service classes.

---

## 1. Existing Service Pattern Analysis

### Decision: Follow `router_password_service.dart` Pattern

**Rationale**: The existing `RouterPasswordService` in the same feature module provides an established pattern that:
- Uses constructor injection for `RouterRepository`
- Defines a `Provider<T>` for dependency injection
- Catches `JNAPError` and maps to `ServiceError`
- Returns domain-specific data structures

**Reference Implementation**: `lib/page/instant_admin/services/router_password_service.dart`

**Alternatives Considered**:
- Creating a shared base service class → Rejected: Adds unnecessary abstraction per Article VII
- Using AsyncNotifier for services → Rejected: Services must be stateless per Article VI

---

## 2. TimezoneNotifier JNAP Operations Analysis

### Current Implementation (to be extracted)

| Method | JNAP Action | Data Transformation |
|--------|-------------|---------------------|
| `performFetch()` | `JNAPAction.getTimeSettings` | Raw output → `TimezoneSettings` + `TimezoneStatus` |
| `performSave()` | `JNAPAction.setTimeSettings` | `TimezoneSettings` → JNAP payload |

### Decision: Extract to TimezoneService with Two Methods

**Methods**:
1. `fetchTimezoneSettings()` → Returns `(TimezoneSettings, TimezoneStatus)`
2. `saveTimezoneSettings(TimezoneSettings settings, List<SupportedTimezone> supportedTimezones)` → Returns `void`

**Rationale**:
- Preserves existing data flow
- `SupportedTimezone` list needed for DST validation during save
- Tuple return maintains atomicity of fetch operation

**Alternatives Considered**:
- Separate fetch methods for settings and status → Rejected: Single JNAP call returns both
- Return raw Map and let provider transform → Rejected: Violates Article VI (Service must transform)

---

## 3. PowerTableNotifier JNAP Operations Analysis

### Current Implementation (to be extracted)

| Method | JNAP Action | Data Transformation |
|--------|-------------|---------------------|
| `build()` | Reads from `pollingProvider` (which calls `JNAPAction.getPowerTableSettings`) | Polling data → `PowerTableState` |
| `save()` | `JNAPAction.setPowerTableSettings` | `PowerTableCountries` → JNAP payload |

### Decision: Extract to PowerTableService

**Methods**:
1. `parsePowerTableSettings(Map<JNAPAction, JNAPResult> pollingData)` → Returns `PowerTableState`
2. `savePowerTableCountry(PowerTableCountries country)` → Returns `void`

**Rationale**:
- `parsePowerTableSettings` receives polling data (already fetched) rather than making new JNAP call
- This preserves existing polling architecture while moving transformation logic to service
- `save` method handles the direct JNAP call

**Alternatives Considered**:
- Have service make its own fetch call → Rejected: Would duplicate polling mechanism
- Keep parsing in provider → Rejected: Violates Article V (JNAP model import in provider)

---

## 4. Error Handling Strategy

### Decision: Use Existing ServiceError Types + mapJnapErrorToServiceError Helper

**Existing helper**: `lib/core/errors/jnap_error_mapper.dart` provides `mapJnapErrorToServiceError(JNAPError)`

**Error Types to Use**:
- `NetworkError` - For network/timeout failures
- `UnexpectedError` - For unmapped JNAP errors

**Rationale**: Timezone and power table operations don't have specific error codes that need special handling; generic error types are sufficient.

**Alternatives Considered**:
- Create `TimezoneError` and `PowerTableError` types → Rejected: No specific error codes; over-engineering

---

## 5. PollingProvider Integration for PowerTableService

### Decision: Service Parses Polling Data, Does Not Trigger Polling

**Architecture**:
```
PollingProvider → fetches JNAP data including getPowerTableSettings
       ↓
PowerTableNotifier.build() → reads pollingProvider.value.data
       ↓
PowerTableService.parsePowerTableSettings(data) → transforms to PowerTableState
```

**For save operation**:
```
PowerTableService.savePowerTableCountry(country) → calls RouterRepository.send()
       ↓
Service returns, Provider restarts polling via pollingProvider.notifier
```

**Rationale**:
- Maintains existing polling architecture
- Service remains stateless (no provider references)
- Polling restart is a UI coordination concern (stays in Provider)

---

## 6. SupportedTimezone Model Location

### Decision: Keep Import in Service Layer Only

**Current state**: `SupportedTimezone` is defined in `lib/core/jnap/models/timezone.dart`

**After refactoring**:
- `TimezoneService` imports `SupportedTimezone` (allowed - Service layer)
- `TimezoneNotifier` does NOT import JNAP models (receives data via Service)
- `TimezoneStatus` contains `List<SupportedTimezone>` (this is acceptable as it's part of the state)

**Note**: The `timezone_state.dart` file currently imports `jnap/models/timezone.dart`. This import should remain but the provider file should NOT have this import.

---

## 7. PowerTableCountries Enum Location

### Decision: Keep in Provider File (Shared)

**Current location**: `lib/page/instant_admin/providers/power_table_provider.dart`

**Rationale**:
- The enum is used by both UI (for display) and Service (for JNAP payload)
- Moving it would require a separate models file
- Keeping it in provider file is acceptable since it's not a JNAP model

**Alternative Considered**:
- Move to `lib/page/instant_admin/models/power_table_countries.dart` → Acceptable but not required

---

## 8. Test Data Builder Strategy

### Decision: Create `InstantAdminTestData` Class

**File**: `test/mocks/test_data/instant_admin_test_data.dart`

**Contents**:
```dart
class InstantAdminTestData {
  // Timezone test data
  static JNAPSuccess createGetTimeSettingsSuccess({...});

  // Power table test data
  static JNAPSuccess createGetPowerTableSettingsSuccess({...});
  static JNAPTransactionSuccessWrap createPollingDataWithPowerTable({...});
}
```

**Rationale**:
- Single file for all instant_admin service tests
- Follows naming convention from Article I Section 1.6.2
- Supports partial override pattern

---

## Resolved Questions

All technical questions have been resolved through analysis of existing code patterns. No external research required.

| Question | Resolution |
|----------|------------|
| Service pattern to follow | `router_password_service.dart` |
| Error handling approach | Use `mapJnapErrorToServiceError` helper |
| Polling integration | Service parses data, doesn't trigger polling |
| Model locations | Keep SupportedTimezone import in service only |
| Test data organization | Single `InstantAdminTestData` class |
