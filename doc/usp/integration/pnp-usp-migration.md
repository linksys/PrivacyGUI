# PnP USP Migration Analysis Report

> Investigation date: 2026-03-20
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
| Save admin password | `SetAdminPassword` | `AdminUsers.update(usp, AdminUserUpdate(password:))` | ✅ Ready |
| Set ISP — PPPoE | `SetWANSettings` | `WanSettings.save(usp, pppUsername:, pppPassword:, pppoeServiceName:)` | ✅ Ready |
| Set ISP — Static IP | `SetWANSettings` | `WanSettings.save(usp, staticIpAddress:, subnetMask:, defaultGateway:, dnsServer1:, ...)` | ✅ Ready |
| Set ISP — DHCP | `SetWANSettings` | `WanOperations.renewDhcpLease(usp)` | ✅ Ready |
| Check firmware | `GetFirmwareUpdateStatus` | `FirmwareImages.fetch(usp)` | ✅ Ready |
| Trigger firmware update | `UpdateFirmware` | — | ❌ Missing (see §4.3) |
| Reboot | `Reboot` | `Device.Reboot()` Operate | 🆕 Needs YAML (see §4.1) |

### 2.3 TroubleshooterPhase (No Internet)

| PnP Operation | USP Equivalent | Status |
|---|---|---|
| Restart modem guidance | UI-only flow (no API needed) | ✅ Ready |
| Set Static IP settings | `WanSettings.save(...)` | ✅ Ready |
| Set PPPoE settings | `WanSettings.save(...)` | ✅ Ready |
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

### 4.1 Device Operations (Reboot + FactoryReset)

**Confirmed available** in `/etc/bbfdm/services/core.json`:

```json
{ "parent_dm": "Device.", "object": "Reboot()" }
{ "parent_dm": "Device.", "object": "FactoryReset()" }
```

**New YAML definition needed:** `definitions/core/device_operations.yaml`

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

### 4.2 SystemInfo Extension (FirstUseDate)

Extend existing `definitions/core/system_info.yaml` to add:

```yaml
# Add to existing instance.params:
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

## 7. Proposed Architecture

```
lib/page/instant_setup/
├── providers/
│   ├── pnp_notifier.dart          ← Unified state machine (PnpFlowStatus enum)
│   ├── pnp_state.dart             ← PnpState + PnpStepState
│   └── pnp_service.dart           ← Encapsulates factory-default detection + save logic
├── views/
│   ├── pnp_admin_view.dart        ← Entry: pre-checks + login
│   ├── pnp_setup_view.dart        ← Setup wizard (stepper)
│   ├── pnp_no_internet_view.dart  ← No internet troubleshooter
│   ├── pnp_isp_settings_view.dart ← ISP manual settings (PPPoE / Static IP)
│   └── pnp_complete_view.dart     ← Setup complete + connect to new WiFi
└── models/
    └── pnp_exception.dart         ← Flow-control exceptions
```

State machine follows the To-Be diagram from `pnp-flow.md`:

```
AdminInitializing → AdminUnconfigured | AdminAwaitingPassword | AdminInternetConnected | AdminError
AdminCheckingInternet → WizardInitializing | NoInternetRoute
WizardInitializing → WizardConfiguring | WizardInitFailed
WizardConfiguring → WizardSaving → WizardSaved → WizardCheckingFirmware → WizardWifiReady
```

## 8. Implementation Priority

| Priority | Task | Effort | Dependencies |
|---|---|---|---|
| **P0** | New YAML: `device_operations.yaml` (Reboot, FactoryReset) + codegen | S | None |
| **P0** | Extend YAML: `system_info.yaml` (FirstUseDate, Description, ProductClass) + codegen | S | None |
| **P1** | `PnpService` — factory-default detection + save orchestration | M | P0 |
| **P1** | `PnpNotifier` + `PnpState` — state machine per To-Be diagram | M | P1 service |
| **P2** | PnP UI pages (Admin, Setup wizard, Troubleshooter, Complete) | L | P1 |
| **P2** | Reconnection polling logic after WiFi/WAN changes | M | P1 |
| **P3** | Firmware update Operate (needs FW team confirmation) | S | FW team |
| **Nice** | Request FW team: expose `X_LINKSYS_Configured` in TR-181 | S | FW team |

## 9. Conclusion

**~90% of PnP backend capabilities are ready** in the current USP layer. The existing 32 generated classes cover WiFi, WAN/ISP, admin password, device info, firmware, and network diagnostics. The primary gaps are:

1. **Factory default detection** — solvable with default-password login test + FirstUseDate (indirect but functional)
2. **Reboot Operate** — confirmed available on router, just needs YAML definition
3. **Firmware update trigger** — needs firmware team confirmation on Operate path
4. **Reconnection logic** — needs implementation in PnpNotifier (polling pattern)

The USP architecture provides a cleaner implementation path than JNAP: typed data classes with `fetch()`/`save()`/`update()` methods eliminate manual JSON serialization, and the state machine pattern from `pnp-flow.md` maps directly to a Riverpod `StateNotifier`.
