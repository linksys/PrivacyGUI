# Feature Specification: DashboardHome Service Extraction

**Feature Branch**: `006-dashboard-home-service-extraction`
**Created**: 2025-12-29
**Status**: Draft
**Input**: User description: "Extract DashboardHomeService from DashboardHomeNotifier to enforce three-layer architecture compliance."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Architecture Compliance Refactoring (Priority: P1)

As a developer maintaining the dashboard home feature, I need the code to follow the three-layer architecture so that JNAP model dependencies are properly isolated in the service layer and the codebase remains maintainable and testable.

**Why this priority**: This is a pure refactoring task with a single goal - architectural compliance. The entire feature is about moving data transformation logic from Provider layer to Service layer without changing any user-facing behavior.

**Independent Test**: Can be fully tested by verifying that Provider and State files no longer import JNAP models, while all existing dashboard functionality continues to work correctly.

**Acceptance Scenarios**:

1. **Given** the refactored codebase, **When** running `grep -r "import.*jnap/models" lib/page/dashboard/providers/`, **Then** zero results are returned
2. **Given** the refactored codebase, **When** the dashboard home view loads, **Then** all WiFi networks, uptime, port connections, and node status display correctly as before
3. **Given** the new DashboardHomeService, **When** unit tests run, **Then** JNAP model to UI model transformations are verified independently

---

### User Story 2 - Service Layer Testability (Priority: P2)

As a developer writing tests, I need the data transformation logic isolated in a service class so that I can unit test the WiFi item creation and state building logic without mocking the entire provider hierarchy.

**Why this priority**: Testability is a key benefit of the service extraction but secondary to the primary architectural compliance goal.

**Independent Test**: Can be tested by creating unit tests for DashboardHomeService that mock only RouterRepository-level data and verify correct UI model output.

**Acceptance Scenarios**:

1. **Given** DashboardHomeService with mocked input data, **When** building WiFi items from main radios, **Then** correct DashboardWiFiUIModel is returned with proper SSID, password, radios list, and device count
2. **Given** DashboardHomeService with mocked input data, **When** building WiFi items from guest radios, **Then** correct DashboardWiFiUIModel is returned with isGuest=true and proper guest network properties

---

### Edge Cases

- What happens when mainRadios list is empty? Service should return empty WiFi list without errors
- What happens when guestRadios list is empty? Service should not add guest WiFi item to the list
- What happens when all nodes are offline? isAnyNodesOffline flag should be true
- What happens when deviceInfo is null? Service should handle null safely for port layout determination

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST create a new DashboardHomeService class in `lib/page/dashboard/services/`
- **FR-002**: DashboardHomeService MUST contain all data transformation logic currently in DashboardHomeNotifier.createState()
- **FR-003**: DashboardHomeService MUST handle WiFi list building from main radios (grouping by band, counting connected devices)
- **FR-004**: DashboardHomeService MUST handle WiFi list building from guest radios
- **FR-005**: DashboardHomeService MUST determine node offline status, WAN type, port layout, and master icon
- **FR-006**: DashboardHomeNotifier MUST delegate to DashboardHomeService for state building
- **FR-007**: DashboardHomeNotifier MUST NOT import any `core/jnap/models/` files after refactoring
- **FR-008**: DashboardHomeState file MUST NOT import any `core/jnap/models/` files after refactoring
- **FR-009**: DashboardWiFiUIModel factory methods (fromMainRadios, fromGuestRadios) MUST be removed or moved to Service layer
- **FR-010**: System MUST maintain identical behavior and output as before refactoring (pure refactor, no feature changes)

### Key Entities

- **DashboardHomeService**: New service class responsible for transforming JNAP/Manager state data into DashboardHomeState
- **DashboardHomeState**: Existing UI state model (unchanged structure, but file must not import JNAP models)
- **DashboardWiFiUIModel**: Existing UI model for WiFi network display (factory methods relocated to service)
- **DashboardManagerState**: Input data source containing radio info, uptime, port connections (JNAP layer)
- **DeviceManagerState**: Input data source containing device list, WAN status, node info (JNAP layer)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Provider layer (`lib/page/dashboard/providers/`) contains zero imports from `core/jnap/models/`
- **SC-002**: All existing dashboard home functionality works identically before and after refactoring
- **SC-003**: DashboardHomeService has unit test coverage of at least 90% for data transformation methods
- **SC-004**: Code passes `flutter analyze` with no new warnings or errors
- **SC-005**: Architecture compliance check script returns zero violations for dashboard providers

## Assumptions

- The existing DashboardManagerState and DeviceManagerState will continue to expose JNAP models (they are in the core/jnap layer, not page layer)
- DashboardHomeService will receive these manager states as input and transform them to UI models
- The service will be stateless (pure transformation functions)
- Helper functions like `routerIconTestByModel` and `isHorizontalPorts` can continue to be used by the service
- The `getBandConnectedBy` method from DeviceManagerNotifier will need to be accessible to the service layer (may require interface or callback pattern)
