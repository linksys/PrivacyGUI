# Firmware Team Request — USP/TR-181 Support Issues

> **Date:** 2026-03-16
> **From:** App Team (PrivacyGUI)
> **Branch:** `feat/usp-protocol-integration`
> **Router:** Linksys M60TB-EU (PINNACLE 2.0) | **FW:** 1.0.16.26013014
> **Test Method:** `ubus call bbfdm {get|set|schema|instances|add|del}` via SSH

---

## Objective

The app team is migrating all features from JNAP protocol to USP/TR-181. M1 has completed 45/72 (63%) features. This document lists all issues requiring firmware team support, organized into three tiers by priority.

**Completing all items below achieves 100% USP migration and fully eliminates JNAP dependency.**

---

## Overview

| Tier | Type | Count | Description |
|------|------|-------|-------------|
| **Tier 1** | Bug Fix — Existing Path Repair | 6 | Path exists but Set behavior is broken |
| **Tier 2** | bbfdm Plugin / Path Extension | 5 | New bbfdm plugin or multi-instance fix needed |
| **Tier 3** | Vendor Extension — New Proprietary Paths | 15 | Map JNAP features to `X_LINKSYS_*` TR-181 paths |
| | **Total** | **26** | |

---

## Tier 1: Bug Fix — Existing TR-181 Path Repair

> These paths already exist in the TR-181 data model, but Set operations behave incorrectly. Once fixed, the app can use them directly.

### FW-001: AddressingType Set No-Op ⭐ P0 Critical

| Field | Value |
|-------|-------|
| **TR-181 Path** | `Device.IP.Interface.2.IPv4Address.1.AddressingType` |
| **Operation** | SET `value: "Static"` |
| **Result** | Returns `data:1` (appears successful), but `modified_uci: []` (empty), value unchanged |
| **Impact** | **Blocks all WAN connection type switching** (DHCP ↔ Static ↔ PPPoE ↔ Bridge) |
| **Related** | Internet Settings ISS-1 |

**SSH Reproduction:**
```bash
# Read current value
ubus call bbfdm get '{"path":"Device.IP.Interface.2.IPv4Address.1.AddressingType"}'
# → "DHCP"

# Attempt to set
ubus call bbfdm set '{"path":"Device.IP.Interface.2.IPv4Address.1.AddressingType","value":"Static"}'
# → data:1, modified_uci: []   ← No effect!

# Read again — value unchanged
ubus call bbfdm get '{"path":"Device.IP.Interface.2.IPv4Address.1.AddressingType"}'
# → "DHCP"  ← Still DHCP
```

**Please confirm:** What is the correct mechanism for WAN protocol switching? Is a different path or Operate command required?

---

### FW-002: MAC Clone Path Non-Writable — P1

| Field | Value |
|-------|-------|
| **TR-181 Path** | `Device.Ethernet.Link.1.MACAddress` |
| **Operation** | SET `value: "AA:BB:CC:DD:EE:FF"` |
| **Result** | fault 9008: non-writable |
| **Schema** | `data: "0"` (read-only) |
| **Impact** | MAC address clone feature unusable |
| **Related** | Internet Settings ISS-5 |

**SSH Reproduction:**
```bash
ubus call bbfdm set '{"path":"Device.Ethernet.Link.1.MACAddress","value":"AA:BB:CC:DD:EE:FF"}'
# → fault 9008
```

**Please provide:** A vendor extension path for MAC clone (e.g., `X_LINKSYS_MACClone.Enable` + `X_LINKSYS_MACClone.MACAddress`), or make `Ethernet.Link.1.MACAddress` writable.

---

### FW-003: PPPoE.ServiceName Set Denied — P1

| Field | Value |
|-------|-------|
| **TR-181 Path** | `Device.PPP.Interface.1.PPPoE.ServiceName` |
| **Operation** | SET `value: "myservice"` |
| **Result** | fault 9001: Request denied |
| **Schema** | `data: "1"` (marked as writable) |
| **Precondition** | PPP.Interface.1 created via Add |
| **Impact** | PPPoE service name cannot be set |
| **Related** | Internet Settings ISS-7 |

**SSH Reproduction:**
```bash
# Create PPP instance first
ubus call bbfdm add '{"path":"Device.PPP.Interface."}'
# → instance created

# Attempt to set ServiceName
ubus call bbfdm set '{"path":"Device.PPP.Interface.1.PPPoE.ServiceName","value":"myservice"}'
# → fault 9001: Request denied

# PPPoE.ACName also denied
ubus call bbfdm set '{"path":"Device.PPP.Interface.1.PPPoE.ACName","value":"test"}'
# → fault 9001: Request denied
```

**Please confirm:** Does the PPPoE sub-object require specific preconditions (e.g., `Enable=true` or `LowerLayers` configured) before allowing Set?

---

### FW-004: IPv6rd Prefix Format Validation Failure — P1

| Field | Value |
|-------|-------|
| **TR-181 Path** | `Device.IPv6rd.InterfaceSetting.1.SPIPv6Prefix` |
| **Operation** | SET `value: "2001:db8::"` |
| **Result** | fault 9007: List patterns did not match |
| **Impact** | Cannot set prefix field for 6rd tunnel manual configuration |
| **Related** | Internet Settings ISS-9 |

**SSH Reproduction:**
```bash
ubus call bbfdm set '{"path":"Device.IPv6rd.InterfaceSetting.1.SPIPv6Prefix","value":"2001:db8::"}'
# → fault 9007
```

**Please confirm:** What is the expected format for this field? Does it require prefix length (e.g., `"2001:db8::/32"`) or a fully expanded IPv6 address?

---

### FW-005: Bandwidth Data Inconsistency — P1

| Field | Value |
|-------|-------|
| **TR-181 Path (A)** | `Device.WiFi.Radio.2.SupportedOperatingChannelBandwidths` |
| **TR-181 Path (B)** | `Device.WiFi.Radio.2.CurrentOperatingChannelBandwidth` |
| **Path A returns** | `"Auto,20MHz,40MHz,80MHz"` — max 80MHz |
| **Path B returns** | `"160MHz"` — currently using 160MHz |
| **Contradiction** | Current bandwidth exceeds the Supported list |
| **Impact** | UI bandwidth dropdown may be incomplete (missing 160MHz) |
| **Related** | WiFi ISS-2b |

**SSH Reproduction:**
```bash
ubus call bbfdm get '{"path":"Device.WiFi.Radio.2.SupportedOperatingChannelBandwidths"}'
# → "Auto,20MHz,40MHz,80MHz"

ubus call bbfdm get '{"path":"Device.WiFi.Radio.2.CurrentOperatingChannelBandwidth"}'
# → "160MHz"
```

**Please confirm:** Is the `SupportedOperatingChannelBandwidths` return value incomplete (should include 160MHz), or is `CurrentOperatingChannelBandwidth` reporting incorrectly?

---

### FW-006: ConnectionTrigger / Bridge.Enable Set Suspected No-Op — P3 (Pending Observation)

| Field | Value |
|-------|-------|
| **TR-181 Path** | `Device.PPP.Interface.1.ConnectionTrigger` / `Device.Bridging.Bridge.1.Enable` |
| **Operation** | SET |
| **Result** | Returns `data:1` but `modified_uci: []` |
| **Possible Cause** | May operate at dmmap level rather than UCI, or same issue as FW-001 (AddressingType) |
| **Impact** | PPPoE connection mode and Bridge mode switching may not take effect |
| **Related** | Internet Settings ISS-10 |

**Please re-verify after FW-001 is fixed.** If these paths still return `modified_uci: []` after AddressingType is fixed, further investigation is needed.

---

## Tier 2: bbfdm Plugin / Path Extension

> These features have partial support at the OpenWrt level (UCI config or kernel module), but bbfdm has not mapped them to TR-181. New bbfdm plugins or multi-instance support fixes are needed.

### FW-007: MAC Filtering — AllowedMACAddress Multi-Instance Missing + Deny-List Missing — P1

| Field | Value |
|-------|-------|
| **TR-181 Path** | `Device.WiFi.AccessPoint.{i}.AllowedMACAddress.{i}.*` |
| **Expected Behavior** | `AllowedMACAddress` should be a multi-instance table (one MAC address per entry) |
| **Actual Behavior** | GET returns flat string `"00:00:00:00:00:00"`; schema query on `AllowedMACAddress.{i}.` returns fault 7026 (not in data model) |
| **JNAP Equivalent** | JNAP MAC Filtering uses a **deny-list** (block specific devices) |
| **Impact** | MAC Filtering feature completely unusable |
| **Related** | WiFi ISS-3 |

**SSH Reproduction:**
```bash
# AllowedMACAddress returns flat string instead of multi-instance
ubus call bbfdm get '{"path":"Device.WiFi.AccessPoint.1.AllowedMACAddress"}'
# → "00:00:00:00:00:00"

# Multi-instance schema does not exist
ubus call bbfdm schema '{"path":"Device.WiFi.AccessPoint.{i}.AllowedMACAddress.{i}."}'
# → fault 7026: not in data model

# Deny-list vendor extension does not exist
ubus call bbfdm get '{"path":"Device.WiFi.AccessPoint.1.X_LINKSYS_DeniedMACAddress"}'
# → fault 9005
```

**Required:**
1. Fix `AllowedMACAddress.{i}` multi-instance table support (TR-181 standard)
2. Add deny-list vendor extension: `X_LINKSYS_DeniedMACAddress.{i}.*` or `X_LINKSYS_MACFilterMode` (allow/deny toggle)

---

### FW-008: PossibleChannels Not Grouped by Channel Width — P2 (Downgraded)

| Field | Value |
|-------|-------|
| **TR-181 Path** | `Device.WiFi.Radio.{i}.PossibleChannels` |
| **Actual Behavior** | Returns flat list, e.g., `"36,40,44,48,52,56,60,64,100-140"` |
| **Original Problem** | Cannot determine which channels are available at 40MHz/80MHz/160MHz |
| **Revised Assessment** | **Client-side computable** — IEEE 802.11 channel bonding rules are spec-defined constants; app can derive channel-per-width mapping without vendor extension |
| **Related** | WiFi ISS-1 |

**SSH Verification Data:**
```bash
ubus call bbfdm get '{"path":"Device.WiFi.Radio.1.PossibleChannels"}'
# → "1-13"  (2.4 GHz)

ubus call bbfdm get '{"path":"Device.WiFi.Radio.2.PossibleChannels"}'
# → "36,40,44,48,52,56,60,64,100-140"  (5 GHz, flat list)

ubus call bbfdm get '{"path":"Device.WiFi.Radio.2.SupportedOperatingChannelBandwidths"}'
# → "Auto,20MHz,40MHz,80MHz"
```

**Existing App Implementation (JNAP):**

The current JNAP implementation receives `supportedChannelsForChannelWidths` directly from the router, mapped to `Map<WifiChannelWidth, List<int>>` in `WiFiItem.availableChannels`:

- `wifi_settings_mapper.dart:32-39` — Maps JNAP `radio.supportedChannelsForChannelWidths` to `availableChannels`
- `wifi_item.dart:22` — `Map<WifiChannelWidth, List<int>> availableChannels` data structure
- `wifi_bundle_provider.dart:262` — `setChannelWidth` uses `availableChannels[channelWidth]` to filter channel list

**Client-Side Computation Approach (USP):**

Channel-per-width grouping can be computed using:
1. `Device.WiFi.Radio.{i}.PossibleChannels` — regulatory-filtered flat channel list
2. `Device.WiFi.Radio.{i}.SupportedOperatingChannelBandwidths` — supported widths for this radio
3. IEEE 802.11 bonding rules (spec-defined constants, already partially in app code):

| Source | Location | Data |
|--------|----------|------|
| Channel/frequency/DFS/UNII mapping | `channel_constants.dart` (1302 lines) | 2.4GHz (ch 1-14), 5GHz (ch 32-196), 6GHz (ch 1-233) |
| Mode → max channel width | `wifi_enums.dart` `WifiWirelessMode.maxSupportedWidth` | e.g., 802.11ac→80MHz, 802.11ax→160MHz, 802.11be→320MHz |

IEEE 802.11 bonding rules (deterministic, per spec):
- **20MHz**: All channels in `PossibleChannels` are valid
- **40MHz (5GHz)**: Primary channel must be lower of bonded pair (36,44,52,60,100,108,116,124,132,149,157)
- **80MHz (5GHz)**: Valid primary channels: 36,52,100,116,132,149
- **160MHz (5GHz)**: Valid primary channels: 36,100 (contiguous) or 80+80 combinations (non-contiguous)
- **320MHz (6GHz)**: Valid primary channels per Wi-Fi 7 spec

**Conclusion:** Vendor extension is **nice-to-have** but not required. App can compute `Map<WifiChannelWidth, List<int>>` client-side by intersecting `PossibleChannels` with IEEE bonding rules, filtered by `SupportedOperatingChannelBandwidths`. Priority downgraded from P1 to P2.

**If vendor extension is provided:** Use `X_LINKSYS_AvailableChannelsByBandwidth` as authoritative source (preferred, accounts for DFS/regulatory edge cases the spec-based computation might miss).

---

### FW-009: Guest Network Indistinguishable — P1

| Field | Value |
|-------|-------|
| **TR-181 Path** | `Device.WiFi.AccessPoint.{i}.*` |
| **Problem** | No field can distinguish Guest AP from Primary AP |
| **Impact** | App can only rely on unreliable heuristic of SSID name containing "guest" |
| **Related** | WiFi ISS-4 |

**SSH Verification — All 4 APs Compared:**

| Field | AP.1 (Primary) | AP.2 (Primary) | AP.3 (Guest) | AP.4 (Guest) |
|-------|---------------|---------------|--------------|--------------|
| `Enable` | `true` | `true` | `false` | `false` |
| `SSIDReference` | `""` | `""` | `""` | `""` |
| `SSIDAdvertisementEnabled` | `true` | `true` | `true` | `true` |
| `IsolationEnable` | `false` | `false` | `false` | `false` |
| `MaxAllowedAssociations` | `32` | `32` | `32` | `32` |
| `X_LINKSYS_MultiAPMode` | `0` | `0` | `0` | `0` |
| `Security.ModeEnabled` | `WPA2-Personal` | `WPA2-Personal` | `None` | `None` |

> All structural fields (SSIDReference, IsolationEnable, MaxAllowedAssociations, X_LINKSYS_MultiAPMode) are identical across all 4 APs. Only `Enable` and `Security.ModeEnabled` differ, but these are not reliable identifiers (users can enable Guest AP and set a password).

**Required:** Add vendor extension on `Device.WiFi.AccessPoint.{i}`:
```
X_LINKSYS_NetworkType   → "primary" | "guest" | "iot"
```

---

### FW-010: DDNS — bbfdm Plugin Missing — P1

| Field | Value |
|-------|-------|
| **TR-181 Path** | `Device.DynamicDNS.*` |
| **Current Status** | fault 9005 (Invalid parameter name) |
| **OpenWrt Support** | ✅ `ddns-scripts` v2.8.2-42 installed, `/etc/config/ddns` UCI config exists |
| **Missing** | No `bbfdm.ddnsmngr` plugin — UCI config not mapped to TR-181 |
| **JNAP Equivalent** | `getDDNSSettings` / `setDDNSSettings` / `getDDNSStatus2` |

**SSH Reproduction:**
```bash
ubus call bbfdm get '{"path":"Device.DynamicDNS."}'
# → fault 9005

ubus call bbfdm get '{"path":"Device.DynamicDNS.Client."}'
# → fault 9005

# But UCI config exists
cat /etc/config/ddns
# → Contains dyndns.org + NoIP configuration templates
```

**Required:** Develop `bbfdm.ddnsmngr` plugin, mapping the following paths:

| TR-181 Path | UCI Path | R/W |
|-------------|----------|-----|
| `Device.DynamicDNS.Client.{i}.Enable` | `ddns.@service[i].enabled` | R/W |
| `Device.DynamicDNS.Client.{i}.Server` | `ddns.@service[i].service_name` | R/W |
| `Device.DynamicDNS.Client.{i}.Username` | `ddns.@service[i].username` | R/W |
| `Device.DynamicDNS.Client.{i}.Password` | `ddns.@service[i].password` | R/W |
| `Device.DynamicDNS.Client.{i}.HostnameList` | `ddns.@service[i].domain` | R/W |
| `Device.DynamicDNS.Client.{i}.Interface` | `ddns.@service[i].interface` | R/W |
| `Device.DynamicDNS.Client.{i}.Status` | runtime | R |

Additional vendor extension needed:
- `X_LINKSYS_SupportedDDNSProviders` — supported DDNS provider list (no standard TR-181 path)

---

### FW-011: QoS Basic — bbfdm Plugin Missing — P3

| Field | Value |
|-------|-------|
| **TR-181 Path** | `Device.QoS.*` |
| **Current Status** | fault 9005 (Invalid parameter name) |
| **Hardware Support** | ✅ `qca-sal-qos` (Qualcomm SAL) installed, ebtables QoS chains exist |
| **Missing** | No `bbfdm.qosmngr` plugin, no `/etc/config/qos` UCI config |
| **JNAP Equivalent** | `setQoSSettings` |

**SSH Reproduction:**
```bash
ubus call bbfdm get '{"path":"Device.QoS."}'
# → fault 9005

ubus call bbfdm get '{"path":"Device.QoS.Classification."}'
# → fault 9005
```

**Required:**
1. Evaluate `bbfdm.qosmngr` plugin feasibility
2. Map basic traffic classification to `Device.QoS.Classification.{i}.*`
3. Confirm whether ebtables rules can be managed via bbfdm

---

## Tier 3: Vendor Extension — New Proprietary Paths

> These features have no corresponding TR-181 standard paths and currently only have JNAP implementations. The firmware team needs to map JNAP features to `X_LINKSYS_*` vendor extensions to complete USP migration.

### WiFi Related

| ID | Feature | JNAP Action | Suggested Vendor Extension | Priority |
|----|---------|-------------|----------------------|----------|
| FW-012 | Smart Connect | `setSmartConnectSettings` | `X_LINKSYS_SmartConnect.Enable`, `X_LINKSYS_SmartConnect.Mode` | P3 |
| FW-013 | Channel Scanner | `startChannelScan` | `X_LINKSYS_ChannelScan()` Operate command + `X_LINKSYS_ChannelScanResult.{i}.*` | P3 |
| FW-014 | WiFi 6E/7 MLO | `setMLOSettings` | `X_LINKSYS_MLO.Enable`, `X_LINKSYS_MLO.Mode` | P2 |
| FW-015 | WiFi Optimization | `setWiFiOptimizationSettings` | `X_LINKSYS_WiFiOptimization.Enable`, `X_LINKSYS_WiFiOptimization.Mode` | P2 |

### Internet Related

| ID | Feature | JNAP Action | Suggested Vendor Extension | Priority |
|----|---------|-------------|----------------------|----------|
| FW-016 | PPTP Connection | `setWANSettings` | `X_LINKSYS_PPTPClient.{i}.Server`, `.Username`, `.Password` | P1 |
| FW-017 | L2TP Connection | `setWANSettings` | `X_LINKSYS_L2TPClient.{i}.Server`, `.Username`, `.Password` | P1 |

### QoS Advanced

| ID | Feature | JNAP Action | Suggested Vendor Extension | Priority |
|----|---------|-------------|----------------------|----------|
| FW-018 | Adaptive QoS | `setAdaptiveQoSSettings` | `X_LINKSYS_AdaptiveQoS.Enable`, `X_LINKSYS_AdaptiveQoS.Mode` | P3 |
| FW-019 | Gaming Prioritization | `setGamePriority` | `X_LINKSYS_GamePriority.Enable`, `X_LINKSYS_GamePriority.DeviceList` | P3 |
| FW-020 | Express Forwarding | `setExpressForwardingSettings` | `X_LINKSYS_ExpressForwarding.Enable` | P3 |

### Parental Control

| ID | Feature | JNAP Action | Suggested Vendor Extension | Priority |
|----|---------|-------------|---------------------------|----------|
| FW-021 | Time-Based Controls | `setParentalControlRules` | `X_LINKSYS_ParentalControl.Rule.{i}.Enable`, `.MACAddress`, `.Schedule`, `.Action` | P3 |
| FW-022 | Content Filtering | `setParentalControlRules` | `X_LINKSYS_ContentFilter.Enable`, `X_LINKSYS_ContentFilter.Category.{i}.*` | P3 |

### Admin / Diagnostics

| ID | Feature | JNAP Action | Suggested Vendor Extension | Priority |
|----|---------|-------------|---------------------------|----------|
| FW-023 | Firmware Update | `setFirmwareUpdateSettings` | First verify `Device.DeviceInfo.FirmwareImage.{i}.Download()` standard path; if unavailable, use `X_LINKSYS_FirmwareUpdate.*` | P1 |
| FW-024 | Auto Firmware Update | `setAutoFirmwareUpdateSettings` | `X_LINKSYS_AutoFirmwareUpdate.Enable`, `.Schedule`, `.Policy` | P2 |
| FW-025 | Speed Test | `runSpeedTest` | `X_LINKSYS_SpeedTest()` Operate command + `X_LINKSYS_SpeedTestResult.*` | P2 |
| FW-026 | Network Modes | `setNetworkModeSettings` | `X_LINKSYS_NetworkMode.Mode` (Router / AP / Bridge) | P1 |

---

## Priority Summary

### P0 Critical — Blocks Core Functionality
| ID | Issue | Category | Status |
|----|-------|----------|--------|
| FW-001 | AddressingType Set No-Op | Internet | 🔴 Blocks all WAN connection switching |

### P1 High — WiFi / Internet Settings Core
| ID | Issue | Category | Status |
|----|-------|----------|--------|
| FW-002 | MAC Clone Non-Writable | Internet | 🔴 MAC clone feature broken |
| FW-003 | PPPoE.ServiceName Denied | Internet | 🔴 PPPoE configuration incomplete |
| FW-004 | IPv6rd Prefix Format | Internet | 🟡 6rd manual configuration blocked |
| FW-005 | Bandwidth Data Inconsistency | WiFi | 🟡 UI bandwidth dropdown may be incomplete |
| FW-007 | MAC Filtering Completely Unusable | WiFi | 🔴 Needs multi-instance fix + deny-list |
| FW-009 | Guest AP Indistinguishable | WiFi | 🟡 Relies on unreliable heuristic |
| FW-010 | DDNS bbfdm Plugin Missing | Internet | 🔴 DDNS feature cannot be migrated |
| FW-016 | PPTP Connection | Internet | 🔴 JNAP dependency |
| FW-017 | L2TP Connection | Internet | 🔴 JNAP dependency |
| FW-023 | Firmware Update Path Verification | Admin | 🟡 Standard path pending verification |
| FW-026 | Network Modes | Internet | 🔴 JNAP dependency |

### P2 Medium — Secondary Features
| ID | Issue | Category | Status |
|----|-------|----------|--------|
| FW-008 | Channel-per-Width Grouping | WiFi | 🟢 Client-side computable (nice-to-have vendor ext) |
| FW-014 | WiFi 6E/7 MLO | WiFi | 🔴 Pending hardware support confirmation |
| FW-015 | WiFi Optimization | WiFi | 🔴 JNAP dependency |
| FW-024 | Auto FW Update | Admin | 🔴 JNAP dependency |
| FW-025 | Speed Test | Diagnostics | 🔴 JNAP dependency |

### P3 Low — QoS / Parental Control / Pending Observation
| ID | Issue | Category | Status |
|----|-------|----------|--------|
| FW-006 | ConnectionTrigger/Bridge.Enable | Internet | 🟡 Pending re-verification after FW-001 fix |
| FW-011 | QoS Basic bbfdm Plugin | QoS | 🔴 QoS cannot be migrated |
| FW-012 | Smart Connect | WiFi | 🔴 JNAP dependency |
| FW-013 | Channel Scanner | WiFi | 🔴 JNAP dependency |
| FW-018 | Adaptive QoS | QoS | 🔴 JNAP dependency |
| FW-019 | Gaming Prioritization | QoS | 🔴 JNAP dependency |
| FW-020 | Express Forwarding | QoS | 🔴 JNAP dependency |
| FW-021 | Parental Control (Time) | Parental | 🔴 JNAP dependency |
| FW-022 | Content Filtering | Parental | 🔴 JNAP dependency |

---

## Expected Delivery and Schedule Suggestion

| Phase | Content | Priority | App-Side Blockers Resolved |
|-------|---------|----------|---------------------------|
| **Phase A** (urgent) | FW-001 AddressingType fix | P0 | WAN connection type switching — unlocks Internet Settings core |
| **Phase B** | FW-002/003/004/005/006 Internet + WiFi bug fix | P1 | MAC clone, full PPPoE config, IPv6rd, Bandwidth correction |
| **Phase C** | FW-007/009 WiFi bbfdm extension | P1 | MAC Filtering, Guest AP identification (FW-008 channel-per-width moved to client-side computation) |
| **Phase D** | FW-010/016/017/026 Internet vendor ext | P1 | DDNS, PPTP/L2TP, Network Modes |
| **Phase E** | FW-014/015/023/024/025 Secondary features | P2 | MLO, WiFi Optimization, FW Update, Speed Test |
| **Phase F** | FW-011/012/013/018/019/020/021/022 QoS + Parental Control + Advanced WiFi | P3 | Full QoS suite, Parental Control, Smart Connect, Channel Scanner |

---

## Test Environment

| Field | Value |
|-------|-------|
| Router Model | Linksys M60TB-EU (PINNACLE 2.0) |
| Firmware | 1.0.16.26013014 |
| OpenWrt | 23.05-SNAPSHOT, r0-225ad95 |
| bbfdm Agent | bbfdm (via ubus) |
| WAN Mode | DHCP (`network.wan.proto='dhcp'`) |
| SSH Access | `root@192.168.1.1` |
| Test Date | 2026-03-16 |

---

## Appendix: bbfdm CLI Quick Reference

```bash
# Get parameter value
ubus call bbfdm get '{"path":"Device.WiFi.Radio.1.PossibleChannels"}'

# Set parameter value
ubus call bbfdm set '{"path":"Device.PPP.Interface.1.Username","value":"myuser"}'

# Get schema (writable check: data:"1"=writable, data:"0"=read-only)
ubus call bbfdm schema '{"path":"Device.PPP.Interface.{i}."}'

# List instances
ubus call bbfdm instances '{"path":"Device.PPP.Interface."}'

# Add instance
ubus call bbfdm add '{"path":"Device.PPP.Interface."}'

# Delete instance
ubus call bbfdm del '{"path":"Device.PPP.Interface.1."}'
```

---

## Related Documentation

- [Internet Settings — Set Validation Report](internet-settings-set-validation.md)
- [Internet Settings — JNAP vs USP Comparison](internet-settings-jnap-vs-usp-comparison.md)
- [WiFi Settings — TR-181 Limitations](wifi-settings-tr181-limitations.md)
- [M2 Roadmap — Full Migration Gap Analysis](../integration/roadmap_m2.md)

---

**Last Updated:** 2026-03-16
**Contact:** App Team — Austin Chang
