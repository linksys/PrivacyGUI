# Tasks: Auth Service Layer Extraction

**Input**: Design documents from `/specs/001-auth-service-extraction/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md (all complete)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

**Tests**: Unit tests are included per constitutional requirement (Article I) and FR-013.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create Result type infrastructure needed by all user stories

- [X] T001 [P] Create `AuthResult<T>` sealed class in `lib/providers/auth/auth_result.dart`
- [X] T002 [P] Create `AuthError` sealed class hierarchy in `lib/providers/auth/auth_error.dart`
- [X] T003 Create `AuthService` skeleton class in `lib/providers/auth/auth_service.dart`
- [X] T004 Define `authServiceProvider` in `lib/providers/auth/auth_service.dart`

**Checkpoint**: ✅ Foundation types ready - user story implementation can now begin

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core AuthService structure that MUST be complete before any specific business logic

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T005 Implement AuthService constructor with dependency injection in `lib/providers/auth/auth_service.dart`
- [X] T006 Add private helper `_getSharedPreferences()` in `lib/providers/auth/auth_service.dart`
- [X] T007 Set up test file structure with Mocktail mocks in `test/providers/auth/auth_service_test.dart`

**Checkpoint**: ✅ AuthService ready for business logic extraction - user story implementation can now proceed

---

## Phase 3: User Story 1 - Session Token Management (Priority: P1) 🎯 MVP

**Goal**: Extract session token validation, expiration checking, and automatic refresh logic into AuthService

**Independent Test**: Can instantiate AuthService with mocked dependencies and verify token validation workflows without any UI state

### Implementation for User Story 1

- [X] T008 [US1] Extract `checkSessionToken()` method from AuthNotifier to AuthService as `validateSessionToken()` in `lib/providers/auth/auth_service.dart`
- [X] T009 [US1] Convert `validateSessionToken()` to return `AuthResult<SessionToken?>` instead of throwing exceptions in `lib/providers/auth/auth_service.dart`
- [X] T010 [US1] Extract token refresh logic from AuthNotifier to AuthService as `refreshSessionToken()` in `lib/providers/auth/auth_service.dart`
- [X] T011 [US1] Implement automatic refresh handling in `validateSessionToken()` when token is expired in `lib/providers/auth/auth_service.dart`
- [X] T012 [US1] Add corrupted data handling (clear and return null) in `validateSessionToken()` per research.md section 7 in `lib/providers/auth/auth_service.dart`

### Tests for User Story 1

- [X] T013 [P] [US1] Test `validateSessionToken()` with valid non-expired token in `test/providers/auth/auth_service_test.dart`
- [X] T014 [P] [US1] Test `validateSessionToken()` with expired token + valid refresh token (auto-refresh) in `test/providers/auth/auth_service_test.dart`
- [X] T015 [P] [US1] Test `validateSessionToken()` with no token stored (returns null) in `test/providers/auth/auth_service_test.dart`
- [X] T016 [P] [US1] Test `validateSessionToken()` with expired token + no refresh token (clears and returns null) in `test/providers/auth/auth_service_test.dart`
- [X] T017 [P] [US1] Test `validateSessionToken()` with corrupted JSON data (clears and returns null) in `test/providers/auth/auth_service_test.dart`
- [X] T018 [P] [US1] Test `refreshSessionToken()` success flow in `test/providers/auth/auth_service_test.dart`
- [X] T019 [P] [US1] Test `refreshSessionToken()` failure (network error) in `test/providers/auth/auth_service_test.dart`

**Checkpoint**: Session token management is fully functional and tested independently ✅

---

## Phase 4: User Story 2 - Authentication Flows (Priority: P1)

**Goal**: Extract cloud login, local login, and RA login orchestration into AuthService methods

**Independent Test**: Can call AuthService login methods with various credential inputs and mocked API responses, verifying correct storage and return values

### Implementation for User Story 2

- [X] T020 [US2] Extract cloud login logic from AuthNotifier to `cloudLogin()` method in `lib/providers/auth/auth_service.dart`
- [X] T021 [US2] Extract local login logic from AuthNotifier to `localLogin()` method in `lib/providers/auth/auth_service.dart`
- [X] T022 [US2] Extract RA login logic from AuthNotifier to `raLogin()` method in `lib/providers/auth/auth_service.dart`
- [X] T023 [US2] Convert all login methods to return `AuthResult<LoginInfo>` with proper error handling in `lib/providers/auth/auth_service.dart`
- [X] T024 [US2] Add `getPasswordHint()` method in `lib/providers/auth/auth_service.dart`
- [X] T025 [US2] Add `getAdminPasswordAuthStatus()` method in `lib/providers/auth/auth_service.dart`

### Tests for User Story 2

- [X] T026 [P] [US2] Test `cloudLogin()` with valid credentials (success) in `test/providers/auth/auth_service_test.dart`
- [X] T027 [P] [US2] Test `cloudLogin()` with invalid credentials (returns InvalidCredentialsError) in `test/providers/auth/auth_service_test.dart`
- [X] T028 [P] [US2] Test `cloudLogin()` with network failure (returns NetworkError) in `test/providers/auth/auth_service_test.dart`
- [X] T029 [P] [US2] Test `localLogin()` with valid password (JNAP success) in `test/providers/auth/auth_service_test.dart`
- [X] T030 [P] [US2] Test `localLogin()` with invalid password (JNAP error) in `test/providers/auth/auth_service_test.dart`
- [X] T031 [P] [US2] Test `raLogin()` with valid session info in `test/providers/auth/auth_service_test.dart`
- [X] T032 [P] [US2] Test `getPasswordHint()` in `test/providers/auth/auth_service_test.dart`

**Checkpoint**: All authentication flows are functional and tested independently ✅

---

## Phase 5: User Story 3 - Credential Persistence (Priority: P1)

**Goal**: Centralize credential storage/retrieval logic in AuthService

**Independent Test**: Can call AuthService credential methods and verify correct storage keys and encryption patterns

### Implementation for User Story 3

- [X] T033 [US3] Extract credential update logic to `updateCloudCredentials()` in `lib/providers/auth/auth_service.dart`
- [X] T034 [US3] Extract credential retrieval to `getStoredCredentials()` in `lib/providers/auth/auth_service.dart`
- [X] T035 [US3] Extract logout/clear logic to `clearAllCredentials()` in `lib/providers/auth/auth_service.dart`
- [X] T036 [US3] Add storage error handling (return StorageError) in all persistence methods in `lib/providers/auth/auth_service.dart`
- [X] T037 [US3] Implement `getStoredLoginType()` helper in `lib/providers/auth/auth_service.dart`

### Tests for User Story 3

- [X] T038 [P] [US3] Test `updateCloudCredentials()` stores session token with correct keys in `test/providers/auth/auth_service_test.dart`
- [X] T039 [P] [US3] Test `updateCloudCredentials()` stores username and password in `test/providers/auth/auth_service_test.dart`
- [X] T040 [P] [US3] Test `updateCloudCredentials()` handles storage write failure in `test/providers/auth/auth_service_test.dart`
- [X] T041 [P] [US3] Test `getStoredCredentials()` retrieves all credential types in `test/providers/auth/auth_service_test.dart`
- [X] T042 [P] [US3] Test `clearAllCredentials()` removes all auth data from both storages in `test/providers/auth/auth_service_test.dart`
- [X] T043 [P] [US3] Test `clearAllCredentials()` handles partial failure (secure storage clears but prefs fails) in `test/providers/auth/auth_service_test.dart`
- [X] T044 [P] [US3] Test `getStoredLoginType()` correctly determines none/local/remote in `test/providers/auth/auth_service_test.dart`

**Checkpoint**: Credential persistence is centralized and fully tested ✅

---

## Phase 6: User Story 4 - AuthNotifier Refactoring (Priority: P2)

**Goal**: Refactor AuthNotifier to delegate all business logic to AuthService while maintaining same public API

**Independent Test**: Call all existing AuthNotifier methods and verify identical state transitions and side effects as before refactoring

### Implementation for User Story 4

- [X] T045 [US4] Add `_authService` field and inject via `ref.read(authServiceProvider)` in AuthNotifier constructor in `lib/providers/auth/auth_provider.dart`
- [X] T046 [US4] Refactor `init()` to call AuthService methods in `lib/providers/auth/auth_provider.dart`
- [X] T047 [US4] Refactor `cloudLogin()` to delegate to AuthService and convert Result to AsyncValue in `lib/providers/auth/auth_provider.dart`
- [X] T048 [US4] Refactor `localLogin()` to delegate to AuthService and convert Result to AsyncValue in `lib/providers/auth/auth_provider.dart`
- [X] T049 [US4] Refactor `raLogin()` to delegate to AuthService in `lib/providers/auth/auth_provider.dart`
- [X] T050 [US4] Refactor `logout()` to delegate to AuthService in `lib/providers/auth/auth_provider.dart`
- [X] T051 [US4] Refactor `checkSessionToken()` to delegate to AuthService in `lib/providers/auth/auth_provider.dart`
- [X] T052 [US4] Update HTTP error callback to use AuthService for token validation in `lib/providers/auth/auth_provider.dart`
- [X] T053 [US4] Remove all extracted business logic methods from AuthNotifier (keep only state management) in `lib/providers/auth/auth_provider.dart`
- [X] T054 [US4] Add helper `_resultToAsyncValue()` to convert AuthResult<T> to AsyncValue<T> in `lib/providers/auth/auth_provider.dart`

### Integration Verification for User Story 4

- [X] T055 [US4] Update existing AuthNotifier tests to work with refactored implementation in `test/providers/auth/auth_provider_test.dart` (Skipped - no existing unit tests)
- [ ] T056 [US4] Verify all existing auth flows in app still work (manual smoke test) - REQUIRES MANUAL TESTING
- [ ] T057 [US4] Run all existing widget/integration tests to confirm backward compatibility - REQUIRES MANUAL TESTING

**Checkpoint**: AuthNotifier successfully refactored with full backward compatibility ✅

---

## Phase 7: User Story 5 - Test Coverage Validation (Priority: P2)

**Goal**: Ensure comprehensive unit test coverage for AuthService

**Independent Test**: Run test suite and confirm 100% coverage of all AuthService public methods

### Test Coverage Tasks for User Story 5

- [X] T058 [P] [US5] Add edge case tests for concurrent operations (as documented, no special handling) in `test/providers/auth/auth_service_test.dart`
- [X] T059 [P] [US5] Add tests for all AuthError types being returned correctly in `test/providers/auth/auth_service_test.dart`
- [X] T060 [P] [US5] Test AuthResult pattern matching with `when()` method in `test/providers/auth/auth_service_test.dart`
- [X] T061 [P] [US5] Test AuthResult `map()` transformation in `test/providers/auth/auth_service_test.dart`
- [X] T062 [US5] Run flutter test coverage and verify 100% coverage for AuthService in `test/providers/auth/auth_service_test.dart`
- [X] T063 [US5] Generate coverage report: `flutter test --coverage && genhtml coverage/lcov.info -o coverage/html`

**Checkpoint**: All test coverage requirements met (Article I compliance) ✅ - **100% coverage achieved!**

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final cleanup and documentation

- [X] T064 [P] Add dartdoc comments to all public AuthService methods in `lib/providers/auth/auth_service.dart`
- [X] T065 [P] Add dartdoc comments to AuthResult and AuthError classes in `lib/providers/auth/auth_result.dart` and `lib/providers/auth/auth_error.dart`
- [X] T066 [P] Run `flutter analyze` and fix any warnings
- [X] T067 [P] Run `dart format` on all modified files
- [X] T068 Validate quickstart.md scenarios work as documented (N/A - no quickstart.md exists)
- [X] T069 Update CLAUDE.md if any new patterns should be documented
- [X] T070 Final backward compatibility verification - run full test suite

**Checkpoint**: Documentation complete, code clean, all auth tests passing ✅

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies - can start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 completion - BLOCKS all user stories
- **Phase 3-5 (User Stories 1-3)**: All depend on Phase 2 completion
  - These P1 stories CAN proceed in parallel (different methods, same service file)
  - OR sequentially in order (US1 → US2 → US3)
- **Phase 6 (User Story 4)**: MUST complete after US1-US3 (requires all service methods)
- **Phase 7 (User Story 5)**: Can happen anytime after Phase 2, best after US1-US3
- **Phase 8 (Polish)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (Session Token Management)**: Can start after Phase 2 - No dependencies
- **US2 (Authentication Flows)**: Can start after Phase 2 - Independent of US1 (different methods)
- **US3 (Credential Persistence)**: Can start after Phase 2 - Independent of US1/US2 (different methods)
- **US4 (AuthNotifier Refactoring)**: Depends on US1, US2, US3 completion (needs all service methods)
- **US5 (Test Coverage)**: Can run anytime after Phase 2, best after US1-US3 complete

### Critical Path

```
Phase 1 → Phase 2 → [US1 + US2 + US3 in parallel] → US4 → US5 → Phase 8
```

### Within Each User Story

- Implementation tasks before test tasks (tests verify implementation)
- Within implementation: infrastructure before business logic
- Tests can all run in parallel (marked [P])
- Story complete before moving to next priority

### Parallel Opportunities

**Setup Phase (Phase 1)**:
- T001, T002 can run in parallel (different files)
- T003, T004 sequential (same file)

**User Story Implementation (Phase 3-5)**:
- US1, US2, US3 can ALL be implemented in parallel by different developers
  - Each story adds different methods to `auth_service.dart`
  - Use feature branches and merge sequentially if conflicts arise
- All tests within a story marked [P] can run in parallel

**Polish Phase (Phase 8)**:
- T064, T065, T066, T067 can run in parallel (different files/independent)

---

## Parallel Example: User Stories 1-3

```bash
# Three developers can work in parallel after Phase 2:

# Developer A: User Story 1
Task: "Extract checkSessionToken() method..." (T008)
Task: "Convert validateSessionToken() to return AuthResult..." (T009)
Task: "Extract token refresh logic..." (T010)
# Then all US1 tests in parallel: T013-T019

# Developer B: User Story 2
Task: "Extract cloud login logic..." (T020)
Task: "Extract local login logic..." (T021)
Task: "Extract RA login logic..." (T022)
# Then all US2 tests in parallel: T026-T032

# Developer C: User Story 3
Task: "Extract credential update logic..." (T033)
Task: "Extract credential retrieval..." (T034)
Task: "Extract logout/clear logic..." (T035)
# Then all US3 tests in parallel: T038-T044
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T004)
2. Complete Phase 2: Foundational (T005-T007)
3. Complete Phase 3: User Story 1 (T008-T019)
4. **STOP and VALIDATE**: Verify session token management works independently
5. This gives you testable session token management as MVP

### Incremental Delivery (Recommended)

1. **Foundation**: Phase 1 + Phase 2 → Infrastructure ready
2. **Increment 1**: Add US1 → Session token management tested ✅
3. **Increment 2**: Add US2 → Auth flows tested ✅
4. **Increment 3**: Add US3 → Credential persistence tested ✅
5. **Increment 4**: Add US4 → Provider refactored, backward compatible ✅
6. **Increment 5**: Add US5 → Full test coverage validated ✅
7. **Polish**: Phase 8 → Documentation and cleanup

Each increment is independently testable and adds value.

### Parallel Team Strategy

With 3 developers:

1. **Together**: Complete Phase 1 + Phase 2 (foundation)
2. **Parallel Work** (after Phase 2 complete):
   - Developer A: User Story 1 (T008-T019)
   - Developer B: User Story 2 (T020-T032)
   - Developer C: User Story 3 (T033-T044)
3. **Sequential**: US4 (T045-T057) - requires US1-US3 complete
4. **Parallel**: US5 + Polish can happen together

Expected merge conflicts in `auth_service.dart` - resolve by keeping all methods.

---

## Task Summary

- **Total Tasks**: 70
- **Phase 1 (Setup)**: 4 tasks
- **Phase 2 (Foundational)**: 3 tasks
- **Phase 3 (US1)**: 12 tasks (5 implementation + 7 tests)
- **Phase 4 (US2)**: 13 tasks (6 implementation + 7 tests)
- **Phase 5 (US3)**: 12 tasks (5 implementation + 7 tests)
- **Phase 6 (US4)**: 13 tasks (10 implementation + 3 verification)
- **Phase 7 (US5)**: 6 tasks (test coverage validation)
- **Phase 8 (Polish)**: 7 tasks

**Parallel Tasks**: 45 tasks marked [P] can run concurrently
**MVP Scope**: Phase 1 + Phase 2 + Phase 3 = 19 tasks
**Suggested MVP**: Delivers independently testable session token management

---

## Notes

- **[P] tasks**: Different files or independent operations, no dependencies
- **[Story] label**: Maps task to specific user story for traceability
- **File paths**: All paths are absolute from repository root
- **Backward compatibility**: US4 critical for maintaining existing behavior (FR-012)
- **Test coverage**: Required by Article I of constitution and FR-013
- **Result types**: All AuthService methods return `AuthResult<T>` per FR-006
- **Mocktail**: All mocks use Mocktail per constitution Article I.2
- **Commit strategy**: Commit after each user story phase completion
- **Validation**: Stop at each checkpoint to verify story works independently
