# Specification Analysis Report: InstantTopology Service Extraction

**Feature**: `001-instant-topology-service`
**Date**: 2026-01-02
**Artifacts Analyzed**: spec.md, plan.md, tasks.md, data-model.md, contracts/

---

## Executive Summary

| Metric | Value | Status |
|--------|-------|--------|
| Total Requirements | 12 (FR-001 to FR-012) | - |
| Total Success Criteria | 7 (SC-001 to SC-007) | - |
| Total Tasks | 49 (T001-T049) | - |
| Requirement Coverage | 100% | :white_check_mark: |
| Success Criteria Coverage | 100% | :white_check_mark: |
| Constitution Compliance | 100% | :white_check_mark: |
| Critical Issues | 0 | :white_check_mark: |
| Warnings | 2 | :warning: |

**Overall Status**: :white_check_mark: **READY FOR IMPLEMENTATION**

---

## 1. Requirements Coverage Analysis

### 1.1 Functional Requirements → Tasks Mapping

| Requirement | Description | Covered By Tasks | Status |
|-------------|-------------|------------------|--------|
| FR-001 | Create InstantTopologyService class | T007 | :white_check_mark: |
| FR-002 | Reboot nodes method | T014, T015 | :white_check_mark: |
| FR-003 | Factory reset nodes method | T022, T023 | :white_check_mark: |
| FR-004 | Start LED blink method | T029 | :white_check_mark: |
| FR-005 | Stop LED blink method | T030 | :white_check_mark: |
| FR-006 | Wait for nodes offline | T016 | :white_check_mark: |
| FR-007 | Convert JNAP errors to ServiceError | T004, T005, T006 | :white_check_mark: |
| FR-008 | Provider delegates to service | T017, T024, T031-T033 | :white_check_mark: |
| FR-009 | Remove JNAP imports from provider | T018, T025, T034, T039-T042 | :white_check_mark: |
| FR-010 | Provider catches only ServiceError | T038 | :white_check_mark: |
| FR-011 | Multi-node reverse order | T015, T023 | :white_check_mark: |
| FR-012 | 60-second timeout | T013 | :white_check_mark: |

### 1.2 Success Criteria → Tasks Mapping

| Criterion | Description | Verification Task | Status |
|-----------|-------------|-------------------|--------|
| SC-001 | Zero JNAP action imports | T043 | :white_check_mark: |
| SC-002 | Zero RouterRepository refs | T045 | :white_check_mark: |
| SC-003 | Zero JNAP type checks | T044 | :white_check_mark: |
| SC-004 | Existing operations unchanged | T048 | :white_check_mark: |
| SC-005 | Service coverage ≥90% | T049 | :white_check_mark: |
| SC-006 | Provider coverage ≥85% | T049 | :white_check_mark: |
| SC-007 | Architecture compliance | T043, T044, T045 | :white_check_mark: |

---

## 2. Constitution Compliance Analysis

### 2.1 Article Compliance Summary

| Article | Requirement | Spec | Plan | Tasks | Status |
|---------|-------------|------|------|-------|--------|
| I - Test Requirement | Service ≥90%, Provider ≥85% | SC-005, SC-006 | Planned | T049 | :white_check_mark: |
| III - Naming | snake_case files, UpperCamelCase classes | - | `instant_topology_service.dart`, `InstantTopologyService` | - | :white_check_mark: |
| V - Three-Layer Architecture | Provider → Service → Data | FR-008, FR-009 | Designed | T017, T024, T031-T034 | :white_check_mark: |
| VI - Service Layer | Services handle JNAP | FR-001-FR-007 | Designed | T007, T014-T016, T022-T023, T029-T030 | :white_check_mark: |
| VII - Anti-Abstraction | No framework wrappers | - | Compliant | - | :white_check_mark: |
| IX - Documentation | Contracts in .md format | - | contracts/*.md | - | :white_check_mark: |
| XIII - Error Handling | ServiceError contract | FR-007 | 3 new error types | T004-T006 | :white_check_mark: |

### 2.2 Constitution MUST/SHALL Verification

| Constitution Statement | Artifact Reference | Status |
|-----------------------|-------------------|--------|
| "Services MUST be organized in `lib/page/[feature]/services/`" (Art VI §6.3) | plan.md: `lib/page/instant_topology/services/` | :white_check_mark: |
| "Services SHALL handle all JNAP API communication" (Art VI §6.2) | spec.md FR-001, contract | :white_check_mark: |
| "Services SHALL return domain/UI models, not raw API responses" (Art VI §6.2) | contract: returns void, throws ServiceError | :white_check_mark: |
| "Services SHALL be stateless" (Art VI §6.2) | contract: no internal state | :white_check_mark: |
| "Provider 層只處理 ServiceError 類型" (Art XIII §13.4) | spec.md FR-010 | :white_check_mark: |
| "Test data builders: `test/mocks/test_data/[feature]_test_data.dart`" (Art I §1.5) | plan.md: `test/mocks/test_data/instant_topology_test_data.dart` | :white_check_mark: |

---

## 3. Cross-Artifact Consistency Analysis

### 3.1 Data Model Consistency

| Entity | spec.md | data-model.md | contract | Status |
|--------|---------|---------------|----------|--------|
| InstantTopologyService | FR-001 | Entity diagram | Full definition | :white_check_mark: |
| TopologyTimeoutError | FR-007 | `timeout`, `deviceIds` fields | Throws on waitForNodesOffline | :white_check_mark: |
| NodeOfflineError | FR-007 | `deviceId` field | Throws on LED blink offline node | :white_check_mark: |
| NodeOperationFailedError | FR-007 | `deviceId`, `operation`, `originalError` fields | Throws on all operation failures | :white_check_mark: |

### 3.2 Method Signature Consistency

| Method | spec.md | contract | tasks | Status |
|--------|---------|----------|-------|--------|
| `rebootNodes(List<String>)` | FR-002 | `Future<void> rebootNodes(List<String> deviceUUIDs)` | T014-T015 | :white_check_mark: |
| `factoryResetNodes(List<String>)` | FR-003 | `Future<void> factoryResetNodes(List<String> deviceUUIDs)` | T022-T023 | :white_check_mark: |
| `startBlinkNodeLED(String)` | FR-004 | `Future<void> startBlinkNodeLED(String deviceId)` | T029 | :white_check_mark: |
| `stopBlinkNodeLED()` | FR-005 | `Future<void> stopBlinkNodeLED()` | T030 | :white_check_mark: |
| `waitForNodesOffline(...)` | FR-006 | `Future<void> waitForNodesOffline(List<String>, {maxRetry, retryDelayMs})` | T016 | :white_check_mark: |

---

## 4. Findings

### 4.1 Critical Issues

**None found.**

### 4.2 Warnings

| ID | Category | Location | Description | Recommendation |
|----|----------|----------|-------------|----------------|
| W-001 | Coverage Gap | tasks.md | T008 creates test data builder but no explicit tests for the builder itself | Consider adding test data builder validation in T049 or accept as acceptable risk since builder is used in other tests |
| W-002 | Assumption | spec.md | "SharedPreferences access for blink tracking can remain in provider" leaves implementation choice ambiguous | Clarified in contract: provider retains SharedPreferences responsibility |

### 4.3 Observations (Non-Issues)

| ID | Category | Description |
|----|----------|-------------|
| O-001 | Design Decision | User Story 1 must complete before User Story 2 due to shared `waitForNodesOffline()` - correctly captured in tasks.md dependency section |
| O-002 | Test Strategy | TDD approach specified - tests written before implementation (T009-T013 before T014-T017) |
| O-003 | Parallelization | Good use of [P] markers for tasks that can run in parallel within phases |

---

## 5. User Story Traceability

### 5.1 US1 - Node Reboot (P1)

| Acceptance Scenario | Requirement | Task |
|---------------------|-------------|------|
| Master node reboot | FR-002 | T009, T014 |
| Multi-node reboot (reverse order) | FR-002, FR-011 | T010, T015 |
| Reboot error handling | FR-007 | T011 |
| Wait for offline success | FR-006 | T012, T016 |
| Wait for offline timeout | FR-012 | T013, T016 |

### 5.2 US2 - Factory Reset (P1)

| Acceptance Scenario | Requirement | Task |
|---------------------|-------------|------|
| Master node factory reset | FR-003 | T019, T022 |
| Multi-node factory reset (reverse order) | FR-003, FR-011 | T020, T023 |
| Factory reset error handling | FR-007 | T021 |

### 5.3 US3 - LED Blink Control (P2)

| Acceptance Scenario | Requirement | Task |
|---------------------|-------------|------|
| Start LED blink | FR-004 | T026, T029 |
| Stop LED blink | FR-005 | T027, T030 |
| LED blink error handling | FR-007 | T028 |
| Toggle between nodes | Provider logic | T031-T033 |

---

## 6. Task Dependency Validation

### 6.1 Phase Dependencies

```
Phase 1 (Setup)     → Phase 2 (Foundational) → Phase 3-5 (User Stories) → Phase 6 (Provider Tests) → Phase 7 (Polish)
     T001-T003            T004-T008                T009-T034                  T035-T042                T043-T049
```

**Validation**: :white_check_mark: Correct sequential flow with appropriate blocking

### 6.2 Inter-Story Dependencies

| Story | Depends On | Reason | Status |
|-------|------------|--------|--------|
| US1 | Phase 2 | ServiceError types required | :white_check_mark: |
| US2 | US1 | Reuses `waitForNodesOffline()` | :white_check_mark: |
| US3 | Phase 2 | ServiceError types required | :white_check_mark: |

**Validation**: :white_check_mark: US2 correctly depends on US1; US3 can run parallel to US2

---

## 7. Metrics Summary

| Metric | Value |
|--------|-------|
| User Stories | 3 |
| Functional Requirements | 12 |
| Success Criteria | 7 |
| ServiceError Types | 3 |
| Service Methods | 5 |
| Total Tasks | 49 |
| Setup Tasks | 3 |
| Foundational Tasks | 5 |
| Implementation Tasks | 26 |
| Provider Test Tasks | 8 |
| Verification Tasks | 7 |
| Parallel Opportunities | 23 tasks marked [P] |

---

## 8. Recommendations

1. **Proceed with Implementation**: All artifacts are consistent and constitution-compliant
2. **Follow Task Order**: Respect the phase dependencies documented in tasks.md
3. **Validate at Checkpoints**: Stop at each phase checkpoint to validate independently
4. **Monitor W-001**: Ensure test data builder is exercised through service tests

---

## 9. Conclusion

The specification artifacts (spec.md, plan.md, tasks.md, data-model.md, contracts/) are:

- :white_check_mark: **Complete**: All requirements have corresponding tasks
- :white_check_mark: **Consistent**: Cross-artifact references align correctly
- :white_check_mark: **Constitution-Compliant**: All MUST/SHALL statements satisfied
- :white_check_mark: **Traceable**: User stories → Requirements → Tasks mapping verified

**Ready for `/speckit.implement`**
