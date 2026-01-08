# Tasks: AutoParentFirstLogin Service Extraction

**Input**: Design documents from `/specs/001-auto-parent-login-service/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Required per constitution.md Article I (Service ≥90%, Provider ≥85%, State ≥90%)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Source**: `lib/page/login/auto_parent/`
- **Tests**: `test/page/login/auto_parent/`
- **Test Data**: `test/mocks/test_data/`

---

## Phase 1: Setup

**Purpose**: Create directory structure and test data builder

- [x] T001 Create services directory at `lib/page/login/auto_parent/services/`
- [x] T002 Create test services directory at `test/page/login/auto_parent/services/`
- [x] T003 [P] Create test data builder at `test/mocks/test_data/auto_parent_first_login_test_data.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: None required - existing infrastructure (RouterRepository, ServiceError, retry strategy) is already in place

**⚠️ CRITICAL**: This refactoring uses existing foundational components. No new foundational work needed.

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Service Layer Extraction (Priority: P1) 🎯 MVP

**Goal**: Create `AutoParentFirstLoginService` with three JNAP methods extracted from the Notifier

**Independent Test**: Service tests pass with mocked RouterRepository; Service correctly calls JNAP actions and returns expected results

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T004 [P] [US1] Create Service test file at `test/page/login/auto_parent/services/auto_parent_first_login_service_test.dart`
- [x] T005 [P] [US1] Write test: `setUserAcknowledgedAutoConfiguration sends JNAP action and awaits response`
- [x] T006 [P] [US1] Write test: `setFirmwareUpdatePolicy fetches settings and sets auto-update policy`
- [x] T007 [P] [US1] Write test: `setFirmwareUpdatePolicy uses default settings on fetch failure`
- [x] T008 [P] [US1] Write test: `checkInternetConnection returns true when connected`
- [x] T009 [P] [US1] Write test: `checkInternetConnection returns false after retries exhausted`
- [x] T010 [P] [US1] Write test: `checkInternetConnection returns false on error`

### Implementation for User Story 1

- [x] T011 [US1] Create Service class and provider at `lib/page/login/auto_parent/services/auto_parent_first_login_service.dart`
- [x] T012 [US1] Implement `autoParentFirstLoginServiceProvider` with RouterRepository injection
- [x] T013 [US1] Implement `setUserAcknowledgedAutoConfiguration()` method with await
- [x] T014 [US1] Implement `setFirmwareUpdatePolicy()` method with GET/SET and fallback logic
- [x] T015 [US1] Implement `checkInternetConnection()` method with retry strategy
- [x] T016 [US1] Verify all Service tests pass

**Checkpoint**: Service layer complete and independently testable

---

## Phase 4: User Story 2 - Error Handling Compliance (Priority: P2)

**Goal**: Ensure Service catches `JNAPError` and converts to `ServiceError`

**Independent Test**: Service throws `ServiceError` (not `JNAPError`) on JNAP failures; `checkInternetConnection` returns false instead of throwing

### Tests for User Story 2

- [x] T017 [P] [US2] Write test: `setUserAcknowledgedAutoConfiguration throws ServiceError on JNAPError`
- [x] T018 [P] [US2] Write test: `setFirmwareUpdatePolicy throws ServiceError on save failure`
- [x] T019 [P] [US2] Write test: `checkInternetConnection does not throw on JNAPError`

### Implementation for User Story 2

- [x] T020 [US2] Add error handling to `setUserAcknowledgedAutoConfiguration()` using `mapJnapErrorToServiceError()`
- [x] T021 [US2] Add error handling to `setFirmwareUpdatePolicy()` using `mapJnapErrorToServiceError()`
- [x] T022 [US2] Verify error handling in `checkInternetConnection()` returns false on errors
- [x] T023 [US2] Verify all error handling tests pass

**Checkpoint**: Error handling complete and compliant with Article XIII

---

## Phase 5: User Story 3 - Provider Refactoring (Priority: P3)

**Goal**: Refactor `AutoParentFirstLoginNotifier` to delegate to Service and remove JNAP imports

**Independent Test**: Provider tests pass with mocked Service; Provider imports contain no `jnap/models`, `jnap/actions`, or `jnap/command`

### Tests for User Story 3

- [x] T024 [P] [US3] Create/Update Provider test file at `test/page/login/auto_parent/providers/auto_parent_first_login_provider_test.dart`
- [x] T025 [P] [US3] Write test: `finishFirstTimeLogin delegates to Service methods`
- [x] T026 [P] [US3] Write test: `finishFirstTimeLogin awaits setUserAcknowledgedAutoConfiguration`
- [x] T027 [P] [US3] Write test: `finishFirstTimeLogin awaits setFirmwareUpdatePolicy`
- [x] T028 [P] [US3] Write test: `finishFirstTimeLogin skips acknowledgment when failCheck is true`

### Tests for State (Required)

- [x] T029 [P] [US3] Create State test file at `test/page/login/auto_parent/providers/auto_parent_first_login_state_test.dart`
- [x] T030 [P] [US3] Write test: `AutoParentFirstLoginState equality and props`

### Implementation for User Story 3

- [x] T031 [US3] Refactor `AutoParentFirstLoginNotifier` at `lib/page/login/auto_parent/providers/auto_parent_first_login_provider.dart`:
  - Remove imports from `jnap/models/`, `jnap/actions/`, `jnap/command/`
  - Remove `routerRepositoryProvider` usage
  - Add import for `auto_parent_first_login_service.dart`
  - Update `finishFirstTimeLogin()` to use Service
- [x] T032 [US3] Update `setUserAcknowledgedAutoConfiguration` call to await
- [x] T033 [US3] Verify all Provider tests pass
- [x] T034 [US3] Verify all State tests pass

**Checkpoint**: Provider refactored and architecture compliant

---

## Phase 6: Polish & Validation

**Purpose**: Final verification and cleanup

- [x] T035 Run architecture compliance check: `grep -r "import.*jnap/models" lib/page/login/auto_parent/providers/` returns 0 results
- [x] T036 Run architecture compliance check: `grep -r "import.*jnap/actions" lib/page/login/auto_parent/providers/` returns 0 results
- [x] T037 Run architecture compliance check: `grep -r "import.*jnap/command" lib/page/login/auto_parent/providers/` returns 0 results
- [x] T038 Run `flutter analyze lib/page/login/auto_parent/` with no errors
- [x] T039 Run all tests: `flutter test test/page/login/auto_parent/` (Service & Provider tests pass; golden tests pre-existing failures)
- [x] T040 Verify test coverage meets requirements (Service ≥90%, Provider ≥85%)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: N/A - uses existing infrastructure
- **User Story 1 (Phase 3)**: Depends on Setup (T001-T003)
- **User Story 2 (Phase 4)**: Depends on User Story 1 completion (T016)
- **User Story 3 (Phase 5)**: Depends on User Story 2 completion (T023)
- **Polish (Phase 6)**: Depends on all user stories complete (T034)

### User Story Dependencies

```
US1 (Service Creation) → US2 (Error Handling) → US3 (Provider Refactoring)
```

**Note**: These stories are **sequential** because:
- US2 adds error handling to methods created in US1
- US3 refactors Provider to use Service from US1/US2

### Within Each User Story

1. Tests MUST be written and FAIL before implementation
2. Implementation follows test order
3. All tests MUST pass before moving to next story

### Parallel Opportunities

**Phase 1 (Setup)**:
- T003 can run in parallel with T001, T002

**Phase 3 (US1 Tests)**:
- T004-T010 can ALL run in parallel (different test cases, same file)

**Phase 4 (US2 Tests)**:
- T017-T019 can ALL run in parallel

**Phase 5 (US3 Tests)**:
- T024-T030 can ALL run in parallel (different test files)

---

## Parallel Example: User Story 1 Tests

```bash
# Launch all tests for US1 together:
Task: T004 - Create test file
Task: T005 - Test setUserAcknowledgedAutoConfiguration
Task: T006 - Test setFirmwareUpdatePolicy success
Task: T007 - Test setFirmwareUpdatePolicy fallback
Task: T008 - Test checkInternetConnection connected
Task: T009 - Test checkInternetConnection retries
Task: T010 - Test checkInternetConnection error
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 3: User Story 1 (T004-T016)
3. **STOP and VALIDATE**: Service tests pass, methods work correctly
4. Continue to US2 and US3

### Full Implementation

1. Setup (T001-T003) → ~5 min
2. US1: Service Creation (T004-T016) → ~30 min
3. US2: Error Handling (T017-T023) → ~15 min
4. US3: Provider Refactoring (T024-T034) → ~20 min
5. Polish & Validation (T035-T040) → ~10 min

**Total Tasks**: 40
**Estimated Time**: ~80 min

---

## Notes

- [P] tasks = different files or independent test cases
- All JNAP operations MUST be awaited (updated from original fire-and-forget)
- `AutoParentFirstLoginState` MUST have tests even though unchanged
- Commit after each phase completion
- Run `flutter analyze` frequently during implementation
