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

# Scope Extension: AddWiredNodesService (2026-01-07)

> **Note**: AddNodesService (Bluetooth) tasks above are complete. The following tasks implement AddWiredNodesService (Wired) per spec.md FR-015 to FR-028.

---

## Phase 7: Setup for Wired Nodes

**Purpose**: Create directory structure and foundational files for wired nodes

- [x] T044 Create models directory at `lib/page/nodes/models/` (if not exists)
- [x] T045 [P] Create test directory at `test/page/nodes/models/` (if not exists)

---

## Phase 8: Foundational (Wired Nodes)

**Purpose**: UI model and test data builder that wired service depends on

**CRITICAL**: No wired service implementation can begin until BackhaulInfoUIModel is complete

- [x] T046 Create BackhaulInfoUIModel in `lib/page/nodes/models/backhaul_info_ui_model.dart`:
  - Extends Equatable
  - Fields: deviceUUID, connectionType, timestamp
  - Methods: toMap(), fromMap(), toJson(), fromJson()
  - Per data-model.md specification

- [x] T047 [P] Create BackhaulInfoUIModel tests in `test/page/nodes/models/backhaul_info_ui_model_test.dart`:
  - Test Equatable equality
  - Test toMap/fromMap roundtrip
  - Test toJson/fromJson roundtrip

- [x] T048 Create AddWiredNodesTestData builder in `test/mocks/test_data/add_wired_nodes_test_data.dart`:
  - `createWiredAutoOnboardingSettingsSuccess(bool isEnabled)`
  - `createBackhaulInfoSuccess(List devices)`
  - `createDevicesSuccess(List devices)`
  - `createBackhaulDevice(deviceUUID, connectionType, timestamp)` helper
  - `createJNAPError(String result)`

**Checkpoint**: UI model and test data ready - wired service implementation can begin

---

## Phase 9: User Story 5+6 - Wired Architecture Compliance & Auto-Onboarding (Priority: P1) - MVP

**Goal**: Create AddWiredNodesService with wired auto-onboarding operations

**Independent Test**:
- Verify AddWiredNodesService methods work via unit tests
- Grep check confirms Provider has no JNAP imports

### Tests for User Story 5+6

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T049 [P] [US5] Create service test file with setup/teardown in `test/page/nodes/services/add_wired_nodes_service_test.dart`
- [x] T050 [P] [US5] Add test group `setAutoOnboardingEnabled` - verify JNAP action call with enabled flag and error mapping
- [x] T051 [P] [US5] Add test group `getAutoOnboardingEnabled` - verify returns boolean from JNAP output
- [x] T052 [P] [US6] Add test group `pollBackhaulChanges` - verify stream returns BackhaulPollResult with correct foundCounting
- [x] T053 [P] [US6] Add test group `fetchNodes` - verify returns List<LinksysDevice> filtered by nodeType

### Implementation for User Story 5+6

- [x] T054 [US5] Create AddWiredNodesService class skeleton with constructor injection in `lib/page/nodes/services/add_wired_nodes_service.dart`
- [x] T055 [US5] Add `addWiredNodesServiceProvider` Riverpod provider definition
- [x] T056 [US5] Define `BackhaulPollResult` class in same file (backhaulList, foundCounting, anyOnboarded)
- [x] T057 [US6] Implement `setAutoOnboardingEnabled(bool enabled)` method per contract
- [x] T058 [US6] Implement `getAutoOnboardingEnabled()` method per contract
- [x] T059 [US6] Implement `pollBackhaulChanges()` method with stream transformation per contract:
  - Move timestamp comparison logic from Provider
  - Use DateFormat for timestamp parsing
  - Calculate foundCounting for new nodes
  - Return Stream<BackhaulPollResult>
- [x] T060 [US6] Implement `fetchNodes()` method per contract
- [x] T061 [US5] Add error mapping using `mapJnapErrorToServiceError()` for all methods
- [x] T062 [US5] Add DartDoc comments to all public methods

**Checkpoint**: Wired service methods complete and tested. Run `flutter test test/page/nodes/services/add_wired_nodes_service_test.dart`

---

## Phase 10: User Story 7 - State Model Compliance (Priority: P2)

**Goal**: Update AddWiredNodesState to use BackhaulInfoUIModel instead of BackHaulInfoData

**Independent Test**: Verify AddWiredNodesState only imports from allowed layers

### Tests for User Story 7

- [x] T063 [P] [US7] Create state test file in `test/page/nodes/providers/add_wired_nodes_state_test.dart`
- [x] T064 [P] [US7] Add tests verifying State uses BackhaulInfoUIModel for backhaulSnapshot
- [x] T065 [P] [US7] Add tests verifying copyWith works correctly with new model type

### Implementation for User Story 7

- [x] T066 [US7] Update imports in `lib/page/nodes/providers/add_wired_nodes_state.dart`:
  - Remove `import 'package:privacy_gui/core/jnap/models/back_haul_info.dart'`
  - Add `import 'package:privacy_gui/page/nodes/models/backhaul_info_ui_model.dart'`
- [x] T067 [US7] Change `backhaulSnapshot` field type from `List<BackHaulInfoData>?` to `List<BackhaulInfoUIModel>?`
- [x] T068 [US7] Update copyWith method signature and implementation for new type

**Checkpoint**: State updated. Run grep check and tests:
```bash
grep -r "import.*jnap/models" lib/page/nodes/providers/add_wired*  # Should return nothing
flutter test test/page/nodes/providers/add_wired_nodes_state_test.dart
```

---

## Phase 11: User Story 5 continued - Provider Refactoring (Priority: P1)

**Goal**: Refactor AddWiredNodesNotifier to delegate to AddWiredNodesService

**Independent Test**:
- Grep check confirms zero JNAP imports in Provider
- Provider tests pass with mocked service

### Tests for Provider Refactoring

- [x] T069 [P] [US5] Create provider test file in `test/page/nodes/providers/add_wired_nodes_provider_test.dart`
- [x] T070 [P] [US5] Add tests verifying provider delegates to service methods
- [x] T071 [P] [US5] Add tests verifying provider handles ServiceError correctly
- [x] T072 [P] [US5] Add tests verifying startAutoOnboarding flow with mocked service

### Implementation for Provider Refactoring

- [x] T073 [US5] Remove JNAP imports from `lib/page/nodes/providers/add_wired_nodes_provider.dart`:
  - Delete `import 'package:privacy_gui/core/jnap/actions/better_action.dart'`
  - Delete `import 'package:privacy_gui/core/jnap/models/back_haul_info.dart'`
  - Delete `import 'package:privacy_gui/core/jnap/result/jnap_result.dart'`
  - Delete `import 'package:privacy_gui/core/jnap/router_repository.dart'`
  - Delete `import 'package:intl/intl.dart'` (DateFormat moves to Service)
- [x] T074 [US5] Add new imports to AddWiredNodesNotifier:
  - Add `import 'package:privacy_gui/page/nodes/models/backhaul_info_ui_model.dart'`
  - Add `import 'package:privacy_gui/page/nodes/services/add_wired_nodes_service.dart'`
- [x] T075 [US5] Add service getter `AddWiredNodesService get _service => ref.read(addWiredNodesServiceProvider)`
- [x] T076 [US5] Refactor `setAutoOnboardingSettings()` to delegate to `_service.setAutoOnboardingEnabled()`
- [x] T077 [US5] Refactor `getAutoOnboardingSettings()` to delegate to `_service.getAutoOnboardingEnabled()`
- [x] T078 [US5] Refactor `startAutoOnboarding()` method:
  - Call `_service.setAutoOnboardingEnabled(true)` instead of direct JNAP
  - Get backhaul snapshot and convert to BackhaulInfoUIModel list
  - Call `_service.pollBackhaulChanges()` instead of `pollBackhaulInfo()`
  - Update state from BackhaulPollResult stream
  - Call `_service.setAutoOnboardingEnabled(false)` to stop
  - Call `_service.fetchNodes()` to get final node list
- [x] T079 [US5] Refactor `stopAutoOnboarding()` to use service
- [x] T080 [US5] Remove `pollBackhaulInfo()` method (moved to service as `pollBackhaulChanges()`)
- [x] T081 [US5] Remove `_checkBackhaulChanges()` helper (logic moved to service)
- [x] T082 [US5] Remove `_fetchNodes()` method (moved to service as `fetchNodes()`)
- [x] T083 [US5] Update error handling to catch ServiceError instead of checking JNAPResult

**Checkpoint**: Provider refactored. Run grep checks and tests:
```bash
grep -r "import.*jnap/models" lib/page/nodes/providers/add_wired*  # Should return nothing
grep -r "import.*jnap/result" lib/page/nodes/providers/add_wired*  # Should return nothing
grep -r "import.*jnap/actions" lib/page/nodes/providers/add_wired*  # Should return nothing
flutter test test/page/nodes/providers/add_wired*
```

---

## Phase 12: Polish & Verification (Wired)

**Purpose**: Final validation and cleanup for wired nodes implementation

- [x] T084 Run `flutter analyze lib/page/nodes/` - fix any warnings
- [x] T085 Run `dart format lib/page/nodes/ test/page/nodes/` - ensure formatting
- [x] T086 Run full test suite `flutter test test/page/nodes/` - verify all pass (excluding pre-existing golden test failures)
- [x] T087 Run architecture compliance checks:
  ```bash
  grep -r "import.*jnap/models" lib/page/nodes/providers/  # Should return nothing
  grep -r "import.*jnap/result" lib/page/nodes/providers/  # Should return nothing
  grep -r "import.*jnap/actions" lib/page/nodes/providers/ # Should return nothing
  ```
- [ ] T088 [P] Verify AddWiredNodesService test coverage meets ≥90% target (SC-010)
- [ ] T089 [P] Verify AddWiredNodesNotifier/State test coverage meets ≥85% target (SC-011)
- [ ] T090 Manual testing: Verify Add Wired Nodes flow works identically to before refactoring

---

## Dependencies & Execution Order

### Phase Dependencies (Bluetooth - Complete)

- **Setup (Phase 1)**: No dependencies - can start immediately ✅
- **Foundational (Phase 2)**: Depends on Phase 1 - BLOCKS all service tests ✅
- **US1+2 (Phase 3)**: Depends on Phase 2 completion ✅
- **US3 (Phase 4)**: Depends on Phase 3 (builds on service class) ✅
- **US4 (Phase 5)**: Depends on Phase 4 (needs complete service) ✅
- **Polish (Phase 6)**: Depends on all phases complete ⏳

### Phase Dependencies (Wired - New)

- **Setup Wired (Phase 7)**: No dependencies - can start immediately
- **Foundational Wired (Phase 8)**: Depends on Phase 7 - BLOCKS wired service
- **US5+6 (Phase 9)**: Depends on Phase 8 (needs BackhaulInfoUIModel)
- **US7 (Phase 10)**: Depends on Phase 8 (needs BackhaulInfoUIModel for State)
- **US5 Provider (Phase 11)**: Depends on Phase 9 + Phase 10 (needs complete wired service)
- **Polish Wired (Phase 12)**: Depends on all wired phases complete

### Task Dependencies Within Phases (Wired)

**Phase 8 (Foundational Wired)**:
- T046 (BackhaulInfoUIModel) → BLOCKS all wired implementation
- T047 (UI model tests) ║ T048 (test data builder) → can run in parallel after T046

**Phase 9 (US5+6)**:
- T049-T053 (tests) → can run in parallel, should FAIL initially
- T054-T056 (service skeleton) → blocks method implementations
- T057-T062 → depend on T054-T056

**Phase 10 (US7)**:
- T063-T065 (tests) → can run in parallel
- T066-T068 → sequential State updates

**Phase 11 (US5 Provider)**:
- T069-T072 (tests) → can run in parallel
- T073-T074 (imports) → MUST be first implementation step
- T075 (getter) → depends on T074
- T076-T083 → sequential refactoring

### Parallel Opportunities (Bluetooth - Complete)

```
Phase 1: T001 ║ T002 (parallel) ✅
Phase 2: T003 (sequential - blocks tests) ✅
Phase 3: T004 ║ T005 ║ T006 ║ T007 ║ T008 (tests parallel) ✅
         T009 → T010 → T011 → T012 → T013 → T014 → T015 → T016 ✅
Phase 4: T017 ║ T018 (tests parallel) ✅
         T019 → T020 → T021 ✅
Phase 5: T022 ║ T023 ║ T024 (tests parallel) ✅
         T025 → T026 → T027 → T028...T037 (sequential) ✅
Phase 6: T038 → T039 → T040 → T041 ✅ → T042 ║ T043 ⏳
```

### Parallel Opportunities (Wired - New)

```
Phase 7:  T044 ║ T045 (parallel)
Phase 8:  T046 → [T047 ║ T048] (UI model tests and test data parallel after model)
Phase 9:  T049 ║ T050 ║ T051 ║ T052 ║ T053 (tests parallel)
          T054 → T055 → T056 → T057 → T058 → T059 → T060 → T061 → T062
Phase 10: T063 ║ T064 ║ T065 (tests parallel)
          T066 → T067 → T068
Phase 11: T069 ║ T070 ║ T071 ║ T072 (tests parallel)
          T073 → T074 → T075 → T076...T083 (sequential)
Phase 12: T084 → T085 → T086 → T087 → T088 ║ T089 → T090
```

---

## Parallel Example: Phase 9 Tests (Wired)

```bash
# Launch all wired service tests together (they will FAIL until implementation):
Task: "Create service test file in test/page/nodes/services/add_wired_nodes_service_test.dart"
Task: "Add test group setAutoOnboardingEnabled"
Task: "Add test group getAutoOnboardingEnabled"
Task: "Add test group pollBackhaulChanges"
Task: "Add test group fetchNodes"
```

---

## Implementation Strategy

### Bluetooth (Complete)

~~1. Complete Phase 1: Setup directories~~ ✅
~~2. Complete Phase 2: Test data builder~~ ✅
~~3. Complete Phase 3: Service with auto-onboarding methods~~ ✅
~~4. Complete Phase 4: Polling operations~~ ✅
~~5. Complete Phase 5: Provider refactoring~~ ✅
6. Phase 6: Final verification ⏳

### Wired (New - MVP First)

1. Complete Phase 7: Setup wired directories
2. Complete Phase 8: BackhaulInfoUIModel + Test data builder
3. Complete Phase 9: AddWiredNodesService methods
4. **STOP and VALIDATE**: Tests pass, service methods work
5. Can deploy/demo service in isolation

### Wired (Incremental Delivery)

1. Setup Wired + Foundational Wired → Infrastructure ready
2. Add US5+6 (Phase 9) → Test service methods → Core functionality
3. Add US7 (Phase 10) → Update State model → Architecture compliant State
4. Add US5 Provider (Phase 11) → Refactor Notifier → Full architecture compliance
5. Polish Wired (Phase 12) → Final validation → Ready for PR

### Single Developer Strategy (Wired Only)

Execute phases sequentially:
1. Phase 7 (5 min)
2. Phase 8 (30 min) - UI model + test data builder
3. Phase 9 (1.5 hours) - Write tests first, then implement service
4. Phase 10 (20 min) - State model update
5. Phase 11 (1.5 hours) - Provider refactoring
6. Phase 12 (30 min) - Verification

**Estimated total for Wired**: ~4.5 hours

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to user story for traceability
- Tests MUST fail before implementation (TDD approach per spec)
- Commit after each checkpoint
- **Bluetooth**: SC-003 Service ≥90% ✅, SC-004 Provider ≥85% ✅
- **Wired**: SC-010 Service ≥90%, SC-011 Provider/State ≥85%
- Run grep checks frequently during Phase 11 to catch import violations early
- Phase 9 and Phase 10 can run in parallel (different files, no dependencies)
