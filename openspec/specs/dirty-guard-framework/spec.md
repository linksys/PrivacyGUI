## Purpose
This specification defines the architecture and usage guidelines for the Dirty State Navigation Guard Framework, which prevents accidental data loss during user navigation on pages with unsaved changes.

## Requirements

### Requirement: Automatic Dirty State Detection
The framework SHALL automatically detect if a page's state has been modified but not yet saved.

#### Scenario: User modifies a setting
- **GIVEN** a page is integrated with the Dirty State Navigation Guard Framework.
- **WHEN** the user modifies a setting on the page.
- **THEN** the page's state SHALL be marked as "dirty".

### Requirement: Navigation Interception and User Prompt
The framework SHALL intercept navigation attempts away from a dirty page and prompt the user for action.

#### Scenario: Attempt to navigate away from a dirty page
- **GIVEN** a page is marked as "dirty".
- **WHEN** the user attempts to navigate away from the page (e.g., via back button, menu navigation).
- **THEN** the system SHALL display a confirmation dialog asking the user to save, discard, or cancel the navigation.

### Requirement: Standardized Fetch and Save Operations
The framework SHALL provide standardized mechanisms for fetching and saving feature-specific data.

#### Scenario: Fetching initial data
- **GIVEN** a feature's Notifier is initialized.
- **WHEN** the `build()` method is called.
- **THEN** an initial state SHALL be returned synchronously.
- **AND** an asynchronous `performFetch()` operation SHALL be triggered to load actual data.

#### Scenario: Saving modified data
- **GIVEN** a feature's Notifier has a dirty state.
- **WHEN** the `save()` method is invoked.
- **THEN** the `performSave()` method SHALL be executed to persist the current settings.
- **AND** the state SHALL be marked as clean after successful saving.

### Requirement: Customizable Dirty Check Logic
The framework SHALL allow for customization of the dirty check logic to exclude specific fields from triggering the dirty state.

#### Scenario: Excluding a UI-only field from dirty check
- **GIVEN** a feature's `FeatureState` has a field (e.g., `uiOnlyFlag`) that should not trigger the dirty state.
- **WHEN** the `isDirty` getter in `FeatureState` is overridden.
- **THEN** changes to the specified field SHALL NOT cause the `isDirty` flag to be true.

### Requirement: Tab-level Navigation Guard for Tabbed Interfaces
For features utilizing tabbed interfaces, the framework SHALL provide a mechanism to guard navigation between tabs if the current tab has unsaved changes.

#### Scenario: Attempt to switch tabs with unsaved changes
- **GIVEN** a tabbed interface is integrated with the Dirty State Navigation Guard Framework.
- **WHEN** the user has made changes in the current tab, making it "dirty".
- **AND** the user attempts to switch to another tab.
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
