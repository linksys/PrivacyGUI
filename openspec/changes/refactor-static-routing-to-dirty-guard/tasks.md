## Implementation Tasks for Static Routing Refactoring

- [ ] 1.1: Refactor `StaticRoutingState` to extend `FeatureState<StaticRoutingSettings, StaticRoutingStatus>`. (Note: `StaticRoutingState` currently holds both settings and status, will need to split if not already done).
- [ ] 1.2: Refactor `StaticRoutingNotifier` to use `with PreservableNotifierMixin` and implement `performFetch` and `performSave`.
- [ ] 1.3: Refactor `StaticRoutingView` to remove custom `preservedState` logic and rely on `StaticRoutingNotifier` for dirty state and actions.
- [ ] 1.4: Update the `LinksysRoute` for `/static-routing` in `lib/route/route_menu.dart` to set `preservableProvider` and `enableDirtyCheck: true`.
- [ ] 1.5: Run relevant tests to verify the refactoring.
