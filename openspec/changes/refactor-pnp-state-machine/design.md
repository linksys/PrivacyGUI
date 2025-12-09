## Context
The current PnP flow implementation suffers from scattered state management, with critical business logic living inside `StatefulWidget`s. This makes the flow hard to reason about and prone to bugs. The goal is to refactor this into a robust, centralized state machine.

## Goals
- Centralize all PnP flow state into `PnpState`.
- Decouple UI widgets from business logic.
- Improve the testability, maintainability, and readability of the PnP module.
- Create a single, predictable state machine for the entire PnP user journey.

## Decisions
### Decision: Adopt a Unified State Machine Model
We will implement a formal state machine within `PnpNotifier`. A single enum, `PnpFlowStatus`, will represent every possible state in the flow, replacing the multiple boolean flags and implicit states in the current code.

### Decision: UI as a Pure Function of State
All UI widgets involved in the flow will be refactored into `ConsumerWidget`s. Their `build` method will simply `watch` the `PnpProvider` and render UI based on the current `PnpState.status`. All user interactions will be forwarded as intent-based calls to the `PnpNotifier` (e.g., `notifier.submitPassword()`).

### To-Be State Diagram
The target architecture is represented by the following state diagram:

```plantuml
@startuml
title Unified PnP Flow State (After Refactor)

[*] --> AdminInitializing

state "Admin Phase" {
    AdminInitializing --> AdminUnconfigured: Router is unconfigured
    AdminInitializing --> AdminAwaitingPassword: Password required
    AdminInitializing --> AdminInternetConnected: Already logged in, has internet
    AdminInitializing --> AdminError: Critical error
    AdminInitializing --> NoInternetRoute <<end>> : No internet

    AdminUnconfigured --> AdminCheckingInternet: notifier.continueFromUnconfigured()
    AdminAwaitingPassword --> AdminLoggingIn: notifier.submitPassword()
    AdminLoggingIn --> AdminCheckingInternet: Login success
    AdminLoggingIn --> AdminLoginFailed: Login fail
    AdminLoginFailed --> AdminLoggingIn: User retries
}

AdminInternetConnected --> WizardInitializing
AdminCheckingInternet --> WizardInitializing: Internet check OK
AdminCheckingInternet --> NoInternetRoute <<end>> : Internet check fail

state "Wizard Phase" {
    WizardInitializing --> WizardConfiguring: Fetch data OK
    WizardInitializing --> WizardInitFailed: Fetch data fail

    WizardConfiguring --> WizardSaving: notifier.saveChanges()
    WizardSaving --> WizardSaved: Save OK (configured flow)
    WizardSaving --> WizardConfiguring: Save OK (unconfigured flow, to next step)
    WizardSaving --> WizardNeedsReconnect: Connection lost during save
    WizardSaving --> WizardSaveFailed: Save operation fails
    WizardSaveFailed --> WizardConfiguring: User can retry

    WizardSaved --> WizardCheckingFirmware: Auto transition
    WizardCheckingFirmware --> WizardUpdatingFirmware: New FW found
    WizardCheckingFirmware --> WizardWifiReady: No new FW
    WizardUpdatingFirmware --> WizardWifiReady: Update complete

    WizardNeedsReconnect --> WizardTestingReconnect: notifier.testReconnect()
    WizardTestingReconnect --> WizardCheckingFirmware: Reconnect OK (configured flow)
    WizardTestingReconnect --> WizardConfiguring: Reconnect OK (unconfigured flow)
    WizardTestingReconnect --> WizardNeedsReconnect: Reconnect fail
}

WizardWifiReady --> DashboardRoute <<end>> : User clicks Done
AdminError --> HomeRoute <<end>> : User clicks Try Again
WizardInitFailed --> HomeRoute <<end>> : User clicks Try Again

@enduml
```

## Risks / Trade-offs
- **Risk:** The refactoring is significant and touches critical user flows. There is a risk of introducing regressions.
- **Mitigation:** Thorough manual testing and reliance on the existing integration test suite are required to ensure behavioral parity. The refactoring will be done in logical, sequential steps as outlined in `tasks.md`.
