# Feature Specification: Extract AddNodesService

**Feature Branch**: `001-add-nodes-service`
**Created**: 2026-01-06
**Status**: Draft
**Input**: User description: "Extract AddNodesService from AddNodesNotifier to enforce three-layer architecture compliance"

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

### Edge Cases

- What happens when JNAP returns unexpected status values during auto-onboarding polling?
- Timeout during `pollForNodesOnline()`: Preserve existing behavior - stream completes after max retries; caller handles empty/partial result
- What happens if `pollNodesBackhaulInfo()` returns empty backhaul data for some nodes?
- How does error handling work when multiple JNAP calls fail in sequence during `startAutoOnboarding()`?

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

### Key Entities

- **AddNodesService**: Stateless service class encapsulating all JNAP communication for the Add Nodes feature. Handles Bluetooth auto-onboarding, device polling, and backhaul info retrieval.
- **AutoOnboardingStatus**: UI-friendly representation of onboarding status (replaces raw JNAP output). Contains status enum (Idle, Onboarding, Complete) and device onboarding details.
- **ServiceError**: Error types thrown by Service layer (already defined in `lib/core/errors/service_error.dart`). AddNodesService maps JNAPError to appropriate ServiceError subtypes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: AddNodesNotifier contains zero imports from `core/jnap/models/`, `core/jnap/actions/`, or `core/jnap/result/` (verified via grep)
- **SC-002**: All existing Add Nodes feature functionality works identically after refactoring (verified via manual testing of node onboarding flow)
- **SC-003**: AddNodesService has unit test coverage of at least 90% for all public methods
- **SC-004**: AddNodesNotifier/State tests achieve at least 85% coverage
- **SC-005**: `flutter analyze` reports no new errors or warnings in the modified files
- **SC-006**: Architecture compliance check passes: `grep -r "import.*jnap/models" lib/page/nodes/providers/` returns 0 results

## Clarifications

### Session 2026-01-06

- Q: How does the system handle timeout during `pollForNodesOnline()` when nodes never come online? → A: Preserve existing behavior (stream completes after max retries; caller handles empty/partial result)
- Q: Should LinksysDevice model remain importable by the Provider layer? → A: Keep LinksysDevice as-is (already in `core/utils/`, not a JNAP model)

## Assumptions

- The existing `LinksysDevice` model from `core/utils/devices.dart` is acceptable for Provider layer use since it resides in `core/utils/` (not `core/jnap/models/`) and thus complies with architecture rules
- The `BackHaulInfoData` model from `core/jnap/models/back_haul_info.dart` needs to stay in Service layer only; Provider should receive transformed data
- The `BenchMarkLogger` utility can remain in Provider for logging purposes as it's not a JNAP concern
- Polling logic (retry counts, delays) should be configurable parameters in Service methods rather than hardcoded
- The `pollingProvider` interaction for stopping/starting polling can remain in the Notifier as it's state coordination, not JNAP communication
