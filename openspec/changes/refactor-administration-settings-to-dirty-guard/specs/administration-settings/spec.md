## MODIFIED Requirements

### Requirement: Administration Settings State Management
The system SHALL manage the Administration Settings using the standardized dirty-guard framework, ensuring automatic detection of unsaved changes and consistent handling of navigation.

#### Scenario: Modify Administration settings and save
- **GIVEN** the user is on the Administration Settings page.
- **WHEN** the user modifies a setting (e.g., changes the admin password).
- **AND** the user clicks the page-level "Save" button.
- **THEN** the changes SHALL be persisted.
- **AND** the page's dirty state SHALL be cleared.

#### Scenario: Attempt to navigate away with unsaved changes
- **GIVEN** the user has modified a setting on the Administration Settings page, making it "dirty".
- **WHEN** the user attempts to navigate away from the page.
- **THEN** a confirmation dialog SHALL be displayed, asking the user to save, discard, or cancel the navigation.
