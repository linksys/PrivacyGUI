# PnP (Plug and Play) Flow State Machine Document

This document aims to describe the changes in the PnP process before and after refactoring using State Diagrams. This helps in understanding the complexity of the existing process and demonstrates the advantages of the refactored architecture.

## As-Is State Diagram (Before Refactor)

Before the refactor, the state logic of the PnP process was scattered across two separate `StatefulWidget`s, `PnpAdminView` and `PnpSetupView`. It relied on numerous local flags and `try-catch` exception handling to control the UI flow.

### 1. `PnpAdminView` Flow

This view acts as the "gatekeeper" for the PnP process. Its state transitions are highly dependent on various exceptions thrown by the `runInitialChecks` method, leading to a decentralized and hard-to-track flow.

```plantuml
@startuml
title PnpAdminView State (Before Refactor)

[*] --> Initializing
Initializing: Enters _runInitialChecks()

Initializing --> InternetConnected : runInitialChecks() OK
Initializing --> AwaitingPassword : throws InvalidAdminPassword
Initializing --> Unconfigured : throws RouterUnconfigured
Initializing --> Error : throws FetchDeviceInfo / other
Initializing --> NoInternetView <<end>> : throws NoInternetConnection
Initializing --> OtherRoute <<end>> : throws InterruptAndExit

InternetConnected --> PnpConfigView <<end>> : After 1s delay, navigates

AwaitingPassword --> LoggingIn : User clicks Login
LoggingIn --> CheckingInternet : checkAdminPassword() OK
LoggingIn --> AwaitingPassword : shows "Incorrect Password" on fail

CheckingInternet --> PnpConfigView <<end>> : Internet OK
CheckingInternet --> NoInternetView <<end>> : No Internet

Unconfigured --> CheckingInternetFromUnconfigured : User clicks Continue
CheckingInternetFromUnconfigured --> PnpConfigView <<end>> : All checks OK
CheckingInternetFromUnconfigured --> NoInternetView <<end>> : No Internet
CheckingInternetFromUnconfigured --> AwaitingPassword : Other error

Error --> HomeView <<end>> : User clicks Try Again

@enduml
```

### 2. `PnpSetupView` Flow

This view is the core setup wizard. Its state is determined by the `_PnpSetupStep` enum and multiple boolean flags (e.g., `_needToReconnect`, `_fetchError`). The state transition logic is mixed with user interactions, asynchronous callbacks, and external event listeners, making it very complex.

```plantuml
@startuml
title PnpSetupView State (Before Refactor)

[*] --> Init
Init : Calls _initialize()

Init --> Config : fetchData() OK
Init --> FetchError : fetchData() fails

Config : Displays PnpStepper
Config --> Saving : User triggers saveChanges()

Saving --> NeedReconnect : pnp.save() throws NeedToReconnect
Saving --> Config : pnp.save() throws SavingChanges (shows error)
Saving --> Saved : pnp.save() OK (configured flow)
Saving --> Config : pnp.save() OK (unconfigured flow, moves to next step)

Saved --> FwCheck : After 3s delay

FwCheck : Checks for firmware
FwCheck --> WifiReady : No new firmware
FwCheck --> WifiReady : Firmware update completes

NeedReconnect --> TestingReconnect : User clicks Next
TestingReconnect --> FwCheck : Reconnect OK (configured flow)
TestingReconnect --> Config : Reconnect OK (unconfigured flow)
TestingReconnect --> NeedReconnect : Reconnect fails

WifiReady --> DashboardView <<end>> : User clicks Done
FetchError --> HomeView <<end>> : User clicks Try Again

@enduml
```

---

## To-Be State Diagram (After Refactor)

The goal of the refactor is to centralize all state and transition logic into a `PnpNotifier`. A unified `PnpFlowStatus` enum will be used to explicitly define every state in the process. The UI layer will only be responsible for reacting to the state and rendering, without containing any flow control logic.

This approach transforms the entire PnP process into a single, linear, and predictable state machine.

```plantuml
@startuml
title Unified PnP Flow State (After Refactor)

[*] --> AdminInitializing

state AdminPhase {
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

state WizardPhase {
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
