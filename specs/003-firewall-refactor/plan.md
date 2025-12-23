# Implementation Plan: Firewall Settings Refactor

**Branch**: `003-firewall-refactor` | **Date**: 2025-12-09 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/003-firewall-refactor/spec.md`

**Note**: This plan follows the architectural pattern established by DMZ refactor (002) and Administration refactor (001), implementing the data model layering rules from Constitution v2.3.

## Summary

Refactor Firewall settings feature to enforce strict data model layering per Constitution v2.3:

**Primary Requirement**: Extract all JNAP protocol logic from Provider layer into a dedicated FirewallSettingsService, create UI-specific models (FirewallUISettings, IPv6PortServiceRuleUI) to isolate Presentation layer from Data layer, and implement comprehensive three-layer testing (Service ≥90%, Provider ≥85%, State ≥90%).

**Technical Approach**:
1. Create FirewallSettingsService as Application layer bridge between Data (JNAP) and Presentation (UI)
2. Introduce UI model wrappers for all Data models used in Presentation layer
3. Refactor Provider to delegate all data operations to Service
4. Implement full three-layer testing with focus on model transformation validation
5. Verify strict model boundaries: no JNAP models in Provider/UI files

## Technical Context

**Language/Version**: Dart >=3.0.0, Flutter >=3.3.0

**Primary Dependencies**:
- flutter_riverpod 2.6.1 (state management)
- mocktail (testing framework)
- JNAP protocol library (local device communication)

**Testing**: Flutter test framework with mocktail for mocking

**Target Platform**: Flutter (iOS, Android, web)

**Project Type**: Mobile/web application (flutter_riverpod based)

**Performance Goals**: No performance optimization needed - refactoring maintains existing behavior

**Constraints**:
- Must maintain backward compatibility with existing UI
- Must preserve PreservableNotifierMixin undo/reset functionality
- Strict architectural constraint: one-way dependency flow only

**Scale/Scope**:
- Feature: Firewall settings management
- Scope: 2 main providers (FirewallNotifier, IPv6PortServiceRuleNotifier)
- Models affected: ~5 major data models (FirewallSettings, IPv6PortServiceRule, etc.)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Architectural Requirements (Constitution v2.3)

- [x] **Three-layer separation verified**:
  - Data (JNAP models in `lib/core/jnap/models/`)
  - Application (Services, UI models in `lib/page/advanced_settings/firewall/`)
  - Presentation (Views in `lib/page/advanced_settings/firewall/views/`)

- [x] **Data model layering (NEW in v2.3)**:
  - ✅ Firewall Data Models (FirewallSettings) will be in Data layer only
  - ✅ Firewall UI Models (FirewallUISettings) will be in Application layer
  - ✅ No JNAP models in Provider or View files
  - ✅ Service layer responsible for all Data ↔ UI transformations

- [x] **One-way dependency flow**:
  - View → Provider → Service → Repository → JNAP
  - No reverse dependencies allowed
  - No circular dependencies

- [x] **Testing coverage requirements**:
  - Service layer: ≥90% (CRITICAL for transformation logic)
  - Provider layer: ≥85% (delegation + state management)
  - State models: ≥90% (especially serialization)

- [x] **Code quality gates**:
  - `flutter analyze` must show 0 warnings on firewall files
  - All public APIs require DartDoc
  - No hardcoded strings (use localization)

**GATE STATUS**: ✅ PASS - All constitutional requirements can be met

---

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

Flutter mobile application structure for firewall refactor:

```text
lib/page/advanced_settings/firewall/
├── services/
│   ├── firewall_settings_service.dart           # NEW: Service layer (Data → UI transformation)
│   └── firewall_settings_service_test_data.dart # NEW: Mock data builders for tests
│
├── providers/
│   ├── firewall_provider.dart                   # REFACTOR: Provider (remove JNAP logic, delegate to Service)
│   ├── firewall_state.dart                      # REFACTOR: Add UI models (FirewallUISettings)
│   ├── firewall_status.dart                     # UNCHANGED
│   ├── ipv6_port_service_rule_provider.dart     # REFACTOR: Same as firewall_provider
│   ├── ipv6_port_service_rule_state.dart        # REFACTOR: Add UI model (IPv6PortServiceRuleUI)
│   ├── ipv6_port_service_list_provider.dart     # REFACTOR: Same as firewall_provider
│   └── ipv6_port_service_list_state.dart        # UNCHANGED
│
└── views/
    ├── firewall_view.dart                        # VERIFY: No JNAP imports, use only UI models
    ├── ipv6_port_service_rule_view.dart         # VERIFY: No JNAP imports, use only UI models
    └── ipv6_port_service_list_view.dart         # VERIFY: No JNAP imports, use only UI models

test/page/advanced_settings/firewall/
├── services/
│   ├── firewall_settings_service_test.dart      # NEW: Service layer tests (≥90% coverage)
│   └── firewall_settings_service_test_data.dart # NEW: Shared mock data
│
├── providers/
│   ├── firewall_provider_test.dart              # NEW: Provider delegation tests
│   ├── firewall_state_test.dart                 # NEW: State model tests (including serialization)
│   ├── ipv6_port_service_rule_provider_test.dart    # NEW
│   ├── ipv6_port_service_rule_state_test.dart      # NEW
│   ├── ipv6_port_service_list_provider_test.dart    # NEW
│   └── ipv6_port_service_list_state_test.dart      # NEW (if needed)
│
└── views/
    └── [existing view tests]                    # VERIFY: Use only UI models
```

**Structure Decision**: Flutter feature-based mobile app. All changes in `lib/page/advanced_settings/firewall/` feature folder plus corresponding test folder. No changes to other parts of the codebase. Follows established PrivacyGUI architecture patterns.

## Complexity Tracking

> **No Constitution Check violations. All requirements are met straightforwardly.**

This refactoring has no complexity trade-offs - it follows established patterns from DMZ and Administration refactors.
