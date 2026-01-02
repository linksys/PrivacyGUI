# Research: InstantPrivacyService Extraction

**Date**: 2026-01-02
**Branch**: `001-instant-privacy-service`

## Overview

This research documents decisions made for extracting InstantPrivacyService from InstantPrivacyNotifier. Since this is a well-defined refactoring following established patterns, no major unknowns existed.

## Decision 1: Service Method Signatures

**Decision**: Use existing UI model types (InstantPrivacySettings, InstantPrivacyStatus) as return types

**Rationale**:
- `InstantPrivacySettings` and `InstantPrivacyStatus` already exist in `instant_privacy_state.dart`
- These classes are suitable UI models (not JNAP models) per spec assumptions
- No new UI Model classes needed - avoids over-engineering per Article V Section 5.4
- Service transforms JNAP `MACFilterSettings` → `InstantPrivacySettings`

**Alternatives Considered**:
- Create new `InstantPrivacyUIModel` class → Rejected: Existing models are sufficient
- Return raw Map → Rejected: Violates type safety and constitution Article V Section 5.3.1

## Decision 2: Error Mapping Strategy

**Decision**: Use generic `UnexpectedError` for MAC filter JNAP errors

**Rationale**:
- Current provider uses `.onError()` which silently handles failures
- MAC filter operations don't have domain-specific error codes requiring distinct handling
- `UnexpectedError` with `originalError` preserved allows debugging while maintaining abstraction
- Future: Can add specific error types (e.g., `MacFilterFullError`) if needed

**Alternatives Considered**:
- Create feature-specific error types → Deferred: No current requirement
- Rethrow as-is → Rejected: Violates Article XIII

## Decision 3: ServiceHelper Capability Check

**Decision**: Move `isSupportGetSTABSSID()` check into service method

**Rationale**:
- Service should encapsulate all JNAP-related logic including capability detection
- Provider shouldn't need to know about JNAP capability details
- Service returns empty list when feature not supported (graceful degradation)

**Alternatives Considered**:
- Keep check in Provider → Rejected: Leaks JNAP knowledge to Provider layer
- Add new service method `supportsStaBssid()` → Over-engineering for single caller

## Decision 4: DeviceManager Access Pattern

**Decision**: Provider continues to access `deviceManagerProvider` for node MAC addresses

**Rationale**:
- `deviceManagerProvider` exposes processed device data (not raw JNAP)
- Getting node MAC addresses for save operation is Provider-level orchestration
- Passing node MACs as parameter to service keeps service stateless

**Alternatives Considered**:
- Inject deviceManager into Service → Creates unnecessary coupling
- Service fetches node MACs → Service shouldn't depend on device state

## Decision 5: Test Data Builder Approach

**Decision**: Create `InstantPrivacyTestData` class with static factory methods

**Rationale**:
- Follows constitution Article I Section 1.6.2 pattern
- Centralizes JNAP mock responses for service tests
- Methods: `createMacFilterSettingsSuccess()`, `createStaBssidsSuccess()`, etc.

**Alternatives Considered**:
- Inline mock data in tests → Rejected: Violates constitution test data builder mandate
- Use fixtures files → Doesn't fit Flutter test patterns

## Reference Implementation Analysis

**Studied**: `lib/page/instant_admin/services/router_password_service.dart`

**Key Patterns Applied**:
1. Provider definition at top of file using `Provider<T>` with `ref.watch(routerRepositoryProvider)`
2. Constructor injection of `RouterRepository`
3. DartDoc comments on public methods
4. Error handling: `on JNAPError catch (e) { throw mapJnapErrorToServiceError(e); }`
5. Returns Map or domain types, never raw JNAP responses

## Summary

All research items resolved. No blocking unknowns remain. Ready for Phase 1 design.

| Item | Status | Notes |
|------|--------|-------|
| Method signatures | ✅ Resolved | Use existing Settings/Status types |
| Error mapping | ✅ Resolved | UnexpectedError for generic failures |
| Capability check | ✅ Resolved | Move to service |
| DeviceManager | ✅ Resolved | Provider passes node MACs to service |
| Test data | ✅ Resolved | InstantPrivacyTestData builder class |
