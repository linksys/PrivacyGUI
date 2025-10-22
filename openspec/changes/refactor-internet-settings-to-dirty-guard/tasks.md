## Implementation Tasks for Internet Settings Refactoring

- [ ] 1.1: Refactor `InternetSettingsState` to extend `FeatureState<InternetSettings, InternetStatus>`. (Note: `InternetSettingsState` currently holds both settings and status, will need to split if not already done).
- [ ] 1.2: Refactor `InternetSettingsNotifier` to use `with PreservableNotifierMixin` and implement `performFetch` and `performSave`.
- [ ] 1.3: Refactor `InternetSettingsView` to remove custom `_preservedState` logic and rely on `InternetSettingsNotifier` for dirty state and actions.
- [ ] 1.4: Use `doSomethingWithSpinner` for `save` and `fetch` operations in `InternetSettingsView`.
- [ ] 1.5: Update the `LinksysRoute` for `/internet-settings` in `lib/route/route_menu.dart` to set `preservableProvider` and `enableDirtyCheck: true`.
- [ ] 1.6: Verify that test states in `test/test_data/**` are correctly modified to correspond to the latest `FeatureState`, and add `fromMap` constructors if missing, by checking their usage in relevant test files.
- [ ] 1.7: sh run_generate_loc_snapshots.sh -c true -f test/page/advanced_settings/internet_settings/views/localizations/internet_settings_view_test.dart