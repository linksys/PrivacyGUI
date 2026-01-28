# Implementation Plan: Device Manager Service Extraction

**Branch**: `001-device-manager-service-extraction` | **Date**: 2025-12-28 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-device-manager-service-extraction/spec.md`

## Summary

Extract `DeviceManagerService` from `DeviceManagerNotifier` to enforce three-layer architecture compliance per constitution Article V, VI, and XIII. The service will encapsulate all JNAP communication (8 model imports, 9 JNAP actions) and data transformation logic, while the notifier becomes a thin state holder that delegates to the service.

## Technical Context

**Language/Version**: Dart 3.0+, Flutter 3.3+
**Primary Dependencies**: flutter_riverpod 2.6.1, equatable 2.0.5
**Storage**: N/A (state management only)
**Testing**: flutter_test, mocktail 1.0.4
**Target Platform**: iOS, Android, Web (multi-platform Flutter app)
**Project Type**: Mobile app with shared core infrastructure
**Performance Goals**: No regression from current behavior
**Constraints**: Must maintain backward compatibility with all consumers of `deviceManagerProvider`
**Scale/Scope**: Core infrastructure provider used by 10+ feature modules

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Article | Requirement | Status | Notes |
|---------|-------------|--------|-------|
| **Article I** | Test coverage (Service ≥90%, Provider ≥85%) | ✅ PASS | SC-003, SC-004 define coverage targets |
| **Article V** | Three-layer architecture compliance | ✅ PASS | Primary goal of this feature |
| **Article VI** | Service layer for JNAP communication | ✅ PASS | Creating DeviceManagerService |
| **Article XIII** | ServiceError for error handling | ✅ PASS | FR-008 requires error mapping |
| **Article III** | Naming conventions | ✅ PASS | Following [feature]Service pattern |
| **Article XI** | Models implement Equatable | ✅ PASS | DeviceManagerState already compliant |

**Gate Result**: ✅ PASS - All constitutional requirements satisfied

## Project Structure

### Documentation (this feature)

```text
specs/001-device-manager-service-extraction/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── device_manager_service_contract.md
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```text
lib/core/jnap/
├── providers/
│   ├── device_manager_provider.dart    # MODIFY: Remove JNAP imports, delegate to service
│   └── device_manager_state.dart       # KEEP: No changes needed
└── services/                           # CREATE: New directory
    └── device_manager_service.dart     # CREATE: New service

test/core/jnap/
├── providers/
│   └── device_manager_provider_test.dart   # CREATE: Provider tests
└── services/
    └── device_manager_service_test.dart    # CREATE: Service tests

test/mocks/test_data/
└── device_manager_test_data.dart           # CREATE: Test data builder
```

**Structure Decision**: Service placed in `lib/core/jnap/services/` (infrastructure location) since this is core infrastructure, not a feature-specific provider. This follows the existing pattern where infrastructure code lives under `lib/core/`.

## Complexity Tracking

> No violations requiring justification - design follows minimal structure.
