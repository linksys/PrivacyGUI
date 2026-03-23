# PnP USP Migration Analysis Report

> Investigation date: 2026-03-20
> Last updated: 2026-03-20 (P1 implementation complete)
> Router firmware: 1.0.16.26013014 (M60TB-EU / PINNACLE 2.0)
> USP bridge: v0.1.1 | OBUSPA: TR-181 2.18.1

## 1. Overview

This document records the findings from investigating how to bring back the PnP (Plug and Play) / Instant Setup feature under the USP-only architecture. The original PnP was built on JNAP; this report maps every PnP operation to its USP equivalent and identifies gaps.

## 2. PnP Flow → USP API Mapping

### 2.1 AdminPhase (Pre-checks)

| PnP Operation | Old JNAP Action | USP Equivalent | Status |
|---|---|---|---|
| Fetch device info | `GetDeviceInfo` | `SystemInfo.fetch(usp)` | ✅ Ready |
| Check router configured | `GetSetupModuleStatus` | Default-password login test (see §3) | ⚠️ Indirect |
| Check internet connection | `GetWANStatus` | `WanStatus.fetch(usp)` — `status=='Up' && ipAddress!=''` | ✅ Ready |
| Check internet (ping) | — | `NetworkDiagnostics.ping(usp, host: '8.8.8.8')` | ✅ Ready |
| Submit admin password | `CheckAdminPassword` | `UspService.login(password)` | ✅ Ready |

### 2.2 WizardPhase (Setup Steps)

| PnP Operation | Old JNAP Action | USP Equivalent | Status |
|---|---|---|---|
| Save WiFi SSID | `SetRadioInfo` | `WiFiSsids.updateMany(usp, [...])` | ✅ Ready |
| Save WiFi password | `SetRadioInfo` | `WiFiAccessPoints.updateMany(usp, [...])` | ✅ Ready |
| Save Guest WiFi | `SetGuestRadioSettings` | Same as above (SSID.3/SSID.4 instances) | ✅ Ready |
| Save admin password | `SetAdminPassword` | `AdminUsers.update(usp, AdminUserUpdate(password:))` | ⏸️ Deferred (see §4.4) |
| Night Mode (LED schedule) | `GetLedNightModeSetting` / `SetLedNightModeSetting` | `Device.LEDs.LED.{i}.Enable` (on/off only, see §4.5) | ⚠️ Partial |
| Your Network (mesh nodes) | `GetDevices` / mesh topology | `DataElementsNetwork.fetch(usp)` — codegen ready | ✅ Ready |
| Set ISP — PPPoE | `SetWANSettings` | `WanSettings.save(usp, pppUsername:, pppPassword:, pppoeServiceName:)` | ✅ Ready |
| Set ISP — Static IP | `SetWANSettings` | `WanSettings.save(usp, staticIpAddress:, subnetMask:, defaultGateway:, dnsServer1:, ...)` | ✅ Ready |
| Set ISP — DHCP | `SetWANSettings` | `WanOperations.renewDhcpLease(usp)` | ✅ Ready |
| Check firmware | `GetFirmwareUpdateStatus` | `FirmwareImages.fetch(usp)` | ✅ Ready |
| Trigger firmware update | `UpdateFirmware` | — | ❌ Missing (see §4.3) |
| Reboot | `Reboot` | `Device.Reboot()` Operate | ✅ Done (P0) |

### 2.3 TroubleshooterPhase (No Internet)

| PnP Operation | USP Equivalent | Status |
|---|---|---|
| **Option A — Restart modem** (3-step guided flow) | UI-only (no API needed) | ✅ Ready |
| ↳ Step 1: Unplug modem | `PnpUnplugModemView` — instruct user | UI-only |
| ↳ Step 2: Verify lights off | `PnpModemLightsOffView` — visual check | UI-only |
| ↳ Step 3: Wait & reconnect | `PnpWaitingModemView` — 150s countdown → plug back → auto-check (30 attempts) | `WanStatus.fetch()` |
| **Option B — Manual ISP settings** | | |
| ↳ ISP type selection | Radio buttons: DHCP / PPPoE / Static IP | UI-only |
| ↳ Set DHCP | `WanOperations.renewDhcpLease(usp)` | ✅ Works |
| ↳ Set PPPoE | `WanSettings.save(usp, pppUsername:, pppPassword:)` | ❌ **Broken** (see §4.7) |
| ↳ Set Static IP | `WanSettings.save(usp, staticIpAddress:, ...)` | ⚠️ **Partial** (see §4.7) |
| Retry internet check | `WanStatus.fetch()` or `NetworkDiagnostics.ping()` | ✅ Ready |

### 2.4 ReconnectionPhase (After WiFi/WAN Change)

| PnP Operation | USP Equivalent | Status |
|---|---|---|
| Wait for router reboot | Polling `SystemInfo.fetch(usp)` with timeout | ✅ Ready |
| Verify router identity | `SessionService.checkRouterIsBack(expectedSerialNumber)` | ✅ Already implemented |
| Re-authenticate after reboot | `UspService.login(password)` | ✅ Ready |

## 3. Factory Default Detection

### 3.1 The Problem

The original JNAP used `GetSetupModuleStatus` to check if the router was in factory-default state. In USP/TR-181, there is **no standard parameter** for this.

### 3.2 Router-Side Investigation

**UCI values (NOT accessible via USP):**

```
linksys.device.configured='0'            ← Primary factory-default flag
lsadmin.user.password_is_default='1'     ← Admin password unchanged
lsadmin.user.user_set_password='0'       ← User never set password
linksys.wireless.setup_vap_enabled='1'   ← Setup WiFi AP still active
```

**TR-181 values (accessible via USP):**

```
Device.DeviceInfo.FirstUseDate = "0001-01-01T00:00:00Z"   ← Zero = never used
Device.DeviceInfo.ProvisioningCode = ""                    ← Empty
Device.Users.User.1.Password = ""                          ← Always empty on read (security)
```

### 3.3 Recommended Detection Strategy

Since `linksys.device.configured` is not exposed through TR-181, use a **combined approach**:

```
Step 1: Attempt UspService.login('admin')
  ├─ Success → Password is still default → likely unconfigured
  │   Step 2: Read Device.DeviceInfo.FirstUseDate
  │     ├─ "0001-01-01T00:00:00Z" → Confirmed unconfigured → Enter full PnP wizard
  │     └─ Valid date → Configured but password reset to default → Enter standard flow
  └─ Failure → Password changed → Not factory default → Normal login page
```

### 3.4 Long-Term Recommendation

Request the firmware team to expose `linksys.device.configured` as a TR-181 vendor parameter:

```
Device.DeviceInfo.X_LINKSYS_Configured = "0" | "1"
```

This is a small bbfdm plugin change and would eliminate the need for the indirect detection approach.

## 4. Missing YAML Definitions

### 4.1 Device Operations (Reboot + FactoryReset) — ✅ P0 Complete

**YAML created:** `definitions/core/device_operations.yaml`
**Generated:** `lib/generated/device_operations.g.dart`

```yaml
name: device_operations
description: "Device lifecycle operations (reboot, factory reset)"
type: operate
operations:
  - name: reboot
    command: "Device.Reboot()"
    description: "Reboot the router"
  - name: factoryReset
    command: "Device.FactoryReset()"
    description: "Reset router to factory defaults"
```

### 4.2 SystemInfo Extension (FirstUseDate) — ✅ P0 Complete

Added to `definitions/core/system_info.yaml` and regenerated:

```yaml
# Added params:
- path: Device.DeviceInfo.FirstUseDate
  name: firstUseDate
  type: string
- path: Device.DeviceInfo.Description
  name: description
  type: string
- path: Device.DeviceInfo.ProductClass
  name: productClass
  type: string
```

### 4.3 Firmware Update Trigger

**Status: Unknown.** The firmware update mechanism on this router is managed by `linksys.fwup.*` UCI config, using a proprietary update server (`https://update1-stage.linksys.com`). No standard TR-181 Operate command for firmware download/install was found in the BBF service registrations.

Possible TR-181 paths (need firmware team confirmation):
- `Device.DeviceInfo.FirmwareImage.{i}.Download()` — standard TR-181
- `Device.SoftwareModules.ExecEnv.{i}.Reset()` — alternative
- Vendor-specific: `Device.X_LINKSYS_FirmwareUpdate()`

**Recommendation:** For MVP, skip auto-firmware-update in PnP. Show firmware info only and prompt user to check manually. Add firmware Operate after confirming with firmware team.

### 4.4 Admin Password Change — ⏸️ Deferred

**Status: Removed from P1 wizard.** Admin password change step was originally planned as Step 2 of the setup wizard, but was removed during implementation due to two unresolved dependency issues:

1. **Unconfigured flow (password = 'admin'):** After PnP setup, the password should be set to the router's factory-specific password (printed on the device label), not left as `admin`. This requires a FW API to retrieve the factory password — **no such API exists yet**.

2. **Configured flow (password != 'admin'):** If the user has already changed the password, there's no need to change it again during PnP. But determining whether the user explicitly changed it or it was set by another mechanism requires FW support — **`lsadmin.user.user_set_password` is UCI-only, not exposed in TR-181**.

**Current behavior:** PnP persists authentication using `PnpService.defaultPassword` ('admin'). The `AdminUsers.update()` codegen class is ready but not called from the wizard.

**Resolution path:**
- Request FW team to expose `Device.Users.User.1.X_LINKSYS_FactoryPassword` (or equivalent)
- Request FW team to expose `Device.Users.User.1.X_LINKSYS_IsDefaultPassword` flag
- Once available, add admin password step back to wizard as Step 3

### 4.5 Night Mode (LED Scheduling) — ⚠️ Needs Investigation

**Status: TR-181 LED paths exist but scheduling capability unknown.**

The original PnP `NightModeStep` used JNAP actions `GetLedNightModeSetting` / `SetLedNightModeSetting` to schedule LED on/off times (default 8PM–8AM). The data model:

```
isNightModeEnable: bool    ← Master toggle
startHour: int             ← Hour LED turns off (0-24)
endHour: int               ← Hour LED turns back on (0-24)
allDayOff: bool            ← LED always off
```

**TR-181 LED paths available** (27 parameters under `Device.LEDs.LED.{i}.*`):

| Path | Type | Can replace? |
|---|---|---|
| `Device.LEDs.LED.{i}.Enable` | read-write | ✅ On/off toggle (no scheduling) |
| `Device.LEDs.LED.{i}.MaxBrightness` | read-write | Brightness control only |
| `Device.LEDs.LED.{i}.CycleElement.{i}.*` | read-write | Animation cycles (not time-of-day schedule) |

**Gap:** Standard TR-181 `Device.LEDs` supports enable/disable and animation cycles, but **does NOT support time-of-day scheduling** (start hour / end hour). The night mode scheduling is JNAP-specific.

**Needs FW investigation:**
- Is there a `Device.LEDs.X_LINKSYS_NightMode.*` vendor extension?
- Or does FW handle scheduling internally via UCI (`linksys.wireless.night_mode_*`)?
- Fallback: Use `Device.LEDs.LED.{i}.Enable` for simple on/off toggle (no scheduling)

**YAML needed:** `definitions/core/led_status.yaml` — multi-instance table for `Device.LEDs.LED.{i}.*`

### 4.6 Mesh Node Display (YourNetworkStep) — ✅ USP Ready

**Status: Codegen ready, just needs PnP view integration.**

The original `YourNetworkStep` displayed connected mesh nodes with location, model, and device images, plus an "Add Nodes" option.

**USP equivalent:**
- `DataElementsNetwork.fetch(usp)` → returns list of `MeshNode` (ID, model, manufacturer, SN, SW version, radios, BSSes, stations)
- YAML: `definitions/wifi/data_elements_network.yaml` (already exists)
- Generated: `lib/generated/data_elements_network.g.dart`
- Mesh enricher: `lib/page/_shared/providers/mesh_node_enricher.dart` (already exists)

**Note:** "Add Nodes" feature (mesh onboarding) is a separate capability from displaying existing nodes. Mesh node onboarding via USP needs separate investigation.

### 4.7 WAN Settings (ISP Configuration) — ❌ PPPoE/Static Broken

**Status: Only DHCP works. PPPoE and Static IP have critical issues.**

PnP troubleshooter calls `WanSettings.save()` for PPPoE and Static IP, but multiple TR-181 paths are non-writable or require instance lifecycle management that doesn't exist.

#### PnP Impact by ISP Type

| ISP Type | PnP Call | Result |
|---|---|---|
| DHCP | `WanOperations.renewDhcpLease()` | ✅ Works |
| PPPoE | `WanSettings.save(pppUsername, pppPassword, pppoeServiceName)` | ❌ Broken — PPP instance missing (fault 9005), ServiceName denied (fault 9001) |
| Static IP | `WanSettings.save(staticIpAddress, subnetMask, defaultGateway, dnsServer1, dnsServer2)` | ⚠️ Partial — IP/Subnet OK, but Gateway (fault 9008) and DNS (fault 9008/9005) non-writable |

#### Critical Issues

| ID | Issue | FW Dependency |
|---|---|---|
| ISS-1 | `AddressingType` Set is a no-op — cannot switch WAN type | **Needs FW** |
| ISS-2 | `Device.PPP.Interface.1.*` doesn't exist in DHCP mode — need Add/Delete lifecycle | Codegen + FW |
| ISS-3 | Gateway path non-writable — **fixable** with `X_LINKSYS_DefaultGateway` | ✅ YAML fix |
| ISS-4 | DNS paths non-writable/missing — **fixable** with `X_LINKSYS_DNSServers` | ✅ YAML fix |
| ISS-7 | `PPPoE.ServiceName` fault 9001 "Request denied" | **Needs FW** |

#### Quick Fixes (no FW dependency)

1. `wan_settings.yaml`: Swap `defaultGateway` path to `Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DefaultGateway`
2. `wan_settings.yaml`: Swap `dnsServer1/2/3` paths to `Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DNSServers` (comma-separated)
3. `wan_settings.yaml`: Change `lcpEcho` to `writable: false`
4. Regenerate codegen → Static IP will work

#### Requires FW + Codegen Work

1. PPP.Interface Add/Delete lifecycle (switch to PPPoE mode)
2. VLANTermination Add/Delete lifecycle (enable VLAN tagging)
3. AddressingType switching mechanism (FW must implement)
4. PPPoE.ServiceName write permission (FW must fix)

**Full analysis:** `doc/usp/issues/internet-settings-jnap-vs-usp-comparison.md`

## 5. Router Data Model Reference

### 5.1 Vendor Prefix

```
/etc/obuspa/vendor_prefix → "X_LINKSYS_"
```

### 5.2 Confirmed X_LINKSYS_ Parameters (via DeviceInfo subtree query)

| TR-181 Path | Value (example) |
|---|---|
| `Device.DeviceInfo.X_LINKSYS_BaseMACAddress` | `74:12:13:21:55:02` |
| `Device.DeviceInfo.NetworkProperties.X_LINKSYS_ActiveConnections` | `496` |
| `Device.DeviceInfo.NetworkProperties.X_LINKSYS_MaxConnections` | `65535` |
| `Device.DeviceInfo.X_LINKSYS_FileDescriptors.Used` | `1056` |
| `Device.DeviceInfo.X_LINKSYS_FileDescriptors.MaxAllowed` | `42117` |
| `Device.DeviceInfo.ProcessStatus.X_LINKSYS_MaxProcessEntries` | `50` |
| `Device.DeviceInfo.ProcessStatus.X_LINKSYS_ProcessCurrentSortingMethod` | `Memory` |

### 5.3 BBF Service Daemons

| Service | BBF Object | Relevant to PnP |
|---|---|---|
| sysmngr | `Device.DeviceInfo` | ✅ SystemInfo, FirstUseDate |
| core | `Device.Reboot()`, `Device.FactoryReset()` | ✅ Lifecycle ops |
| wifidmd | `Device.WiFi` | ✅ SSID, AP, Radio |
| netmngr | `Device.IP`, `Device.PPP`, `Device.Routing` | ✅ WAN settings |
| dhcpmngr | `Device.DHCPv4`, `Device.DHCPv6` | ✅ DHCP renewal |
| usermngr | `Device.Users` | ✅ Admin password |
| gateway-info | `Device.GatewayInfo` | Limited (ManufacturerOUI, ProductClass, SerialNumber, MACAddress) |
| custommngr | `Device.X_CISCO_COM_Custom` | Not useful for PnP |
| trustdomainmngr | `Device.X_LINKSYS_TRUSTDOMAIN` | Not useful for PnP |

### 5.4 Setup VAP (Virtual Access Point) Architecture

The router uses a dedicated "setup" WiFi network for PnP:

```
linksys.wireless.setup_vap_enabled='1'
linksys.wireless.svap_lan_ifname='br-setup'
linksys.wireless.svap_vlan_id='4'
linksys.wireless.setup_vap_subnet='192.168.20.0'
linksys.wireless.setup_vap_ipaddr='192.168.20.1'
linksys.wireless.wl0_setup_vap='ath6'   ← 2.4GHz setup AP
```

This setup VAP broadcasts a separate WiFi for initial device configuration. The bridge and USP services are accessible at `192.168.20.1` when connected to this network. **This is UCI-managed and not controllable through TR-181.**

### 5.5 Guest WiFi Architecture

```
linksys.wireless.guest_enabled='0'             ← Master switch
linksys.wireless.wl0_guest_vap='ath2'          ← 2.4GHz guest AP
linksys.wireless.wl1_guest_vap='ath12'         ← 5GHz guest AP
linksys.wireless.guest_ssid='toob-215502-guest'
linksys.wireless.guest_password='BeMyGuest'
linksys.wireless.guest_lan_ifname='br-guest'
linksys.wireless.guest_subnet='192.168.3.0'
linksys.wireless.guest_max_allowed='5'
```

Guest WiFi SSID instances in TR-181:
- `Device.WiFi.SSID.3` → `ath2` (2.4GHz guest)
- `Device.WiFi.SSID.4` → `ath12` (5GHz guest)

Readable/writable via existing `WiFiSsids` and `WiFiAccessPoints` generated classes.

## 6. Existing USP Generated Classes (Ready for PnP)

| Generated Class | File | PnP Usage |
|---|---|---|
| `SystemInfo` | `system_info.g.dart` | Device info, serial number, software version |
| `WanStatus` | `wan_status.g.dart` | Internet connection check |
| `WanSettings` | `wan_settings.g.dart` | ISP configuration (PPPoE, Static IP, VLAN) |
| `WiFiSsids` | `wi_fi_ssids.g.dart` | WiFi SSID names (read + update) |
| `WiFiAccessPoints` | `wi_fi_access_points.g.dart` | WiFi security/passwords (read + update) |
| `WiFiRadios` | `wi_fi_radios.g.dart` | Radio band info |
| `AdminUsers` | `admin_users.g.dart` | Admin password change |
| `FirmwareImages` | `firmware_images.g.dart` | Firmware version check |
| `NetworkDiagnostics` | `network_diagnostics.g.dart` | Ping / Traceroute |
| `WanOperations` | `wan_operations.g.dart` | DHCP lease renewal |
| `LanNetworkInfo` | `lan_network_info.g.dart` | LAN IP / DHCP pool |

## 7. Implemented Architecture (P1)

```
lib/page/instant_setup/
├── models/
│   ├── pnp_state.dart             ← Sealed class hierarchy: PnpPhase (17 states)
│   ├── pnp_wifi_config.dart       ← WiFi form model (main + guest, dirty tracking)
│   ├── pnp_admin_config.dart      ← Admin password model (kept for future use)
│   └── pnp_isp_config.dart        ← ISP config model (DHCP/PPPoE/Static)
├── services/
│   └── pnp_service.dart           ← Stateless USP service (all codegen calls)
├── providers/
│   ├── pnp_providers.dart         ← Provider declarations
│   └── pnp_notifier.dart          ← Notifier<PnpState> state machine
└── views/
    ├── pnp_admin_view.dart        ← Entry: default-password probe + login form
    ├── pnp_setup_view.dart        ← Two-step wizard (Main WiFi → Guest WiFi)
    ├── pnp_no_internet_view.dart  ← Troubleshooter hub (modem restart / ISP settings)
    └── pnp_isp_settings_view.dart ← PPPoE / Static IP forms
```

### 7.1 State Machine (Sealed Class)

Complete transition map (17 states in `PnpPhase`):

```
AdminInitializing
  ├─ [default pw OK + factory default] → AdminUnconfigured
  ├─ [default pw OK + not factory]     → AdminUnconfigured (flowMode=unconfigured)
  ├─ [default pw fail]                 → AdminAwaitingPassword
  └─ [error]                           → AdminError

AdminUnconfigured → AdminCheckingInternet          (continueFromUnconfigured)
AdminAwaitingPassword → AdminLoggingIn              (submitPassword)
AdminLoggingIn
  ├─ [success] → AdminCheckingInternet
  └─ [fail]    → AdminLoginFailed
AdminLoginFailed → AdminLoggingIn                   (user retries submitPassword)

AdminCheckingInternet
  ├─ [WAN up + IP] → AdminInternetConnected → WizardInitializing
  └─ [no internet] → NoInternet              (view navigates to /pnpNoInternetConnection)

WizardInitializing
  ├─ [fetch OK] → WizardConfiguring
  └─ [error]    → WizardError

WizardConfiguring → WizardSaving                    (saveChanges)
WizardSaving
  ├─ [isMainDirty]     → WizardNeedsReconnect(newSsid, newPassword)
  ├─ [!isMainDirty]    → WizardSaved
  └─ [error]           → WizardConfiguring + errorMessage  (no WizardSaveFailed state)

WizardNeedsReconnect → WizardTestingReconnect       (testReconnect, exponential backoff)
WizardTestingReconnect
  ├─ [router found, SN match] → WizardSaved
  └─ [all attempts exhausted] → WizardNeedsReconnect (user can retry)

WizardSaved → WizardCheckingFirmware → WizardWifiReady  (FW update skipped, P3)

WizardWifiReady → [user Done] → /uspDashboard
WizardError → [user Try Again] → AdminInitializing     (startFlow)
AdminError → [user Try Again] → AdminInitializing      (startFlow)
```

#### Deviations from pnp-flow.md To-Be Design

| To-Be 設計 | 實際實作 | 原因 |
|---|---|---|
| `WizardInitFailed` 獨立狀態 | `WizardError` 通用錯誤 | 一個 error 狀態涵蓋所有 wizard 錯誤 |
| `WizardSaveFailed` → retry | 回到 `WizardConfiguring` + `errorMessage` | 直接回表單更自然 |
| `WizardUpdatingFirmware` 狀態 | 不存在，跳到 `WizardWifiReady` | FW update Operate 尚未確認 (P3) |
| Save/Reconnect 後依 configured/unconfigured 分流 | 統一以 `isMainDirty` 判定 | Admin password 步驟已移除，無 unconfigured 額外步驟 |
| `NoInternetRoute` 為終態 | `NoInternet` 留在 PnpPhase 內 | View 透過 `ref.listen` 觸發路由，state machine 不中斷 |

### 7.2 Wizard UI (Two-Step Stepper)

| Step | Content | Button |
|---|---|---|
| 0 — Main WiFi | SSID + password fields | **Next** (or **Save** if no guest network) |
| 1 — Guest WiFi | Enable toggle + SSID + password | **Back** / **Save** |

- Uses `AppStepper` (bar indicator, `StepIndicatorType.bar`) from ui_kit_library
- Bar indicator only shown when guest network instance paths exist
- Step state is local widget state (`_currentStep`), not in `PnpPhase`
- Back button in app bar navigates step → step 0 → `context.pop()`

### 7.3 Guest WiFi Detection

SSIDs are classified as main vs guest by **radio occupancy**: when multiple SSIDs share the same `lowerLayers` (radio interface), the first is main, subsequent are guest.

```dart
final seenRadios = <String>{};
for (final ssid in ssids.items) {
  if (seenRadios.contains(ssid.lowerLayers)) {
    guestSsids.add(ssid);    // Second SSID on same radio → guest
  } else {
    seenRadios.add(ssid.lowerLayers);
    mainSsids.add(ssid);     // First SSID per radio → main
  }
}
```

### 7.4 WiFi Credential Flow (Reconnection)

WiFi credentials must survive the reconnect phase. The chain:

```
saveChanges() → WizardNeedsReconnect(newSsid, newPassword)
  → testReconnect() extracts ssid/password from WizardNeedsReconnect
  → _checkFirmware(ssid:, password:)
  → WizardWifiReady(ssid:, password:)
```

`WizardNeedsReconnect` carries both `newSsid` and `newPassword` to avoid losing credentials during the reconnect polling loop.

### 7.5 Key Integrations

| Integration | Provider | Usage |
|---|---|---|
| Mutation lock | `uspMutationLockProvider.withLock()` | All WiFi save operations |
| Auth persist | `authProvider.notifier.localLogin()` | After save, persist credentials |
| SN persist | `SharedPreferences` + `sessionProvider` | Store configured SN for future route detection |
| Reconnect auth | `uspAuthCoordinatorProvider.restoreSession()` | Re-establish WASM session after WiFi change |

### 7.6 Route Integration

- Routes defined in `lib/route/route_pnp.dart` (`part of router_provider.dart`)
- `autoConfigurationLogic()`: if `LoginType.none` and no stored `pPnpConfiguredSN` → route to `/pnp`
- `/pnp` and `/pnpNoInternetConnection` bypass auth redirect
- Demo mode: `_DemoAuthNotifier.build()` returns `LoginType.none` to activate PnP routing

### 7.7 Dirty Tracking

`PnpWifiConfig` tracks changes separately for main and guest WiFi:

| Getter | Meaning |
|---|---|
| `isMainDirty` | SSID or password changed → triggers reconnect flow |
| `isGuestDirty` | Guest enable/SSID/password changed → no reconnect needed |
| `isDirty` | Any change → determines if save is meaningful |

## 8. Implementation Status

### 8.1 Completed (P0 + P1)

| Priority | Task | Effort | Status |
|---|---|---|---|
| **P0** | `device_operations.yaml` (Reboot, FactoryReset) + codegen | S | ✅ Complete |
| **P0** | `system_info.yaml` extension (FirstUseDate, Description, ProductClass) + codegen | S | ✅ Complete |
| **P1** | `PnpService` — factory-default detection + WiFi save (main + guest) | M | ✅ Complete |
| **P1** | `PnpNotifier` + `PnpState` — sealed class state machine (17 phases) | M | ✅ Complete |
| **P1** | PnP UI views — Admin login, WiFi wizard (2-step), Troubleshooter hub, ISP settings | L | ✅ Complete |
| **P1** | Reconnection polling (exponential backoff 2–32s, SN verification) | M | ✅ Complete |
| **P1** | Route integration (`route_pnp.dart`, auto-redirect, demo mode) | S | ✅ Complete |

### 8.2 Remaining — UI Only (no FW dependency)

| Priority | Task | Effort | Status | Notes |
|---|---|---|---|---|
| **P2** | Modem restart sub-flow — 3 guided views | M | 🔲 Not started | `UnplugModem → ModemLightsOff → WaitingModem` (150s countdown + 30-attempt auto-check). Pure UI, all localization keys exist. Route constants defined. |
| **P2** | ISP type selection view | S | 🔲 Not started | Radio buttons: DHCP / PPPoE / Static IP. Currently `pnp_isp_settings_view.dart` goes direct to form — needs type selector at top. |
| **P2** | YourNetworkStep — mesh node display | M | 🔲 Not started | Show connected nodes (model, location, image). `DataElementsNetwork.fetch()` codegen ready. Mesh enricher provider exists. "Add Nodes" is separate feature. |

### 8.3 Remaining — Blocked by Firmware

| Priority | Task | Effort | Status | FW Dependency |
|---|---|---|---|---|
| **P3** | NightModeStep — LED schedule (see §4.5) | M | ⏸️ Needs investigation | TR-181 has `Device.LEDs.LED.{i}.Enable` (on/off) but no time-of-day scheduling. Need FW to confirm vendor extension or alternative. |
| **P3** | Admin password step (see §4.4) | M | ⏸️ Deferred | Need `X_LINKSYS_FactoryPassword` + `X_LINKSYS_IsDefaultPassword` |
| **P3** | Firmware update Operate (see §4.3) | S | ⏸️ Deferred | Need FW to confirm Operate command path |

### 8.4 Nice-to-Have (FW Requests)

| Task | Effort | Status |
|---|---|---|
| Expose `Device.DeviceInfo.X_LINKSYS_Configured` ("0"/"1") | S | 🔲 Not started |
| Expose `Device.Users.User.1.X_LINKSYS_FactoryPassword` | S | 🔲 Not started |
| Expose `Device.Users.User.1.X_LINKSYS_IsDefaultPassword` | S | 🔲 Not started |
| Expose LED night mode scheduling via vendor extension | S | 🔲 Needs investigation |
| Create `led_status.yaml` YAML definition for `Device.LEDs.LED.{i}.*` | S | 🔲 Blocked on §4.5 |

## 9. Conclusion

**P0 + P1 complete.** Core PnP flow functional under USP-only architecture:

- Factory default detection (default-password probe + `FirstUseDate`)
- Main WiFi + Guest WiFi configuration (two-step stepper)
- ISP troubleshooting (PPPoE, Static IP, DHCP)
- Post-WiFi-change reconnection with exponential backoff polling
- Route auto-detection and demo mode integration

**P2 remaining (no FW dependency):**

- Modem restart 3-step guided flow (UI only, localization ready)
- ISP type selection (DHCP / PPPoE / Static IP radio buttons)
- YourNetworkStep — mesh node display (`DataElementsNetwork` codegen ready)

**P3 blocked by firmware team:**

1. **Night mode / LED scheduling** (§4.5) — TR-181 has on/off but no time-of-day schedule; need vendor extension investigation
2. **Admin password change** (§4.4) — needs factory password API + `IsDefaultPassword` flag
3. **Firmware update trigger** (§4.3) — needs Operate command confirmation
4. **`X_LINKSYS_Configured` flag** — would simplify factory-default detection

### Design Decisions Log

| Decision | Rationale |
|---|---|
| Removed admin password step from wizard | Both unconfigured and configured scenarios need FW APIs not yet available (§4.4) |
| Guest WiFi classified by radio occupancy | Multiple SSIDs sharing `lowerLayers` = guest; first per radio = main (§7.3) |
| `WizardNeedsReconnect` carries `newPassword` | WiFi credentials must survive reconnect polling loop without loss (§7.4) |
| `isMainDirty` determines reconnect | Only main WiFi SSID/password changes drop the connection; guest changes don't (§7.7) |
| Stepper step is local widget state | Avoids polluting `PnpPhase` sealed class with UI-only navigation concern |
| `AppStepper` bar indicator | Minimal visual footprint for a 2-step wizard; hidden when no guest network |
| `Notifier<PnpState>` not `AsyncNotifier` | State machine has discrete phase transitions, not a single async build |
