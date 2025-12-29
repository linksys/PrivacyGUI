# Research: Dashboard Manager Service Extraction

**Date**: 2025-12-29
**Status**: Complete

## Research Summary

This refactoring follows an established pattern in the codebase. No unknowns requiring external research.

---

## Decision 1: Service Location

**Decision**: Place `DashboardManagerService` in `lib/core/jnap/services/`

**Rationale**:
- Follows existing pattern of `DeviceManagerService` in same directory
- Both are core infrastructure services used across multiple features
- Keeps JNAP-related services co-located with JNAP providers

**Alternatives Considered**:
- `lib/page/dashboard/services/` - Rejected: DashboardManagerProvider is in `lib/core/jnap/providers/`, not page-specific
- `lib/core/services/` - Rejected: Service is JNAP-specific, not generic

---

## Decision 2: State Class Handling

**Decision**: Keep `DashboardManagerState` unchanged; Service returns it directly

**Rationale**:
- State class already exists with proper structure
- State contains JNAP models (`NodeDeviceInfo`, `RouterRadio`, `GuestRadioInfo`) which are domain concepts, not implementation details
- Creating a separate UI model would be over-engineering per Article V Section 5.3.4

**Alternatives Considered**:
- Create `DashboardUIModel` - Rejected: No reuse across features, no complex transformations needed
- Transform to primitive types - Rejected: Would lose type safety and require duplicate definitions

---

## Decision 3: Error Handling Pattern

**Decision**: Use `ServiceError` sealed class for checkRouterIsBack() and checkDeviceInfo() methods; transformPollingData() never throws

**Rationale**:
- transformPollingData() processes polling data which may have partial failures - should return partial state, not throw
- checkRouterIsBack() and checkDeviceInfo() are imperative operations that can fail - should throw ServiceError
- Follows Article XIII patterns

**Alternatives Considered**:
- Return Result<T> type - Rejected: Not established pattern in codebase
- Throw for all methods - Rejected: Polling transformation should be resilient

---

## Decision 4: Reference Implementation

**Decision**: Use `DeviceManagerService` as the primary reference implementation

**Rationale**:
- Same architectural context (core JNAP provider refactoring)
- Already implements the transformPollingData() pattern
- Uses proper ServiceError mapping
- Recently implemented (branch 001) and validated

**Reference Files**:
- `lib/core/jnap/services/device_manager_service.dart`
- `lib/core/jnap/providers/device_manager_provider.dart`

---

## Decision 5: Test Data Builder Pattern

**Decision**: Create `DashboardManagerTestData` class in `test/mocks/test_data/`

**Rationale**:
- Follows Article I Section 1.6.2 test data builder pattern
- Provides reusable mock JNAP responses
- Supports partial override design for flexible test scenarios

**Methods to Include**:
- `createDeviceInfoSuccess()` - Mock getDeviceInfo response
- `createRadioInfoSuccess()` - Mock getRadioInfo response
- `createGuestRadioSettingsSuccess()` - Mock getGuestRadioSettings response
- `createSystemStatsSuccess()` - Mock getSystemStats response
- `createEthernetPortConnectionsSuccess()` - Mock getEthernetPortConnections response
- `createLocalTimeSuccess()` - Mock getLocalTime response
- `createSoftSKUSettingsSuccess()` - Mock getSoftSKUSettings response
- `createSuccessfulPollingData()` - Combined polling data with all actions

---

## No Further Research Required

All technical decisions resolved based on:
1. Existing codebase patterns (DeviceManagerService)
2. Constitution requirements (Article V, VI, XIII)
3. Feature spec acceptance criteria
