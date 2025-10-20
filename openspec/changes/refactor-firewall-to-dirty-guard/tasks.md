## Implementation Tasks for Firewall Refactoring

- [ ] 1.1: Refactor `FirewallState` to extend `FeatureState<FirewallSettings, FirewallStatus>`. (Note: `FirewallState` currently holds both settings and status, will need to split if not already done).
- [ ] 1.2: Refactor `FirewallNotifier` to use `with PreservableNotifierMixin` and implement `performFetch` and `performSave`.
- [ ] 1.3: Refactor `FirewallView` to remove custom `_preservedState` logic and rely on `FirewallNotifier` for dirty state and actions.
- [ ] 1.4: Update the `LinksysRoute` for `/firewall` in `lib/route/route_menu.dart` to set `preservableProvider` and `enableDirtyCheck: true`.
- [ ] 1.5: Run relevant tests to verify the refactoring.
