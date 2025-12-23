# Tasks: Instant Admin Service Extraction

**Input**: Design documents from `/specs/003-instant-admin-service/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Unit tests are REQUIRED per spec.md FR-010 (≥90% coverage for both services)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions (Flutter Project)

- **Source**: `lib/page/instant_admin/services/`, `lib/page/instant_admin/providers/`
- **Tests**: `test/page/instant_admin/services/`, `test/mocks/test_data/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Test data builder and shared test utilities

- [ ] T001 Create test data builder file `test/mocks/test_data/instant_admin_test_data.dart` with class skeleton
- [ ] T002 Add timezone test data factory methods to `InstantAdminTestData` class (createGetTimeSettingsSuccess, createGetTimeSettingsError)
- [ ] T003 [P] Add power table test data factory methods to `InstantAdminTestData` class (createGetPowerTableSettingsSuccess, createPollingDataWithPowerTable)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Verify existing infrastructure supports the refactoring

**⚠️ CRITICAL**: Verify these before proceeding with service implementation

- [ ] T004 Verify `mapJnapErrorToServiceError` helper exists in `lib/core/errors/jnap_error_mapper.dart`
- [ ] T005 [P] Verify existing `RouterPasswordService` pattern in `lib/page/instant_admin/services/router_password_service.dart` as reference
- [ ] T006 [P] Create test directory structure `test/page/instant_admin/services/` if not exists

**Checkpoint**: Foundation ready - service implementation can now begin

---

## Phase 3: User Story 1 - TimezoneService (Priority: P1) 🎯 MVP

**Goal**: Extract JNAP communication from TimezoneNotifier into TimezoneService

**Independent Test**: Unit tests for TimezoneService that mock RouterRepository, verifying JNAP data transformation

### Tests for User Story 1

> **NOTE: Write tests FIRST, ensure they FAIL before implementation**

- [ ] T007 [US1] Create test file `test/page/instant_admin/services/timezone_service_test.dart` with imports and mock setup
- [ ] T008 [US1] Add test group "TimezoneService - fetchTimezoneSettings" with success case test
- [ ] T009 [P] [US1] Add test for fetchTimezoneSettings sorts timezones by UTC offset
- [ ] T010 [P] [US1] Add test for fetchTimezoneSettings throws ServiceError on JNAP failure
- [ ] T011 [US1] Add test group "TimezoneService - saveTimezoneSettings" with success case test
- [ ] T012 [P] [US1] Add test for saveTimezoneSettings handles DST for non-DST timezones
- [ ] T013 [P] [US1] Add test for saveTimezoneSettings throws ServiceError on JNAP failure

### Implementation for User Story 1

- [ ] T014 [US1] Create `lib/page/instant_admin/services/timezone_service.dart` with class skeleton and provider definition
- [ ] T015 [US1] Implement `fetchTimezoneSettings()` method - JNAP call, response parsing, model transformation
- [ ] T016 [US1] Implement `saveTimezoneSettings()` method - DST validation, JNAP payload construction, error handling
- [ ] T017 [US1] Add DartDoc documentation for all public methods
- [ ] T018 [US1] Run tests and verify ≥90% coverage for TimezoneService

**Checkpoint**: TimezoneService complete and tested independently

---

## Phase 4: User Story 2 - PowerTableService (Priority: P1)

**Goal**: Extract JNAP communication from PowerTableNotifier into PowerTableService

**Independent Test**: Unit tests for PowerTableService that mock RouterRepository, verifying country data transformation

### Tests for User Story 2

- [ ] T019 [US2] Create test file `test/page/instant_admin/services/power_table_service_test.dart` with imports and mock setup
- [ ] T020 [US2] Add test group "PowerTableService - parsePowerTableSettings" with success case test
- [ ] T021 [P] [US2] Add test for parsePowerTableSettings returns null when data missing
- [ ] T022 [P] [US2] Add test for parsePowerTableSettings resolves country codes correctly
- [ ] T023 [P] [US2] Add test for parsePowerTableSettings sorts countries by index
- [ ] T024 [P] [US2] Add test for parsePowerTableSettings handles non-selectable state
- [ ] T025 [US2] Add test group "PowerTableService - savePowerTableCountry" with success case test
- [ ] T026 [P] [US2] Add test for savePowerTableCountry throws ServiceError on JNAP failure

### Implementation for User Story 2

- [ ] T027 [US2] Create `lib/page/instant_admin/services/power_table_service.dart` with class skeleton and provider definition
- [ ] T028 [US2] Implement `parsePowerTableSettings()` method - polling data extraction, model transformation
- [ ] T029 [US2] Implement `savePowerTableCountry()` method - JNAP payload construction, error handling
- [ ] T030 [US2] Add DartDoc documentation for all public methods
- [ ] T031 [US2] Run tests and verify ≥90% coverage for PowerTableService

**Checkpoint**: Both services complete and tested independently

---

## Phase 5: User Story 3 - Provider Refactoring (Priority: P2)

**Goal**: Refactor existing providers to use new services, ensuring architecture compliance

**Independent Test**: Verify providers no longer import `jnap/models` or `jnap/result`

### Implementation for User Story 3

- [ ] T032 [US3] Refactor `lib/page/instant_admin/providers/timezone_provider.dart` - remove JNAP imports, inject TimezoneService
- [ ] T033 [US3] Update `TimezoneNotifier.performFetch()` to delegate to `TimezoneService.fetchTimezoneSettings()`
- [ ] T034 [US3] Update `TimezoneNotifier.performSave()` to delegate to `TimezoneService.saveTimezoneSettings()`
- [ ] T035 [US3] Refactor `lib/page/instant_admin/providers/power_table_provider.dart` - remove JNAP imports, inject PowerTableService
- [ ] T036 [US3] Update `PowerTableNotifier.build()` to use `PowerTableService.parsePowerTableSettings()`
- [ ] T037 [US3] Update `PowerTableNotifier.save()` to delegate to `PowerTableService.savePowerTableCountry()`
- [ ] T038 [US3] Remove unused JNAP-related imports from both provider files

**Checkpoint**: All providers refactored, architecture compliance achieved

---

## Phase 6: Polish & Verification

**Purpose**: Final validation and cleanup

- [ ] T039 Run architecture compliance check: `grep -r "import.*jnap/models" lib/page/instant_admin/providers/` (expect 0 results except timezone_state.dart)
- [ ] T040 [P] Run architecture compliance check: `grep -r "import.*jnap/result" lib/page/instant_admin/providers/` (expect 0 results)
- [ ] T041 [P] Run `flutter analyze` and verify no new errors
- [ ] T042 Run full test suite: `flutter test test/page/instant_admin/services/`
- [ ] T043 [P] Run `dart format` on all modified files
- [ ] T044 Manual smoke test: Verify timezone and power table functionality in InstantAdminView

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion
- **User Story 1 (Phase 3)**: Depends on Phase 1 & 2 completion
- **User Story 2 (Phase 4)**: Depends on Phase 1 & 2 completion, CAN run in parallel with Phase 3
- **User Story 3 (Phase 5)**: Depends on Phase 3 & 4 completion (needs both services)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Independent - can start after Foundational
- **User Story 2 (P1)**: Independent - can start after Foundational, parallel with US1
- **User Story 3 (P2)**: Depends on US1 and US2 - requires both services to exist

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Service skeleton before method implementation
- Method implementation before DartDoc
- All tests pass before story is complete

### Parallel Opportunities

**Phase 1 (Setup)**:
- T002 and T003 can run in parallel (different factory methods)

**Phase 2 (Foundational)**:
- T005 and T006 can run in parallel

**Phase 3 (US1 Tests)**:
- T009, T010 can run in parallel
- T012, T013 can run in parallel

**Phase 4 (US2 Tests)**:
- T021, T022, T023, T024 can run in parallel
- T026 can run in parallel

**Phase 3 & 4 (Services)**:
- US1 and US2 can be developed in parallel by different developers

**Phase 6 (Polish)**:
- T039, T040, T041, T043 can run in parallel

---

## Parallel Example: User Story 1 & 2 in Parallel

```bash
# Developer A: User Story 1 (Timezone)
Task: T007-T018 (TimezoneService tests + implementation)

# Developer B: User Story 2 (Power Table) - in parallel
Task: T019-T031 (PowerTableService tests + implementation)

# Both converge for User Story 3
Task: T032-T038 (Provider refactoring)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (test data builder)
2. Complete Phase 2: Foundational (verify infrastructure)
3. Complete Phase 3: User Story 1 (TimezoneService)
4. **STOP and VALIDATE**: Test TimezoneService independently
5. Can ship partial improvement if needed

### Full Implementation

1. Complete Setup + Foundational → Foundation ready
2. Complete User Story 1 → TimezoneService testable
3. Complete User Story 2 → PowerTableService testable (can parallel with US1)
4. Complete User Story 3 → Providers refactored
5. Complete Polish → Architecture compliance verified

### Parallel Team Strategy

With two developers:

1. Both complete Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (TimezoneService)
   - Developer B: User Story 2 (PowerTableService)
3. Both converge for User Story 3 (Provider refactoring)
4. Polish together

---

## Notes

- [P] tasks = different files, no dependencies
- [US1/US2/US3] label maps task to specific user story
- Tests are REQUIRED per FR-010 (≥90% coverage)
- Follow existing `router_password_service.dart` pattern
- Use `mapJnapErrorToServiceError` for error handling
- Commit after each task or logical group
- Run `flutter analyze` frequently to catch issues early
