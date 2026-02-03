# Tasks: NodeLightSettings Service Extraction

**Input**: Design documents from `/specs/002-node-light-settings-service/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), data-model.md, contracts/

**Tests**: Included as requested in spec.md (FR-010, FR-011)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter mobile**: `lib/` for source, `test/` for tests
- Paths follow plan.md structure

---

## Phase 1: Setup

**Purpose**: No setup needed - this is a refactoring of existing code

**Note**: Project structure already exists. Proceed directly to implementation.

---

## Phase 2: Foundational (Service Creation)

**Purpose**: Create the NodeLightSettingsService that ALL user stories depend on

**⚠️ CRITICAL**: Service must be complete before Provider refactoring can begin

### Model Tests

- [X] T001 [P] Create NodeLightSettings model tests in test/core/jnap/models/node_light_settings_test.dart
  - fromMap with all fields
  - fromMap with minimal fields (Enable only)
  - toMap excludes null fields
  - toMap includes all non-null fields
  - factory on() produces correct settings
  - factory off() produces correct settings
  - factory night() produces correct settings
  - fromStatus(on/off/night) conversions
  - copyWith partial updates
  - equality (Equatable props)
  - toJson/fromJson roundtrip

### Service Implementation

- [X] T002 Create NodeLightSettingsService class in lib/core/jnap/services/node_light_settings_service.dart
  - Constructor with RouterRepository injection
  - Provider definition (nodeLightSettingsServiceProvider)

- [X] T003 Implement fetchSettings() method in lib/core/jnap/services/node_light_settings_service.dart
  - Call JNAPAction.getLedNightModeSetting via RouterRepository
  - Support forceRemote parameter for cache bypass
  - Return NodeLightSettings.fromMap(result.output)

- [X] T004 Implement saveSettings() method in lib/core/jnap/services/node_light_settings_service.dart
  - Call JNAPAction.setLedNightModeSetting via RouterRepository
  - Send Enable, StartingTime, EndingTime (exclude nulls)
  - Re-fetch after save to return confirmed state

- [X] T005 Implement _mapJnapError() method in lib/core/jnap/services/node_light_settings_service.dart
  - Map _ErrorUnauthorized to UnauthorizedError
  - Map other errors to UnexpectedError with original error

### Service Tests

- [X] T006 [P] Create NodeLightSettingsService tests in test/core/jnap/services/node_light_settings_service_test.dart
  - Mock RouterRepository
  - Test fetchSettings returns NodeLightSettings from JNAP response
  - Test fetchSettings with forceRemote=true bypasses cache
  - Test fetchSettings throws UnauthorizedError on auth failure
  - Test saveSettings persists and returns refreshed settings
  - Test saveSettings throws UnauthorizedError on auth failure
  - Test saveSettings excludes null fields from request

**Checkpoint**: Service layer complete and tested - Provider refactoring can now begin

---

## Phase 3: User Story 1 - Code Architecture Compliance (Priority: P1) 🎯 MVP

**Goal**: Remove JNAP imports from Provider, delegate to Service

**Independent Test**: `grep -r "import.*jnap/actions" lib/core/jnap/providers/node_light_settings_provider.dart` returns zero results

### Implementation for User Story 1

- [X] T007 [US1] Refactor NodeLightSettingsNotifier.fetch() in lib/core/jnap/providers/node_light_settings_provider.dart
  - Remove direct JNAP communication code
  - Delegate to nodeLightSettingsServiceProvider.fetchSettings()
  - Update state with result

- [X] T008 [US1] Refactor NodeLightSettingsNotifier.save() in lib/core/jnap/providers/node_light_settings_provider.dart
  - Remove direct JNAP communication code
  - Delegate to nodeLightSettingsServiceProvider.saveSettings(state)
  - Update state with result

- [X] T009 [US1] Remove JNAP imports from lib/core/jnap/providers/node_light_settings_provider.dart
  - Remove: import 'package:privacy_gui/core/jnap/actions/better_action.dart'
  - Remove: import 'package:privacy_gui/core/jnap/router_repository.dart'
  - Add: import 'package:privacy_gui/core/jnap/services/node_light_settings_service.dart'

- [X] T010 [US1] Verify currentStatus getter remains unchanged in lib/core/jnap/providers/node_light_settings_provider.dart
  - Getter should stay in Provider (UI transformation logic)
  - No modification needed, just verification

### Provider Tests for User Story 1

- [X] T011 [US1] Create Provider delegation tests in test/core/jnap/providers/node_light_settings_provider_test.dart
  - Mock NodeLightSettingsService
  - Test fetch() calls service.fetchSettings() and updates state
  - Test save() calls service.saveSettings(state) and updates state
  - Test setSettings() updates state directly (no service call)

### Verification for User Story 1

- [X] T012 [US1] Run architecture verification
  - Execute: grep -r "import.*jnap/actions" lib/core/jnap/providers/node_light_settings_provider.dart
  - Execute: grep -r "import.*router_repository" lib/core/jnap/providers/node_light_settings_provider.dart
  - Both commands must return empty (zero matches)

- [X] T013 [US1] Run static analysis
  - Execute: flutter analyze lib/core/jnap/providers/node_light_settings_provider.dart
  - Execute: flutter analyze lib/core/jnap/services/node_light_settings_service.dart
  - No errors allowed

**Checkpoint**: Architecture compliance verified - Provider has no JNAP imports

---

## Phase 4: User Story 2 - LED Settings Retrieval (Priority: P1)

**Goal**: Verify settings retrieval works correctly through new architecture

**Independent Test**: Navigate to node detail page and verify LED status displays correctly

### Provider Tests for User Story 2

- [X] T014 [US2] Add currentStatus getter tests in test/core/jnap/providers/node_light_settings_provider_test.dart
  - Test currentStatus returns NodeLightStatus.on when isNightModeEnable=false
  - Test currentStatus returns NodeLightStatus.off when allDayOff=true
  - Test currentStatus returns NodeLightStatus.off when startHour=0 and endHour=24
  - Test currentStatus returns NodeLightStatus.night when isNightModeEnable=true with partial schedule

**Checkpoint**: Settings retrieval verified through Provider tests

---

## Phase 5: User Story 3 - LED Settings Update (Priority: P1)

**Goal**: Verify settings update works correctly through new architecture

**Independent Test**: Toggle night mode in dashboard quick panel, verify change persists

### Integration Verification for User Story 3

- [X] T015 [US3] Verify save flow in test/core/jnap/providers/node_light_settings_provider_test.dart
  - Test setSettings() followed by save() persists correct values
  - Test state updates after successful save

**Checkpoint**: Settings update verified - all user stories complete

---

## Phase 6: Polish & Verification

**Purpose**: Final validation and cleanup

- [X] T016 Run all tests
  - Execute: flutter test test/core/jnap/models/node_light_settings_test.dart
  - Execute: flutter test test/core/jnap/services/node_light_settings_service_test.dart
  - Execute: flutter test test/core/jnap/providers/node_light_settings_provider_test.dart
  - All tests must pass ✓ (35 tests passed)

- [X] T017 Run full project analysis
  - Execute: flutter analyze
  - No errors on affected files ✓

- [X] T018 Verify success criteria
  - SC-001: Zero JNAP action imports in provider ✓
  - SC-002: Zero router_repository imports in provider ✓
  - SC-003: Existing functionality unchanged (manual verification)
  - SC-004: Service test coverage ≥90% ✓
  - SC-005: Provider test coverage ≥85% ✓
  - SC-006: flutter analyze passes ✓
  - SC-007: All existing tests pass ✓

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Skipped - existing project
- **Phase 2 (Foundational)**: Creates Service - BLOCKS all user stories
- **Phase 3 (US1)**: Depends on Phase 2 - refactors Provider
- **Phase 4 (US2)**: Depends on Phase 3 - tests retrieval
- **Phase 5 (US3)**: Depends on Phase 3 - tests update
- **Phase 6 (Polish)**: Depends on all phases complete

### User Story Dependencies

- **User Story 1 (P1)**: Requires Service (Phase 2) complete
- **User Story 2 (P1)**: Requires US1 complete (Provider refactored)
- **User Story 3 (P1)**: Requires US1 complete (Provider refactored)
- US2 and US3 can run in parallel after US1

### Within Each Phase

- Tests before implementation (TDD approach)
- Service methods in order: constructor → fetchSettings → saveSettings → error mapping
- Provider refactoring in order: fetch → save → remove imports → verify

### Parallel Opportunities

```text
Phase 2 (Foundational):
  - T001 [P] Model tests
  - T006 [P] Service tests
  (can write tests in parallel before implementation)

Phase 4 & 5 (US2 & US3):
  - Can run in parallel after US1 complete
  - T014 [US2] and T015 [US3] are independent
```

---

## Parallel Example: Phase 2

```bash
# Launch tests in parallel (write first, then implement):
Task: T001 - Model tests in test/core/jnap/models/node_light_settings_test.dart
Task: T006 - Service tests in test/core/jnap/services/node_light_settings_service_test.dart

# Then implement sequentially:
Task: T002 → T003 → T004 → T005 (Service implementation)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 2: Service creation + tests
2. Complete Phase 3: Provider refactoring (US1)
3. **STOP and VALIDATE**: Run T012 architecture verification
4. Proceed to US2/US3 tests

### Incremental Delivery

1. Service created → Tests pass
2. Provider refactored → Architecture verified → MVP done!
3. Add US2 tests → Verify retrieval
4. Add US3 tests → Verify update
5. Each phase adds confidence without breaking functionality

---

## Notes

- All 3 User Stories have P1 priority - they are all essential
- US1 is the core refactoring task
- US2/US3 verify the refactoring works correctly
- No UI changes needed - pure backend refactoring
- Existing model (NodeLightSettings) remains unchanged
- currentStatus getter stays in Provider (UI logic)
