## Implementation Tasks for Firewall Refactoring

- [ ] 1.1: Refactor `FirewallState` to extend `FeatureState<FirewallSettings, FirewallStatus>`. (Note: `FirewallState` currently holds both settings and status, will need to split if not already done).
- [ ] 1.2: Refactor `FirewallNotifier` to use `with PreservableNotifierMixin` and implement `performFetch` and `performSave`.
- [ ] 1.3: Refactor `FirewallView` to remove custom `_preservedState` logic and rely on `FirewallNotifier` for dirty state and actions.
- [ ] 1.4: Use `doSomethingWithSpinner` for `save` and `fetch` operations in `FirewallView`.
- [ ] 1.5: Update the `LinksysRoute` for `/firewall` in `lib/route/route_menu.dart` to set `preservableProvider` and `enableDirtyCheck: true`.
- [ ] 1.6: Verify that test states in `test/test_data/**` are correctly modified to correspond to the latest `FeatureState`, and add `fromMap` constructors if missing, by checking their usage in relevant test files.
- [ ] 1.7: sh run_generate_loc_snapshots.sh -c true -f test/page/advanced_settings/firewall/views/localizations/firewall_view_test.dart