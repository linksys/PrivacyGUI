# Tasks: Extract AddNodesService

**Input**: Design documents from `/specs/001-add-nodes-service/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/add_nodes_service_contract.md, quickstart.md

**Tests**: Required per spec.md Success Criteria (SC-003: Service ≥90%, SC-004: Provider ≥85%)

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **Source**: `lib/page/nodes/`
- **Tests**: `test/page/nodes/`
- **Test Data**: `test/mocks/test_data/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create directory structure and foundational files

- [x] T001 Create services directory at `lib/page/nodes/services/`
- [x] T002 [P] Create test directories at `test/page/nodes/services/` and `test/page/nodes/providers/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Test data builder that ALL service tests depend on

**CRITICAL**: No service tests can run until test data builder is complete

- [x] T003 Create AddNodesTestData builder in `test/mocks/test_data/add_nodes_test_data.dart` with factory methods:
  - `createAutoOnboardingSettingsSuccess(bool isEnabled)`
  - `createAutoOnboardingStatusSuccess(String status, List deviceOnboardingStatus)`
  - `createDevicesSuccess(List devices)`
  - `createBackhaulInfoSuccess(List backhaulDevices)`
  - `createJNAPError(String result)` for error testing

**Checkpoint**: Test data builder ready - service implementation can begin

---

## Phase 3: User Story 1+2 - Architecture Compliance & Auto-Onboarding (Priority: P1) - MVP

**Goal**: Create AddNodesService with auto-onboarding operations and establish architecture compliance

**Independent Test**:
- Verify AddNodesService methods work via unit tests
- Grep check confirms Provider has no JNAP imports

### Tests for User Story 1+2

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T004 [P] [US1] Create service test file with setup/teardown in `test/page/nodes/services/add_nodes_service_test.dart`
- [x] T005 [P] [US1] Add test group `setAutoOnboardingSettings` - verify JNAP action call and error mapping
- [x] T006 [P] [US1] Add test group `getAutoOnboardingSettings` - verify returns boolean from JNAP output
- [x] T007 [P] [US2] Add test group `pollAutoOnboardingStatus` - verify stream transforms JNAPResult to status map
- [x] T008 [P] [US2] Add test group `startAutoOnboarding` - verify JNAP action call

### Implementation for User Story 1+2

- [x] T009 [US1] Create AddNodesService class skeleton with constructor injection in `lib/page/nodes/services/add_nodes_service.dart`
- [x] T010 [US1] Add `addNodesServiceProvider` Riverpod provider definition
- [x] T011 [US2] Implement `setAutoOnboardingSettings()` method per contract
- [x] T012 [US2] Implement `getAutoOnboardingSettings()` method per contract
- [x] T013 [US2] Implement `pollAutoOnboardingStatus()` method with stream transformation per contract
- [x] T014 [US2] Implement `startAutoOnboarding()` method per contract
- [x] T015 [US1] Add error mapping using `mapJnapErrorToServiceError()` for all methods
- [x] T016 [US1] Add DartDoc comments to all public methods

**Checkpoint**: Service auto-onboarding methods complete and tested. Run `flutter test test/page/nodes/services/`

---

## Phase 4: User Story 3 - Node Polling Operations (Priority: P2)

**Goal**: Add polling operations for nodes online and backhaul info

**Independent Test**: Verify polling methods via unit tests with mocked RouterRepository

### Tests for User Story 3

- [x] T017 [P] [US3] Add test group `pollForNodesOnline` - verify stream returns List<LinksysDevice>
- [x] T018 [P] [US3] Add test group `pollNodesBackhaulInfo` - verify backhaul merge into LinksysDevice

### Implementation for User Story 3

- [x] T019 [US3] Implement `pollForNodesOnline()` method with device list transformation per contract
- [x] T020 [US3] Implement `pollNodesBackhaulInfo()` method with backhaul info merge per contract
- [x] T021 [US3] Add helper method `_collectChildNodeData()` for backhaul info merging

**Checkpoint**: All service methods complete. Run `flutter test test/page/nodes/services/` - should achieve ≥90% coverage

---

## Phase 5: User Story 4 - Provider Refactoring & Testability (Priority: P2)

**Goal**: Refactor AddNodesNotifier to delegate to AddNodesService

**Independent Test**:
- Grep check confirms zero JNAP imports in Provider
- Provider tests pass with mocked service

### Tests for User Story 4

- [x] T022 [P] [US4] Create provider test file in `test/page/nodes/providers/add_nodes_provider_test.dart`
- [x] T023 [P] [US4] Add tests verifying provider delegates to service methods
- [x] T024 [P] [US4] Add tests verifying provider handles ServiceError correctly

### Implementation for User Story 4

- [x] T025 [US4] Remove JNAP imports from `lib/page/nodes/providers/add_nodes_provider.dart`:
  - Delete `import 'package:privacy_gui/core/jnap/actions/better_action.dart'`
  - Delete `import 'package:privacy_gui/core/jnap/models/back_haul_info.dart'`
  - Delete `import 'package:privacy_gui/core/jnap/result/jnap_result.dart'`
  - Delete `import 'package:privacy_gui/core/jnap/router_repository.dart'`
- [x] T026 [US4] Add new imports to AddNodesNotifier:
  - Add `import 'package:privacy_gui/core/errors/service_error.dart'`
  - Add `import 'package:privacy_gui/page/nodes/services/add_nodes_service.dart'`
- [x] T027 [US4] Add service getter `AddNodesService get _service => ref.read(addNodesServiceProvider)`
- [x] T028 [US4] Refactor `setAutoOnboardingSettings()` to delegate to service
- [x] T029 [US4] Refactor `getAutoOnboardingSettings()` to delegate to service
- [x] T030 [US4] Refactor `getAutoOnboardingStatus()` to delegate to service
- [x] T031 [US4] Refactor `pollAutoOnboardingStatus()` to delegate to service
- [x] T032 [US4] Refactor `startAutoOnboarding()` to use service methods
- [x] T033 [US4] Refactor `pollForNodesOnline()` to delegate to service
- [x] T034 [US4] Refactor `pollNodesBackhaulInfo()` to delegate to service
- [x] T035 [US4] Refactor `startRefresh()` to use service methods
- [x] T036 [US4] Remove `collectChildNodeData()` method (moved to service)
- [x] T037 [US4] Update error handling to catch ServiceError instead of checking JNAPResult

**Checkpoint**: Provider refactored. Run grep checks and tests:
```bash
grep -r "import.*jnap/models" lib/page/nodes/providers/  # Should return nothing
grep -r "import.*jnap/result" lib/page/nodes/providers/  # Should return nothing
flutter test test/page/nodes/
```

---

## Phase 6: Polish & Verification

**Purpose**: Final validation and cleanup

- [x] T038 Run `flutter analyze lib/page/nodes/` - fix any warnings
- [x] T039 Run `dart format lib/page/nodes/ test/page/nodes/` - ensure formatting
- [x] T040 Run full test suite `flutter test test/page/nodes/` - verify all pass (excluding pre-existing golden test failures)
- [x] T041 Run architecture compliance checks per quickstart.md Step 6
- [ ] T042 [P] Verify test coverage meets targets (Service ≥90%, Provider ≥85%)
- [ ] T043 Manual testing: Verify Add Nodes flow works identically to before refactoring

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 - BLOCKS all service tests
- **US1+2 (Phase 3)**: Depends on Phase 2 completion
- **US3 (Phase 4)**: Depends on Phase 3 (builds on service class)
- **US4 (Phase 5)**: Depends on Phase 4 (needs complete service)
- **Polish (Phase 6)**: Depends on all phases complete

### Task Dependencies Within Phases

**Phase 3 (US1+2)**:
- T004-T008 (tests) → can run in parallel, should FAIL initially
- T009-T010 (service skeleton) → blocks method implementations
- T011-T016 → depend on T009-T010

**Phase 4 (US3)**:
- T017-T018 (tests) → can run in parallel, should FAIL initially
- T019-T021 → depend on service class from Phase 3

**Phase 5 (US4)**:
- T022-T024 (tests) → can run in parallel
- T025-T026 (imports) → MUST be first implementation step
- T027 (getter) → depends on T026
- T028-T037 → sequential refactoring, each depends on previous

### Parallel Opportunities

```
Phase 1: T001 ║ T002 (parallel)
Phase 2: T003 (sequential - blocks tests)
Phase 3: T004 ║ T005 ║ T006 ║ T007 ║ T008 (tests parallel)
         T009 → T010 → T011 → T012 → T013 → T014 → T015 → T016
Phase 4: T017 ║ T018 (tests parallel)
         T019 → T020 → T021
Phase 5: T022 ║ T023 ║ T024 (tests parallel)
         T025 → T026 → T027 → T028...T037 (sequential)
Phase 6: T038 → T039 → T040 → T041 → T042 ║ T043
```

---

## Parallel Example: Phase 3 Tests

```bash
# Launch all US1+2 tests together (they will FAIL until implementation):
Task: "Create service test file in test/page/nodes/services/add_nodes_service_test.dart"
Task: "Add test group setAutoOnboardingSettings"
Task: "Add test group getAutoOnboardingSettings"
Task: "Add test group pollAutoOnboardingStatus"
Task: "Add test group startAutoOnboarding"
```

---

## Implementation Strategy

### MVP First (Phase 1-3)

1. Complete Phase 1: Setup directories
2. Complete Phase 2: Test data builder
3. Complete Phase 3: Service with auto-onboarding methods
4. **STOP and VALIDATE**: Tests pass, service methods work
5. Can deploy/demo service in isolation

### Incremental Delivery

1. Setup + Foundational → Infrastructure ready
2. Add US1+2 (Phase 3) → Test service methods → Core functionality
3. Add US3 (Phase 4) → Test polling → Full service
4. Add US4 (Phase 5) → Test provider → Architecture compliant
5. Polish (Phase 6) → Final validation → Ready for PR

### Single Developer Strategy

Execute phases sequentially:
1. Phase 1 (5 min)
2. Phase 2 (15 min)
3. Phase 3 (1 hour) - Write tests first, then implement
4. Phase 4 (30 min) - Extend service
5. Phase 5 (1.5 hours) - Provider refactoring
6. Phase 6 (30 min) - Verification

**Estimated total**: ~4 hours

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to user story for traceability
- Tests MUST fail before implementation (TDD approach per spec)
- Commit after each checkpoint
- SC-003 requires Service ≥90% coverage
- SC-004 requires Provider ≥85% coverage
- Run grep checks frequently during Phase 5 to catch import violations early
