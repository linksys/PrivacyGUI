## Why
The DHCP Reservations feature currently uses a custom `_preservedState` mechanism for dirty checking, which is not integrated with the standardized `dirty-guard` framework. This leads to inconsistent behavior and increased maintenance burden.

## What Changes
This proposal outlines the refactoring of the DHCP Reservations feature to use the existing, robust `dirty-guard` framework.

The core changes are:
- **Migrate State Management:** Refactor `DHCPReservationsNotifier` to fully leverage `PreservableNotifierMixin`.
- **Remove Custom Dirty Checking:** Eliminate the custom `_preservedState` usage from `DHCPReservationsView`.
- **Integrate with Framework:** Configure the `LinksysRoute` for `/dhcp-reservations` to enable the dirty-guard.

## Impact
- **Affected Specs:** `dhcp-reservations` (delta spec for this change).
- **Affected Code:**
  - `lib/page/advanced_settings/local_network_settings/providers/dhcp_reservations_provider.dart`: Providers and views in this directory will be refactored.
  - `lib/page/advanced_settings/local_network_settings/views/dhcp_reservations_view.dart`: The view will be updated.
  - `lib/route/route_menu.dart`: The route for `/dhcp-reservations` will be updated.
- **Outcome:** The refactoring will result in a cleaner, more maintainable, and consistent implementation of dirty checking for the DHCP Reservations feature, aligning with the project's established architecture.