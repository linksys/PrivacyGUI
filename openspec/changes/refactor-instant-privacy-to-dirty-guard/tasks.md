## Implementation Tasks for Instant Privacy Refactoring

- [ ] 1.1: Refactor `InstantPrivacyState` to extend `FeatureState<InstantPrivacySettings, InstantPrivacyStatus>`.
- [ ] 1.2: Refactor `InstantPrivacyNotifier` to use `with PreservableNotifierMixin` and implement `performFetch` and `performSave`.
- [ ] 1.3: Refactor `InstantPrivacyView` to remove `PreservedStateMixin` and rely on `InstantPrivacyNotifier` for dirty state and actions.
- [ ] 1.4: Update the `LinksysRoute` for `/instant-privacy` in `lib/route/route_menu.dart` to set `preservableProvider` and `enableDirtyCheck: true`.
- [ ] 1.5: Run relevant tests to verify the refactoring.
