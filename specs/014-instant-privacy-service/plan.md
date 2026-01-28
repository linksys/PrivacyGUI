# Implementation Plan: Extract InstantPrivacyService

**Branch**: `001-instant-privacy-service` | **Date**: 2026-01-02 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-instant-privacy-service/spec.md`

## Summary

Extract JNAP communication from `InstantPrivacyNotifier` into a new `InstantPrivacyService` class to enforce three-layer architecture compliance per constitution.md Articles V, VI, and XIII. The service will handle all MAC filter JNAP operations (`getMACFilterSettings`, `getSTABSSIDs`, `setMACFilterSettings`, `getLocalDevice`) and convert JNAPErrors to ServiceErrors.

## Technical Context

**Language/Version**: Dart 3.0+, Flutter 3.3+
**Primary Dependencies**: flutter_riverpod, RouterRepository, ServiceError
**Storage**: N/A (existing SharedPreferences used by Provider for blink state - unaffected)
**Testing**: flutter_test, mocktail
**Target Platform**: iOS, Android, Web (Flutter multi-platform)
**Project Type**: Mobile app - Flutter feature module
**Performance Goals**: No regression from current implementation
**Constraints**: Must preserve existing PreservableNotifierMixin behavior
**Scale/Scope**: Single feature refactoring (InstantPrivacy / MAC Filtering)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Article | Gate | Status |
|---------|------|--------|
| **Article I** | Unit tests required for Service (≥90%) and Provider (≥85%) | ✅ PLANNED |
| **Article III** | Naming conventions: `InstantPrivacyService`, `instantPrivacyServiceProvider` | ✅ COMPLIANT |
| **Article V** | Three-layer architecture: Service handles JNAP, Provider delegates | ✅ TARGET |
| **Article VI** | Service layer mandate: Stateless, RouterRepository injection | ✅ PLANNED |
| **Article VIII** | Test organization: `test/page/instant_privacy/services/` | ✅ PLANNED |
| **Article XIII** | Error handling: JNAPError → ServiceError mapping in Service | ✅ PLANNED |

**Gate Status**: ✅ All gates pass - proceeding to Phase 0

## Project Structure

### Documentation (this feature)

```text
specs/001-instant-privacy-service/
├── spec.md              # Feature specification (complete)
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (API contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/page/instant_privacy/
├── providers/
│   ├── instant_privacy_provider.dart  # MODIFY: Remove JNAP imports, delegate to service
│   └── instant_privacy_state.dart     # KEEP: No changes needed
├── services/                          # CREATE
│   └── instant_privacy_service.dart   # NEW: Service with JNAP communication
└── views/                             # KEEP: No changes needed

test/page/instant_privacy/
├── providers/
│   └── instant_privacy_provider_test.dart  # UPDATE: Mock service instead of repository
├── services/                               # CREATE
│   └── instant_privacy_service_test.dart   # NEW: Service unit tests
└── [existing tests]

test/mocks/test_data/
└── instant_privacy_test_data.dart     # NEW: JNAP response builders
```

**Structure Decision**: Flutter feature module structure following constitution.md Article V Section 5.2. Service added to existing feature directory.

## Complexity Tracking

> No violations requiring justification. This refactoring follows standard patterns.

| Aspect | Evaluation |
|--------|------------|
| New Service class | Legitimate abstraction per Article VI |
| Error mapping | Required by Article XIII |
| Test data builder | Standard pattern per Article I Section 1.6.2 |
