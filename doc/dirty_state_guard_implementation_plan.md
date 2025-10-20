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

## Phase 5 (Optional): Wider Refactoring

*   **Task 5.1**: Identify and schedule other features (e.g., `VPN`) for refactoring to use this framework.
