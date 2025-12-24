---

description: "Task list for AdministrationSettingsService Extraction Refactor"

---

# Tasks: AdministrationSettingsService Extraction Refactor

**Input**: Design documents from `/specs/001-administration-service-refactor/`
**Branch**: `001-administration-service-refactor`
**Status**: Ready for implementation
**Tests**: Included - write tests FIRST, then implementation

**Organization**: This refactor has 2 developer stories (both P1, dependent on each other) plus setup/polish phases.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which developer story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

---

## Phase 1: Setup & Analysis

**Purpose**: Understand existing code and set up for refactor

- [x] T001 Analyze existing `AdministrationSettingsNotifier` to identify JNAP logic extraction points in `lib/page/advanced_settings/administration/providers/administration_settings_provider.dart`
- [x] T002 [P] Analyze existing JNAP action imports and constants to be moved in `lib/core/jnap/actions/` and `lib/page/advanced_settings/administration/providers/administration_settings_provider.dart`
- [x] T003 [P] Review existing domain models (ManagementSettings, UPnPSettings, ALGSettings, ExpressForwardingSettings) to understand `.fromMap()` constructors in `lib/core/jnap/models/`
- [x] T004 [P] Review RouterRepository interface for transaction orchestration in `lib/core/jnap/router_repository.dart`
- [x] T005 Review PreservableNotifierMixin pattern to ensure refactor maintains compatibility in `lib/page/advanced_settings/administration/providers/administration_settings_provider.dart`

**Checkpoint**: Full understanding of existing implementation patterns established ✅

### Analysis Findings

**Current State (223 LOC)**:
- **performFetch()** (lines 66-138): 73 LOC containing JNAP orchestration + data transformation
  - 4 JNAP actions bundled in single transaction
  - Direct model parsing via `.fromMap()`
  - Data aggregation into AdministrationSettings
- **performSave()** (lines 140-170): 30 LOC for writes
- **State management** (lines 25-63, 172-223): ~120 LOC for PreservableNotifierMixin pattern

**Extraction Points**:
1. **JNAP Actions**: JNAPAction.get/setManagementSettings, getUPnPSettings, getALGSettings, getExpressForwardingSettings
2. **Data Models**: ManagementSettings, UPnPSettings, ALGSettings, ExpressForwardingSettings (all have .fromMap())
3. **Transaction Building**: JNAPTransactionBuilder pattern with 4 commands
4. **Result Parsing**: JNAPTransactionSuccessWrap.getResult() logic
5. **Error Handling**: All-or-nothing semantics for partial failures

**Domain Models**: ✅ All 4 models exist with serialization
**RouterRepository**: ✅ Injected via ref.read(), uses .transaction() method
**PreservableNotifierMixin**: ✅ Pattern intact, no external behavior changes needed

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Create service infrastructure that enables all stories

- [x] T006 Create directory structure `lib/page/advanced_settings/administration/services/` for new service layer
- [x] T007 Create directory structure `test/page/advanced_settings/administration/services/` for service tests

**Checkpoint**: File structure ready - stories can now proceed in parallel ✅

---

## Phase 3: Developer Story 1 - Cleaner Service Layer (Priority: P1) 🎯

**Goal**: Extract JNAP action orchestration and data transformation logic from Notifier into a dedicated, testable service layer

**Independent Test**: Service can be unit tested in isolation by providing mock JNAP responses and verifying correct data model instantiation without requiring Provider/Notifier setup.

**Acceptance Criteria**:
- Service returns parsed data models with proper error handling
- JNAP responses correctly mapped to domain models
- Meaningful failures with action context on error
- All imports consolidated in service layer

### Tests for Story 1 ⚠️

> **IMPORTANT**: Write these tests FIRST, ensure they FAIL before implementation

- [x] T008 [P] [US1] Write unit test for successful fetch of all four settings in `test/page/advanced_settings/administration/services/administration_settings_service_test.dart` (test case: "fetches all four settings successfully")
- [x] T009 [P] [US1] Write unit test for ManagementSettings parsing in `test/page/advanced_settings/administration/services/administration_settings_service_test.dart` (test case: "parses ManagementSettings correctly")
- [x] T010 [P] [US1] Write unit test for UPnPSettings parsing in `test/page/advanced_settings/administration/services/administration_settings_service_test.dart` (test case: "parses UPnPSettings correctly")
- [x] T011 [P] [US1] Write unit test for ALGSettings parsing in `test/page/advanced_settings/administration/services/administration_settings_service_test.dart` (test case: "parses ALGSettings correctly")
- [x] T012 [P] [US1] Write unit test for ExpressForwardingSettings parsing in `test/page/advanced_settings/administration/services/administration_settings_service_test.dart` (test case: "parses ExpressForwardingSettings correctly")
- [x] T013 [P] [US1] Write unit test for partial failure handling in `test/page/advanced_settings/administration/services/administration_settings_service_test.dart` (test case: "throws error if any JNAP action fails")
- [x] T014 [P] [US1] Write unit test for error context in `test/page/advanced_settings/administration/services/administration_settings_service_test.dart` (test case: "includes action context in error message")

**Tests written with TDD approach - currently FAILING (expected)**

### Implementation for Story 1

- [x] T015 [US1] Create `AdministrationSettingsService` class with public method signature in `lib/page/advanced_settings/administration/services/administration_settings_service.dart`
- [x] T016 [US1] Implement `fetchAdministrationSettings(Ref ref, {bool forceRemote, bool updateStatusOnly})` method with JNAP transaction building in `lib/page/advanced_settings/administration/services/administration_settings_service.dart`
- [x] T017 [US1] Implement JNAP action orchestration (4 actions in single transaction) in `lib/page/advanced_settings/administration/services/administration_settings_service.dart`
- [x] T018 [US1] Implement result parsing logic using `JNAPTransactionSuccessWrap` to extract individual action results in `lib/page/advanced_settings/administration/services/administration_settings_service.dart`
- [x] T019 [P] [US1] Implement ManagementSettings instantiation from JNAP response using `.fromMap()` in `lib/page/advanced_settings/administration/services/administration_settings_service.dart`
- [x] T020 [P] [US1] Implement UPnPSettings instantiation from JNAP response using `.fromMap()` in `lib/page/advanced_settings/administration/services/administration_settings_service.dart`
- [x] T021 [P] [US1] Implement ALGSettings instantiation from JNAP response using `.fromMap()` in `lib/page/advanced_settings/administration/services/administration_settings_service.dart`
- [x] T022 [P] [US1] Implement ExpressForwardingSettings instantiation from JNAP response using `.fromMap()` in `lib/page/advanced_settings/administration/services/administration_settings_service.dart`
- [x] T023 [US1] Implement AdministrationSettings aggregate construction from parsed models in `lib/page/advanced_settings/administration/services/administration_settings_service.dart`
- [x] T024 [US1] Implement error handling with action context and meaningful failure indicators in `lib/page/advanced_settings/administration/services/administration_settings_service.dart`
- [x] T025 [US1] Add comprehensive DartDoc comments to `fetchAdministrationSettings()` method in `lib/page/advanced_settings/administration/services/administration_settings_service.dart`
- [ ] T026 [US1] Run service unit tests (from T008-T014) and verify all pass with ≥90% coverage in `test/page/advanced_settings/administration/services/administration_settings_service_test.dart`
- [ ] T027 [US1] Verify service execution time <100ms per test suite in `test/page/advanced_settings/administration/services/administration_settings_service_test.dart`

**Checkpoint**: Service layer fully implemented and tested independently. Ready for notifier refactoring.

### Implementation Summary (T015-T025)

**Service Class Created**: `administration_settings_service.dart` (~160 LOC)

**Public Interface**:
```dart
Future<AdministrationSettings> fetchAdministrationSettings(
  Ref ref, {
  bool forceRemote = false,
  bool updateStatusOnly = false,
})
```

**Key Features**:
- ✓ Orchestrates 4 JNAP actions in single transaction
- ✓ Parses all domain models via `.fromMap()`
- ✓ Aggregates into AdministrationSettings
- ✓ Error handling with action context
- ✓ Comprehensive DartDoc comments
- ✓ Private helper methods for each model parsing

**Dependency Injection**: Via `ref.read(routerRepositoryProvider)` (Riverpod pattern)

**Error Strategy**: All-or-nothing + action context in exceptions

---

## Phase 4: Developer Story 2 - Improved Testability (Priority: P1)

**Goal**: Refactor AdministrationSettingsNotifier to delegate to service layer, enabling isolated testing of each layer

**Independent Test**: Service tests can mock RouterRepository directly. Notifier tests can mock AdministrationSettingsService. Each layer validates in isolation without provider overhead.

**Acceptance Criteria**:
- Notifier delegates data-fetching to service in `performFetch()`
- JNAP imports removed from Notifier (moved to service)
- Notifier's `performFetch()` reduced by ≥50% in lines
- Existing UI tests pass without modification
- Test execution time <100ms per test

### Tests for Story 2 ⚠️

> **IMPORTANT**: Write these tests FIRST, ensure they FAIL before implementation

- [ ] T028 [P] [US2] Update Notifier test to mock service instead of RouterRepository in `test/page/advanced_settings/administration/providers/administration_settings_provider_test.dart` (test case: "delegates to service on performFetch")
- [ ] T029 [P] [US2] Write unit test for Notifier state update from service results in `test/page/advanced_settings/administration/providers/administration_settings_provider_test.dart` (test case: "updates state with service results")
- [ ] T030 [P] [US2] Write unit test for Notifier error handling from service exceptions in `test/page/advanced_settings/administration/providers/administration_settings_provider_test.dart` (test case: "handles service errors gracefully")

### Implementation for Story 2

- [ ] T031 [US2] Add service import to `AdministrationSettingsNotifier` in `lib/page/advanced_settings/administration/providers/administration_settings_provider.dart`
- [ ] T032 [US2] Remove JNAP action imports (JNAPAction, JNAPTransaction, JNAPTransactionBuilder) from Notifier in `lib/page/advanced_settings/administration/providers/administration_settings_provider.dart`
- [ ] T033 [US2] Remove domain model imports (ManagementSettings, UPnPSettings, ALGSettings, ExpressForwardingSettings) from Notifier in `lib/page/advanced_settings/administration/providers/administration_settings_provider.dart`
- [ ] T034 [US2] Refactor `performFetch()` method to instantiate service and delegate to `fetchAdministrationSettings()` in `lib/page/advanced_settings/administration/providers/administration_settings_provider.dart`
- [ ] T035 [US2] Verify Notifier `performFetch()` reduced to <75 LOC by removing inline JNAP logic in `lib/page/advanced_settings/administration/providers/administration_settings_provider.dart`
- [ ] T036 [US2] Update Notifier tests to mock `AdministrationSettingsService` instead of directly accessing RouterRepository in `test/page/advanced_settings/administration/providers/administration_settings_provider_test.dart`
- [ ] T037 [US2] Run Notifier unit tests (from T028-T030) and verify all pass in `test/page/advanced_settings/administration/providers/administration_settings_provider_test.dart`
- [ ] T038 [US2] Run existing UI/golden tests to ensure backward compatibility (no behavioral changes) in `test/page/advanced_settings/administration/`

**Checkpoint**: Notifier refactored and tested. Service extraction complete. Both layers independently testable.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Validation, code quality, and final checks

- [ ] T039 [P] Run `flutter analyze` and verify zero warnings for modified files in `lib/page/advanced_settings/administration/` and `test/page/advanced_settings/administration/`
- [ ] T040 [P] Run `dart format` on all changed files in `lib/page/advanced_settings/administration/` and `test/page/advanced_settings/administration/`
- [ ] T041 Run all tests: `flutter test test/page/advanced_settings/` and verify 100% pass
- [ ] T042 Verify coverage ≥90% for service layer and ≥80% overall in `test/page/advanced_settings/administration/services/` and `test/page/advanced_settings/administration/providers/`
- [ ] T043 [P] Document service interface with examples in DartDoc comments in `lib/page/advanced_settings/administration/services/administration_settings_service.dart`
- [ ] T044 Validate backward compatibility - existing consumers of `administrationSettingsProvider` work unchanged in `lib/page/advanced_settings/administration/`
- [ ] T045 Verify service reusability by confirming another component could call it directly (code review step) in `lib/page/advanced_settings/administration/services/administration_settings_service.dart`
- [ ] T046 Run full app lint and test suite to ensure no regressions elsewhere in codebase: `flutter analyze && ./run_tests.sh`

**Checkpoint**: Refactor complete, tested, documented. Ready for PR and merge.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS both stories
- **Developer Story 1 (Phase 3)**: Depends on Foundational completion
  - All story tasks can proceed in parallel after setup
  - Tests (T008-T014) must pass before implementation tasks (T015+)
- **Developer Story 2 (Phase 4)**: Depends on Story 1 completion
  - Cannot refactor Notifier until service is complete and tested
  - All story tasks can proceed in parallel after Story 1 done
- **Polish (Phase 5)**: Depends on all stories being complete

### Story Dependencies Within Implementation

**Story 1 → Story 2 (Sequential required)**:
- Story 1 (service extraction) MUST complete before Story 2 (notifier refactoring)
- Story 2 refactors Notifier to delegate to Story 1's service
- Cannot test Story 2 delegation without Story 1 service existing

### Parallel Opportunities

**Phase 1 (Setup & Analysis)**:
- Tasks T002-T005 can run in parallel (all analysis, different files)

**Phase 2 (Foundational)**:
- Tasks T006-T007 can run in parallel (different directories)

**Phase 3 (Story 1 Implementation)**:
- All tests (T008-T014) can be written in parallel, then run together
- Model parsing implementations (T019-T022) can be coded in parallel once test framework is set up
- Service integration (T015-T024) must follow test writing but can parallelize component implementations

**Phase 4 (Story 2 Refactoring)**:
- Tests (T028-T030) can be written in parallel
- Import removal tasks (T032-T033) can happen in parallel
- But delegation task (T034) must happen after imports are removed

**Phase 5 (Polish)**:
- Linting/formatting tasks (T039-T040) can run in parallel
- Documentation (T043) can happen in parallel with final validation tasks

---

## Parallel Example: Story 1 Implementation

```bash
# After tests written (T008-T014), implement in parallel:
Task T019: "Implement ManagementSettings instantiation..."
Task T020: "Implement UPnPSettings instantiation..."
Task T021: "Implement ALGSettings instantiation..."
Task T022: "Implement ExpressForwardingSettings instantiation..."
→ These 4 can code in parallel, then integrate in T023

# Then sequential:
Task T023: Aggregate construction (depends on T019-T022)
Task T024: Error handling
Task T025: Documentation
Task T026: Run tests
Task T027: Verify performance
```

---

## Implementation Strategy

### MVP (Just Service Layer - Fastest Path)

1. Complete Phase 1: Setup & Analysis (T001-T005)
2. Complete Phase 2: Foundational (T006-T007)
3. Complete Phase 3: Story 1 only (T008-T027)
4. **STOP and VALIDATE**: Service fully tested in isolation
5. Can stop here if only goal is service extraction (service is reusable by others)

### Full Refactor (MVP + Notifier Refactoring)

1. Complete Setup + Foundational (T001-T007)
2. Complete Story 1: Service extraction (T008-T027)
3. Complete Story 2: Notifier refactoring (T028-T038) - depends on Story 1
4. Complete Polish (T039-T046)
5. Submit PR with both layers refactored

### Team Parallelization

With 2+ developers:
- Developer A: Completes Phase 1 & 2 (setup/analysis)
- Developer B: Writes Story 1 tests (T008-T014) while A finishes setup
- Developer A & B: Implement Story 1 in parallel (T019-T022 split)
- Developer A: Completes Story 1 integration & testing (T023-T027)
- Developer B (waiting): Writes Story 2 tests (T028-T030)
- Both: Implement Story 2 refactoring (T031-T038)
- Both: Polish phase tasks (T039-T046)

---

## Success Metrics

✅ **After Story 1 (Service Extraction)**:
- Service file exists: `lib/page/advanced_settings/administration/services/administration_settings_service.dart`
- Service tests: ≥90% coverage, <100ms execution
- All JNAP imports moved to service
- Acceptance test passes: Service returns correctly parsed models

✅ **After Story 2 (Notifier Refactoring)**:
- Service coverage: ≥90%
- Notifier tests updated to mock service
- Notifier `performFetch()` reduced by ≥50% LOC
- Existing UI tests: 100% pass (backward compatible)
- `flutter analyze`: 0 warnings

✅ **After Polish (Final)**:
- Full test suite passes
- Code formatted and linted
- Coverage ≥80% overall
- Service reusable by other components
- Documentation complete
- Ready for PR merge

---

## Notes

- [P] tasks = different files, independent, can run in parallel
- [Story] label = US1 (Cleaner Service Layer) or US2 (Improved Testability)
- Tests MUST be written first, MUST fail before implementation
- Story 1 MUST complete before Story 2 starts (sequential dependency)
- After Story 1, service can be used immediately by other features
- Notifier refactoring (Story 2) is optional - service alone provides value
- Each story can be deployed/reviewed independently
- Stop at any checkpoint to validate independently

---

## References

- **Spec**: [spec.md](./spec.md)
- **Plan**: [plan.md](./plan.md)
- **Research**: [research.md](./research.md)
- **Data Model**: [data-model.md](./data-model.md)
- **Quick Start**: [quickstart.md](./quickstart.md)
