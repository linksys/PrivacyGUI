## Implementation Tasks for DHCP Reservations Refactoring

- [x] 1.1: Refactor `DHCPReservationsState` to extend `FeatureState<DHCPReservationsSettings, DHCPReservationsStatus>`. (Note: `DHCPReservationsState` currently holds both settings and status, will need to split if not already done).
- [x] 1.2: Refactor `DHCPReservationsNotifier` to use `with PreservableNotifierMixin` and implement `performFetch` and `performSave`.
- [x] 1.3: Refactor `DHCPReservationsView` to remove custom `_preservedState` logic and rely on `DHCPReservationsNotifier` for dirty state and actions.
- [x] 1.4: Use `doSomethingWithSpinner` for `save` and `fetch` operations in `DHCPReservationsView`.
- [x] 1.5: Update the `LinksysRoute` for `/dhcp-reservations` in `lib/route/route_menu.dart` to set `preservableProvider` and `enableDirtyCheck: true`.
- [x] 1.6: Verify that test states in `test/test_data/**` are correctly modified to correspond to the latest `FeatureState`, and add `fromMap` constructors if missing, by checking their usage in relevant test files.
- [x] 1.7: sh run_generate_loc_snapshots.sh -c true -f test/page/advanced_settings/local_network_settings/views/localizations/dhcp_reservations_view_test.dart