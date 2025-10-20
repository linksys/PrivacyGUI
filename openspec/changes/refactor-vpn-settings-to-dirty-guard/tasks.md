## Implementation Tasks for VPN Settings Refactoring

- [ ] 1.1: Refactor `VPNState` to extend `FeatureState<VPNSettings, VPNStatus>`.
- [ ] 1.2: Refactor `VPNNotifier` to use `with PreservableNotifierMixin` and implement `performFetch` and `performSave`.
- [ ] 1.3: Refactor `VPNSettingsPage` to remove `PreservedStateMixin` and rely on `VPNNotifier` for dirty state and actions.
- [ ] 1.4: Update the `LinksysRoute` for `/vpn-settings` in `lib/route/route_menu.dart` to set `preservableProvider` and `enableDirtyCheck: true`.
- [ ] 1.5: Run relevant tests to verify the refactoring.
