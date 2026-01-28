# Feature Specification: NodeLightSettings Service Extraction

**Feature Branch**: `002-node-light-settings-service`
**Created**: 2026-01-02
**Status**: Draft
**Input**: User description: "Extract NodeLightSettingsService from NodeLightSettingsNotifier to enforce three-layer architecture compliance."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Code Architecture Compliance (Priority: P1)

As a developer maintaining the codebase, I need the NodeLightSettings feature to follow three-layer architecture so that the code remains consistent, testable, and maintainable according to project standards.

**Why this priority**: Architecture compliance is foundational - it enables proper testing, reduces coupling, and ensures consistency across the codebase. This must be addressed first before any feature enhancements.

**Independent Test**: Run `grep -r "import.*jnap/actions" lib/core/jnap/providers/node_light_settings_provider.dart` and verify zero results. The Provider should only import Service layer dependencies.

**Acceptance Scenarios**:

1. **Given** the refactored codebase, **When** I check imports in `node_light_settings_provider.dart`, **Then** there are no direct imports of `jnap/actions` or `router_repository`
2. **Given** the refactored codebase, **When** I run static analysis, **Then** no architecture violations are reported

---

### User Story 2 - LED Night Mode Settings Retrieval (Priority: P1)

As a user, I want to view my current LED night mode settings so that I can see whether night mode is enabled and what hours it covers.

**Why this priority**: Reading settings is the most fundamental operation - users need to see current state before making changes.

**Independent Test**: Navigate to node detail page and verify LED night mode status displays correctly (On, Off, or Night Mode with time range).

**Acceptance Scenarios**:

1. **Given** the router has night mode enabled (8PM-8AM), **When** I view node details, **Then** I see "Night Mode" status with "8PM - 8AM" displayed
2. **Given** the router has LED always off, **When** I view node details, **Then** I see "Off" status displayed
3. **Given** the router has LED always on, **When** I view node details, **Then** I see "On" status displayed
4. **Given** a network error occurs during fetch, **When** the system retries, **Then** appropriate error handling occurs without crashing

---

### User Story 3 - LED Night Mode Settings Update (Priority: P1)

As a user, I want to change my LED night mode settings so that I can control when my router's LED lights are on or off.

**Why this priority**: Equal priority with retrieval - both read and write operations are essential for the feature to be useful.

**Independent Test**: Toggle night mode setting in dashboard quick panel and verify the change persists after page refresh.

**Acceptance Scenarios**:

1. **Given** I am on the dashboard, **When** I enable night mode, **Then** the setting is saved and LED behavior changes to night mode (off 8PM-8AM)
2. **Given** I am on the node detail page, **When** I set LED to always off, **Then** the setting persists and status shows "Off"
3. **Given** a network error occurs during save, **When** the operation fails, **Then** an appropriate error message is displayed and state remains unchanged

---

### Edge Cases

- What happens when the router is unreachable during settings fetch? System should handle timeout gracefully and show cached/default state.
- What happens when save operation fails mid-way? State should rollback to previous value, not leave in inconsistent state.
- What happens when authentication expires during operation? Service should throw UnauthorizedError for Provider to handle.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a stateless NodeLightSettingsService class that encapsulates all JNAP communication for LED settings
- **FR-002**: Service MUST implement `fetchSettings()` method to retrieve current LED night mode settings from the router
- **FR-003**: Service MUST implement `saveSettings(NodeLightSettings settings)` method to persist LED settings to the router
- **FR-004**: Service MUST map all JNAP errors to appropriate ServiceError types (UnauthorizedError, UnexpectedError)
- **FR-005**: NodeLightSettingsNotifier MUST delegate all JNAP operations to NodeLightSettingsService
- **FR-006**: NodeLightSettingsNotifier MUST NOT import any JNAP action or router repository modules directly
- **FR-007**: The `currentStatus` getter MUST remain in the Provider layer as UI transformation logic
- **FR-008**: Service MUST use constructor injection for RouterRepository dependency
- **FR-009**: Service MUST be provided via Riverpod Provider for dependency injection
- **FR-010**: All Service methods MUST have comprehensive unit tests with mocked RouterRepository
- **FR-011**: All Provider methods MUST have unit tests verifying delegation to Service

### Key Entities

- **NodeLightSettings**: Represents LED night mode configuration with properties: isNightModeEnable, startHour, endHour, allDayOff
- **NodeLightStatus**: UI enum (on, off, night) derived from NodeLightSettings for display purposes
- **NodeLightSettingsService**: Stateless service handling JNAP communication for LED settings
- **NodeLightSettingsNotifier**: Riverpod Notifier managing state and delegating to Service

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Zero JNAP action imports in `node_light_settings_provider.dart` (verified by grep)
- **SC-002**: Zero router_repository imports in `node_light_settings_provider.dart` (verified by grep)
- **SC-003**: All existing LED settings functionality works identically after refactor (no user-facing changes)
- **SC-004**: Service layer unit test coverage ≥90%
- **SC-005**: Provider layer unit test coverage ≥85%
- **SC-006**: `flutter analyze` passes with no errors on affected files
- **SC-007**: All existing tests continue to pass after refactor

## Assumptions

- The existing NodeLightSettings model class is adequate and does not need modification
- The currentStatus getter logic is UI-specific and appropriately belongs in Provider layer
- Error handling follows the established ServiceError pattern used in other services
- The fetch-after-save pattern (calling fetch after save to sync state) should be preserved

## Out of Scope

- Modifying the NodeLightSettings data model
- Adding new LED settings features (e.g., custom schedules)
- UI changes - this is purely a backend refactoring task
- Changes to other providers or services
