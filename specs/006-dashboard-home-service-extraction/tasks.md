# Tasks: DashboardHome Service Extraction

**Input**: Design documents from `/specs/006-dashboard-home-service-extraction/`
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/dashboard_home_service_contract.md

**Tests**: Tests are REQUIRED per spec.md (SC-003: ≥90% coverage for DashboardHomeService)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

## Path Conventions

- **Source**: `lib/page/dashboard/`
- **Tests**: `test/page/dashboard/`
- **Test Data**: `test/mocks/test_data/`

---

## Phase 1: Setup

**Purpose**: Create directory structure and test infrastructure

- [ ] T001 Create services directory at `lib/page/dashboard/services/`
- [ ] T002 [P] Create test services directory at `test/page/dashboard/services/`

**Checkpoint**: Directory structure ready for implementation

---

## Phase 2: Foundational (Test Data Builder)

**Purpose**: Create test infrastructure required by both user stories

**⚠️ CRITICAL**: Test data builder is needed before any tests can be written

- [ ] T003 Create DashboardHomeTestData class in `test/mocks/test_data/dashboard_home_test_data.dart` with:
  - `createDashboardManagerState()` factory for mock DashboardManagerState
  - `createDeviceManagerState()` factory for mock DeviceManagerState
  - `createRouterRadio()` helper for radio configurations
  - `createGuestRadioInfo()` helper for guest radio configurations
  - `createLinksysDevice()` helper for device mocks

**Checkpoint**: Test data builder ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Architecture Compliance Refactoring (Priority: P1) 🎯 MVP

**Goal**: Extract transformation logic to DashboardHomeService, remove JNAP model imports from Provider layer

**Independent Test**: `grep -r "import.*jnap/models" lib/page/dashboard/providers/` returns zero results

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T004 [P] [US1] Create service test file `test/page/dashboard/services/dashboard_home_service_test.dart` with test group structure
- [ ] T005 [P] [US1] Add test: 'returns correct state with main WiFi networks grouped by band'
- [ ] T006 [P] [US1] Add test: 'returns correct state with guest WiFi when guest radios exist'
- [ ] T007 [P] [US1] Add test: 'returns empty WiFi list when no radios exist'
- [ ] T008 [P] [US1] Add test: 'sets isAnyNodesOffline true when nodes are offline'
- [ ] T009 [P] [US1] Add test: 'sets isFirstPolling true when lastUpdateTime is zero'
- [ ] T010 [P] [US1] Add test: 'handles null deviceInfo for port layout'

### Implementation for User Story 1

- [ ] T011 [US1] Create DashboardHomeService class in `lib/page/dashboard/services/dashboard_home_service.dart` with:
  - `dashboardHomeServiceProvider` provider definition
  - `DashboardHomeService` class with const constructor
  - `buildDashboardHomeState()` public method signature
  - Required imports from JNAP models and utilities

- [ ] T012 [US1] Implement `_buildMainWiFiItems()` private method in `lib/page/dashboard/services/dashboard_home_service.dart`:
  - Group radios by band using `groupFoldBy`
  - Count connected devices per band
  - Create DashboardWiFiUIModel for each band group

- [ ] T013 [US1] Implement `_buildGuestWiFiItem()` private method in `lib/page/dashboard/services/dashboard_home_service.dart`:
  - Check if guest radios exist
  - Count online guest devices
  - Create DashboardWiFiUIModel with isGuest=true

- [ ] T014 [US1] Implement `_createWiFiItemFromMainRadios()` private method in `lib/page/dashboard/services/dashboard_home_service.dart`:
  - Extract SSID, password, radioIDs from RouterRadio list
  - Replace DashboardWiFiUIModel.fromMainRadios() factory logic

- [ ] T015 [US1] Implement `_createWiFiItemFromGuestRadios()` private method in `lib/page/dashboard/services/dashboard_home_service.dart`:
  - Extract guest SSID, password, radioIDs from GuestRadioInfo list
  - Replace DashboardWiFiUIModel.fromGuestRadios() factory logic

- [ ] T016 [US1] Complete `buildDashboardHomeState()` implementation in `lib/page/dashboard/services/dashboard_home_service.dart`:
  - Call _buildMainWiFiItems() and _buildGuestWiFiItem()
  - Determine isAnyNodesOffline from nodeDevices
  - Extract WAN type and detected WAN type
  - Determine isFirstPolling from lastUpdateTime
  - Get master icon using routerIconTestByModel()
  - Get port layout using isHorizontalPorts()
  - Return complete DashboardHomeState

- [ ] T017 [US1] Refactor DashboardHomeNotifier in `lib/page/dashboard/providers/dashboard_home_provider.dart`:
  - Add import for DashboardHomeService
  - Remove import for `core/jnap/models/radio_info.dart`
  - Update build() to use service.buildDashboardHomeState()
  - Remove createState() method (logic moved to service)

- [ ] T018 [US1] Refactor DashboardHomeState in `lib/page/dashboard/providers/dashboard_home_state.dart`:
  - Remove import for `core/jnap/models/guest_radio_settings.dart`
  - Remove import for `core/jnap/models/radio_info.dart`
  - Remove DashboardWiFiUIModel.fromMainRadios() factory method
  - Remove DashboardWiFiUIModel.fromGuestRadios() factory method

- [ ] T019 [US1] Run architecture compliance check:
  - Execute `grep -r "import.*jnap/models" lib/page/dashboard/providers/`
  - Verify zero results returned

**Checkpoint**: User Story 1 complete - Architecture compliant, all tests passing

---

## Phase 4: User Story 2 - Service Layer Testability (Priority: P2)

**Goal**: Complete test coverage for edge cases and transformation logic

**Independent Test**: Run `flutter test test/page/dashboard/services/` - all tests pass with ≥90% coverage

### Tests for User Story 2

- [ ] T020 [P] [US2] Add test: 'correctly counts connected devices per band' in `test/page/dashboard/services/dashboard_home_service_test.dart`
- [ ] T021 [P] [US2] Add test: 'does not add guest WiFi when guest network disabled' in `test/page/dashboard/services/dashboard_home_service_test.dart`
- [ ] T022 [P] [US2] Add test: 'correctly extracts WAN type from wanStatus' in `test/page/dashboard/services/dashboard_home_service_test.dart`
- [ ] T023 [P] [US2] Add test: 'correctly extracts detectedWANType from wanStatus' in `test/page/dashboard/services/dashboard_home_service_test.dart`
- [ ] T024 [P] [US2] Add test: 'correctly determines master icon from deviceList' in `test/page/dashboard/services/dashboard_home_service_test.dart`
- [ ] T025 [P] [US2] Add test: 'correctly determines horizontal port layout' in `test/page/dashboard/services/dashboard_home_service_test.dart`
- [ ] T026 [P] [US2] Add test: 'passes through uptime, wanConnection, lanConnections correctly' in `test/page/dashboard/services/dashboard_home_service_test.dart`

### Implementation for User Story 2

- [ ] T027 [US2] Add edge case handling to DashboardHomeService if any test reveals missing logic in `lib/page/dashboard/services/dashboard_home_service.dart`
- [ ] T028 [US2] Run test coverage check: `flutter test --coverage test/page/dashboard/services/`
- [ ] T029 [US2] Verify ≥90% coverage for DashboardHomeService methods

**Checkpoint**: User Story 2 complete - Full test coverage achieved

---

## Phase 5: Polish & Verification

**Purpose**: Final validation and cleanup

- [ ] T030 Run `flutter analyze lib/page/dashboard/` - verify no new warnings
- [ ] T031 Run `dart format lib/page/dashboard/` - apply formatting
- [ ] T032 Run `dart format test/page/dashboard/` - apply formatting to tests
- [ ] T033 Run full test suite: `flutter test test/page/dashboard/`
- [ ] T034 Manual verification: Launch app and verify dashboard home displays correctly

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational phase completion
- **User Story 2 (Phase 4)**: Can start after Phase 3 tests are written (T004-T010)
- **Polish (Phase 5)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: No dependencies on other stories - this is the core refactoring
- **User Story 2 (P2)**: Extends US1 test coverage - requires US1 implementation complete

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Service methods before provider refactoring
- Provider refactoring before state refactoring
- Architecture check after all refactoring complete

### Parallel Opportunities

- T001-T002: Can run in parallel (different directories)
- T004-T010: All US1 tests can be written in parallel
- T011-T016: Service implementation is sequential (method dependencies)
- T017-T018: Provider and State refactoring can run in parallel
- T020-T026: All US2 tests can be written in parallel

---

## Parallel Example: User Story 1 Tests

```bash
# Launch all US1 tests in parallel:
Task: T004 "Create service test file structure"
Task: T005 "Add test: main WiFi networks grouped by band"
Task: T006 "Add test: guest WiFi when guest radios exist"
Task: T007 "Add test: empty WiFi list"
Task: T008 "Add test: isAnyNodesOffline"
Task: T009 "Add test: isFirstPolling"
Task: T010 "Add test: null deviceInfo"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T002)
2. Complete Phase 2: Foundational (T003)
3. Complete Phase 3: User Story 1 (T004-T019)
4. **STOP and VALIDATE**: Run architecture compliance check
5. Core refactoring complete - dashboard functions correctly

### Incremental Delivery

1. Setup + Foundational → Infrastructure ready
2. Add User Story 1 → Architecture compliant → **MVP Complete**
3. Add User Story 2 → Full test coverage → Production ready
4. Polish → Code quality verified

---

## Notes

- [P] tasks = different files, no dependencies
- [US1] = Architecture Compliance Refactoring (core goal)
- [US2] = Service Layer Testability (extended testing)
- Tests must fail before implementation begins
- Commit after each logical task group
- Stop at any checkpoint to validate independently
