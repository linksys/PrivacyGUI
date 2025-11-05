## Why
The Instant Privacy feature currently uses a custom `PreservedStateMixin` for dirty checking, which is not integrated with the standardized `dirty-guard` framework. This leads to inconsistent behavior and increased maintenance burden.

## What Changes
This proposal outlines the refactoring of the Instant Privacy feature to use the existing, robust `dirty-guard` framework.

The core changes are:
- **Migrate State Management:** Refactor `InstantPrivacyNotifier` to fully leverage `PreservableNotifierMixin`.
- **Remove Custom Dirty Checking:** Eliminate the custom `PreservedStateMixin` usage from `InstantPrivacyView`.
- **Integrate with Framework:** Configure the `LinksysRoute` for `/instant-privacy` to enable the dirty-guard.

## Impact
- **Affected Specs:** `instant-privacy` (delta spec for this change).
- **Affected Code:**
  - `lib/page/instant_privacy/**`: Providers and views in this directory will be refactored.
  - `lib/route/route_menu.dart`: The route for `/instant-privacy` will be updated.
- **Outcome:** The refactoring will result in a cleaner, more maintainable, and consistent implementation of dirty checking for the Instant Privacy feature, aligning with the project's established architecture.