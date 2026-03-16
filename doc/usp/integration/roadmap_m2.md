# USP Milestone 2 Roadmap — JNAP Migration Gap & Feasibility Analysis

> Date: 2026-03-16 | Branch: `feat/usp-protocol-integration`
> Based on: M1 Feature Roadmap, SSH Validation, USP Features Matrix, JNAP Alignment Analysis
> Router: Linksys M60TB-EU (PINNACLE 2.0) | Firmware: 1.0.16.26013014

---

## Migration Goal

**Fully eliminate JNAP dependency and migrate all features to USP protocol.**

M1 completed USP migration for 45/72 (63%) features. This document tracks USP support gaps for the remaining 27 features, categorized by blocker type, to guide firmware team communication and development scheduling.

All features still dependent on JNAP are considered **Migration Gaps**, requiring resolution or firmware team USP/vendor extension support.

---

## Scope

1. Remaining M1 pending features (WiFi management, Diagnostics, Performance)
2. Internet Settings write support (10 open issues)
3. WiFi Settings TR-181 limitations (4 issues)
4. DDNS, QoS, Parental Control feasibility (SSH-verified 2026-03-16)
5. **JNAP dependencies requiring USP vendor extension support**

---

## Status Overview

| Category | Total | ✅ USP Ready | 🔧 Needs Code Fix | 🏭 Needs FW Team | 🔴 USP Gap (JNAP dependency) |
|----------|-------|-------------|-------------------|-----------------|-------------------------------|
| M1 Pending Features | 8 | 6 | — | — | — |
| Internet Settings | 10 | — | 5 | 4 | 1 |
| WiFi Settings | 4 | — | 2 | 2 | — |
| WiFi Advanced / Security | 3 | 1 | 1 | — | 1 |
| DDNS | 1 | — | — | 1 | — |
| QoS | 4 | — | — | 1 | 3 |
| Parental Control | 3 | — | — | — | 2 |
| Remaining JNAP Dependencies | 7 | — | — | — | 7 |
| **Total** | **40** | **7** | **8** | **8** | **14** |

> 🔴 **USP Gap** = Feature currently only supported by JNAP, no corresponding USP path. Requires firmware team to provide vendor extension or bbfdm plugin to complete migration.

---

## 1. M1 Pending Features

These features have verified TR-181 support and are ready for implementation.

### F-001: WiFi SSID / Password / Security Management

**Priority:** P0 | **Effort:** Small | **Feasibility:** ✅ USP Ready (SSH-verified 2026-03-16)

- `Device.WiFi.AccessPoint.{i}.Security.KeyPassphrase` — validated SET-able
- `Device.WiFi.AccessPoint.{i}.Security.SAEPassphrase` — WPA3 password (writable)
- `Device.WiFi.AccessPoint.{i}.Security.ModeEnabled` — writable, supports: `None, WPA2-Personal, WPA3-Personal, WPA3-Personal-Transition, Enhanced-Open`
- `Device.WiFi.AccessPoint.{i}.Security.MFPConfig` — Management Frame Protection (writable)
- `Device.WiFi.AccessPoint.{i}.Security.Reset()` — Operate command
- Add `writable: true` to `wi_fi_access_points.yaml`, re-run codegen
- New dialog: WiFi password edit per AP/SSID + security mode selector
- **JNAP `setWPSServerSessionStatus` can be fully migrated to USP**

### F-004: WiFi Channel Width Edit

**Priority:** P1 | **Effort:** Small | **Feasibility:** ✅ USP Ready

- `Device.WiFi.Radio.{i}.OperatingChannelBandwidth` — available in codegen
- Mark as `writable` in `wi_fi_radios.yaml`
- Expand `wifi_channel_dialog.dart` with bandwidth selector

### F-007: Guest Network Management

**Priority:** P1 | **Effort:** Medium | **Feasibility:** ✅ USP Ready (with heuristic)

- BUG-001 fixed, WiFi SSID enumeration works
- Guest AP identification: AP index-based or `SSIDAdvertisementEnabled` heuristic
- See [wifi-settings-tr181-limitations.md ISS-4](../issues/wifi-settings-tr181-limitations.md) — reliable detection needs vendor extension

### F-011: Network Diagnostics (Ping / Traceroute)

**Priority:** P1 | **Effort:** Medium | **Feasibility:** ✅ SSE Infrastructure Ready

- Backend complete: `SseOperationAwaiter`, `PingResult`, `TracerouteResult`
- Remaining: UI page only (models, notifier, view, routing)
- Plan file: `noble-tickling-pumpkin.md`

### F-025: Historical Trend Analysis

**Priority:** P2 | **Effort:** Large | **Feasibility:** ⚠️ Client-Side Only

- No TR-181 historical storage — requires Hive local DB + background collection
- Weekly/monthly trend charts, seasonal analysis

### F-026: Dashboard Prefetch Cache

**Priority:** P1 | **Effort:** Medium | **Feasibility:** ✅ USP Ready

- Batch prefetch: 17 requests → 1 batch + 16 cache hits
- Target: dashboard load <500ms in high-latency networks

### F-027: WPS (Wi-Fi Protected Setup)

**Priority:** P2 | **Effort:** Small | **Feasibility:** ✅ USP Ready (SSH-verified 2026-03-16)

- `Device.WiFi.AccessPoint.{i}.WPS.Enable` — writable (toggle per AP)
- `Device.WiFi.AccessPoint.{i}.WPS.ConfigMethodsEnabled` — writable (`"PushButton"`)
- `Device.WiFi.AccessPoint.{i}.WPS.Status` — read-only (`Configured` / `Disabled`)
- `Device.WiFi.AccessPoint.{i}.WPS.InitiateWPSPBC()` — async Operate command
- Verified: AP.1 ✅ AP.2 ✅ AP.3 (guest, disabled) ✅ AP.4 ✅
- **JNAP `setWPSServerSessionStatus` can be fully migrated to USP**

### F-028: WiFi Advanced Radio Settings

**Priority:** P2 | **Effort:** Medium | **Feasibility:** ✅ USP Ready (SSH-verified 2026-03-16)

All 12 Radio parameters below are writable (schema `data:"1"`), partially replacing JNAP `setAdvancedRadioSettings`:

| Parameter | Path | Current Value | Notes |
|-----------|------|--------------|-------|
| Transmit Power | `Radio.{i}.TransmitPower` | (supported: -1,25,50,75,100) | % or auto(-1) |
| Guard Interval | `Radio.{i}.GuardInterval` | `"Auto"` | Auto/Short/Long |
| Beacon Period | `Radio.{i}.BeaconPeriod` | 100 | ms |
| DTIM Period | `Radio.{i}.DTIMPeriod` | 2 | beacon count |
| RTS Threshold | `Radio.{i}.RTSThreshold` | 2347 | bytes |
| Fragmentation | `Radio.{i}.FragmentationThreshold` | 2346 | bytes |
| Preamble Type | `Radio.{i}.PreambleType` | `"long"` | long/short |
| MCS Index | `Radio.{i}.MCS` | 0 | modulation scheme |
| 802.11h (DFS) | `Radio.{i}.IEEE80211hEnabled` | | radar detection |
| Extension Channel | `Radio.{i}.ExtensionChannel` | | HT40 secondary |
| Operating Standards | `Radio.{i}.OperatingStandards` | | 802.11 a/b/g/n/ac/ax |
| Auto Channel Refresh | `Radio.{i}.AutoChannelRefreshPeriod` | | seconds |

**Most of JNAP `setAdvancedRadioSettings` can be migrated to USP.** Remaining JNAP-only items in §7.

---

## 2. Internet Settings — Write Support

**Reference:** [internet-settings-set-validation.md](../issues/internet-settings-set-validation.md) | [internet-settings-jnap-vs-usp-comparison.md](../issues/internet-settings-jnap-vs-usp-comparison.md)

### 🔧 Needs Code Fix (no FW dependency)

| ID | Issue | Root Cause | Fix |
|----|-------|-----------|-----|
| ISS-3 | Gateway path non-writable | Standard path fault 9008 | Swap to `X_LINKSYS_DefaultGateway` vendor extension |
| ISS-4 | DNS Server paths non-writable / missing | Standard paths fault 9008/9005 | Swap to `X_LINKSYS_DNSServers` (comma-separated) |
| ISS-6 | LCPEcho marked writable but read-only | YAML error | Remove `writable: true` from `wan_settings.yaml` |
| ISS-8 | VLANTermination no instances by default | Multi-instance lifecycle | Implement Add before Set, Delete when disabling |
| ISS-2 | PPP.Interface missing in non-PPPoE mode | Multi-instance lifecycle | Implement Add before Set, Delete when leaving PPPoE |

**Vendor Extension Paths (SSH-verified writable):**

```
Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DefaultGateway   → replaces Routing.Router.1.IPv4Forwarding.1.GatewayIPAddress
Device.IP.Interface.2.IPv4Address.1.X_LINKSYS_DNSServers        → replaces DNS.Client.Server.{1,2,3}.DNSServer
```

### 🏭 Needs FW Team

| ID | Issue | Problem | Impact |
|----|-------|---------|--------|
| ISS-1 | AddressingType set is no-op | Set accepted (`data:1`) but `modified_uci: []`, value unchanged | **Blocks all connection type switching** |
| ISS-5 | MAC Clone non-writable | `Ethernet.Link.1.MACAddress` fault 9008 | MAC clone feature broken |
| ISS-7 | PPPoE.ServiceName denied | fault 9001 even after PPP instance created | PPPoE service name can't be set |
| ISS-9 | IPv6rd prefix format validation | fault 9007 pattern mismatch on `"2001:db8::"` | 6rd tunnel manual config may fail |
| ISS-2b | Bandwidth Data Inconsistency | Radio.2 `CurrentOperatingChannelBandwidth`=160MHz but `SupportedOperatingChannelBandwidths` max 80MHz | UI bandwidth dropdown may be incomplete |

### ⚠️ Suspect (needs re-test after ISS-1 fix)

| ID | Issue | Symptom |
|----|-------|---------|
| ISS-10 | ConnectionTrigger / Bridge.Enable | Set returns `data:1` but `modified_uci: []` — may work at dmmap level or silently fail |

### 🔴 USP Gap — Needs Vendor Extension

| Feature | JNAP Action | TR-181 Gap | Required Extension |
|---------|-------------|-----------|-------------------|
| PPTP connection type | `setWANSettings` | No standard TR-181 path for PPTP | `X_LINKSYS_PPTPClient.*` or equivalent vendor object |
| L2TP connection type | `setWANSettings` | No standard TR-181 path for L2TP | `X_LINKSYS_L2TPClient.*` or equivalent vendor object |

### Recommended Fix Priority

```
Phase 1 — Code Fix (no FW dependency):
  1. ISS-3 + ISS-4: Swap to X_LINKSYS_* vendor extensions
  2. ISS-6: Remove LCPEcho writable flag
  3. ISS-2 + ISS-8: Implement PPP/VLAN Add/Delete lifecycle

Phase 2 — FW Team Resolution:
  4. ISS-1: AddressingType switching mechanism (blocks everything)
  5. ISS-5: MAC clone writable path
  6. ISS-7: PPPoE.ServiceName denial
  7. ISS-9: IPv6rd prefix format

Phase 3 — Re-test:
  8. ISS-10: Re-verify after ISS-1 resolved
```

---

## 3. WiFi Settings — TR-181 Limitations

**Reference:** [wifi-settings-tr181-limitations.md](../issues/wifi-settings-tr181-limitations.md)
**SSH Re-verified:** 2026-03-16

### 🔧 ISS-2: Channel Width — ✅ Standard Path Exists (Code Fix Only)

**Original Assessment:** Vendor extension needed (`X_LINKSYS_PossibleChannelBandwidths`)
**SSH Verification:** `Device.WiFi.Radio.{i}.SupportedOperatingChannelBandwidths` path exists and returns correct data

```
Radio.1 (2.4 GHz): "Auto,20MHz"
Radio.2 (5 GHz):   "Auto,20MHz,40MHz,80MHz"    ← SupportedBandwidths max 80MHz
```

> ⚠️ **Data Inconsistency (2026-03-16):** Radio.2's `CurrentOperatingChannelBandwidth` reports `160MHz`, but `SupportedOperatingChannelBandwidths` only lists up to `80MHz`. This contradiction needs FW team clarification — `SupportedOperatingChannelBandwidths` return value may be incomplete, or `CurrentOperatingChannelBandwidth` is reporting incorrectly.

**Fix:** Remove UI hardcoded values, read `SupportedOperatingChannelBandwidths` for dynamic rendering. Update `wifi-settings-tr181-limitations.md` accordingly.

### 🔧 ISS-1: Channel-per-Width — Client-Side Computable (Code Fix)

**Original Assessment:** Vendor extension needed (`X_LINKSYS_AvailableChannels`)
**Revised Assessment:** **Client-side computable** — downgraded from FW Team dependency to Code Fix

IEEE 802.11 channel bonding rules are spec-defined constants. The app can derive `Map<WifiChannelWidth, List<int>>` by combining:
1. `Device.WiFi.Radio.{i}.PossibleChannels` — regulatory-filtered flat channel list from TR-181
2. `Device.WiFi.Radio.{i}.SupportedOperatingChannelBandwidths` — supported widths per radio
3. IEEE 802.11 bonding rules — deterministic primary channel selection per width

**Existing App Code:**

| Component | Location | Description |
|-----------|----------|-------------|
| Channel/frequency/DFS/UNII data | `lib/page/wifi_settings/models/channel_constants.dart` | 1302-line static table: 2.4GHz (14 ch), 5GHz (~60 ch), 6GHz (~90 ch) |
| Mode → max width mapping | `lib/page/wifi_settings/models/wifi_enums.dart` `WifiWirelessMode.maxSupportedWidth` | e.g., ac→80MHz, ax→160MHz, be→320MHz |
| JNAP channel-per-width mapping | `lib/page/wifi_settings/services/wifi_settings_mapper.dart:32-39` | Maps `supportedChannelsForChannelWidths` → `Map<WifiChannelWidth, List<int>>` |
| Target data structure | `lib/page/wifi_settings/providers/wifi_item.dart:22` | `Map<WifiChannelWidth, List<int>> availableChannels` |
| Channel selection by width | `lib/page/wifi_settings/providers/wifi_bundle_provider.dart:262` | `setChannelWidth` uses `availableChannels[channelWidth]` |

**USP Migration Fix:** Implement a utility that parses `PossibleChannels` string → applies IEEE 802.11 bonding rules per width → produces `Map<WifiChannelWidth, List<int>>` to populate `WiFiItem.availableChannels`. This replaces the JNAP `supportedChannelsForChannelWidths` without FW dependency.

### 🏭 Needs FW Team (1 item)

| ID | Issue | Impact | Needed Extension |
|----|-------|--------|-----------------|
| ISS-4 | Guest network detection — no field distinguishes Guest/Primary | SSH verified 4 APs: SSIDReference/IsolationEnable/MultiAPMode identical across all, only Enable and Security.ModeEnabled differ (AP.3/4 disabled + None) | `X_LINKSYS_NetworkType` on `Device.WiFi.AccessPoint.{i}` |

### 🏭 ISS-3: MAC Filtering — Issue More Severe Than Documented

**Original Assessment:** TR-181 only supports allow-list, vendor extension needed for deny-list
**SSH Verification Results:**

| Path | Result | Issue |
|------|--------|-------|
| `MACAddressControlEnabled` | ✅ writable (modifies `/etc/config/trx69`) | Toggle works |
| `AllowedMACAddress` (GET) | Returns flat string `"00:00:00:00:00:00"` | **Not a multi-instance table** |
| `AllowedMACAddress.{i}.` (schema) | fault 7026: not in data model | **Multi-instance does not exist** |
| `X_LINKSYS_DeniedMACAddress` | fault 9005 | Vendor extension does not exist |

**Revised Assessment:** Not only is the deny-list missing, but the allow-list multi-instance table is also not implemented. The entire MAC address list mechanism is broken at the bbfdm level. FW team needs to fix `AllowedMACAddress.{i}` multi-instance support **and** add deny-list vendor extension.

**Current Mitigations:**
- ISS-1: ~~Hardcoded channel lists~~ → **Client-side computable** using `PossibleChannels` + `SupportedOperatingChannelBandwidths` + IEEE 802.11 bonding rules (see ISS-1 section above)
- ISS-2: ~~Hardcoded width lists~~ → **Can use `SupportedOperatingChannelBandwidths` instead**
- ISS-3: MAC Filtering tab removed from WiFi Settings page
- ISS-4: Case-insensitive `"guest"` substring match on SSID name

---

## 3b. WiFi Features — JNAP Dependency Re-evaluation

**SSH-verified:** 2026-03-16 — Multiple features originally marked "JNAP Required" actually have TR-181 paths

### ✅ USP Ready (Moved from JNAP Required)

| Feature | JNAP Action | USP Path | Status |
|---------|-------------|----------|--------|
| **WPS** | `setWPSServerSessionStatus` | `AP.{i}.WPS.Enable` + `InitiateWPSPBC()` | ✅ Full support (see §1 F-027) |
| **Advanced Radio (partial)** | `setAdvancedRadioSettings` | 12 writable Radio parameters | ✅ Mostly migratable (see §1 F-028) |
| **Security Mode** | `setWirelessNetworkSettings` | `AP.{i}.Security.ModeEnabled` + WPA3 | ✅ Includes WPA3 + MFP (see §1 F-001) |

### 🔧 Code Fix (YAML/codegen update needed)

| Feature | JNAP Action | USP Path | Fix |
|---------|-------------|----------|-----|
| **WiFi Scheduling** | `setWirelessSchedulerSettings` | `Radio.{i}.Enable` + client-side timer | No TR-181 scheduler — use Radio Enable + app scheduling workaround |

### 🔴 USP Gap (Still needs vendor extension)

| Feature | JNAP Action | TR-181 Gap | Required Extension |
|---------|-------------|-----------|-------------------|
| **Smart Connect** | `setSmartConnectSettings` | Linksys proprietary band steering algorithm | `X_LINKSYS_SmartConnect.*` |
| **WiFi 6E/7 MLO** | `setMLOSettings` | Multi-Link Operation not standardized in TR-181 | `X_LINKSYS_MLO.*` |
| **WiFi Optimization** | `setWiFiOptimizationSettings` | Linksys proprietary optimization | `X_LINKSYS_WiFiOptimization.*` |
| **Channel Scanner** | `startChannelScan` | No standard Operate command | `X_LINKSYS_ChannelScan()` |

---

## 4. DDNS — SSH Verification Results

**Verified:** 2026-03-16 | **Status:** 🔴 bbfdm plugin missing

### TR-181 Path Test

```bash
ubus call bbfdm get '{"path":"Device.DynamicDNS."}'
# → fault 9005: Invalid parameter name

ubus call bbfdm get '{"path":"Device.DynamicDNS.Client."}'
# → fault 9005: Invalid parameter name
```

### Router-Level Support

| Layer | Status | Detail |
|-------|--------|--------|
| **OpenWrt packages** | ✅ Installed | `ddns-scripts` v2.8.2-42, `ddns-scripts-noip`, `ddns-scripts-services` |
| **UCI config** | ✅ Exists | `/etc/config/ddns` — dyndns.org + NoIP templates (IPv4/IPv6) |
| **Update scripts** | ✅ Available | `/usr/lib/ddns/update_no-ip_com.sh`, `dynamic_dns_updater.sh` |
| **bbfdm plugin** | ❌ Missing | No DDNS module in `/usr/lib/bbfdm/`, no `bbfdm.ddnsmngr` daemon |
| **TR-181 path** | ❌ Not exposed | `Device.DynamicDNS.*` returns fault 9005 |

### Assessment

DDNS functionality fully exists at the OpenWrt level (UCI + ddns-scripts), but firmware has not implemented a bbfdm plugin to map it to the TR-181 data model.

**Action Required:** Firmware team to develop `bbfdm.ddnsmngr` plugin, mapping `/etc/config/ddns` UCI configuration to `Device.DynamicDNS.Client.{i}.*` TR-181 paths.

**Expected TR-181 Mapping:**

| TR-181 Path | UCI Path | Notes |
|-------------|----------|-------|
| `Device.DynamicDNS.Client.{i}.Enable` | `ddns.@service[i].enabled` | Service enable/disable |
| `Device.DynamicDNS.Client.{i}.Server` | `ddns.@service[i].service_name` | Provider name (dyndns.org, no-ip.com) |
| `Device.DynamicDNS.Client.{i}.Username` | `ddns.@service[i].username` | Provider login |
| `Device.DynamicDNS.Client.{i}.Password` | `ddns.@service[i].password` | Provider password |
| `Device.DynamicDNS.Client.{i}.HostnameList` | `ddns.@service[i].domain` | Hostname to update |
| `Device.DynamicDNS.Client.{i}.Interface` | `ddns.@service[i].interface` | WAN interface |
| `Device.DynamicDNS.Client.{i}.Status` | runtime | Current update status |

**JNAP → USP Migration Mapping:**

| JNAP Action (to eliminate) | USP Replacement (after bbfdm plugin) | Notes |
|---------------------------|--------------------------------------|-------|
| `getDDNSSettings` | `GET Device.DynamicDNS.Client.*` | Read all DDNS clients |
| `setDDNSSettings` | `SET Device.DynamicDNS.Client.{i}.*` | Update provider config |
| `getDDNSStatus2` | `GET Device.DynamicDNS.Client.{i}.Status` | Update status polling |
| `getSupportedDDNSProviders` | `X_LINKSYS_SupportedDDNSProviders` | Need vendor extension — provider list not in TR-181 standard |

---

## 5. QoS — SSH Verification Results

**Verified:** 2026-03-16 | **Status:** 🔴 bbfdm plugin missing + partially proprietary

### TR-181 Path Test

```bash
ubus call bbfdm get '{"path":"Device.QoS."}'
# → fault 9005: Invalid parameter name

ubus call bbfdm get '{"path":"Device.QoS.Classification."}'
# → fault 9005: Invalid parameter name
```

### Router-Level Support

| Layer | Status | Detail |
|-------|--------|--------|
| **Hardware QoS** | ✅ Installed | `qca-sal-qos` (Qualcomm SAL hardware-level QoS) |
| **ebtables rules** | ✅ Exists | `bridging.qos` / `bridging.qos_output` chains (broute + nat) |
| **UCI config** | ❌ None | No `/etc/config/qos` file |
| **init.d service** | ❌ None | No QoS service daemon |
| **bbfdm plugin** | ❌ Missing | No QoS module in `/usr/lib/bbfdm/`, no `bbfdm.qosmngr` daemon |
| **TR-181 path** | ❌ Not exposed | `Device.QoS.*` returns fault 9005 |

### Feature Breakdown

| Feature | JNAP Action | Feasibility | Blocker | Required Extension |
|---------|-------------|------------|---------|-------------------|
| **QoS Basic** (traffic classification) | `setQoSSettings` | 🏭 Needs FW | bbfdm plugin missing | `bbfdm.qosmngr` → `Device.QoS.Classification.{i}.*` |
| **Adaptive QoS** (AI-based) | `setAdaptiveQoSSettings` | 🔴 USP Gap | Linksys proprietary AI algorithm | `X_LINKSYS_AdaptiveQoS.*` vendor extension |
| **Express Forwarding** | `setExpressForwardingSettings` | 🔴 USP Gap | Qualcomm SAL hardware layer | `X_LINKSYS_ExpressForwarding.*` vendor extension |
| **Gaming Prioritization** | `setGamePriority` | 🔴 USP Gap | Linksys proprietary feature | `X_LINKSYS_GamePriority.*` vendor extension |

### Assessment

QoS is implemented via Qualcomm hardware layer (SAL) + ebtables bridging rules. Firmware has not built a bbfdm plugin, TR-181 `Device.QoS.*` is completely unavailable.

- **Basic QoS:** Can theoretically be mapped via bbfdm plugin to `Device.QoS.Classification.{i}.*`
- **Advanced QoS:** Adaptive QoS / Gaming Prioritization / Express Forwarding are Linksys proprietary implementations, requiring firmware team vendor extensions to eliminate JNAP

**Action Required — Firmware Team:**
1. Evaluate `bbfdm.qosmngr` plugin feasibility (basic traffic classification)
2. Confirm whether basic `Device.QoS.Classification.{i}.*` can map to ebtables rules
3. Provide vendor extension paths or alternatives for Adaptive QoS / Gaming Prioritization / Express Forwarding
4. If vendor extensions cannot be provided, please respond explicitly so we can plan alternative architecture

---

## 6. Parental Control — Feature Analysis

**Status:** 🔴 Core features have no TR-181 standard path — requires firmware team vendor extension

### Feature Breakdown

| Feature | JNAP Action | Current Status | USP Gap | Required Extension |
|---------|-------------|---------------|---------|-------------------|
| **Safe Browsing (DNS)** | `setParentalControlSettings` | ✅ M1 implemented | ✅ Migrated | — (DNS override via `LanNetworkInfo.save()`) |
| **Time-Based Controls** | `setParentalControlRules` | ❌ Not migrated | 🔴 USP Gap | `X_LINKSYS_ParentalControl.Rule.{i}.*` (device scheduling, time limits) |
| **Content Filtering** | `setParentalControlRules` | ❌ Not migrated | 🔴 USP Gap | `X_LINKSYS_ContentFilter.*` (age-based filtering, website allow/block lists) |

### USP Migration Path Analysis

| Approach | Feasibility | Limitations |
|----------|-------------|-------------|
| **WiFi Radio Scheduling** | ⚠️ Partially viable | Too coarse-grained — affects all devices, no per-device control |
| **MAC-based Firewall Rules** | ⚠️ Partially viable | `Device.Firewall.Chain.*.Rule.*` can block MAC, but no time-scheduled trigger mechanism |
| **DNS Override** | ✅ Implemented | Safe Browsing already completed via USP |
| **Vendor Extension** | 🏭 Best approach | Requires firmware team to map JNAP parental control features to TR-181 vendor extension |

**Action Required — Firmware Team:**
1. Provide `X_LINKSYS_ParentalControl.*` vendor extension, mapping JNAP `setParentalControlRules` functionality
2. Must support at minimum: per-device time scheduling, enable/disable, rule CRUD
3. Content filtering database access path (if feasible)

---

## 7. Remaining JNAP Dependencies — USP Migration Gaps

The following features currently only have JNAP implementations, with no standard TR-181 paths. **Each requires firmware team vendor extension to complete migration.**

> ~~WPS~~ — ✅ Confirmed USP Ready (2026-03-16), moved to §1 F-027
> ~~WiFi Advanced Settings~~ — ✅ Mostly confirmed USP Ready, moved to §1 F-028 / §3b

| Feature | JNAP Action | Category | Required Vendor Extension | Priority |
|---------|-------------|----------|--------------------------|----------|
| Smart Connect | `setSmartConnectSettings` | WiFi | `X_LINKSYS_SmartConnect.*` | P2 |
| WiFi 6E/7 MLO | `setMLOSettings` | WiFi | `X_LINKSYS_MLO.*` | P3 |
| WiFi Optimization | `setWiFiOptimizationSettings` | WiFi | `X_LINKSYS_WiFiOptimization.*` | P3 |
| Channel Scanner | `startChannelScan` | WiFi | `X_LINKSYS_ChannelScan()` Operate command | P2 |
| PPTP Connection | `setWANSettings` | Internet | `X_LINKSYS_PPTPClient.*` | P2 |
| L2TP Connection | `setWANSettings` | Internet | `X_LINKSYS_L2TPClient.*` | P2 |
| Speed Test | `runSpeedTest` | Diagnostics | `X_LINKSYS_SpeedTest()` Operate command | P2 |
| Firmware Update | `setFirmwareUpdateSettings` | Admin | `Device.DeviceInfo.FirmwareImage.{i}.Download()` or `X_LINKSYS_FirmwareUpdate.*` | P1 |
| Auto Firmware Update | `setAutoFirmwareUpdateSettings` | Admin | `X_LINKSYS_AutoFirmwareUpdate.*` (schedule + policy) | P2 |
| Network Modes | `setNetworkModeSettings` | Advanced | `X_LINKSYS_NetworkMode.*` (Router/AP/Bridge) | P2 |

> **Note:** Firmware Update has TR-181 `Device.DeviceInfo.FirmwareImage.{i}.Download()` standard Operate — needs SSH verification to confirm router implementation.

**Action Required — Firmware Team:**
1. Verify Firmware Update TR-181 standard path support
2. Provide Smart Connect / Channel Scanner vendor extension
3. Provide PPTP/L2TP vendor extension paths
4. Provide Speed Test vendor extension (or Operate command)
5. QoS-related vendor extensions (see §5)
6. WiFi 6E/7 MLO / WiFi Optimization — low priority, pending hardware support confirmation

---

## 8. Dependency Map — JNAP Migration Path

```
┌──────────────────────────────────────────────────────────┐
│  Layer 1: No Dependencies — Can develop immediately          │
│                                                          │
│  F-001 WiFi PW/Security  F-004 Channel Width             │
│  F-011 Ping UI           F-026 Prefetch Cache            │
│  F-027 WPS               F-028 Advanced Radio            │
│  WiFi ISS-1 (channel-per-width client computation)       │
│  WiFi ISS-2 (use SupportedBandwidths)                    │
│  Internet ISS-3/4 Vendor Ext  ISS-6 YAML Fix            │
│  Internet ISS-2/8 Add/Delete                             │
└──────────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────┐
│  Layer 2: FW Team Bug Fix — Existing path repair             │
│                                                          │
│  ISS-1 AddressingType  → blocks connection type switch   │
│  ISS-5 MAC Clone       → blocks MAC clone feature        │
│  ISS-7 PPPoE.ServiceName → blocks PPPoE service name     │
│  ISS-9 IPv6rd prefix   → blocks 6rd manual config        │
│  ISS-10 re-test        → depends on ISS-1 resolution     │
└──────────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────┐
│  Layer 3: FW Team bbfdm Plugin — New TR-181 paths            │
│                                                          │
│  DDNS (bbfdm.ddnsmngr)  → Device.DynamicDNS.*           │
│  QoS Basic (bbfdm.qosmngr) → Device.QoS.*               │
│  WiFi ISS-3 (MAC deny-list vendor ext)                   │
│  WiFi ISS-4 (network type vendor ext)                    │
└──────────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────┐
│  Layer 4: FW Team Vendor Extension — Eliminate JNAP dep      │
│  ⚠️ Each item is a JNAP migration blocker, must request from FW│
│                                                          │
│  Smart Connect       → X_LINKSYS_SmartConnect.*          │
│  Channel Scanner     → X_LINKSYS_ChannelScan()           │
│  WiFi 6E/7 MLO       → X_LINKSYS_MLO.*                  │
│  WiFi Optimization   → X_LINKSYS_WiFiOptimization.*      │
│  Network Modes       → X_LINKSYS_NetworkMode.*           │
│  Parental Control    → X_LINKSYS_ParentalControl.*       │
│  Adaptive QoS        → X_LINKSYS_AdaptiveQoS.*          │
│  Gaming Priority     → X_LINKSYS_GamePriority.*          │
│  Express Forwarding  → X_LINKSYS_ExpressForwarding.*     │
│  PPTP / L2TP         → X_LINKSYS_PPTPClient/L2TPClient.* │
│  Speed Test          → X_LINKSYS_SpeedTest()             │
│  Firmware Update     → Device.DeviceInfo.FirmwareImage.* │
│  Auto FW Update      → X_LINKSYS_AutoFirmwareUpdate.*    │
└──────────────────────────────────────────────────────────┘
```

> **Goal:** Complete all Layers 1-4 to achieve 100% USP migration and fully remove JNAP dependency.

---

## 9. Recommended Execution Order

### Phase M2-A: Immediate (no external dependency)

| # | Feature | Effort | Rationale |
|---|---------|--------|-----------|
| 1 | F-001 WiFi Password/Security | Small | P0 daily WiFi management + WPA3 security modes |
| 2 | F-004 Channel Width | Small | P1 paired with WiFi, switch to `SupportedOperatingChannelBandwidths` |
| 3 | WiFi ISS-1 fix | Medium | Channel-per-width client-side computation (IEEE 802.11 bonding rules + `PossibleChannels`) |
| 4 | WiFi ISS-2 fix | Trivial | Remove hardcoded bandwidth, read from TR-181 |
| 5 | F-027 WPS | Small | P2 ✅ SSH verified full support |
| 6 | F-028 Advanced Radio | Medium | P2 12 writable parameters, partially replaces JNAP |
| 7 | F-011 Ping/Traceroute UI | Medium | SSE infrastructure ready, UI only |
| 8 | Internet ISS-3/4 | Small | Vendor extension path swap |
| 9 | Internet ISS-6 | Trivial | YAML writable flag removal |
| 10 | Internet ISS-2/8 | Medium | PPP/VLAN Add/Delete lifecycle |
| 11 | F-026 Prefetch Cache | Medium | Dashboard performance optimization |

### Phase M2-B: FW Team Coordination

| # | Feature | Dependency | Priority |
|---|---------|-----------|----------|
| 8 | ISS-1 AddressingType | FW team confirms switching mechanism | **P0 Critical** |
| 9 | ISS-5 MAC Clone | FW team provides vendor extension | P1 |
| 10 | ISS-7 PPPoE ServiceName | FW team investigates fault 9001 | P1 |
| 11 | ISS-9 IPv6rd Prefix | FW team confirms format specification | P2 |
| 12 | F-007 Guest Network | Can use heuristic first, vendor extension later | P1 |

### Phase M2-C: bbfdm Plugin Development

| # | Feature | Plugin | Priority |
|---|---------|--------|----------|
| 13 | DDNS | `bbfdm.ddnsmngr` | P1 — UCI config already exists |
| 14 | QoS Basic | `bbfdm.qosmngr` | P2 — needs feasibility assessment |
| 15 | WiFi ISS-3 | MAC deny-list vendor extension | P3 |
| 16 | WiFi ISS-4 | Network type vendor extension | P3 |

### Phase M2-D: Vendor Extension — JNAP Dependency Elimination

| # | Feature | Required from FW Team | Priority |
|---|---------|----------------------|----------|
| 18 | Firmware Update | Verify `Device.DeviceInfo.FirmwareImage.{i}.Download()` or provide vendor ext | P1 |
| 19 | Smart Connect | Provide `X_LINKSYS_SmartConnect.*` vendor extension | P2 |
| 20 | Channel Scanner | Provide `X_LINKSYS_ChannelScan()` Operate command | P2 |
| 21 | Network Modes | Provide `X_LINKSYS_NetworkMode.*` (Router/AP/Bridge) | P2 |
| 22 | Parental Control (time/content) | Provide `X_LINKSYS_ParentalControl.*` vendor extension | P2 |
| 23 | PPTP / L2TP | Provide `X_LINKSYS_PPTPClient/L2TPClient.*` vendor extension | P2 |
| 24 | Speed Test | Provide `X_LINKSYS_SpeedTest()` Operate command | P2 |
| 25 | Auto Firmware Update | Provide `X_LINKSYS_AutoFirmwareUpdate.*` vendor extension | P2 |
| 26 | Adaptive QoS / Gaming / Express FW | Provide vendor extensions (see §5) | P3 |
| 27 | WiFi 6E/7 MLO / Optimization | Provide vendor extensions (pending hardware support) | P3 |
| 28 | F-025 Historical Trends | Client-side Hive DB (no FW dependency) | P3 |

---

## 10. JNAP Migration Progress Tracker

**Goal: 72/72 (100%) USP coverage, fully remove JNAP dependency.**

Based on USP Features Matrix (72 features total):

| Status | Count | Percentage | Description |
|--------|-------|-----------|-------------|
| ✅ USP Complete | 45 | 63% | M1 migration completed |
| ✅ USP Ready (verified) | 3 | 4% | SSH verified available: WPS, Advanced Radio, Security Mode |
| 🔧 Code Fix Only | 8 | 11% | Vendor extension path swap, YAML fix, bandwidth fix, channel-per-width computation, scheduling workaround |
| 🏭 FW Bug Fix | 5 | 7% | Existing TR-181 paths need repair (ISS-1/5/7/9/10) |
| 🏭 FW bbfdm Plugin | 2 | 3% | New bbfdm plugins needed (DDNS, QoS Basic) |
| 🔴 FW Vendor Extension | 9 | 13% | FW team must provide new vendor extensions (JNAP migration blockers) |

### Migration Milestones

| Milestone | Scope | USP Coverage | JNAP Dependencies |
|-----------|-------|-------------|-------------------|
| **M1 Done** | 45 features implemented | 45/72 (63%) | 27 remaining |
| **M2-A** (code fix) | F-001/004/011/026/027/028 + WiFi ISS-1/2 + Internet ISS-3/4/6/2/8 | 56/72 (78%) | 16 remaining |
| **M2-B** (FW bug fix) | ISS-1/5/7/9/10 + F-007 | 61/72 (85%) | 11 remaining |
| **M2-C** (bbfdm plugins) | DDNS, QoS Basic | 63/72 (88%) | 9 remaining |
| **M2-D** (vendor extensions) | Smart Connect, Parental Control, PPTP/L2TP, FW Update, etc. | **72/72 (100%)** | **0 — JNAP migration complete** |

### FW Team Request Summary

Completing 100% migration requires the firmware team to provide:

| Category | Items | Effort Estimate |
|----------|-------|-----------------|
| **Bug Fix** (existing path repair) | ISS-1, ISS-5, ISS-7, ISS-9 | Low — fix existing bbfdm behavior |
| **bbfdm Plugin** (new standard paths) | DDNS (`bbfdm.ddnsmngr`), QoS (`bbfdm.qosmngr`), MAC Filter AllowedMACAddress.{i} multi-instance fix + deny-list | Medium — UCI config already exists, plugin development needed |
| **Vendor Extension** (new proprietary paths) | Smart Connect, Channel Scanner, Network Modes, Parental Control, QoS Advanced, PPTP/L2TP, Speed Test, FW Update | High — map JNAP features to TR-181 vendor extensions |

> ⚠️ **Vendor extensions are the biggest blocker to 100% migration.** If the firmware team cannot provide certain vendor extensions, those features cannot be decoupled from JNAP. Feasibility must be confirmed individually during M2-D phase.

---

## Related Documentation

- [M1 Feature Roadmap](feature_roadmap.md) — Implemented features and infrastructure
- [FW Team Request](../issues/fw-team-request.md) — All issues requiring firmware team action (26 items)
- [Internet Settings Validation](../issues/internet-settings-set-validation.md) — SSH test results
- [Internet Settings JNAP vs USP](../issues/internet-settings-jnap-vs-usp-comparison.md) — Field-by-field comparison
- [WiFi Settings Limitations](../issues/wifi-settings-tr181-limitations.md) — TR-181 gaps
- [Router Firmware Bugs](../issues/router-firmware-bugs.md) — All resolved
- [USP Features Matrix](../USP_FEATURES_MATRIX.md) — Complete 72-feature coverage analysis
- [JNAP USP Alignment](../archive/milestone1/JNAP_USP_ALIGNMENT.md) — Issue #641 (DDNS), #643 (Parental Control)
- [SSE Implementation](sse_implementation.md) — Real-time notification infrastructure

---

**Last Updated:** 2026-03-16
**Next Review:** After FW team response on ISS-1 / bbfdm plugin feasibility
