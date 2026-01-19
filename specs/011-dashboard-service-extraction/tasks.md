# Tasks: Dashboard Manager Service Extraction

**Input**: Design documents from `/specs/005-dashboard-service-extraction/`
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓, quickstart.md ✓

**Tests**: Included per constitution.md Article I (Service ≥90%, Provider ≥85% coverage required)

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

```text
lib/core/jnap/
├── providers/
│   └── dashboard_manager_provider.dart  # MODIFY
└── services/
    └── dashboard_manager_service.dart   # CREATE

test/core/jnap/
├── providers/
│   └── dashboard_manager_provider_test.dart  # CREATE
├── services/
│   └── dashboard_manager_service_test.dart   # CREATE
└── test_data/
    └── dashboard_manager_test_data.dart      # CREATE

lib/core/errors/
└── service_error.dart  # MODIFY (if needed)
```

---

## Phase 1: Setup

**Purpose**: Verify prerequisites and create file structure

- [x] T001 Verify DeviceManagerService reference exists at `lib/core/jnap/services/device_manager_service.dart`
- [x] T002 [P] Verify test directory exists: `test/core/jnap/services/` (create if needed)
- [x] T003 [P] Verify test directory exists: `test/core/jnap/providers/` (create if needed)
- [x] T004 Check if `SerialNumberMismatchError` exists in `lib/core/errors/service_error.dart`
- [x] T005 Check if `ConnectivityError` exists in `lib/core/errors/service_error.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add required ServiceError types before service implementation

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T006 Add `SerialNumberMismatchError` to `lib/core/errors/service_error.dart` (if not exists from T004)
- [x] T007 Add `ConnectivityError` to `lib/core/errors/service_error.dart` (if not exists from T005)

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Polling Data Transformation (Priority: P1) 🎯 MVP

**Goal**: Transform dashboard polling data into UI state via Service without exposing JNAP details to Provider

**Independent Test**: Provide mock CoreTransactionData → verify DashboardManagerState contains correctly transformed values

### Tests for User Story 1

- [ ] T008 [P] [US1] Create test data builder class `DashboardManagerTestData` in `test/mocks/test_data/dashboard_manager_test_data.dart`
- [ ] T009 [P] [US1] Add `createDeviceInfoSuccess()` method to test data builder
- [ ] T010 [P] [US1] Add `createRadioInfoSuccess()` method to test data builder
- [ ] T011 [P] [US1] Add `createGuestRadioSettingsSuccess()` method to test data builder
- [ ] T012 [P] [US1] Add `createSystemStatsSuccess()` method to test data builder
- [ ] T013 [P] [US1] Add `createEthernetPortConnectionsSuccess()` method to test data builder
- [ ] T014 [P] [US1] Add `createLocalTimeSuccess()` method to test data builder
- [ ] T015 [P] [US1] Add `createSoftSKUSettingsSuccess()` method to test data builder
- [ ] T016 [US1] Add `createSuccessfulPollingData()` method combining all JNAP responses
- [ ] T017 [US1] Create service test file with transformPollingData test group in `test/core/jnap/services/dashboard_manager_service_test.dart`
- [ ] T018 [US1] Add test: transformPollingData returns default state when pollingResult is null
- [ ] T019 [US1] Add test: transformPollingData returns complete state when all actions succeed
- [ ] T020 [US1] Add test: transformPollingData returns partial state when some actions fail
- [ ] T021 [US1] Add test: transformPollingData correctly parses each JNAP action response
- [ ] T022 [US1] Add test: transformPollingData uses default localTime when parsing fails

### Implementation for User Story 1

- [ ] T023 [US1] Create service file with provider definition in `lib/core/jnap/services/dashboard_manager_service.dart`
- [ ] T024 [US1] Create `DashboardManagerService` class with `RouterRepository` constructor injection
- [ ] T025 [US1] Implement `transformPollingData()` method - extract JNAP data from polling result
- [ ] T026 [US1] Move `_getMainRadioList()` helper from provider to service
- [ ] T027 [US1] Move `_getGuestRadioList()` helper from provider to service
- [ ] T028 [US1] Implement date/time parsing with fallback to current time
- [ ] T029 [US1] Implement system stats extraction (cpuLoad, memoryLoad, uptimes)
- [ ] T030 [US1] Implement ethernet port connections extraction (wanConnection, lanConnections)
- [ ] T031 [US1] Implement SoftSKU settings extraction (skuModelNumber)
- [ ] T032 [US1] Run service tests for transformPollingData: `flutter test test/core/jnap/services/dashboard_manager_service_test.dart`

**Checkpoint**: transformPollingData() fully functional and tested

---

## Phase 4: User Story 2 - Router Connectivity Check (Priority: P2)

**Goal**: Verify router accessibility and serial number matching via Service

**Independent Test**: Mock RouterRepository.send() → verify SN matching logic and error handling

### Tests for User Story 2

- [ ] T033 [US2] Add checkRouterIsBack test group to `test/core/jnap/services/dashboard_manager_service_test.dart`
- [ ] T034 [US2] Add test: checkRouterIsBack returns NodeDeviceInfo when SN matches
- [ ] T035 [US2] Add test: checkRouterIsBack throws SerialNumberMismatchError when SN doesn't match
- [ ] T036 [US2] Add test: checkRouterIsBack throws ConnectivityError when router unreachable
- [ ] T037 [US2] Add test: checkRouterIsBack maps JNAPError to ServiceError correctly

### Implementation for User Story 2

- [ ] T038 [US2] Implement `checkRouterIsBack(String expectedSerialNumber)` method in service
- [ ] T039 [US2] Implement `_mapJnapError()` helper for JNAPError → ServiceError conversion
- [ ] T040 [US2] Add serial number comparison logic with SerialNumberMismatchError
- [ ] T041 [US2] Add connectivity error handling with ConnectivityError
- [ ] T042 [US2] Run service tests for checkRouterIsBack: `flutter test test/core/jnap/services/dashboard_manager_service_test.dart`

**Checkpoint**: checkRouterIsBack() fully functional and tested

---

## Phase 5: User Story 3 - Device Info Retrieval (Priority: P2)

**Goal**: Fetch device info with caching support via Service

**Independent Test**: Verify cache usage when available, API call when cache is null

### Tests for User Story 3

- [ ] T043 [US3] Add checkDeviceInfo test group to `test/core/jnap/services/dashboard_manager_service_test.dart`
- [ ] T044 [US3] Add test: checkDeviceInfo returns cached value immediately when available
- [ ] T045 [US3] Add test: checkDeviceInfo makes API call when cached value is null
- [ ] T046 [US3] Add test: checkDeviceInfo throws ServiceError on API failure

### Implementation for User Story 3

- [ ] T047 [US3] Implement `checkDeviceInfo(NodeDeviceInfo? cachedDeviceInfo)` method in service
- [ ] T048 [US3] Add cache check logic - return immediately if cached value exists
- [ ] T049 [US3] Add API call with error handling for cache miss scenario
- [ ] T050 [US3] Run service tests for checkDeviceInfo: `flutter test test/core/jnap/services/dashboard_manager_service_test.dart`

**Checkpoint**: checkDeviceInfo() fully functional and tested

---

## Phase 6: User Story 4 - Provider Architecture Compliance (Priority: P1)

**Goal**: Refactor Provider to delegate all JNAP operations to Service, removing JNAP imports

**Independent Test**: Static analysis - Provider has zero imports from jnap/models, jnap/actions, jnap/result

### Tests for User Story 4

- [ ] T051 [US4] Create provider test file in `test/core/jnap/providers/dashboard_manager_provider_test.dart`
- [ ] T052 [US4] Add test: build() delegates to service.transformPollingData()
- [ ] T053 [US4] Add test: checkRouterIsBack() delegates to service with correct SN
- [ ] T054 [US4] Add test: checkDeviceInfo() delegates to service with cached state

### Implementation for User Story 4

- [ ] T055 [US4] Add service import to `lib/core/jnap/providers/dashboard_manager_provider.dart`
- [ ] T056 [US4] Refactor `build()` to delegate to `service.transformPollingData()`
- [ ] T057 [US4] Remove `createState()` method from provider (moved to service)
- [ ] T058 [US4] Remove `_getMainRadioList()` helper from provider (moved to service)
- [ ] T059 [US4] Remove `_getGuestRadioList()` helper from provider (moved to service)
- [ ] T060 [US4] Refactor `checkRouterIsBack()` to delegate to service
- [ ] T061 [US4] Refactor `checkDeviceInfo()` to delegate to service
- [ ] T062 [US4] Remove JNAP imports from provider: `jnap/actions/better_action.dart`
- [ ] T063 [US4] Remove JNAP imports from provider: `jnap/models/device_info.dart`
- [ ] T064 [US4] Remove JNAP imports from provider: `jnap/models/guest_radio_settings.dart`
- [ ] T065 [US4] Remove JNAP imports from provider: `jnap/models/radio_info.dart`
- [ ] T066 [US4] Remove JNAP imports from provider: `jnap/models/soft_sku_settings.dart`
- [ ] T067 [US4] Remove JNAP imports from provider: `jnap/result/jnap_result.dart`
- [ ] T068 [US4] Remove JNAP imports from provider: `jnap/router_repository.dart`
- [ ] T069 [US4] Keep `saveSelectedNetwork()` method unchanged in provider
- [ ] T070 [US4] Run provider tests: `flutter test test/core/jnap/providers/dashboard_manager_provider_test.dart`

**Checkpoint**: Provider fully refactored with zero JNAP imports

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Verification, documentation, and final validation

- [ ] T071 Run architecture compliance check: `grep -r "import.*jnap/models" lib/core/jnap/providers/dashboard_manager_provider.dart` (expect 0 results)
- [ ] T072 Run architecture compliance check: `grep -r "import.*jnap/result" lib/core/jnap/providers/dashboard_manager_provider.dart` (expect 0 results)
- [ ] T073 Run architecture compliance check: `grep -r "import.*jnap/actions" lib/core/jnap/providers/dashboard_manager_provider.dart` (expect 0 results)
- [ ] T074 Run `flutter analyze` and fix any issues in modified files
- [ ] T075 Run `dart format` on all modified files
- [ ] T076 Run all service tests: `flutter test test/core/jnap/services/dashboard_manager_service_test.dart`
- [ ] T077 Run all provider tests: `flutter test test/core/jnap/providers/dashboard_manager_provider_test.dart`
- [ ] T078 Run full test suite: `./run_tests.sh`
- [ ] T079 Verify test coverage meets requirements (Service ≥90%, Provider ≥85%)
- [ ] T080 Manual verification: Dashboard displays correctly after refactoring

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1: Setup ─────────────────────────────┐
                                            │
Phase 2: Foundational ──────────────────────┼─── BLOCKS ALL USER STORIES
                                            │
                    ┌───────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │ Phase 3: US1 (P1) MVP │ ◄── transformPollingData
        └───────────┬───────────┘
                    │
        ┌───────────▼───────────┐
        │ Phase 4: US2 (P2)     │ ◄── checkRouterIsBack
        └───────────┬───────────┘
                    │
        ┌───────────▼───────────┐
        │ Phase 5: US3 (P2)     │ ◄── checkDeviceInfo
        └───────────┬───────────┘
                    │
        ┌───────────▼───────────┐
        │ Phase 6: US4 (P1)     │ ◄── Provider refactoring
        └───────────┬───────────┘
                    │
        ┌───────────▼───────────┐
        │ Phase 7: Polish       │
        └───────────────────────┘
```

### User Story Dependencies

| Story | Depends On | Can Run With |
|-------|------------|--------------|
| **US1** (transformPollingData) | Foundational | Independent |
| **US2** (checkRouterIsBack) | US1 (service file exists) | After US1 |
| **US3** (checkDeviceInfo) | US1 (service file exists) | After US1, parallel with US2 |
| **US4** (Provider refactoring) | US1, US2, US3 (all service methods) | After US1-3 |

### Within Each User Story

1. Test data builders first (parallel)
2. Tests defined (parallel)
3. Implementation
4. Run tests to verify

### Parallel Opportunities

**Phase 1**: T002, T003 can run in parallel
**Phase 3**: T008-T015 (test data builder methods) can run in parallel
**Phase 4-5**: US2 and US3 can potentially run in parallel after US1
**Phase 6**: T062-T068 (import removals) can be done in single refactor step

---

## Parallel Example: User Story 1 Test Data Builder

```bash
# Launch all test data builder methods together:
Task: "Add createDeviceInfoSuccess() method" (T009)
Task: "Add createRadioInfoSuccess() method" (T010)
Task: "Add createGuestRadioSettingsSuccess() method" (T011)
Task: "Add createSystemStatsSuccess() method" (T012)
Task: "Add createEthernetPortConnectionsSuccess() method" (T013)
Task: "Add createLocalTimeSuccess() method" (T014)
Task: "Add createSoftSKUSettingsSuccess() method" (T015)
```

---

## Implementation Strategy

### MVP First (User Story 1 + 4)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: US1 (transformPollingData)
4. Complete Phase 6: US4 (Provider refactoring for build() only)
5. **STOP and VALIDATE**: Dashboard displays correctly
6. Continue with US2, US3 for full feature

### Recommended Order

1. Setup + Foundational → Foundation ready
2. US1 (transformPollingData) → Core functionality
3. US2 (checkRouterIsBack) → Connectivity check
4. US3 (checkDeviceInfo) → Caching support
5. US4 (Provider refactoring) → Architecture compliance
6. Polish → Final validation

### Quick Win Strategy

For fastest working implementation:
1. T001-T007 (Setup + Foundational)
2. T023-T031 (US1 Implementation only)
3. T055-T069 (US4 Provider refactoring)
4. T071-T080 (Verification)

Then backfill tests if time permits.

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story
- Each user story should be independently testable after completion
- Commit after each phase or logical group
- Reference: `lib/core/jnap/services/device_manager_service.dart` for implementation patterns
