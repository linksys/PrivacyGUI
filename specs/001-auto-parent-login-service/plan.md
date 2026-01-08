# Implementation Plan: AutoParentFirstLogin Service Extraction

**Branch**: `001-auto-parent-login-service` | **Date**: 2026-01-07 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-auto-parent-login-service/spec.md`

## Summary

Extract JNAP communication logic from `AutoParentFirstLoginNotifier` into a dedicated `AutoParentFirstLoginService` class to enforce three-layer architecture compliance per constitution.md Article V, VI, XIII. The Service will handle `setUserAcknowledgedAutoConfiguration`, `setFirmwareUpdatePolicy`, and `checkInternetConnection` operations, while the Notifier retains orchestration and state management responsibilities.

## Technical Context

**Language/Version**: Dart 3.0+, Flutter 3.3+
**Primary Dependencies**: flutter_riverpod, RouterRepository (core/jnap)
**Storage**: N/A (no persistent storage in this feature)
**Testing**: flutter_test + mocktail
**Target Platform**: iOS, Android, Web
**Project Type**: Mobile (Flutter)
**Performance Goals**: N/A (refactoring, no new performance requirements)
**Constraints**: Retry strategy (5 attempts, 2s delay); **all JNAP operations must be awaited**
**Scale/Scope**: Single Provider → Service extraction

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Article | Requirement | Status | Notes |
|---------|-------------|--------|-------|
| **Article I** | Test coverage: Service ≥90%, Provider ≥85% | ⬜ Pending | Will be enforced during implementation |
| **Article III** | Naming: `AutoParentFirstLoginService`, `autoParentFirstLoginServiceProvider` | ✅ Pass | Follows Section 3.2, 3.3.1, 3.4.1 |
| **Article V** | Three-layer architecture compliance | ⬜ Target | Current Provider violates; Service extraction fixes this |
| **Article VI** | Service handles JNAP, returns UI models, stateless | ✅ Aligned | Service design follows Section 6.2 |
| **Article XIII** | Service converts JNAPError → ServiceError | ✅ Aligned | Will use `mapJnapErrorToServiceError()` |

**Gate Result**: ✅ PASS - No violations; refactoring is designed to achieve compliance.

## Project Structure

### Documentation (this feature)

```text
specs/001-auto-parent-login-service/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── auto_parent_first_login_service_contract.md
└── tasks.md             # Phase 2 output (via /speckit.tasks)
```

### Source Code (repository root)

```text
lib/page/login/auto_parent/
├── providers/
│   ├── auto_parent_first_login_provider.dart  # Refactored (remove JNAP imports)
│   └── auto_parent_first_login_state.dart     # Unchanged
└── services/                                   # NEW directory
    └── auto_parent_first_login_service.dart   # NEW service file

test/page/login/auto_parent/
├── providers/
│   ├── auto_parent_first_login_provider_test.dart  # NEW or updated
│   └── auto_parent_first_login_state_test.dart     # NEW (required)
└── services/                                        # NEW directory
    └── auto_parent_first_login_service_test.dart   # NEW test file

test/mocks/test_data/
└── auto_parent_first_login_test_data.dart  # NEW test data builder
```

**Structure Decision**: Flutter mobile single-project structure following existing `lib/page/[feature]/` pattern. Service layer added per constitution.md Article V Section 5.2.

## Complexity Tracking

> No violations to justify - this is a simplification refactoring.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |
