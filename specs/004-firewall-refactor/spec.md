# Feature Specification: Firewall Settings Refactor

**Feature Branch**: `003-firewall-refactor`
**Created**: 2025-12-09
**Status**: Draft
**Input**: User description: "根據憲章重構advanced_setting/firewall"

## Overview

Refactor the Firewall settings feature to comply with the updated project constitution (v2.3), specifically:
- Extract JNAP protocol logic from Provider into a dedicated Service layer
- Introduce UI-specific models to isolate Presentation layer from Data layer models
- Implement comprehensive three-layer testing (Service ≥90%, Provider ≥85%, State ≥90%)
- Ensure strict model layering: no JNAP Data Models in Provider/UI layers

This refactor follows the same architectural pattern established by DMZ refactor and Administration refactor.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Admin Views and Edits Firewall Rules (Priority: P1)

An administrator accesses the Firewall settings page to enable/disable firewall protections and modify port forwarding rules. The feature must abstract away JNAP protocol details from the UI layer.

**Why this priority**: Core functionality - this is the primary user interaction with firewall settings. Essential for MVP.

**Independent Test**: Can be fully tested by verifying that:
1. UI layer never imports JNAP models (only UI models)
2. Service layer correctly transforms JNAP responses to UI models
3. Provider delegates all data operations to Service layer

**Acceptance Scenarios**:

1. **Given** admin is on firewall settings page, **When** they toggle a firewall option, **Then** the UI immediately reflects the change without knowing about JNAP models
2. **Given** firewall settings are fetched from device, **When** the Service layer receives JNAP response, **Then** it correctly transforms to FirewallUISettings and Provider receives only UI models
3. **Given** admin saves changes, **When** Provider calls Service, **Then** Service transforms FirewallUISettings to FirewallSettings (JNAP model) and calls repository

---

### User Story 2 - Manage IPv6 Port Service Rules (Priority: P2)

Administrator manages IPv6 port forwarding rules with the same architectural layering. Port service rules include complex nested data structures.

**Why this priority**: Important secondary feature. Demonstrates proper handling of complex nested models through the three layers.

**Independent Test**: Can be fully tested by verifying:
1. IPv6 port service rule UI models are separate from JNAP models
2. Service layer handles nested transformation correctly
3. Provider state management for rule list operations

**Acceptance Scenarios**:

1. **Given** admin views IPv6 port service list, **When** list is fetched, **Then** all data is displayed using UI models with no JNAP imports
2. **Given** admin adds/modifies/deletes a port service rule, **When** changes are saved, **Then** Service layer transforms UI model to JNAP model before calling repository

---

### User Story 3 - Error Handling and Edge Cases (Priority: P3)

System gracefully handles errors, null values, and edge cases in firewall configuration.

**Why this priority**: Important for robustness but doesn't block core functionality.

**Independent Test**: Can be fully tested by verifying error handling paths in Service layer tests.

**Acceptance Scenarios**:

1. **Given** JNAP call fails, **When** Provider calls performFetch, **Then** error is properly propagated without corrupting state
2. **Given** firewall settings contain null/empty port lists, **When** Service transforms to UI models, **Then** nulls are handled consistently
3. **Given** invalid input data from device, **When** Service attempts to parse, **Then** error is logged and user sees appropriate message

---

### Edge Cases

- What happens when device returns unexpected JNAP response format?
- How does system handle partial firewall rule data (missing optional fields)?
- What happens when enabling IPv4 firewall but IPv6 rules already exist?
- How are empty port service lists represented in both JNAP and UI models?

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST extract all JNAP logic (JNAPAction, JNAPTransactionBuilder, FirewallSettings) from Provider layer into dedicated FirewallSettingsService
- **FR-002**: System MUST create UI-specific models (FirewallUISettings, IPv6PortServiceRuleUI) in Application layer, completely separate from Data layer models
- **FR-003**: Provider MUST depend only on FirewallSettingsService, never directly on Router Repository or JNAP components
- **FR-004**: Provider MUST only use UI models for state management (FirewallUISettings), not JNAP models (FirewallSettings)
- **FR-005**: UI layer (Views) MUST never import 'lib/core/jnap/models/' or any JNAP data models
- **FR-006**: FirewallSettingsService MUST handle complete transformation pipeline: JNAP response → Data models → UI models (fetch) and UI models → Data models → JNAP request (save)
- **FR-007**: All existing firewall functionality MUST remain unchanged from user perspective (no feature additions, only refactoring)
- **FR-008**: System MUST maintain PreservableNotifierMixin pattern for undo/reset functionality
- **FR-009**: Tests MUST use only UI models (FirewallUISettings) in View/Provider tests, never JNAP models
- **FR-010**: System MUST achieve ≥90% test coverage for Service layer, ≥85% for Provider layer, ≥90% for State models

### Key Entities

- **FirewallSettings** (Data Layer): JNAP protocol model - represents device firewall configuration exactly as received from device
  - Attributes: blockAnonymousRequests, blockIDENT, blockIPSec, blockL2TP, blockMulticast, blockNATRedirection, blockPPTP, isIPv4FirewallEnabled, isIPv6FirewallEnabled
  - Belongs in: `lib/core/jnap/models/`
  - Usage: Only in Data layer (Service, Repository)

- **FirewallUISettings** (Application Layer): UI-adapted model - adapts JNAP model for application use
  - Attributes: Same as FirewallSettings but as UI model without JNAP coupling
  - Belongs in: `lib/page/advanced_settings/firewall/providers/firewall_state.dart`
  - Usage: Application layer (Service, Provider) and Presentation layer (Views)

- **IPv6PortServiceRule** (Data Layer): JNAP protocol model for port forwarding rules
  - Attributes: Protocol, externalPort, internalPort, internalIPAddress, description, enabled
  - Belongs in: `lib/core/jnap/models/`

- **IPv6PortServiceRuleUI** (Application Layer): UI-adapted model for port rules
  - Attributes: Same structure but as UI model without JNAP coupling
  - Belongs in: `lib/page/advanced_settings/firewall/providers/ipv6_port_service_rule_state.dart`

- **FirewallState** (Application Layer): Provider state container
  - Attributes: settings (Preservable<FirewallUISettings>), status (EmptyStatus)
  - Belongs in: `lib/page/advanced_settings/firewall/providers/firewall_state.dart`

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All firewall JNAP imports removed from Provider layer - `grep -r "import.*jnap/models" lib/page/advanced_settings/firewall/providers/` returns 0 results
- **SC-002**: All firewall JNAP imports removed from View layer - `grep -r "import.*jnap/models" lib/page/advanced_settings/firewall/views/` returns 0 results
- **SC-003**: FirewallSettingsService test coverage ≥90% including all JNAP transformation logic
- **SC-004**: FirewallNotifier test coverage ≥85% including delegation and state management
- **SC-005**: FirewallState and related model tests ≥90% coverage including serialization tests
- **SC-006**: All existing UI tests pass without modification (backward compatibility)
- **SC-007**: All view/provider tests use only UI models (FirewallUISettings, IPv6PortServiceRuleUI)
- **SC-008**: FirewallSettingsService includes complete documentation of transformation logic via DartDoc
- **SC-009**: Code passes `flutter analyze` with 0 warnings on firewall feature files
- **SC-010**: Code passes `dart format` compliance

---

## Assumptions

1. **No UI changes**: This is purely a refactoring - no new features, no UI modifications
2. **PreservableNotifierMixin continues**: Existing undo/reset functionality is preserved
3. **Existing test coverage maintained**: All existing tests that pass before refactor must still pass
4. **Standard model transformation**: Similar to DMZ and Administration refactors - Service layer handles all Data ↔ UI model conversions
5. **Same JNAP protocol**: Firewall protocol remains unchanged; refactoring doesn't modify JNAP behavior
6. **Port service lists remain**: IPv6 port service rule functionality preserved as-is

---

## Dependencies & Constraints

### Internal Dependencies
- Depends on established patterns from: Administration Settings refactor, DMZ refactor
- Must follow: Updated Project Constitution v2.3 (Data Model Layering Rules)

### Constraints
- JNAP protocol details must be completely hidden from Provider/UI layers
- Must maintain strict one-way dependency flow: UI → Provider → Service → Repository → JNAP
- No circular dependencies allowed
- All public APIs must have DartDoc comments

---

## Out of Scope

- Adding new firewall rules or features
- UI redesign or improvements
- Performance optimization (optimize only if refactoring reveals bottlenecks)
- New test types (use existing unit test framework)

---

## Notes

This refactoring is a direct application of the data model layering principles added to constitution v2.3, learned from the DMZ refactor. The goal is to enforce architectural discipline and make future maintenance easier by ensuring each layer only knows about models appropriate to that layer.
