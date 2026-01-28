# Feature Specification: InstantSafety Service Extraction

**Feature Branch**: `004-instant-safety-service`
**Created**: 2025-12-22
**Status**: Draft
**Input**: User description: "Extract InstantSafetyService from InstantSafetyNotifier to enforce three-layer architecture compliance"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Maintain Architecture Compliance (Priority: P1)

The InstantSafety feature currently violates the three-layer architecture by having the Provider layer directly import and use JNAP models. Developers need the codebase to follow consistent architectural patterns where Service layer handles all data source communication.

**Why this priority**: This is the core purpose of the refactoring - ensuring architecture compliance enables maintainability, testability, and future data source migrations without impacting upper layers.

**Independent Test**: Can be verified by running architecture compliance checks that confirm no JNAP model imports exist in the Provider layer.

**Acceptance Scenarios**:

1. **Given** the InstantSafetyNotifier class, **When** checking its imports, **Then** no imports from `core/jnap/models/` should exist
2. **Given** the InstantSafetyNotifier class, **When** checking its imports, **Then** no imports from `core/jnap/result/` should exist
3. **Given** the InstantSafetyNotifier class, **When** checking error handling, **Then** only ServiceError types should be caught (not JNAPError)

---

### User Story 2 - Fetch Safe Browsing Settings (Priority: P1)

Users can view the current safe browsing configuration (Fortinet, OpenDNS, or Off) through the InstantSafety feature. The Service must fetch LAN settings and determine the active safe browsing type based on DNS server configuration.

**Why this priority**: This is the primary read operation for the feature - users need to see their current configuration.

**Independent Test**: Can be tested by calling the service fetch method and verifying it returns correct safe browsing type based on mocked JNAP responses.

**Acceptance Scenarios**:

1. **Given** the router has Fortinet DNS servers configured, **When** fetching settings, **Then** the service returns `InstantSafetyType.fortinet`
2. **Given** the router has OpenDNS servers configured, **When** fetching settings, **Then** the service returns `InstantSafetyType.openDNS`
3. **Given** the router has no safe browsing DNS configured, **When** fetching settings, **Then** the service returns `InstantSafetyType.off`
4. **Given** the JNAP call fails, **When** fetching settings, **Then** the service throws a ServiceError

---

### User Story 3 - Save Safe Browsing Settings (Priority: P1)

Users can change their safe browsing provider (Fortinet, OpenDNS, or disable). The Service must transform the selected option into the appropriate DHCP/DNS settings and persist them via JNAP.

**Why this priority**: This is the primary write operation - users need to actually change their configuration.

**Independent Test**: Can be tested by calling the service save method with different safe browsing types and verifying correct JNAP payloads are constructed.

**Acceptance Scenarios**:

1. **Given** user selects Fortinet, **When** saving settings, **Then** the service constructs DHCP settings with Fortinet DNS servers and saves via JNAP
2. **Given** user selects OpenDNS, **When** saving settings, **Then** the service constructs DHCP settings with OpenDNS servers and saves via JNAP
3. **Given** user disables safe browsing, **When** saving settings, **Then** the service clears DNS servers from DHCP settings and saves via JNAP
4. **Given** the JNAP save call fails, **When** saving settings, **Then** the service throws an appropriate ServiceError

---

### User Story 4 - Check Fortinet Compatibility (Priority: P2)

The system determines whether the router hardware/firmware supports Fortinet safe browsing based on device information and a compatibility map.

**Why this priority**: This is supplementary functionality that determines which options are available to users.

**Independent Test**: Can be tested by mocking device info responses and verifying Fortinet availability logic.

**Acceptance Scenarios**:

1. **Given** a router model that supports Fortinet, **When** checking compatibility, **Then** the service indicates Fortinet is available
2. **Given** a router model that does not support Fortinet, **When** checking compatibility, **Then** the service indicates Fortinet is unavailable
3. **Given** device info is unavailable, **When** checking compatibility, **Then** the service defaults to Fortinet unavailable

---

### Edge Cases

- What happens when LAN settings are not available during save? Service should throw appropriate error
- How does the system handle partial DNS server configuration (only 1 of 3 servers set)?
- What happens when the compatibility map is empty? Service defaults to no Fortinet support

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST create InstantSafetyService class that encapsulates all JNAP communication for the InstantSafety feature
- **FR-002**: InstantSafetyService MUST handle `getLANSettings` JNAP action and transform response to UI-appropriate data
- **FR-003**: InstantSafetyService MUST handle `setLANSettings` JNAP action to persist safe browsing configuration
- **FR-004**: InstantSafetyService MUST convert all JNAPError exceptions to appropriate ServiceError types
- **FR-005**: InstantSafetyService MUST determine safe browsing type by comparing DNS server values against known provider configurations
- **FR-006**: InstantSafetyService MUST check device compatibility for Fortinet support using device info and compatibility rules
- **FR-007**: InstantSafetyNotifier MUST delegate all JNAP operations to InstantSafetyService
- **FR-008**: InstantSafetyNotifier MUST NOT import any `core/jnap/models/` modules after refactoring
- **FR-009**: InstantSafetyNotifier MUST NOT import `core/jnap/result/` after refactoring
- **FR-010**: InstantSafetyNotifier MUST only catch and handle ServiceError types (not JNAPError)
- **FR-011**: InstantSafetyState MUST NOT contain any JNAP model types in its public interface (the `RouterLANSettings` dependency in `InstantSafetyStatus` must be removed or replaced with UI-appropriate types)

### Key Entities

- **InstantSafetyService**: Stateless service class handling JNAP communication for safe browsing settings
- **InstantSafetySettings**: User-modifiable settings containing the selected safe browsing type
- **InstantSafetyStatus**: Read-only status containing Fortinet availability and any required LAN settings data (refactored to not expose JNAP models)
- **InstantSafetyType**: Enum representing safe browsing options (off, fortinet, openDNS)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Architecture compliance checks pass - no JNAP model imports in Provider layer for InstantSafety feature
- **SC-002**: All existing functionality preserved - users can view and change safe browsing settings without regression
- **SC-003**: Service layer test coverage reaches minimum 90% for InstantSafetyService
- **SC-004**: Provider layer test coverage reaches minimum 85% for InstantSafetyNotifier
- **SC-005**: All JNAP errors are mapped to ServiceError types - no JNAPError leakage to Provider layer

## Assumptions

- The existing `PreservableNotifierMixin` pattern will continue to be used for dirty state management
- DNS server IP addresses for Fortinet (208.91.114.155) and OpenDNS (208.67.222.123, 208.67.220.123) are fixed and do not require configuration
- The compatibility map for Fortinet support (currently empty) will remain managed within the service layer
- The InstantSafety feature currently has no unit tests, so new tests will be created from scratch
