## Why
The DMZ Settings feature currently uses a custom `PreservedStateMixin` for dirty checking, which is not integrated with the standardized `dirty-guard` framework. This leads to inconsistent behavior and increased maintenance burden.

## What Changes
This proposal outlines the refactoring of the DMZ Settings feature to use the existing, robust `dirty-guard` framework.

The core changes are:
- **Migrate State Management:** Refactor `DMZSettingsNotifier` to fully leverage `PreservableNotifierMixin`.
- **Remove Custom Dirty Checking:** Eliminate the custom `PreservedStateMixin` usage from `DMZSettingsView`.
- **Integrate with Framework:** Configure the `LinksysRoute` for `/dmz-settings` to enable the dirty-guard.

## Impact
- **Affected Specs:** `dmz-settings` (delta spec for this change).
- **Affected Code:**
  - `lib/page/advanced_settings/dmz/**`: Providers and views in this directory will be refactored.
  - `lib/route/route_menu.dart`: The route for `/dmz-settings` will be updated.
- **Outcome:** The refactoring will result in a cleaner, more maintainable, and consistent implementation of dirty checking for the DMZ Settings feature, aligning with the project's established architecture.