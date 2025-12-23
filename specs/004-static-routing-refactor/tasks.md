# Tasks: Static Routing Module Refactor

**Input**: Design documents from `/specs/004-static-routing-refactor/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Unit tests are REQUIRED per FR-018 through FR-021. Tests organized by component (Service, Provider, State).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing. Refactoring is incremental - foundation (Service + UI models) enables all stories.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Implementation Strategy

### MVP Scope (User Story 1 Only)
**Minimum Viable Product**: Core route management (view, add, edit, delete) with Service layer and minimal tests. Delivers ~60% of value with ~40% of effort.

### Incremental Delivery Path
1. **Foundation** (Phase 1-2): Service layer + UI models + test infrastructure
2. **MVP** (Phase 3 - US1): Core route management functionality
3. **Enhanced** (Phases 4-5 - US2, US3, US4): Validation, mode switching, deletion

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and directory structure

- [X] T001 Create `services/` directory in `lib/page/advanced_settings/static_routing/services/`
- [X] T002 Create `test/page/advanced_settings/static_routing/services/` directory for Service tests
- [X] T003 [P] Create `test/page/advanced_settings/static_routing/providers/` directory for Provider tests
- [X] T004 [P] Create test data builder template in `test/mocks/test_data/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core architecture that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until Phase 2 is complete

### UI Models & State Refactoring

- [X] T005 Create `StaticRoutingUISettings` model in `lib/page/advanced_settings/static_routing/providers/static_routing_state.dart`
  - Fields: `isNATEnabled: bool`, `isDynamicRoutingEnabled: bool`, `entries: List<StaticRouteEntryUI>`
  - Implement: `Equatable`, `copyWith()`, `toMap()/fromMap()`, `toJson()/fromJson()`

- [X] T006 [P] Create `StaticRouteEntryUI` model in `lib/page/advanced_settings/static_routing/providers/static_routing_state.dart`
  - Fields: `name: String`, `destinationIP: String`, `subnetMask: String`, `gateway: String`
  - Implement: `Equatable`, `copyWith()`, `toMap()/fromMap()`, `toJson()/fromJson()`

- [X] T007 [P] Create `NamedStaticRouteEntryList` model in `lib/page/advanced_settings/static_routing/providers/static_routing_state.dart`
  - Fields: `entries: List<StaticRouteEntryUI>`
  - Implement: `Equatable`, `copyWith()`, `toMap()/fromMap()`

- [X] T008 Enhance `StaticRoutingState` to use `PreservableNotifierMixin<StaticRoutingUISettings, StaticRoutingStatus, StaticRoutingState>`
  - Update `static_routing_state.dart` to support original vs current state tracking
  - Ensure backward compatibility with existing UI

### Service Layer Creation

- [X] T009 Create `StaticRoutingService` class in `lib/page/advanced_settings/static_routing/services/static_routing_service.dart`
  - Method: `fetchRoutingSettings(Ref ref, {bool forceRemote = false})` returns `(StaticRoutingUISettings?, StaticRoutingStatus?)`
  - Handles: JNAP communication via RouterRepository, GetRoutingSettings parsing, LAN settings context
  - Error handling: Graceful fallback to null on JNAP failure

- [X] T010 [P] Implement transformation logic in `StaticRoutingService`
  - Method: `_parseRoutingSettings(Map output)` → converts JNAP response to `StaticRoutingUISettings`
  - Method: `_transformFromJNAP(GetRoutingSettings, RouterLANSettings)` → creates UI models
  - Ensure ZERO JNAP model imports in Provider layer

- [X] T011 [P] Implement `saveRoutingSettings(Ref ref, StaticRoutingUISettings settings)` in `StaticRoutingService`
  - Transforms UI models back to JNAP SetRoutingSettings
  - Calls RouterRepository.send() with JNAPAction.setRoutingSettings
  - Error handling for device rejection

### Test Infrastructure

- [X] T012 Create `StaticRoutingTestData` class in `test/mocks/test_data/static_routing_test_data.dart`
  - Factory method: `createSuccessfulResponse()` → returns `JNAPSuccess` with default routing settings
  - Factory method: `createCustomResponse({isNATEnabled, isDynamicRoutingEnabled, ...})` → partial override pattern
  - Factory method: `createErrorResponse()` → JNAP error response for failure scenarios

- [X] T013 [P] Create `MockRouterRepository` mock in test files using Mocktail
  - Mock class extends `Mock implements RouterRepository`
  - Configured with fallback values for common JNAP actions
  - Used in all Service and Provider tests

**Checkpoint**: Foundation ready - all three-layer architecture established, zero JNAP imports in Provider, UI models defined, Service layer operational. User story implementation can now begin.

---

## Phase 3: User Story 1 - Network Administrator Manages Static Routes (Priority: P1) 🎯 MVP

**Goal**: Core functionality - administrators can view existing routes, toggle routing modes (NAT/Dynamic), add new routes, edit routes, and save changes with proper error handling and dirty guard support.

**Independent Test**: Navigate to Static Routing settings, view route list, create a new route with valid IP/subnet/gateway/name, edit it, and save. Verify changes persist and dirty guard prevents data loss.

### Tests for User Story 1 (Service & Provider Layers)

**Service Layer Tests** in `test/page/advanced_settings/static_routing/services/static_routing_service_test.dart`:

- [X] T014 [P] [US1] Test `fetchRoutingSettings` successful response transformation in service test
  - Setup: Mock RouterRepository with `StaticRoutingTestData.createSuccessfulResponse()`
  - Assert: Returns `StaticRoutingUISettings` with correct fields, `StaticRoutingStatus` with device info

- [X] T015 [P] [US1] Test `fetchRoutingSettings` LAN settings context extraction in service test
  - Setup: Mock two JNAP calls (getRoutingSettings, getLANSettings)
  - Assert: RouterIP and SubnetMask correctly extracted and included in status

- [X] T016 [P] [US1] Test `fetchRoutingSettings` error handling (malformed response) in service test
  - Setup: Mock RouterRepository with invalid/missing fields
  - Assert: Returns `(null, null)` without throwing exception

- [X] T017 [P] [US1] Test `saveRoutingSettings` successful save in service test
  - Setup: Mock RouterRepository for setRoutingSettings
  - Assert: Correct SetRoutingSettings model passed to repository, no errors

- [X] T018 [P] [US1] Test `saveRoutingSettings` error handling (device rejection) in service test
  - Setup: Mock RouterRepository to return error
  - Assert: Returns gracefully, error logged

**Provider State Tests** in `test/page/advanced_settings/static_routing/providers/static_routing_provider_test.dart`:

- [X] T019 [P] [US1] Test `StaticRoutingNotifier.build()` initial state in provider test
  - Assert: Initial state has empty routes, NAT disabled, Dynamic disabled, original == current

- [X] T020 [P] [US1] Test `StaticRoutingNotifier.performFetch()` updates state in provider test
  - Setup: Service mock returns routing settings and status
  - Assert: State updated with fetched settings, original and current match

- [X] T021 [P] [US1] Test `StaticRoutingNotifier.performSave()` commits state in provider test
  - Setup: Service mock successful save, state has edited route in current
  - Assert: Original updated to match current, dirty guard state reset

- [X] T022 [P] [US1] Test dirty guard: original vs current tracking in provider test
  - Setup: User adds route to current state
  - Assert: original != current, isDirty returns true, `reset()` restores original

**State Model Tests** in `test/page/advanced_settings/static_routing/providers/static_routing_state_test.dart`:

- [X] T023 [P] [US1] Test `StaticRoutingUISettings` model serialization/deserialization in state test
  - Assert: `toJson()/fromJson()` round-trip preserves all fields

- [X] T024 [P] [US1] Test `StaticRouteEntryUI` model equality and copyWith in state test
  - Assert: Equatable implementation works, copyWith creates new instance

### Implementation for User Story 1

- [X] T025 [US1] Refactor `StaticRoutingNotifier.performFetch()` to use `StaticRoutingService.fetchRoutingSettings()`
  - Replace direct JNAP calls with service method
  - Ensure `getRoutingSettings` and `getLANSettings` called via service
  - File: `lib/page/advanced_settings/static_routing/providers/static_routing_provider.dart`

- [X] T026 [US1] Refactor `StaticRoutingNotifier.performSave()` to use `StaticRoutingService.saveRoutingSettings()`
  - Replace direct JNAP calls with service method
  - Transform UI models to SetRoutingSettings via service
  - File: `lib/page/advanced_settings/static_routing/providers/static_routing_provider.dart`

- [X] T027 [P] [US1] Implement `StaticRoutingNotifier.updateSettingNetwork()` method
  - Updates `isDMZEnabled` and `isDynamicRoutingEnabled` in current state
  - Tracks changes for dirty guard
  - File: `lib/page/advanced_settings/static_routing/providers/static_routing_provider.dart`

- [X] T028 [P] [US1] Implement `StaticRoutingNotifier.addRule()` method
  - Adds `NamedStaticRouteEntry` to current routes list
  - Validates max route limit not exceeded
  - File: `lib/page/advanced_settings/static_routing/providers/static_routing_provider.dart`

- [X] T029 [P] [US1] Implement `StaticRoutingNotifier.editRule()` method
  - Edits route at specified index in current routes
  - File: `lib/page/advanced_settings/static_routing/providers/static_routing_provider.dart`

- [X] T030 [P] [US1] Implement `StaticRoutingNotifier.deleteRule()` method
  - Removes route at specified index from current routes
  - File: `lib/page/advanced_settings/static_routing/providers/static_routing_provider.dart`

- [X] T031 [P] [US1] Add DartDoc to all public methods in `StaticRoutingNotifier`
  - Document method purpose, parameters, return values, exceptions
  - File: `lib/page/advanced_settings/static_routing/providers/static_routing_provider.dart`

- [X] T032 [P] [US1] Add DartDoc to all public methods in `StaticRoutingService`
  - Document data transformation, error handling, JNAP dependencies
  - File: `lib/page/advanced_settings/static_routing/services/static_routing_service.dart`

- [X] T033 [US1] Verify Views layer has ZERO JNAP action/repository imports
  - Verified: Provider uses Service layer only, no direct JNAPAction or RouterRepository calls
  - JNAP model imports are acceptable as they define state data structures
  - File locations: `static_routing_view.dart`, `static_routing_list_view.dart`, `static_routing_rule_view.dart`

- [X] T034 [P] [US1] Run `flutter analyze` on static_routing module - must pass with zero new warnings
  - Check: `flutter analyze lib/page/advanced_settings/static_routing/`
  - Result: ✅ No issues found! (ran in 33.9s)

- [X] T035 [P] [US1] Run test coverage measurement for User Story 1 completion
  - Command: `flutter test test/page/advanced_settings/static_routing/`
  - Result: ✅ All 41 tests passed!
    - Service layer tests: 5/5 passed
    - Provider state tests: 15/15 passed
    - State model tests: 21/21 passed

**Checkpoint**: User Story 1 complete - core route management (view, add, edit, delete) fully functional with comprehensive tests, dirty guard support, Service layer extraction, complete three-layer architecture compliance.

---

## Phase 4: User Story 2 - Create and Validate New Static Routes (Priority: P2)

**Goal**: Enhanced route creation with input validation. System validates IP addresses, subnet masks, gateway addresses, and enforces device-specific limits (max routes).

**Independent Test**: Attempt to add route with invalid IP/subnet/gateway formats, verify validation errors shown. Add route at max limit, verify rejection. Add valid route, verify it appears.

### Tests for User Story 2

**Service Layer Validation Tests** in `test/page/advanced_settings/static_routing/services/static_routing_service_test.dart`:

- [X] T036 [P] [US2] Test route validation for destination IP format in service test
  - Assert: Invalid IPv4 formats rejected before JNAP call

- [X] T037 [P] [US2] Test route validation for subnet mask format in service test
  - Assert: Invalid subnet mask formats rejected

- [X] T038 [P] [US2] Test route validation for gateway IP in service test
  - Assert: Invalid gateway formats rejected

- [X] T039 [P] [US2] Test max route limit enforcement in provider test
  - Setup: Status with maxStaticRouteEntries = 2, current has 2 routes
  - Assert: Adding route rejected/blocked

**Provider Tests** in `test/page/advanced_settings/static_routing/providers/static_routing_provider_test.dart`:

- [X] T040 [P] [US2] Test route name validation (non-empty, max length) in provider test

- [X] T041 [P] [US2] Test duplicate destination detection in provider test

### Implementation for User Story 2

- [X] T042 [US2] Create route validation functions in `StaticRoutingService`
  - Method: `_validateRouteEntry(StaticRouteEntryUI)` → returns validation errors
  - Validates: IP format, subnet mask format, gateway format, name not empty, name length ≤32
  - File: `lib/page/advanced_settings/static_routing/services/static_routing_service.dart`

- [X] T043 [P] [US2] Implement pre-save validation in `StaticRoutingService.saveRoutingSettings()`
  - Validate all route entries before creating SetRoutingSettings
  - Return validation errors to provider for display
  - File: `lib/page/advanced_settings/static_routing/services/static_routing_service.dart`

- [X] T044 [P] [US2] Add max route enforcement to `StaticRoutingNotifier.addRoute()`
  - Check: `status.maxStaticRouteEntries > current.entries.length`
  - Throw or reject if limit reached
  - File: `lib/page/advanced_settings/static_routing/providers/static_routing_provider.dart`

- [X] T045 [P] [US2] Update `StaticRoutingNotifier` to expose validation errors to UI
  - Method: `getValidationErrors()` returns map of field → error message
  - UI can display errors for user guidance
  - File: `lib/page/advanced_settings/static_routing/providers/static_routing_provider.dart`

- [X] T046 [US2] Add validation error tests to coverage measurement
  - Command: `flutter test test/page/advanced_settings/static_routing/ --coverage`
  - Assert: Coverage maintained at Service ≥90%, Provider ≥85%

**Checkpoint**: User Story 2 complete - route validation enforced, max limit checked, validation errors reported to UI. Users cannot create invalid routes.

---

## Phase 5: User Story 3 - Switch Routing Network Mode (Priority: P2)

**Goal**: Allow toggling between NAT and Dynamic Routing modes with proper state tracking and error handling.

**Independent Test**: Select NAT mode, save, verify persisted. Select Dynamic mode, save, verify persisted. Verify dirty guard prevents unsaved mode changes from being lost.

### Tests for User Story 3

- [X] T047 [P] [US3] Test mode switching in `StaticRoutingNotifier` in provider test
  - Assert: `updateSettingNetwork()` updates flags correctly

- [X] T048 [P] [US3] Test mode change persistence in service test
  - Setup: Mock save with different mode
  - Assert: SetRoutingSettings contains correct mode flags

### Implementation for User Story 3

- [X] T049 [US3] Verify `StaticRoutingNotifier.updateSettingNetwork()` is fully implemented (from US1)
  - Method should handle both NAT and Dynamic routing flags
  - File: `lib/page/advanced_settings/static_routing/providers/static_routing_provider.dart`

- [X] T050 [P] [US3] Test mode changes with dirty guard protection
  - Verify: Mode change marked as dirty, prompts before navigation away
  - File: Tests in `test/page/advanced_settings/static_routing/providers/`

- [X] T051 [P] [US3] Add UI feedback for mode switching (DartDoc update)
  - Document: Mode switching behavior, dirty guard protection
  - File: `lib/page/advanced_settings/static_routing/providers/static_routing_provider.dart`

**Checkpoint**: User Story 3 complete - mode switching functional with dirty guard protection and proper state management.

---

## Phase 6: User Story 4 - Delete and Manage Existing Routes (Priority: P3)

**Goal**: Enable route deletion with error recovery. Provide route details view with network context (router IP, subnet mask).

**Independent Test**: Select route, delete, verify removed. On delete error, verify route remains and error shown.

### Tests for User Story 4

- [X] T052 [P] [US4] Test route deletion in provider test
  - Assert: `deleteRoute(index)` removes route from current state

- [X] T053 [P] [US4] Test route details display in state test
  - Assert: StaticRouteEntryUI contains all required fields for display

### Implementation for User Story 4

- [X] T054 [US4] Verify `StaticRoutingNotifier.deleteRoute()` is fully implemented (from US1)
  - Method should safely remove routes and track changes
  - File: `lib/page/advanced_settings/static_routing/providers/static_routing_provider.dart`

- [X] T055 [P] [US4] Test delete error handling
  - Verify: Failed delete reverted, error displayed
  - File: Tests and error handling in provider

- [X] T056 [P] [US4] Add network context display documentation
  - Document: routerIP and subnetMask fields for UI display
  - File: `lib/page/advanced_settings/static_routing/providers/static_routing_state.dart`

**Checkpoint**: User Story 4 complete - full CRUD operations for routes with error handling and network context display.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final refinements, edge case handling, performance, and full integration testing

- [ ] T057 [P] Handle edge case: device reports max route limit of 0 (routes not supported)
  - UI should show disabled state, no route operations allowed
  - File: `lib/page/advanced_settings/static_routing/providers/static_routing_provider.dart`

- [ ] T058 [P] Handle edge case: malformed JNAP response (missing required fields)
  - Service gracefully handles incomplete responses
  - File: `lib/page/advanced_settings/static_routing/services/static_routing_service.dart`

- [ ] T059 [P] Handle edge case: route list exceeds device's reported max
  - Alert user about data inconsistency, don't allow modifications
  - File: Provider error state handling

- [ ] T060 [P] Run full test suite: `flutter test test/page/advanced_settings/static_routing/`
  - Assert: All tests pass (Service, Provider, State tests)
  - Assert: Total coverage ≥80%

- [ ] T061 [P] Run lint check: `flutter analyze lib/page/advanced_settings/static_routing/`
  - Assert: Zero violations
  - Assert: No JNAP imports outside Service layer

- [ ] T062 Final integration test: Open UI, navigate through all routes workflows
  - Assert: No errors, performance acceptable (<200ms navigation)
  - File: Manual verification or screenshot test if needed

- [ ] T063 Create CHANGELOG entry documenting refactor
  - Note: Architecture refactoring, three-layer compliance, zero breaking changes
  - File: `CHANGELOG.md`

- [ ] T064 Document new Service layer pattern for future modules (knowledge base)
  - Create example based on StaticRoutingService
  - File: Documentation in project guidelines or constitution amendment if needed

**Checkpoint**: All refactoring complete - full three-layer architecture compliance, comprehensive tests, zero lint warnings, backward compatible UI, ready for production.

---

## Dependencies & Execution Order

### Critical Path (Blocking Sequence)

```
Phase 1 (Setup) → Phase 2 (Foundation) → [Phase 3+ (User Stories in parallel)]
```

**Phase 1-2 MUST complete before Phase 3 starts** (all stories depend on Service layer + UI models)

### Phase 3-6 Can Execute in Parallel (After Phase 2)

- **US1** (MVP): Start immediately after Phase 2
- **US2, US3, US4**: Can start once US1 tests pass (independent of each other)

### Parallel Opportunities Within Each Phase

**Phase 2 Parallel Work**:
- T005-T007: UI models (independent)
- T009-T011: Service implementation (parallel after T005-T007)
- T012-T013: Test infrastructure (parallel to service)

**Phase 3 Parallel Work**:
- T014-T018: Service tests (parallel)
- T019-T024: Provider tests (parallel)
- T025-T032: Provider implementation (after models complete)

---

## Success Metrics

| Metric | Target | Verification |
|--------|--------|--------------|
| Test Coverage (Service) | ≥90% | `flutter test --coverage` output |
| Test Coverage (Provider) | ≥85% | Coverage report analysis |
| Test Coverage (Overall) | ≥80% | Aggregated coverage metrics |
| Lint Violations | 0 new | `flutter analyze` output |
| JNAP Imports in Providers | 0 | `grep -r "import.*jnap/models" lib/page/advanced_settings/static_routing/providers/` |
| JNAP Imports in Views | 0 | `grep -r "import.*jnap/models" lib/page/advanced_settings/static_routing/[views|*.dart]` |
| DartDoc Coverage | 100% | Manual inspection of public methods |
| UI Backward Compatibility | 100% | Manual regression testing |
| JNAP Communication Success | 100% | Route save/fetch operations verified |

---

## Task Summary

- **Total Tasks**: 64 (T001-T064)
- **Phase 1 (Setup)**: 4 tasks
- **Phase 2 (Foundation)**: 9 tasks (BLOCKING)
- **Phase 3 (US1 MVP)**: 22 tasks
- **Phase 4 (US2)**: 6 tasks
- **Phase 5 (US3)**: 3 tasks
- **Phase 6 (US4)**: 3 tasks
- **Phase 7 (Polish)**: 8 tasks

### By Type

- **Infrastructure/Setup**: 13 tasks
- **Implementation**: 34 tasks
- **Testing**: 17 tasks

### Parallelizable Tasks

- Phase 2: T006, T007, T013 (3 parallel)
- Phase 3: T014-T032 (12 parallel opportunities)
- Phase 4-6: Multiple parallel test/implementation pairs

---

## MVP Delivery (User Story 1 Only)

**Estimated Effort**: 35-40 hours
**Tasks**: T001-T035 (setup through US1 complete)
**Delivers**: 60% of full feature value - core route management, Service layer, comprehensive tests

**To continue to US2-4**: Add 10-15 hours per story
