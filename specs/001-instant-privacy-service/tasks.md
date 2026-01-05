# Tasks: Extract InstantPrivacyService

**Input**: Design documents from `/specs/001-instant-privacy-service/`
**Prerequisites**: plan.md (complete), spec.md (complete), research.md, data-model.md, contracts/

**Tests**: Required per constitution.md Article I (Service ≥90%, Provider ≥85%)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **Source**: `lib/page/instant_privacy/`
- **Tests**: `test/page/instant_privacy/`
- **Test Data**: `test/mocks/test_data/`

---

## Phase 1: Setup

**Purpose**: Create directory structure and test infrastructure

- [x] T001 Create services directory at `lib/page/instant_privacy/services/`
- [x] T002 Create services test directory at `test/page/instant_privacy/services/`
- [x] T003 [P] Create test data builder file at `test/mocks/test_data/instant_privacy_test_data.dart` with InstantPrivacyTestData class stub

---

## Phase 2: Foundational (Test Data Builder)

**Purpose**: Create test data infrastructure that all service tests depend on

**⚠️ CRITICAL**: Service tests cannot be written until this phase is complete

- [x] T004 Implement `createMacFilterSettingsSuccess()` in `test/mocks/test_data/instant_privacy_test_data.dart` - returns JNAPSuccess with configurable macFilterMode, maxMacAddresses, macAddresses
- [x] T005 [P] Implement `createStaBssidsSuccess()` in `test/mocks/test_data/instant_privacy_test_data.dart` - returns JNAPSuccess with staBSSIDS list
- [x] T006 [P] Implement `createLocalDeviceSuccess()` in `test/mocks/test_data/instant_privacy_test_data.dart` - returns JNAPSuccess with deviceID

**Checkpoint**: Test data builder ready - service tests can now be written

---

## Phase 3: User Story 2 - Service Handles JNAP Communication (Priority: P1) 🎯 MVP

**Goal**: Create InstantPrivacyService with all JNAP communication methods

**Independent Test**: Run `flutter test test/page/instant_privacy/services/` - all service unit tests pass

### Tests for User Story 2

> **NOTE: Write tests FIRST, ensure they FAIL before implementation**

- [ ] T007 [P] [US2] Create test file `test/page/instant_privacy/services/instant_privacy_service_test.dart` with MockRouterRepository setup
- [ ] T008 [P] [US2] Write test: fetchMacFilterSettings returns settings and status on success in `test/page/instant_privacy/services/instant_privacy_service_test.dart`
- [ ] T009 [P] [US2] Write test: fetchMacFilterSettings returns only status when updateStatusOnly=true in `test/page/instant_privacy/services/instant_privacy_service_test.dart`
- [ ] T010 [P] [US2] Write test: fetchMacFilterSettings correctly splits macAddresses by mode (allow vs deny) in `test/page/instant_privacy/services/instant_privacy_service_test.dart`
- [ ] T011 [P] [US2] Write test: saveMacFilterSettings transforms settings to JNAP format in `test/page/instant_privacy/services/instant_privacy_service_test.dart`
- [ ] T012 [P] [US2] Write test: saveMacFilterSettings merges nodesMacAddresses for allow mode in `test/page/instant_privacy/services/instant_privacy_service_test.dart`
- [ ] T013 [P] [US2] Write test: fetchStaBssids returns empty list when not supported in `test/page/instant_privacy/services/instant_privacy_service_test.dart`
- [ ] T014 [P] [US2] Write test: fetchMyMacAddress returns MAC from device list in `test/page/instant_privacy/services/instant_privacy_service_test.dart`
- [ ] T015 [P] [US2] Write test: fetchMyMacAddress returns null when device not found in `test/page/instant_privacy/services/instant_privacy_service_test.dart`

### Implementation for User Story 2

- [ ] T016 [US2] Create `lib/page/instant_privacy/services/instant_privacy_service.dart` with class stub, provider definition, and RouterRepository injection
- [ ] T017 [US2] Implement `fetchMacFilterSettings()` method in `lib/page/instant_privacy/services/instant_privacy_service.dart` per contract
- [ ] T018 [US2] Implement `saveMacFilterSettings()` method in `lib/page/instant_privacy/services/instant_privacy_service.dart` per contract
- [ ] T019 [US2] Implement `fetchStaBssids()` method in `lib/page/instant_privacy/services/instant_privacy_service.dart` per contract
- [ ] T020 [US2] Implement `fetchMyMacAddress()` method in `lib/page/instant_privacy/services/instant_privacy_service.dart` per contract
- [ ] T021 [US2] Run service tests and verify ≥90% coverage: `flutter test test/page/instant_privacy/services/`

**Checkpoint**: InstantPrivacyService complete with all JNAP methods and tests passing

---

## Phase 4: User Story 3 - Error Handling Follows ServiceError Pattern (Priority: P2)

**Goal**: Service converts all JNAPError to ServiceError

**Independent Test**: Error handling tests in service test file pass; no JNAPError leaks to caller

### Tests for User Story 3

- [ ] T022 [P] [US3] Write test: fetchMacFilterSettings throws ServiceError (not JNAPError) on JNAP failure in `test/page/instant_privacy/services/instant_privacy_service_test.dart`
- [ ] T023 [P] [US3] Write test: saveMacFilterSettings throws ServiceError on JNAP failure in `test/page/instant_privacy/services/instant_privacy_service_test.dart`

### Implementation for User Story 3

- [ ] T024 [US3] Add `_mapJnapError()` helper method in `lib/page/instant_privacy/services/instant_privacy_service.dart`
- [ ] T025 [US3] Add try-catch with JNAPError → ServiceError mapping to all public methods in `lib/page/instant_privacy/services/instant_privacy_service.dart`
- [ ] T026 [US3] Run error handling tests: `flutter test test/page/instant_privacy/services/ --name="error"`

**Checkpoint**: Service error handling complete - all errors converted to ServiceError

---

## Phase 5: User Story 1 - Developer Maintains Architecture Compliance (Priority: P1)

**Goal**: Refactor InstantPrivacyNotifier to delegate to Service, removing JNAP imports

**Independent Test**: `grep -r "import.*jnap/models" lib/page/instant_privacy/providers/` returns no results

### Tests for User Story 1

- [ ] T027 [P] [US1] Update provider test file to mock InstantPrivacyService instead of RouterRepository in `test/page/instant_privacy/providers/instant_privacy_provider_test.dart`
- [ ] T028 [P] [US1] Write test: performFetch delegates to service.fetchMacFilterSettings() in `test/page/instant_privacy/providers/instant_privacy_provider_test.dart`
- [ ] T029 [P] [US1] Write test: performSave delegates to service.saveMacFilterSettings() in `test/page/instant_privacy/providers/instant_privacy_provider_test.dart`

### Implementation for User Story 1

- [ ] T030 [US1] Add import for InstantPrivacyService in `lib/page/instant_privacy/providers/instant_privacy_provider.dart`
- [ ] T031 [US1] Refactor `performFetch()` to delegate to service in `lib/page/instant_privacy/providers/instant_privacy_provider.dart`
- [ ] T032 [US1] Refactor `performSave()` to delegate to service in `lib/page/instant_privacy/providers/instant_privacy_provider.dart`
- [ ] T033 [US1] Refactor `getMyMACAddress()` to delegate to service in `lib/page/instant_privacy/providers/instant_privacy_provider.dart`
- [ ] T034 [US1] Remove JNAP imports (jnap/models, jnap/actions, jnap/command, router_repository) from `lib/page/instant_privacy/providers/instant_privacy_provider.dart`
- [ ] T035 [US1] Run architecture compliance check: `grep -r "import.*jnap/models" lib/page/instant_privacy/providers/`
- [ ] T036 [US1] Run architecture compliance check: `grep -r "import.*jnap/actions" lib/page/instant_privacy/providers/`
- [ ] T037 [US1] Run provider tests: `flutter test test/page/instant_privacy/providers/`

**Checkpoint**: Provider fully delegates to Service - architecture compliant

---

## Phase 6: User Story 4 - Existing Functionality Preserved (Priority: P1)

**Goal**: Verify all existing functionality works identically after refactoring

**Independent Test**: All existing InstantPrivacy tests pass; manual verification of MAC filter operations

### Verification for User Story 4

- [ ] T038 [US4] Run all existing InstantPrivacy tests: `flutter test test/page/instant_privacy/`
- [ ] T039 [US4] Run full test suite to check for regressions: `flutter test`
- [ ] T040 [US4] Verify analyzer passes: `flutter analyze lib/page/instant_privacy/`

**Checkpoint**: All existing functionality preserved - refactoring complete

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final cleanup and documentation

- [ ] T041 [P] Run dart format on all modified files: `dart format lib/page/instant_privacy/ test/page/instant_privacy/`
- [ ] T042 Verify test coverage meets requirements: Service ≥90%, Provider ≥85%
- [ ] T043 Final architecture compliance verification: run all SC-001 through SC-007 checks from spec.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS service tests
- **US2 Service (Phase 3)**: Depends on Foundational - core service implementation
- **US3 Error Handling (Phase 4)**: Depends on US2 - adds error handling to service
- **US1 Provider Refactor (Phase 5)**: Depends on US2, US3 - needs complete service
- **US4 Verification (Phase 6)**: Depends on US1 - verifies complete refactoring
- **Polish (Phase 7)**: Depends on all user stories complete

### User Story Dependencies

- **User Story 2 (Service)**: No story dependencies - creates the service
- **User Story 3 (Errors)**: Depends on US2 - adds error handling to existing service
- **User Story 1 (Provider)**: Depends on US2, US3 - needs complete service to delegate to
- **User Story 4 (Verify)**: Depends on US1 - verifies the refactored system

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Implementation follows test failures
- Run story-specific tests to verify completion
- Checkpoint validation before moving to next story

### Parallel Opportunities

**Phase 2 - Foundational**: T004, T005, T006 can run in parallel (different methods)

**Phase 3 - US2 Tests**: T007-T015 can all run in parallel (same file, different tests)

**Phase 3 - US2 Implementation**: T017-T020 can run in parallel after T016 creates the class

**Phase 4 - US3 Tests**: T022, T023 can run in parallel

**Phase 5 - US1 Tests**: T027-T029 can run in parallel

---

## Parallel Example: User Story 2 Tests

```bash
# Launch all US2 tests in parallel (same file, different test methods):
Task: T008 - fetchMacFilterSettings returns settings and status
Task: T009 - fetchMacFilterSettings updateStatusOnly behavior
Task: T010 - fetchMacFilterSettings mode splitting
Task: T011 - saveMacFilterSettings transformation
Task: T012 - saveMacFilterSettings merging
Task: T013 - fetchStaBssids graceful failure
Task: T014 - fetchMyMacAddress success
Task: T015 - fetchMyMacAddress null case
```

---

## Implementation Strategy

### MVP First (User Story 2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (test data builder)
3. Complete Phase 3: User Story 2 (Service implementation)
4. **STOP and VALIDATE**: Service tests pass with ≥90% coverage
5. Service is now independently usable

### Incremental Delivery

1. Setup + Foundational → Test infrastructure ready
2. US2 (Service) → Core service complete → Can test service in isolation
3. US3 (Errors) → Error handling complete → Service is production-ready
4. US1 (Provider) → Architecture compliant → Full integration
5. US4 (Verify) → Regression-free → Ready for merge

### Recommended Execution

For this refactoring, sequential execution is recommended:
- US2 and US3 could theoretically be done together but US3 modifies US2's code
- US1 requires complete service (US2 + US3)
- US4 is pure verification after US1

---

## Notes

- [P] tasks = different files OR independent test methods, no dependencies
- [Story] label maps task to specific user story for traceability
- This is a refactoring - existing tests MUST continue to pass
- Commit after each phase completion
- Stop at any checkpoint to validate story independently
- Architecture compliance checks are critical success criteria
