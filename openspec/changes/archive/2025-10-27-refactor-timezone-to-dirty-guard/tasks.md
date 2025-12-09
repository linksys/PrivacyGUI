## Implementation Tasks for Timezone Refactoring

- [x] 1.1: Refactor `TimezoneState` to extend `FeatureState<TimezoneSettings, TimezoneStatus>`. (Note: `TimezoneState` currently holds both settings and status, will need to split if not already done).
- [x] 1.2: Refactor `TimezoneNotifier` to use `with PreservableNotifierMixin` and implement `performFetch` and `performSave`.
- [x] 1.3: Refactor `TimezoneView` to remove `PreservedStateMixin` and rely on `TimezoneNotifier` for dirty state and actions.
- [x] 1.4: Use `doSomethingWithSpinner` for `save` and `fetch` operations in `TimezoneView`.
- [x] 1.5: Update the `LinksysRoute` for `/timezone` in `lib/route/route_menu.dart` to set `preservableProvider` and `enableDirtyCheck: true`.
- [x] 1.6: Verify that test states in `test/test_data/**` are correctly modified to correspond to the latest `FeatureState`, and add `fromMap` constructors if missing, by checking their usage in relevant test files.
- [x] 1.7: sh run_generate_loc_snapshots.sh -c true -f test/page/instant_admin/views/localizations/timezone_view_test.dart
