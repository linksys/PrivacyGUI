# Implementation Plan: ConnectivityService Extraction

**Branch**: `001-connectivity-service` | **Date**: 2026-01-02 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-connectivity-service/spec.md`

## Summary

Extract JNAP-related logic from `ConnectivityNotifier` into a dedicated `ConnectivityService` to enforce three-layer architecture compliance. The Service will handle `testRouterType()` and `fetchRouterConfiguredData()` methods, converting JNAP models to return types and mapping errors to `ServiceError`.

## Technical Context

**Language/Version**: Dart 3.0+, Flutter 3.3+
**Primary Dependencies**: flutter_riverpod, shared_preferences, connectivity_plus
**Storage**: SharedPreferences (for router serial number comparison)
**Testing**: flutter_test with mocktail
**Target Platform**: iOS, Android, Web
**Project Type**: Mobile application (Flutter)
**Performance Goals**: N/A (internal refactoring, no performance changes)
**Constraints**: Must maintain backward compatibility with existing functionality
**Scale/Scope**: Single provider refactoring (~130 lines affected)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Article | Requirement | Status |
|---------|-------------|--------|
| **Article V Section 5.3** | Provider layer MUST NOT import `jnap/models`, `jnap/result`, `jnap/actions` | Will be enforced |
| **Article VI Section 6.1** | Services handle JNAP communication | Will create ConnectivityService |
| **Article VI Section 6.2** | Services return domain/UI models, not raw API responses | RouterType, RouterConfiguredData |
| **Article VI Section 6.3** | Services location: `lib/page/[feature]/services/` | Special case: `lib/providers/connectivity/services/` |
| **Article XIII Section 13.3** | Service layer converts JNAPError to ServiceError | Will use `mapJnapErrorToServiceError()` |
| **Article I Section 1.1** | Unit tests required | Will create service tests |

**Note**: ConnectivityProvider is in `lib/providers/` not `lib/page/`, so the service will be placed at `lib/providers/connectivity/services/` following the same relative pattern.

## Project Structure

### Documentation (this feature)

```text
specs/001-connectivity-service/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/providers/connectivity/
├── _connectivity.dart           # Existing: barrel export
├── availability_info.dart       # Existing: no changes
├── connectivity_info.dart       # Existing: contains RouterType enum
├── connectivity_provider.dart   # Modify: remove JNAP imports, delegate to service
├── connectivity_state.dart      # Existing: no changes
├── mixin.dart                   # Existing: no changes
└── services/                    # NEW
    └── connectivity_service.dart

test/providers/connectivity/
└── services/
    └── connectivity_service_test.dart
```

**Structure Decision**: Follow existing provider structure pattern. Since `ConnectivityProvider` lives in `lib/providers/connectivity/`, the service will be placed in `lib/providers/connectivity/services/` rather than `lib/page/*/services/`.

## Complexity Tracking

No complexity violations. This is a straightforward service extraction following established patterns.
