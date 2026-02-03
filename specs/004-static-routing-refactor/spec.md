# Feature Specification: Static Routing Module Refactor

**Feature Branch**: `004-static-routing-refactor`
**Created**: 2025-12-12
**Status**: Draft
**Input**: User description: "Refactor lib/page/advanced_settings/static_routing according to constitution.md"

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.
  
  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently
-->

### User Story 1 - Network Administrator Manages Static Routes (Priority: P1)

A network administrator needs to configure static routing rules on their Linksys device. They can view all existing routes, understand the device's routing network configuration (NAT vs Dynamic Routing), add new routes, edit existing routes, and save changes with proper error handling.

**Why this priority**: This is the core functionality of the module. Without this working properly, the feature delivers no value. All other functionality depends on this baseline working correctly.

**Independent Test**: Can be fully tested by opening the static routing settings, viewing the route list, creating a new route, and verifying it appears in the list. This demonstrates the feature's core capability.

**Acceptance Scenarios**:

1. **Given** the device is connected and routing settings are loaded, **When** the network administrator navigates to Static Routing settings, **Then** they see all existing static routes and the current routing network mode (NAT enabled/disabled, Dynamic Routing enabled/disabled)
2. **Given** the route list is displayed, **When** the administrator selects to edit a route, **Then** they can modify destination IP, subnet mask, gateway, and route name, and save changes
3. **Given** the administrator has unsaved changes to routes, **When** they navigate away, **Then** the system either prompts to save or preserves changes (dirty guard)
4. **Given** a save operation fails (network error, device error), **When** the administrator attempts to save, **Then** they see a user-friendly error message and can retry

---

### User Story 2 - Create and Validate New Static Routes (Priority: P2)

The administrator can add new static routes with automatic validation ensuring routes are valid before being saved. The system validates IP addresses, subnet masks, gateway addresses, and enforces device-specific limits like maximum number of routes.

**Why this priority**: This enables users to actually create new routes, which extends the core functionality to the full use case. Validation ensures data integrity on the device.

**Independent Test**: Can be tested by attempting to add a new route with valid and invalid data, verifying that validation messages appear and preventing invalid entries from being saved.

**Acceptance Scenarios**:

1. **Given** the maximum route limit hasn't been reached, **When** the administrator adds a new route with valid IP/subnet/gateway addresses, **Then** the route is added to the current list
2. **Given** the administrator has reached the maximum route limit for their device, **When** they attempt to add another route, **Then** they see a message indicating the limit is reached and cannot add more routes
3. **Given** invalid IP addresses (malformed format, invalid subnet), **When** the administrator attempts to save, **Then** validation errors are displayed and the route is not saved
4. **Given** a route with the same destination already exists, **When** the administrator attempts to save a duplicate, **Then** the system either prevents it or allows it based on device capability

---

### User Story 3 - Switch Routing Network Mode (Priority: P2)

The administrator can toggle between NAT and Dynamic Routing modes. The system provides clear indication of the current mode and any implications of switching modes.

**Why this priority**: This is an important configuration option but secondary to managing routes. It provides value but isn't blocking for basic route management.

**Independent Test**: Can be tested by selecting different routing modes and verifying the selection is saved and reflected in the UI.

**Acceptance Scenarios**:

1. **Given** routing settings are loaded, **When** the administrator selects a different routing mode (NAT vs Dynamic Routing), **Then** the UI reflects the selection
2. **Given** the administrator has changed the routing mode, **When** they save changes, **Then** the mode change is persisted on the device
3. **Given** a routing mode change fails, **When** the save operation encounters an error, **Then** the previous mode is restored or an error message is shown

---

### User Story 4 - Delete and Manage Existing Routes (Priority: P3)

The administrator can delete existing routes, view route details (destination, subnet, gateway, name), and see network context information like the router's IP and subnet mask.

**Why this priority**: Route deletion is necessary for full management capability but is less critical than creation and is often used less frequently.

**Independent Test**: Can be tested by selecting a route, deleting it, and verifying it no longer appears in the list.

**Acceptance Scenarios**:

1. **Given** routes exist in the list, **When** the administrator selects a route to delete, **Then** the route is removed from the list and the device (after save)
2. **Given** a delete operation fails, **When** the administrator attempts to delete, **Then** they see an error message and the route remains

### Edge Cases

- What happens when the device reports a maximum route limit of 0 (no routes supported)?
- How does the system handle receiving malformed routing settings from the device (missing required fields, invalid data types)?
- What happens if the user switches devices mid-editing (another device is selected before save)?
- How does the system handle when the device supports dynamic features but restricts certain configurations (e.g., can't enable NAT and dynamic routing simultaneously)?
- What happens when the route list contains more entries than the device claims is the maximum (data inconsistency)?

## Requirements *(mandatory)*

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right functional requirements.
-->

### Functional Requirements

**Architecture & Code Organization**:

- **FR-001**: System MUST enforce three-layer architecture with clear separation between Presentation (views), Application (providers/services), and Data (JNAP models) layers
- **FR-002**: System MUST have a dedicated Service layer (`StaticRoutingService`) that handles all JNAP protocol communication and data transformation
- **FR-003**: System MUST have UI models (`StaticRoutingUISettings`, `StaticRouteEntryUI`) that isolate the Presentation layer from JNAP data models
- **FR-004**: System MUST ensure Providers only depend on Service layer, never directly on JNAP models or Repository
- **FR-005**: System MUST ensure Views only depend on Providers and UI models, never on JNAP models

**Data Management**:

- **FR-006**: System MUST fetch routing settings (routes, NAT enabled, dynamic routing enabled) from the device via JNAP protocol
- **FR-007**: System MUST fetch network context (router IP, subnet mask) from device LAN settings to display to users
- **FR-008**: System MUST save routing configuration changes back to the device via JNAP protocol
- **FR-009**: System MUST validate all route data (destination IP, subnet mask, gateway, name) before persisting to device
- **FR-010**: System MUST support maximum route entry limit enforcement from device

**State Management**:

- **FR-011**: System MUST use `PreservableNotifierMixin` to support undo/reset (dirty guard) for unsaved changes
- **FR-012**: System MUST track original (device) vs current (edited) state separately
- **FR-013**: System MUST provide methods to add, edit, delete routes in current state
- **FR-014**: System MUST update "original" state to match "current" after successful save (commit operation)

**Error Handling**:

- **FR-015**: System MUST handle JNAP communication failures gracefully with appropriate error messages
- **FR-016**: System MUST validate routes before sending to device and show validation errors to user
- **FR-017**: System MUST handle device rejecting invalid configurations with user-friendly error messages

**Testing**:

- **FR-018**: System MUST have comprehensive unit tests for Service layer with mocked dependencies
- **FR-019**: System MUST have unit tests for Provider state management (add/edit/delete routes)
- **FR-020**: System MUST have test data builders following the constitution pattern
- **FR-021**: System MUST have screenshot tests for the UI views

### Key Entities

- **StaticRoutingUISettings**: Application layer model containing NAT/dynamic routing flags and route entries (UI-specific representation, never contains JNAP models)
- **StaticRouteEntryUI**: UI representation of a single route with destination IP, subnet mask, gateway, and description
- **StaticRoutingStatus**: Status information including max route entries, router IP, and subnet mask for display context
- **GetRoutingSettings**: Data layer (JNAP) model with device routing configuration (this should NOT appear in Provider/View layers after refactor)
- **SetRoutingSettings**: Data layer (JNAP) model for sending routing configuration to device

## Success Criteria *(mandatory)*

<!--
  ACTION REQUIRED: Define measurable success criteria.
  These must be technology-agnostic and measurable.
-->

### Measurable Outcomes

- **SC-001**: All JNAP model imports are removed from Provider and View layers (0 JNAP model imports in `providers/` and views except in Service layer)
- **SC-002**: Service layer (`StaticRoutingService`) handles 100% of JNAP communication and transformation logic
- **SC-003**: All business logic is independently unit testable by mocking `RouterRepository` (no direct JNAP calls in tests)
- **SC-004**: Test coverage for Service layer ≥90%, Provider state management ≥85%, overall ≥80%
- **SC-005**: All public methods in Service and Provider classes have DartDoc documentation
- **SC-006**: Zero lint warnings introduced by refactoring (`flutter analyze` passes)
- **SC-007**: All existing UI functionality remains unchanged (backward compatible with views)
- **SC-008**: Route management operations (add/edit/delete) maintain consistency between UI and device state
- **SC-009**: Users can recover from errors (edit errors don't lose data, save errors allow retry)
- **SC-010**: Network context (router IP, subnet mask) is correctly displayed based on device LAN settings

## Assumptions

- The maximum route entry limit is a fixed device capability (doesn't change per route, but may vary by device model)
- Route validation rules (IP format, subnet mask format, etc.) follow standard IPv4 conventions unless device specifies otherwise
- Users have proper network knowledge to configure static routes (no in-app routing tutorials; error messages guide configuration)
- The existing UI components (views, widgets, dialogs) are stable and don't need modification
- Performance is not a constraint (route lists typically < 50 entries)
- The module continues to use `PreservableNotifierMixin` for dirty guard functionality

## Out of Scope

- Changes to the UI/View components (static_routing_view.dart, static_routing_rule_view.dart)
- Changes to JNAP model definitions (GetRoutingSettings, SetRoutingSettings)
- Supporting dynamic routing protocol (OSPF, RIP) - static routes only
- Supporting IPv6 static routes (IPv4 only in this refactor)
- Analytics or telemetry for route configuration changes
- API documentation beyond DartDoc comments

## Implementation Notes

### Current Architecture Issues

The current implementation has several violations of the constitution:

1. **Service Layer Missing**: Business logic (JNAP calls, data transformation) is directly in `StaticRoutingNotifier.performFetch()` and `performSave()` methods
2. **JNAP Models Exposed**: Provider directly imports and uses `GetRoutingSettings` and `SetRoutingSettings`
3. **No Abstraction**: No dedicated Service class to encapsulate JNAP interaction
4. **Limited Testing**: Current structure makes it difficult to unit test business logic independently
5. **Tight Coupling**: Providers are tightly coupled to JNAP protocol details

### Required Refactoring Steps

1. Create `StaticRoutingService` class in `services/` directory
2. Move JNAP communication logic from Provider to Service
3. Create UI models (`StaticRoutingUISettings`, `StaticRouteEntryUI`, `StaticRoutingStatus`) in Provider layer
4. Update Provider to use Service layer for all JNAP interactions
5. Add comprehensive unit tests for Service and Provider layers
6. Update DartDoc for all public methods
7. Verify Views layer has zero JNAP model imports
