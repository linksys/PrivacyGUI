# Implementation Plan: NodeDetail Service Extraction

**Branch**: `001-node-detail-service` | **Date**: 2026-01-02 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-node-detail-service/spec.md`

## Summary

Extract NodeDetailService from NodeDetailNotifier to enforce three-layer architecture compliance (constitution.md Article V, VI, XIII). The Service will handle JNAP communication for LED blinking operations and provide transformation helpers for converting device data to UI-appropriate values. The Provider will delegate JNAP operations to the Service and only handle ServiceError types.

## Technical Context

**Language/Version**: Dart 3.0+, Flutter 3.3+
**Primary Dependencies**: flutter_riverpod, shared_preferences, collection
**Storage**: SharedPreferences (for blink tracking state)
**Testing**: flutter test with Mocktail for mocking
**Target Platform**: iOS, Android, Web (cross-platform Flutter app)
**Project Type**: Mobile/Web Flutter application
**Performance Goals**: N/A (refactoring task, no performance changes)
**Constraints**: Must maintain identical behavior to existing implementation
**Scale/Scope**: Single Provider/Service extraction, affects ~3 files

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Design Check (Phase 0)

| Article | Requirement | Status | Notes |
|---------|-------------|--------|-------|
| **Article I** (Tests) | Unit tests for Service ≥90%, Provider ≥85% | PLANNED | New tests required |
| **Article III** (Naming) | Service: `node_detail_service.dart`, Class: `NodeDetailService` | COMPLIANT | |
| **Article V** (Architecture) | Three-layer separation, no JNAP imports in Provider | PLANNED | Core goal of this refactoring |
| **Article VI** (Service Layer) | Service handles JNAP, returns UI models, stateless | PLANNED | Service design follows this |
| **Article XI** (Models) | State implements Equatable, toJson/fromJson | EXISTING | NodeDetailState already compliant |
| **Article XIII** (Errors) | Service maps JNAPError to ServiceError | PLANNED | Error handling will be implemented |

**Gate Status**: PASS - No violations, all requirements can be addressed in implementation.

### Post-Design Check (Phase 1)

| Article | Requirement | Status | Notes |
|---------|-------------|--------|-------|
| **Article I** (Tests) | Unit tests for Service ≥90%, Provider ≥85% | DESIGNED | Test structure defined in quickstart.md |
| **Article III** (Naming) | Service: `node_detail_service.dart`, Class: `NodeDetailService` | COMPLIANT | Follows `[feature]_service.dart` pattern |
| **Article V** (Architecture) | Three-layer separation, no JNAP imports in Provider | DESIGNED | Contract specifies transformation helpers pattern |
| **Article VI** (Service Layer) | Service handles JNAP, returns UI models, stateless | DESIGNED | Service contract is stateless, uses constructor injection |
| **Article IX** (Docs) | Contract documentation in Markdown | COMPLIANT | `contracts/node_detail_service_contract.md` created |
| **Article XI** (Models) | State implements Equatable, toJson/fromJson | EXISTING | No changes to existing compliant state |
| **Article XIII** (Errors) | Service maps JNAPError to ServiceError | DESIGNED | Uses `mapJnapErrorToServiceError()` per contract |

**Post-Design Gate Status**: PASS - Design artifacts conform to all constitution articles.

## Project Structure

### Documentation (this feature)

```text
specs/001-node-detail-service/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/page/nodes/
├── providers/
│   ├── node_detail_provider.dart    # MODIFY: Remove JNAP imports, delegate to Service
│   ├── node_detail_state.dart       # MODIFY: Remove JNAP model import (NodeLightSettings)
│   └── node_detail_id_provider.dart # NO CHANGE
├── services/
│   └── node_detail_service.dart     # CREATE: New Service class
└── views/
    └── ...                          # NO CHANGE

test/page/nodes/
├── providers/
│   ├── node_detail_provider_test.dart  # CREATE: Provider unit tests
│   └── node_detail_state_test.dart     # CREATE: State unit tests
├── services/
│   └── node_detail_service_test.dart   # CREATE: Service unit tests
└── ...

test/mocks/test_data/
└── node_detail_test_data.dart          # CREATE: Test data builder
```

**Structure Decision**: Following existing Flutter feature structure pattern at `lib/page/[feature]/`. Adding `services/` subdirectory for the new Service class.

## Complexity Tracking

> No violations requiring justification. This is a straightforward service extraction following established patterns.
