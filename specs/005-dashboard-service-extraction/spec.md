# Feature Specification: Dashboard Manager Service Extraction

**Feature Branch**: `005-dashboard-service-extraction`
**Created**: 2025-12-29
**Status**: Draft
**Input**: Extract DashboardManagerService from DashboardManagerNotifier to enforce three-layer architecture compliance.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Polling Data Transformation (Priority: P1)

The system transforms dashboard polling data into UI state without exposing JNAP protocol details to the Provider layer. When polling data arrives, the Service extracts device info, radio settings, system stats, and network connections, then provides a clean DashboardManagerState to the Provider.

**Why this priority**: This is the core transformation logic that runs on every polling cycle. Without this, the dashboard cannot display any router information.

**Independent Test**: Can be fully tested by providing mock CoreTransactionData and verifying the returned DashboardManagerState contains correctly transformed values.

**Acceptance Scenarios**:

1. **Given** valid polling data with all JNAP actions successful, **When** transformPollingData is called, **Then** DashboardManagerState contains deviceInfo, mainRadios, guestRadios, uptimes, system stats, and network connections.

2. **Given** polling data with some JNAP actions failed, **When** transformPollingData is called, **Then** DashboardManagerState contains data from successful actions and null/defaults for failed ones.

3. **Given** null polling data, **When** transformPollingData is called, **Then** DashboardManagerState returns default empty state.

---

### User Story 2 - Router Connectivity Check (Priority: P2)

Users can verify if the router is accessible and matches the expected serial number. This supports reconnection flows after network changes or app backgrounding.

**Why this priority**: Critical for session management and reconnection, but less frequent than polling data transformation.

**Independent Test**: Can be fully tested by mocking RouterRepository.send() and verifying serial number matching logic.

**Acceptance Scenarios**:

1. **Given** router is accessible and serial number matches stored value, **When** checkRouterIsBack is called, **Then** returns NodeDeviceInfo successfully.

2. **Given** router is accessible but serial number does not match, **When** checkRouterIsBack is called, **Then** throws appropriate error.

3. **Given** router is not accessible, **When** checkRouterIsBack is called, **Then** throws ServiceError indicating connectivity failure.

---

### User Story 3 - Device Info Retrieval (Priority: P2)

Users can fetch device information on-demand, using cached state when available or making a fresh API call when needed. This supports various UI flows that need quick access to router information.

**Why this priority**: Used by multiple UI components for display, same priority as connectivity check.

**Independent Test**: Can be fully tested by verifying cache usage and API call behavior.

**Acceptance Scenarios**:

1. **Given** device info exists in current state, **When** checkDeviceInfo is called, **Then** returns cached NodeDeviceInfo without API call.

2. **Given** device info is null in current state, **When** checkDeviceInfo is called, **Then** makes API call and returns fresh NodeDeviceInfo.

---

### User Story 4 - Provider Architecture Compliance (Priority: P1)

The DashboardManagerNotifier maintains clean architecture by delegating all JNAP operations to DashboardManagerService. The Provider layer contains no JNAP model imports, action references, or result type handling.

**Why this priority**: This is an architectural requirement that ensures maintainability and testability of the codebase.

**Independent Test**: Can be verified by static analysis - Provider file should have zero imports from jnap/models, jnap/actions, or jnap/result directories.

**Acceptance Scenarios**:

1. **Given** the refactored Provider file, **When** checking imports, **Then** no imports from core/jnap/models/, core/jnap/actions/, or core/jnap/result/ exist.

2. **Given** the refactored Provider file, **When** checking for RouterRepository usage, **Then** no direct RouterRepository access exists except through Service.

---

### Edge Cases

- What happens when polling data contains malformed JSON for individual actions? The service should skip that action and continue processing others.
- How does the system handle date/time parsing failures from getLocalTime? Should default to current device time.
- What happens when system stats fields (cpuLoad, memoryLoad) are missing? Should default to null values.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST create DashboardManagerService class that encapsulates all JNAP communication for dashboard data.

- **FR-002**: DashboardManagerService MUST implement transformPollingData() method that converts CoreTransactionData to DashboardManagerState.

- **FR-003**: DashboardManagerService MUST implement checkRouterIsBack() method that verifies router connectivity and serial number matching.

- **FR-004**: DashboardManagerService MUST implement checkDeviceInfo() method that returns NodeDeviceInfo from cache or API.

- **FR-005**: DashboardManagerService MUST handle the following JNAP actions:
  - getDeviceInfo
  - getRadioInfo
  - getGuestRadioSettings
  - getSystemStats
  - getEthernetPortConnections
  - getLocalTime
  - getSoftSKUSettings

- **FR-006**: DashboardManagerNotifier MUST be refactored to delegate all JNAP operations to DashboardManagerService.

- **FR-007**: DashboardManagerNotifier MUST NOT contain any imports from jnap/models, jnap/actions, or jnap/result directories after refactoring.

- **FR-008**: DashboardManagerService MUST convert JNAPError to ServiceError types for consistent error handling.

- **FR-009**: Service MUST gracefully handle partial failures where some JNAP actions succeed and others fail.

- **FR-010**: Service MUST provide a dashboardManagerServiceProvider for dependency injection via Riverpod.

### Key Entities

- **DashboardManagerService**: Stateless service class that handles all JNAP communication and data transformation for dashboard functionality. Injected with RouterRepository.

- **DashboardManagerState**: Existing state class containing deviceInfo, mainRadios, guestRadios, isGuestNetworkEnabled, uptimes, wanConnection, lanConnections, skuModelNumber, localTime, cpuLoad, memoryLoad.

- **CoreTransactionData**: Input from pollingProvider containing raw JNAP action results.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: DashboardManagerNotifier contains zero imports from jnap/models, jnap/actions, or jnap/result directories (verified by static analysis).

- **SC-002**: All existing dashboard functionality continues to work correctly (no regression in user-visible behavior).

- **SC-003**: DashboardManagerService has unit test coverage of at least 90% for all public methods.

- **SC-004**: Provider test coverage maintains at least 85% after refactoring.

- **SC-005**: Polling data transformation produces identical DashboardManagerState output before and after refactoring (verified by comparing state snapshots).

## Assumptions

- The existing DashboardManagerState class structure will be preserved; no changes to its fields or serialization.
- The saveSelectedNetwork() method in DashboardManagerNotifier does not involve JNAP calls and can remain in the Provider.
- The polling mechanism via pollingProvider remains unchanged; only the transformation logic moves to Service.
- NodeDeviceInfo and other JNAP models used in DashboardManagerState will continue to be valid return types from Service methods where they represent domain concepts (e.g., checkRouterIsBack returns NodeDeviceInfo).
