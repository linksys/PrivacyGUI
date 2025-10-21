## Implementation Tasks for VPN Settings Refactoring

- [ ] 1.1: Refactor `VPNState` to extend `FeatureState<VPNSettings, VPNStatus>`.
- [ ] 1.2: Refactor `VPNNotifier` to use `with PreservableNotifierMixin` and implement `performFetch` and `performSave`.
- [ ] 1.3: Refactor `VPNSettingsPage` to remove `PreservedStateMixin` and rely on `VPNNotifier` for dirty state and actions.
- [ ] 1.4: Use `doSomethingWithSpinner` for `save` and `fetch` operations in `VPNSettingsPage`.
- [ ] 1.5: Update the `LinksysRoute` for `/vpn-settings` in `lib/route/route_menu.dart` to set `preservableProvider` and `enableDirtyCheck: true`.
- [ ] 1.6: sh run_generate_loc_snapshots.sh -c true -f test/page/vpn/views/localizations/vpn_settings_page_test.dart