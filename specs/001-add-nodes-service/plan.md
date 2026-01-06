# Implementation Plan: Extract AddNodesService

**Branch**: `001-add-nodes-service` | **Date**: 2026-01-06 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-add-nodes-service/spec.md`

## Summary

Extract JNAP communication logic from AddNodesNotifier into a new AddNodesService class to enforce three-layer architecture compliance (constitution Articles V, VI, XIII). The service will handle Bluetooth auto-onboarding operations and node polling, converting JNAPError to ServiceError and returning UI-friendly models.

## Technical Context

**Language/Version**: Dart 3.0+, Flutter 3.3+
**Primary Dependencies**: flutter_riverpod, RouterRepository (core/jnap)
**Storage**: N/A (no persistent storage in this feature)
**Testing**: flutter_test, mocktail
**Target Platform**: iOS, Android, Web
**Project Type**: Mobile (Flutter)
**Performance Goals**: Preserve existing polling behavior; no performance regression
**Constraints**: Must maintain backward compatibility; no UI changes
**Scale/Scope**: Single provider refactoring; ~300 lines of code movement

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Article | Requirement | Status | Notes |
|---------|-------------|--------|-------|
| **V §5.3** | Three-layer architecture | **TARGET** | Current violation: Provider imports jnap/models, jnap/result |
| **V §5.3.2** | Provider layer no JNAP models | **TARGET** | Will remove BackHaulInfoData import from Provider |
| **VI §6.1** | Service layer mandate | **TARGET** | Will create AddNodesService |
| **VI §6.2** | Service responsibilities | **COMPLIANT** | Service will be stateless, inject RouterRepository |
| **VI §6.3** | File organization | **COMPLIANT** | `lib/page/nodes/services/add_nodes_service.dart` |
| **XIII §13.1** | Unified error handling | **TARGET** | Service will convert JNAPError → ServiceError |
| **XIII §13.4** | Provider only ServiceError | **TARGET** | Will remove JNAPResult handling from Provider |
| **I §1.4** | Test coverage | **COMPLIANT** | Service ≥90%, Provider ≥85% |
| **III §3.2** | File naming | **COMPLIANT** | `add_nodes_service.dart` |
| **III §3.3.1** | Class naming | **COMPLIANT** | `AddNodesService` |
| **III §3.4.1** | Provider naming | **COMPLIANT** | `addNodesServiceProvider` |

**Gate Status**: ✅ PASS - All requirements clear, no violations in design approach

## Project Structure

### Documentation (this feature)

```text
specs/001-add-nodes-service/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Phase 0 output (patterns research)
├── data-model.md        # Phase 1 output (entity definitions)
├── quickstart.md        # Phase 1 output (implementation guide)
├── contracts/           # Phase 1 output (service contract)
│   └── add_nodes_service_contract.md
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
lib/page/nodes/
├── providers/
│   ├── add_nodes_provider.dart   # MODIFY: Remove JNAP imports, delegate to Service
│   └── add_nodes_state.dart      # NO CHANGE: Already architecture-compliant
└── services/                      # CREATE directory
    └── add_nodes_service.dart     # CREATE: New service file

test/page/nodes/
├── providers/
│   └── add_nodes_provider_test.dart  # CREATE: Provider tests
└── services/
    └── add_nodes_service_test.dart   # CREATE: Service tests

test/mocks/test_data/
└── add_nodes_test_data.dart          # CREATE: Test data builder
```

**Structure Decision**: Flutter mobile app structure following `lib/page/[feature]/` convention per constitution Article V §5.2

## Complexity Tracking

No violations requiring justification. Design follows minimal structure principles.

---

## Post-Design Constitution Check

*Re-evaluated after Phase 1 design completion.*

| Article | Requirement | Status | Verification |
|---------|-------------|--------|--------------|
| **V §5.3** | Three-layer architecture | ✅ COMPLIANT | Service handles JNAP, Provider delegates |
| **V §5.3.2** | Provider no JNAP models | ✅ COMPLIANT | Imports removed per quickstart |
| **VI §6.1** | Service layer mandate | ✅ COMPLIANT | AddNodesService created |
| **VI §6.2** | Service stateless | ✅ COMPLIANT | Only holds RouterRepository |
| **VI §6.3** | File organization | ✅ COMPLIANT | `lib/page/nodes/services/` |
| **XIII §13.1** | Error mapping | ✅ COMPLIANT | JNAPError → ServiceError in contract |
| **XIII §13.4** | Provider ServiceError only | ✅ COMPLIANT | No JNAPError handling in Provider |
| **I §1.4** | Test coverage targets | ✅ PLANNED | Tests defined in quickstart |
| **III** | Naming conventions | ✅ COMPLIANT | All names follow patterns |
| **IX §9.2** | Contract as .md | ✅ COMPLIANT | `contracts/add_nodes_service_contract.md` |

**Final Gate Status**: ✅ PASS - Ready for task generation

---

## Generated Artifacts

| Artifact | Path | Purpose |
|----------|------|---------|
| Implementation Plan | `specs/001-add-nodes-service/plan.md` | This file |
| Research | `specs/001-add-nodes-service/research.md` | Design decisions |
| Data Model | `specs/001-add-nodes-service/data-model.md` | Entity definitions |
| Service Contract | `specs/001-add-nodes-service/contracts/add_nodes_service_contract.md` | API specification |
| Quickstart Guide | `specs/001-add-nodes-service/quickstart.md` | Implementation steps |

---

## Next Steps

Run `/speckit.tasks` to generate the task breakdown for implementation.
