# Implementation Plan: NodeLightSettings Service Extraction

**Branch**: `002-node-light-settings-service` | **Date**: 2026-01-02 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-node-light-settings-service/spec.md`

## Summary

Extract `NodeLightSettingsService` from `NodeLightSettingsNotifier` to enforce three-layer architecture compliance. The service will handle all JNAP communication for LED night mode settings (`getLedNightModeSetting`, `setLedNightModeSetting`), mapping errors to `ServiceError` types. The provider will delegate to the service while retaining the `currentStatus` getter as UI transformation logic.

## Technical Context

**Language/Version**: Dart 3.0+, Flutter 3.3+
**Primary Dependencies**: flutter_riverpod, equatable
**Storage**: N/A (settings stored on router via JNAP)
**Testing**: flutter test (unit tests with mockito)
**Target Platform**: iOS 15+, Android, Web
**Project Type**: mobile
**Performance Goals**: N/A (refactoring only, no functional changes)
**Constraints**: No user-facing behavior changes
**Scale/Scope**: 2 files to create, 1 file to refactor, ~200 lines total

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Rule | Status | Notes |
|------|--------|-------|
| Article V: Three-Layer Architecture | ✅ Pass | Service extraction enforces this |
| Article VI: Layer Communication | ✅ Pass | Provider → Service → Repository |
| Article XIII: Testing Strategy | ✅ Pass | Service and Provider tests planned |

## Project Structure

### Documentation (this feature)

```text
specs/002-node-light-settings-service/
├── plan.md              # This file
├── research.md          # Phase 0 output (complete)
├── data-model.md        # Phase 1 output (complete)
├── quickstart.md        # Phase 1 output (complete)
├── contracts/           # Phase 1 output (complete)
│   └── node_light_settings_service_contract.md
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── jnap/
│   │   ├── services/
│   │   │   └── node_light_settings_service.dart  # NEW: Service class
│   │   ├── providers/
│   │   │   └── node_light_settings_provider.dart # MODIFY: Remove JNAP imports
│   │   └── models/
│   │       └── node_light_settings.dart          # UNCHANGED
│   └── errors/
│       └── service_error.dart                    # UNCHANGED (existing errors)
└── page/
    └── nodes/
        └── providers/
            └── node_detail_state.dart            # UNCHANGED (NodeLightStatus enum)

test/
├── core/
│   └── jnap/
│       ├── models/
│       │   └── node_light_settings_test.dart          # NEW: Model tests
│       ├── services/
│       │   └── node_light_settings_service_test.dart  # NEW: Service tests
│       └── providers/
│           └── node_light_settings_provider_test.dart # NEW/UPDATE: Provider tests
```

**Structure Decision**: Standard Flutter mobile project structure. Service placed in existing `lib/core/jnap/services/` directory alongside `device_manager_service.dart` and others.

## Complexity Tracking

> No constitution violations. This is a straightforward service extraction following established patterns.

| Aspect | Complexity | Justification |
|--------|------------|---------------|
| Files Changed | Low | 1 new service, 1 refactored provider, 3 test files |
| Risk | Low | No functional changes, pattern established |
| Testing | Medium | New service tests + provider delegation tests |
