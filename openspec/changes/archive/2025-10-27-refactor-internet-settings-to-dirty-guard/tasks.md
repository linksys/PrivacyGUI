## Implementation Tasks for Internet Settings Refactoring

- [x] 1.1 Define `InternetSettings` class to encapsulate all editable settings (Ipv4Setting, Ipv6Setting, macClone, macCloneAddress).
- [x] 1.2 Define `InternetStatus` class to encapsulate non-editable status information (e.g., supportedWANCombinations, supportedIPv4ConnectionType, supportedIPv6ConnectionType).
- [x] 1.3 Refactor `InternetSettingsState` to extend `FeatureState<InternetSettings, InternetStatus>`.
- [x] 1.4 Refactor `InternetSettingsNotifier` to use `with PreservableNotifierMixin` and implement `performFetch` and `performSave`. Adjust `saveInternetSettings` logic to fit `performSave`.
- [x] 1.5 Refactor `InternetSettingsView` to remove custom `originalState` logic and rely on `InternetSettingsNotifier` for dirty state and actions. Adjust UI update logic (`initUI`) to work with the new state structure.
- [x] 1.6 Use `doSomethingWithSpinner` for `save` and `fetch` operations in `InternetSettingsView`.
- [x] 1.7 Update the `LinksysRoute` for `/internet-settings` in `lib/route/route_menu.dart` to set `preservableProvider` and `enableDirtyCheck: true`.
- [x] 1.8 Verify that test states in `test/test_data/**` are correctly modified to correspond to the latest `FeatureState`, and add `fromMap` constructors if missing, by checking their usage in relevant test files.
- [x] 1.9: sh run_generate_loc_snapshots.sh -c true -f test/page/advanced_settings/internet_settings/views/localizations/internet_settings_view_test.dart