# Tasks: Device Manager Service Extraction

**Input**: Design documents from `/specs/001-device-manager-service-extraction/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/device_manager_service_contract.md, quickstart.md

**Tests**: Included per spec requirements (SC-003: Service ≥90%, SC-004: Provider ≥85%)

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **Source**: `lib/core/jnap/` (infrastructure code)
- **Tests**: `test/core/jnap/` (mirrors source structure)
- **Test Data**: `test/mocks/test_data/`

---

## Phase 1: Setup

**Purpose**: Create service infrastructure and test data builder

- [x] T001 Create services directory at `lib/core/jnap/services/`
- [x] T002 [P] Create test services directory at `test/core/jnap/services/`
- [x] T003 [P] Create test data builder file at `test/mocks/test_data/device_manager_test_data.dart`

---

## Phase 2: Foundational (Test Data Builder)

**Purpose**: Test data infrastructure that MUST be complete before user story implementation

**⚠️ CRITICAL**: All user story tests depend on the test data builder

- [x] T004 Implement `DeviceManagerTestData.createGetDevicesSuccess()` in `test/mocks/test_data/device_manager_test_data.dart`
- [x] T005 [P] Implement `DeviceManagerTestData.createGetNetworkConnectionsSuccess()` in `test/mocks/test_data/device_manager_test_data.dart`
- [x] T006 [P] Implement `DeviceManagerTestData.createGetRadioInfoSuccess()` in `test/mocks/test_data/device_manager_test_data.dart`
- [x] T007 [P] Implement `DeviceManagerTestData.createGetGuestRadioSettingsSuccess()` in `test/mocks/test_data/device_manager_test_data.dart`
- [x] T008 [P] Implement `DeviceManagerTestData.createGetWANStatusSuccess()` in `test/mocks/test_data/device_manager_test_data.dart`
- [x] T009 [P] Implement `DeviceManagerTestData.createGetBackhaulInfoSuccess()` in `test/mocks/test_data/device_manager_test_data.dart`
- [x] T010 Implement `DeviceManagerTestData.createCompletePollingData()` in `test/mocks/test_data/device_manager_test_data.dart`
- [x] T011 [P] Implement `DeviceManagerTestData.createNullPollingData()` in `test/mocks/test_data/device_manager_test_data.dart`
- [x] T012 [P] Implement `DeviceManagerTestData.createPartialErrorData()` in `test/mocks/test_data/device_manager_test_data.dart`

**Checkpoint**: Test data builder ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Data Transformation Isolation (Priority: P1) 🎯 MVP

**Goal**: Extract JNAP data transformation logic from DeviceManagerNotifier to DeviceManagerService

**Independent Test**: Mock service's `transformPollingData()` and verify provider correctly delegates and consumes transformed state. Verify provider file has zero JNAP model imports.

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T013 [P] [US1] Create service test file at `test/core/jnap/services/device_manager_service_test.dart`
- [x] T014 [P] [US1] Test `transformPollingData` with null input returns empty state in `test/core/jnap/services/device_manager_service_test.dart`
- [x] T015 [P] [US1] Test `transformPollingData` with valid data returns complete state in `test/core/jnap/services/device_manager_service_test.dart`
- [x] T016 [P] [US1] Test `transformPollingData` with partial error data returns partial state in `test/core/jnap/services/device_manager_service_test.dart`
- [x] T017 [P] [US1] Create provider test file at `test/core/jnap/providers/device_manager_provider_test.dart`
- [x] T018 [US1] Test provider `build()` delegates to service in `test/core/jnap/providers/device_manager_provider_test.dart`

### Implementation for User Story 1

- [x] T019 [US1] Create `DeviceManagerService` class skeleton with constructor in `lib/core/jnap/services/device_manager_service.dart`
- [x] T020 [US1] Create `deviceManagerServiceProvider` Riverpod provider in `lib/core/jnap/services/device_manager_service.dart`
- [x] T021 [US1] Copy `_getWirelessConnections()` helper from notifier to service in `lib/core/jnap/services/device_manager_service.dart`
- [x] T022 [US1] Copy `_getDeviceListAndLocations()` helper from notifier to service in `lib/core/jnap/services/device_manager_service.dart`
- [x] T023 [US1] Copy all remaining transformation helpers from notifier to service in `lib/core/jnap/services/device_manager_service.dart`
- [x] T024 [US1] Implement `transformPollingData()` method using copied helpers in `lib/core/jnap/services/device_manager_service.dart`
- [x] T025 [US1] Update `DeviceManagerNotifier.build()` to delegate to service in `lib/core/jnap/providers/device_manager_provider.dart`
- [x] T026 [US1] Remove JNAP model imports from notifier in `lib/core/jnap/providers/device_manager_provider.dart`
- [x] T027 [US1] Remove JNAP result imports from notifier in `lib/core/jnap/providers/device_manager_provider.dart`
- [x] T028 [US1] Remove JNAP action imports from notifier in `lib/core/jnap/providers/device_manager_provider.dart`
- [x] T029 [US1] Delete transformation helper methods from notifier in `lib/core/jnap/providers/device_manager_provider.dart`

**Checkpoint**: US1 complete - Provider has zero JNAP imports, transformation delegated to service

---

## Phase 4: User Story 2 - Device Property Updates (Priority: P2)

**Goal**: Extract device name/icon update logic to service layer

**Independent Test**: Call `updateDeviceNameAndIcon()` and verify service makes correct API calls and returns appropriate results.

### Tests for User Story 2

- [x] T030 [P] [US2] Test `updateDeviceNameAndIcon` success case in `test/core/jnap/services/device_manager_service_test.dart`
- [x] T031 [P] [US2] Test `updateDeviceNameAndIcon` error throws ServiceError in `test/core/jnap/services/device_manager_service_test.dart`
- [x] T032 [US2] Test provider `updateDeviceNameAndIcon` delegates to service in `test/core/jnap/providers/device_manager_provider_test.dart`

### Implementation for User Story 2

- [x] T033 [US2] Move `updateDeviceNameAndIcon()` logic from notifier to service in `lib/core/jnap/services/device_manager_service.dart`
- [x] T034 [US2] Add JNAP error to ServiceError mapping for device updates in `lib/core/jnap/services/device_manager_service.dart`
- [x] T035 [US2] Update notifier `updateDeviceNameAndIcon()` to delegate to service in `lib/core/jnap/providers/device_manager_provider.dart`

**Checkpoint**: US2 complete - Device updates work through service layer

---

## Phase 5: User Story 3 - Device Deletion (Priority: P2)

**Goal**: Extract device deletion logic to service layer

**Independent Test**: Call `deleteDevices()` with device IDs and verify service handles bulk deletion and returns success map.

### Tests for User Story 3

- [x] T036 [P] [US3] Test `deleteDevices` with empty list returns empty map in `test/core/jnap/services/device_manager_service_test.dart`
- [x] T037 [P] [US3] Test `deleteDevices` with valid IDs returns success map in `test/core/jnap/services/device_manager_service_test.dart`
- [x] T038 [P] [US3] Test `deleteDevices` partial failure returns mixed map in `test/core/jnap/services/device_manager_service_test.dart`
- [x] T039 [US3] Test provider `deleteDevices` delegates to service in `test/core/jnap/providers/device_manager_provider_test.dart`

### Implementation for User Story 3

- [x] T040 [US3] Move `deleteDevices()` logic from notifier to service in `lib/core/jnap/services/device_manager_service.dart`
- [x] T041 [US3] Add early return for empty device list in service in `lib/core/jnap/services/device_manager_service.dart`
- [x] T042 [US3] Update notifier `deleteDevices()` to delegate to service in `lib/core/jnap/providers/device_manager_provider.dart`

**Checkpoint**: US3 complete - Device deletion works through service layer

---

## Phase 6: User Story 4 - Client Deauthentication (Priority: P3)

**Goal**: Extract client deauthentication logic to service layer

**Independent Test**: Call `deauthClient()` with MAC address and verify service makes correct API call.

### Tests for User Story 4

- [x] T043 [P] [US4] Test `deauthClient` success case in `test/core/jnap/services/device_manager_service_test.dart`
- [x] T044 [P] [US4] Test `deauthClient` error throws ServiceError in `test/core/jnap/services/device_manager_service_test.dart`
- [x] T045 [US4] Test provider `deauthClient` delegates to service in `test/core/jnap/providers/device_manager_provider_test.dart`

### Implementation for User Story 4

- [x] T046 [US4] Move `deauthClient()` logic from notifier to service in `lib/core/jnap/services/device_manager_service.dart`
- [x] T047 [US4] Add error handling with ServiceError mapping in `lib/core/jnap/services/device_manager_service.dart`
- [x] T048 [US4] Update notifier `deauthClient()` to delegate to service in `lib/core/jnap/providers/device_manager_provider.dart`

**Checkpoint**: US4 complete - All JNAP operations now handled by service

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Verification, cleanup, and coverage validation

- [x] T049 Verify provider has zero JNAP imports using grep command
- [x] T050 [P] Run service tests and verify ≥90% coverage in `test/core/jnap/services/device_manager_service_test.dart`
- [x] T051 [P] Run provider tests and verify ≥85% coverage in `test/core/jnap/providers/device_manager_provider_test.dart`
- [x] T052 Run full test suite to verify no regressions (`./run_tests.sh`)
- [x] T053 Complete implementation checklist at `specs/001-device-manager-service-extraction/checklists/implementation.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - User stories can proceed sequentially in priority order (P1 → P2 → P2 → P3)
  - US2 and US3 are both P2 - can be done in parallel if desired
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after US1 complete (needs service infrastructure)
- **User Story 3 (P2)**: Can start after US1 complete (needs service infrastructure) - Can run parallel to US2
- **User Story 4 (P3)**: Can start after US1 complete (needs service infrastructure)

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Service implementation before provider delegation
- Remove old code after new code works
- Story complete before moving to next priority

### Parallel Opportunities

- T002, T003 can run in parallel (different directories)
- T005-T009, T011-T012 can run in parallel (same file, but different factory methods)
- T013-T017 tests can be written in parallel (different test files/groups)
- T030-T031, T036-T038, T043-T044 tests can run in parallel within each story
- US2 and US3 can be implemented in parallel after US1 completes

---

## Parallel Example: User Story 1 Tests

```bash
# Launch all tests for User Story 1 together:
Task T013: "Create service test file at test/core/jnap/services/device_manager_service_test.dart"
Task T014: "Test transformPollingData with null input"
Task T015: "Test transformPollingData with valid data"
Task T016: "Test transformPollingData with partial error data"
Task T017: "Create provider test file at test/core/jnap/providers/device_manager_provider_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (test data builder)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**:
   - Verify `grep -E "import.*jnap/(models|result|actions)" lib/core/jnap/providers/device_manager_provider.dart` returns nothing
   - Run `./run_tests.sh` to verify no regressions
5. MVP complete - architecture compliance achieved

### Incremental Delivery

1. Complete Setup + Foundational → Test data ready
2. Add User Story 1 → Test independently → **MVP Complete!** (Architecture compliance)
3. Add User Story 2 → Test independently → Device updates via service
4. Add User Story 3 → Test independently → Device deletion via service
5. Add User Story 4 → Test independently → All operations via service
6. Polish phase → Coverage verified, checklist complete

### Parallel Team Strategy

With multiple developers after US1 is complete:
- Developer A: User Story 2 (device updates)
- Developer B: User Story 3 (device deletion)
- Developer C: User Story 4 (deauthentication)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently testable after Phase 2
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- **Critical files to modify**:
  - `lib/core/jnap/providers/device_manager_provider.dart` (remove JNAP imports, delegate to service)
  - `lib/core/jnap/services/device_manager_service.dart` (new - all JNAP logic)
