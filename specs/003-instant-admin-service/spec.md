# Feature Specification: Instant Admin Service Extraction

**Feature Branch**: `003-instant-admin-service`
**Created**: 2025-12-22
**Status**: Draft
**Input**: User description: "Extract JNAP communication logic from TimezoneNotifier and PowerTableNotifier into dedicated Service classes (TimezoneService and PowerTableService) following Article VI Service Layer Principle."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Developer Maintains Timezone Provider Code (Priority: P1)

As a developer maintaining the timezone functionality, I need the JNAP communication logic separated from state management so that I can easily test, modify, and extend the timezone feature without affecting the UI layer.

**Why this priority**: This is the core architectural improvement that enables all other benefits. TimezoneNotifier currently contains JNAP calls directly (`RouterRepository.send()` for `getTimeSettings` and `setTimeSettings`), violating the three-layer architecture principle.

**Independent Test**: Can be fully tested by creating unit tests for the new TimezoneService that mock RouterRepository, verifying that JNAP data is correctly transformed to UI models.

**Acceptance Scenarios**:

1. **Given** TimezoneService is implemented, **When** `fetchTimezoneSettings()` is called, **Then** it returns timezone configuration data transformed from JNAP response to application-layer models.
2. **Given** TimezoneService is implemented, **When** `saveTimezoneSettings()` is called with valid settings, **Then** it transforms UI model to JNAP format and sends the request.
3. **Given** a JNAP error occurs during fetch, **When** the service catches the error, **Then** it throws an appropriate ServiceError type instead of JNAPError.

---

### User Story 2 - Developer Maintains Power Table Provider Code (Priority: P1)

As a developer maintaining the power table (transmit region) functionality, I need the JNAP communication logic separated from state management so that I can easily test and modify the feature independently.

**Why this priority**: Same architectural concern as timezone. PowerTableNotifier directly accesses polling provider data and calls `RouterRepository.send()` for `setPowerTableSettings`, which should be encapsulated in a service.

**Independent Test**: Can be fully tested by creating unit tests for the new PowerTableService that mock RouterRepository, verifying country data transformation and save operations.

**Acceptance Scenarios**:

1. **Given** PowerTableService is implemented, **When** `fetchPowerTableSettings()` is called, **Then** it returns power table configuration including supported countries list.
2. **Given** PowerTableService is implemented, **When** `savePowerTableCountry()` is called with a valid country, **Then** it sends the correct JNAP request and handles polling restart.
3. **Given** a JNAP error occurs during save, **When** the service catches the error, **Then** it throws an appropriate ServiceError type.

---

### User Story 3 - Refactored Providers Delegate to Services (Priority: P2)

As a developer, I need the existing TimezoneNotifier and PowerTableNotifier to be refactored to use the new services so that the architecture compliance is complete.

**Why this priority**: This completes the refactoring by connecting the new services to existing providers, ensuring the three-layer architecture is properly implemented.

**Independent Test**: Can be tested by verifying that providers no longer import JNAP models or call RouterRepository directly.

**Acceptance Scenarios**:

1. **Given** TimezoneNotifier is refactored, **When** `performFetch()` is called, **Then** it delegates to TimezoneService instead of calling RouterRepository directly.
2. **Given** TimezoneNotifier is refactored, **When** `performSave()` is called, **Then** it delegates to TimezoneService.
3. **Given** PowerTableNotifier is refactored, **When** `build()` is called, **Then** it uses PowerTableService to fetch data.
4. **Given** PowerTableNotifier is refactored, **When** `save()` is called, **Then** it delegates to PowerTableService.

---

### Edge Cases

- What happens when JNAP returns an empty supported timezones list?
  - Service should return an empty list; provider should handle gracefully.
- What happens when power table is not selectable (`isPowerTableSelectable: false`)?
  - Service should return this status; UI should not show the transmit region option (existing behavior preserved).
- What happens when network timeout occurs during save?
  - Service should throw NetworkError; provider should propagate error to UI for user feedback.
- What happens when invalid country code is provided to PowerTableService?
  - Service should handle gracefully; rely on enum resolution with fallback to USA.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a `TimezoneService` class that encapsulates all timezone-related JNAP communication (getTimeSettings, setTimeSettings).
- **FR-002**: System MUST provide a `PowerTableService` class that encapsulates all power table-related JNAP communication (getPowerTableSettings via polling data, setPowerTableSettings).
- **FR-003**: Services MUST accept `RouterRepository` via constructor injection for testability.
- **FR-004**: Services MUST transform JNAP response data to application-layer models (TimezoneSettings, TimezoneStatus, PowerTableState).
- **FR-005**: Services MUST catch all `JNAPError` exceptions and convert them to appropriate `ServiceError` types per Article XIII.
- **FR-006**: `TimezoneNotifier` MUST be refactored to use `TimezoneService` instead of direct RouterRepository calls.
- **FR-007**: `PowerTableNotifier` MUST be refactored to use `PowerTableService` instead of direct RouterRepository/polling calls.
- **FR-008**: Provider layer files MUST NOT import `jnap/models` or `jnap/result` after refactoring (architecture compliance).
- **FR-009**: Service providers MUST be defined using `Provider<T>` pattern (stateless) following Article VI.
- **FR-010**: Unit tests MUST be provided for both services with ≥90% coverage per Article I.

### Key Entities

- **TimezoneService**: Stateless service handling timezone JNAP operations. Key operations: `fetchTimezoneSettings()`, `saveTimezoneSettings()`.
- **PowerTableService**: Stateless service handling power table JNAP operations. Key operations: `fetchPowerTableSettings()`, `savePowerTableCountry()`.
- **TimezoneSettings**: Application-layer model for timezone configuration (isDaylightSaving, timezoneId).
- **TimezoneStatus**: Application-layer model for read-only timezone data (supportedTimezones list).
- **PowerTableState**: Application-layer model for power table configuration (isPowerTableSelectable, supportedCountries, country).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Architecture compliance check passes - `grep -r "import.*jnap/models" lib/page/instant_admin/providers/` returns 0 results for timezone and power table providers.
- **SC-002**: Architecture compliance check passes - `grep -r "import.*jnap/result" lib/page/instant_admin/providers/` returns 0 results for timezone and power table providers.
- **SC-003**: Unit test coverage for TimezoneService is ≥90%.
- **SC-004**: Unit test coverage for PowerTableService is ≥90%.
- **SC-005**: All existing functionality in InstantAdminView related to timezone and power table continues to work without regression.
- **SC-006**: `flutter analyze` passes with no new errors introduced.
- **SC-007**: All existing tests in the project continue to pass.

## Assumptions

- The existing `TimezoneState`, `TimezoneSettings`, `TimezoneStatus`, and `PowerTableState` classes are already suitable for use as application-layer models and do not need to be changed (they already follow Equatable pattern).
- The `SupportedTimezone` JNAP model can continue to be used in `TimezoneStatus` since it's a data transfer object, but the import should be in the service layer, not provider layer.
- The `PowerTableCountries` enum is already defined in the provider file and can remain there as it's used by both service and provider layers.
- Error handling for timezone and power table operations does not require new ServiceError types beyond what exists in `service_error.dart`.
