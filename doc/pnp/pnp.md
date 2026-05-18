# PnP (Plug and Play) Setup Feature Specification (v3)

## Change Log

### v3 (2026-05)
- **Login-First Architecture**: User must authenticate via `LoginLocalView` before PnP check
- Removed: `PnpAdminView`, admin login phases (`AdminInitializing`, `AdminAwaitingPassword`, `AdminLoggingIn`, `AdminLoginFailed`)
- Added: `PnpEntryView`, `PnpStatusService`
- Changed: PnP check moved from pre-login to post-login in `router_provider.dart`
- **Reason**: Firmware PR #19 rejected the following proposed endpoints:
  - `GET /api/v1/setup/status` — check if setup is complete
  - `POST /api/v1/setup/acknowledge` — mark setup as complete
  
  TR-181 does not currently have parameters for PnP status tracking (e.g., `Device.X_LINKSYS.Setup.*`).
  Until firmware adds such parameters, we use `LocalPnpStatusService` with SharedPreferences as a fallback.

## 1. Overview
This document describes the architecture and core flows of the "Instant Setup" (PnP) feature. This feature guides the user through the initial setup of a router, from checking internet connectivity to customizing Wi-Fi, guest networks, and other settings.

## 2. Core Architecture
This feature adopts a State-Driven architecture, with responsibilities clearly divided into layers:

*   **View Layer**: 
    - `PnpEntryView`: Lightweight flow entry point (internet check only)
    - `PnpSetupView`: Setup wizard main body
*   **Logic Layer (Notifier)**: `PnpNotifier` acts as the brain, executing business logic, making API calls, and managing state.
*   **Data Layer (State)**: `PnpState` stores all flow state using sealed class phases.
*   **Service Layer**: 
    - `PnpService`: USP operations for WiFi, WAN, mesh topology
    - `PnpStatusService`: PnP completion status tracking
      - Current: `LocalPnpStatusService` (SharedPreferences) — TR-181 has no PnP status parameters yet
      - Future: `Tr181PnpStatusService` — when `Device.X_LINKSYS.Setup.*` becomes available

## 3. Core Flows

The PnP flow is triggered **after successful login** based on `PnpStatusService.check()` result.

### 3.1. Entry Point & Pre-checks

**Flow:**
```
User opens app
  → LoginLocalView (user authenticates)
  → router_provider._prepare()
  → PnpStatusService.check(serialNumber)
  → If needsPnp=true → /pnp (PnpEntryView)
  → If needsPnp=false → /usp/dashboard
```

**PnP Trigger Conditions** (`LocalPnpStatusService`):
- No acknowledged serial number in SharedPreferences → needs PnP
- Serial number changed (different router) → needs PnP
- Serial number matches acknowledged → skip PnP

### 3.2. PnpEntryView Flow

`PnpEntryView` assumes user is already authenticated. On mount:

1. Calls `PnpNotifier.startPostLoginFlow()`
2. Fetches device info (serial number, model name)
3. Checks internet connectivity

**Flow Branching:**
- Internet connected → `WizardConfiguring` → navigate to `/pnp/config`
- No internet → `NoInternet` → navigate to `/pnpNoInternetConnection`
- Error → `AdminError` → show error with retry

### 3.3. Network Troubleshooter Flow

When no internet connection is detected, this flow provides solutions.

*   **Entry Page**: `PnpNoInternetView`
*   **User Options**:
    1.  **Option A - Restart Modem**: Physical power cycle guide
        *   Flow: `PnpUnplugModemView` → `PnpModemLightsOffView` → `PnpWaitingModemView`
    2.  **Option B - Manual ISP Settings**: Enter ISP connection info
        *   Flow: `PnpIspSettingsView` → `PnpStaticIpView` / `PnpPppoeView`
*   **Outcome**: Re-check internet. Success → wizard; Failure → stay in troubleshooter.

### 3.4. Setup Wizard Flow (`PnpSetupView`)

Multi-step wizard for WiFi configuration:

*   **Steps**: `PersonalWiFiStep`, `GuestWiFiStep`, `YourNetworkStep` (mesh node confirmation)
*   **Save Flow**:
    1. `WizardSaving` → save WiFi settings
    2. `PnpStatusService.acknowledge(serialNumber)` → mark PnP complete
    3. If SSID changed → `WizardNeedsReconnect` → user reconnects to new WiFi
    4. `WizardTestingReconnect` → poll router with exponential backoff
    5. `WizardCheckingFirmware` → (placeholder for future FW update)
    6. `WizardWifiReady` → show new credentials + QR code → Done

## 4. State Management

*   **`PnpState`**: Single Source of Truth with sealed class `PnpPhase` for exhaustive switch.
*   **Key Phases**:
    - `AdminCheckingInternet`: Entry point, checking WAN status
    - `AdminInternetConnected`: Ready to proceed to wizard
    - `NoInternet`: Route to troubleshooter
    - `WizardConfiguring`: User editing WiFi settings
    - `WizardSaving` / `WizardSaved`: Save in progress / complete
    - `WizardNeedsReconnect` / `WizardTestingReconnect`: WiFi SSID changed, reconnecting
    - `WizardWifiReady`: Setup complete

## 5. Session Restore Scenarios

| Scenario | Behavior |
|----------|----------|
| First login | Login → PnP check → needsPnp=true → /pnp |
| PnP interrupted, app reopened | Auto restore session → PnP check → needsPnp=true → /pnp (wizard state reset) |
| PnP completed, app reopened | Auto restore session → PnP check → needsPnp=false → dashboard |
| Different router | Restore session → PnP check → SN mismatch → /pnp |

## 6. File Structure

```
lib/page/instant_setup/
├── models/
│   ├── pnp_state.dart           # PnpState + PnpPhase sealed classes
│   ├── pnp_wifi_config.dart     # WiFi form data model
│   ├── pnp_isp_config.dart      # ISP settings model
│   └── pnp_trigger_result.dart  # PnpStatusService check result
├── providers/
│   ├── pnp_providers.dart       # Provider exports
│   └── pnp_notifier.dart        # State machine logic
├── services/
│   ├── pnp_service.dart         # USP operations
│   └── pnp_status_service.dart  # PnP completion tracking
└── views/
    ├── pnp_entry_view.dart      # Flow entry (internet check)
    ├── pnp_setup_view.dart      # Wizard main body
    ├── pnp_no_internet_view.dart
    ├── pnp_isp_settings_view.dart
    ├── pnp_pppoe_view.dart
    ├── pnp_static_ip_view.dart
    ├── pnp_unplug_modem_view.dart
    ├── pnp_modem_lights_off_view.dart
    └── pnp_waiting_modem_view.dart
```
