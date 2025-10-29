## Purpose
This specification defines the requirements for the Wi-Fi Settings feature, including its state management, dirty-checking behavior, and navigation guards.

## Requirements

### Requirement: Unified State Management for Wi-Fi Settings
The system SHALL manage all Wi-Fi settings (Main/Guest, Advanced, and MAC Filtering) as a single, cohesive unit, ensuring that changes made across different tabs are tracked together.

#### Scenario: Modify Multiple Tabs and Save
- **GIVEN** the user is on the Wi-Fi Settings page.
- **WHEN** the user changes the Wi-Fi name on the "Wi-Fi" tab, then switches to the "Advanced" tab and enables Client Steering.
- **AND** the user clicks the main "Save" button on the page.
- **THEN** both the Wi-Fi name change and the Client Steering setting SHALL be persisted in a single save operation.
- **AND** the page's dirty state SHALL be cleared.

### Requirement: Unsaved Changes Navigation Guard
The system SHALL prevent the user from accidentally losing unsaved changes when navigating away from any tab within the Wi-Fi Settings page.

#### Scenario: Block Navigation on Dirty State
- **GIVEN** the user has modified a setting on any of the Wi-Fi Settings tabs, making the page "dirty".
- **WHEN** the user attempts to navigate away from the page (e.g., by clicking the browser's back button, using the main side menu, or clicking the back arrow in the top bar).
- **THEN** the system SHALL display a confirmation dialog asking if they want to discard their unsaved changes.

#### Scenario: Discard Changes and Proceed with Navigation
- **GIVEN** the unsaved changes confirmation dialog is displayed.
- **WHEN** the user confirms they want to discard their changes (e.g., clicks "OK" or "Discard").
- **THEN** all pending changes on all tabs SHALL be reverted to their last saved state.
- **AND** the original navigation action SHALL proceed.

#### Scenario: Cancel Navigation and Preserve Changes
- **GIVEN** the unsaved changes confirmation dialog is displayed.
- **WHEN** the user cancels the dialog (e.g., clicks "Cancel").
- **THEN** the user SHALL remain on the Wi-Fi Settings page.
- **AND** all pending changes SHALL be preserved, and the page SHALL remain in a "dirty" state.

### Requirement: Exclude `isSimpleMode` from Dirty Check
The system SHALL exclude changes to `wifilist.isSimpleMode` from triggering the dirty state for the Wi-Fi Settings feature.

#### Scenario: Changing `isSimpleMode` does not make the page dirty
- **GIVEN** the user is on the Wi-Fi Settings page, and no other changes have been made.
- **WHEN** the user toggles the `isSimpleMode` switch.
- **THEN** the page SHALL NOT be marked as "dirty".
- **AND** the save button SHALL remain disabled.

### Requirement: Tab-level Unsaved Changes Guard
The system SHALL prompt the user to save or discard changes before allowing navigation between tabs within the Wi-Fi Settings page.

#### Scenario: Attempt to switch tabs with unsaved changes
- **GIVEN** the user has made changes in the current tab of the Wi-Fi Settings page, making it "dirty".
- **WHEN** the user attempts to switch to another tab.
- **THEN** a confirmation dialog SHALL be displayed, asking the user to save, discard, or cancel the tab switch.

#### Scenario: Save changes and switch tabs
- **GIVEN** the tab-level confirmation dialog is displayed.
- **WHEN** the user chooses to save the changes.
- **THEN** all pending changes in the current tab SHALL be saved.
- **AND** the tab switch SHALL proceed to the selected tab.

#### Scenario: Discard changes and switch tabs
- **GIVEN** the tab-level confirmation dialog is displayed.
- **WHEN** the user chooses to discard the changes.
- **THEN** all pending changes in the current tab SHALL be reverted.
- **AND** the tab switch SHALL proceed to the selected tab.

#### Scenario: Cancel tab switch and remain on current tab
- **GIVEN** the tab-level confirmation dialog is displayed.
- **WHEN** the user chooses to cancel the tab switch.
- **THEN** the user SHALL remain on the current tab.
- **AND** all pending changes SHALL be preserved, and the tab SHALL remain in a "dirty" state.
