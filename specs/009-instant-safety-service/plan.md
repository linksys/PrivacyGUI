# Implementation Plan: InstantSafety Service Extraction

**Branch**: `004-instant-safety-service` | **Date**: 2025-12-22 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-instant-safety-service/spec.md`

## Summary

Extract `InstantSafetyService` from `InstantSafetyNotifier` to enforce three-layer architecture compliance per constitution.md Articles V, VI, and XIII. The service will encapsulate all JNAP communication (getLANSettings, setLANSettings) and error mapping to ServiceError, removing JNAP model imports from the Provider and State layers.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x
**Primary Dependencies**: Riverpod (state management), Mocktail (testing), Equatable (models)
**Storage**: N/A (no persistent storage changes)
**Testing**: flutter test, Mocktail for mocks
**Target Platform**: iOS, Android, Web (existing Flutter app)
**Project Type**: Mobile application
**Performance Goals**: No performance changes - internal refactoring only
**Constraints**: Maintain PreservableNotifierMixin compatibility for dirty guard functionality
**Scale/Scope**: Single feature module refactoring (~300 lines affected)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Article | Requirement | Status | Notes |
|---------|-------------|--------|-------|
| **I** Test Requirement | Service ≥90%, Provider ≥85% coverage | ✅ Planned | New tests will be created |
| **I.6** Mock Creation | Use Mocktail for mocks | ✅ Compliant | Will use MockRouterRepository |
| **III** Naming Conventions | snake_case files, UpperCamelCase classes | ✅ Compliant | `instant_safety_service.dart`, `InstantSafetyService` |
| **V** Three-Layer Architecture | No JNAP imports in Provider | 🎯 Target | This is the goal of this refactoring |
| **VI** Service Layer Principle | Service handles JNAP, returns UI models | ✅ Planned | Core implementation approach |
| **XI** Data Models | Equatable, toMap/fromMap | ✅ Compliant | Existing models already compliant |
| **XIII** Error Handling | ServiceError only in Provider | 🎯 Target | Will remove JNAPError from Provider |

**Pre-Design Gate**: ✅ PASS - No violations, proceeding to research

## Project Structure

### Documentation (this feature)

```text
specs/004-instant-safety-service/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── instant_safety_service_contract.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
lib/page/instant_safety/
├── providers/
│   ├── instant_safety_provider.dart  # MODIFY: Remove JNAP imports, delegate to service
│   └── instant_safety_state.dart     # MODIFY: Remove RouterLANSettings from Status
├── services/                          # CREATE
│   └── instant_safety_service.dart   # CREATE: New service class
└── views/
    └── instant_safety_view.dart      # NO CHANGE

test/page/instant_safety/
├── providers/
│   ├── instant_safety_provider_test.dart  # CREATE: Provider tests
│   └── instant_safety_state_test.dart     # CREATE: State tests
├── services/
│   └── instant_safety_service_test.dart   # CREATE: Service tests
└── [no models/ - not needed per Section 5.3.4]

test/mocks/test_data/
└── instant_safety_test_data.dart     # CREATE: Test data builder
```

**Structure Decision**: Flutter mobile app structure following existing `lib/page/[feature]/` pattern. No UI Model needed per constitution Section 5.3.4 (InstantSafetySettings has only 1 enum field - flat basic types).

## Complexity Tracking

No violations to justify - this refactoring simplifies the codebase by enforcing proper layer separation.
