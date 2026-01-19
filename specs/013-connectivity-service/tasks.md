# Tasks: ConnectivityService Extraction

**Input**: Design documents from `/specs/001-connectivity-service/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Included per constitution.md Article I (test coverage required for services)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Source**: `lib/providers/connectivity/`
- **Service**: `lib/providers/connectivity/services/`
- **Tests**: `test/providers/connectivity/services/`
- **Test Data**: `test/mocks/test_data/`

---

## Phase 1: Setup

**Purpose**: Create directory structure and test data builder

- [x] T001 Create services directory at `lib/providers/connectivity/services/`
- [x] T002 Create test directory at `test/providers/connectivity/services/`
- [x] T003 [P] Create test data builder at `test/mocks/test_data/connectivity_test_data.dart`

---

## Phase 2: Foundational (Service Implementation)

**Purpose**: Create the `ConnectivityService` class - MUST be complete before Provider refactoring

**CRITICAL**: No Provider changes can begin until this phase is complete

- [x] T004 Create `ConnectivityService` class skeleton with constructor injection in `lib/providers/connectivity/services/connectivity_service.dart`
- [x] T005 Define `connectivityServiceProvider` in `lib/providers/connectivity/services/connectivity_service.dart`
- [x] T006 Implement `testRouterType(String? gatewayIp)` method in `lib/providers/connectivity/services/connectivity_service.dart`
- [x] T007 Implement `fetchRouterConfiguredData()` method in `lib/providers/connectivity/services/connectivity_service.dart`

**Checkpoint**: ConnectivityService is complete and ready for testing and integration

---

## Phase 3: User Story 1 - Connectivity Check (Priority: P1)

**Goal**: Ensure router type detection continues to work via the new service layer

**Independent Test**: Launch app on various network conditions and verify correct RouterType is returned

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T008 [P] [US1] Unit test: `testRouterType` returns `RouterType.behindManaged` when serial numbers match in `test/providers/connectivity/services/connectivity_service_test.dart`
- [x] T009 [P] [US1] Unit test: `testRouterType` returns `RouterType.behind` when serial numbers differ in `test/providers/connectivity/services/connectivity_service_test.dart`
- [x] T010 [P] [US1] Unit test: `testRouterType` returns `RouterType.others` when JNAP call fails in `test/providers/connectivity/services/connectivity_service_test.dart`
- [x] T011 [P] [US1] Unit test: `testRouterType` returns `RouterType.others` when serial number is empty in `test/providers/connectivity/services/connectivity_service_test.dart`

### Implementation for User Story 1

- [x] T012 [US1] Verify `testRouterType` implementation handles all edge cases in `lib/providers/connectivity/services/connectivity_service.dart`
- [x] T013 [US1] Run tests and ensure all pass for `testRouterType` functionality

**Checkpoint**: Router type detection via service is fully tested

---

## Phase 4: User Story 2 - Router Configuration Status (Priority: P1)

**Goal**: Ensure router configuration check continues to work via the new service layer

**Independent Test**: Check configuration status with factory-reset and configured routers

### Tests for User Story 2

- [x] T014 [P] [US2] Unit test: `fetchRouterConfiguredData` returns correct data on success in `test/providers/connectivity/services/connectivity_service_test.dart`
- [x] T015 [P] [US2] Unit test: `fetchRouterConfiguredData` throws `ServiceError` on JNAP failure in `test/providers/connectivity/services/connectivity_service_test.dart`
- [x] T016 [P] [US2] Unit test: `fetchRouterConfiguredData` handles default password state in `test/providers/connectivity/services/connectivity_service_test.dart`
- [x] T017 [P] [US2] Unit test: `fetchRouterConfiguredData` handles user-set password state in `test/providers/connectivity/services/connectivity_service_test.dart`

### Implementation for User Story 2

- [x] T018 [US2] Verify `fetchRouterConfiguredData` implementation handles all scenarios in `lib/providers/connectivity/services/connectivity_service.dart`
- [x] T019 [US2] Run tests and ensure all pass for `fetchRouterConfiguredData` functionality

**Checkpoint**: Router configuration check via service is fully tested

---

## Phase 5: User Story 3 - Architecture Compliance (Priority: P1)

**Goal**: Refactor `ConnectivityNotifier` to delegate to `ConnectivityService` and remove JNAP imports

**Independent Test**: Run architecture compliance check (grep for JNAP imports in Provider)

### Implementation for User Story 3

- [x] T020 [US3] Update `ConnectivityNotifier._testRouterType()` to delegate to service in `lib/providers/connectivity/connectivity_provider.dart`
- [x] T021 [US3] Update `ConnectivityNotifier.isRouterConfigured()` to delegate to service in `lib/providers/connectivity/connectivity_provider.dart`
- [x] T022 [US3] Remove JNAP-related imports from `lib/providers/connectivity/connectivity_provider.dart`:
  - Remove `import 'package:privacy_gui/core/jnap/command/base_command.dart'`
  - Remove `import 'package:privacy_gui/core/jnap/extensions/_extensions.dart'`
  - Remove `import 'package:privacy_gui/core/jnap/models/device_info.dart'`
  - Remove `import 'package:privacy_gui/core/jnap/actions/better_action.dart'`
  - Remove `import 'package:privacy_gui/core/jnap/result/jnap_result.dart'`
  - Remove `import 'package:privacy_gui/core/jnap/router_repository.dart'`
- [x] T023 [US3] Add service import to `lib/providers/connectivity/connectivity_provider.dart`:
  - Add `import 'package:privacy_gui/providers/connectivity/services/connectivity_service.dart'`
- [x] T024 [US3] Remove unused method bodies from `ConnectivityNotifier` (keep signatures, delegate to service)

**Checkpoint**: Provider no longer has JNAP imports, delegates to service

---

## Phase 6: Verification & Polish

**Purpose**: Validate architecture compliance and ensure all tests pass

- [x] T025 Run architecture compliance check: `grep -r "import.*jnap/models" lib/providers/connectivity/connectivity_provider.dart` (expect no results)
- [x] T026 Run architecture compliance check: `grep -r "import.*jnap/result" lib/providers/connectivity/connectivity_provider.dart` (expect no results)
- [x] T027 Run architecture compliance check: `grep -r "import.*jnap/actions" lib/providers/connectivity/connectivity_provider.dart` (expect no results)
- [x] T028 Verify service HAS JNAP imports: `grep -r "import.*jnap" lib/providers/connectivity/services/` (expect results)
- [x] T029 Run all connectivity tests: `flutter test test/providers/connectivity/`
- [x] T030 Run `dart analyze lib/providers/connectivity/` and fix any issues
- [x] T031 Run `dart format lib/providers/connectivity/` to ensure code formatting

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS Provider refactoring
- **User Story 1 (Phase 3)**: Depends on Foundational phase completion
- **User Story 2 (Phase 4)**: Depends on Foundational phase completion (can run in parallel with US1)
- **User Story 3 (Phase 5)**: Depends on US1 and US2 tests passing (service must be verified before Provider uses it)
- **Verification (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - tests `testRouterType`
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - tests `fetchRouterConfiguredData` - can run in parallel with US1
- **User Story 3 (P1)**: Depends on US1 and US2 - refactors Provider to use tested service

### Within Each User Story

- Tests MUST be written and FAIL before implementation verification
- Service implementation verified before Provider integration
- Story complete before moving to next phase

### Parallel Opportunities

**Phase 1 - Setup**:
- T001, T002, T003 can run in parallel (different directories/files)

**Phase 3 & 4 - US1 and US2 Tests**:
- T008, T009, T010, T011 can run in parallel (same test file, different test cases)
- T014, T015, T016, T017 can run in parallel (same test file, different test cases)
- US1 and US2 test phases can run in parallel

**Phase 6 - Verification**:
- T025, T026, T027, T028 can run in parallel (different grep commands)

---

## Parallel Example: Test Writing

```bash
# Launch all US1 tests together:
Task: "Unit test: testRouterType returns RouterType.behindManaged when serial numbers match"
Task: "Unit test: testRouterType returns RouterType.behind when serial numbers differ"
Task: "Unit test: testRouterType returns RouterType.others when JNAP call fails"
Task: "Unit test: testRouterType returns RouterType.others when serial number is empty"

# Launch all US2 tests together (can be parallel with US1):
Task: "Unit test: fetchRouterConfiguredData returns correct data on success"
Task: "Unit test: fetchRouterConfiguredData throws ServiceError on JNAP failure"
Task: "Unit test: fetchRouterConfiguredData handles default password state"
Task: "Unit test: fetchRouterConfiguredData handles user-set password state"
```

---

## Implementation Strategy

### MVP First (Service + Tests)

1. Complete Phase 1: Setup (directories)
2. Complete Phase 2: Foundational (service implementation)
3. Complete Phase 3: User Story 1 (testRouterType tests)
4. Complete Phase 4: User Story 2 (fetchRouterConfiguredData tests)
5. **STOP and VALIDATE**: All service tests pass
6. Proceed with Phase 5: Provider refactoring

### Incremental Delivery

1. Setup + Foundational → Service created
2. US1 Tests → testRouterType verified
3. US2 Tests → fetchRouterConfiguredData verified
4. US3 → Provider refactored to use service
5. Verification → Architecture compliance confirmed

### Suggested Execution Order

```
T001 → T002 → T003 (parallel)
↓
T004 → T005 → T006 → T007 (sequential - service building)
↓
T008-T011 (parallel) + T014-T017 (parallel)
↓
T012 → T013 + T018 → T019
↓
T020 → T021 → T022 → T023 → T024 (sequential - provider refactoring)
↓
T025-T028 (parallel) → T029 → T030 → T031
```

---

## Notes

- [P] tasks = different files or independent operations
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Reference implementation: `lib/page/instant_admin/services/router_password_service.dart`
