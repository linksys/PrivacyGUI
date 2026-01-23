# Feature Specification: ConnectivityService Extraction

**Feature Branch**: `001-connectivity-service`
**Created**: 2026-01-02
**Status**: Draft
**Input**: Extract ConnectivityService from ConnectivityNotifier to enforce three-layer architecture compliance

## Overview

This is an internal refactoring task to improve code architecture. The goal is to extract JNAP-related logic from `ConnectivityNotifier` into a dedicated `ConnectivityService`, ensuring the Provider layer no longer directly depends on JNAP models, actions, or error types.

**Architecture Reference**: constitution.md Article V (Three-Layer Architecture), Article VI (Service Layer), Article XIII (Error Handling)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Connectivity Check Continues to Work (Priority: P1)

As a user, I want the app to automatically detect my network connectivity status (WiFi, mobile data, no connection) and determine if I'm connected to a Linksys router, so that the app can provide appropriate functionality.

**Why this priority**: This is the core functionality that must remain intact after refactoring. Any regression would break fundamental app behavior.

**Independent Test**: Can be fully tested by launching the app on various network conditions (WiFi connected to Linksys router, non-Linksys router, mobile data, no connection) and verifying the correct connectivity state is detected.

**Acceptance Scenarios**:

1. **Given** the user is connected to a Linksys router WiFi, **When** the app checks connectivity, **Then** the router type is correctly identified as `behind` or `behindManaged`
2. **Given** the user is connected to a non-Linksys router, **When** the app checks connectivity, **Then** the router type is identified as `others`
3. **Given** the user has no network connection, **When** the app checks connectivity, **Then** the state reflects no internet access

---

### User Story 2 - Router Configuration Status Check (Priority: P1)

As a user opening the app for the first time with a new router, I want the app to detect whether my router has been configured (password changed from default), so that the app can guide me through setup if needed.

**Why this priority**: Essential for first-time user experience and security guidance.

**Independent Test**: Can be tested by checking router configuration status with both a factory-reset router and a previously-configured router.

**Acceptance Scenarios**:

1. **Given** a router with default admin password, **When** checking configuration status, **Then** the app receives `isDefaultPassword: true`
2. **Given** a router with user-set admin password, **When** checking configuration status, **Then** the app receives `isDefaultPassword: false, isSetByUser: true`

---

### User Story 3 - Architecture Compliance (Priority: P1)

As a developer, I want the ConnectivityNotifier to delegate JNAP operations to ConnectivityService, so that the codebase follows the three-layer architecture and is easier to maintain and test.

**Why this priority**: Core objective of this refactoring task.

**Independent Test**: Can be verified by running architecture compliance checks (grep for JNAP imports in Provider layer) and ensuring all tests pass.

**Acceptance Scenarios**:

1. **Given** the refactoring is complete, **When** checking `connectivity_provider.dart` imports, **Then** no `jnap/models`, `jnap/result`, or `jnap/actions` imports exist
2. **Given** the refactoring is complete, **When** running existing unit tests, **Then** all tests pass with identical behavior
3. **Given** a JNAP error occurs during connectivity check, **When** the Service handles the error, **Then** it is converted to a `ServiceError` before reaching the Provider

---

### Edge Cases

- What happens when the router is unreachable during `testRouterType()`? The Service should return `RouterType.others` gracefully.
- What happens when `getDeviceInfo` JNAP action fails? The Service should catch the error and return a fallback value.
- What happens when SharedPreferences is unavailable? The Service should handle this gracefully without crashing.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST create a new `ConnectivityService` class in `lib/providers/connectivity/services/`
- **FR-002**: `ConnectivityService` MUST implement `testRouterType(String? gatewayIp)` method that returns `RouterType`
- **FR-003**: `ConnectivityService` MUST implement `fetchRouterConfiguredData()` method that returns `RouterConfiguredData`
- **FR-004**: `ConnectivityService` MUST handle all JNAP communication via `RouterRepository`
- **FR-005**: `ConnectivityService` MUST convert JNAP models (`NodeDeviceInfo`) to return types internally
- **FR-006**: `ConnectivityService` MUST map JNAP errors to `ServiceError` types
- **FR-007**: `ConnectivityNotifier` MUST delegate to `ConnectivityService` instead of calling `RouterRepository` directly
- **FR-008**: `ConnectivityNotifier` MUST NOT import any `jnap/models`, `jnap/result`, or `jnap/actions` packages
- **FR-009**: System MUST maintain backward compatibility - all existing functionality must work identically
- **FR-010**: System MUST provide unit tests for `ConnectivityService` with mocked `RouterRepository`

### Key Entities

- **ConnectivityService**: Stateless service handling JNAP communication for connectivity features. Accepts `RouterRepository` via constructor injection.
- **RouterType**: Enum representing the type of router connection (`others`, `behind`, `behindManaged`)
- **RouterConfiguredData**: Data class containing `isDefaultPassword` and `isSetByUser` boolean flags
- **ServiceError**: Sealed class for unified error handling across the application

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Zero JNAP-related imports (`jnap/models`, `jnap/result`, `jnap/actions`) in `connectivity_provider.dart` after refactoring
- **SC-002**: All existing connectivity-related functionality works identically before and after refactoring
- **SC-003**: `ConnectivityService` unit test coverage reaches at least 90%
- **SC-004**: Architecture compliance check passes: `grep -r "import.*jnap/models" lib/providers/connectivity/` returns no results
- **SC-005**: No new runtime errors introduced - app connectivity detection works on all network conditions

## Assumptions

- The existing `RouterConfiguredData` class will remain in `connectivity_provider.dart` or be moved to an appropriate location
- The `ConnectivityInfo`, `ConnectivityState`, and mixin files do not require modification
- `ServiceError` types needed for this feature already exist in `lib/core/errors/service_error.dart`, or will be added if missing
- The refactoring does not change any public API or user-facing behavior
