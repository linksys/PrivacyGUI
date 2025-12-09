## Implementation Tasks for Apps and Gaming Refactoring

- [x] 1.1: Refactor `DDNSState` to extend `FeatureState<DDNSSettings, DDNSStatus>`.
- [x] 1.2: Refactor `DDNSNotifier` to use `with PreservableNotifierMixin` and implement `performFetch` and `performSave`.
- [x] 1.3: Refactor `SinglePortForwardingListState` to extend `FeatureState<List<SinglePortForwardingRule>, SinglePortForwardingListStatus>`.
- [x] 1.4: Refactor `SinglePortForwardingListNotifier` to use `with PreservableNotifierMixin` and implement `performFetch` and `performSave`.
- [x] 1.5: Refactor `PortRangeForwardingListState` to extend `FeatureState<List<PortRangeForwardingRule>, PortRangeForwardingListStatus>`.
- [x] 1.6: Refactor `PortRangeForwardingListNotifier` to use `with PreservableNotifierMixin` and implement `performFetch` and `performSave`.
- [x] 1.7: Refactor `PortRangeTriggeringListState` to extend `FeatureState<List<PortRangeTriggeringRule>, PortRangeTriggeringListStatus>`.
- [x] 1.8: Refactor `PortRangeTriggeringListNotifier` to use `with PreservableNotifierMixin` and implement `performFetch` and `performSave`.
- [x] 1.9: Refactor `AppsGamingSettingsView` to remove custom `_preservedState` logic and rely on all sub-feature notifiers for dirty state and actions.
- [x] 1.10: Use `doSomethingWithSpinner` for `save` and `fetch` operations in `AppsGamingSettingsView`.
- [x] 1.11: Update the `LinksysRoute` for `/apps-and-gaming` in `lib/route/route_menu.dart` to set `preservableProvider` and `enableDirtyCheck: true`.
- [x] 1.12: Verify that test states in `test/test_data/**` are correctly modified to correspond to the latest `FeatureState`, and add `fromMap` constructors if missing, by checking their usage in relevant test files.
- [x] 1.13: sh run_generate_loc_snapshots.sh -c true -f test/page/advanced_settings/apps_and_gaming/views/localizations/apps_and_gaming_view_test.dart
