## Why
The Static Routing feature currently uses a custom `preservedState` mechanism for dirty checking, which is not integrated with the standardized `dirty-guard` framework. This leads to inconsistent behavior and increased maintenance burden.

## What Changes
This proposal outlines the refactoring of the Static Routing feature to use the existing, robust `dirty-guard` framework.

The core changes are:
- **Migrate State Management:** Refactor `StaticRoutingNotifier` to fully leverage `PreservableNotifierMixin`.
- **Remove Custom Dirty Checking:** Eliminate the custom `preservedState` usage from `StaticRoutingView`.
- **Integrate with Framework:** Configure the `LinksysRoute` for `/static-routing` to enable the dirty-guard.

## Impact
- **Affected Specs:** `static-routing` (delta spec for this change).
- **Affected Code:**
  - `lib/page/advanced_settings/static_routing/**`: Providers and views in this directory will be refactored.
  - `lib/route/route_menu.dart`: The route for `/static-routing` will be updated.
- **Outcome:** The refactoring will result in a cleaner, more maintainable, and consistent implementation of dirty checking for the Static Routing feature, aligning with the project's established architecture.