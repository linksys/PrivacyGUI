## MODIFIED Requirements

### Requirement: Firewall Settings State Management
The system SHALL manage the Firewall Settings using the standardized dirty-guard framework, ensuring automatic detection of unsaved changes and consistent handling of navigation.

#### Scenario: Modify Firewall settings and save
- **GIVEN** the user is on the Firewall page.
- **WHEN** the user modifies a setting (e.g., enables a firewall rule).
- **AND** the user clicks the page-level "Save" button.
- **THEN** the changes SHALL be persisted.
- **AND** the page's dirty state SHALL be cleared.

#### Scenario: Attempt to navigate away with unsaved changes
- **GIVEN** the user has modified a setting on the Firewall page, making it "dirty".
- **WHEN** the user attempts to navigate away from the page.
- **THEN** a confirmation dialog SHALL be displayed, asking the user to save, discard, or cancel the navigation.
