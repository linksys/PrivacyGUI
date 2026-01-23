# Feature Specification: Device Manager Service Extraction

**Feature Branch**: `001-device-manager-service-extraction`
**Created**: 2025-12-28
**Status**: Draft
**Input**: User description: "Extract DeviceManagerService from DeviceManagerNotifier to enforce three-layer architecture compliance."

## Clarifications

### Session 2025-12-28

- Q: When `transformPollingData()` receives null or malformed JNAP responses, how should the service behave? → A: Return empty/default state (preserves current behavior)
- Q: When `deleteDevices()` is called with an empty list of device IDs, how should the service behave? → A: Return early with empty success result (no-op)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Data Transformation Isolation (Priority: P1)

As a developer, when the DeviceManagerNotifier receives polling data, the JNAP-specific data transformation logic should be handled by a dedicated service so that the provider layer remains free of JNAP model dependencies.

**Why this priority**: This is the core architectural change. All other functionality depends on this transformation being properly isolated. It directly addresses the constitution Article V violation.

**Independent Test**: Can be fully tested by mocking the service's `transformPollingData()` method and verifying the provider correctly delegates and consumes the transformed state.

**Acceptance Scenarios**:

1. **Given** polling data arrives from `pollingProvider`, **When** `DeviceManagerNotifier.build()` is called, **Then** it delegates to `DeviceManagerService.transformPollingData()` and receives a `DeviceManagerState`.
2. **Given** the service transforms polling data, **When** transformation completes, **Then** all JNAP models are converted internally and only `DeviceManagerState` is exposed.
3. **Given** the provider file, **When** inspecting imports, **Then** no imports from `core/jnap/models/` or `core/jnap/result/` are present.

---

### User Story 2 - Device Property Updates (Priority: P2)

As a user, when I update a device's name or icon, the system should persist these changes via the router API, with all JNAP communication handled by the service layer.

**Why this priority**: This is a user-facing write operation that currently violates architecture by directly using RouterRepository in the provider.

**Independent Test**: Can be tested by calling `updateDeviceNameAndIcon()` and verifying the service makes the correct API calls and returns appropriate results.

**Acceptance Scenarios**:

1. **Given** a device ID, new name, and optional icon, **When** `updateDeviceNameAndIcon()` is called, **Then** the service sends the correct JNAP action and updates local state on success.
2. **Given** the API call fails, **When** an error occurs, **Then** the service throws a `ServiceError` that the provider can handle appropriately.

---

### User Story 3 - Device Deletion (Priority: P2)

As a user, when I delete devices from my network, the system should remove them via the router API with proper error handling at the service layer.

**Why this priority**: Another user-facing write operation requiring service extraction.

**Independent Test**: Can be tested by calling `deleteDevices()` with device IDs and verifying service handles bulk deletion and error cases.

**Acceptance Scenarios**:

1. **Given** a list of device IDs, **When** `deleteDevices()` is called, **Then** the service deletes each device and updates local state for successfully deleted devices.
2. **Given** some deletions fail, **When** partial success occurs, **Then** the service reports which devices were deleted and which failed.

---

### User Story 4 - Client Deauthentication (Priority: P3)

As a user, when I disconnect a client device from my network, the system should deauthenticate it via the router API through the service layer.

**Why this priority**: Less frequently used operation, but still requires service extraction for consistency.

**Independent Test**: Can be tested by calling `deauthClient()` with a MAC address and verifying the service makes the correct API call.

**Acceptance Scenarios**:

1. **Given** a device MAC address, **When** `deauthClient()` is called, **Then** the service sends the clientDeauth action.
2. **Given** deauthentication completes, **When** successful, **Then** the provider triggers a polling refresh.

---

### Edge Cases

- **Null/malformed polling data**: Service returns empty/default `DeviceManagerState` (preserves current behavior).
- **Partial transformation failures**: Service processes available data and skips failed JNAP actions, returning partial state with available information.
- **Empty device list for deletion**: Service returns early with empty success result (no-op); no API calls made.
- **Concurrent update operations**: Handled by existing polling mechanism; no additional synchronization required.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST create a `DeviceManagerService` class that encapsulates all JNAP communication and data transformation logic currently in `DeviceManagerNotifier`.
- **FR-002**: `DeviceManagerService` MUST provide a `transformPollingData(CoreTransactionData?)` method that transforms raw JNAP polling results into `DeviceManagerState`.
- **FR-003**: `DeviceManagerService` MUST provide an `updateDeviceNameAndIcon()` method that handles the `setDeviceProperties` JNAP action and error mapping.
- **FR-004**: `DeviceManagerService` MUST provide a `deleteDevices(List<String> deviceIds)` method that handles bulk device deletion via RouterRepository.
- **FR-005**: `DeviceManagerService` MUST provide a `deauthClient(String macAddress)` method that handles client deauthentication.
- **FR-006**: `DeviceManagerNotifier` MUST NOT import any modules from `core/jnap/models/`, `core/jnap/result/`, or `core/jnap/actions/`.
- **FR-007**: `DeviceManagerNotifier` MUST delegate all JNAP operations to `DeviceManagerService`.
- **FR-008**: `DeviceManagerService` MUST map JNAP errors to `ServiceError` types as defined in Article XIII of the constitution.
- **FR-009**: All helper methods currently in `DeviceManagerNotifier` that query state (e.g., `getSsidConnectedBy`, `getBandConnectedBy`, `findParent`) MUST remain in the notifier as they operate on cached state, not JNAP.
- **FR-010**: The service MUST be provided via a Riverpod `Provider<DeviceManagerService>` following Article VI naming conventions.

### Key Entities

- **DeviceManagerService**: New service class responsible for JNAP communication and data transformation. Located in `lib/core/jnap/services/`.
- **DeviceManagerState**: Existing state class containing transformed device data. Remains in `lib/core/jnap/providers/`.
- **CoreTransactionData**: Input from polling provider containing raw JNAP responses.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `DeviceManagerNotifier` contains zero imports from `core/jnap/models/`, `core/jnap/result/`, or `core/jnap/actions/` directories.
- **SC-002**: All existing functionality (device list display, device updates, deletions, deauthentication) works identically from the user's perspective.
- **SC-003**: `DeviceManagerService` has unit test coverage of at least 90% for all public methods.
- **SC-004**: `DeviceManagerNotifier` has unit test coverage of at least 85% for state management logic.
- **SC-005**: No regression in dependent features (device filtering, topology display, device details) verified by running existing test suite.

## Assumptions

- The `DeviceManagerState` class will remain in `lib/core/jnap/providers/` as it is the public API consumed by feature providers.
- Helper methods that query cached state (not JNAP) will remain in the notifier for performance and simplicity.
- The service will be placed in `lib/core/jnap/services/` since it's infrastructure code, not feature-specific.
- Existing consumers of `deviceManagerProvider` will not require changes as the public API remains unchanged.

## Dependencies

- Depends on existing `ServiceError` infrastructure defined in `lib/core/errors/service_error.dart`.
- Depends on `RouterRepository` for JNAP command execution.
- Depends on `pollingProvider` for raw JNAP transaction data.

## Out of Scope

- Refactoring `DeviceManagerState` to use UI Models (state is already the "UI model" for this infrastructure provider).
- Changes to downstream feature providers that consume `deviceManagerProvider`.
- Performance optimizations beyond the scope of service extraction.
