## ADDED Requirements

### Requirement: Local Network Settings State Management
The system SHALL manage the Local Network Settings using the standardized dirty-guard framework, ensuring automatic detection of unsaved changes and consistent handling of navigation.

#### Scenario: Modify Local Network settings and save
- **GIVEN** the user is on the Local Network Settings page.
- **WHEN** the user modifies a setting (e.g., changes the IP address).
- **AND** the user clicks the page-level "Save" button.
- **THEN** the changes SHALL be persisted.
- **AND** the page's dirty state SHALL be cleared.

#### Scenario: Attempt to navigate away with unsaved changes
- **GIVEN** the user has modified a setting on the Local Network Settings page, making it "dirty".
- **WHEN** the user attempts to navigate away from the page.
- **THEN** a confirmation dialog SHALL be displayed, asking the user to save, discard, or cancel the navigation.

### Requirement: Exclude DHCP Reservation List from Dirty Check
The system SHALL exclude changes to the DHCP reservation list from triggering the dirty state for the Local Network Settings feature.

#### Scenario: Changing DHCP reservation list does not make the page dirty
- **GIVEN** the user is on the Local Network Settings page, and no other changes have been made.
- **WHEN** the user modifies the DHCP reservation list (e.g., adds or removes a reservation).
- **THEN** the page SHALL NOT be marked as "dirty".
- **AND** the save button SHALL remain disabled.

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