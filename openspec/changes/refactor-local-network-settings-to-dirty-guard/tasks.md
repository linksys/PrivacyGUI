## Implementation Tasks for Local Network Settings Refactoring

- [x] 1.1: Refactor `LocalNetworkSettingsState` to extend `FeatureState<LocalNetworkSettings, LocalNetworkStatus>`. (Note: `LocalNetworkSettingsState` currently holds both settings and status, will need to split if not already done).
- [x] 1.2: Refactor `LocalNetworkSettingsNotifier` to use `with PreservableNotifierMixin` and implement `performFetch` and `performSave`.
- [x] 1.3: Refactor `LocalNetworkSettingsView` to remove custom `_preservedState` logic and rely on `LocalNetworkSettingsNotifier` for dirty state and actions.
- [x] 1.4: Refactor `DHCPReservationsView` to remove custom `_preservedState` logic and rely on `DHCPReservationsNotifier` for dirty state and actions.
- [x] 1.5: Use `doSomethingWithSpinner` for `save` and `fetch` operations in `LocalNetworkSettingsView`.
- [x] 1.6: Ensure `TextEditingController`s in `LocalNetworkSettingsView` and its sub-views are properly updated on `fetch`, `save`, and `revert` operations.
- [x] 1.7: Override `isDirty` in `LocalNetworkSettingsState` to exclude the DHCP reservation list from the dirty check.
- [x] 1.8: Update the `LinksysRoute` for `/local-network-settings` in `lib/route/route_menu.dart` to set `preservableProvider` and `enableDirtyCheck: true`.
- [x] 1.9: Verify that test states in `test/test_data/**` are correctly modified to correspond to the latest `FeatureState`, and add `fromMap` constructors if missing, by checking their usage in relevant test files.
- [x] 1.10: sh run_generate_loc_snapshots.sh -c true -f test/page/advanced_settings/local_network_settings/views/localizations/local_network_settings_view_test.dart
