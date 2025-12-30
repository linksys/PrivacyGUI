# Implementation Plan: Dashboard Manager Service Extraction

**Branch**: `005-dashboard-service-extraction` | **Date**: 2025-12-29 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/005-dashboard-service-extraction/spec.md`

## Summary

Extract JNAP communication and data transformation logic from `DashboardManagerNotifier` into a new `DashboardManagerService` class to enforce three-layer architecture compliance per constitution.md Article V, VI, XIII. The service will handle 7 JNAP actions (getDeviceInfo, getRadioInfo, getGuestRadioSettings, getSystemStats, getEthernetPortConnections, getLocalTime, getSoftSKUSettings) and provide 3 public methods: `transformPollingData()`, `checkRouterIsBack()`, and `checkDeviceInfo()`.

## Technical Context

**Language/Version**: Dart 3.0+, Flutter 3.3+
**Primary Dependencies**: flutter_riverpod 2.6.1, equatable 2.0.5
**Storage**: N/A (state management only)
**Testing**: flutter_test, mocktail
**Target Platform**: iOS, Android, Web
**Project Type**: Mobile application (Flutter)
**Performance Goals**: No degradation from current polling cycle performance
**Constraints**: Must maintain backward compatibility with existing dashboard UI
**Scale/Scope**: Single provider refactoring, ~150 lines of code to move

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Article | Requirement | Status | Notes |
|---------|-------------|--------|-------|
| **Article I** | Test coverage (Service ≥90%, Provider ≥85%) | ✅ Planned | Test files specified in structure |
| **Article III** | Naming conventions | ✅ Compliant | `DashboardManagerService`, `dashboardManagerServiceProvider` |
| **Article V Section 5.3** | Three-layer architecture | ✅ Target | This refactoring enforces compliance |
| **Article VI** | Service layer principle | ✅ Compliant | Service handles JNAP, returns state |
| **Article VII** | Anti-abstraction (no framework wrappers) | ✅ Compliant | Service is legitimate abstraction |
| **Article XIII** | Error handling (ServiceError) | ✅ Planned | JNAPError → ServiceError mapping |

**Gate Result**: ✅ PASS - No violations requiring justification

## Project Structure

### Documentation (this feature)

```text
specs/005-dashboard-service-extraction/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── dashboard_manager_service_contract.md
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
lib/core/jnap/
├── providers/
│   ├── dashboard_manager_provider.dart  # MODIFY: Remove JNAP imports, delegate to service
│   └── dashboard_manager_state.dart     # PRESERVE: No changes
└── services/
    └── dashboard_manager_service.dart   # CREATE: New service file

test/core/jnap/
├── providers/
│   └── dashboard_manager_provider_test.dart  # CREATE: Provider tests
└── services/
    └── dashboard_manager_service_test.dart   # CREATE: Service tests

test/mocks/test_data/
└── dashboard_manager_test_data.dart          # CREATE: Test data builder (per constitution Section 1.6.2)
```

**Structure Decision**: Following existing pattern from `lib/core/jnap/services/device_manager_service.dart`. Service placed in `lib/core/jnap/services/` alongside DeviceManagerService since both are core infrastructure services, not page-specific features.

## Complexity Tracking

> No violations requiring justification. This is a straightforward refactoring with clear reference implementation (DeviceManagerService).
