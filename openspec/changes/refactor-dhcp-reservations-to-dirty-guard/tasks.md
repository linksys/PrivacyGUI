## Implementation Tasks for DHCP Reservations Refactoring

- [ ] 1.1: Refactor `DHCPReservationsState` to extend `FeatureState<DHCPReservationsSettings, DHCPReservationsStatus>`. (Note: `DHCPReservationsState` currently holds both settings and status, will need to split if not already done).
- [ ] 1.2: Refactor `DHCPReservationsNotifier` to use `with PreservableNotifierMixin` and implement `performFetch` and `performSave`.
- [ ] 1.3: Refactor `DHCPReservationsView` to remove custom `_preservedState` logic and rely on `DHCPReservationsNotifier` for dirty state and actions.
- [ ] 1.4: Update the `LinksysRoute` for `/dhcp-reservations` in `lib/route/route_menu.dart` to set `preservableProvider` and `enableDirtyCheck: true`.
- [ ] 1.5: Run relevant tests to verify the refactoring.
