# Implementation Plan: DMZ Settings Provider Refactor

**Branch**: `002-dmz-refactor` | **Date**: 2025-12-08 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-dmz-refactor/spec.md`

## Summary

Refactor the DMZ Settings provider to follow PrivacyGUI's three-layer architecture (Data → Application → Presentation), extracting all JNAP protocol code from the Provider layer into a dedicated Service layer. Apply the Test Data Builder pattern to all service tests (proven effective in Administration Settings refactor). The refactored module will validate that the constitution v2.2 patterns are practical and clear for future refactors.

## Technical Context

**Language/Version**: Dart >=3.0.0, Flutter >=3.3.0
**Primary Dependencies**: flutter_riverpod (2.6.1), mocktail (for testing), JNAP protocol library
**Storage**: Local device communication (JNAP protocol), no persistent storage changes
**Testing**: Flutter test framework with mocktail, dart format, flutter analyze
**Target Platform**: iOS, Android, Web (existing PrivacyGUI targets)
**Project Type**: Mobile/Flutter app (single project with test subdirectory)
**Performance Goals**: Service layer response time <200ms (typical JNAP latency)
**Constraints**: No breaking changes to existing UI layer; maintain backward compatibility
**Scale/Scope**: ~3-5 DMZ-related JNAP actions to orchestrate; refactor existing functionality (no new features)

## Constitution Check

✅ **GATE ANALYSIS** (v2.2)

| Check | Status | Details |
|-------|--------|---------|
| Architecture Compliance | ✅ PASS | Three-layer architecture required; this feature enforces it |
| Testing Requirements | ✅ PASS | Spec requires Service ≥90%, Provider ≥85%, State ≥90% coverage |
| Mock Strategy | ✅ PASS | mocktail required for all unit tests per constitution |
| Test Data Builder | ✅ PASS | Spec requires use of centralized TestData builder pattern |
| Mocking All Dependencies | ✅ PASS | MockRouterRepository with mocktail for Service layer testing |
| Code Quality | ✅ PASS | 0 lint warnings, dart format compliance required in spec |
| DartDoc Comments | ✅ PASS | Public APIs in Service/Provider must have DartDoc |
| No Hardcoded Strings | ✅ PASS | UI layer responsibility; Service layer is protocol-only |

**Gate Result**: ✅ **ALL GATES PASS** - Feature aligns with constitution v2.2

## Project Structure

### Documentation (this feature)

```text
specs/002-dmz-refactor/
├── spec.md                      # Feature specification
├── plan.md                       # This file (implementation plan)
├── research.md                   # Phase 0: Architecture research (if needed)
├── data-model.md                 # Phase 1: Entity definitions
├── quickstart.md                 # Phase 1: Development quickstart
├── contracts/                    # Phase 1: API contracts (if applicable)
│   └── service-interface.md      # Service layer method signatures
├── checklists/
│   └── requirements.md           # Specification quality checklist
└── tasks.md                      # Phase 2: Task breakdown (created by /speckit.tasks)
```

### Source Code (repository)

```text
lib/page/advanced_settings/dmz/
├── services/
│   └── dmz_settings_service.dart                    # Service layer (NEW)
├── providers/
│   ├── dmz_settings_provider.dart                   # Provider/Notifier (REFACTORED)
│   └── dmz_settings_state.dart                      # State model (NEW/MOVED)
└── views/
    └── dmz_settings_view.dart                       # Presentation (UNCHANGED)

test/page/advanced_settings/dmz/
├── services/
│   ├── dmz_settings_service_test.dart               # Service tests (NEW)
│   └── dmz_settings_service_test_data.dart          # TestData builder (NEW)
├── providers/
│   ├── dmz_settings_provider_test.dart              # Provider tests (NEW)
│   └── dmz_settings_state_test.dart                 # State tests (NEW)
└── views/
    └── dmz_settings_view_test.dart                  # UI tests (UNCHANGED)

test/common/
└── unit_test_helper.dart                            # Existing helper for unit tests
```

**Structure Decision**: Flutter mobile app single-project structure. DMZ settings are part of the `advanced_settings` feature, organized by architectural layers (services, providers, views) with corresponding test structure. Uses existing PrivacyGUI patterns and infrastructure.

## Phase 0: Research & Clarifications

### No Clarifications Needed

The specification contains no [NEEDS CLARIFICATION] markers. All requirements are clear based on:

1. **Existing Administration Settings refactor** as a proven pattern
2. **Constitution v2.2** as the authoritative guide
3. **Existing PrivacyGUI architecture** as the reference implementation

### Research Tasks (Optional - Informational)

No blocking research required. Optional exploratory tasks:

- Understand existing DMZ provider implementation (current JNAP code structure)
- Review Administration Settings refactor (pattern reference)
- Verify JNAP DMZ action names and response structures

---

## Phase 1: Design & Contracts

### 1. Entity Design (data-model.md)

**Key Entities to Define**:

- **DmzSettings**: Core state model
  - Fields: `isEnabled`, `portRange`, `appVisibility`, `loggingEnabled`, `customRules`, etc.
  - Behaviors: Equatable, serializable (toMap/fromMap/toJson/fromJson), copyWith
  - Constraints: Port ranges must be valid (1-65535), immutable

- **DmzSettingsService**: Business logic coordinator
  - Methods: `fetchDmzSettings(Ref ref)`, `saveDmzSettings(Ref ref, DmzSettings settings)`
  - Responsibilities: JNAP orchestration, response parsing, error handling

- **DmzSettingsNotifier**: State management
  - Methods: `performFetch()`, `performSave()`
  - State: Preservable<DmzSettings> + DmzSettingsStatus
  - Responsibility: Delegate to Service, update UI state

- **DmzSettingsTestData**: Mock data factory
  - Factory methods: `createSuccessfulTransaction()`, `createPartialErrorTransaction()`
  - Purpose: Centralize JNAP mock responses, reduce test boilerplate

### 2. Service Layer Contract (contracts/service-interface.md)

Define public API for DmzSettingsService:

```dart
class DmzSettingsService {
  /// Fetch current DMZ settings from device
  Future<DmzSettings> fetchDmzSettings(Ref ref, {
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async { ... }

  /// Save modified DMZ settings to device
  Future<DmzSettings> saveDmzSettings(Ref ref, DmzSettings settings) async { ... }
}
```

### 3. TestData Builder Contract

Define centralized mock data factory:

```dart
class DmzSettingsTestData {
  static JNAPTransactionSuccessWrap createSuccessfulTransaction({
    Map<String, dynamic>? dmzState,
    Map<String, dynamic>? portMapping,
  }) { ... }

  static JNAPTransactionSuccessWrap createPartialErrorTransaction({
    required JNAPAction errorAction,
    String errorMessage = 'Operation failed',
  }) { ... }
}
```

### 4. Test Organization

Following constitution v2.2 Section 7 guidelines:

- **Service layer**: 7-10 tests (fetch success, save success, error paths, edge cases)
- **Provider layer**: 3-5 tests (delegation, state updates, error handling)
- **State layer**: 20-30 tests (serialization, copyWith, equality, boundaries)
- **Total**: ~33+ unit tests with ≥90% / ≥85% / ≥90% coverage targets

### 5. Agent Context Update

After design completion:
```bash
.specify/scripts/bash/update-agent-context.sh claude
```

This will add:
- DMZ module structure reference
- Service/Provider/State pattern reminder
- Test file locations for future AI assistance

---

## Phase 2: Implementation Ordering

### Phase 2A: Data Layer (Foundation)

**Tasks** (in order):

1. **T001**: Extract DMZ data model from existing provider
   - Create `lib/page/advanced_settings/dmz/providers/dmz_settings_state.dart`
   - Define `DmzSettings` with Equatable, serialization, copyWith
   - Define `DmzSettingsStatus`

2. **T002**: Create Service layer
   - Create `lib/page/advanced_settings/dmz/services/dmz_settings_service.dart`
   - Implement `fetchDmzSettings()` method
   - Implement `saveDmzSettings()` method (if applicable)
   - Add error handling with action context

3. **T003**: Create Service layer tests (7-10 tests)
   - Create `test/.../dmz/services/dmz_settings_service_test.dart`
   - Test successful fetch, save, error paths, edge cases
   - Use mocktail + RouterRepository

4. **T004**: Create TestData builder
   - Create `test/.../dmz/services/dmz_settings_service_test_data.dart`
   - Implement `createSuccessfulTransaction()` with partial override
   - Implement `createPartialErrorTransaction()`
   - Reduce test verbosity from 50+ LOC to <15 LOC per test

### Phase 2B: Application Layer (Business Logic)

**Tasks** (in order):

5. **T005**: Refactor Provider layer
   - Update `lib/page/advanced_settings/dmz/providers/dmz_settings_provider.dart`
   - Remove all JNAP imports and protocol code
   - Delegate to Service layer via `performFetch()` / `performSave()`
   - Use Preservable for undo/reset support
   - Verify 0 JNAP imports remain

6. **T006**: Create Provider layer tests (3-5 tests)
   - Create `test/.../dmz/providers/dmz_settings_provider_test.dart`
   - Test delegation to Service, state updates, error propagation
   - Use ProviderContainer for isolation

7. **T007**: Create State layer tests (20-30 tests)
   - Create `test/.../dmz/providers/dmz_settings_state_test.dart`
   - Test construction, copyWith, serialization (⚠️ critical), equality, boundaries
   - Focus on toMap/fromMap/toJson/fromJson (most commonly omitted)

### Phase 2C: Quality & Validation

**Tasks** (in order):

8. **T008**: Run full test suite
   - Execute all 33+ DMZ unit tests
   - Verify ≥90% Service, ≥85% Provider, ≥90% State coverage
   - Target overall ≥80% coverage

9. **T009**: Lint & format compliance
   - Run `flutter analyze` on DMZ module → 0 warnings
   - Run `dart format` → no changes
   - Verify no circular dependencies

10. **T010**: Constitution validation
    - Check against constitution v2.2 Section 6 (Test Data Builder)
    - Check against constitution v2.2 Section 7 (Three-Layer Testing)
    - Document any unclear or missing guidelines

11. **T011**: Backward compatibility testing
    - Run existing DMZ UI tests
    - Verify 0 breaking changes
    - Ensure UI layer remains unchanged

### Phase 2D: Documentation

**Tasks** (final):

12. **T012**: Update design artifacts
    - Finalize data-model.md with actual entities
    - Create service-interface.md with final method signatures
    - Create quickstart.md with developer guidance

---

## Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|-----------|
| Service layer methods incomplete | Low | High | Reference Administration Settings; spec defines required methods |
| Test coverage insufficient | Low | High | Use constitution targets (≥90%); automated coverage checks |
| JNAP code remains in Provider | Low | High | Use automated grep checks; Code Review gate |
| TestData builder not applied | Low | Medium | Enforce 3+ reuse rule; Code Review verification |
| Backward compatibility broken | Low | High | Run existing UI tests; maintain current API surface |
| Constitution guidance unclear | Medium | Medium | Document gaps; note for v2.3 updates; this is intentional validation |

---

## Success Criteria

✅ **Feature is complete when**:

1. All 33+ tests pass with ≥90% / ≥85% / ≥90% coverage
2. `flutter analyze` returns 0 warnings on DMZ module
3. All JNAP code isolated in Service layer (0 JNAP imports in Provider)
4. TestData builder applied to all Service tests (≥70% code reduction)
5. All existing UI tests continue to pass (backward compatibility)
6. Constitution v2.2 patterns validated and any unclear guidelines documented

---

## Next Steps

→ **Phase 2 Tasks Ready for Implementation**

1. Follow task ordering: T001 → T012
2. Each task includes specific acceptance criteria
3. Constitution v2.2 guidelines available for reference
4. Use Administration Settings refactor as pattern reference

Once Phase 2 implementation is complete, run `/speckit.tasks` to generate detailed task breakdown with dependencies.
