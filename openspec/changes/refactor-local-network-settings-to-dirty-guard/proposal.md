## Why
The Local Network Settings feature currently uses a custom `_preservedState` mechanism for dirty checking, which is not integrated with the standardized `dirty-guard` framework. This leads to inconsistent behavior and increased maintenance burden.

## What Changes
This proposal outlines the refactoring of the Local Network Settings feature to use the existing, robust `dirty-guard` framework.

The core changes are:
- **Migrate State Management:** Refactor `LocalNetworkSettingsNotifier` to fully leverage `PreservableNotifierMixin`.
- **Remove Custom Dirty Checking:** Eliminate the custom `_preservedState` usage from `LocalNetworkSettingsView`.
- **Integrate with Framework:** Configure the `LinksysRoute` for `/local-network-settings` to enable the dirty-guard.

## Impact
- **Affected Specs:** `local-network-settings` (delta spec for this change).
- **Affected Code:**
  - `lib/page/advanced_settings/local_network_settings/**`: Providers and views in this directory will be refactored.
  - `lib/route/route_menu.dart`: The route for `/local-network-settings` will be updated.
- **Outcome:** The refactoring will result in a cleaner, more maintainable, and consistent implementation of dirty checking for the Local Network Settings feature, aligning with the project's established architecture.