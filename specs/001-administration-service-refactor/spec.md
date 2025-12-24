# Feature Specification: AdministrationSettingsService Extraction Refactor

**Feature Branch**: `001-administration-service-refactor`
**Created**: 2024-12-03
**Status**: Draft
**Input**: Refactor AdministrationSettingsNotifier to extract JNAP actions and data models into AdministrationSettingsService

## Overview

This refactor improves code maintainability by separating the Provider layer concerns from data-fetching and JNAP coordination logic in `AdministrationSettingsNotifier`. The new `AdministrationSettingsService` will handle JNAP action orchestration and data model transformation, following the Clean Architecture principles defined in the project constitution.

## User Scenarios & Testing

### Developer Story 1 - Cleaner Service Layer (Priority: P1)

As a developer maintaining the administration settings feature, I need the data-fetching logic extracted from the Notifier so that:
- JNAP actions and commands are managed in a dedicated service layer
- The Notifier focuses only on state management and UI concerns
- Data transformation logic is centralized and testable independently

**Why this priority**: This is the core refactor goal that enables all other improvements. It directly supports the project constitution's Clean Architecture and Adapter Pattern principles.

**Independent Test**: The service can be unit tested in isolation by providing mock JNAP responses and verifying correct data model instantiation without requiring Provider/Notifier setup.

**Acceptance Scenarios**:

1. **Given** AdministrationSettingsService is created, **When** calling `fetchAdministrationSettings()`, **Then** the service returns parsed data models (ManagementSettings, UPnPSettings, ALGSettings, ExpressForwardingSettings) with proper error handling

2. **Given** the JNAP transaction is called with the required actions, **When** responses are received, **Then** data is correctly mapped to domain models

3. **Given** a network error occurs during JNAP transaction, **When** the service processes it, **Then** it returns a meaningful failure indicating which action failed

---

### Developer Story 2 - Improved Testability (Priority: P1)

As a test engineer, I need JNAP logic extracted so that:
- Service tests can mock router repository without provider overhead
- Notifier tests can mock the service layer
- Each layer has clear, isolated test boundaries

**Why this priority**: Testability is essential for maintaining the 80%+ code coverage requirement from the constitution. Direct JNAP mocking in Notifier tests is cumbersome and violates layering principles.

**Independent Test**: Can be validated by creating unit tests for the service layer that inject mock `RouterRepository` and verify transformation logic without any Provider dependencies.

**Acceptance Scenarios**:

1. **Given** a mock RouterRepository providing JNAP transaction results, **When** AdministrationSettingsService processes them, **Then** correct domain models are created

2. **Given** unit tests for the service layer, **When** they run, **Then** test execution time is <100ms per test (no Provider overhead)

---

### Developer Story 3 - Reusability & Consistency (Priority: P2)

As a developer building new administration features, I need the service to be reusable so that:
- Multiple Providers/Notifiers can request the same data without duplication
- Future refactors follow the same pattern for consistency
- Service responsibilities are clear and minimal

**Why this priority**: Enables future maintainability and consistency across the codebase. Sets a template for other similar refactors.

**Independent Test**: Verified by implementing a second small feature (e.g., fetching a subset of administration settings) that reuses the service without modification, proving the abstraction is correct.

**Acceptance Scenarios**:

1. **Given** AdministrationSettingsService is extracted, **When** another component needs administration data, **Then** it can directly use the service without duplicating JNAP logic

2. **Given** the service interface is stable, **When** future refactors follow this pattern, **Then** code consistency is achieved

---

### Edge Cases

- What happens if one of the four JNAP actions (getManagementSettings, getUPnPSettings, getALGSettings, getExpressForwardingSettings) returns an error while others succeed?
- How does the service handle missing or unexpected fields in JNAP responses?
- What is the behavior if the RouterRepository is not available when the service is called?

## Requirements

### Functional Requirements

- **FR-001**: AdministrationSettingsService MUST orchestrate four JNAP actions (getManagementSettings, getUPnPSettings, getALGSettings, getExpressForwardingSettings) in a single coordinated transaction
- **FR-002**: AdministrationSettingsService MUST parse JNAP responses and instantiate domain models: ManagementSettings, UPnPSettings, ALGSettings, ExpressForwardingSettings
- **FR-003**: AdministrationSettingsService MUST accept optional parameters to control caching behavior (forceRemote, updateStatusOnly)
- **FR-004**: AdministrationSettingsService MUST return parsed data models or failure indicators with clear error context
- **FR-005**: AdministrationSettingsNotifier MUST delegate data-fetching to AdministrationSettingsService in the `performFetch()` method
- **FR-006**: AdministrationSettingsNotifier MUST continue managing state via PreservableNotifierMixin without changes to external behavior
- **FR-007**: All JNAP action constants and imports MUST be moved to the service layer
- **FR-008**: Data model instantiation (ManagementSettings.fromMap, UPnPSettings.fromMap, etc.) MUST be centralized in the service

### Key Entities

- **AdministrationSettingsService**: Handles JNAP transaction orchestration and data model transformation. Accepts RouterRepository dependency. Returns structured data or failures.
- **AdministrationSettings (Aggregate)**: Composed of ManagementSettings, UPnPSettings, ALGSettings, ExpressForwardingSettings. Currently in Notifier; remains unchanged externally.
- **JNAPTransactionBuilder**: Existing JNAP coordination utility. Service will encapsulate transaction building logic.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Service layer is extracted into a separate file (`administration_settings_service.dart`) with clear, testable public interface
- **SC-002**: AdministrationSettingsNotifier `performFetch()` is reduced by ≥50% in lines of code (from ~150+ lines to <75) via delegation to service
- **SC-003**: Unit tests for AdministrationSettingsService achieve ≥90% code coverage with execution time <100ms per test suite
- **SC-004**: Existing UI and test suites pass without modification (backward compatibility maintained)
- **SC-005**: JNAP-related imports (JNAPAction, JNAPTransaction, etc.) are eliminated from Notifier file and consolidated in service
- **SC-006**: Service is usable by other components that need administration data (verified by code review)

## Assumptions

- The existing PreservableNotifierMixin interface and state management logic remain unchanged in functionality
- All four JNAP actions will be bundled in a single transaction (no separate sequential calls)
- Error handling strategy for partial failures (3/4 actions succeed) will follow existing patterns in the codebase
- The service will be injected via provider dependency (ref.read) rather than constructor injection
- No breaking changes to the external API of AdministrationSettingsNotifier

## Out of Scope

- Changes to state structure or UI layer behavior
- Migration of other Notifiers to similar service layers (can be future refactors)
- Changes to JNAP command definitions or action constants
- Performance optimization of JNAP transaction processing
