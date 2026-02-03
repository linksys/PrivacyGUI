# Tasks: InstantTopology Service Extraction

**Input**: Design documents from `/specs/001-instant-topology-service/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Required per constitution Article I (Service ≥90%, Provider ≥85% coverage)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Based on plan.md structure:
- **Source**: `lib/page/instant_topology/`
- **Tests**: `test/page/instant_topology/`
- **Shared errors**: `lib/core/errors/`
- **Test data**: `test/mocks/test_data/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and directory structure

- [x] T001 Create services directory at `lib/page/instant_topology/services/`
- [x] T002 Create test services directory at `test/page/instant_topology/services/`
- [x] T003 Create test providers directory at `test/page/instant_topology/providers/` (if not exists)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 [P] Add TopologyTimeoutError to `lib/core/errors/service_error.dart`
- [x] T005 [P] Add NodeOfflineError to `lib/core/errors/service_error.dart`
- [x] T006 [P] Add NodeOperationFailedError to `lib/core/errors/service_error.dart`
- [x] T007 Create InstantTopologyService class skeleton with provider definition in `lib/page/instant_topology/services/instant_topology_service.dart`
- [x] T008 Create InstantTopologyTestData builder class in `test/mocks/test_data/instant_topology_test_data.dart`

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Node Reboot Operation (Priority: P1) 🎯 MVP

**Goal**: Enable reboot of master node or multiple child nodes via service layer

**Independent Test**: Trigger reboot operation and verify it completes without JNAP imports in provider

### Tests for User Story 1

- [x] T009 [P] [US1] Write unit tests for rebootNodes() master node scenario in `test/page/instant_topology/services/instant_topology_service_test.dart`
- [x] T010 [P] [US1] Write unit tests for rebootNodes() multi-node scenario in `test/page/instant_topology/services/instant_topology_service_test.dart`
- [x] T011 [P] [US1] Write unit tests for rebootNodes() error handling in `test/page/instant_topology/services/instant_topology_service_test.dart`
- [x] T012 [P] [US1] Write unit tests for waitForNodesOffline() success scenario in `test/page/instant_topology/services/instant_topology_service_test.dart`
- [x] T013 [P] [US1] Write unit tests for waitForNodesOffline() timeout scenario in `test/page/instant_topology/services/instant_topology_service_test.dart`

### Implementation for User Story 1

- [x] T014 [US1] Implement rebootNodes() method for master node (empty list) in `lib/page/instant_topology/services/instant_topology_service.dart`
- [x] T015 [US1] Implement rebootNodes() method for child nodes (non-empty list with transaction) in `lib/page/instant_topology/services/instant_topology_service.dart`
- [x] T016 [US1] Implement waitForNodesOffline() polling method in `lib/page/instant_topology/services/instant_topology_service.dart`
- [x] T017 [US1] Update Provider reboot() method to delegate to service in `lib/page/instant_topology/providers/instant_topology_provider.dart`
- [x] T018 [US1] Remove JNAP imports related to reboot from provider in `lib/page/instant_topology/providers/instant_topology_provider.dart`

**Checkpoint**: Reboot functionality works through service layer, provider has no reboot-related JNAP imports

---

## Phase 4: User Story 2 - Factory Reset Operation (Priority: P1)

**Goal**: Enable factory reset of master node or multiple child nodes via service layer

**Independent Test**: Trigger factory reset operation and verify it completes without JNAP imports in provider

### Tests for User Story 2

- [x] T019 [P] [US2] Write unit tests for factoryResetNodes() master node scenario in `test/page/instant_topology/services/instant_topology_service_test.dart`
- [x] T020 [P] [US2] Write unit tests for factoryResetNodes() multi-node scenario in `test/page/instant_topology/services/instant_topology_service_test.dart`
- [x] T021 [P] [US2] Write unit tests for factoryResetNodes() error handling in `test/page/instant_topology/services/instant_topology_service_test.dart`

### Implementation for User Story 2

- [x] T022 [US2] Implement factoryResetNodes() method for master node (empty list) in `lib/page/instant_topology/services/instant_topology_service.dart`
- [x] T023 [US2] Implement factoryResetNodes() method for child nodes (non-empty list with transaction) in `lib/page/instant_topology/services/instant_topology_service.dart`
- [x] T024 [US2] Update Provider factoryReset() method to delegate to service in `lib/page/instant_topology/providers/instant_topology_provider.dart`
- [x] T025 [US2] Remove JNAP imports related to factoryReset from provider in `lib/page/instant_topology/providers/instant_topology_provider.dart`

**Checkpoint**: Factory reset functionality works through service layer

---

## Phase 5: User Story 3 - Node LED Blink Control (Priority: P2)

**Goal**: Enable LED blink start/stop via service layer while keeping SharedPreferences state in provider

**Independent Test**: Trigger LED blink and verify it works without JNAP imports in provider

### Tests for User Story 3

- [x] T026 [P] [US3] Write unit tests for startBlinkNodeLED() in `test/page/instant_topology/services/instant_topology_service_test.dart`
- [x] T027 [P] [US3] Write unit tests for stopBlinkNodeLED() in `test/page/instant_topology/services/instant_topology_service_test.dart`
- [x] T028 [P] [US3] Write unit tests for LED blink error handling in `test/page/instant_topology/services/instant_topology_service_test.dart`

### Implementation for User Story 3

- [x] T029 [US3] Implement startBlinkNodeLED() method in `lib/page/instant_topology/services/instant_topology_service.dart`
- [x] T030 [US3] Implement stopBlinkNodeLED() method in `lib/page/instant_topology/services/instant_topology_service.dart`
- [x] T031 [US3] Update Provider toggleBlinkNode() to delegate JNAP calls to service in `lib/page/instant_topology/providers/instant_topology_provider.dart`
- [x] T032 [US3] Update Provider startBlinkNodeLED() to delegate to service in `lib/page/instant_topology/providers/instant_topology_provider.dart`
- [x] T033 [US3] Update Provider stopBlinkNodeLED() to delegate to service in `lib/page/instant_topology/providers/instant_topology_provider.dart`
- [x] T034 [US3] Remove remaining JNAP imports from provider in `lib/page/instant_topology/providers/instant_topology_provider.dart`

**Checkpoint**: All LED blink operations work through service layer

---

## Phase 6: Provider Tests & Cleanup

**Purpose**: Add provider tests and complete architecture compliance

### Provider Tests

- [x] T035 [P] Write unit tests for Provider reboot() delegation in `test/page/instant_topology/providers/instant_topology_provider_test.dart`
- [x] T036 [P] Write unit tests for Provider factoryReset() delegation in `test/page/instant_topology/providers/instant_topology_provider_test.dart`
- [x] T037 [P] Write unit tests for Provider toggleBlinkNode() delegation in `test/page/instant_topology/providers/instant_topology_provider_test.dart`
- [x] T038 [P] Write unit tests for Provider ServiceError handling in `test/page/instant_topology/providers/instant_topology_provider_test.dart`

### Final Cleanup

- [x] T039 Remove JNAPTransactionBuilder import from provider in `lib/page/instant_topology/providers/instant_topology_provider.dart`
- [x] T040 Remove routerRepositoryProvider import from provider in `lib/page/instant_topology/providers/instant_topology_provider.dart`
- [x] T041 Add ServiceError import to provider in `lib/page/instant_topology/providers/instant_topology_provider.dart`
- [x] T042 Add instantTopologyServiceProvider import to provider in `lib/page/instant_topology/providers/instant_topology_provider.dart`

**Checkpoint**: Provider has zero JNAP-related imports

---

## Phase 7: Polish & Verification

**Purpose**: Ensure architecture compliance and code quality

- [x] T043 Run architecture compliance check: `grep -r "import.*jnap/actions" lib/page/instant_topology/providers/`
- [x] T044 Run architecture compliance check: `grep -r "import.*jnap/result" lib/page/instant_topology/providers/`
- [x] T045 Run architecture compliance check: `grep -r "routerRepositoryProvider" lib/page/instant_topology/providers/`
- [x] T046 Run dart analyze on `lib/page/instant_topology/`
- [x] T047 Run dart format on modified files
- [x] T048 Run all tests: `flutter test test/page/instant_topology/`
- [x] T049 Verify test coverage meets requirements (Service ≥90%, Provider ≥85%)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - US1 and US2 share waitForNodesOffline, so US1 should complete first
  - US3 is independent and can run in parallel with US2
- **Provider Tests (Phase 6)**: Depends on all user story implementation
- **Polish (Phase 7)**: Depends on all prior phases

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational - Implements waitForNodesOffline used by US2
- **User Story 2 (P1)**: Can start after US1 completes (reuses waitForNodesOffline)
- **User Story 3 (P2)**: Can start after Foundational - Independent of US1/US2

### Within Each User Story

- Tests written first (TDD approach per constitution)
- Service implementation before Provider update
- Provider update includes JNAP import removal
- Story complete before moving to next

### Parallel Opportunities

**Phase 2 (Foundational)**:
```
T004, T005, T006 can run in parallel (different error types)
```

**Phase 3 (US1 Tests)**:
```
T009, T010, T011, T012, T013 can run in parallel (different test scenarios)
```

**Phase 4 (US2 Tests)**:
```
T019, T020, T021 can run in parallel (different test scenarios)
```

**Phase 5 (US3 Tests)**:
```
T026, T027, T028 can run in parallel (different test scenarios)
```

**Phase 6 (Provider Tests)**:
```
T035, T036, T037, T038 can run in parallel (different test scenarios)
```

---

## Parallel Example: User Story 1 Tests

```bash
# Launch all tests for User Story 1 together:
Task: "T009 Write unit tests for rebootNodes() master node scenario"
Task: "T010 Write unit tests for rebootNodes() multi-node scenario"
Task: "T011 Write unit tests for rebootNodes() error handling"
Task: "T012 Write unit tests for waitForNodesOffline() success scenario"
Task: "T013 Write unit tests for waitForNodesOffline() timeout scenario"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 2: Foundational (T004-T008)
3. Complete Phase 3: User Story 1 (T009-T018)
4. **STOP and VALIDATE**: Test reboot independently
5. Run compliance checks (T043-T045) for reboot-related code

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Reboot works via service → Validate
3. Add User Story 2 → Factory reset works via service → Validate
4. Add User Story 3 → LED blink works via service → Validate
5. Complete Provider Tests + Polish → Full compliance

### Sequential Execution (Recommended)

Given the shared components (waitForNodesOffline, ServiceError types):

1. Phase 1 → Phase 2 → Phase 3 (US1) → Phase 4 (US2) → Phase 5 (US3) → Phase 6 → Phase 7

---

## Success Criteria Mapping

| Success Criteria | Verification Task |
|-----------------|-------------------|
| SC-001: Zero imports from core/jnap/actions/ | T043 |
| SC-002: Zero references to RouterRepository | T045 |
| SC-003: Zero JNAPSuccess/JNAPError checks | T044 |
| SC-004: Existing operations function identically | T048 |
| SC-005: Service coverage ≥90% | T049 |
| SC-006: Provider coverage ≥85% | T049 |
| SC-007: Architecture compliance checks pass | T043, T044, T045 |

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing (TDD)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Reference files:
  - Service pattern: `lib/page/instant_admin/services/router_password_service.dart`
  - Error mapper: `lib/core/errors/jnap_error_mapper.dart`
  - Contract: `specs/001-instant-topology-service/contracts/instant_topology_service_contract.md`
