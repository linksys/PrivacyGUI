# Feature Specification: Auth Service Layer Extraction

**Feature Branch**: `001-auth-service-extraction`
**Created**: 2025-12-10
**Status**: Draft
**Input**: User description: "Extract authentication business logic from AuthProvider into AuthService - Currently AuthNotifier handles session management, credential storage, and API communication directly, violating the Service Layer principle in our constitution. Split this into: AuthService for business logic (token refresh, credential persistence, login orchestration) and AuthNotifier for state management only. Must maintain full backward compatibility with all existing authentication flows (local/cloud/RA login, session refresh, logout)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Service Extracts Session Token Management (Priority: P1)

As a developer maintaining the authentication system, I need session token validation, expiration checking, and automatic refresh logic extracted into AuthService so that this business logic can be tested independently without involving UI state management.

**Why this priority**: Session token management is the core security mechanism and must work flawlessly. Extracting it first ensures the most critical authentication flow is properly isolated and testable.

**Independent Test**: Can be fully tested by instantiating AuthService with mocked dependencies (RouterRepository, CloudRepository, FlutterSecureStorage) and verifying token validation, expiration detection, and refresh workflows without any UI state.

**Acceptance Scenarios**:

1. **Given** a valid session token stored in secure storage, **When** AuthService checks token validity, **Then** it returns the valid token without triggering refresh
2. **Given** an expired session token with valid refresh token, **When** AuthService checks token validity, **Then** it automatically refreshes the token and returns the new token
3. **Given** no session token exists, **When** AuthService checks token validity, **Then** it returns null without throwing errors
4. **Given** an expired token without refresh token, **When** AuthService checks token validity, **Then** it returns null and clears stored credentials

---

### User Story 2 - Service Handles Authentication Flows (Priority: P1)

As a developer implementing login features, I need local login, cloud login, and RA login orchestration extracted into AuthService methods so that these workflows can be tested independently and reused across different UI contexts.

**Why this priority**: Authentication flows are critical user-facing features. Extracting them ensures consistency across the app and enables thorough testing of edge cases (network failures, invalid credentials, etc.).

**Independent Test**: Can be fully tested by calling AuthService login methods with various credential inputs and mocked API responses, verifying correct credential storage, error handling, and return values without involving AuthNotifier state updates.

**Acceptance Scenarios**:

1. **Given** valid cloud credentials, **When** AuthService performs cloud login, **Then** it stores session token securely and returns success result
2. **Given** valid local password, **When** AuthService performs local login, **Then** it verifies password via JNAP and stores credentials securely
3. **Given** valid RA session information, **When** AuthService performs RA login, **Then** it stores session details and network ID to appropriate storage
4. **Given** invalid credentials for any login type, **When** AuthService attempts authentication, **Then** it returns specific error without storing any credentials

---

### User Story 3 - Service Manages Credential Persistence (Priority: P1)

As a developer working with secure data, I need credential storage/retrieval logic centralized in AuthService so that all sensitive data operations follow consistent patterns and can be audited in one place.

**Why this priority**: Credential storage involves security-critical operations with FlutterSecureStorage. Centralizing this logic reduces duplication and ensures security best practices are applied consistently.

**Independent Test**: Can be fully tested by calling AuthService credential methods and verifying correct storage keys, encryption, and retrieval patterns using mocked FlutterSecureStorage.

**Acceptance Scenarios**:

1. **Given** new session token data, **When** AuthService updates cloud credentials, **Then** it stores token and timestamp in secure storage with correct keys
2. **Given** new local password, **When** AuthService updates local credentials, **Then** it stores password in secure storage under correct key
3. **Given** logout request, **When** AuthService clears credentials, **Then** it removes all authentication data from both secure storage and shared preferences
4. **Given** multiple credential updates in sequence, **When** AuthService processes them, **Then** each update persists independently without data loss

---

### User Story 4 - AuthNotifier Refactored to Use AuthService (Priority: P2)

As a UI developer using AuthProvider, I need AuthNotifier to delegate all business logic to AuthService while maintaining the same public API so that existing UI code continues to work without modifications.

**Why this priority**: After service extraction, the provider layer must adapt to use the new service while maintaining backward compatibility with all existing screens and flows.

**Independent Test**: Can be fully tested by calling all existing AuthNotifier methods (init, cloudLogin, localLogin, logout, etc.) and verifying they produce identical state transitions and side effects as before refactoring.

**Acceptance Scenarios**:

1. **Given** existing auth provider usage in UI, **When** refactored AuthNotifier is used, **Then** all public methods maintain same signatures and behaviors
2. **Given** AuthNotifier calls AuthService methods, **When** service returns success, **Then** AuthNotifier updates state correctly
3. **Given** AuthNotifier calls AuthService methods, **When** service returns errors, **Then** AuthNotifier propagates errors to AsyncValue.error state
4. **Given** any authentication flow in the app, **When** using refactored provider, **Then** UI behavior remains identical to pre-refactor behavior

---

### User Story 5 - Unit Tests Cover AuthService (Priority: P2)

As a developer ensuring code quality, I need comprehensive unit tests for AuthService that mock all dependencies so that business logic correctness is verified independently from UI and infrastructure.

**Why this priority**: The constitution mandates test coverage for all business logic. Service extraction enables proper unit testing of authentication logic in isolation.

**Independent Test**: Can be verified by running test suite and confirming 100% coverage of all AuthService public methods with varied input scenarios (success, errors, edge cases).

**Acceptance Scenarios**:

1. **Given** AuthService unit tests, **When** executed, **Then** all session token management logic is covered with success/error cases
2. **Given** AuthService unit tests, **When** executed, **Then** all authentication flows are tested with mocked RouterRepository and CloudRepository
3. **Given** AuthService unit tests, **When** executed, **Then** all credential persistence operations are verified with mocked storage
4. **Given** test suite execution, **When** complete, **Then** no business logic paths remain untested

---

### Edge Cases

- What happens when FlutterSecureStorage read/write operations fail due to platform issues? → Return error Result to caller; AuthService does not retry or silently degrade
- How does the service handle concurrent login attempts (multiple calls to cloudLogin simultaneously)? → AuthService does not manage concurrency; concurrent calls are allowed and caller is responsible for coordination if needed
- What happens when session token refresh is triggered during an active authentication flow? → Each refresh call executes independently; AuthService does not serialize concurrent refreshes. Caller (AuthNotifier) should handle coordination if needed. Multiple simultaneous refreshes will each call CloudRepository.refreshToken(), which is acceptable.
- How does the system handle corrupted data in secure storage (invalid JSON, missing fields)? → Treat as missing and clear corrupted data; user must re-authenticate
- What happens when RouterRepository or CloudRepository throw unexpected exceptions?
- How does logout handle partial failures (e.g., secure storage clears but SharedPreferences fails)? → Best-effort cleanup strategy: continue attempting to clear all storage locations even if one fails. Return AuthFailure(StorageError) only if ANY deletion fails, but still clear as much as possible. Log all failures for debugging. Caller should treat partial failure as logout success since user credentials are removed.
- What happens when the app is terminated mid-authentication flow?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: AuthService MUST extract all session token validation logic from AuthNotifier, including expiration checking and automatic refresh handling
- **FR-002**: AuthService MUST extract all authentication flow orchestration (cloud login, local login, RA login) from AuthNotifier
- **FR-003**: AuthService MUST extract all credential persistence operations (save/update/delete) using FlutterSecureStorage and SharedPreferences
- **FR-004**: AuthService MUST be stateless - it SHALL NOT manage any internal state, only perform operations and return results
- **FR-005**: AuthService MUST accept all dependencies (RouterRepository, CloudRepository, FlutterSecureStorage, SharedPreferences) via constructor injection
- **FR-006**: AuthService MUST implement error handling for all API communication and storage operations using Result<T, AuthError> types (functional style with explicit error propagation, no thrown exceptions for expected failures)
- **FR-007**: AuthService MUST handle session token refresh automatically when expired tokens are detected
- **FR-008**: AuthService MUST implement logout operations that clear all authentication data from secure storage and preferences
- **FR-009**: AuthNotifier MUST be refactored to delegate all business logic calls to AuthService while maintaining identical public API
- **FR-010**: AuthNotifier MUST continue managing AuthState using Riverpod AsyncNotifier pattern
- **FR-011**: AuthNotifier MUST transform AuthService results into appropriate AsyncValue state updates (loading, data, error)
- **FR-012**: All existing authentication flows in the app MUST continue to work identically after refactoring (backward compatibility)
- **FR-013**: Unit tests MUST be created for AuthService covering all business logic paths using Mocktail for mocking dependencies
- **FR-014**: All existing tests for AuthNotifier MUST continue to pass or be updated to reflect new implementation while maintaining same behavior validation
- **FR-015**: A Riverpod Provider (single instance, not factory) for AuthService MUST be defined to enable dependency injection throughout the app

### Key Entities

- **AuthService**: Stateless service encapsulating all authentication business logic (session management, login flows, credential persistence, logout operations)
- **AuthNotifier**: Riverpod AsyncNotifier managing authentication UI state by delegating business logic to AuthService
- **SessionToken**: Represents cloud authentication token with access token, refresh token, expiration time, and token type
- **AuthState**: Immutable state object containing username, passwords, session token, and login type for UI consumption
- **LoginType**: Enumeration of authentication modes (none, local, remote/cloud)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All authentication business logic is extracted into AuthService with zero business logic remaining in AuthNotifier (verified by code review)
- **SC-002**: AuthService achieves 100% unit test coverage with all methods tested using mocked dependencies (verified by coverage report)
- **SC-003**: All existing authentication flows continue to function identically after refactoring (verified by running all existing integration and widget tests without failures)
- **SC-004**: Refactored code follows Article VI of the constitution with clear separation between service (business logic) and provider (state management) layers (verified by architecture review)
- **SC-005**: AuthService can be instantiated and tested independently without requiring any Riverpod providers or UI context (verified by unit tests)
- **SC-006**: Code maintainability improves as measured by reduced cyclomatic complexity in AuthNotifier (target: reduce complexity by at least 50%)
- **SC-007**: Zero breaking changes to public API - all existing code using AuthProvider continues to work without modifications (verified by no compilation errors in dependent code)

## Assumptions

- FlutterSecureStorage is available on all target platforms and handles encryption automatically
- Existing error handling patterns in AuthNotifier are adequate and should be preserved in AuthService
- RouterRepository and CloudRepository interfaces are stable and will not change during this refactoring
- The constitution's Article VI patterns (as demonstrated in health_check_service.dart, pnp_service.dart) are the correct architecture to follow
- Session token refresh logic can remain synchronous within the token validation flow
- The project uses Mocktail for testing (as specified in constitution), not Mockito

## Dependencies

- **Internal**: RouterRepository, CloudRepository, FlutterSecureStorage, SharedPreferences, Riverpod providers
- **External**: No new external dependencies required - uses existing packages (flutter_secure_storage, shared_preferences, riverpod)
- **Architecture**: Must follow Article VI (Service Layer Principle) of the project constitution

## Clarifications

### Session 2025-12-10

- Q: What error handling pattern should AuthService use? → A: Result<T, AuthError> types for all methods (functional style, explicit errors)
- Q: How should concurrent login attempts be handled? → A: Ignore/allow concurrent calls (caller responsibility to manage)
- Q: Should AuthService be singleton or instantiated per-use? → A: Single instance via Riverpod Provider (standard service pattern)
- Q: How should storage failures (FlutterSecureStorage) be handled? → A: Return error Result, let caller decide (propagate failure)
- Q: How should corrupted data in secure storage be handled? → A: Treat as missing, clear corrupted data (clean slate recovery)

## Out of Scope

- Changing authentication logic behavior or adding new authentication features
- Modifying RouterRepository or CloudRepository interfaces
- Adding new authentication methods (OAuth, biometric, etc.)
- Changing how session tokens are encrypted or stored (platform-level security)
- Refactoring other providers that depend on AuthProvider (handled separately)
- Performance optimization of authentication flows (not a goal of this refactor)
- UI changes or user-facing feature additions
