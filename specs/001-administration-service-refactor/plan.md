# Implementation Plan: AdministrationSettingsService Extraction Refactor

**Branch**: `001-administration-service-refactor` | **Date**: 2025-12-05 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-administration-service-refactor/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Extract JNAP action orchestration and data model transformation logic from `AdministrationSettingsNotifier` into a new `AdministrationSettingsService`. This improves maintainability by separating presentation state management from data-fetching concerns, enabling independent testing and reusability. The service will handle four JNAP transactions (getManagementSettings, getUPnPSettings, getALGSettings, getExpressForwardingSettings) and return properly parsed domain models or failure indicators.

## Technical Context

**Language/Version**: Dart >=3.0.0, Flutter >=3.3.0
**Primary Dependencies**: flutter_riverpod (2.6.1), JNAP protocol library (local communication)
**Storage**: N/A (data-fetching only, no persistence in service)
**Testing**: flutter test + mocktail (mocking framework)
**Target Platform**: Flutter app (iOS, Android, web)
**Project Type**: Single mobile/web app with Riverpod state management
**Performance Goals**: Service unit tests <100ms per test; JNAP transactions <200ms typical on local network
**Constraints**: Must maintain backward compatibility; existing UI tests must pass; follow Clean Architecture 3-layer pattern
**Scale/Scope**: Single feature refactor affecting ~150 lines in Notifier; 1 new service file; ~6 related model files involved

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Architecture Layer Compliance
- ✅ **Clean Architecture 3-Layer**: Service layer (Data) will be separate from Notifier (Application) and UI (Presentation)
- ✅ **One-way Dependency**: Notifier → Service → RouterRepository (downward only, no circular deps)
- ✅ **Adapter Pattern**: RouterRepository is already injected, Service will also use injection

### Data Model Requirements
- ✅ **Equatable**: All models (ManagementSettings, UPnPSettings, ALGSettings, ExpressForwardingSettings) are already Equatable
- ✅ **toJson/fromJson**: All models already have serialization methods
- ✅ **Code Generation**: No new code generation needed (leveraging existing models)

### Testing Requirements
- ✅ **Coverage Target**: Service layer must achieve ≥90% coverage (isolated from Notifier)
- ✅ **Mocking Strategy**: Mock RouterRepository in service tests (external dependency)
- ✅ **Speed**: Service unit tests should execute <100ms per test

### DartDoc & Public APIs
- ✅ **Documentation**: All public methods in service will have DartDoc comments
- ✅ **No Hardcoded Strings**: Service layer contains no UI strings

### State Management Pattern
- ✅ **PreservableNotifierMixin**: Remains unchanged in Notifier, external behavior preserved
- ✅ **Result Pattern**: Service will follow existing error handling (JNAPResult pattern)

**GATE STATUS**: ✅ PASS - No violations. Refactor aligns with all constitution principles.

## Project Structure

### Documentation (this feature)

```text
specs/001-administration-service-refactor/
├── plan.md              # This file (implementation design)
├── research.md          # Phase 0 output (clarifications & patterns)
├── data-model.md        # Phase 1 output (service data contract)
├── quickstart.md        # Phase 1 output (integration guide)
├── contracts/           # Phase 1 output (service interface)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (Flutter app)

```text
lib/page/advanced_settings/administration/
├── providers/
│   ├── administration_settings_provider.dart  # Notifier (REFACTORED: delegates to service)
│   └── administration_settings_state.dart     # State model (unchanged)
├── views/
│   └── administration_settings_view.dart      # UI (unchanged)

lib/page/advanced_settings/administration/services/  # NEW
└── administration_settings_service.dart       # Service (extraction target)

lib/core/jnap/
├── models/
│   ├── management_settings.dart              # (unchanged)
│   ├── unpn_settings.dart                    # (unchanged)
│   ├── alg_settings.dart                     # (unchanged)
│   └── express_forwarding_settings.dart      # (unchanged)
└── router_repository.dart                    # (unchanged)

test/page/advanced_settings/administration/
├── providers/
│   └── administration_settings_provider_test.dart  # Existing (will be updated to mock service)
└── services/  # NEW
    └── administration_settings_service_test.dart  # New unit tests for service
```

**Structure Decision**: Single service file extraction. No changes to model locations or UI structure. Tests remain co-located with source under `test/page/` mirror. RouterRepository is injected via Riverpod provider pattern.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**Status**: ✅ No violations to justify. Refactor follows all constitution principles without exceptions.

---

## Phase 1 Design Artifacts

All Phase 1 outputs are complete:

- ✅ **research.md**: All clarifications resolved, no unknowns remain
- ✅ **data-model.md**: Service interface and data structures fully specified
- ✅ **quickstart.md**: Step-by-step implementation guide with examples
- ✅ **plan.md**: This file (architecture and design decisions)

---

## Ready for Phase 2: Task Generation

Run `/speckit.tasks` to generate actionable task list from this plan and design artifacts.
