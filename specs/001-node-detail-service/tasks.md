# Implementation Tasks: NodeDetail Service Extraction

**Feature**: 001-node-detail-service
**Branch**: `001-node-detail-service`
**Created**: 2026-01-02
**Spec**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md)

---

## Overview

| Metric | Value |
|--------|-------|
| Total Tasks | 36 |
| Phases | 6 |
| User Stories | 3 (US1: P1, US2: P1, US3: P2) |
| Parallel Opportunities | 14 tasks |

---

## Phase 1: Setup

**Goal**: Create project structure and test infrastructure

- [x] T001 Create services directory at `lib/page/nodes/services/`
- [x] T002 [P] Create test directory at `test/page/nodes/services/`
- [x] T003 [P] Create test directory at `test/page/nodes/providers/` (if not exists)
- [x] T004 Create test data builder file at `test/mocks/test_data/node_detail_test_data.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Goal**: Create the Service class skeleton and provider definition (blocks all user stories)

- [x] T005 Create NodeDetailService class with constructor injection in `lib/page/nodes/services/node_detail_service.dart`
- [x] T006 Create nodeDetailServiceProvider using `Provider<NodeDetailService>` in `lib/page/nodes/services/node_detail_service.dart`
- [x] T007 Add required imports to Service file (jnap_error_mapper, service_error, better_action, base_command, device, device_manager_state, jnap_result, router_repository, devices utils)

---

## Phase 3: User Story 1 - Code Architecture Compliance (P1)

**Goal**: Establish three-layer architecture compliance by removing JNAP imports from Provider

**Independent Test**: `grep -r "import.*jnap/models" lib/page/nodes/providers/` returns zero results

### Implementation Tasks

- [x] T008 [US1] Implement `startBlinkNodeLED(String deviceId)` method with JNAP error mapping in `lib/page/nodes/services/node_detail_service.dart`
- [x] T009 [US1] Implement `stopBlinkNodeLED()` method with JNAP error mapping in `lib/page/nodes/services/node_detail_service.dart`
- [x] T010 [US1] Remove JNAP imports from `lib/page/nodes/providers/node_detail_provider.dart` (better_action, base_command, device, router_repository)
- [x] T011 [US1] Add nodeDetailServiceProvider import to `lib/page/nodes/providers/node_detail_provider.dart`
- [x] T012 [US1] Remove NodeLightSettings import from `lib/page/nodes/providers/node_detail_state.dart`
- [x] T013 [US1] Run architecture compliance check: `grep -r "import.*jnap/models" lib/page/nodes/providers/`

### Test Tasks (Required per FR-010, FR-011)

- [x] T014 [P] [US1] Create MockRouterRepository in `test/page/nodes/services/node_detail_service_test.dart`
- [x] T015 [P] [US1] Add test data for blink operations in `test/mocks/test_data/node_detail_test_data.dart`
- [x] T016 [US1] Write unit tests for `startBlinkNodeLED` (success and error cases) in `test/page/nodes/services/node_detail_service_test.dart`
- [x] T017 [US1] Write unit tests for `stopBlinkNodeLED` (success and error cases) in `test/page/nodes/services/node_detail_service_test.dart`

---

## Phase 4: User Story 2 - Node LED Blinking Operations (P1)

**Goal**: Refactor Provider to delegate LED blink operations to Service

**Independent Test**: Trigger LED blink from UI and verify device LED blinks physically

### Implementation Tasks

- [x] T018 [US2] Refactor `startBlinkNodeLED` in NodeDetailNotifier to delegate to Service in `lib/page/nodes/providers/node_detail_provider.dart`
- [x] T019 [US2] Refactor `stopBlinkNodeLED` in NodeDetailNotifier to delegate to Service in `lib/page/nodes/providers/node_detail_provider.dart`
- [x] T020 [US2] Update `toggleBlinkNode` to catch ServiceError instead of generic error in `lib/page/nodes/providers/node_detail_provider.dart`
- [x] T021 [US2] Verify 24-second auto-stop timer behavior is preserved in `lib/page/nodes/providers/node_detail_provider.dart`

### Provider Test Tasks (Required per FR-011)

- [x] T029 [US2] Create MockNodeDetailService in `test/page/nodes/providers/node_detail_provider_test.dart`
- [x] T030 [US2] Write unit tests for `toggleBlinkNode` (start, stop, error handling) in `test/page/nodes/providers/node_detail_provider_test.dart`
- [ ] T031 [US2] Write unit tests for 24-second auto-stop timer behavior in `test/page/nodes/providers/node_detail_provider_test.dart`

---

## Phase 5: User Story 3 - State Creation from Device Data (P2)

**Goal**: Move JNAP model transformation to Service layer

**Independent Test**: Verify `createState` no longer directly accesses RawDevice, DeviceConnectionType

### Implementation Tasks

- [x] T022 [US3] Implement `transformDeviceToUIValues` method per contract in `lib/page/nodes/services/node_detail_service.dart`
- [x] T023 [US3] Implement `transformConnectedDevices` method per contract in `lib/page/nodes/services/node_detail_service.dart`
- [x] T024 [US3] Refactor `createState` in NodeDetailNotifier to use Service transformation helpers in `lib/page/nodes/providers/node_detail_provider.dart`

### Service Test Tasks (Required per FR-010)

- [ ] T032 [US3] Write unit tests for `transformDeviceToUIValues` (various device configurations) in `test/page/nodes/services/node_detail_service_test.dart`
- [ ] T033 [US3] Write unit tests for `transformConnectedDevices` in `test/page/nodes/services/node_detail_service_test.dart`

### Provider Test Tasks (Required per FR-011)

- [x] T034 [US3] Write unit tests for `createState` (device found, device not found, master vs child node) in `test/page/nodes/providers/node_detail_provider_test.dart`

### State Test Tasks (Required per Article I Section 1.7)

- [x] T035 [US3] Create test file at `test/page/nodes/providers/node_detail_state_test.dart`
- [x] T036 [US3] Write unit tests for `NodeDetailState` (copyWith, equality, toJson/fromJson) in `test/page/nodes/providers/node_detail_state_test.dart`

---

## Phase 6: Polish & Verification

**Goal**: Final verification and cleanup

- [x] T025 Run `flutter analyze lib/page/nodes/` and fix any warnings
- [x] T026 Run architecture compliance checks (SC-005, SC-006 from spec)
- [x] T027 Run all tests: `flutter test test/page/nodes/`
- [ ] T028 Verify test coverage meets requirements (Service ≥90%, Provider ≥85%)

---

## Dependencies

```
Phase 1 (Setup)
    │
    ▼
Phase 2 (Foundational) ─── Blocks all User Stories
    │
    ├──────────────────┬──────────────────┐
    ▼                  ▼                  │
Phase 3 (US1)    Phase 4 (US2)           │
Architecture     LED Blinking            │
    │                  │                  │
    └────────┬─────────┘                  │
             ▼                            │
        Phase 5 (US3) ◄───────────────────┘
        State Creation
             │
             ▼
        Phase 6 (Polish)
```

**Notes**:
- US1 and US2 can be worked in parallel after Phase 2
- US3 depends on US1 (JNAP imports must be removed first)
- Phase 6 must run after all user stories complete

---

## Parallel Execution Opportunities

### Within Phase 1
```
T001 ──┬── T002 (parallel - different directories)
       └── T003 (parallel - different directories)
T004 (after T001-T003)
```

### Within Phase 3 (US1)
```
T014 ──┬── T015 (parallel - different files)
T016, T017 (after T014, T015)
```

### Within Phase 4 (US2)
```
T029 (MockNodeDetailService - blocks T030, T031)
T030 ──┬── T031 (parallel - different test scenarios)
```

### Within Phase 5 (US3)
```
T032 ──┬── T033 (parallel - different service methods)
T034 (Provider tests - after implementation)
T035 ──── T036 (State tests - after T035 creates file)
```

---

## Implementation Strategy

### MVP Scope (Recommended First Delivery)
- **Phase 1 + Phase 2 + Phase 3 (US1)**: Architecture compliance
- Deliverable: Service created, JNAP imports removed from Provider
- Verification: Architecture compliance checks pass

### Incremental Delivery
1. **Increment 1**: MVP (Phases 1-3) - Architecture foundation
2. **Increment 2**: Phase 4 (US2) - LED blinking delegation
3. **Increment 3**: Phase 5 (US3) - State transformation
4. **Increment 4**: Phase 6 - Polish and verification

---

## Task-to-Requirement Traceability

| Task | Requirements |
|------|--------------|
| T005-T007 | FR-001 |
| T008-T009 | FR-002, FR-003 |
| T010-T012 | FR-004, FR-005 |
| T014-T017 | FR-010 (Service tests) |
| T018-T021 | FR-008, FR-009 |
| T022-T024 | FR-007 |
| T025-T028 | SC-001 to SC-007 |
| T029-T031 | FR-011 (Provider tests - LED blinking) |
| T032-T033 | FR-010 (Service tests - transformation) |
| T034 | FR-011 (Provider tests - state creation) |
| T035-T036 | Article I §1.7 (State tests) |

---

## Success Criteria Mapping

| Success Criteria | Verification Task |
|-----------------|-------------------|
| SC-001 (Zero JNAP imports in Provider) | T013, T026 |
| SC-002 (Identical functionality) | T021, T027 |
| SC-003 (Service coverage ≥90%) | T028 |
| SC-004 (Provider coverage ≥85%) | T028 |
| SC-005 (grep jnap/models = 0) | T026 |
| SC-006 (grep JNAPError = 0) | T026 |
| SC-007 (flutter analyze passes) | T025 |
