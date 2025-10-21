## Implementation Tasks for Administration Settings Refactoring

- [ ] 1.1: Refactor `AdministrationSettingsState` to extend `FeatureState<AdministrationSettings, AdministrationStatus>`. (Note: `AdministrationSettingsState` currently holds both settings and status, will need to split if not already done).
- [ ] 1.2: Refactor `AdministrationSettingsNotifier` to use `with PreservableNotifierMixin` and implement `performFetch` and `performSave`.
- [ ] 1.3: Refactor `AdministrationSettingsView` to remove custom `_preservedState` logic and rely on `AdministrationSettingsNotifier` for dirty state and actions.
- [ ] 1.4: Use `doSomethingWithSpinner` for `save` and `fetch` operations in `AdministrationSettingsView`.
- [ ] 1.5: Update the `LinksysRoute` for `/administration-settings` in `lib/route/route_menu.dart` to set `preservableProvider` and `enableDirtyCheck: true`.
- [ ] 1.6: sh run_generate_loc_snapshots.sh -c true -f test/page/advanced_settings/administration/views/localizations/administration_settings_view_test.dart