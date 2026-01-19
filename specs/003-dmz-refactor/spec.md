# Feature Specification: DMZ Settings Provider Refactor

**Feature Branch**: `002-dmz-refactor`
**Created**: 2025-12-08
**Status**: Draft
**Input**: User description: "根據憲章重構advanced_setting/dmz"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Developer Refactors DMZ Settings Service to Follow Three-Layer Architecture (Priority: P1)

As a developer maintaining the PrivacyGUI codebase, I need to refactor the DMZ Settings provider to follow the established three-layer architecture (Data → Application → Presentation) so that the codebase maintains consistent patterns and future developers can navigate and modify the DMZ functionality without encountering architectural violations.

**Why this priority**: This establishes the foundation for all other work. The three-layer architecture is a core constitutional principle of PrivacyGUI, and all new or refactored features must comply. Without this, the feature cannot meet the project's quality standards.

**Independent Test**: Can be fully tested by running the test suite for the refactored DMZ Service, Provider, and State layers and verifying that all JNAP code is isolated in the Service layer with 0 imports in the Provider layer. This delivers a maintainable, standards-compliant codebase foundation.

**Acceptance Scenarios**:

1. **Given** the existing DMZ settings provider has JNAP protocol code embedded in the Notifier, **When** the developer runs the refactored service layer tests, **Then** the Service layer correctly parses all DMZ configurations (isEnabled, appVisibility, portRanges, etc.) with ≥90% coverage

2. **Given** a DMZ Service layer with full functionality, **When** the Provider layer calls the Service, **Then** the Notifier correctly delegates fetch/save operations without containing any JNAP imports or protocol details

3. **Given** refactored code, **When** running `flutter analyze` on the DMZ module, **Then** 0 warnings are raised and no circular dependencies exist

4. **Given** refactored State layer with serialization methods, **When** running State layer tests, **Then** all toMap/fromMap/toJson/fromJson operations pass with ≥90% coverage

---

### User Story 2 - Apply Test Data Builder Pattern to DMZ Service Tests (Priority: P1)

As a developer writing DMZ Service layer tests, I need to centralize mock JNAP responses into a dedicated TestData builder class so that test code is more readable, maintainable, and follows the patterns established in the constitution and proven in the Administration Settings refactor.

**Why this priority**: This is a critical pattern that reduces test code verbosity by ~70% and prevents mock data from obscuring business logic. Since this pattern is now part of the constitution, it must be applied consistently.

**Independent Test**: Can be fully tested by verifying that all 7+ DMZ Service tests use the DmzSettingsTestData builder, mock data code is reduced by 70%, and all tests pass with 0 lint warnings.

**Acceptance Scenarios**:

1. **Given** DMZ Service tests with repeated mock JNAP responses, **When** tests are refactored to use DmzSettingsTestData.createSuccessfulTransaction(), **Then** each test is reduced from 50+ lines to <15 lines with improved readability

2. **Given** error path tests, **When** using createPartialErrorTransaction() builder, **Then** error scenarios can be tested with minimal boilerplate

3. **Given** the TestData builder, **When** a test needs a partial configuration (e.g., only test port mapping), **Then** the builder's partial override pattern allows specifying just the needed fields while using sensible defaults for others

---

### User Story 3 - Validate DMZ Refactoring Against Constitution (Priority: P2)

As a project maintainer, I need to ensure the refactored DMZ provider adheres to all requirements in the constitution (v2.2) so that the refactor serves as a validation that the new testing patterns are effective and the constitution guidelines are clear enough for other developers to follow.

**Why this priority**: This validates that the constitution's new testing patterns (Section 6: Test Data Builder, Section 7: Three-Layer Testing) are practical and understandable. Early validation helps identify unclear guidelines before scaling to other modules.

**Independent Test**: Can be fully tested by using the constitution's checklists and validating that: (1) all three layers have complete tests, (2) mocktail is used for all mocking, (3) TestData builder is properly applied, and (4) coverage targets are met.

**Acceptance Scenarios**:

1. **Given** the completed DMZ refactor, **When** checking against the constitution's "三層測試實踐指南" section, **Then** Service layer has ≥90% coverage, Provider layer has ≥85% coverage, and State layer has ≥90% coverage

2. **Given** the constitution's "測試資料建構模式" section, **When** reviewing DMZ Service tests, **Then** all mock data is centralized in DmzSettingsTestData and no inline mock responses appear in tests (3+ reuse rule applied)

3. **Given** a completed refactor, **When** another developer tries to follow the same pattern for a different feature, **Then** the constitution guidance is clear and actionable (document any missing or ambiguous guidelines)

---

### Edge Cases

- What happens if the DMZ settings response includes new fields not yet handled by the Service layer?
- How does the system handle partial DMZ responses (e.g., port mapping succeeds but application visibility fails)?
- What happens if a DMZ configuration change is requested but the device is unreachable (network error)?
- How should the State layer handle null or missing DMZ settings from the API?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Service layer MUST extract all JNAP protocol code (JNAPAction, JNAPTransactionBuilder, request building) from the Provider layer into dedicated methods

- **FR-002**: The Service layer MUST implement `fetchDmzSettings()` method that parses JNAP responses into a unified `DmzSettings` data object, handling all DMZ-related configurations (enabled/disabled state, application visibility, port mappings, logging, etc.)

- **FR-003**: The Service layer MUST implement error handling to catch and contextualize JNAP failures with action-specific error messages

- **FR-004**: The Service layer MUST implement `saveDmzSettings()` method if DMZ write operations are supported, following the same patterns as fetch

- **FR-005**: The Provider layer (Notifier) MUST delegate all fetch/save operations to the Service layer without containing any JNAP imports or protocol-specific code

- **FR-006**: The Provider layer MUST manage state updates correctly, including success, loading, and error states

- **FR-007**: The State layer MUST implement a `DmzSettings` data model with immutability (Equatable), serialization (toMap/fromMap/toJson/fromJson), and copyWith operations

- **FR-008**: All Service layer tests MUST use mocktail for mocking RouterRepository and follow the TestData builder pattern centralized in `DmzSettingsTestData`

- **FR-009**: All tests MUST pass with 0 lint warnings and comply with `dart format` standards

- **FR-010**: The refactored code MUST maintain backward compatibility with the existing UI layer (no breaking changes to public APIs)

### Key Entities

- **DmzSettings**: Data model representing the complete DMZ configuration state (enabled, port mappings, application visibility, logging settings, etc.)

- **DmzSettingsService**: Service layer responsible for orchestrating JNAP calls and parsing responses into `DmzSettings`

- **DmzSettingsNotifier**: Provider layer Notifier managing state updates through the Service

- **DmzSettingsState**: Complete state object including both `DmzSettings` and status/error information

- **DmzSettingsTestData**: Centralized mock data builder for JNAP responses used across all Service layer tests

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Three-layer separation: 0 JNAP imports in Provider layer, 100% of protocol code isolated in Service layer (verifiable by `grep` or lint rules)

- **SC-002**: Test coverage: Service layer ≥90%, Provider layer ≥85%, State layer ≥90%, overall ≥80%

- **SC-003**: Code quality: `flutter analyze` returns 0 warnings, `dart format` shows no changes, all lint checks pass

- **SC-004**: Test data optimization: Mock data code reduced by ~70% compared to pre-builder tests, all 7+ Service tests use centralized TestData builder (verifiable by code review)

- **SC-005**: Constitution validation: All requirements in constitution v2.2 Section 6 (Test Data Builder) and Section 7 (Three-Layer Testing) are satisfied

- **SC-006**: Backward compatibility: All existing UI tests that reference DMZ settings continue to pass after refactoring (0 breaking changes)

## Assumptions

- The existing DMZ settings functionality will remain logically unchanged; this is purely a refactoring for architectural compliance
- The JNAP protocol structure for DMZ settings is stable (no major protocol changes during refactoring)
- The constitution v2.2 patterns (Test Data Builder, three-layer testing) are final and won't require major changes
- The refactored DMZ settings will be used as a validation case for the constitution patterns; if the patterns prove unclear or unworkable, it will inform v2.3 updates
- State serialization format (toMap/fromMap/toJson/fromJson) will be compatible with existing persistence mechanisms

## Scope & Constraints

### In Scope

- Refactor existing DMZ settings provider to follow three-layer architecture
- Create Service layer with full JNAP orchestration
- Create comprehensive test suite (Service, Provider, State layers)
- Apply Test Data Builder pattern to all Service tests
- Validate against constitution v2.2 requirements
- Document any constitution patterns that need clarification for future refactors

### Out of Scope

- Creating new DMZ features or changing existing functionality
- Refactoring other advanced settings providers (Administration, WiFi, etc.) - those are separate features
- Modifying the JNAP protocol itself
- Updating the UI/presentation layer beyond what's necessary for backward compatibility
- Rewriting the constitution (only documenting clarifications needed)

## Dependencies & Integration Points

- **Constitution v2.2**: Must follow Section 6 (Test Data Builder Pattern) and Section 7 (Three-Layer Testing Practice Guide)
- **UnitTestHelper**: Uses existing test infrastructure from `test/common/unit_test_helper.dart`
- **Existing DMZ UI**: Must maintain API compatibility with current UI layer
- **JNAP Protocol**: Uses existing RouterRepository and JNAP transaction infrastructure
