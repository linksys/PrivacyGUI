# Feature Specification: Extract InstantPrivacyService

**Feature Branch**: `001-instant-privacy-service`
**Created**: 2026-01-02
**Status**: Draft
**Input**: User description: "Extract InstantPrivacyService from InstantPrivacyNotifier to enforce three-layer architecture compliance"

## Overview

This is a **refactoring feature** to improve code architecture compliance. The InstantPrivacyNotifier currently violates the three-layer architecture by directly importing JNAP models, handling JNAP actions, and communicating with RouterRepository. This extraction creates a dedicated service layer to handle all JNAP communication, ensuring proper separation of concerns per constitution.md Articles V, VI, and XIII.

**Architectural Context**:
- **Current violation**: Provider layer imports `jnap/models`, `jnap/actions`, `jnap/command`
- **Target compliance**: Provider delegates to Service; Service handles JNAP; Provider only handles ServiceError

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Developer Maintains Architecture Compliance (Priority: P1)

As a developer working on the InstantPrivacy feature, I need the code to follow the three-layer architecture so that JNAP implementation details are isolated in the Service layer, making the codebase maintainable and testable.

**Why this priority**: This is the core purpose of the refactoring - ensuring architecture compliance enables all other benefits (testability, maintainability, future-proofing).

**Independent Test**: Can be fully tested by verifying that `instant_privacy_provider.dart` no longer imports any `jnap/models`, `jnap/actions`, or `jnap/command` packages, and all JNAP communication flows through `InstantPrivacyService`.

**Acceptance Scenarios**:

1. **Given** the refactored codebase, **When** I check imports in `instant_privacy_provider.dart`, **Then** there are no imports from `core/jnap/models/`, `core/jnap/actions/`, or `core/jnap/command/`
2. **Given** the InstantPrivacyNotifier, **When** it needs to fetch MAC filter settings, **Then** it delegates to InstantPrivacyService instead of calling RouterRepository directly
3. **Given** the InstantPrivacyNotifier, **When** it needs to save MAC filter settings, **Then** it delegates to InstantPrivacyService instead of calling RouterRepository directly

---

### User Story 2 - Service Handles JNAP Communication (Priority: P1)

As a developer, I need InstantPrivacyService to encapsulate all JNAP protocol details so that future changes to JNAP APIs only require changes in one place.

**Why this priority**: Equal to P1 because the service layer is essential for achieving architecture compliance.

**Independent Test**: Can be fully tested by verifying InstantPrivacyService correctly handles all four JNAP actions (getMACFilterSettings, getSTABSSIDs, setMACFilterSettings, getLocalDevice) and transforms data appropriately.

**Acceptance Scenarios**:

1. **Given** InstantPrivacyService, **When** fetchMacFilterSettings() is called, **Then** it returns InstantPrivacySettings and InstantPrivacyStatus (not raw JNAP data)
2. **Given** InstantPrivacyService, **When** saveMacFilterSettings() is called with InstantPrivacySettings, **Then** it transforms to JNAP format and sends to RouterRepository
3. **Given** InstantPrivacyService, **When** fetchMyMacAddress() is called, **Then** it returns the device's MAC address as a String

---

### User Story 3 - Error Handling Follows ServiceError Pattern (Priority: P2)

As a developer, I need JNAP errors to be converted to ServiceError types so that the Provider layer handles errors consistently without JNAP-specific knowledge.

**Why this priority**: Error handling is important for maintainability but secondary to the core data flow refactoring.

**Independent Test**: Can be tested by verifying that JNAPError exceptions thrown by RouterRepository are caught by the Service and converted to appropriate ServiceError subtypes.

**Acceptance Scenarios**:

1. **Given** a JNAP call fails in InstantPrivacyService, **When** the error is propagated, **Then** it is converted to a ServiceError subtype (not JNAPError)
2. **Given** InstantPrivacyNotifier receives an error from Service, **When** it handles the error, **Then** it only catches ServiceError types (no JNAPError handling)

---

### User Story 4 - Existing Functionality Preserved (Priority: P1)

As a user of the Instant Privacy feature, I need all existing functionality to work exactly as before so that the refactoring has no user-visible impact.

**Why this priority**: User functionality must not regress - this is a pure internal refactoring.

**Independent Test**: Can be tested by running existing tests and manually verifying MAC filter enable/disable, allow/deny mode switching, and device selection all work correctly.

**Acceptance Scenarios**:

1. **Given** the refactored code, **When** a user enables MAC filtering, **Then** the behavior is identical to the previous implementation
2. **Given** the refactored code, **When** a user adds devices to allow/deny list, **Then** the behavior is identical to the previous implementation
3. **Given** the refactored code, **When** a user saves MAC filter settings, **Then** the settings are persisted correctly

---

### Edge Cases

- What happens when getSTABSSIDs fails (device doesn't support it)? Service should return empty list gracefully.
- What happens when getLocalDevice fails (can't determine current device)? Service should return null for MAC address.
- What happens when JNAP returns unexpected data format? Service should throw appropriate ServiceError.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST create InstantPrivacyService class in `lib/page/instant_privacy/services/instant_privacy_service.dart`
- **FR-002**: InstantPrivacyService MUST provide `fetchMacFilterSettings()` method that returns a tuple of (InstantPrivacySettings?, InstantPrivacyStatus?)
- **FR-003**: InstantPrivacyService MUST provide `saveMacFilterSettings(InstantPrivacySettings, List<String> nodesMacAddresses)` method
- **FR-004**: InstantPrivacyService MUST provide `fetchMyMacAddress(String deviceId)` method returning String?
- **FR-005**: InstantPrivacyService MUST provide `fetchStaBssids()` method returning List<String>
- **FR-006**: InstantPrivacyService MUST convert all JNAPError exceptions to ServiceError subtypes
- **FR-007**: InstantPrivacyNotifier MUST delegate all JNAP operations to InstantPrivacyService
- **FR-008**: InstantPrivacyNotifier MUST NOT import any packages from `core/jnap/models/`, `core/jnap/actions/`, or `core/jnap/command/`
- **FR-009**: InstantPrivacyNotifier MUST only handle ServiceError types (not JNAPError)
- **FR-010**: All existing InstantPrivacy functionality MUST be preserved with identical behavior

### Key Entities

- **InstantPrivacyService**: Stateless service that handles all JNAP communication for MAC filtering feature. Depends on RouterRepository.
- **InstantPrivacySettings**: Existing UI model representing MAC filter configuration (mode, macAddresses, denyMacAddresses, etc.)
- **InstantPrivacyStatus**: Existing UI model representing current MAC filter status (mode only)
- **MACFilterSettings**: JNAP model (imported only in Service layer) representing raw API response

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: InstantPrivacyNotifier has zero imports from `core/jnap/models/`, `core/jnap/actions/`, or `core/jnap/command/` directories
- **SC-002**: InstantPrivacyService handles 100% of JNAP communication previously in InstantPrivacyNotifier
- **SC-003**: All existing unit tests for InstantPrivacy feature continue to pass
- **SC-004**: Architecture compliance check passes: `grep -r "import.*jnap/models" lib/page/instant_privacy/providers/` returns no results
- **SC-005**: Architecture compliance check passes: `grep -r "import.*jnap/actions" lib/page/instant_privacy/providers/` returns no results
- **SC-006**: New InstantPrivacyService has unit test coverage of at least 90%
- **SC-007**: InstantPrivacyNotifier test coverage remains at or above 85%

## Assumptions

- The existing InstantPrivacySettings and InstantPrivacyStatus classes are suitable as UI models and do not need modification
- The PreservableNotifierMixin pattern will continue to work with the service delegation approach
- The deviceManagerProvider can still be accessed from the Provider layer for getting node MAC addresses (this is acceptable as it's not JNAP-layer data)
- The serviceHelper.isSupportGetSTABSSID() check can be moved to the service or remain as a capability check
