# "Dirty State" Navigation Guard Implementation Plan

## Objective
To build and integrate a generic, reusable, and fully tested framework to handle unsaved changes on a page, preventing accidental data loss during navigation.

---

## Phase 1: Core Framework Implementation

This phase focuses on creating the foundational, reusable components of the framework.

*   **Task 1.1: Create `Preservable<T>` Generic Wrapper Class**
    *   **Description**: Implement the `Preservable<T>` generic class to wrap any data model that requires dirty state tracking. This class will hold `original` and `current` versions of the data and contain the core `isDirty` comparison logic.
    *   **Output**: `lib/providers/preservable.dart`

*   **Task 1.2: Create `FeatureState<S, T>` Abstract Base Class**
    *   **Description**: Implement the `FeatureState<TSettings, TStatus>` abstract base class to serve as a standardized template for feature state objects, enforcing the separation of configurable `settings` from transient `status` data.
    *   **Output**: `lib/providers/feature_state.dart`

*   **Task 1.3: Create the "Smart" `LinksysRoute<S>`**
    *   **Description**: Implement a custom `GoRoute` subclass named `LinksysRoute<S>`. This class will encapsulate the `onExit` navigation guard logic, including reading the provider state and showing a confirmation dialog.
    *   **Output**: `lib/route/linksys_route.dart` (or an existing equivalent location for custom routes)

---

## Phase 2: Framework Unit & Integration Testing

This phase ensures the stability and correctness of the core framework through isolated testing.

*   **Task 2.1: Configure Test Tagging**
    *   **Description**: To enable isolated testing of the framework components, all related tests will be assigned a unique tag.
    *   **Proposed Tag**: `'dirty-guard-framework'`
    *   **Execution Command**: `flutter test --tags dirty-guard-framework`

*   **Task 2.2: Unit Test `Preservable<T>`**
    *   **Description**: Verify the core logic of the `Preservable<T>` wrapper.
    *   **Test Cases**:
        *   Verify `isDirty` is `false` after initialization.
        *   Verify `isDirty` is `true` after calling `update()` with different data.
        *   Verify `isDirty` returns to `false` after calling `saved()`.
    *   **Tag**: `'dirty-guard-framework'`

*   **Task 2.3: Integration Test `LinksysRoute<S>`**
    *   **Description**: Create a Flutter widget test environment to simulate `go_router` navigation and verify the `LinksysRoute` navigation guard functionality.
    *   **Test Setup**:
        1.  Create a mock `TestFeatureState` and `TestFeatureNotifier`.
        2.  Build a test application with a `GoRouter` instance that uses the new `LinksysRoute` with `enableDirtyCheck: true`.
        3.  The test page should include UI elements to modify the state (making it "dirty") and to trigger navigation.
    *   **Test Cases**:
        *   **Clean State**: Assert that navigation succeeds without a prompt when the state is not dirty.
        *   **Dirty State & Cancel**: Assert that a confirmation dialog appears when navigating away from a dirty page. Simulate tapping "Cancel" and verify that navigation is blocked.
        *   **Dirty State & Confirm**: Assert that after the dialog appears, simulating a "Confirm" action allows navigation to proceed.
        *   **System Back Navigation**: Repeat the dirty state tests by triggering a system back gesture (`tester.pageBack()`).
    *   **Tag**: `'dirty-guard-framework'`

---

## Phase 3: Reference Implementation - Refactor `InstantSafety` Feature

This phase applies the new, tested framework to an existing feature to serve as a reference for future work.

*   **Task 3.1**: Refactor `InstantSafetyState` to extend `FeatureState<InstantSafetySettings, InstantSafetyStatus>`.
*   **Task 3.2**: Refactor `InstantSafetyNotifier` to manage the new state structure, using the `Preservable<T>` helpers.
*   **Task 3.3**: Refactor `InstantSafetyView` to remove the `PreservedStateMixin` and rely entirely on the provider for state management and dirty checking.
*   **Task 3.4**: Update the router configuration to replace the `GoRoute` for `/instant-safety` with the new `LinksysRoute`, setting `provider: instantSafetyProvider` and `enableDirtyCheck: true`.

---

## Phase 4: Rollout & Documentation

This phase ensures the team is aware of and can effectively use the new framework.

*   **Task 4.1**: Finalize Specification Document (Done).
*   **Task 4.2**: Update team development guidelines and/or wiki to establish this framework as the standard pattern for handling unsaved changes.

---

## Phase 5 (Optional): Wider Refactoring

Once the framework is established, plan the refactoring of other features in the application.

*   **Task 5.1**: Identify and schedule other features (e.g., `VPN`) that have custom "unsaved changes" logic for refactoring to adopt the new, unified framework.
