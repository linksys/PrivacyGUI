# Implementation Plan: DashboardHome Service Extraction

**Branch**: `006-dashboard-home-service-extraction` | **Date**: 2025-12-29 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/006-dashboard-home-service-extraction/spec.md`

## Summary

Extract data transformation logic from `DashboardHomeNotifier` into a new `DashboardHomeService` class to enforce three-layer architecture compliance. The service will handle all JNAP model transformations, allowing the Provider and State layers to remain free of `core/jnap/models/` imports.

## Technical Context

**Language/Version**: Dart 3.0+, Flutter 3.3+
**Primary Dependencies**: flutter_riverpod 2.6.1, equatable 2.0.5, collection
**Storage**: N/A (state management only)
**Testing**: flutter_test, mocktail
**Target Platform**: iOS, Android, Web (Flutter multi-platform)
**Project Type**: Mobile application
**Performance Goals**: N/A (pure refactoring, no behavior change)
**Constraints**: Must maintain identical runtime behavior; Provider layer must not import `core/jnap/models/`
**Scale/Scope**: Single feature refactoring (~100 lines of code moved)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Article | Requirement | Status | Notes |
|---------|-------------|--------|-------|
| **Article I** | Test coverage for Services ≥90%, Providers ≥85% | ✅ PASS | Will create unit tests for DashboardHomeService |
| **Article III** | Naming conventions (snake_case files, UpperCamelCase classes) | ✅ PASS | `dashboard_home_service.dart`, `DashboardHomeService` |
| **Article V** | Three-layer architecture compliance | ✅ PASS | This refactoring enforces Article V compliance |
| **Article VI** | Service layer for business logic & JNAP communication | ✅ PASS | Creating DashboardHomeService per Article VI |
| **Article VII** | No unnecessary abstractions | ✅ PASS | Service is legitimate abstraction per Article VII Section 7.2 |
| **Article VIII** | Unit tests with Mocktail | ✅ PASS | Will use Mocktail for service tests |
| **Article IX** | API contracts in Markdown | ✅ PASS | contracts/dashboard_home_service_contract.md |
| **Article XI** | Models implement Equatable, toMap/fromMap | ✅ PASS | Existing models already compliant |
| **Article XIII** | ServiceError for error handling | ⚠️ N/A | No JNAP calls in service (pure transformation) |

**Gate Status**: ✅ PASSED - All applicable articles satisfied

## Project Structure

### Documentation (this feature)

```text
specs/006-dashboard-home-service-extraction/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── dashboard_home_service_contract.md
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
lib/page/dashboard/
├── providers/
│   ├── dashboard_home_provider.dart  # Refactored - delegates to service
│   └── dashboard_home_state.dart     # Refactored - no JNAP imports
├── services/                          # NEW directory
│   └── dashboard_home_service.dart   # NEW - transformation logic
└── views/
    └── [unchanged]

test/page/dashboard/
├── providers/
│   └── dashboard_home_provider_test.dart  # Update/create
├── services/                               # NEW directory
│   └── dashboard_home_service_test.dart   # NEW - service tests
└── mocks/test_data/
    └── dashboard_home_test_data.dart      # NEW - test data builder
```

**Structure Decision**: Flutter mobile app structure with three-layer architecture (views → providers → services). New `services/` directory created under `lib/page/dashboard/`.

## Complexity Tracking

No violations to justify - this implementation follows standard patterns.
