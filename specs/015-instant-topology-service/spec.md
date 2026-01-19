# Feature Specification: InstantTopology Service Extraction

**Feature Branch**: `001-instant-topology-service`
**Created**: 2026-01-02
**Status**: Draft
**Input**: Extract InstantTopologyService from InstantTopologyNotifier to enforce three-layer architecture compliance

## Overview

This feature refactors the InstantTopologyNotifier to comply with the project's three-layer architecture (Article V, VI, XIII of constitution.md). Currently, the provider directly handles JNAP communication, which violates the architectural principle that providers should only manage UI state while services handle business logic and external communication.

## Clarifications

### Session 2026-01-02

- Q: What should happen when the maximum wait time is exceeded while waiting for nodes to go offline? → A: Throw timeout error after max retries (preserve current behavior: 20 retries at 3-second intervals = 60 seconds)
- Q: Should new ServiceError subtypes be created specifically for topology operations? → A: Yes, create specific types: TopologyTimeoutError, NodeOfflineError, NodeOperationFailedError

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Node Reboot Operation (Priority: P1)

As a network administrator, I want to reboot router nodes so that I can resolve network issues or apply configuration changes.

**Why this priority**: Reboot is the most common maintenance operation and affects system availability. Must work reliably.

**Independent Test**: Can be fully tested by triggering a reboot operation and verifying the node restarts successfully.

**Acceptance Scenarios**:

1. **Given** a single master node is online, **When** I initiate a reboot, **Then** the master node reboots and the operation completes without error
2. **Given** multiple child nodes are online, **When** I initiate a reboot for specific nodes, **Then** only the specified nodes reboot in reverse order (bottom-up) and the system waits for them to go offline
3. **Given** a reboot operation is in progress, **When** a network error occurs, **Then** the system reports a meaningful error to the user

---

### User Story 2 - Factory Reset Operation (Priority: P1)

As a network administrator, I want to factory reset router nodes so that I can restore them to default settings or remove them from the network.

**Why this priority**: Factory reset is critical for node removal and troubleshooting. Must be reliable as it's destructive.

**Independent Test**: Can be fully tested by triggering a factory reset and verifying the node returns to factory defaults.

**Acceptance Scenarios**:

1. **Given** a master node is online, **When** I initiate a factory reset, **Then** the master node resets to factory defaults
2. **Given** multiple child nodes are online, **When** I initiate a factory reset for specific nodes, **Then** the nodes reset in reverse order (bottom-up) and the system waits for them to go offline before completing
3. **Given** a factory reset operation fails, **When** the error is returned, **Then** the system reports a meaningful error indicating which node failed

---

### User Story 3 - Node LED Blink Control (Priority: P2)

As a network administrator, I want to blink a node's LED so that I can physically identify which router corresponds to which entry in the app.

**Why this priority**: LED blink is a convenience feature for physical identification. Important but not critical.

**Independent Test**: Can be fully tested by starting LED blink on a node and verifying the LED starts blinking.

**Acceptance Scenarios**:

1. **Given** a node is online, **When** I start LED blink for that node, **Then** the node's LED begins blinking
2. **Given** a node's LED is blinking, **When** I stop LED blink, **Then** the LED stops blinking
3. **Given** node A's LED is blinking, **When** I start LED blink for node B, **Then** node A stops blinking and node B starts blinking
4. **Given** an LED blink operation fails, **When** the error is returned, **Then** the system handles the error gracefully

---

### Edge Cases

- What happens when a node goes offline during a reboot or factory reset operation? → Operation continues; going offline is the expected outcome
- Timeout behavior: Service throws a timeout ServiceError after 60 seconds (20 retries × 3-second intervals) if nodes don't go offline
- What happens when LED blink is requested for an offline node? → Operation fails with appropriate ServiceError
- How does the system handle partial failures in multi-node operations? → Operation stops at first failure, throws ServiceError indicating which node failed

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST create an InstantTopologyService class that handles all JNAP communication for topology operations
- **FR-002**: Service MUST provide a method to reboot nodes (single master or multiple child nodes)
- **FR-003**: Service MUST provide a method to factory reset nodes (single master or multiple child nodes)
- **FR-004**: Service MUST provide a method to start LED blinking on a specific node
- **FR-005**: Service MUST provide a method to stop LED blinking
- **FR-006**: Service MUST wait for nodes to go offline after reboot/factory reset operations before completing
- **FR-007**: Service MUST convert all JNAP errors to specific ServiceError types: TopologyTimeoutError (wait timeout), NodeOfflineError (node unreachable), NodeOperationFailedError (reboot/reset/blink failure)
- **FR-008**: InstantTopologyNotifier MUST delegate all JNAP operations to the service
- **FR-009**: InstantTopologyNotifier MUST NOT import any jnap/actions, jnap/command, or jnap/result modules after refactoring
- **FR-010**: InstantTopologyNotifier MUST only catch ServiceError types, not JNAPError
- **FR-011**: Service MUST handle multi-node operations in reverse order (bottom-up for reboot/factory reset)
- **FR-012**: Service MUST throw a timeout ServiceError if nodes do not go offline within 60 seconds (20 retries at 3-second intervals)

### Key Entities

- **InstantTopologyService**: Service class responsible for JNAP communication and error handling for topology operations
- **TopologyTimeoutError**: ServiceError subtype for wait timeout scenarios (extends ServiceError)
- **NodeOfflineError**: ServiceError subtype when target node is unreachable (extends ServiceError)
- **NodeOperationFailedError**: ServiceError subtype for reboot/reset/blink failures (extends ServiceError)
- **InstantTopologyNotifier**: Existing provider that will delegate to the service (no longer handles JNAP directly)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: InstantTopologyNotifier contains zero imports from `core/jnap/actions/`, `core/jnap/command/`, or `core/jnap/result/`
- **SC-002**: InstantTopologyNotifier contains zero direct references to RouterRepository
- **SC-003**: InstantTopologyNotifier contains zero `JNAPSuccess` or `JNAPError` type checks
- **SC-004**: All existing topology operations (reboot, factory reset, LED blink) continue to function identically from the user's perspective
- **SC-005**: Service layer has unit test coverage of at least 90% for all public methods
- **SC-006**: Provider layer has unit test coverage of at least 85%
- **SC-007**: Architecture compliance checks pass (grep commands from constitution.md Section 5.3.3 return expected results)

## Assumptions

- New ServiceError subtypes (TopologyTimeoutError, NodeOfflineError, NodeOperationFailedError) will be added to `lib/core/errors/service_error.dart` following the existing sealed class pattern
- The `RouterRepository` interface remains stable and does not require modification
- The polling mechanism for waiting for nodes to go offline can remain in the service layer
- SharedPreferences access for blink tracking can remain in the provider (UI state management) or move to service based on implementation preference
