# Feature Specification: Extract AddNodesService

**Feature Branch**: `001-add-nodes-service`
**Created**: 2026-01-06
**Status**: Draft
**Input**: User description: "Extract AddNodesService from AddNodesNotifier and AddWiredNodesNotifier to enforce three-layer architecture compliance"

> **Scope Update (2026-01-07)**: Extended to include `AddWiredNodesNotifier` refactoring alongside the completed `AddNodesNotifier` refactoring.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Architecture Compliance for AddNodes Provider (Priority: P1)

As a developer maintaining the codebase, I need the AddNodesNotifier to comply with the three-layer architecture so that JNAP communication is isolated in the Service layer, making the code more testable and maintainable.

**Why this priority**: This is the core objective of the refactoring. Without architecture compliance, the Provider continues to violate Article V, VI, and XIII of the constitution, creating tight coupling between UI state management and data layer concerns.

**Independent Test**: Can be fully tested by verifying that AddNodesNotifier no longer imports any `jnap/models`, `jnap/actions`, or `jnap/result` packages, and all JNAP communication flows through AddNodesService.

**Acceptance Scenarios**:

1. **Given** the refactored AddNodesNotifier, **When** I inspect its imports, **Then** there are no imports from `core/jnap/models/`, `core/jnap/actions/`, or `core/jnap/result/`
2. **Given** the refactored AddNodesNotifier, **When** it needs to communicate with JNAP, **Then** it delegates to AddNodesService methods instead of using RouterRepository directly
3. **Given** the new AddNodesService, **When** a JNAP error occurs, **Then** it converts the JNAPError to a ServiceError before propagating to the Provider

---

### User Story 2 - Bluetooth Auto-Onboarding Operations via Service (Priority: P1)

As a developer, I need the Bluetooth auto-onboarding JNAP operations (get/set settings, get status, start onboarding) to be encapsulated in AddNodesService so that the Provider only handles UI state and error presentation.

**Why this priority**: These operations form the core business logic of the Add Nodes feature. Extracting them enables proper error handling and testability.

**Independent Test**: Can be tested by invoking AddNodesService methods and verifying they return appropriate UI-friendly results or throw ServiceError on failure.

**Acceptance Scenarios**:

1. **Given** AddNodesService, **When** `setAutoOnboardingSettings()` is called, **Then** it sends the JNAP action and returns success or throws ServiceError
2. **Given** AddNodesService, **When** `getAutoOnboardingSettings()` is called, **Then** it returns a boolean indicating if auto-onboarding is enabled
3. **Given** AddNodesService, **When** `pollAutoOnboardingStatus()` is called, **Then** it returns a Stream of UI-friendly status objects (not raw JNAPResult)
4. **Given** AddNodesService, **When** JNAP returns an error during any operation, **Then** the Service converts it to an appropriate ServiceError

---

### User Story 3 - Node Polling Operations via Service (Priority: P2)

As a developer, I need the node polling operations (poll for nodes online, poll backhaul info) to be encapsulated in AddNodesService so that complex device list transformations happen in the Service layer.

**Why this priority**: These operations involve significant data transformation from JNAP models to UI models. Moving them to Service ensures proper separation of concerns.

**Independent Test**: Can be tested by mocking RouterRepository and verifying AddNodesService correctly transforms JNAP device responses to LinksysDevice lists.

**Acceptance Scenarios**:

1. **Given** AddNodesService, **When** `pollForNodesOnline()` is called with MAC addresses, **Then** it returns a Stream of device lists without exposing JNAPResult to the caller
2. **Given** AddNodesService, **When** `pollNodesBackhaulInfo()` is called with nodes, **Then** it returns a Stream of backhaul info data as UI models
3. **Given** AddNodesService, **When** polling times out or fails, **Then** it throws an appropriate ServiceError

---

### User Story 4 - Service Layer Testability (Priority: P2)

As a developer writing tests, I need AddNodesService to be independently testable with mocked RouterRepository so that I can verify JNAP communication and data transformation logic in isolation.

**Why this priority**: Testability is a key architectural requirement. The Service must accept RouterRepository via constructor injection for easy mocking.

**Independent Test**: Can be verified by writing unit tests that mock RouterRepository and test all Service methods.

**Acceptance Scenarios**:

1. **Given** AddNodesService, **When** instantiated, **Then** it accepts RouterRepository as a constructor parameter
2. **Given** a test with mocked RouterRepository, **When** AddNodesService methods are called, **Then** they can be tested without actual JNAP communication
3. **Given** test data builders, **When** testing AddNodesService, **Then** they provide reusable JNAP mock responses

---

### User Story 5 - Architecture Compliance for AddWiredNodes Provider (Priority: P1)

As a developer maintaining the codebase, I need the AddWiredNodesNotifier to comply with the three-layer architecture so that JNAP communication for wired node onboarding is isolated in the Service layer, making the code more testable and maintainable.

**Why this priority**: Similar to User Story 1, AddWiredNodesNotifier currently violates Article V, VI, and XIII by directly importing JNAP models (BackHaulInfoData), JNAP result (JNAPSuccess), and JNAP actions, and using RouterRepository directly.

**Independent Test**: Can be fully tested by verifying that AddWiredNodesNotifier no longer imports any `jnap/models`, `jnap/actions`, or `jnap/result` packages, and all JNAP communication flows through AddWiredNodesService.

**Acceptance Scenarios**:

1. **Given** the refactored AddWiredNodesNotifier, **When** I inspect its imports, **Then** there are no imports from `core/jnap/models/`, `core/jnap/actions/`, or `core/jnap/result/`
2. **Given** the refactored AddWiredNodesNotifier, **When** it needs to communicate with JNAP, **Then** it delegates to AddWiredNodesService methods instead of using RouterRepository directly
3. **Given** the new AddWiredNodesService, **When** a JNAP error occurs, **Then** it converts the JNAPError to a ServiceError before propagating to the Provider
4. **Given** the refactored AddWiredNodesState, **When** I inspect its imports, **Then** there are no imports from `core/jnap/models/` (BackHaulInfoData should be replaced with a UI model)

---

### User Story 6 - Wired Auto-Onboarding Operations via Service (Priority: P1)

As a developer, I need the wired auto-onboarding JNAP operations (get/set settings, poll backhaul info, fetch nodes) to be encapsulated in AddWiredNodesService so that the Provider only handles UI state and error presentation.

**Why this priority**: These operations form the core business logic of the Add Wired Nodes feature. The current implementation directly uses RouterRepository.scheduledCommand() for polling, which exposes JNAP internals to the Provider.

**Independent Test**: Can be tested by invoking AddWiredNodesService methods and verifying they return appropriate UI-friendly results or throw ServiceError on failure.

**Acceptance Scenarios**:

1. **Given** AddWiredNodesService, **When** `setAutoOnboardingEnabled(true)` is called, **Then** it sends `setWiredAutoOnboardingSettings` JNAP action and returns success or throws ServiceError
2. **Given** AddWiredNodesService, **When** `getAutoOnboardingEnabled()` is called, **Then** it returns a boolean indicating if wired auto-onboarding is enabled
3. **Given** AddWiredNodesService, **When** `pollBackhaulChanges()` is called with a snapshot, **Then** it returns a Stream of backhaul change events as UI-friendly objects (not raw JNAPResult)
4. **Given** AddWiredNodesService, **When** `fetchNodes()` is called, **Then** it returns a List<LinksysDevice> transformed from JNAP response
5. **Given** AddWiredNodesService, **When** JNAP returns an error during any operation, **Then** the Service converts it to an appropriate ServiceError

---

### User Story 7 - AddWiredNodesState Model Compliance (Priority: P2)

As a developer, I need the AddWiredNodesState to not directly reference JNAP models (BackHaulInfoData) so that the State layer complies with the three-layer architecture.

**Why this priority**: The current AddWiredNodesState contains `List<BackHaulInfoData>` which violates architecture rules. This needs to be replaced with a UI model.

**Independent Test**: Can be tested by checking that AddWiredNodesState only imports from allowed layers and uses UI models.

**Acceptance Scenarios**:

1. **Given** the refactored AddWiredNodesState, **When** I inspect its definition, **Then** it uses `List<BackhaulInfoUIModel>` instead of `List<BackHaulInfoData>`
2. **Given** AddWiredNodesService, **When** it transforms backhaul data, **Then** it converts `BackHaulInfoData` (JNAP model) to `BackhaulInfoUIModel` (UI model)

---

### Edge Cases

- What happens when JNAP returns unexpected status values during auto-onboarding polling?
- Timeout during `pollForNodesOnline()`: Preserve existing behavior - stream completes after max retries; caller handles empty/partial result
- What happens if `pollNodesBackhaulInfo()` returns empty backhaul data for some nodes?
- How does error handling work when multiple JNAP calls fail in sequence during `startAutoOnboarding()`?
- **Wired-specific**: What happens when `pollBackhaulChanges()` finds no new wired nodes after the timeout period?
- **Wired-specific**: How does the system handle the timestamp comparison logic for detecting new vs existing backhaul entries?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST create AddNodesService class in `lib/page/nodes/services/add_nodes_service.dart`
- **FR-002**: AddNodesService MUST accept RouterRepository via constructor injection
- **FR-003**: AddNodesService MUST provide `setAutoOnboardingSettings()` method that enables Bluetooth auto-onboarding
- **FR-004**: AddNodesService MUST provide `getAutoOnboardingSettings()` method that returns boolean status
- **FR-005**: AddNodesService MUST provide `pollAutoOnboardingStatus()` method that returns Stream of UI-friendly status objects
- **FR-006**: AddNodesService MUST provide `startAutoOnboarding()` method that orchestrates the full onboarding flow
- **FR-007**: AddNodesService MUST provide `pollForNodesOnline()` method that returns Stream of device lists
- **FR-008**: AddNodesService MUST provide `pollNodesBackhaulInfo()` method that returns Stream of backhaul info
- **FR-009**: AddNodesService MUST convert all JNAPError instances to appropriate ServiceError types
- **FR-010**: AddNodesNotifier MUST be refactored to delegate all JNAP communication to AddNodesService
- **FR-011**: AddNodesNotifier MUST NOT import any modules from `core/jnap/models/`, `core/jnap/actions/`, or `core/jnap/result/`
- **FR-012**: AddNodesNotifier MUST only handle ServiceError types, not JNAPError
- **FR-013**: System MUST create addNodesServiceProvider as a stateless Provider<AddNodesService>
- **FR-014**: System MUST maintain all existing functionality of the Add Nodes feature without behavioral changes

#### Wired Nodes Service Requirements (Scope Extension)

- **FR-015**: System MUST create AddWiredNodesService class in `lib/page/nodes/services/add_wired_nodes_service.dart`
- **FR-016**: AddWiredNodesService MUST accept RouterRepository via constructor injection
- **FR-017**: AddWiredNodesService MUST provide `setAutoOnboardingEnabled(bool enabled)` method that enables/disables wired auto-onboarding
- **FR-018**: AddWiredNodesService MUST provide `getAutoOnboardingEnabled()` method that returns boolean status
- **FR-019**: AddWiredNodesService MUST provide `pollBackhaulChanges(List<BackhaulInfoUIModel> snapshot)` method that returns Stream of backhaul change events. The initial snapshot is obtained by the Provider from `deviceManagerProvider` and converted to `List<BackhaulInfoUIModel>` before calling this method
- **FR-020**: AddWiredNodesService MUST provide `fetchNodes()` method that returns List<LinksysDevice>
- **FR-021**: AddWiredNodesService MUST convert all JNAPError instances to appropriate ServiceError types
- **FR-022**: AddWiredNodesNotifier MUST be refactored to delegate all JNAP communication to AddWiredNodesService
- **FR-023**: AddWiredNodesNotifier MUST NOT import any modules from `core/jnap/models/`, `core/jnap/actions/`, or `core/jnap/result/`
- **FR-024**: AddWiredNodesNotifier MUST only handle ServiceError types, not JNAPError
- **FR-025**: System MUST create addWiredNodesServiceProvider as a stateless Provider<AddWiredNodesService>
- **FR-026**: System MUST create BackhaulInfoUIModel to replace BackHaulInfoData in State layer
- **FR-027**: AddWiredNodesState MUST use BackhaulInfoUIModel instead of BackHaulInfoData for backhaulSnapshot field
- **FR-028**: System MUST maintain all existing functionality of the Add Wired Nodes feature without behavioral changes

### Key Entities

- **AddNodesService**: Stateless service class encapsulating all JNAP communication for the Add Nodes feature. Handles Bluetooth auto-onboarding, device polling, and backhaul info retrieval.
- **AddWiredNodesService**: Stateless service class encapsulating all JNAP communication for the Add Wired Nodes feature. Handles wired auto-onboarding settings, backhaul polling, and node fetching.
- **AutoOnboardingStatus**: UI-friendly representation of onboarding status (replaces raw JNAP output). Contains status enum (Idle, Onboarding, Complete) and device onboarding details.
- **BackhaulInfoUIModel**: UI-friendly representation of backhaul information. Replaces `BackHaulInfoData` (JNAP model) in State/Provider layers. Contains deviceUUID, connectionType, timestamp, and wirelessConnectionInfo.
- **ServiceError**: Error types thrown by Service layer (already defined in `lib/core/errors/service_error.dart`). Both AddNodesService and AddWiredNodesService map JNAPError to appropriate ServiceError subtypes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: AddNodesNotifier contains zero imports from `core/jnap/models/`, `core/jnap/actions/`, or `core/jnap/result/` (verified via grep)
- **SC-002**: All existing Add Nodes feature functionality works identically after refactoring (verified via manual testing of node onboarding flow)
- **SC-003**: AddNodesService has unit test coverage of at least 90% for all public methods
- **SC-004**: AddNodesNotifier/State tests achieve at least 85% coverage
- **SC-005**: `flutter analyze` reports no new errors or warnings in the modified files
- **SC-006**: Architecture compliance check passes: `grep -r "import.*jnap/models" lib/page/nodes/providers/` returns 0 results

#### Wired Nodes Success Criteria (Scope Extension)

- **SC-007**: AddWiredNodesNotifier contains zero imports from `core/jnap/models/`, `core/jnap/actions/`, or `core/jnap/result/` (verified via grep)
- **SC-008**: AddWiredNodesState contains zero imports from `core/jnap/models/` (verified via grep)
- **SC-009**: All existing Add Wired Nodes feature functionality works identically after refactoring (verified via manual testing of wired node onboarding flow)
- **SC-010**: AddWiredNodesService has unit test coverage of at least 90% for all public methods
- **SC-011**: AddWiredNodesNotifier/State tests achieve at least 85% coverage

## Clarifications

### Session 2026-01-06

- Q: How does the system handle timeout during `pollForNodesOnline()` when nodes never come online? → A: Preserve existing behavior (stream completes after max retries; caller handles empty/partial result)
- Q: Should LinksysDevice model remain importable by the Provider layer? → A: Keep LinksysDevice as-is (already in `core/utils/`, not a JNAP model)

### Session 2026-01-07 (Wired Nodes Scope Extension)

- Q: Should AddWiredNodesService reuse any methods from AddNodesService? → A: No, keep them separate. AddWiredNodesService handles different JNAP actions (wired vs Bluetooth) and has different polling logic (backhaul-based detection vs status-based detection)
- Q: Should BackhaulInfoUIModel be shared between AddNodesService and AddWiredNodesService? → A: Yes, BackhaulInfoUIModel can be shared as it represents the same conceptual data, just used differently in each context

## Assumptions

- The existing `LinksysDevice` model from `core/utils/devices.dart` is acceptable for Provider layer use since it resides in `core/utils/` (not `core/jnap/models/`) and thus complies with architecture rules
- The `BackHaulInfoData` model from `core/jnap/models/back_haul_info.dart` needs to stay in Service layer only; Provider should receive transformed data
- The `BenchMarkLogger` utility can remain in Provider for logging purposes as it's not a JNAP concern
- Polling logic (retry counts, delays) should be configurable parameters in Service methods rather than hardcoded
- The `pollingProvider` interaction for stopping/starting polling can remain in the Notifier as it's state coordination, not JNAP communication
- The `idleCheckerPauseProvider` interaction can remain in the Notifier as it's UI lifecycle coordination, not JNAP communication
- The timestamp comparison logic for detecting new backhaul entries (DateFormat parsing) should move to AddWiredNodesService as it's data transformation logic
- The `deviceManagerProvider` read for getting initial backhaul snapshot can remain in the Notifier as it's state coordination from another provider
