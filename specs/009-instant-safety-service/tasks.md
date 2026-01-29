# Tasks: InstantSafety Service Extraction

**Input**: Design documents from `/specs/004-instant-safety-service/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Required per constitution.md Article I (Service ≥90%, Provider ≥85% coverage)

**Organization**: Tasks organized by user story priority. All P1 stories must be completed together as they form a cohesive refactoring unit.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Includes exact file paths

## Path Conventions

Flutter mobile app structure:
- Source: `lib/page/instant_safety/`
- Tests: `test/page/instant_safety/`
- Test Data: `test/mocks/test_data/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create directory structure and test data builder

- [x] T001 Create services directory at `lib/page/instant_safety/services/`
- [x] T002 [P] Create test directories at `test/page/instant_safety/services/` and `test/page/instant_safety/providers/`
- [x] T003 [P] Create test data builder `InstantSafetyTestData` in `test/mocks/test_data/instant_safety_test_data.dart` with factory methods for LAN settings responses

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core service implementation that ALL user stories depend on

**CRITICAL**: No provider refactoring can begin until service is complete

- [x] T004 Create `InstantSafetyFetchResult` class in `lib/page/instant_safety/services/instant_safety_service.dart`
- [x] T005 Create `InstantSafetyService` class skeleton with constructor injection in `lib/page/instant_safety/services/instant_safety_service.dart`
- [x] T006 Create `instantSafetyServiceProvider` in `lib/page/instant_safety/services/instant_safety_service.dart`
- [x] T007 Add DNS configuration constants (Fortinet, OpenDNS) as private statics in `lib/page/instant_safety/services/instant_safety_service.dart`
- [x] T008 Move `DhcpOption`, `CompatibilityItem`, `CompatibilityFW` helper classes to `lib/page/instant_safety/services/instant_safety_service.dart`

**Checkpoint**: Service file structure ready - method implementation can now begin

---

## Phase 3: User Story 2 - Fetch Safe Browsing Settings (Priority: P1)

**Goal**: Service fetches LAN settings and determines safe browsing type from DNS configuration

**Independent Test**: Verify `fetchSettings()` returns correct `InstantSafetyType` based on mocked JNAP responses

### Tests for User Story 2

- [x] T009 [P] [US2] Create service test file `test/page/instant_safety/services/instant_safety_service_test.dart` with setup and mocks
- [x] T010 [P] [US2] Add test: `fetchSettings returns fortinet type when Fortinet DNS configured` in `test/page/instant_safety/services/instant_safety_service_test.dart`
- [x] T011 [P] [US2] Add test: `fetchSettings returns openDNS type when OpenDNS configured` in `test/page/instant_safety/services/instant_safety_service_test.dart`
- [x] T012 [P] [US2] Add test: `fetchSettings returns off type when no safe browsing DNS` in `test/page/instant_safety/services/instant_safety_service_test.dart`
- [x] T013 [P] [US2] Add test: `fetchSettings throws ServiceError on JNAP failure` in `test/page/instant_safety/services/instant_safety_service_test.dart`

### Implementation for User Story 2

- [x] T014 [US2] Implement `_determineSafeBrowsingType()` private helper in `lib/page/instant_safety/services/instant_safety_service.dart`
- [x] T015 [US2] Implement `fetchSettings()` method with JNAP call and DNS detection in `lib/page/instant_safety/services/instant_safety_service.dart`
- [x] T016 [US2] Implement `_mapJnapError()` private helper for error mapping in `lib/page/instant_safety/services/instant_safety_service.dart`

**Checkpoint**: Service can fetch and identify safe browsing type - run tests T009-T013

---

## Phase 4: User Story 3 - Save Safe Browsing Settings (Priority: P1)

**Goal**: Service saves safe browsing configuration by constructing appropriate DNS settings

**Independent Test**: Verify `saveSettings()` constructs correct JNAP payload for each safe browsing type

### Tests for User Story 3

- [x] T017 [P] [US3] Add test: `saveSettings with fortinet constructs Fortinet DNS payload` in `test/page/instant_safety/services/instant_safety_service_test.dart`
- [x] T018 [P] [US3] Add test: `saveSettings with openDNS constructs OpenDNS payload` in `test/page/instant_safety/services/instant_safety_service_test.dart`
- [x] T019 [P] [US3] Add test: `saveSettings with off clears DNS servers` in `test/page/instant_safety/services/instant_safety_service_test.dart`
- [x] T020 [P] [US3] Add test: `saveSettings throws InvalidInputError when LAN settings not cached` in `test/page/instant_safety/services/instant_safety_service_test.dart`
- [x] T021 [P] [US3] Add test: `saveSettings throws ServiceError on JNAP failure` in `test/page/instant_safety/services/instant_safety_service_test.dart`

### Implementation for User Story 3

- [x] T022 [US3] Implement `saveSettings()` method with DHCP construction logic in `lib/page/instant_safety/services/instant_safety_service.dart`

**Checkpoint**: Service can save all safe browsing types - run tests T017-T021

---

## Phase 5: User Story 4 - Check Fortinet Compatibility (Priority: P2)

**Goal**: Service checks device compatibility for Fortinet safe browsing

**Independent Test**: Verify `_checkFortinetCompatibility()` returns correct values based on device info

### Tests for User Story 4

- [x] T023 [P] [US4] Add test: `fetchSettings returns hasFortinet true for compatible device` in `test/page/instant_safety/services/instant_safety_service_test.dart`
- [x] T024 [P] [US4] Add test: `fetchSettings returns hasFortinet false for incompatible device` in `test/page/instant_safety/services/instant_safety_service_test.dart`
- [x] T025 [P] [US4] Add test: `fetchSettings returns hasFortinet false when deviceInfo null` in `test/page/instant_safety/services/instant_safety_service_test.dart`

### Implementation for User Story 4

- [x] T026 [US4] Implement `_checkFortinetCompatibility()` private helper in `lib/page/instant_safety/services/instant_safety_service.dart`
- [x] T027 [US4] Update `fetchSettings()` to call `_checkFortinetCompatibility()` with deviceInfo in `lib/page/instant_safety/services/instant_safety_service.dart`

**Checkpoint**: Service fully functional - all service tests should pass

---

## Phase 6: User Story 1 - Maintain Architecture Compliance (Priority: P1)

**Goal**: Refactor Provider and State to remove JNAP dependencies, delegate to service

**Independent Test**: Verify no JNAP model imports in Provider/State files via grep checks

### State Refactoring

- [x] T028 [US1] Remove `RouterLANSettings` import from `lib/page/instant_safety/providers/instant_safety_state.dart`
- [x] T029 [US1] Remove `lanSetting` field from `InstantSafetyStatus` class in `lib/page/instant_safety/providers/instant_safety_state.dart`
- [x] T030 [US1] Update `InstantSafetyStatus.copyWith()` to remove `lanSetting` parameter in `lib/page/instant_safety/providers/instant_safety_state.dart`
- [x] T031 [US1] Update `InstantSafetyStatus.toMap()` and `props` to remove `lanSetting` in `lib/page/instant_safety/providers/instant_safety_state.dart`
- [x] T032 [US1] Update `InstantSafetyState.fromMap()` to not parse `lanSetting` in `lib/page/instant_safety/providers/instant_safety_state.dart`

### Provider Refactoring

- [x] T033 [US1] Remove JNAP imports from `lib/page/instant_safety/providers/instant_safety_provider.dart`:
  - `core/jnap/actions/better_action.dart`
  - `core/jnap/command/base_command.dart`
  - `core/jnap/models/device_info.dart`
  - `core/jnap/models/lan_settings.dart`
  - `core/jnap/models/set_lan_settings.dart`
  - `core/jnap/result/jnap_result.dart`
  - `core/jnap/router_repository.dart`
- [x] T034 [US1] Add service and error imports to `lib/page/instant_safety/providers/instant_safety_provider.dart`:
  - `instant_safety_service.dart`
  - `core/errors/service_error.dart`
- [x] T035 [US1] Refactor `performFetch()` to delegate to `InstantSafetyService.fetchSettings()` in `lib/page/instant_safety/providers/instant_safety_provider.dart`
- [x] T036 [US1] Refactor `performSave()` to delegate to `InstantSafetyService.saveSettings()` in `lib/page/instant_safety/providers/instant_safety_provider.dart`
- [x] T037 [US1] Remove `_getSafeBrowsingType()` private method from `lib/page/instant_safety/providers/instant_safety_provider.dart`
- [x] T038 [US1] Remove `_hasFortinet()` private method from `lib/page/instant_safety/providers/instant_safety_provider.dart`
- [x] T039 [US1] Remove `DhcpOption`, `CompatibilityItem`, `CompatibilityFW` classes from `lib/page/instant_safety/providers/instant_safety_provider.dart`
- [x] T040 [US1] Remove `SafeBrowsingError` class from `lib/page/instant_safety/providers/instant_safety_provider.dart`
- [x] T041 [US1] Remove `fortinetSetting`, `openDNSSetting`, `compatibilityMap` constants from `lib/page/instant_safety/providers/instant_safety_provider.dart`
- [x] T042 [US1] Update error handling in provider to catch `ServiceError` instead of `JNAPError` in `lib/page/instant_safety/providers/instant_safety_provider.dart`

**Checkpoint**: Provider refactoring complete - verify no JNAP imports remain

---

## Phase 7: State and Provider Tests

**Purpose**: Add tests for refactored State and Provider classes

### State Tests

- [x] T043 [P] [US1] Create state test file `test/page/instant_safety/providers/instant_safety_state_test.dart`
- [x] T044 [P] [US1] Add tests for `InstantSafetySettings`: copyWith, equality, toMap in `test/page/instant_safety/providers/instant_safety_state_test.dart`
- [x] T045 [P] [US1] Add tests for `InstantSafetyStatus`: copyWith, equality, toMap in `test/page/instant_safety/providers/instant_safety_state_test.dart`
- [x] T046 [P] [US1] Add tests for `InstantSafetyState`: initial factory, copyWith, serialization in `test/page/instant_safety/providers/instant_safety_state_test.dart`

### Provider Tests

- [x] T047 [P] [US1] Create provider test file `test/page/instant_safety/providers/instant_safety_provider_test.dart` with setup and mocks
- [x] T048 [US1] Add test: `build triggers fetch` in `test/page/instant_safety/providers/instant_safety_provider_test.dart`
- [x] T049 [US1] Add test: `performFetch delegates to service and updates state` in `test/page/instant_safety/providers/instant_safety_provider_test.dart`
- [x] T050 [US1] Add test: `performSave delegates to service` in `test/page/instant_safety/providers/instant_safety_provider_test.dart`
- [x] T051 [US1] Add test: `setSafeBrowsingEnabled updates state correctly` in `test/page/instant_safety/providers/instant_safety_provider_test.dart`
- [x] T052 [US1] Add test: `setSafeBrowsingProvider updates state correctly` in `test/page/instant_safety/providers/instant_safety_provider_test.dart`

**Checkpoint**: All unit tests complete - verify coverage targets

---

## Phase 8: Polish & Verification

**Purpose**: Final verification and cleanup

- [x] T053 Run architecture compliance check: `grep -r "import.*jnap/models" lib/page/instant_safety/providers/` (expect 0 results)
- [x] T054 Run architecture compliance check: `grep -r "import.*jnap/result" lib/page/instant_safety/providers/` (expect 0 results)
- [x] T055 Run service JNAP import check: `grep -r "import.*jnap/models" lib/page/instant_safety/services/` (expect results)
- [x] T056 Run all instant_safety tests: `flutter test test/page/instant_safety/`
- [x] T057 Run coverage check: `flutter test --coverage test/page/instant_safety/` and verify Service ≥90%, Provider ≥85%
- [x] T058 Run static analysis: `flutter analyze lib/page/instant_safety/`
- [x] T059 Format code: `dart format lib/page/instant_safety/ test/page/instant_safety/`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS all service methods
- **US2 Fetch (Phase 3)**: Depends on Foundational - first service method
- **US3 Save (Phase 4)**: Depends on US2 (needs cached LAN settings from fetch)
- **US4 Fortinet (Phase 5)**: Depends on US2 (extends fetchSettings)
- **US1 Compliance (Phase 6)**: Depends on US2, US3, US4 - refactors provider to use service
- **Tests (Phase 7)**: Depends on US1 - tests the refactored code
- **Polish (Phase 8)**: Depends on all phases - final verification

### User Story Dependencies

```
Foundational (T004-T008)
         │
         ▼
    US2: Fetch ─────────────┐
    (T009-T016)             │
         │                  │
         ▼                  │
    US3: Save               │
    (T017-T022)             │
         │                  │
         ├──────────────────┤
         │                  │
         ▼                  ▼
    US4: Fortinet      US1: Compliance
    (T023-T027)        (T028-T052)
                            │
                            ▼
                     Polish (T053-T059)
```

### Parallel Opportunities

**Within Phase 1**:
- T002 and T003 can run in parallel

**Within Phase 3 (US2 Tests)**:
- T009, T010, T011, T012, T013 can all run in parallel (different test cases)

**Within Phase 4 (US3 Tests)**:
- T017, T018, T019, T020, T021 can all run in parallel

**Within Phase 5 (US4 Tests)**:
- T023, T024, T025 can all run in parallel

**Within Phase 7 (State/Provider Tests)**:
- T043, T044, T045, T046 can all run in parallel (state tests)
- T047 must complete before T048-T052

---

## Parallel Example: Service Tests

```bash
# Launch all US2 fetch tests together:
Task: "Add test: fetchSettings returns fortinet type when Fortinet DNS configured"
Task: "Add test: fetchSettings returns openDNS type when OpenDNS configured"
Task: "Add test: fetchSettings returns off type when no safe browsing DNS"
Task: "Add test: fetchSettings throws ServiceError on JNAP failure"

# Launch all US3 save tests together:
Task: "Add test: saveSettings with fortinet constructs Fortinet DNS payload"
Task: "Add test: saveSettings with openDNS constructs OpenDNS payload"
Task: "Add test: saveSettings with off clears DNS servers"
Task: "Add test: saveSettings throws InvalidInputError when LAN settings not cached"
Task: "Add test: saveSettings throws ServiceError on JNAP failure"
```

---

## Implementation Strategy

### MVP First (Service Implementation)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: US2 Fetch (with tests)
4. Complete Phase 4: US3 Save (with tests)
5. **STOP and VALIDATE**: Service fully functional

### Full Refactoring

6. Complete Phase 5: US4 Fortinet
7. Complete Phase 6: US1 Provider refactoring
8. Complete Phase 7: Provider/State tests
9. Complete Phase 8: Verification

### Incremental Delivery

Each checkpoint allows validation:
- After Phase 4: Service works independently (can be used by new provider)
- After Phase 6: Old provider refactored (architecture compliant)
- After Phase 8: Full test coverage verified

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- US2/US3/US4 are tightly coupled (form service implementation)
- US1 depends on service being complete
- Run architecture compliance checks (T053-T055) to verify success criteria
- Commit after each phase completion
