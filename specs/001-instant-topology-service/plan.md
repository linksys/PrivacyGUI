# Implementation Plan: InstantTopology Service Extraction

**Branch**: `001-instant-topology-service` | **Date**: 2026-01-02 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-instant-topology-service/spec.md`

## Summary

Extract JNAP communication logic from `InstantTopologyNotifier` into a new `InstantTopologyService` class to comply with three-layer architecture (Article V, VI, XIII). The service will handle node reboot, factory reset, and LED blink operations, converting all JNAP errors to ServiceError types.

## Technical Context

**Language/Version**: Dart 3.0+, Flutter 3.3+
**Primary Dependencies**: flutter_riverpod, shared_preferences
**Storage**: SharedPreferences (for blink node tracking)
**Testing**: flutter_test, mocktail
**Target Platform**: iOS, Android, Web
**Project Type**: Mobile/Web Flutter application
**Performance Goals**: Timeout: 60 seconds for node offline wait (20 retries × 3s)
**Constraints**: Must preserve existing behavior; no UI changes required
**Scale/Scope**: Single feature refactor affecting 2 files + 3 new ServiceError types

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Article | Requirement | Status | Notes |
|---------|-------------|--------|-------|
| **I - Test Requirement** | Service ≥90%, Provider ≥85% coverage | ✅ WILL COMPLY | Tests required for new Service and updated Provider |
| **III - Naming** | snake_case files, UpperCamelCase classes | ✅ WILL COMPLY | `instant_topology_service.dart`, `InstantTopologyService` |
| **V - Three-Layer Architecture** | Provider → Service → Data | ✅ TARGET | This is the goal of the refactor |
| **VI - Service Layer** | Services handle JNAP, return UI models | ✅ WILL COMPLY | Service encapsulates all JNAP calls |
| **VII - Anti-Abstraction** | No framework wrappers | ✅ COMPLIANT | Service is legitimate abstraction |
| **XIII - Error Handling** | ServiceError contract | ✅ WILL COMPLY | New error types extend ServiceError |

**Pre-Design Gate**: ✅ PASS - No violations, refactor aligns with constitution goals.

## Project Structure

### Documentation (this feature)

```text
specs/001-instant-topology-service/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── instant_topology_service_contract.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
lib/
├── core/
│   └── errors/
│       └── service_error.dart          # Add 3 new error types
├── page/
│   └── instant_topology/
│       ├── providers/
│       │   └── instant_topology_provider.dart  # MODIFY: delegate to service
│       └── services/                           # NEW directory
│           └── instant_topology_service.dart   # NEW service file

test/
├── mocks/
│   └── test_data/
│       └── instant_topology_test_data.dart     # NEW test data builder
└── page/
    └── instant_topology/
        ├── providers/
        │   └── instant_topology_provider_test.dart  # NEW/UPDATE provider tests
        └── services/
            └── instant_topology_service_test.dart   # NEW service tests
```

**Structure Decision**: Flutter mobile app structure per constitution Article V Section 5.2. Service goes in `lib/page/instant_topology/services/` following existing patterns.

## Complexity Tracking

No complexity violations. This refactor reduces complexity by:
- Separating JNAP communication from state management
- Adding testable service layer
- Following established patterns (reference: `RouterPasswordService`)

---

## Post-Design Constitution Re-Check

| Article | Requirement | Status | Verification |
|---------|-------------|--------|--------------|
| **I - Test Requirement** | Service ≥90%, Provider ≥85% | ✅ PLANNED | Test files specified in structure |
| **III - Naming** | snake_case files, UpperCamelCase classes | ✅ COMPLIANT | `instant_topology_service.dart`, `InstantTopologyService` |
| **V - Three-Layer Architecture** | Provider → Service → Data | ✅ DESIGNED | Contract shows clear layer separation |
| **VI - Service Layer** | Services handle JNAP | ✅ DESIGNED | 5 JNAP methods extracted to service |
| **IX - Documentation** | Contracts in .md format | ✅ COMPLIANT | `contracts/instant_topology_service_contract.md` |
| **XIII - Error Handling** | ServiceError contract | ✅ DESIGNED | 3 new error types defined |

**Post-Design Gate**: ✅ PASS

---

## Generated Artifacts

| Artifact | Path | Purpose |
|----------|------|---------|
| Plan | `specs/001-instant-topology-service/plan.md` | Implementation overview |
| Research | `specs/001-instant-topology-service/research.md` | Technical decisions |
| Data Model | `specs/001-instant-topology-service/data-model.md` | Entity definitions |
| Contract | `specs/001-instant-topology-service/contracts/instant_topology_service_contract.md` | API specification |
| Quickstart | `specs/001-instant-topology-service/quickstart.md` | Developer guide |

---

## Next Step

Run `/speckit.tasks` to generate implementation tasks.
