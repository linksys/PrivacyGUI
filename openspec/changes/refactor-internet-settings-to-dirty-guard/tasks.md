## Implementation Tasks for Internet Settings Refactoring

- [ ] 1.1: Refactor `InternetSettingsState` to extend `FeatureState<InternetSettings, InternetStatus>`. (Note: `InternetSettingsState` currently holds both settings and status, will need to split if not already done).
- [ ] 1.2: Refactor `InternetSettingsNotifier` to use `with PreservableNotifierMixin` and implement `performFetch` and `performSave`.
- [ ] 1.3: Refactor `InternetSettingsView` to remove custom `_preservedState` logic and rely on `InternetSettingsNotifier` for dirty state and actions.
- [ ] 1.4: Update the `LinksysRoute` for `/internet-settings` in `lib/route/route_menu.dart` to set `preservableProvider` and `enableDirtyCheck: true`.
- [ ] 1.5: Run relevant tests to verify the refactoring.
