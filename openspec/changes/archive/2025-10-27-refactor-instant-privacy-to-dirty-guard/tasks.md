## Implementation Tasks for Instant Privacy Refactoring

- [x] 1.1: Refactor `InstantPrivacyState` to extend `FeatureState<InstantPrivacySettings, InstantPrivacyStatus>`.
- [x] 1.2: Refactor `InstantPrivacyNotifier` to use `with PreservableNotifierMixin` and implement `performFetch` and `performSave`.
- [x] 1.3: Refactor `InstantPrivacyView` to remove `PreservedStateMixin` and rely on `InstantPrivacyNotifier` for dirty state and actions.
- [x] 1.4: Update the `LinksysRoute` for `/instant-privacy` in `lib/route/route_menu.dart` to set `preservableProvider` and `enableDirtyCheck: true`.
- [x] 1.5: Use `doSomethingWithSpinner` for `save` and `fetch` operations in `InstantPrivacyView`.
- [x] 1.6: Verify that test states in `test/test_data/**` are correctly modified to correspond to the latest `FeatureState`, and add `fromMap` constructors if missing, by checking their usage in relevant test files.
- [x] 1.7: sh run_generate_loc_snapshots.sh -c true -f test/page/instant_privacy/views/localizations/instant_privacy_view_test.dart
