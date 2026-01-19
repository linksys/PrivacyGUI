# Feature Specification: AutoParentFirstLogin Service Extraction

**Feature Branch**: `001-auto-parent-login-service`
**Created**: 2026-01-07
**Status**: Draft
**Input**: User description: "Extract AutoParentFirstLoginService from AutoParentFirstLoginNotifier to enforce three-layer architecture compliance."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Service Layer Extraction (Priority: P1)

As a developer maintaining the codebase, I need the `AutoParentFirstLoginNotifier` to delegate all JNAP communication to a dedicated Service class so that the architecture complies with the three-layer separation principle (constitution.md Article V, VI, XIII).

**Why this priority**: This is the core objective of the refactoring. Without extracting the Service, the Provider layer continues to violate architectural principles by directly importing JNAP models and using RouterRepository.

**Independent Test**: Can be fully tested by verifying that `AutoParentFirstLoginNotifier` no longer imports any `jnap/models`, `jnap/actions`, or `jnap/command` packages, and all JNAP communication flows through the new Service.

**Acceptance Scenarios**:

1. **Given** the new `AutoParentFirstLoginService` exists, **When** `setUserAcknowledgedAutoConfiguration()` is called, **Then** the Service sends the JNAP action via RouterRepository and handles errors appropriately.
2. **Given** the new `AutoParentFirstLoginService` exists, **When** `setFirmwareUpdatePolicy()` is called, **Then** the Service fetches current settings, modifies the update policy, and saves via RouterRepository.
3. **Given** the new `AutoParentFirstLoginService` exists, **When** `checkInternetConnection()` is called, **Then** the Service checks connection status with retry logic and returns a boolean result.

---

### User Story 2 - Error Handling Compliance (Priority: P2)

As a developer, I need all JNAP errors to be converted to `ServiceError` types in the Service layer so that the Provider layer only handles `ServiceError` and remains decoupled from JNAP-specific error types.

**Why this priority**: Proper error handling ensures that future changes to the data layer (e.g., replacing JNAP) won't require Provider modifications. This is required by constitution.md Article XIII.

**Independent Test**: Can be fully tested by verifying that the Service catches `JNAPError` and throws corresponding `ServiceError` subtypes, and the Provider's catch blocks only reference `ServiceError`.

**Acceptance Scenarios**:

1. **Given** a JNAP error occurs during `setFirmwareUpdatePolicy()`, **When** the Service catches the error, **Then** it throws an appropriate `ServiceError` subtype.
2. **Given** a network error occurs during `checkInternetConnection()`, **When** the retry strategy is exhausted, **Then** the method returns `false` without throwing.
3. **Given** the Provider calls any Service method, **When** an error occurs, **Then** the Provider handles only `ServiceError` types, never `JNAPError`.

---

### User Story 3 - Provider Refactoring (Priority: P3)

As a developer, I need the `AutoParentFirstLoginNotifier` to be refactored to delegate to `AutoParentFirstLoginService` so that the Notifier only manages state and orchestrates calls to the Service.

**Why this priority**: This completes the separation of concerns. Once the Service exists (P1) and error handling is correct (P2), the Provider refactoring ensures full compliance.

**Independent Test**: Can be fully tested by verifying that `AutoParentFirstLoginNotifier` imports `AutoParentFirstLoginService` (not RouterRepository) and delegates all JNAP-related work to the Service.

**Acceptance Scenarios**:

1. **Given** the refactored `AutoParentFirstLoginNotifier`, **When** `finishFirstTimeLogin()` is called, **Then** it delegates internet checking, acknowledgment, and policy setting to the Service.
2. **Given** the refactored `AutoParentFirstLoginNotifier`, **When** examining its imports, **Then** it contains no imports from `jnap/models/`, `jnap/actions/`, or `jnap/command/`.
3. **Given** the refactored Provider file, **When** `flutter analyze` runs, **Then** no lint errors are reported for architecture violations.

---

### Edge Cases

- What happens when `getFirmwareUpdateSettings` fails but `setFirmwareUpdateSettings` needs to proceed? (Current behavior: fallback to default settings with auto-update policy)
- How does the system handle network timeout during internet connection check? (Current behavior: retry up to 5 times with exponential backoff, then return false)
- What happens if `setUserAcknowledgedAutoConfiguration` fails? (Updated behavior: method is now awaited and throws `ServiceError` on failure)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST create a new `AutoParentFirstLoginService` class in `lib/page/login/auto_parent/services/` directory
- **FR-002**: Service MUST implement `setUserAcknowledgedAutoConfiguration()` that sends the JNAP action via RouterRepository
- **FR-003**: Service MUST implement `setFirmwareUpdatePolicy()` that:
  - Fetches current firmware update settings via `JNAPAction.getFirmwareUpdateSettings`
  - Sets update policy to auto-update
  - Falls back to default settings if fetch fails
  - Saves settings via `JNAPAction.setFirmwareUpdateSettings`
- **FR-004**: Service MUST implement `checkInternetConnection()` that:
  - Uses `ExponentialBackoffRetryStrategy` with 5 retries, 2-second initial/max delay
  - Returns `true` if `connectionStatus == 'InternetConnected'`
  - Returns `false` on exhausted retries or error
- **FR-005**: Service MUST catch `JNAPError` and convert to appropriate `ServiceError` subtypes where applicable
- **FR-006**: `AutoParentFirstLoginNotifier` MUST be refactored to:
  - Remove all imports from `jnap/models/`, `jnap/actions/`, `jnap/command/`
  - Remove direct use of `routerRepositoryProvider`
  - Delegate JNAP operations to `AutoParentFirstLoginService`
- **FR-007**: Provider MUST create a `autoParentFirstLoginServiceProvider` following naming conventions in constitution.md Article III Section 3.4.1
- **FR-008**: System MUST maintain existing behavior:
  - `checkAndAutoInstallFirmware()` continues to use `firmwareUpdateProvider` (no change needed)
  - `finishFirstTimeLogin()` orchestration logic remains in Notifier

### Key Entities

- **AutoParentFirstLoginService**: Stateless service class handling JNAP communication for first-time login flow. Injected with `RouterRepository`.
- **autoParentFirstLoginServiceProvider**: Riverpod Provider exposing the Service instance with dependency injection of `routerRepositoryProvider`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `AutoParentFirstLoginNotifier` contains zero imports from `core/jnap/models/`, `core/jnap/actions/`, or `core/jnap/command/` packages
- **SC-002**: `AutoParentFirstLoginService` contains imports from `core/jnap/models/`, `core/jnap/actions/`, and uses `RouterRepository`
- **SC-003**: Architecture compliance check passes: `grep -r "import.*jnap/models" lib/page/login/auto_parent/providers/` returns 0 results
- **SC-004**: Service test coverage reaches minimum 90% as required by constitution.md Article I Section 1.4
- **SC-005**: Provider test coverage reaches minimum 85% as required by constitution.md Article I Section 1.4
- **SC-006**: All existing functionality works identically after refactoring (regression-free)
- **SC-007**: `flutter analyze` reports no new errors in the affected files

## Assumptions

1. The `ExponentialBackoffRetryStrategy` class from `lib/core/retry_strategy/retry.dart` can be used directly in the Service layer
2. The existing `firmwareUpdateProvider` dependency in `checkAndAutoInstallFirmware()` does not need to move to the Service (it's already a Provider-to-Provider dependency, which is acceptable)
3. **Updated**: All JNAP operations (`setUserAcknowledgedAutoConfiguration`, `setFirmwareUpdatePolicy`) MUST be awaited for proper sequencing and error propagation
4. No new `ServiceError` subtypes need to be created - existing types in `service_error.dart` are sufficient
5. The `FirmwareUpdateSettings` and `FirmwareAutoUpdateWindow` JNAP models are only needed in the Service layer

## Clarifications

### Session 2026-01-07

- Q: Should `setUserAcknowledgedAutoConfiguration` and `setFirmwareUpdatePolicy` be awaited? → A: Yes, all JNAP operations must be awaited for proper sequencing and error propagation
- Q: Should `AutoParentFirstLoginState` have tests? → A: Yes, required per constitution.md Article I
