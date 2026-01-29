# Implementation Plan: Static Routing Module Refactor

**Branch**: `004-static-routing-refactor` | **Date**: 2025-12-12 | **Spec**: [../spec.md](../spec.md)
**Input**: Feature specification from `/specs/004-static-routing-refactor/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Refactor the Static Routing module (`lib/page/advanced_settings/static_routing`) to comply with the project constitution by implementing a three-layer architecture. Extract business logic from Providers into a dedicated Service layer, create UI models to isolate Presentation from JNAP data models, and add comprehensive unit tests. This refactor maintains backward compatibility with the existing UI while dramatically improving testability and adherence to clean architecture principles.

## Technical Context

**Language/Version**: Dart ≥3.0.0, Flutter ≥3.3.0
**Primary Dependencies**: flutter_riverpod 2.6.1, mocktail (testing), JNAP protocol library (local communication)
**Storage**: N/A (device-side storage via JNAP)
**Testing**: flutter test, mocktail for mocking, coverage measurement via `flutter test --coverage`
**Target Platform**: iOS, Android, Web (cross-platform Flutter)
**Project Type**: Mobile + Web (monorepo Flutter app with multiple feature modules)
**Performance Goals**: Route list typical <50 entries, UI responsiveness <200ms for navigation, JNAP communication <500ms
**Constraints**: Must maintain backward compatibility with existing UI, offline-capable (routes cached until unsync), no new external dependencies
**Scale/Scope**: Single feature module refactor (~3-4 files refactored, +5-6 new files created, <2000 LOC change)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Architectural Compliance (Article V - Three-Layer Architecture)

| Gate | Requirement | Status | Notes |
|------|-------------|--------|-------|
| **Three-Layer Separation** | Presentation → Application → Data layers with one-way dependencies | ✅ PASS | Service layer will enforce separation; Views stay independent |
| **JNAP Model Isolation** | JNAP models (GetRoutingSettings, SetRoutingSettings) only in Service layer, never in Provider/View | ✅ PASS | All JNAP imports will be moved to Service layer per spec FR-005 |
| **UI Model Creation** | Presentation layer uses UI models (StaticRoutingUISettings, StaticRouteEntryUI), not JNAP models | ✅ PASS | UI models defined per spec, Service transforms between layers |
| **Service Layer** | Dedicated Service class for business logic and JNAP orchestration | ✅ PASS | StaticRoutingService will be created per spec FR-002 |

### Testing Requirements (Article I & VIII)

| Gate | Requirement | Status | Notes |
|------|-------------|--------|-------|
| **Unit Tests** | Service layer ≥90%, Provider ≥85%, Overall ≥80% coverage | ✅ PASS | Test suite will be built per spec FR-018 through FR-021 |
| **Mocking** | All JNAP communication mocked using Mocktail | ✅ PASS | RouterRepository mocked for all Service/Provider tests |
| **Test Organization** | Service tests in `test/page/advanced_settings/static_routing/services/`, Provider tests in `providers/` | ✅ PASS | Directory structure defined in spec |
| **Test Data Builders** | StaticRoutingTestData following constitution pattern | ✅ PASS | Builders for JNAP responses defined per Article I Section 1.6.2 |

### Code Quality (Article III & X)

| Gate | Requirement | Status | Notes |
|------|-------------|--------|-------|
| **Naming Conventions** | Service: `StaticRoutingService`, Notifier: `StaticRoutingNotifier`, State: `StaticRoutingState` | ✅ PASS | Names follow Article III conventions |
| **DartDoc** | All public methods documented | ✅ PASS | Required per spec SC-005 and Article X |
| **Lint Warnings** | `flutter analyze` passes with zero new warnings | ✅ PASS | Required per spec SC-006 |
| **No Over-Engineering** | Simple refactor, no new abstractions beyond Service layer | ✅ PASS | Limited to architecture compliance only |

### Result: ✅ **GATE PASSED** - All constitutional requirements met

**No violations requiring justification. Refactor is straightforward application of architecture principles.**

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

```text
lib/page/advanced_settings/static_routing/
├── providers/
│   ├── _providers.dart              # Barrel export (UNCHANGED)
│   ├── static_routing_provider.dart  # Notifier + provider (REFACTORED)
│   ├── static_routing_state.dart     # State + UI models (ENHANCED with UI models)
│   ├── static_routing_rule_provider.dart  # Rule notifier (UNCHANGED)
│   └── static_routing_rule_state.dart     # Rule state (UNCHANGED)
├── services/                          # NEW directory
│   └── static_routing_service.dart    # Service layer (NEW - extracted from provider)
├── static_routing_view.dart           # Main view (UNCHANGED - Views stay simple)
├── static_routing_list_view.dart      # List view (UNCHANGED)
└── static_routing_rule_view.dart      # Rule editing view (UNCHANGED)

test/page/advanced_settings/static_routing/
├── services/                          # NEW
│   ├── static_routing_service_test.dart      # NEW - Service unit tests
│   └── static_routing_service_test_data.dart # NEW - Test data builder
├── providers/                         # NEW (or ENHANCED if exists)
│   ├── static_routing_provider_test.dart     # NEW - Provider state tests
│   ├── static_routing_state_test.dart        # NEW - State model tests
│   └── static_routing_rule_provider_test.dart # NEW - Rule provider tests
└── views/localizations/               # Screenshot tests location (if needed)
    └── static_routing_view_test.dart  # Screenshot/localization test (if new UI)
```

**Structure Decision**: Flutter monorepo with feature modules. Static Routing is a single feature module within `advanced_settings`. Refactoring adds a dedicated Service layer (`services/` directory) with comprehensive unit tests. Views layer remains unchanged for backward compatibility.

## Complexity Tracking

✅ **No violations requiring justification** - Constitution Check passed all gates.

---

## Phase 0: Outline & Research

### Research Tasks

All technical context is clearly defined - **no NEEDS CLARIFICATION markers exist**. Research is minimal:

1. **Reference Implementation Study** (5 min)
   - Review existing service layer implementations: `lib/page/advanced_settings/dmz/services/dmz_settings_service.dart`
   - Document Service layer pattern with transformation logic
   - Verify UI model pattern already used in firewall module

2. **Test Pattern Documentation** (5 min)
   - Confirm Test Data Builder pattern from DMZ module
   - Document Mocktail usage in existing tests
   - Identify test coverage tools and execution patterns

3. **JNAP Protocol Analysis** (10 min)
   - Review current GetRoutingSettings and SetRoutingSettings models
   - Document JNAP transformation patterns (input ↔ UI models)
   - Identify validation rules for static route entries

**Expected Output**: `research.md` - Implementation approach validated against existing patterns

---

## Phase 1: Design & Contracts

### Data Model Design

**Entity: StaticRoutingUISettings** (UI Model)
- `isDMZEnabled: bool` - NAT enabled flag
- `isDynamicRoutingEnabled: bool` - Dynamic routing flag
- `entries: List<StaticRouteEntryUI>` - Routes list

**Entity: StaticRouteEntryUI** (UI Model)
- `name: String` - Route description (max 32 chars)
- `destinationIP: String` - Target network (IPv4)
- `subnetMask: String` - Network mask (IPv4)
- `gateway: String` - Gateway address (IPv4)

**Entity: StaticRoutingStatus** (Status)
- `maxStaticRouteEntries: int` - Device limit
- `routerIP: String` - Router IP for display
- `subnetMask: String` - Router subnet for display

**Entity: GetRoutingSettings** (JNAP Data Model - Data Layer Only)
- Maps JNAP response to domain model
- Contains entries array from device
- **Visibility**: Service layer only

**Entity: SetRoutingSettings** (JNAP Data Model - Data Layer Only)
- Transforms UI settings back to JNAP protocol
- **Visibility**: Service layer only

### API Contracts

```dart
// Service Layer Contract

class StaticRoutingService {
  /// Fetch routing configuration from device
  Future<(StaticRoutingUISettings?, StaticRoutingStatus?)> fetchRoutingSettings(
    Ref ref, {
    bool forceRemote = false,
  })

  /// Save routing configuration to device
  Future<void> saveRoutingSettings(
    Ref ref,
    StaticRoutingUISettings settings,
  )
}

// Provider Layer Contract

class StaticRoutingNotifier extends Notifier<StaticRoutingState>
    with PreservableNotifierMixin<StaticRoutingUISettings, StaticRoutingStatus, StaticRoutingState> {

  Future<(StaticRoutingUISettings?, StaticRoutingStatus?)> performFetch(...)
  Future<void> performSave()
  void updateSettingNetwork(RoutingSettingNetwork option)
  void addRoute(StaticRouteEntryUI route)
  void editRoute(int index, StaticRouteEntryUI route)
  void deleteRoute(int index)
}
```

### Test Contracts

**Service Layer Tests** (StaticRoutingServiceTest):
- fetchRoutingSettings: Valid response transformation
- fetchRoutingSettings: LAN settings context extraction
- fetchRoutingSettings: Error handling (malformed response, network error)
- saveRoutingSettings: Successful save
- saveRoutingSettings: Validation failure
- saveRoutingSettings: Device rejection

**Provider Layer Tests** (StaticRoutingProviderTest):
- Initial state: Default values (NAT disabled, Dynamic disabled, empty routes)
- performFetch: State updates from service
- performSave: Routes persisted
- addRoute: Respects max limit
- editRoute: Route updated at index
- deleteRoute: Route removed from list
- Dirty guard: original vs current tracking

**State Model Tests** (StaticRoutingStateTest):
- Model serialization (toMap/fromMap)
- Model equality (Equatable)
- copyWith: Creates new instance with overrides

### Agent Context Update

Run context update to register new Dart/Flutter technologies:
```bash
.specify/scripts/bash/update-agent-context.sh claude
```

This adds:
- Service layer implementation pattern
- UI model transformation pattern
- Test data builder pattern
- Riverpod mocking patterns

**Expected Outputs**:
- `data-model.md` - Entity definitions and relationships
- `contracts/service-contract.md` - Service interface specification
- `contracts/provider-contract.md` - Provider state interface
- `contracts/test-contract.md` - Test coverage expectations
- `quickstart.md` - Implementation getting started guide
- Updated agent context file

## Phase 2: Implementation Planning

### Implementation Strategy

**Incremental Refactoring Approach** (Minimize breaking changes):

#### Step 1: Create Service Layer (Isolate JNAP)
- Create `lib/page/advanced_settings/static_routing/services/static_routing_service.dart`
- Extract JNAP communication from `performFetch()` and `performSave()`
- Implement model transformation (JNAP ↔ UI models)
- **Dependency**: RouterRepository (via Ref parameter)

#### Step 2: Define UI Models (Presentation Isolation)
- Add to `static_routing_state.dart`: `StaticRoutingUISettings`, `StaticRouteEntryUI`
- All models implement `Equatable`, `copyWith()`, `toMap()/fromMap()`
- Ensure Provider never imports JNAP models directly

#### Step 3: Refactor Provider (Update Dependencies)
- Update `StaticRoutingNotifier.performFetch()` to call Service
- Update `StaticRoutingNotifier.performSave()` to call Service
- Remove JNAP model imports (except indirectly through Service)
- Keep existing public methods for UI compatibility

#### Step 4: Add Comprehensive Tests
- Service layer tests with mocked RouterRepository
- Provider state management tests
- State model serialization tests
- Test data builders for JNAP responses

#### Step 5: Verify Compliance
- Run `flutter analyze` - 0 violations
- Run `flutter test --coverage` - Meet target coverage
- Grep verification: No JNAP imports in Provider/View layers
- UI functionality regression test

### Critical Success Factors

1. **Backward Compatibility**: View layer sees no changes - no UI rework needed
2. **Test Coverage**: Achieve ≥80% overall with Service ≥90%, Provider ≥85%
3. **Zero Lint**: No new warnings introduced by refactoring
4. **Architecture Compliance**: All constitutional requirements met
5. **Code Review Readiness**: All public APIs documented with DartDoc

### Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|-----------|
| Breaking UI during refactor | Low | High | Keep Views layer changes minimal, comprehensive UI tests |
| Test coverage shortfall | Low | Medium | Use existing test patterns from DMZ/Firewall modules |
| JNAP import violations | Low | High | Automated grep checks in final verification |
| Performance regression | Very Low | Low | Profile JNAP calls, use local caching pattern |

---

## Next Steps

✅ **All prerequisite phases complete**:
- ✅ Specification complete and approved (spec.md)
- ✅ Constitution compliance verified (plan.md)
- ✅ No clarifications needed (research minimal)
- ✅ Design artifacts defined (data models, contracts)
- ✅ Implementation strategy documented

**Ready for**: `/speckit.tasks` - Generate actionable, dependency-ordered task list for implementation

---

## Appendix: Architecture Transformation

### Before (Current - Violates Constitution)

```
StaticRoutingNotifier (Provider Layer)
  ├── Imports: GetRoutingSettings, SetRoutingSettings (JNAP models) ❌
  ├── performFetch() 
  │   ├── Direct RouterRepository call
  │   └── Direct JNAP model transformation ❌
  └── performSave()
      ├── Direct RouterRepository call
      └── Direct JNAP model transformation ❌
```

### After (Refactored - Constitution Compliant)

```
StaticRoutingNotifier (Provider Layer) ✅
  ├── Imports: StaticRoutingUISettings, StaticRouteEntryUI (UI models only) ✅
  ├── performFetch() 
  │   ├── Calls: StaticRoutingService.fetchRoutingSettings() ✅
  │   └── Works with: UI models ✅
  └── performSave()
      ├── Calls: StaticRoutingService.saveRoutingSettings() ✅
      └── Works with: UI models ✅

StaticRoutingService (Service Layer) ✅
  ├── Imports: GetRoutingSettings, SetRoutingSettings (JNAP models allowed here)
  ├── fetchRoutingSettings()
  │   ├── RouterRepository communication
  │   ├── JNAP response parsing
  │   └── Transformation: JNAP → UI models ✅
  └── saveRoutingSettings()
      ├── RouterRepository communication
      ├── Transformation: UI models → JNAP
      └── Device communication ✅
```

**Key Improvement**: JNAP coupling isolated to Service layer, Provider/View layers use UI models, complete testability via mocking.
