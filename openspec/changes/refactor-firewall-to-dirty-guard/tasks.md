## Implementation Tasks for Firewall Refactoring

- [x] 1.1: Refactor `FirewallState` to extend `FeatureState<FirewallSettings, EmptyStatus>`.
- [x] 1.2: Refactor `FirewallNotifier` to use `with PreservableNotifierMixin` and implement `performFetch` and `performSave`.
- [x] 1.3: Refactor `Ipv6PortServiceListState` to extend `FeatureState<List<IPv6FirewallRule>, Ipv6PortServiceListStatus>`.
- [x] 1.4: Refactor `Ipv6PortServiceListNotifier` to use `with PreservableNotifierMixin` and implement `performFetch` and `performSave`.
- [x] 1.5: Refactor `FirewallView` to remove custom `_preservedState` logic and rely on `FirewallNotifier` and `Ipv6PortServiceListNotifier` for dirty state and actions.
- [x] 1.6: Use `doSomethingWithSpinner` for `save` and `fetch` operations in `FirewallView`.
- [x] 1.7: Update the `LinksysRoute` for `/firewall` in `lib/route/route_menu.dart` to set `preservableProvider` and `enableDirtyCheck: true`.
- [x] 1.8: Verify that test states in `test/test_data/**` are correctly modified to correspond to the latest `FeatureState`, and add `fromMap` constructors if missing, by checking their usage in relevant test files. (This includes `firewallSettingsTestState` and `ipv6PortServiceListTestState`).
- [x] 1.9: sh run_generate_loc_snapshots.sh -c true -f test/page/advanced_settings/firewall/views/localizations/firewall_view_test.dart