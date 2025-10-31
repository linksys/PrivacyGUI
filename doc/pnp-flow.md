# PnP (Plug and Play) 流程狀態機文檔

本文檔旨在通過狀態圖（State Diagram）來描述 PnP 流程在重構前後的變化。這有助於理解現有流程的複雜性，並展示重構後架構的優勢。

## 重構前狀態圖 (As-Is State Diagram)

在重構之前，PnP 流程的狀態邏輯分散在 `PnpAdminView` 和 `PnpSetupView` 兩個獨立的 `StatefulWidget` 中，並依賴大量的本地旗標（flags）和 `try-catch` 異常處理來控制 UI 流程。

### 1. `PnpAdminView` 流程

此視圖作為 PnP 流程的“守門員”，其狀態轉換高度依賴於 `runInitialChecks` 方法拋出的各種異常，導致流程分散且難以追蹤。

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

### 2. `PnpSetupView` 流程

此視圖是核心的設定精靈，其狀態由 `_PnpSetupStep` 枚舉和多個布林旗標（如 `_needToReconnect`, `_fetchError`）共同決定。狀態轉換邏輯混合在用戶交互、異步回調和外部事件監聽中，使其非常複雜。

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

## 重構後狀態圖 (To-Be State Diagram)

重構的目標是將所有狀態和轉換邏輯集中到 `PnpNotifier` 中，並使用一個統一的 `PnpFlowStatus` 枚舉來顯式定義流程中的每一個狀態。UI 層只負責響應狀態並渲染，不再包含任何流程控制邏輯。

這樣做使得整個 PnP 流程變成一個單一、線性和可預測的狀態機。

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
