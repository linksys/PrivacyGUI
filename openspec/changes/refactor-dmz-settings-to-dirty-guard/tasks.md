## Implementation Tasks for DMZ Settings Refactoring

- [ ] 1.1: Refactor `DMZSettingsState` to extend `FeatureState<DMZSettings, DMZStatus>`. (Note: `DMZSettingsState` currently holds both settings and status, will need to split if not already done).
- [ ] 1.2: Refactor `DMZSettingsNotifier` to use `with PreservableNotifierMixin` and implement `performFetch` and `performSave`.
- [ ] 1.3: Refactor `DMZSettingsView` to remove `PreservedStateMixin` and rely on `DMZSettingsNotifier` for dirty state and actions.
- [ ] 1.4: Use `doSomethingWithSpinner` for `save` and `fetch` operations in `DMZSettingsView`.
- [ ] 1.5: Update the `LinksysRoute` for `/dmz-settings` in `lib/route/route_menu.dart` to set `preservableProvider` and `enableDirtyCheck: true`.
- [ ] 1.6: sh run_generate_loc_snapshots.sh -c true -f test/page/advanced_settings/dmz/views/localizations/dmz_settings_view_test.dart