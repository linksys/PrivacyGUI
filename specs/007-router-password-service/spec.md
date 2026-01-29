# Feature Specification: Router Password Service Layer Extraction

**Feature Branch**: `002-router-password-service`
**Created**: 2025-12-15
**Status**: Draft
**Input**: User description: "Refactor RouterPasswordNotifier to follow Service Layer architecture by extracting all JNAP communication logic into RouterPasswordService. The notifier currently violates three-layer architecture by directly calling RouterRepository for password operations (fetch, set, verify). Need to create stateless service with dependency injection, add comprehensive unit tests, and maintain backward compatibility."

## Clarifications

### Session 2025-12-15

- Q: Should RouterPasswordService follow the AuthService pattern with Result<T> sealed classes for functional error handling, or use traditional exception throwing? → A: Use traditional exception throwing (throw JNAPError, StorageError, etc.)
- Q: Should RouterPasswordService accept FlutterSecureStorage as a constructor dependency for testability, or should password persistence remain in the notifier layer? → A: Service accepts FlutterSecureStorage as constructor dependency (fully testable, single responsibility)
- Q: Should RouterPasswordService have a dedicated Riverpod Provider for dependency injection, or should the notifier create the service instance directly? → A: Create dedicated routerPasswordServiceProvider (matches AuthService pattern, follows constitution Article VI Section 6.3)

## User Scenarios & Testing *(mandatory)*

### Developer Story 1 - Service Layer Extraction (Priority: P1)

As a developer maintaining the codebase, I need the router password functionality to follow the established Service Layer Pattern so that business logic is separated from state management, making the code more testable and maintainable.

**Why this priority**: This is the core architectural change that establishes the foundation. Without this, the code continues to violate architecture principles and accumulate technical debt.

**Independent Test**: Can be fully tested by creating RouterPasswordService with mocked RouterRepository, verifying all JNAP communication methods work correctly, and confirming the service returns appropriate data models without managing state.

**Acceptance Scenarios**:

1. **Given** existing RouterPasswordNotifier code, **When** developer extracts JNAP communication logic, **Then** RouterPasswordService is created with all password-related JNAP operations
2. **Given** RouterPasswordService is implemented, **When** developer runs unit tests with mocked dependencies, **Then** all service methods execute correctly without accessing real JNAP endpoints
3. **Given** the new service layer, **When** developer checks imports in provider files, **Then** no JNAP models are directly imported in RouterPasswordNotifier

---

### Developer Story 2 - Notifier Refactoring (Priority: P2)

As a developer, I need RouterPasswordNotifier to delegate all JNAP operations to RouterPasswordService so that the notifier focuses solely on state management and UI coordination.

**Why this priority**: This completes the architectural separation and ensures the Provider layer no longer violates three-layer architecture principles.

**Independent Test**: Can be tested by verifying RouterPasswordNotifier calls service methods instead of RouterRepository directly, and that all existing functionality continues to work through the UI.

**Acceptance Scenarios**:

1. **Given** RouterPasswordService is available, **When** RouterPasswordNotifier needs password data, **Then** it calls service methods instead of RouterRepository
2. **Given** refactored notifier, **When** user performs password operations through the UI, **Then** all operations complete successfully with identical behavior to before refactoring
3. **Given** the refactored architecture, **When** developer reviews code, **Then** RouterPasswordNotifier contains only state management logic with no JNAP model transformations

---

### Developer Story 3 - Comprehensive Test Coverage (Priority: P3)

As a developer, I need comprehensive unit tests for both the service and refactored notifier so that future changes don't break functionality and the code can be maintained with confidence.

**Why this priority**: Testing ensures the refactoring didn't introduce regressions and provides safety net for future development.

**Independent Test**: Can be tested by running the test suite and verifying coverage meets project requirements (Service ≥90%, Provider ≥85%).

**Acceptance Scenarios**:

1. **Given** RouterPasswordService implementation, **When** developer runs service unit tests, **Then** all JNAP operations are tested with mocked repository responses
2. **Given** refactored RouterPasswordNotifier, **When** developer runs provider unit tests, **Then** state management logic is tested with mocked service
3. **Given** complete test suite, **When** developer generates coverage report, **Then** coverage meets or exceeds constitutional requirements

---

### Edge Cases

- Service throws JNAPError when JNAP operations fail (network errors, invalid responses); notifier catches and updates error state
- Service throws StorageError when FlutterSecureStorage read/write operations fail; notifier catches and handles gracefully
- Service propagates recovery code validation errors (invalid code, attempts exhausted) as JNAPError with specific error codes; notifier updates remainingErrorAttempts state
- Service propagates authentication failures during password change as exceptions; notifier catches and maintains current state
- Concurrent password operations are not prevented at service layer; caller (notifier) responsible for operation serialization if needed

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST maintain all existing router password functionality without behavioral changes
- **FR-002**: System MUST define routerPasswordServiceProvider (Riverpod Provider) for RouterPasswordService dependency injection
- **FR-003**: RouterPasswordService MUST be stateless and accept all dependencies via constructor injection (RouterRepository, FlutterSecureStorage)
- **FR-004**: RouterPasswordService MUST handle all JNAP communication for password operations (fetch configuration, set password, verify recovery code)
- **FR-005**: RouterPasswordService MUST handle password persistence operations via FlutterSecureStorage dependency
- **FR-006**: RouterPasswordService MUST transform JNAP responses into appropriate data models for the provider layer
- **FR-007**: RouterPasswordService MUST propagate errors using traditional exception throwing (JNAPError, StorageError, etc.) rather than Result<T> sealed classes
- **FR-008**: RouterPasswordNotifier MUST access RouterPasswordService via routerPasswordServiceProvider
- **FR-009**: RouterPasswordNotifier MUST delegate all JNAP operations and storage operations to RouterPasswordService
- **FR-010**: RouterPasswordNotifier MUST maintain its public API to ensure backward compatibility
- **FR-011**: RouterPasswordNotifier MUST handle exceptions from service layer using try-catch blocks and update state accordingly
- **FR-012**: System MUST include unit tests for RouterPasswordService with ≥90% coverage
- **FR-013**: System MUST include unit tests for RouterPasswordNotifier with ≥85% coverage
- **FR-014**: Test suite MUST use Test Data Builder pattern for JNAP mock responses
- **FR-015**: System MUST pass architectural compliance checks (no JNAP models in provider layer)

### Key Entities

- **RouterPasswordService**: Stateless service that encapsulates all router password-related JNAP communication, password persistence (via FlutterSecureStorage), and data transformation logic
- **RouterPasswordNotifier**: State management notifier that coordinates user interactions and delegates all business logic and storage operations to RouterPasswordService
- **RouterPasswordState**: UI model representing router password configuration (isDefault, isSetByUser, adminPassword, hint, validation state)
- **RouterPasswordTestData**: Test Data Builder providing reusable JNAP mock responses for password operations

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All existing password management functionality continues to work without regression (validated through manual testing and existing integration tests)
- **SC-002**: RouterPasswordService achieves ≥90% test coverage with all JNAP operations tested in isolation
- **SC-003**: RouterPasswordNotifier achieves ≥85% test coverage with mocked service dependencies
- **SC-004**: Architectural compliance check passes: zero JNAP model imports found in `lib/page/instant_admin/providers/` directory
- **SC-005**: Code review confirms separation of concerns: service handles business logic, notifier handles state management
- **SC-006**: All unit tests execute in under 5 seconds (fast, deterministic tests with no network calls)

## Scope

### In Scope

- Extract all JNAP communication from RouterPasswordNotifier to new RouterPasswordService
- Refactor RouterPasswordNotifier to delegate to service layer
- Create comprehensive unit tests for both service and provider
- Create Test Data Builder for router password JNAP responses
- Maintain backward compatibility of public APIs
- Update code to comply with three-layer architecture

### Out of Scope

- UI changes or modifications to password management screens
- Changes to JNAP protocol or RouterRepository implementation
- Migration of other providers to service layer pattern (separate effort)
- Integration tests for password functionality (existing tests sufficient)
- Changes to FlutterSecureStorage implementation
- Authentication flow modifications beyond maintaining compatibility

## Assumptions

- RouterRepository interface remains stable during refactoring
- Existing integration tests adequately cover password functionality workflows
- FlutterSecureStorage operations can be mocked in unit tests
- JNAP protocol responses for password operations are well-documented and stable
- AuthService pattern established in `lib/providers/auth/` serves as reference implementation
- Constitution Article VI (Service Layer Principle) requirements are understood and accepted

## Dependencies

- Existing RouterRepository for JNAP communication (injected into service)
- FlutterSecureStorage for password persistence (injected into service)
- AuthProvider for authentication integration during password changes (accessed by notifier)
- Mocktail library for creating test mocks
- Test infrastructure and coverage tools

## Risk Assessment

### Technical Risks

- **Medium Risk**: Breaking existing password functionality during refactoring
  - *Mitigation*: Incremental refactoring with continuous testing, maintain existing integration tests

- **Low Risk**: Test coverage not meeting constitutional requirements
  - *Mitigation*: Follow Test Data Builder pattern, use coverage reports to track progress

### Project Risks

- **Low Risk**: Increased initial development time due to comprehensive testing
  - *Mitigation*: Investment in tests pays off through reduced maintenance burden and faster future changes
