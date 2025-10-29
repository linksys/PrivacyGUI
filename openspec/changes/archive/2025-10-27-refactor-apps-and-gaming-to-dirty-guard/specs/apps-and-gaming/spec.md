## ADDED Requirements

### Requirement: Apps and Gaming Settings State Management
The system SHALL manage the Apps and Gaming Settings using the standardized dirty-guard framework, ensuring automatic detection of unsaved changes and consistent handling of navigation across all sub-features (DDNS, Single Port Forwarding, Port Range Forwarding, Port Range Triggering).

#### Scenario: Modify Apps and Gaming settings and save
- **GIVEN** the user is on the Apps and Gaming page.
- **WHEN** the user modifies a setting in any sub-feature (e.g., enables a DDNS provider, adds a port forwarding rule).
- **AND** the user clicks the page-level "Save" button.
- **THEN** the changes SHALL be persisted for all modified sub-features.
- **AND** the page's dirty state SHALL be cleared.

#### Scenario: Attempt to navigate away with unsaved changes
- **GIVEN** the user has modified a setting on the Apps and Gaming page, making it "dirty".
- **WHEN** the user attempts to navigate away from the page.
- **THEN** a confirmation dialog SHALL be displayed, asking the user to save, discard, or cancel the navigation.

## ADDED Requirements

### Requirement: Visual Feedback for Operations
The system SHALL display a loading spinner during `save` and `fetch` operations to provide visual feedback to the user.

#### Scenario: Saving changes
- **GIVEN** the user has modified a setting.
- **WHEN** the user initiates a save operation.
- **THEN** a loading spinner SHALL be displayed while the operation is in progress.
- **AND** the spinner SHALL be dismissed upon completion.

#### Scenario: Fetching data
- **GIVEN** the user navigates to a page that requires data fetching.
- **WHEN** the data fetch operation is initiated.
- **THEN** a loading spinner SHALL be displayed while the operation is in progress.
- **AND** the spinner SHALL be dismissed upon completion.
