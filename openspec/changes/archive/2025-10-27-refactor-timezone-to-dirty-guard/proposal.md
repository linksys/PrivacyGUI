## Why
The Timezone feature currently uses a custom `PreservedStateMixin` for dirty checking, which is not integrated with the standardized `dirty-guard` framework. This leads to inconsistent behavior and increased maintenance burden.

## What Changes
This proposal outlines the refactoring of the Timezone feature to use the existing, robust `dirty-guard` framework.

The core changes are:
- **Migrate State Management:** Refactor `TimezoneNotifier` to fully leverage `PreservableNotifierMixin`.
- **Remove Custom Dirty Checking:** Eliminate the custom `PreservedStateMixin` usage from `TimezoneView`.
- **Integrate with Framework:** Configure the `LinksysRoute` for `/timezone` to enable the dirty-guard.

## Impact
- **Affected Specs:** `timezone-settings` (delta spec for this change).
- **Affected Code:**
  - `lib/page/instant_admin/providers/timezone_provider.dart`: Providers and views in this directory will be refactored.
  - `lib/page/instant_admin/views/timezone_view.dart`: The view will be updated.
  - `lib/route/route_menu.dart`: The route for `/timezone` will be updated.
- **Outcome:** The refactoring will result in a cleaner, more maintainable, and consistent implementation of dirty checking for the Timezone feature, aligning with the project's established architecture.