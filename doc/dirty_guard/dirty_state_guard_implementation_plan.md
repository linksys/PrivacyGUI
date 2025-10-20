# "Dirty State" Navigation Guard Implementation Plan

## Objective
To build and integrate a generic, reusable, and fully tested framework to handle unsaved changes on a page, preventing accidental data loss during navigation.

---

## Phase 1: Core Framework Implementation

This phase focuses on creating the foundational, reusable components of the framework.

*   **Task 1.1: Create `Preservable<T>` Generic Wrapper Class**
    *   **Description**: Implement the `Preservable<T>` class to track `original` and `current` versions of settings data. This now includes serialization helpers (`toMap`, `fromMap`, etc.).
    *   **Output**: `lib/providers/preservable.dart`

*   **Task 1.2: Update `FeatureState<S, T>` Abstract Base Class**
    *   **Description**: Modify the `FeatureState` abstract class to include abstract `copyWith` and `toMap` methods, ensuring all subclasses are copyable and serializable.
    *   **Output**: `lib/providers/feature_state.dart`

*   **Task 1.3: Create `PreservableContract` and `PreservableNotifierMixin`**
    *   **Description**: Create a `PreservableContract` interface and a `PreservableNotifierMixin`. The mixin uses the Template Method pattern to provide generic `fetch()` and `save()` methods, requiring concrete notifiers to implement `performFetch()` and `performSave()`.
    *   **Output**: `lib/providers/preservable_contract.dart`, `lib/providers/preservable_notifier_mixin.dart`

*   **Task 1.4: Update the "Smart" `LinksysRoute`**
    *   **Description**: Modify the `LinksysRoute` class in `lib/route/route_model.dart`. The `onExit` logic will be updated to check if a notifier implements `PreservableContract` and, if so, call its `isDirty()` and `revert()` methods.
    *   **Output**: `lib/route/route_model.dart`

---

## Phase 2: Framework Unit & Integration Testing

This phase ensures the stability and correctness of the core framework through isolated testing.

*   **Task 2.1: Configure Test Tagging**
    *   **Description**: All framework-related tests will be assigned a unique tag for isolated execution.
    *   **Proposed Tag**: `'dirty-guard-framework'`
    *   **Execution Command**: `flutter test --tags dirty-guard-framework`

*   **Task 2.2: Write Unit Tests**
    *   **Description**: Create unit tests for `Preservable<T>` and for the logic within `PreservableNotifierMixin`, including the new `fetch()` and `save()` template methods.
    *   **Tag**: `'dirty-guard-framework'`

*   **Task 2.3: Write Integration Test for `LinksysRoute`**
    *   **Description**: Create a widget test to verify that the updated `LinksysRoute` correctly uses the `PreservableContract` to block or allow navigation based on the dirty state and user dialog interaction.
    *   **Tag**: `'dirty-guard-framework'`

---

## Phase 3: Reference Implementation - Refactor `InstantSafety` Feature

This phase applies the new, tested framework to an existing feature.

*   **Task 3.1**: Refactor `InstantSafetyState` to correctly extend the updated `FeatureState` and implement its `copyWith` and `toMap` methods.
*   **Task 3.2**: Refactor `InstantSafetyNotifier` to use `with PreservableNotifierMixin` and implement the `performFetch` and `performSave` methods.
*   **Task 3.3**: Refactor `InstantSafetyView` to rely on the notifier for dirty state and actions, calling the new `fetch()` and `save()` methods.
*   **Task 3.4**: Update the `LinksysRoute` in the router configuration for `/instant-safety` to ensure `preservableProvider` and `enableDirtyCheck: true` are set.

---

## Phase 4: Rollout & Documentation

*   **Task 4.1**: Finalize Specification Document (Done).
*   **Task 4.2**: Update Implementation Plan & Checklist (Done).
*   **Task 4.3**: Update team development guidelines to incorporate the new framework.

---

## Phase 5: Wider Refactoring - Migrate Existing Features to Dirty Guard Framework

This phase focuses on migrating existing features that currently manage their own "preserved state" or rely on custom dirty-checking mechanisms to the standardized Dirty Guard Framework.

*   **Task 5.1: Refactor Instant Privacy View**
    *   **View**: `lib/page/instant_privacy/views/instant_privacy_view.dart`
    *   **Provider**: `instantPrivacyProvider`
    *   **Notifier**: `InstantPrivacyNotifier`
    *   **Description**: Migrate to `PreservableNotifierMixin` and integrate with `LinksysRoute`'s dirty check. Update custom dialogs to use framework's dialogs.

*   **Task 5.2: Refactor VPN Settings Page**
    *   **View**: `lib/page/vpn/views/vpn_settings_page.dart`
    *   **Provider**: `vpnProvider`
    *   **Notifier**: `VPNNotifier`
    *   **Description**: Migrate to `PreservableNotifierMixin` and integrate with `LinksysRoute`'s dirty check. Update local `showUnsavedAlert` to use framework's dialogs.

*   **Task 5.3: Refactor Timezone View**
    *   **View**: `lib/page/instant_admin/views/timezone_view.dart`
    *   **Provider**: `timezoneProvider`
    *   **Notifier**: `TimezoneNotifier`
    *   **Description**: Migrate to `PreservableNotifierMixin` and integrate with `LinksysRoute`'s dirty check.

*   **Task 5.4: Refactor DHCP Reservations View**
    *   **View**: `lib/page/advanced_settings/local_network_settings/views/dhcp_reservations_view.dart`
    *   **Provider**: `dhcpReservationsProvider`
    *   **Notifier**: `DHCPReservationsNotifier`
    *   **Description**: Migrate to `PreservableNotifierMixin` and integrate with `LinksysRoute`'s dirty check.

*   **Task 5.5: Refactor DMZ Settings View**
    *   **View**: `lib/page/advanced_settings/dmz/views/dmz_settings_view.dart`
    *   **Provider**: `dmzSettingsProvider`
    *   **Notifier**: `DMZSettingsNotifier`
    *   **Description**: Migrate to `PreservableNotifierMixin` and integrate with `LinksysRoute`'s dirty check. Update local `showUnsavedAlert` to use framework's dialogs.

*   **Task 5.6: Refactor Administration Settings View**
    *   **View**: `lib/page/advanced_settings/administration/views/administration_settings_view.dart`
    *   **Provider**: `administrationSettingsProvider`
    *   **Notifier**: `AdministrationSettingsNotifier`
    *   **Description**: Migrate to `PreservableNotifierMixin` and integrate with `LinksysRoute`'s dirty check.

*   **Task 5.7: Refactor Static Routing View**
    *   **View**: `lib/page/advanced_settings/static_routing/static_routing_view.dart`
    *   **Provider**: `staticRoutingProvider`
    *   **Notifier**: `StaticRoutingNotifier`
    *   **Description**: Migrate to `PreservableNotifierMixin` and integrate with `LinksysRoute`'s dirty check.

*   **Task 5.8: Refactor Firewall View**
    *   **View**: `lib/page/advanced_settings/firewall/views/firewall_view.dart`
    *   **Provider**: `firewallProvider`
    *   **Notifier**: `FirewallNotifier`
    *   **Description**: Migrate to `PreservableNotifierMixin` and integrate with `LinksysRoute`'s dirty check.

*   **Task 5.9: Refactor Local Network Settings View**
    *   **View**: `lib/page/advanced_settings/local_network_settings/views/local_network_settings_view.dart`
    *   **Provider**: `localNetworkSettingProvider`
    *   **Notifier**: `LocalNetworkSettingsNotifier`
    *   **Description**: Migrate to `PreservableNotifierMixin` and integrate with `LinksysRoute`'s dirty check.

*   **Task 5.10: Refactor Internet Settings View**
    *   **View**: `lib/page/advanced_settings/internet_settings/views/internet_settings_view.dart`
    *   **Provider**: `internetSettingsProvider`
    *   **Notifier**: `InternetSettingsNotifier`
    *   **Description**: Migrate to `PreservableNotifierMixin` and integrate with `LinksysRoute`'s dirty check.
