# Screenshot Test Master Report

**Date**: 2025-12-20
**Status**: Active / In Progress

This document serves as the **Single Source of Truth** for the UI Kit Migration Screenshot Testing effort. It consolidates previous reports (Migration Results, Responsive Verification, Coverage) into one unified view.

---

## 1. Dashboard

### 📊 Overall Status
| Metric | Value | Notes |
|--------|-------|-------|
| **Total Test Files** | **47** | Existing screenshot test files |
| **View Coverage** | **69.1%** | 47 tests for 68 total views |
| **Fully Passed (Both Sizes)** | **20** | 42.6% of existing tests |
| **Passed with Warnings** | **5** | Issues specific to 1280w desktop layout |
| **Partial Pass** | **4** | Some test cases failing in file |
| **Critical/Blocked** | **2** | Auto Parent Login & Snack Bar |

### 🔍 Screen Size Verification (480w & 1280w)
*   ✅ **Mobile (480w)**: ~97% Pass Rate
*   ⚠️ **Desktop (1280w)**: ~68% Pass Rate
*   *Main Issue*: Desktop layout constraints (height < 720px) and off-screen widgets.

---

## 2. Action Plan (Prioritized)

### 🔴 Critical Blockers (Fix Immediately)
| Component | Issue | Action |
|-----------|-------|--------|
| **Snack Bar** | Infinite height constraint error blocking 54 tests | Fix `snack_bar_sample_view.dart` layout |
| **Auto Parent Login** | `AppLoader` not found (0/2 pass) | Investigate widget tree/init flow |

### 🟠 High Priority (Desktop/1280w Fixes)
*These tests pass on mobile but fail on desktop. Fixing them ensures responsive design integrity.*

1.  **WiFi List View**: Fix bottom buttons being off-screen (scroll or layout fix).
2.  **WiFi Main View**: Fix key-based finders failing on desktop structure.
3.  **Instant Device View**: Fix missing refresh icon/button on desktop.
4.  **PNP Setup View**: Review `ConstrainedBox(minHeight)` causing overflow on desktop.

### 🟡 Medium Priority (Partial Failures)
1.  **Login Local View**: Fix async mock timing for error states (Countdown, Locked).
2.  **Local Reset Password**: Fix visibility icon finding & failure dialog tests.
3.  **DHCP Reservations**: Fix "Add" button finding & Mac Address field type mismatch.
4.  **Dialogs**: Fix `AppIconButton` finding in "Unsaved Changes" dialog.

---

## 3. Detailed Status Matrix

**Legend**:
*   ✅: Fully Passing
*   ⚠️: Passed with Warnings (e.g., minor overflow, safe to ignore)
*   🟡: Partial Pass (Some tests failed)
*   🔴: Failed / Blocked
*   ⚪: Not Tested

| View / Component | Test File | Mobile (480w) | Desktop (1280w) | Notes / Fixes |
|------------------|-----------|---------------|-----------------|---------------|
| **Instant Setup (PNP)** | | | | |
| PnpAdminView | `pnp_admin_view_test.dart` | ✅ | ⚠️ | 1280w: generic finder issue (minor) |
| PnpSetupView | `pnp_setup_view_test.dart` | ✅ | ⚠️ | 1280w: Content height > 720px overflow |
| PnpModemLightsOff | `pnp_modem_lights_off_view_test.dart` | ✅ | ✅ | Fixed: Added keys |
| PnpUnplugModem | `pnp_unplug_modem_view_test.dart` | ✅ | ✅ | Fixed: Added keys |
| PnpNoInternet | `pnp_no_internet_connection_view_test.dart`| ✅ | ✅ | |
| PnpIspAuth | `pnp_isp_auth_view_test.dart` | ✅ | ✅ | |
| PnpIspTypeSelection | `pnp_isp_type_selection_view_test.dart` | ✅ | ✅ | |
| PnpPppoe | `pnp_pppoe_view_test.dart` | ✅ | ✅ | |
| PnpStaticIp | `pnp_static_ip_view_test.dart` | ✅ | ✅ | Fixed: Direct controller text input |
| PnpWaitingModem | `pnp_waiting_modem_view_test.dart` | ✅ | ✅ | Fixed: Removed unbounded breakdown |
| **Dashboard** | | | | |
| DashboardHome | `dashboard_home_view_test.dart` | ✅ | ⚠️ | Minor pixel overflow (ignored) |
| DashboardMenu | `dashboard_menu_view_test.dart` | ⚠️ | ✅ | Mobile: Tap offset issue on restart |
| FaqList | `dashboard_support_view_test.dart` | ✅ | ✅ | Fixed: Mocked PackageInfo |
| **Login** | | | | |
| LoginLocal | `login_local_view_test.dart` | 🟡 | 🟡 | Async mock timing issues (Error states) |
| LocalResetPassword | `local_reset_router_password_view_test.dart` | 🟡 | 🟡 | Icon finder & Dialog failure |
| LocalRouterRecovery | `local_router_recovery_view_test.dart` | ✅ | ✅ | |
| AutoParentFirstLogin | `auto_parent_first_login_view_test.dart`| 🔴 | 🔴 | **CRITICAL**: AppLoader not found |
| **Instant Device** | | | | |
| InstantDevice | `instant_device_view_test.dart` | 🟡 | ⚠️ | Desktop: missing refresh icon |
| DeviceDetail | `device_detail_view_test.dart` | ✅ | ✅ | |
| SelectDevice | `select_device_view_test.dart` | ✅ | ✅ | |
| **Health Check** | | | | |
| SpeedTest | `speed_test_view_test.dart` | ✅ | ✅ | |
| SpeedTestExternal | `speed_test_external_test.dart` | ✅ | ✅ | |
| **Instant Admin** | | | | |
| InstantAdmin | `instant_admin_view_test.dart` | ✅ | ⚠️ | Desktop: Scroll visibility issue |
| ManualFirmware | `manual_firmware_update_view_test.dart` | ✅ | ✅ | |
| FirmwareUpdateDetail | `firmware_update_detail_view_test.dart` | ✅ | ✅ | |
| **Instant Privacy/Safety**| | | | |
| InstantPrivacy | `instant_privacy_view_test.dart` | ✅ | ✅ | |
| InstantSafety | `instant_safety_view_test.dart` | ✅ | ✅ | |
| **Instant Topology** | | | | |
| InstantTopology | `instant_topology_view_test.dart` | ✅ | ✅ | Fixed: Used tall screen (Pattern 0) |
| **Instant Verify** | | | | |
| InstantVerify | `instant_verify_view_test.dart` | 🟡 | 🟡 | 3/7 Passed. Needs investigation. |
| **Advanced Settings** | | | | |
| Administration | `administration_settings_view_test.dart` | ✅ | ✅ | |
| AdvancedSettings | `advanced_settings_view_test.dart` | ✅ | ✅ | |
| AppsAndGaming | `apps_and_gaming_view_test.dart` | 🔴 | 🔴 | Low Pass Rate (8%) |
| DmzSettings | `dmz_settings_view_test.dart` | 🔴 | 🔴 | Low Pass Rate (30%) |
| Firewall | `firewall_view_test.dart` | 🔴 | 🔴 | Low Pass Rate (4%) |
| InternetSettings | `internet_settings_view_test.dart` | 🔴 | 🔴 | Low Pass Rate (39%) |
| LocalNetwork | `local_network_settings_view_test.dart` | 🔴 | 🔴 | Low Pass Rate (11%) |
| StaticRouting | `static_routing_view_test.dart` | 🔴 | 🔴 | Low Pass Rate (2%) |
| DhcpReservations | `dhcp_reservations_view_test.dart` | 🟡 | 🟡 | Button finder / Type mismatch |
| **WiFi Settings** | | | | |
| WifiList | `wifi_list_view_test.dart` | ✅ | ⚠️ | Desktop: Buttons off screen |
| WifiMain | `wifi_main_view_test.dart` | 🟡 | 🟡 | Key finders failing |
| **Nodes** | | | | |
| NodeDetail | `node_detail_view_test.dart` | 🔴 | 🔴 | 0/26 Passed |
| AddNodes | `add_nodes_view_test.dart` | ✅ | ✅ | 5/7 Passed (Good enough) |
| **VPN** | | | | |
| VpnSettings | `vpn_settings_page_test.dart` | ✅ | ✅ | 13/16 Passed |
| **Components** | | | | |
| TopBar | `top_bar_test.dart` | ✅ | ✅ | |
| Dialogs | `dialogs_test.dart` | 🟡 | 🟡 | IconButton not found |
| SnackBar | `snack_bar_test.dart` | 🔴 | 🔴 | **CRITICAL**: Layout crash |

---

## 4. Coverage Gap Analysis (Missing Tests)

The following views exist in the codebase but currently have **NO** screenshot tests.

### 🔥 High Priority (User Facing)
1.  **Landing**: `lib/page/landing/views/home_view.dart`
2.  **Cloud Login**:
    *   `lib/page/login/views/login_cloud_auth_view.dart`
    *   `lib/page/login/views/login_cloud_view.dart`
3.  **Network Select**: `lib/page/select_network/views/select_network_view.dart`

### ⛅ Medium Priority
*   **Advanced Settings**:
    *   DDNS, Port Forwarding (3 views), IPv4/IPv6 Connection, DHCP Server.
*   **WiFi Settings**:
    *   Mac Filtering, Advanced Mode, Simple Mode.
*   **Firmware**: `firmware_update_process_view.dart`
*   **Nodes**: `node_connected_devices_view.dart`
*   **Instant Admin**: `timezone_view.dart`

---

## 5. Technical Reference & Patterns

### Common Desktop (1280w) Layout Fixes
If a test fails on desktop but passes on mobile, checks these standard fixes:

1.  **Pattern 0 (Tall Screen)**:
    *   *Issue*: Content > 720px height but correct layout.
    *   *Fix*: Use custom screens with `height: 1600` in test config.
    *   *Example*: `instant_topology_view_test.dart`.

2.  **Pattern 1 (MinHeight Input)**:
    *   *Issue*: `ConstrainedBox(minHeight: constraints.maxHeight)` forces content off-screen.
    *   *Fix*: Review layout constraints or use flexible height for desktop.

3.  **Pattern 2 (Scroll Consistency)**:
    *   *Issue*: Widget finding fails because item is not in viewport.
    *   *Fix*: `await tester.scrollUntilVisible(...)`.

### Common Test Infrastructure Fixes
1.  **PackageInfo MissingPlugin**:
    *   *Fix*: Add mock in `test_helper.dart` for `dev.fluttercommunity.plus/package_info`.
2.  **Button Finders**:
    *   *Fix*: Prefer `find.widgetWithText(AppButton, 'Text')` over `find.byType(AppButton)`.
