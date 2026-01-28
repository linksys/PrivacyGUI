# Implementation Plan: Extract AddNodesService (Bluetooth + Wired)

**Branch**: `001-add-nodes-service` | **Date**: 2026-01-07 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-add-nodes-service/spec.md`

> **Note**: AddNodesService (Bluetooth) is already implemented. This plan focuses on the scope extension: **AddWiredNodesService**.

## Summary

Extract JNAP communication from `AddWiredNodesNotifier` into a dedicated `AddWiredNodesService` class to enforce three-layer architecture compliance (constitution Article V, VI, XIII). The service will handle wired auto-onboarding settings, backhaul polling, and node fetching. A new `BackhaulInfoUIModel` will replace `BackHaulInfoData` in the State layer.

## Technical Context

**Language/Version**: Dart 3.0+, Flutter 3.3+
**Primary Dependencies**: flutter_riverpod, RouterRepository (core/jnap)
**Storage**: N/A (no persistent storage in this feature)
**Testing**: flutter_test, mocktail
**Target Platform**: iOS, Android, Web (existing app targets)
**Project Type**: Mobile (Flutter)
**Performance Goals**: Preserve existing polling behavior and timing
**Constraints**: Must maintain 100% behavioral compatibility with existing implementation
**Scale/Scope**: Single feature refactoring (4 files modified, 2-3 files created)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Article | Requirement | Status | Notes |
|---------|-------------|--------|-------|
| **Article I** | Test coverage (Service ≥90%, Provider ≥85%) | ✅ PASS | SC-010, SC-011 define targets |
| **Article V** | Three-layer architecture | ✅ PASS | This refactoring enforces compliance |
| **Article VI** | Service Layer Principle | ✅ PASS | Creating AddWiredNodesService |
| **Article VII** | Anti-Abstraction (no framework wrappers) | ✅ PASS | Service is legitimate abstraction |
| **Article XI** | Model requirements (Equatable, toMap/fromMap) | ✅ PASS | BackhaulInfoUIModel will implement |
| **Article XIII** | Error handling (ServiceError) | ✅ PASS | Service will map JNAPError → ServiceError |

**Gate Result**: ✅ PASS - All constitution checks satisfied

## Project Structure

### Documentation (this feature)

```text
specs/001-add-nodes-service/
├── plan.md              # This file
├── research.md          # Phase 0 output (minimal - existing patterns)
├── data-model.md        # Phase 1 output (BackhaulInfoUIModel)
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (AddWiredNodesService contract)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/page/nodes/
├── providers/
│   ├── add_wired_nodes_provider.dart  # MODIFY: Remove JNAP imports, delegate to service
│   └── add_wired_nodes_state.dart     # MODIFY: Replace BackHaulInfoData with BackhaulInfoUIModel
├── services/
│   ├── add_nodes_service.dart         # EXISTING: Bluetooth service (already done)
│   └── add_wired_nodes_service.dart   # CREATE: New wired nodes service
└── models/
    └── backhaul_info_ui_model.dart    # CREATE: UI model for backhaul info

test/page/nodes/
├── providers/
│   ├── add_wired_nodes_provider_test.dart  # CREATE: Provider tests
│   └── add_wired_nodes_state_test.dart     # CREATE: State tests
├── services/
│   └── add_wired_nodes_service_test.dart   # CREATE: Service tests
└── models/
    └── backhaul_info_ui_model_test.dart    # CREATE: UI model tests

test/mocks/test_data/
└── add_wired_nodes_test_data.dart     # CREATE: Test data builder
```

**Structure Decision**: Using existing Flutter feature structure per constitution Article V Section 5.2.

## Complexity Tracking

> No violations requiring justification. This is a straightforward service extraction following established patterns.

