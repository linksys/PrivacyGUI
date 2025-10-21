## Implementation Tasks for Timezone Refactoring

- [ ] 1.1: Refactor `TimezoneState` to extend `FeatureState<TimezoneSettings, TimezoneStatus>`. (Note: `TimezoneState` currently holds both settings and status, will need to split if not already done).
- [ ] 1.2: Refactor `TimezoneNotifier` to use `with PreservableNotifierMixin` and implement `performFetch` and `performSave`.
- [ ] 1.3: Refactor `TimezoneView` to remove `PreservedStateMixin` and rely on `TimezoneNotifier` for dirty state and actions.
- [ ] 1.4: Use `doSomethingWithSpinner` for `save` and `fetch` operations in `TimezoneView`.
- [ ] 1.5: Update the `LinksysRoute` for `/timezone` in `lib/route/route_menu.dart` to set `preservableProvider` and `enableDirtyCheck: true`.
