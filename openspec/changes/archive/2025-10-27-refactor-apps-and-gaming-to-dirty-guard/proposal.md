## Why
The Apps and Gaming feature currently manages multiple sub-features (DDNS, Single Port Forwarding, Port Range Forwarding, Port Range Triggering) with custom state management and dirty checking logic. This leads to inconsistent behavior, increased complexity, and a higher maintenance burden compared to using the standardized `dirty-guard` framework.

## What Changes
This proposal outlines the refactoring of the Apps and Gaming feature to integrate with the existing, robust `dirty-guard` framework. This will involve updating the state management of all sub-features and centralizing dirty checking within the `AppsAndGamingView`.

The core changes are:
- **Migrate Sub-Feature State Management:** Refactor `DDNSState`, `SinglePortForwardingListState`, `PortRangeForwardingListState`, and `PortRangeTriggeringListState` to extend `FeatureState<Settings, Status>`.
- **Migrate Sub-Feature Notifiers:** Refactor `DDNSNotifier`, `SinglePortForwardingListNotifier`, `PortRangeForwardingListNotifier`, and `PortRangeTriggeringListNotifier` to use `with PreservableNotifierMixin` and implement `performFetch` and `performSave`.
- **Centralize Dirty Checking in `AppsAndGamingView`:** Update `AppsAndGamingView` and `AppsAndGamingViewNotifier` to coordinate the dirty state and save/revert actions across all sub-feature notifiers.
- **Integrate with Framework:** Configure the `LinksysRoute` for `/apps-and-gaming` to enable the dirty-guard.

## Impact
- **Affected Specs:** `apps-and-gaming` (delta spec for this change).
- **Affected Code:**
  - `lib/page/advanced_settings/apps_and_gaming/**`: All providers, states, and views within this directory will be refactored.
  - `lib/route/route_menu.dart`: The route for `/apps-and-gaming` will be updated.
- **Outcome:** The refactoring will result in a cleaner, more maintainable, and consistent implementation of dirty checking for the Apps and Gaming feature, aligning with the project's established architecture.
