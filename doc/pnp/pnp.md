# PnP (Plug and Play) Setup Feature Specification (v2)

## 1. Overview
This document aims to describe the existing architecture and core flows of the "Instant Setup" feature. This feature guides the user through the initial setup of a router, from validating the router's status to customizing Wi-Fi, guest networks, and other settings.

## 2. Core Architecture
This feature adopts a State-Driven architecture, with responsibilities clearly divided into three layers:

*   **View Layer**: Composed of `PnpAdminView` (flow entry point) and `PnpSetupView` (setup wizard main body), responsible for rendering the UI based on the current state.
*   **Logic Layer (Notifier)**: Handled solely by `PnpNotifier`, which acts as the brain for the entire feature. It is responsible for executing all business logic, making API calls, and managing state.
*   **Data Layer (State)**: Composed of `PnpState` (stores all state) and `PnpException` (defines error types).

## 3. Core Flows

The core of this feature can be seen as a state machine that enters different flow branches based on the results of pre-checks.

### 3.1. Entry Point & Pre-checks (`PnpAdminView`)
This is the starting point for all flows. This page automatically executes a series of asynchronous checks to determine the current environment and triggers different flows based on the results:

1.  **`fetchDeviceInfo`**: Gets basic device information.
2.  **`checkRouterConfigured`**: Checks if the router is in a factory default (unconfigured) state.
3.  **`checkInternetConnection`**: Checks the internet connection status.

**Flow Branching Logic:**
*   If `checkInternetConnection` fails ➔ Throws `ExceptionNoInternetConnection` ➔ **Enter 3.2 Network Troubleshooter Flow**.
*   If `checkRouterConfigured` finds the router is **unconfigured** ➔ Throws `ExceptionRouterUnconfigured` ➔ **Enter 3.3 First-Time Setup Wizard Flow**.
*   If all checks succeed ➔ **Enter 3.4 Standard Setup Wizard Flow** (or complete the setup logically).

### 3.2. Network Troubleshooter Flow (`pnp_no_internet_connection_view.dart` & related pages)
When no internet connection is detected, this flow is initiated to provide the user with solutions.

*   **Entry Page**: `PnpNoInternetConnectionView`.
*   **User Options**: This page provides two main options:
    1.  **Option A - Restart Modem**: Guides the user through a physical power cycle of their modem.
        *   **Flow**: `PnpUnplugModemView` (Unplug) ➔ `PnpModemLightsOffView` (Check lights) ➔ `PnpWaitingModemView` (Wait for reboot and reconnect).
    2.  **Option B - Manual ISP Settings**: Allows the user to manually enter connection information provided by their Internet Service Provider (ISP).
        *   **Flow**: `PnpIspTypeSelectionView` (Select connection type) ➔ `PnpStaticIpView` / `PnpPPPOEView` (Enter corresponding info) ➔ `PnpIspSaveSettingsView` (Save and validate settings).
*   **Flow Outcome**: Both options will eventually re-attempt to check the internet connection. Success may lead back to the main flow; failure may keep the user in the troubleshooter flow.

### 3.3. First-Time Setup Wizard Flow (`PnpSetupView` - Unconfigured Mode)
When the router is in its factory default state, this full version of the setup wizard is initiated.

*   **Steps**: Includes all available setup steps, such as `PersonalWiFiStep`, `GuestWiFiStep`, `NightModeStep`, `YourNetworkStep`, etc.
*   **Goal**: To guide the user through the complete personalization of all core features from scratch, including Wi-Fi, passwords, nodes, etc.

### 3.4. Standard Setup Wizard Flow (`PnpSetupView` - Configured Mode)
When the router is already configured, but the user enters the flow via a specific entry point (e.g., from the dashboard), this simplified version of the setup flow may be initiated.

*   **Steps**: May only include a subset of modifiable steps, such as `PersonalWiFiStep`.
*   **Goal**: To allow the user to quickly modify some existing settings.

## 4. State Management
*   **`PnpState`**: Acts as the Single Source of Truth, storing all data that needs to be shared across pages during the flow.
*   **`PnpStepState`**: Stores the state of a single setup step, including user-entered data and the validation status of that step (`data`, `error`, `loading`).

## 5. Error Handling
*   Predictable errors in the flow are defined as subclasses of `PnpException`.
*   `catchError` blocks in `PnpAdminView` and `PnpNotifier` catch these specific exceptions and execute corresponding UI actions (e.g., page navigation) instead of crashing the application.