# Tasks: Router Password Service Layer Extraction

**Input**: Design documents from `/specs/002-router-password-service/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/router_password_service_contract.md

**Tests**: Test tasks are included and integrated with implementation (TDD approach per project requirements)

**Organization**: Tasks are grouped by user story (developer story) to enable structured implementation and testing of each architectural milestone.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which developer story this task belongs to (e.g., DS1, DS2, DS3)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter Project**: `lib/` for source, `test/` for tests
- Service Layer: `lib/page/instant_admin/services/`
- Provider Layer: `lib/page/instant_admin/providers/`
- Test Data: `test/mocks/test_data/`
- Service Tests: `test/page/instant_admin/services/`
- Provider Tests: `test/page/instant_admin/providers/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and directory structure

- [X] T001 Create services directory: `lib/page/instant_admin/services/`
- [X] T002 Create service test directory: `test/page/instant_admin/services/`
- [X] T003 Create test data directory: `test/mocks/test_data/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Test Data Builder that ALL testing depends on

**⚠️ CRITICAL**: No service or provider testing can begin until this phase is complete

- [X] T004 Create RouterPasswordTestData class in test/mocks/test_data/router_password_test_data.dart with factory methods for JNAP mock responses
- [X] T005 Implement createFetchConfiguredSuccess() factory method in RouterPasswordTestData
- [X] T006 [P] Implement createPasswordHintSuccess() factory method in RouterPasswordTestData
- [X] T007 [P] Implement createSetPasswordSuccess() factory method in RouterPasswordTestData
- [X] T008 [P] Implement createVerifyCodeSuccess() factory method in RouterPasswordTestData
- [X] T009 [P] Implement createVerifyCodeError() factory method in RouterPasswordTestData
- [X] T010 [P] Implement createVerifyCodeExhaustedError() factory method in RouterPasswordTestData
- [X] T011 [P] Implement createGenericError() factory method in RouterPasswordTestData
- [X] T012 Verify RouterPasswordTestData compiles: `flutter analyze test/mocks/test_data/router_password_test_data.dart`

**Checkpoint**: Test Data Builder ready - service implementation and testing can now begin

---

## Phase 3: Developer Story 1 - Service Layer Extraction (Priority: P1) 🎯 MVP

**Goal**: Extract JNAP communication logic from RouterPasswordNotifier into stateless RouterPasswordService following Service Layer Principle (Constitution Article VI)

**Independent Test**: Create RouterPasswordService with mocked RouterRepository and FlutterSecureStorage, verify all JNAP methods work correctly without managing state

### Service Skeleton for Developer Story 1

- [X] T013 [DS1] Create RouterPasswordService class skeleton in lib/page/instant_admin/services/router_password_service.dart with constructor and method signatures
- [X] T014 [DS1] Add RouterRepository and FlutterSecureStorage constructor dependencies to RouterPasswordService
- [X] T015 [DS1] Define routerPasswordServiceProvider in lib/page/instant_admin/services/router_password_service.dart
- [X] T016 [DS1] Verify service skeleton compiles: `flutter analyze lib/page/instant_admin/services/router_password_service.dart`

### Service Implementation - fetchPasswordConfiguration() [DS1]

- [X] T017 [DS1] Implement fetchPasswordConfiguration() method in lib/page/instant_admin/services/router_password_service.dart (extract from RouterPasswordNotifier.fetch() lines 22-49)
- [X] T018 [DS1] Add JNAP fetchIsConfigured() call and result transformation in fetchPasswordConfiguration()
- [X] T019 [DS1] Add conditional getAdminPasswordHint JNAP call in fetchPasswordConfiguration()
- [X] T020 [DS1] Add FlutterSecureStorage read for pLocalPassword in fetchPasswordConfiguration()
- [X] T021 [DS1] Add exception handling (JNAPError, StorageError) in fetchPasswordConfiguration()

### Service Tests - fetchPasswordConfiguration() [DS1]

- [X] T022 [DS1] Create router_password_service_test.dart in test/page/instant_admin/services/ with test structure and mocks (MockRouterRepository, MockFlutterSecureStorage)
- [X] T023 [DS1] Write test: fetchPasswordConfiguration returns correct data when password is default (uses RouterPasswordTestData)
- [X] T024 [DS1] Write test: fetchPasswordConfiguration returns correct data when password is set by user
- [X] T025 [DS1] Write test: fetchPasswordConfiguration includes hint when password is not default
- [X] T026 [DS1] Write test: fetchPasswordConfiguration reads stored password from FlutterSecureStorage
- [X] T027 [DS1] Write test: fetchPasswordConfiguration throws JNAPError when JNAP call fails
- [X] T028 [DS1] Write test: fetchPasswordConfiguration throws StorageError when FlutterSecureStorage read fails

### Service Implementation - setPasswordWithResetCode() [DS1]

- [X] T029 [DS1] Implement setPasswordWithResetCode() method in lib/page/instant_admin/services/router_password_service.dart (extract from RouterPasswordNotifier.setAdminPasswordWithResetCode() lines 51-69)
- [X] T030 [DS1] Add JNAP setupSetAdminPassword call in setPasswordWithResetCode()
- [X] T031 [DS1] Add exception handling (JNAPError) in setPasswordWithResetCode()

### Service Tests - setPasswordWithResetCode() [DS1]

- [X] T032 [DS1] Write test: setPasswordWithResetCode succeeds with valid code
- [X] T033 [DS1] Write test: setPasswordWithResetCode throws JNAPError with invalid code
- [X] T034 [DS1] Write test: setPasswordWithResetCode throws JNAPError when JNAP call fails

### Service Implementation - setPasswordWithCredentials() [DS1]

- [X] T035 [DS1] Implement setPasswordWithCredentials() method in lib/page/instant_admin/services/router_password_service.dart (extract JNAP logic from RouterPasswordNotifier.setAdminPasswordWithCredentials() lines 71-91, exclude AuthProvider)
- [X] T036 [DS1] Add JNAP coreSetAdminPassword call in setPasswordWithCredentials()
- [X] T037 [DS1] Add exception handling (JNAPError) in setPasswordWithCredentials()

### Service Tests - setPasswordWithCredentials() [DS1]

- [X] T038 [DS1] Write test: setPasswordWithCredentials succeeds with valid credentials
- [X] T039 [DS1] Write test: setPasswordWithCredentials includes hint in JNAP payload when provided
- [X] T040 [DS1] Write test: setPasswordWithCredentials throws JNAPError on authentication failure
- [X] T041 [DS1] Write test: setPasswordWithCredentials throws JNAPError when JNAP call fails

### Service Implementation - verifyRecoveryCode() [DS1]

- [X] T042 [DS1] Implement verifyRecoveryCode() method in lib/page/instant_admin/services/router_password_service.dart (extract from RouterPasswordNotifier.checkRecoveryCode() lines 93-119)
- [X] T043 [DS1] Add JNAP verifyRouterResetCode call in verifyRecoveryCode()
- [X] T044 [DS1] Add error response parsing for attemptsRemaining in verifyRecoveryCode()
- [X] T045 [DS1] Add exception handling (JNAPError) in verifyRecoveryCode()

### Service Tests - verifyRecoveryCode() [DS1]

- [X] T046 [DS1] Write test: verifyRecoveryCode returns isValid=true for valid code
- [X] T047 [DS1] Write test: verifyRecoveryCode returns isValid=false with attemptsRemaining for invalid code
- [X] T048 [DS1] Write test: verifyRecoveryCode throws JNAPError for exhausted attempts (ErrorConsecutiveInvalidResetCodeEntered)
- [X] T049 [DS1] Write test: verifyRecoveryCode throws JNAPError when JNAP call fails

### Service Implementation - persistPassword() [DS1]

- [X] T050 [DS1] Implement persistPassword() method in lib/page/instant_admin/services/router_password_service.dart (wrapper for FlutterSecureStorage write)
- [X] T051 [DS1] Add FlutterSecureStorage write call with pLocalPassword key in persistPassword()
- [X] T052 [DS1] Add exception handling (StorageError) in persistPassword()

### Service Tests - persistPassword() [DS1]

- [X] T053 [DS1] Write test: persistPassword successfully writes to FlutterSecureStorage
- [X] T054 [DS1] Write test: persistPassword throws StorageError when FlutterSecureStorage write fails

### Service Verification [DS1]

- [X] T055 [DS1] Run all RouterPasswordService tests: `flutter test test/page/instant_admin/services/router_password_service_test.dart`
- [X] T056 [DS1] Verify RouterPasswordService test coverage ≥90%: `flutter test --coverage test/page/instant_admin/services/`
- [X] T057 [DS1] Verify RouterPasswordService has no lint errors: `flutter analyze lib/page/instant_admin/services/router_password_service.dart`

**Checkpoint**: At this point, RouterPasswordService is complete, fully tested, and ready for integration with RouterPasswordNotifier

---

## Phase 4: Developer Story 2 - Notifier Refactoring (Priority: P2)

**Goal**: Refactor RouterPasswordNotifier to delegate all JNAP operations to RouterPasswordService, focusing notifier solely on state management

**Independent Test**: Verify RouterPasswordNotifier calls service methods instead of RouterRepository directly, and all UI operations continue to work identically

### Update Imports [DS2]

- [X] T058 [DS2] Add service import to lib/page/instant_admin/providers/router_password_provider.dart: `import 'package:privacy_gui/page/instant_admin/services/router_password_service.dart';`
- [X] T059 [DS2] Remove unused imports (dart:convert if not needed elsewhere) from lib/page/instant_admin/providers/router_password_provider.dart

### Refactor fetch() Method [DS2]

- [X] T060 [DS2] Replace JNAP logic in RouterPasswordNotifier.fetch() with service call (lib/page/instant_admin/providers/router_password_provider.dart lines 22-49)
- [X] T061 [DS2] Add try-catch block for JNAPError and StorageError in RouterPasswordNotifier.fetch()
- [X] T062 [DS2] Update state transformation to use service response map in RouterPasswordNotifier.fetch()

### Refactor setAdminPasswordWithResetCode() Method [DS2]

- [X] T063 [DS2] Replace JNAP send with service.setPasswordWithResetCode() call in RouterPasswordNotifier.setAdminPasswordWithResetCode()
- [X] T064 [DS2] Add try-catch block for JNAPError in RouterPasswordNotifier.setAdminPasswordWithResetCode()

### Refactor setAdminPasswordWithCredentials() Method [DS2]

- [X] T065 [DS2] Replace JNAP send with service.setPasswordWithCredentials() call in RouterPasswordNotifier.setAdminPasswordWithCredentials()
- [X] T066 [DS2] Keep AuthProvider.localLogin call in notifier (IMPORTANT: do not move to service per architecture decision)
- [X] T067 [DS2] Add try-catch block for JNAPError in RouterPasswordNotifier.setAdminPasswordWithCredentials()

### Refactor checkRecoveryCode() Method [DS2]

- [X] T068 [DS2] Replace JNAP send with service.verifyRecoveryCode() call in RouterPasswordNotifier.checkRecoveryCode()
- [X] T069 [DS2] Update state.remainingErrorAttempts handling from service response in RouterPasswordNotifier.checkRecoveryCode()
- [X] T070 [DS2] Add try-catch block for JNAPError in RouterPasswordNotifier.checkRecoveryCode()

### Provider Verification [DS2]

- [X] T071 [DS2] Verify RouterPasswordNotifier compiles: `flutter analyze lib/page/instant_admin/providers/router_password_provider.dart`
- [X] T072 [DS2] Verify architectural compliance - no JNAP model imports in router_password_provider: `grep "import.*jnap/models" lib/page/instant_admin/providers/router_password_provider.dart` (expect 0 results)
- [X] T073 [DS2] Verify architectural compliance - router_password views don't exist (password UI is part of other views)
- [X] T074 [DS2] Verify JNAP model imports exist in service: `grep -r "import.*jnap" lib/page/instant_admin/services/router_password_service.dart` (expect results found)

**Checkpoint**: At this point, RouterPasswordNotifier is refactored, delegates to service, and maintains backward compatibility

---

## Phase 5: Developer Story 3 - Comprehensive Test Coverage (Priority: P3)

**Goal**: Create comprehensive unit tests for refactored RouterPasswordNotifier to ensure safety net for future changes and verify no regressions

**Independent Test**: Run test suite and verify coverage meets requirements (Service ≥90% already verified, Provider ≥85% target)

### Provider Test Setup [DS3]

- [ ] T075 [DS3] Create router_password_provider_test.dart in test/page/instant_admin/providers/ with test structure and mocks (MockRouterPasswordService, MockAuthNotifier)
- [ ] T076 [DS3] Setup ProviderContainer with provider overrides for routerPasswordServiceProvider and authProvider in router_password_provider_test.dart

### Provider Tests - fetch() [DS3]

- [ ] T077 [DS3] Write test: RouterPasswordNotifier.fetch() updates state on successful service call
- [ ] T078 [DS3] Write test: RouterPasswordNotifier.fetch() updates state.isDefault correctly from service response
- [ ] T079 [DS3] Write test: RouterPasswordNotifier.fetch() updates state.isSetByUser correctly from service response
- [ ] T080 [DS3] Write test: RouterPasswordNotifier.fetch() updates state.hint correctly from service response
- [ ] T081 [DS3] Write test: RouterPasswordNotifier.fetch() updates state.adminPassword from service response
- [ ] T082 [DS3] Write test: RouterPasswordNotifier.fetch() sets state.error on JNAPError from service
- [ ] T083 [DS3] Write test: RouterPasswordNotifier.fetch() sets state.error on StorageError from service

### Provider Tests - setAdminPasswordWithResetCode() [DS3]

- [ ] T084 [DS3] Write test: RouterPasswordNotifier.setAdminPasswordWithResetCode() calls service with correct parameters
- [ ] T085 [DS3] Write test: RouterPasswordNotifier.setAdminPasswordWithResetCode() sets state.error on JNAPError from service

### Provider Tests - setAdminPasswordWithCredentials() [DS3]

- [ ] T086 [DS3] Write test: RouterPasswordNotifier.setAdminPasswordWithCredentials() calls service.setPasswordWithCredentials()
- [ ] T087 [DS3] Write test: RouterPasswordNotifier.setAdminPasswordWithCredentials() calls AuthProvider.localLogin after service success
- [ ] T088 [DS3] Write test: RouterPasswordNotifier.setAdminPasswordWithCredentials() calls fetch(true) after AuthProvider.localLogin
- [ ] T089 [DS3] Write test: RouterPasswordNotifier.setAdminPasswordWithCredentials() sets state.error on JNAPError from service

### Provider Tests - checkRecoveryCode() [DS3]

- [ ] T090 [DS3] Write test: RouterPasswordNotifier.checkRecoveryCode() returns true for valid code
- [ ] T091 [DS3] Write test: RouterPasswordNotifier.checkRecoveryCode() returns false for invalid code
- [ ] T092 [DS3] Write test: RouterPasswordNotifier.checkRecoveryCode() updates state.remainingErrorAttempts from service response
- [ ] T093 [DS3] Write test: RouterPasswordNotifier.checkRecoveryCode() sets state.error on JNAPError from service

### Provider Tests - State Flags [DS3]

- [ ] T094 [P] [DS3] Write test: RouterPasswordNotifier.setEdited() updates state.hasEdited correctly
- [ ] T095 [P] [DS3] Write test: RouterPasswordNotifier.setValidate() updates state.isValid correctly

### Provider Verification [DS3]

- [ ] T096 [DS3] Run all RouterPasswordNotifier tests: `flutter test test/page/instant_admin/providers/router_password_provider_test.dart`
- [ ] T097 [DS3] Verify RouterPasswordNotifier test coverage ≥85%: `flutter test --coverage test/page/instant_admin/providers/`
- [ ] T098 [DS3] Run all instant_admin tests together: `flutter test test/page/instant_admin/`

**Checkpoint**: All unit tests complete and coverage targets met (Service ≥90%, Provider ≥85%)

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final verification and validation of the refactoring

### Integration Verification

- [ ] T099 Run full test suite: `flutter test`
- [ ] T100 Verify overall test coverage ≥80%: `flutter test --coverage`
- [ ] T101 Verify all tests execute in <5 seconds (measure test execution time)
- [ ] T102 Run lint check on all modified files: `flutter analyze`
- [ ] T103 Run code formatting: `dart format lib/page/instant_admin/services/ lib/page/instant_admin/providers/`

### Manual Testing (Success Criteria SC-001)

- [ ] T104 Manual test: Launch app and navigate to router password settings
- [ ] T105 Manual test: Fetch password configuration displays correctly
- [ ] T106 Manual test: Set password with reset code completes successfully
- [ ] T107 Manual test: Set password with credentials completes successfully
- [ ] T108 Manual test: Verify recovery code validates correctly (valid/invalid codes)
- [ ] T109 Manual test: Verify error handling displays appropriate messages
- [ ] T110 Manual test: Verify all password operations match pre-refactoring behavior

### Final Validation

- [ ] T111 Review quickstart.md and verify all steps were completed correctly
- [ ] T112 Verify all Success Criteria from spec.md are met (SC-001 through SC-006)
- [ ] T113 Update CLAUDE.md if needed (run update-agent-context.sh if service pattern examples should be added)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all testing
- **Developer Story 1 (Phase 3)**: Depends on Foundational completion - Service extraction with unit tests
- **Developer Story 2 (Phase 4)**: Depends on DS1 completion - Cannot refactor notifier until service exists
- **Developer Story 3 (Phase 5)**: Depends on DS2 completion - Cannot test provider until refactored
- **Polish (Phase 6)**: Depends on DS1, DS2, DS3 completion

### Developer Story Dependencies

- **DS1 (Service Extraction)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **DS2 (Notifier Refactoring)**: MUST wait for DS1 complete - Requires working RouterPasswordService
- **DS3 (Test Coverage)**: MUST wait for DS2 complete - Requires refactored RouterPasswordNotifier

### Within Each Developer Story

**DS1 (Service Extraction)**:
- Skeleton before implementation
- Each method: implementation then tests (or TDD: test first, then implement)
- All methods must be complete before DS2 starts

**DS2 (Notifier Refactoring)**:
- Import updates before refactoring
- Each method: refactor then verify
- All methods refactored before DS3 starts

**DS3 (Test Coverage)**:
- Test setup before individual tests
- Tests can be written in parallel (different test groups)
- All tests must pass before Phase 6

### Parallel Opportunities

- **Phase 1 (Setup)**: All 3 directory creation tasks can run in parallel
- **Phase 2 (Foundational)**: Tasks T006-T011 (factory methods) can run in parallel after T005
- **DS1**: Within each service method group, tests can run in parallel (e.g., T023-T028 all test fetchPasswordConfiguration)
- **DS3**: Tasks T094-T095 (state flag tests) can run in parallel

---

## Parallel Example: Developer Story 1 - fetchPasswordConfiguration

```bash
# After implementing fetchPasswordConfiguration (T017-T021), launch all tests together:
Task T023: "Write test: fetchPasswordConfiguration returns correct data when password is default"
Task T024: "Write test: fetchPasswordConfiguration returns correct data when password is set by user"
Task T025: "Write test: fetchPasswordConfiguration includes hint when password is not default"
Task T026: "Write test: fetchPasswordConfiguration reads stored password from FlutterSecureStorage"
Task T027: "Write test: fetchPasswordConfiguration throws JNAPError when JNAP call fails"
Task T028: "Write test: fetchPasswordConfiguration throws StorageError when FlutterSecureStorage read fails"
```

---

## Implementation Strategy

### MVP First (Developer Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all testing)
3. Complete Phase 3: Developer Story 1 (Service Extraction)
4. **STOP and VALIDATE**: Test RouterPasswordService independently with ≥90% coverage
5. Review and approve before proceeding to notifier refactoring

### Incremental Delivery

1. Complete Setup + Foundational → Test Data Builder ready
2. Add Developer Story 1 → Service layer complete, fully tested, isolated ✅
3. Add Developer Story 2 → Notifier refactored, backward compatible ✅
4. Add Developer Story 3 → Full test coverage achieved ✅
5. Polish & Verify → Production-ready refactoring ✅

### Sequential Implementation (Recommended)

This refactoring MUST be done sequentially due to dependencies:

1. Complete all of DS1 (Service Extraction) first
2. Then complete DS2 (Notifier Refactoring)
3. Then complete DS3 (Test Coverage)
4. Finally, Phase 6 (Polish)

Cannot parallelize stories because DS2 requires DS1 complete, and DS3 requires DS2 complete.

---

## Notes

- **[P] tasks**: Different files, no dependencies - can run in parallel
- **[Story] label**: Maps task to specific developer story for traceability (DS1, DS2, DS3)
- **Sequential dependency**: DS1 → DS2 → DS3 (cannot skip or reorder)
- **Test approach**: TDD-friendly - write tests after or alongside each method implementation
- **Constitution compliance**: Article I (testing), Article VI (service layer), Article V (three-layer architecture)
- **Backward compatibility**: Critical constraint throughout - RouterPasswordNotifier public API unchanged
- **Coverage targets**: Service ≥90%, Provider ≥85%, Overall ≥80%
- Commit after each logical task or group
- Stop at any checkpoint to validate independently
- Avoid: vague tasks, architectural violations, breaking backward compatibility
