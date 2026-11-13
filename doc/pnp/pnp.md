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
    - `PnpWifiStepView`, `PnpGuestStepView`, `PnpYourNetworkStepView`: the wizard's
      steps, one route each (#1511 P4)
    - `PnpFlowShell` + `PnpFlowFrameView`: the shell over `/pnp` — navigation, the
      top bar, the stepper and the status screens (saving, reconnect, firmware,
      completion)
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

**Flow Branching** — the navigation is `PnpFlowShell`'s, the `ShellRoute` over
the `/pnp` tree, which maps phases to pages in one place (`pnpFlowDestination`,
#1511 P2); `PnpEntryView` only renders the checks:
- Internet connected → `WizardConfiguring` → navigate to `/pnp/config`
- No internet → `NoInternet` → navigate to `/pnpNoInternetConnection/pnp`
- Router could not be read → `AdminReadFailure` → show its error card with Try again

### 3.3. Network Troubleshooter Flow

When no internet connection is detected, this flow provides solutions.

*   **Entry Page**: `PnpNoInternetView`
*   **User Options**:
    1.  **Option A - Restart Modem**: Physical power cycle guide
        *   Flow: `PnpUnplugModemView` → `PnpModemLightsOffView` → `PnpWaitingModemView`
    2.  **Option B - Manual ISP Settings**: Enter ISP connection info
        *   Flow: `PnpIspSettingsView` → `PnpStaticIpView` / `PnpPppoeView`
*   **Outcome**: Re-check internet. Success → the caller's ending (for PnP, back to
    `/pnp`, which re-runs the check and starts the wizard); Failure → stay in
    troubleshooter.
*   **State**: its own, not PnP's (#1511 P1) — `internetTroubleshootingProvider`,
    with the WAN prefill in `troubleshootingWanPrefillProvider`. The caller is the
    `:caller` segment of every troubleshooting URL (`pnp` or `dashboard`), turned
    into a `TroubleshootingEnding` by the route layer; see `pnp-flow.md`.

### 3.4. Setup Wizard Flow (the steps under `/pnp/pnpConfig`)

Multi-step wizard for WiFi configuration:

*   **Steps**: Wi-Fi, guest Wi-Fi (only when the router has a guest SSID), Your
    Network (mesh node confirmation, holds Save). Which steps, in which order, is a
    plan built once when the wizard reads the router; each setting step edits a
    draft of its own. See `pnp-flow.md` for the plan, the back policy and leaving.
*   **Save Flow**:
    1. `WizardSaving` → save WiFi settings
    2. `PnpStatusService.acknowledge(serialNumber)` → mark PnP complete
    3. If SSID changed → `WizardNeedsReconnect` → user reconnects to new WiFi
    4. `WizardTestingReconnect` → poll router with exponential backoff
    5. `WizardCheckingFirmware` → the router's OTA check; `WizardUpdatingFirmware` while an update installs (locked)
    6. `WizardWifiReady` → show new credentials + QR code → Done

## 4. State Management

*   **`PnpState`**: Single Source of Truth with sealed class `PnpPhase` for exhaustive switch.
*   **Key Phases**:
    - `AdminCheckingInternet`: Entry point, checking WAN status
    - `AdminInternetConnected`: Ready to proceed to wizard
    - `NoInternet`: Route to troubleshooter
    - `WizardConfiguring`: User on the steps (the form itself is in the drafts)
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
│   ├── pnp_flow_plan.dart       # Which steps, in which order — built once
│   ├── pnp_wifi_settings.dart   # Main / guest Wi-Fi as a step edits it
│   ├── pnp_wifi_write.dart      # What one save writes (both drafts)
│   ├── pnp_isp_config.dart      # ISP settings model
│   └── pnp_trigger_result.dart  # PnpStatusService check result
├── providers/
│   ├── pnp_providers.dart       # Provider exports
│   ├── pnp_notifier.dart        # State machine logic
│   ├── pnp_setting_steps.dart   # The step list + the flow-level dirty guard
│   └── pnp_wifi_drafts.dart     # One Preservable draft per setting step
├── services/
│   ├── pnp_service.dart         # USP operations
│   └── pnp_status_service.dart  # PnP completion tracking
└── views/
    ├── pnp_entry_view.dart      # Flow entry (internet check)
    ├── pnp_flow_shell.dart      # The shell: navigation, back policy
    ├── pnp_flow_frame_view.dart # Top bar, stepper, status screens
    ├── pnp_setting_step_pages.dart # The step list's page side
    ├── pnp_wifi_step_view.dart
    ├── pnp_guest_step_view.dart
    ├── pnp_your_network_step_view.dart
    ├── pnp_no_internet_view.dart
    ├── pnp_isp_settings_view.dart
    ├── pnp_pppoe_view.dart
    ├── pnp_static_ip_view.dart
    ├── pnp_unplug_modem_view.dart
    ├── pnp_modem_lights_off_view.dart
    └── pnp_waiting_modem_view.dart
```
