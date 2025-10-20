## MODIFIED Requirements

### Requirement: Static Routing State Management
The system SHALL manage the Static Routing settings using the standardized dirty-guard framework, ensuring automatic detection of unsaved changes and consistent handling of navigation.

#### Scenario: Modify Static Routing settings and save
- **GIVEN** the user is on the Static Routing page.
- **WHEN** the user modifies a setting (e.g., adds a new static route).
- **AND** the user clicks the page-level "Save" button.
- **THEN** the changes SHALL be persisted.
- **AND** the page's dirty state SHALL be cleared.

#### Scenario: Attempt to navigate away with unsaved changes
- **GIVEN** the user has modified a setting on the Static Routing page, making it "dirty".
- **WHEN** the user attempts to navigate away from the page.
- **THEN** a confirmation dialog SHALL be displayed, asking the user to save, discard, or cancel the navigation.
