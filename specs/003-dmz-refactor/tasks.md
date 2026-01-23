# Tasks: DMZ Settings Provider Refactor

**Input**: Design documents from `/specs/002-dmz-refactor/`
**Prerequisites**: plan.md (✅), spec.md (✅), checklists/requirements.md (✅)
**Branch**: `002-dmz-refactor`

**Organization**: Tasks are grouped by user story (P1, P1, P2) to enable independent implementation and testing of each story. All tasks follow the checklist format and reference exact file paths.

## Dependency Graph

```
Phase 1: Setup (T001-T002)
    ↓
Phase 2: Foundational (T003-T007)
    ├─→ Phase 3: US1 - Three-Layer Architecture (T008-T019) [P1]
    │   ├─→ Phase 4: US2 - Test Data Builder (T020-T025) [P1]
    │   │   ├─→ Phase 5: US3 - Constitution Validation (T026-T028) [P2]
    │   │   └─→ Phase 6: Polish & Cleanup (T029-T032)
    │   └─→ (Can parallelize T020-T025 with T008-T019)
    └─→ (All foundational tasks must complete before user story work)
```

## Parallel Opportunities

- **T003 + T004** (Setup configuration): Can run in parallel
- **T008-T011** (Test files for Service layer): Can write tests in parallel before implementation
- **T012 + T013** (State and Service layers): Can implement in parallel (State has no Service dependencies)
- **T020-T022** (TestData builder, Service tests, Provider tests): Can parallelize across test files

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and verify existing infrastructure

- [ ] T001 Review existing DMZ provider implementation in `lib/page/advanced_settings/dmz/providers/dmz_settings_provider.dart` to understand current JNAP code structure
- [ ] T002 Verify UnitTestHelper is working properly in `test/common/unit_test_helper.dart` for test infrastructure

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T003 Create DMZ services directory structure `lib/page/advanced_settings/dmz/services/` for Service layer implementation
- [ ] T004 Create DMZ test directory structure `test/page/advanced_settings/dmz/services/` and `test/page/advanced_settings/dmz/providers/` for all test files
- [ ] T005 Review Administration Settings Service implementation (`lib/page/advanced_settings/administration/services/administration_settings_service.dart`) as pattern reference for architecture
- [ ] T006 Review Administration Settings TestData builder (`test/page/advanced_settings/administration/services/administration_settings_service_test_data.dart`) as pattern reference for mock data centralization
- [ ] T007 Review existing DMZ UI tests to understand backward compatibility requirements in `test/page/advanced_settings/dmz/views/`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Developer Refactors DMZ Settings Service to Follow Three-Layer Architecture (Priority: P1) 🎯 MVP

**Goal**: Extract all JNAP protocol code from Provider into Service layer, implement three-layer architecture with complete test coverage (Service ≥90%, Provider ≥85%, State ≥90%)

**Independent Test**: Run test suite and verify:
1. Service layer tests pass with ≥90% coverage
2. Provider layer tests pass with ≥85% coverage
3. State layer tests pass with ≥90% coverage
4. `flutter analyze` returns 0 warnings
5. All JNAP imports are isolated in Service layer (0 in Provider)

### Implementation for User Story 1

#### Data Model Layer (State)

- [ ] T008 [P] [US1] Create `DmzSettings` data model in `lib/page/advanced_settings/dmz/providers/dmz_settings_state.dart` with:
  - Fields: `isEnabled`, `portMappings`, `appVisibility`, `loggingEnabled`, `customRules` (or actual DMZ fields from existing provider)
  - Implement Equatable for equality comparison
  - Implement copyWith() for immutable updates
  - Implement serialization: toMap(), fromMap(), toJson(), fromJson()

- [ ] T009 [P] [US1] Create `DmzSettingsStatus` in `lib/page/advanced_settings/dmz/providers/dmz_settings_state.dart` as marker class for state status tracking

#### Service Layer Implementation

- [ ] T010 [US1] Create `DmzSettingsService` in `lib/page/advanced_settings/dmz/services/dmz_settings_service.dart` with:
  - Method: `fetchDmzSettings(Ref ref, {bool forceRemote = false, bool updateStatusOnly = false})`
  - Method: `saveDmzSettings(Ref ref, DmzSettings settings)` (if applicable)
  - Extract all JNAP protocol code from existing Provider into these methods
  - Implement error handling with action-specific context messages
  - Handle partial responses and edge cases (new fields, null values, empty data)

#### Service Layer Tests (7-10 tests)

- [ ] T011 [P] [US1] Create `test/page/advanced_settings/dmz/services/dmz_settings_service_test.dart` with test structure:
  - T001: Test successful fetch with all DMZ fields present (≥90% coverage goal)
  - T002: Test fetch parsing for each DMZ field individually
  - T003: Test save operation (if applicable)
  - T004-T007: Error path tests (API failure, timeout, partial response, device unreachable)
  - Use MockRouterRepository with mocktail
  - Use UnitTestHelper.createMockRef() for mock setup

#### Provider Layer Refactoring

- [ ] T012 [US1] Refactor existing `lib/page/advanced_settings/dmz/providers/dmz_settings_provider.dart`:
  - Remove all JNAP imports: JNAPAction, JNAPTransactionBuilder, protocol-specific types
  - Update Notifier to delegate to DmzSettingsService
  - Implement `performFetch()` method calling Service.fetchDmzSettings()
  - Implement `performSave()` method calling Service.saveDmzSettings() (if applicable)
  - Use Preservable<DmzSettings> for undo/reset support
  - Use DmzSettingsStatus for state tracking
  - Verify 0 JNAP imports remain (use grep as validation)

#### Provider Layer Tests (3-5 tests)

- [ ] T013 [US1] Create `test/page/advanced_settings/dmz/providers/dmz_settings_provider_test.dart`:
  - T001: Test delegation to Service on performFetch
  - T002: Test state updates with service results
  - T003: Test error propagation from Service
  - Use ProviderContainer for test isolation
  - Target ≥85% Provider layer coverage

#### State Layer Tests (20-30 tests)

- [ ] T014 [US1] Create `test/page/advanced_settings/dmz/providers/dmz_settings_state_test.dart`:
  - **Construction & Defaults**: Test basic construction, default values, required fields
  - **copyWith Tests**: Test creating new instances, preserving unmodified fields, immutability
  - **Serialization Tests (⚠️ CRITICAL - most commonly omitted)**:
    - toMap() includes all fields
    - fromMap() restores all fields correctly
    - toJson() produces valid JSON string
    - fromJson() parses JSON correctly
    - Round-trip: object → map → object results in equality
    - Round-trip: object → JSON → object results in equality
  - **Equality Tests (Equatable)**: Same data equals, different data not equals
  - **Boundary Cases**: Null values, empty collections, special characters, extreme values
  - Target ≥90% State layer coverage

#### Code Quality & Validation

- [ ] T015 [US1] Run `flutter analyze lib/page/advanced_settings/dmz/` and fix all warnings to achieve 0 warnings
- [ ] T016 [US1] Run `dart format lib/page/advanced_settings/dmz/` to ensure code formatting compliance
- [ ] T017 [US1] Run full test suite for DMZ module and verify all 33+ tests pass with target coverage (Service ≥90%, Provider ≥85%, State ≥90%)
- [ ] T018 [US1] Verify backward compatibility by running existing DMZ UI tests to ensure 0 breaking changes
- [ ] T019 [US1] Add DartDoc comments to all public methods in Service layer and Provider notifier methods

**Checkpoint**: At this point, User Story 1 should be fully functional with complete three-layer architecture, all JNAP code isolated in Service layer, and comprehensive test coverage.

---

## Phase 4: User Story 2 - Apply Test Data Builder Pattern to DMZ Service Tests (Priority: P1)

**Goal**: Centralize mock JNAP responses in TestData builder, reduce Service test verbosity by ~70%, prove pattern effectiveness

**Independent Test**: Verify:
1. All 7+ DMZ Service tests use DmzSettingsTestData builder
2. Each test code reduced from 50+ LOC to <15 LOC
3. All tests pass with 0 lint warnings
4. Mock data centralization complete (no inline JNAP responses in tests)

### Implementation for User Story 2

#### TestData Builder Implementation

- [ ] T020 [P] [US2] Create `test/page/advanced_settings/dmz/services/dmz_settings_service_test_data.dart`:
  - Factory method: `createSuccessfulTransaction()` with optional Map overrides for partial customization
  - Factory method: `createPartialErrorTransaction(errorAction, errorMessage)`
  - Private helper methods for default values: `_createDefaultState()`, etc.
  - Apply partial override pattern: merge user-provided fields with sensible defaults
  - Document default value meanings (e.g., "typical disabled device")

#### Service Test Refactoring

- [ ] T021 [P] [US2] Refactor `test/page/advanced_settings/dmz/services/dmz_settings_service_test.dart`:
  - Replace all inline JNAP response creation with DmzSettingsTestData builders
  - Each test should use: `AdministrationSettingsTestData.createSuccessfulTransaction(field1: {...})`
  - Verify test code reduction from 50+ LOC to <15 LOC per test
  - Ensure all 7+ tests follow centralized builder pattern

#### Pattern Validation

- [ ] T022 [US2] Verify Test Data Builder pattern compliance:
  - Confirm 3+ reuse rule: All JNAP responses used in 3+ tests are centralized
  - Confirm no inline mock responses appear in tests (use grep: `grep -n "JNAPTransactionSuccessWrap\|JNAPSuccess" test/.../dmz_settings_service_test.dart` should return 0)
  - Confirm builder methods are well-documented with usage examples
  - Document any builder improvements for future modules

**Checkpoint**: User Story 2 complete - Test Data Builder pattern applied, test code cleaner and more maintainable, pattern proven effective for DMZ module.

---

## Phase 5: User Story 3 - Validate DMZ Refactoring Against Constitution (Priority: P2)

**Goal**: Ensure refactored DMZ adheres to constitution v2.2, validate testing patterns are clear and practical

**Independent Test**: Verify:
1. All constitution v2.2 Section 6 requirements met (Test Data Builder)
2. All constitution v2.2 Section 7 requirements met (Three-Layer Testing)
3. Coverage targets met: Service ≥90%, Provider ≥85%, State ≥90%
4. Any unclear guidelines documented for v2.3 updates

### Implementation for User Story 3

#### Constitution Compliance Validation

- [ ] T023 [US3] Validate against constitution v2.2 Section 6 (Test Data Builder Pattern):
  - ✓ Mock data centralized in DmzSettingsTestData (check file exists)
  - ✓ Partial override pattern implemented (check factory methods accept Maps)
  - ✓ 3+ reuse rule enforced (check all repeated responses use builder)
  - ✓ Default values documented (check comments explain "typical device", etc.)
  - Document any section 6 guidance that was unclear

- [ ] T024 [US3] Validate against constitution v2.2 Section 7 (Three-Layer Testing):
  - ✓ Service layer: ≥90% coverage (run coverage report)
  - ✓ Provider layer: ≥85% coverage (run coverage report)
  - ✓ State layer: ≥90% coverage (run coverage report)
  - ✓ mocktail used for all mocking (grep for "Mock" classes in tests)
  - ✓ All 33+ tests passing (run test suite)
  - ✓ 0 lint warnings (flutter analyze)
  - ✓ Test file organization matches Section 7 guidelines
  - Document any section 7 guidance that was unclear

#### Documentation of Validation Results

- [ ] T025 [US3] Create validation report documenting:
  - Constitution compliance checklist (all items passed)
  - Coverage metrics (Service %, Provider %, State %, Overall %)
  - Test count by layer (Service 7+, Provider 3-5, State 20-30)
  - Any gaps or unclear guidelines in constitution
  - Recommendations for constitution v2.3 improvements
  - Save report in `specs/002-dmz-refactor/validation-report.md`

**Checkpoint**: User Story 3 complete - DMZ refactor fully validated against constitution v2.2, all patterns proven effective and guidance verified for clarity. Constitution validation loop complete; any identified gaps noted for future refinement.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final cleanup, documentation, and preparation for code review

- [ ] T026 Update `specs/002-dmz-refactor/data-model.md` with final entity definitions from implementation (DmzSettings, Service methods, TestData structure)
- [ ] T027 Create `specs/002-dmz-refactor/contracts/service-interface.md` with final Service layer method signatures and examples
- [ ] T028 Create `specs/002-dmz-refactor/quickstart.md` with developer guidance on how to extend DMZ service or follow this pattern for other modules
- [ ] T029 [P] Run final `flutter analyze` on entire DMZ module to ensure 0 warnings across all files
- [ ] T030 [P] Run `dart format` on all DMZ implementation and test files
- [ ] T031 Run complete test suite one final time to verify all tests pass: `flutter test test/page/advanced_settings/dmz/`
- [ ] T032 Prepare commit message and verify all changes are staged for PR

**Checkpoint**: Refactor complete - all code polished, documentation finalized, tests passing, ready for code review and merge.

---

## Implementation Strategy: MVP First

### MVP Scope (Ready to Deploy)
**User Story 1 (P1)** - Complete after Phase 3:
- Three-layer architecture refactored ✅
- Service layer fully implemented ✅
- Provider layer cleaned of JNAP code ✅
- All tests passing ✅
- Backward compatibility maintained ✅

This MVP delivers core value: architectural compliance, maintainable code, and proper separation of concerns.

### Enhancement Scope (Polish)
**User Story 2 (P1)** - Complete after Phase 4:
- TestData Builder pattern applied ✅
- Test code verbosity reduced ✅
- Pattern proven effective ✅

This enhancement proves pattern effectiveness and serves as reference for future modules.

### Validation Scope (Knowledge Transfer)
**User Story 3 (P2)** - Complete after Phase 5:
- Constitution v2.2 patterns validated ✅
- Unclear guidelines identified ✅
- Documented for future improvements ✅

This validation ensures new constitution patterns are practical and helps refine them for v2.3.

---

## Task Summary

| Phase | ID | Count | Purpose |
|-------|------|-------|---------|
| 1. Setup | T001-T002 | 2 | Infrastructure verification |
| 2. Foundational | T003-T007 | 5 | Blocking prerequisites |
| 3. US1 - Architecture | T008-T019 | 12 | Three-layer refactor + tests |
| 4. US2 - TestData Builder | T020-T022 | 3 | Mock data optimization |
| 5. US3 - Constitution Validation | T023-T025 | 3 | Pattern validation |
| 6. Polish | T026-T032 | 7 | Cleanup & documentation |
| **Total** | **T001-T032** | **32** | Complete refactor |

---

## Coverage Targets

| Layer | Target | Tasks | Success Criteria |
|-------|--------|-------|------------------|
| Service | ≥90% | T011 (tests), T015 (validation) | `flutter test` + coverage report |
| Provider | ≥85% | T013 (tests), T015 (validation) | `flutter test` + coverage report |
| State | ≥90% | T014 (tests), T015 (validation) | `flutter test` + coverage report |
| **Overall** | **≥80%** | T015, T017 | `flutter test` + coverage report |

---

## Quality Gates

✅ **All gates must pass before code review**:

1. **Lint**: `flutter analyze lib/page/advanced_settings/dmz/` → 0 warnings
2. **Format**: `dart format` → no changes
3. **Tests**: `flutter test test/page/advanced_settings/dmz/` → all pass
4. **Coverage**: Service ≥90%, Provider ≥85%, State ≥90%
5. **Architecture**: 0 JNAP imports in Provider layer (grep validation)
6. **Compatibility**: All existing DMZ UI tests pass
7. **Documentation**: All public APIs have DartDoc

---

## Next Steps

→ **Ready to Begin Phase 1**

1. Start with T001-T002 (Setup verification)
2. Continue with T003-T007 (Foundational infrastructure)
3. Parallelize T008-T014 where possible (test files can be written before implementation)
4. Follow task ordering to maintain dependency correctness
5. After each phase checkpoint, verify against success criteria before moving forward

Mark tasks complete as they are finished. The overall feature is complete when all tasks T001-T032 are checked off and all quality gates pass.
