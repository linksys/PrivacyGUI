# Implementation Plan: Instant Admin Service Extraction

**Branch**: `003-instant-admin-service` | **Date**: 2025-12-22 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-instant-admin-service/spec.md`

## Summary

Extract JNAP communication logic from `TimezoneNotifier` and `PowerTableNotifier` into dedicated `TimezoneService` and `PowerTableService` classes, following Article VI Service Layer Principle. This refactoring ensures three-layer architecture compliance by moving all RouterRepository calls and JNAP data transformations to the Service layer, while Providers focus solely on state management.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x
**Primary Dependencies**: Riverpod (state management), Mocktail (testing), Equatable (models)
**Storage**: N/A (no persistent storage changes)
**Testing**: flutter test with Mocktail for mocking
**Target Platform**: iOS, Android, Web
**Project Type**: Mobile application (Flutter)
**Performance Goals**: No regression from current behavior
**Constraints**: Must maintain backward compatibility; no UI changes
**Scale/Scope**: 2 new service files, 2 provider refactors, 2 test files, 1 test data builder

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Article | Requirement | Status | Notes |
|---------|-------------|--------|-------|
| I (Test) | Unit tests for Services ≥90% coverage | ✅ Planned | Tests will be created for both services |
| III (Naming) | snake_case files, UpperCamelCase classes | ✅ Compliant | `timezone_service.dart`, `TimezoneService` |
| V (Architecture) | Three-layer separation | ✅ Addressed | This is the core goal of this feature |
| VI (Service Layer) | Services encapsulate JNAP, stateless, constructor injection | ✅ Planned | Following `router_password_service.dart` pattern |
| VIII (Testing) | Mocktail for mocks, Test Data Builders | ✅ Planned | `instant_admin_test_data.dart` |
| XIII (Error Handling) | JNAPError → ServiceError mapping in Service layer | ✅ Planned | Using `mapJnapErrorToServiceError` helper |

**Gate Result**: ✅ PASS - No violations; design aligns with constitution.

## Project Structure

### Documentation (this feature)

```text
specs/003-instant-admin-service/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── timezone_service_contract.md
│   └── power_table_service_contract.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
lib/page/instant_admin/
├── providers/
│   ├── timezone_provider.dart      # MODIFY: delegate to TimezoneService
│   ├── timezone_state.dart         # NO CHANGE
│   ├── power_table_provider.dart   # MODIFY: delegate to PowerTableService
│   └── power_table_state.dart      # NO CHANGE
└── services/
    ├── router_password_service.dart  # EXISTING (reference)
    ├── timezone_service.dart         # NEW
    └── power_table_service.dart      # NEW

test/
├── page/instant_admin/services/
│   ├── timezone_service_test.dart    # NEW
│   └── power_table_service_test.dart # NEW
└── mocks/test_data/
    └── instant_admin_test_data.dart  # NEW (or extend existing)
```

**Structure Decision**: Mobile application with feature-based organization. Services added to existing `lib/page/instant_admin/services/` directory alongside `router_password_service.dart`.

## Complexity Tracking

> No violations requiring justification. Design follows existing patterns.

| Aspect | Decision | Rationale |
|--------|----------|-----------|
| Separate Services | TimezoneService + PowerTableService | Each provider has distinct JNAP actions; single responsibility principle |
| Reuse existing models | TimezoneSettings, TimezoneStatus, PowerTableState | Already Equatable-compliant; no need for new UI models |
| Error handling | Use existing ServiceError types | UnexpectedError, NetworkError sufficient for timezone/power table |
