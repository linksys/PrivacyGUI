# Feature Specification: NodeDetail Service Extraction

**Feature Branch**: `001-node-detail-service`
**Created**: 2026-01-02
**Status**: Draft
**Input**: User description: "Extract NodeDetailService from NodeDetailNotifier to enforce three-layer architecture compliance."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Code Architecture Compliance (Priority: P1)

As a developer maintaining the codebase, I need the NodeDetailNotifier to follow the three-layer architecture so that business logic is properly separated from data layer concerns and the codebase remains maintainable.

**Why this priority**: This is the core purpose of the refactoring. Without proper architecture separation, the Provider layer directly depends on JNAP models, violating constitution.md Article V, VI, and XIII principles.

**Independent Test**: Can be verified by checking that NodeDetailNotifier no longer imports any `jnap/models`, `jnap/actions`, or `jnap/command` packages after refactoring.

**Acceptance Scenarios**:

1. **Given** NodeDetailNotifier exists with JNAP imports, **When** the service extraction is complete, **Then** NodeDetailNotifier must not import any `core/jnap/models/`, `core/jnap/actions/`, or `core/jnap/command/` packages
2. **Given** the refactored architecture, **When** reviewing the Provider layer, **Then** all JNAP communication must be delegated to NodeDetailService
3. **Given** NodeDetailService is created, **When** the Service handles JNAP errors, **Then** errors must be mapped to ServiceError types before reaching the Provider

---

### User Story 2 - Node LED Blinking Operations (Priority: P1)

As a user viewing node details, I need to be able to trigger the LED blinking on my network node so that I can physically identify which device I'm managing.

**Why this priority**: This is a core user-facing feature that must continue working after refactoring. The blinking functionality uses JNAP actions that need to move to the Service layer.

**Independent Test**: Can be tested by triggering LED blink on a node and verifying the LED physically blinks on the target device.

**Acceptance Scenarios**:

1. **Given** a user is on the node detail screen, **When** they trigger the blink action, **Then** the target node's LED should start blinking
2. **Given** the LED is currently blinking, **When** the user triggers stop blink or the timer expires (24 seconds), **Then** the LED should stop blinking
3. **Given** a blink operation fails, **When** the error is returned from JNAP, **Then** the user should see an appropriate error state and the blinking status should reset

---

### User Story 3 - State Creation from Device Data (Priority: P2)

As a developer, I need the NodeDetailState to be created from device data without directly accessing JNAP model properties in the Provider, so that data transformation logic is properly encapsulated in the Service layer.

**Why this priority**: This ensures the Provider only works with UI-friendly data structures, making it easier to test and maintain.

**Independent Test**: Can be verified by ensuring the `createState` method no longer accesses raw JNAP model properties like `RawDevice`, `DeviceConnectionType`, etc.

**Acceptance Scenarios**:

1. **Given** device manager state contains device data, **When** NodeDetailState is created, **Then** the Service layer must transform JNAP models to UI-appropriate values
2. **Given** the target device is found, **When** state is created, **Then** all node properties (location, connection type, firmware, etc.) must be correctly populated
3. **Given** the target device ID does not exist in the device list, **When** state is created, **Then** an empty state should be returned

---

### Edge Cases

- What happens when the device ID is empty or invalid?
- How does the system handle JNAP communication failures during LED blink operations?
- What happens if SharedPreferences cannot be accessed during blink toggle?
- How does the system handle concurrent blink requests for the same device?
- What happens when the blink timer fires but the device has gone offline?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST create a new NodeDetailService class that encapsulates all JNAP communication for node detail operations
- **FR-002**: NodeDetailService MUST handle JNAP actions `startBlinkNodeLed` and `stopBlinkNodeLed`
- **FR-003**: NodeDetailService MUST map all JNAP errors to appropriate ServiceError types
- **FR-004**: NodeDetailNotifier MUST delegate all JNAP operations to NodeDetailService
- **FR-005**: NodeDetailNotifier MUST NOT import any packages from `core/jnap/models/`, `core/jnap/actions/`, or `core/jnap/command/`
- **FR-006**: NodeDetailNotifier MUST only handle ServiceError types for error handling, not JNAPError
- **FR-007**: NodeDetailService MUST provide transformation helper methods that convert JNAP model properties to UI-appropriate values; the Provider retains responsibility for state creation by calling these helpers
- **FR-008**: System MUST maintain existing blinking functionality behavior including the 24-second auto-stop timer
- **FR-009**: System MUST maintain existing SharedPreferences integration for tracking blinking device state
- **FR-010**: System MUST provide comprehensive unit tests for NodeDetailService with minimum 90% coverage
- **FR-011**: System MUST provide unit tests for refactored NodeDetailNotifier with minimum 85% coverage

### Key Entities

- **NodeDetailState**: UI state model containing node properties (deviceId, location, isMaster, isOnline, connectedDevices, upstreamDevice, connection info, hardware details, etc.)
- **NodeDetailService**: Service class responsible for JNAP communication and data transformation for node detail operations
- **BlinkingStatus**: Enum representing LED blinking states (blinkNode, blinking, stopBlinking)
- **ServiceError**: Base error type for service layer errors (extends from core/errors/service_error.dart)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: NodeDetailNotifier contains zero imports from `core/jnap/models/`, `core/jnap/actions/`, or `core/jnap/command/` after refactoring
- **SC-002**: All existing node detail functionality (LED blinking, device info display) works identically to pre-refactoring behavior
- **SC-003**: NodeDetailService has unit test coverage of at least 90%
- **SC-004**: NodeDetailNotifier has unit test coverage of at least 85%
- **SC-005**: Architecture compliance check passes: `grep -r "import.*jnap/models" lib/page/nodes/providers/` returns zero results
- **SC-006**: Architecture compliance check passes: `grep -r "on JNAPError" lib/page/nodes/providers/` returns zero results
- **SC-007**: `flutter analyze` reports no new errors or warnings in the modified files

## Clarifications

### Session 2026-01-02

- Q: Should the Service own the full state creation logic, or should it provide transformation helpers that the Provider calls? → A: Service provides transformation helpers; Provider creates state by calling these helpers

## Assumptions

- The existing `ServiceError` class hierarchy in `lib/core/errors/service_error.dart` is sufficient for NodeDetail error handling, or can be extended with new error types if needed
- The `DeviceListItem` model used by `connectedDevices` is already a UI model and does not need transformation
- The `nodeDetailIdProvider` remains unchanged as it only provides a String identifier
- SharedPreferences usage for blink tracking will remain in the Provider layer as it's a UI state concern, not JNAP communication
- The `deviceManagerProvider` is an existing Provider that the NodeDetailNotifier will continue to watch for device data
