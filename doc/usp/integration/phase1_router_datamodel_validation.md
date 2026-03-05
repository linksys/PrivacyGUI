# Phase 1: Router Data Model Validation Report

**Date:** 2026-03-02
**Router:** Linksys M60TB-EU (PINNACLE 2.0)
**Firmware:** 1.0.14.26013014
**Serial:** 67A10M24F00066
**TR-181 Version:** v2.18.1 (reported by SupportedDataModel)
**bbfdm Architecture:** Top-level `bbfdm` + 18 sub-daemons (via `ubus list`)
**Validation Method:** SSH `ubus call` against each bbfdm daemon; cross-referenced with `doc/jnap/jnap_commands_used.md` (140 actions, 31 categories)

---

## Executive Summary

| Metric | Value |
|--------|-------|
| **PrivacyGUI JNAP actions (實際使用)** | **140** |
| **JNAP categories** | **31** |
| TR-181 paths probed | 50+ |
| CRUD operations verified | GET, SET, ADD, DEL, OPERATE |
| **JNAP actions fully replaceable** | **66 (47%)** |
| **JNAP actions partially replaceable** | **18 (13%)** |
| **JNAP actions not replaceable** | **56 (40%)** |
| **Field-level mapping tables** | **37** (for ✅/🟡/⚠️ actions) |
| Critical firmware bugs | 1 (WiFi SSID enumeration) |
| Missing data model modules (fault 9005) | 8 (DDNS, UPnP, QoS, IPsec, SoftwareModules, VendorExt, MACFilter, IPTV) |

---

## CRUD Operations Verification

All five bbfdm operations verified end-to-end:

| Operation | Test Case | Result |
|-----------|-----------|--------|
| **GET** | `Device.DeviceInfo.Manufacturer` | ✅ "Linksys" |
| **SET** | `Device.Time.NTPServer5` → write + readback | ✅ Value persisted, `modified_uci` returned |
| **ADD** | `Device.DHCPv4.Server.Pool.1.StaticAddress.` | ✅ Instance.1 created, UCI modified |
| **DEL** | `Device.DHCPv4.Server.Pool.1.StaticAddress.1.` | ✅ Deleted, instances confirmed empty |
| **OPERATE** | `Device.IP.Diagnostics.IPPing()` Host=8.8.8.8 | ✅ 3/3 success, avg 6ms |

- SET returns `modified_uci` array (e.g. `["/etc/config/system"]`)
- ADD returns new instance number and modified UCI files
- OPERATE returns structured output with Status, SuccessCount, AverageResponseTime, etc.

---

## Complete JNAP-to-TR-181 Replacement Matrix (140 Actions / 31 Categories)

### Status Legend

| Status | Meaning |
|--------|---------|
| ✅ | Fully replaceable — TR-181 data available and verified |
| 🟡 | Partially replaceable — data exists but with gaps or transform needed |
| ❌ | Not replaceable — data model missing (fault 9005 or no equivalent) |
| ⚠️ | Blocked by firmware bug |

> **Field Mapping Tables**: Actions marked ✅ / 🟡 / ⚠️ include an expandable field-level mapping table (`<details>`) below the action row, listing each JNAP response field and its corresponding TR-181 path. Field data sourced from `doc/jnap/jnap_full.md`.

---

### 1. Core (13 actions)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `transaction` | N/A (USP batch) | ✅ | USP natively supports multi-path GET/SET |
| 2 | `checkAdminPassword` | `Device.Users.User.{i}.Password` | 🟡 | Password field returns empty (security); need auth logic via USP auth endpoint |
| 3 | `pnpCheckAdminPassword` | `Device.Users.User.{i}.Password` | 🟡 | Same as above |
| 4 | `coreSetAdminPassword` | `Device.Users.User.{i}.Password` | 🟡 | SET available, but auth flow differs |
| 5 | `pnpSetAdminPassword` | `Device.Users.User.{i}.Password` | 🟡 | Same as above |
| 6 | `getAdminPasswordHint` | — | ❌ | No vendor extension `X_LINKSYS_COM_PasswordHint` |
| 7 | `getAdminPasswordAuthStatus` | — | ❌ | No equivalent in TR-181 |
| 8 | `getDeviceInfo` | `Device.DeviceInfo.` | ✅ | Manufacturer, ModelName, SerialNumber, HardwareVersion, SoftwareVersion, UpTime — all verified |
| 9 | `isAdminPasswordDefault` | — | ❌ | No `X_LINKSYS_COM_IsDefaultPassword` |
| 10 | `reboot` | `Device.Reboot()` | ✅ | OPERATE command registered in bbfdm.core |
| 11 | `reboot2` | `Device.Reboot()` | ✅ | USP Reboot() (node targeting via different agent) |
| 12 | `factoryReset` | `Device.FactoryReset()` | ✅ | OPERATE command registered in bbfdm.core |
| 13 | `factoryReset2` | `Device.FactoryReset()` | ✅ | Same as above |

<details>
<summary>📋 GetDeviceInfo — Field Mapping (8 fields)</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `manufacturer` | string | `Device.DeviceInfo.Manufacturer` | — |
| `modelNumber` | string | `Device.DeviceInfo.ModelName` | JNAP="modelNumber", TR-181="ModelName" |
| `hardwareVersion` | string | `Device.DeviceInfo.HardwareVersion` | — |
| `description` | string | `Device.DeviceInfo.Description` | — |
| `serialNumber` | string | `Device.DeviceInfo.SerialNumber` | — |
| `firmwareVersion` | string | `Device.DeviceInfo.SoftwareVersion` | JNAP="firmwareVersion", TR-181="SoftwareVersion" |
| `firmwareDate` | DateTime | — | No TR-181 equivalent |
| `services` | string[] | — | JNAP-proprietary service list |

</details>

<details>
<summary>📋 checkAdminPassword / setAdminPassword — Field Mapping</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `adminPassword` (input) | string | `Device.Users.User.{i}.Password` | Password field returns empty on GET (security) |
| `passwordHint` | string | — | No vendor extension `X_LINKSYS_COM_PasswordHint` |
| `isDefault` | bool | — | No `X_LINKSYS_COM_IsDefaultPassword` |

> Auth flow differs: JNAP uses session-based auth; USP uses JWT via usp-bridge `/api/v1/auth`.

</details>

**Score: 6 ✅ / 4 🟡 / 3 ❌**

---

### 2. Auto Onboarding (6 actions)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `startBlueboothAutoOnboarding` | — | ❌ | No TR-181 equivalent (Linksys proprietary) |
| 2 | `getBluetoothAutoOnboardingStatus` | — | ❌ | No TR-181 equivalent |
| 3 | `getBluetoothAutoOnboardingSettings` | — | ❌ | No TR-181 equivalent |
| 4 | `setBluetoothAutoOnboardingSettings` | — | ❌ | No TR-181 equivalent |
| 5 | `getWiredAutoOnboardingSettings` | — | ❌ | No TR-181 equivalent |
| 6 | `setWiredAutoOnboardingSettings` | — | ❌ | No TR-181 equivalent |

**Score: 0 ✅ / 0 🟡 / 6 ❌** — Auto onboarding is entirely Linksys-proprietary

---

### 3. DDNS (4 actions)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getDDNSSettings` | `Device.DynamicDNS.Client.{i}.` | ❌ | fault 9005 — no DynamicDNS daemon |
| 2 | `getDDNSStatus` | `Device.DynamicDNS.Client.{i}.Status` | ❌ | Same |
| 3 | `getSupportedDDNSProviders` | — | ❌ | Vendor extension required |
| 4 | `setDDNSSetting` | `Device.DynamicDNS.Client.{i}.` | ❌ | Same |

**Score: 0 ✅ / 0 🟡 / 4 ❌**

---

### 4. Device List (4 actions)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getDevices` | `Device.Hosts.Host.{i}.` | ✅ | Rich: PhysAddress, IPAddress, HostName, Active, InterfaceType, DeviceID, ParentNodeID, IPv4/IPv6 addresses |
| 2 | `getLocalDevice` | `Device.Hosts.Host.{i}.` (filter self) | 🟡 | Need to identify "self" from Hosts list |
| 3 | `setDeviceProperties` | `Device.Hosts.Host.{i}.FriendlyName` | 🟡 | FriendlyName available but custom properties need vendor ext |
| 4 | `deleteDevice` | — | ❌ | TR-181 doesn't support deleting Host entries |

<details>
<summary>📋 GetDevices — Field Mapping (Device2 struct)</summary>

**Top-level output:**

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `revision` | int | — | JNAP-proprietary change tracking |
| `devices` | Device2[] | `Device.Hosts.Host.{i}.*` | Per-device mapping below |
| `deletedDeviceIDs` | UUID[] (opt) | — | JNAP-proprietary (since revision) |

**Device2 per-device fields:**

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `deviceID` | UUID | `Device.Hosts.Host.{i}.DeviceID` | — |
| `lastChangeRevision` | int | — | JNAP-proprietary |
| `model.deviceType` | string | `Device.Hosts.Host.{i}.DeviceType` | — |
| `model.manufacturer` | string (opt) | `Device.Hosts.Host.{i}.Manufacturer` | — |
| `model.modelNumber` | string (opt) | `Device.Hosts.Host.{i}.ModelName` | — |
| `model.hardwareVersion` | string (opt) | — | No host-level HW version in TR-181 |
| `model.description` | string (opt) | — | — |
| `unit.serialNumber` | string (opt) | — | No host-level serial in TR-181 |
| `unit.firmwareVersion` | string (opt) | — | No host-level firmware in TR-181 |
| `unit.operatingSystem` | string (opt) | — | — |
| `isAuthority` | bool | — | JNAP-proprietary (network authority flag) |
| `nodeType` | NodeType (opt) | — | JNAP-proprietary (Master/Slave/None) |
| `friendlyName` | string (opt) | `Device.Hosts.Host.{i}.FriendlyName` | — |
| `knownInterfaces[].macAddress` | MACAddress | `Device.Hosts.Host.{i}.PhysAddress` | — |
| `knownInterfaces[].interfaceType` | InterfaceType | `Device.Hosts.Host.{i}.InterfaceType` | Enum: Wireless, Wired, Unknown |
| `knownInterfaces[].band` | WirelessBand (opt) | `Device.Hosts.Host.{i}.Layer1Interface` | Inferred from Radio reference |
| `connections[].macAddress` | MACAddress | `Device.Hosts.Host.{i}.PhysAddress` | — |
| `connections[].ipAddress` | IPAddress (opt) | `Device.Hosts.Host.{i}.IPAddress` | — |
| `connections[].ipv6Address` | IPv6Address (opt) | `Device.Hosts.Host.{i}.IPv6Address.{i}.IPAddress` | — |
| `connections[].parentDeviceID` | UUID (opt) | `Device.Hosts.Host.{i}.ParentNodeID` | — |
| `connections[].isGuest` | bool (opt) | — | Inferred from AP interface (guest AP) |
| `properties` | Property[] | — | JNAP custom properties (no TR-181 equivalent) |
| `maxAllowedProperties` | int | — | Capability info |

</details>

<details>
<summary>📋 SetDeviceProperties — Field Mapping</summary>

| JNAP Field (input) | Type | TR-181 Path | Notes |
|---------------------|------|-------------|-------|
| `deviceID` | UUID | `Device.Hosts.Host.{i}.DeviceID` | Used to locate instance |
| `propertiesToModify` | Property[] | `Device.Hosts.Host.{i}.FriendlyName` | 🟡 Only FriendlyName mappable; custom props need vendor ext |

</details>

**Score: 1 ✅ / 2 🟡 / 1 ❌**

---

### 5. Diagnostics (7 actions)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `startPing` | `Device.IP.Diagnostics.IPPing()` | ✅ | OPERATE verified: 3/3 success, avg 6ms |
| 2 | `getPingStatus` | IPPing() result | ✅ | Status, SuccessCount, FailureCount, AverageResponseTime |
| 3 | `stopPing` | — | ❌ | TR-181 has no cancel for async commands |
| 4 | `startTracroute` | `Device.IP.Diagnostics.TraceRoute()` | ✅ | TraceRoute params verified (Host, MaxHopCount, Timeout) |
| 5 | `getTracerouteStatus` | TraceRoute() result | ✅ | RouteHops available |
| 6 | `stopTracroute` | — | ❌ | TR-181 has no cancel |
| 7 | `getSystemStats` | `Device.DeviceInfo.ProcessStatus.CPUUsage` + `MemoryStatus.` | ✅ | CPUUsage, Total/Free memory verified |

<details>
<summary>📋 StartPing / GetPingStatus — Field Mapping</summary>

**StartPing input:**

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `host` (input) | string | `Device.IP.Diagnostics.IPPing.Host` | IP or hostname |
| `pingCount` (input) | int | `Device.IP.Diagnostics.IPPing.NumberOfRepetitions` | — |
| `pingSize` (input) | int | `Device.IP.Diagnostics.IPPing.DataBlockSize` | — |

**GetPingStatus output:**

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `isRunning` | bool | `Device.IP.Diagnostics.IPPing.DiagnosticsState` | "Requested"/"Complete" → bool |
| `pingLog` | string | — | JNAP returns raw text log; TR-181 returns structured fields below |
| — | — | `...IPPing.SuccessCount` | Available in TR-181 (not in JNAP structured) |
| — | — | `...IPPing.FailureCount` | Available in TR-181 |
| — | — | `...IPPing.AverageResponseTime` | Available in TR-181 |
| — | — | `...IPPing.MinimumResponseTime` | Available in TR-181 |
| — | — | `...IPPing.MaximumResponseTime` | Available in TR-181 |

> TR-181 IPPing() returns structured results (SuccessCount, AvgTime, etc.), while JNAP returns a text-based pingLog. TR-181 is richer for programmatic use.

</details>

<details>
<summary>📋 StartTraceroute / GetTracerouteStatus — Field Mapping</summary>

**StartTraceroute input:**

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `host` (input) | string | `Device.IP.Diagnostics.TraceRoute.Host` | IP or hostname |

**GetTracerouteStatus output:**

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `isRunning` | bool | `Device.IP.Diagnostics.TraceRoute.DiagnosticsState` | "Requested"/"Complete" → bool |
| `tracerouteLog` | string | — | JNAP returns raw text; TR-181 returns structured RouteHops |
| — | — | `...TraceRoute.RouteHops.{i}.Host` | Structured hop data in TR-181 |
| — | — | `...TraceRoute.RouteHops.{i}.RTTimes` | Per-hop round-trip times |

</details>

<details>
<summary>📋 GetSystemStats — Field Mapping (1 field)</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `uptimeSeconds` | int | `Device.DeviceInfo.UpTime` | — |
| — | — | `Device.DeviceInfo.ProcessStatus.CPUUsage` | Available in TR-181 (not in JNAP) |
| — | — | `Device.DeviceInfo.MemoryStatus.Total` | Available in TR-181 (not in JNAP) |
| — | — | `Device.DeviceInfo.MemoryStatus.Free` | Available in TR-181 (not in JNAP) |

> JNAP GetSystemStats only returns uptimeSeconds. TR-181 exposes richer system stats (CPU, Memory) that JNAP doesn't surface.

</details>

**Score: 5 ✅ / 0 🟡 / 2 ❌**

---

### 6. Firewall (14 actions)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getSinglePortForwardingRules` | `Device.NAT.PortMapping.{i}.` | ✅ | Schema: 20+ params; ADD/DEL verified; empty = no rules configured |
| 2 | `setSinglePortForwardingRules` | `Device.NAT.PortMapping.{i}.` | ✅ | SET available |
| 3 | `getPortRangeForwardingRules` | `Device.NAT.PortMapping.{i}.` (with PortRange) | ✅ | Uses ExternalPortEndRange |
| 4 | `setPortRangeForwardingRules` | `Device.NAT.PortMapping.{i}.` | ✅ | SET available |
| 5 | `getPortRangeTriggeringRules` | `Device.NAT.PortTrigger.{i}.` | ✅ | Schema exists; empty = no rules |
| 6 | `setPortRangeTriggeringRules` | `Device.NAT.PortTrigger.{i}.` | ✅ | SET available |
| 7 | `getIPv6FirewallRules` | `Device.Firewall.Chain.{i}.Rule.{i}.` | ✅ | 106KB data — complete rule chains |
| 8 | `setIPv6FirewallRules` | `Device.Firewall.Chain.{i}.Rule.{i}.` | ✅ | SET available |
| 9 | `getFirewallSettings` | `Device.Firewall.Enable` + `Level.{i}.` | 🟡 | Enable works; Level (8 entries); top-level enum bug (BUG-002) |
| 10 | `setFirewallSettings` | `Device.Firewall.` | 🟡 | SET on individual params works |
| 11 | `getDMZSettings` | `Device.Firewall.DMZ.{i}.` | 🟡 | Schema exists; empty = no DMZ configured; ADD available |
| 12 | `setDMZSettings` | `Device.Firewall.DMZ.{i}.` | 🟡 | SET available when DMZ created |
| 13 | `getALGSettings` | `Device.Firewall.ConnectionTracking.` | ❌ | fault 9005 — not implemented |
| 14 | `setALGSettings` | `Device.Firewall.ConnectionTracking.` | ❌ | Same |

<details>
<summary>📋 GetSinglePortForwardingRules / SetSinglePortForwardingRules — Field Mapping</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `maxRules` | int | — | Capability info |
| `maxDescriptionLength` | int | — | Capability info |
| `rules` | SinglePortForwardingRule[] | `Device.NAT.PortMapping.{i}.*` | Per-instance mapping below |
| `rules[].isEnabled` | bool | `...PortMapping.{i}.Enable` | — |
| `rules[].externalPort` | int | `...PortMapping.{i}.ExternalPort` | — |
| `rules[].protocol` | IPProtocol | `...PortMapping.{i}.Protocol` | Enum: TCP, UDP, Both → "TCP", "UDP", "TCP/UDP" |
| `rules[].internalServerIPAddress` | IPAddress | `...PortMapping.{i}.InternalClient` | — |
| `rules[].internalPort` | int | `...PortMapping.{i}.InternalPort` | — |
| `rules[].description` | string | `...PortMapping.{i}.Description` | — |

</details>

<details>
<summary>📋 GetPortRangeForwardingRules / SetPortRangeForwardingRules — Field Mapping</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `maxRules` | int | — | Capability info |
| `maxDescriptionLength` | int | — | Capability info |
| `rules` | PortRangeForwardingRule[] | `Device.NAT.PortMapping.{i}.*` | Uses ExternalPortEndRange |
| `rules[].isEnabled` | bool | `...PortMapping.{i}.Enable` | — |
| `rules[].firstExternalPort` | int | `...PortMapping.{i}.ExternalPort` | — |
| `rules[].lastExternalPort` | int | `...PortMapping.{i}.ExternalPortEndRange` | — |
| `rules[].protocol` | IPProtocol | `...PortMapping.{i}.Protocol` | — |
| `rules[].internalServerIPAddress` | IPAddress | `...PortMapping.{i}.InternalClient` | — |
| `rules[].description` | string | `...PortMapping.{i}.Description` | — |

</details>

<details>
<summary>📋 GetPortRangeTriggeringRules / SetPortRangeTriggeringRules — Field Mapping</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `maxRules` | int | — | Capability info |
| `maxDescriptionLength` | int | — | Capability info |
| `rules` | PortRangeTriggeringRule[] | `Device.NAT.PortTrigger.{i}.*` | Per-instance mapping below |
| `rules[].isEnabled` | bool | `...PortTrigger.{i}.Enable` | — |
| `rules[].firstTriggerPort` | int | `...PortTrigger.{i}.TriggerPortStart` | — |
| `rules[].lastTriggerPort` | int | `...PortTrigger.{i}.TriggerPortEnd` | — |
| `rules[].firstForwardedPort` | int | `...PortTrigger.{i}.OpenPortStart` | — |
| `rules[].lastForwardedPort` | int | `...PortTrigger.{i}.OpenPortEnd` | — |
| `rules[].description` | string | `...PortTrigger.{i}.Description` | — |

</details>

<details>
<summary>📋 GetIPv6FirewallRules / SetIPv6FirewallRules — Field Mapping</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `maxRules` | int | — | Capability info |
| `maxPortRanges` | int | — | Capability info |
| `maxDescriptionLength` | int | — | Capability info |
| `rules` | IPv6FirewallRule[] | `Device.Firewall.Chain.{i}.Rule.{i}.*` | Per-rule mapping below |
| `rules[].isEnabled` | bool | `...Rule.{i}.Enable` | — |
| `rules[].ipv6Address` | IPv6Address | `...Rule.{i}.DestIP` | — |
| `rules[].portRanges` | PortRange[] | `...Rule.{i}.DestPort` | Multiple port ranges → rule format |
| `rules[].description` | string | `...Rule.{i}.Description` | — |

</details>

<details>
<summary>📋 GetFirewallSettings / SetFirewallSettings — Field Mapping (9 fields)</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `isIPv4FirewallEnabled` | bool | `Device.Firewall.Enable` | String "1" → bool |
| `isIPv6FirewallEnabled` | bool | `Device.Firewall.Enable` | 🟡 Single Enable in TR-181 (no v4/v6 split) |
| `blockMulticast` | bool | `Device.Firewall.Level.{i}.*` | Mapped to firewall level config |
| `blockNATRedirection` | bool | `Device.Firewall.Level.{i}.*` | — |
| `blockIDENT` | bool | `Device.Firewall.Level.{i}.*` | Port 113 block |
| `blockAnonymousRequests` | bool | `Device.Firewall.Level.{i}.*` | WAN ping block |
| `blockIPSec` | bool | `Device.Firewall.Level.{i}.*` | — |
| `blockPPTP` | bool | `Device.Firewall.Level.{i}.*` | — |
| `blockL2TP` | bool | `Device.Firewall.Level.{i}.*` | — |

> TR-181 uses `Firewall.Level.{i}` with 8 entries for per-feature toggles. BUG-002: top-level `Device.Firewall.` GET returns empty, must query sub-objects individually.

</details>

<details>
<summary>📋 GetDMZSettings / SetDMZSettings — Field Mapping (4 fields)</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `isDMZEnabled` | bool | `Device.Firewall.DMZ.{i}.Enable` | Schema exists; empty = no DMZ configured |
| `sourceRestriction` | DMZSourceRestriction (opt) | `Device.Firewall.DMZ.{i}.SourceIP` | 🟡 Partial mapping |
| `destinationIPAddress` | IPAddress (opt) | `Device.Firewall.DMZ.{i}.DestinationIP` | — |
| `destinationMACAddress` | MACAddress (opt) | `Device.Firewall.DMZ.{i}.DestinationMAC` | — |

</details>

**Score: 8 ✅ / 4 🟡 / 2 ❌**

---

### 7. Firmware Update (6 actions)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getFirmwareUpdateStatus` | `Device.DeviceInfo.FirmwareImage.{i}.Status` | 🟡 | FirmwareImage exists in DeviceInfo but limited |
| 2 | `getNodesFirmwareUpdateStatus` | — | ❌ | No multi-node firmware model |
| 3 | `getFirmwareUpdateSettings` | `Device.SoftwareModules.` | ❌ | fault 9005 — no SoftwareModules daemon |
| 4 | `setFirmwareUpdateSettings` | — | ❌ | Same |
| 5 | `updateFirmwareNow` | — | ❌ | No Download()/Install() command |
| 6 | `nodesUpdateFirmwareNow` | — | ❌ | Same |

<details>
<summary>📋 GetFirmwareUpdateStatus — Field Mapping (4 fields)</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `lastSuccessfulCheckTime` | DateTime | — | No TR-181 equivalent |
| `availableUpdate` | FirmwareUpdate (opt) | `Device.DeviceInfo.FirmwareImage.{i}.Version` | 🟡 Limited — only current image info available |
| `pendingOperation` | FirmwareUpdateOperationStatus (opt) | — | No equivalent (no SoftwareModules daemon) |
| `lastOperationFailure` | FirmwareUpdateOperationFailure (opt) | — | No equivalent |

</details>

**Score: 0 ✅ / 1 🟡 / 5 ❌**

---

### 8. Guest Network (5 actions)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getGuestRadioSettings` | `Device.WiFi.AccessPoint.3.` + `AP.4.` | ✅ | AP + SSID data available (BUG-001 fixed) |
| 2 | `setGuestRadioSettings` | `Device.WiFi.AccessPoint.3.` + `AP.4.` | ⚠️ | Same |
| 3 | `getGuestNetworkSettings` | `Device.WiFi.AccessPoint.{i}.` (guest APs) | 🟡 | AP config available; SSID name missing |
| 4 | `setGuestNetworkSettings` | `Device.WiFi.AccessPoint.{i}.` | 🟡 | SET available on AP params |
| 5 | `getGuestNetworkClients` | `Device.WiFi.AccessPoint.{i}.AssociatedDevice.{i}.` | ✅ | Verified: AP.2 has 1 AssociatedDevice |

<details>
<summary>📋 GetGuestRadioSettings / SetGuestRadioSettings — Field Mapping ⚠️</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `isGuestNetworkEnabled` | bool | `Device.WiFi.AccessPoint.{guest_i}.Enable` | Guest AP enable flag |
| `radios` | GuestRadioSettings[] | `Device.WiFi.AccessPoint.{guest_i}.*` | Per-radio guest config |
| `radios[].radioID` | string | `Device.WiFi.Radio.{i}.Name` | Identifies radio |
| `radios[].isEnabled` | bool | `Device.WiFi.AccessPoint.{guest_i}.Enable` | — |
| `radios[].broadcastGuestSSID` | bool | `Device.WiFi.AccessPoint.{guest_i}.SSIDAdvertisementEnabled` | — |
| `radios[].guestSSID` | string | `Device.WiFi.SSID.{guest_i}.SSID` | ✅ BUG-001 fixed |
| `radios[].guestPassword` | string | `Device.WiFi.AccessPoint.{guest_i}.Security.KeyPassphrase` | — |
| `maxSimultaneousGuests` | int | — | JNAP-proprietary |
| `guestPasswordRestrictions` | GuestPasswordRestrictions | — | Capability info |
| `maxSimultaneousGuestsLimit` | int | — | Capability info |

</details>

<details>
<summary>📋 GetGuestNetworkSettings / SetGuestNetworkSettings — Field Mapping</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `isGuestNetworkEnabled` | bool | `Device.WiFi.AccessPoint.{guest_i}.Enable` | — |
| `broadcastGuestSSID` | bool | `Device.WiFi.AccessPoint.{guest_i}.SSIDAdvertisementEnabled` | — |
| `guestSSID` | string | `Device.WiFi.SSID.{guest_i}.SSID` | ✅ BUG-001 fixed |
| `guestPassword` | string | `Device.WiFi.AccessPoint.{guest_i}.Security.KeyPassphrase` | — |
| `maxSimultaneousGuests` | int | — | JNAP-proprietary |
| `canEnableGuestNetwork` | bool | — | Capability info |

</details>

<details>
<summary>📋 GetGuestNetworkClients — Field Mapping</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `clients` | AuthorizedClient[] | `Device.WiFi.AccessPoint.{guest_i}.AssociatedDevice.{i}.*` | Per-client mapping |
| `clients[].macAddress` | MACAddress | `...AssociatedDevice.{i}.MACAddress` | — |

</details>

**Score: 1 ✅ / 2 🟡 / 0 ❌ / 2 ⚠️**

---

### 9. Health Check (6 actions)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `runHealthCheck` | `Device.IP.Diagnostics.SpeedTest.` (partial) | ❌ | No complete HealthCheck model |
| 2 | `getHealthCheckStatus` | — | ❌ | No equivalent |
| 3 | `getHealthCheckResults` | — | ❌ | No equivalent |
| 4 | `getSupportedHealthCheckModules` | — | ❌ | Linksys-proprietary |
| 5 | `getCloseHealthCheckServers` | — | ❌ | Linksys-proprietary |
| 6 | `stopHealthCheck` | — | ❌ | No equivalent |

**Score: 0 ✅ / 0 🟡 / 6 ❌**

---

### 10. Locale / Time (3 actions)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getLocalTime` | `Device.Time.CurrentLocalTime` | ✅ | Value: `2026-03-02T03:34:02+00:00` |
| 2 | `getTimeSettings` | `Device.Time.` | ✅ | Enable, NTPServer1-5, LocalTimeZone, Status |
| 3 | `setTimeSettings` | `Device.Time.` | ✅ | SET verified (NTPServer5 write + readback) |

<details>
<summary>📋 GetLocalTime / GetTimeSettings / SetTimeSettings — Field Mapping (shared)</summary>

**GetLocalTime output:**

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `currentTime` | string (ISO-8601) | `Device.Time.CurrentLocalTime` | — |

**GetTimeSettings output:**

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `timeZoneID` | string | `Device.Time.LocalTimeZone` | Transform: JNAP timezone ID → POSIX TZ string |
| `autoAdjustForDST` | bool | — | Embedded in POSIX TZ string in TR-181 |
| `supportedTimeZones` | TimeZone[] | — | Capability info (no TR-181 equivalent) |
| `currentTime` | DateTime | `Device.Time.CurrentLocalTime` | — |

**SetTimeSettings input (same fields writable):**

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `timeZoneID` | string | `Device.Time.LocalTimeZone` | Transform needed |
| `autoAdjustForDST` | bool | — | Encoded in TZ string |

> TR-181 also exposes `Device.Time.Enable`, `NTPServer1-5`, `Status` which have no direct JNAP equivalent — JNAP abstracts NTP config.

</details>

**Score: 3 ✅ / 0 🟡 / 0 ❌**

---

### 11. MAC Filter (3 actions)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getMACFilterSettings` | `Device.WiFi.AP.{i}.X_LINKSYS_COM_MACFilter.` | ❌ | fault 9005; no Hosts.AccessControl either |
| 2 | `setMACFilterSettings` | — | ❌ | Same |
| 3 | `getSTABSSIDs` | — | ❌ | No equivalent |

**Score: 0 ✅ / 0 🟡 / 3 ❌**

---

### 12. Network Connections (1 action)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getNetworkConnections` | `Device.WiFi.AP.{i}.AssociatedDevice.{i}.` + `Ethernet.Interface.{i}.` | ✅ | WiFi clients via AP AssociatedDevice; Ethernet via Interface |

<details>
<summary>📋 GetNetworkConnections — Field Mapping (Layer2Connection)</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `connections` | Layer2Connection[] | WiFi + Ethernet combined | Per-connection mapping below |
| `connections[].macAddress` | MACAddress | `Device.WiFi.AccessPoint.{i}.AssociatedDevice.{i}.MACAddress` / `Device.Hosts.Host.{i}.PhysAddress` | WiFi or Ethernet |
| `connections[].negotiatedMbps` | int | `Device.WiFi.AccessPoint.{i}.AssociatedDevice.{i}.LastDataDownlinkRate` / `Device.Ethernet.Interface.{i}.CurrentBitRate` | Source depends on connection type |
| `connections[].wireless` | WirelessConnection (opt) | `Device.WiFi.AccessPoint.{i}.AssociatedDevice.{i}.*` | Present only for WiFi clients |
| `connections[].wireless.bssid` | MACAddress | `Device.WiFi.AccessPoint.{i}.MACAddress` | — |
| `connections[].wireless.band` | WirelessBand | Inferred from `Device.WiFi.Radio.{i}.OperatingFrequencyBand` | Via AP → Radio reference |
| `connections[].wireless.signalStrength` | int | `...AssociatedDevice.{i}.SignalStrength` | dBm |

</details>

**Score: 1 ✅ / 0 🟡 / 0 ❌**

---

### 13. Nodes Diagnostics (1 action)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getBackhaulInfo` | `Device.WiFi.DataElements.` | 🟡 | DataElements available (127B) but minimal data |

<details>
<summary>📋 GetBackhaulInfo — Field Mapping (BackhaulDeviceInfo)</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `backhaulDevices` | BackhaulDeviceInfo[] | `Device.WiFi.DataElements.*` | 🟡 Minimal data available |
| `backhaulDevices[].deviceUUID` | UUID | — | JNAP-proprietary |
| `backhaulDevices[].ipAddress` | IPAddress | — | 🟡 Not in DataElements |
| `backhaulDevices[].parentIPAddress` | IPAddress | — | 🟡 Not in DataElements |
| `backhaulDevices[].connectionType` | BackhaulConnectionType | — | Wired/Wireless — partial via MultiAP |
| `backhaulDevices[].wirelessConnectionInfo` | WirelessBackhaulConnectionInfo (opt) | — | — |
| `backhaulDevices[].speedMbps` | string | — | — |

> TR-181 `Device.WiFi.DataElements` is available (127B) but provides minimal backhaul data compared to JNAP's rich structure.

</details>

**Score: 0 ✅ / 1 🟡 / 0 ❌**

---

### 14. Nodes Network Connections (1 action)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getNodesWirelessNetworkConnections` | `Device.WiFi.MultiAP.APDevice.{i}.` | 🟡 | MultiAP available (122B) but minimal |

<details>
<summary>📋 GetNodesWirelessNetworkConnections — Field Mapping</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `nodeWirelessConnections` | NodeWirelessConnection[] | `Device.WiFi.MultiAP.APDevice.{i}.*` | 🟡 Minimal — 122B total |

> TR-181 MultiAP data is skeletal. Most JNAP node-level wireless connection details (per-client RSSI, band, connected AP) have no direct TR-181 mapping.

</details>

**Score: 0 ✅ / 1 🟡 / 0 ❌**

---

### 15. Nodes Topology Optimization (2 actions)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getTopologyOptimizationSettings` | `Device.WiFi.MultiAP.` | ❌ | MultiAP has data but no topology optimization params |
| 2 | `setTopologyOptimizationSettings` | — | ❌ | Requires vendor extension |

**Score: 0 ✅ / 0 🟡 / 2 ❌**

---

### 16. Power Table (2 actions)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getPowerTableSettings` | — | ❌ | No TR-181 equivalent; Linksys-proprietary |
| 2 | `setPowerTableSettings` | — | ❌ | Same |

**Score: 0 ✅ / 0 🟡 / 2 ❌**

---

### 17. Product (1 action)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getSoftSKUSettings` | — | ❌ | No TR-181 equivalent; Linksys-proprietary |

**Score: 0 ✅ / 0 🟡 / 1 ❌**

---

### 18. QoS (1 action)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getQoSSettings` | `Device.QoS.` | ❌ | fault 9005 — no QoS daemon registered |

**Score: 0 ✅ / 0 🟡 / 1 ❌**

---

### 19. Router (17 actions)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getWANSettings` | `Device.IP.Interface.{i}.` + `Device.PPP.Interface.{i}.` | ✅ | Full WAN data (DHCP/Static/PPPoE) |
| 2 | `setWANSettings` | Same | ✅ | SET available |
| 3 | `getWANStatus` | `Device.IP.Interface.{i}.Status` + `IPv4Address` | ✅ | Status="Up", IP available |
| 4 | `getWANExternal` | `Device.IP.Interface.{i}.IPv4Address.{i}.` | 🟡 | External IP via WAN interface; may need NAT traversal |
| 5 | `getLANSettings` | `Device.DHCPv4.Server.Pool.{i}.` + `Device.IP.Interface.1.IPv4Address.{i}.` | ✅ | MinAddress, MaxAddress, SubnetMask, LeaseTime, DNSServers — all verified |
| 6 | `setLANSettings` | Same | ✅ | SET available |
| 7 | `getIPv6Settings` | `Device.IP.Interface.{i}.IPv6Address.{i}.` + DHCPv6 | ✅ | Client + Server pools available |
| 8 | `setIPv6Settings` | Same | ✅ | SET available |
| 9 | `getRoutingSettings` | `Device.Routing.Router.{i}.IPv4Forwarding.{i}.` | ✅ | 7899B data — full routing table |
| 10 | `setRoutingSettings` | Same | ✅ | SET available |
| 11 | `renewDHCPWANLease` | `Device.DHCPv4.Client.{i}.Renew()` | ✅ | OPERATE command |
| 12 | `renewDHCPIPv6WANLease` | `Device.DHCPv6.Client.{i}.Renew()` | ✅ | OPERATE command |
| 13 | `getEthernetPortConnections` | `Device.Ethernet.Interface.{i}.` | ✅ | Status, DuplexMode, CurrentBitRate |
| 14 | `getMACAddressCloneSettings` | `Device.Ethernet.Interface.{i}.MACAddress` | 🟡 | MAC readable; clone logic needs vendor ext |
| 15 | `setMACAddressCloneSettings` | — | ❌ | Requires vendor extension |
| 16 | `getExpressForwardingSettings` | — | ❌ | Linksys-proprietary |
| 17 | `setExpressForwardingSettings` | — | ❌ | Same |

<details>
<summary>📋 GetWANSettings / SetWANSettings — Field Mapping (9 fields)</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `wanType` | WANType enum | `Device.IP.Interface.{i}.Type` | Enum: DHCP, Static, PPPoE, PPTP, L2TP, Bridge, DSLite, Telstra |
| `pppoeSettings` | PPPoESettings | `Device.PPP.Interface.{i}.*` | username, password, serviceName → PPP.Interface params |
| `pppoeSettings.username` | string | `Device.PPP.Interface.{i}.Username` | — |
| `pppoeSettings.password` | string | `Device.PPP.Interface.{i}.Password` | — |
| `pppoeSettings.serviceName` | string | `Device.PPP.Interface.{i}.ServiceName` | — |
| `staticSettings` | StaticSettings | `Device.IP.Interface.{i}.IPv4Address.{i}.*` | ipAddress, networkPrefixLength, gateway, dnsServer1/2 |
| `staticSettings.ipAddress` | IPAddress | `Device.IP.Interface.{i}.IPv4Address.{i}.IPAddress` | — |
| `staticSettings.gateway` | IPAddress | `Device.Routing.Router.1.IPv4Forwarding.{i}.GatewayIPAddress` | — |
| `domainName` | string | `Device.IP.Interface.{i}.DomainName` | Optional; ISP-assigned |
| `mtu` | int | `Device.IP.Interface.{i}.MaxMTUSize` | 0 = auto; Bridge mode always 0 |
| `tpSettings` | TPSettings | — | 🟡 PPTP/L2TP — partial TR-181 mapping |
| `bridgeSettings` | BridgeSettings | — | 🟡 Bridge mode — vendor-specific |
| `dsliteSettings` | DSLiteSettings | `Device.IPv6rd.*` | Partial — DS-Lite tunnel params |
| `telstraSettings` | TelstraSettings | — | ❌ Telstra-specific, no TR-181 |

</details>

<details>
<summary>📋 GetWANStatus — Field Mapping (10 fields)</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `supportedWANTypes` | WANType[] | — | No TR-181 equivalent (capability discovery) |
| `isDetectingWANType` | bool | — | JNAP-proprietary auto-detect state |
| `detectedWANType` | WANType (opt) | — | JNAP-proprietary |
| `wanStatus` | WANStatus enum | `Device.IP.Interface.{i}.Status` | Enum mapping: Connected→"Up", Disconnected→"Down" |
| `wanConnection` | WANConnectionInfo (opt) | `Device.IP.Interface.{i}.IPv4Address.{i}.*` | ipAddress, networkPrefixLength, gateway, dnsServer1/2 |
| `wanConnection.ipAddress` | IPAddress | `Device.IP.Interface.{i}.IPv4Address.{i}.IPAddress` | — |
| `wanConnection.gateway` | IPAddress | `Device.Routing.Router.1.IPv4Forwarding.{i}.GatewayIPAddress` | — |
| `state` | PPPConnectionState (opt) | `Device.PPP.Interface.{i}.Status` | Only when wanType=PPPoE |
| `wanIPv6Status` | WANStatus | `Device.IP.Interface.{i}.IPv6Address.{i}.Status` | — |
| `linkLocalIPv6Address` | IPv6Address (opt) | `Device.IP.Interface.{i}.IPv6Address.{i}.IPAddress` | Link-local scope |
| `wanIPv6Connection` | WANIPv6ConnectionInfo (opt) | `Device.IP.Interface.{i}.IPv6Address.{i}.*` | IPv6 address + prefix info |
| `macAddress` | MACAddress | `Device.Ethernet.Interface.{i}.MACAddress` | WAN interface MAC |

</details>

<details>
<summary>📋 GetWANExternal — Field Mapping</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `externalIPAddress` | IPAddress | `Device.IP.Interface.{i}.IPv4Address.{i}.IPAddress` | 🟡 May differ if behind NAT; TR-181 shows local WAN IP |

</details>

<details>
<summary>📋 GetLANSettings / SetLANSettings — Field Mapping (10 fields)</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `ipAddress` | IPAddress | `Device.IP.Interface.1.IPv4Address.{i}.IPAddress` | Router LAN IP |
| `networkPrefixLength` | int | `Device.IP.Interface.1.IPv4Address.{i}.SubnetMask` | Transform: prefix length ↔ subnet mask |
| `minNetworkPrefixLength` | int | — | Capability info, no TR-181 equivalent |
| `maxNetworkPrefixLength` | int | — | Capability info |
| `hostName` | string | `Device.DeviceInfo.HostName` | — |
| `minAllowedDHCPLeaseMinutes` | int | — | Capability info |
| `maxAllowedDHCPLeaseMinutes` | int (opt) | — | Capability info |
| `maxDHCPReservationDescriptionLength` | int | — | Capability info |
| `isDHCPEnabled` | bool | `Device.DHCPv4.Server.Pool.{i}.Enable` | String "1" → bool |
| `dhcpSettings.minAddress` | IPAddress | `Device.DHCPv4.Server.Pool.{i}.MinAddress` | — |
| `dhcpSettings.maxAddress` | IPAddress | `Device.DHCPv4.Server.Pool.{i}.MaxAddress` | — |
| `dhcpSettings.leaseMinutes` | int | `Device.DHCPv4.Server.Pool.{i}.LeaseTime` | Transform: minutes → seconds (×60) |
| `dhcpSettings.dnsServer1` | IPAddress | `Device.DHCPv4.Server.Pool.{i}.DNSServers` | Comma-separated in TR-181 |
| `dhcpSettings.dnsServer2` | IPAddress | `Device.DHCPv4.Server.Pool.{i}.DNSServers` | Combined with dnsServer1 |
| `dhcpSettings.reservations` | DHCPReservation[] | `Device.DHCPv4.Server.Pool.{i}.StaticAddress.{i}.*` | ADD/DEL instances |

</details>

<details>
<summary>📋 GetIPv6Settings / SetIPv6Settings — Field Mapping (4 fields)</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `isIPv6AutomaticEnabled` | bool | `Device.IP.Interface.{i}.IPv6Enable` | — |
| `ipv6rdTunnelMode` | IPv6rdTunnelMode (opt) | `Device.IPv6rd.InterfaceSetting.{i}.Status` | Enum: Automatic, Manual, 6to4, Disabled |
| `ipv6rdTunnelSettings` | IPv6rdTunnelSettings (opt) | `Device.IPv6rd.InterfaceSetting.{i}.*` | prefix, relay, prefixLength |
| `duid` | string (opt) | `Device.DHCPv6.Client.{i}.DUID` | DHCPv6 unique ID |

</details>

<details>
<summary>📋 GetRoutingSettings / SetRoutingSettings — Field Mapping (4 fields)</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `isNATEnabled` | bool | `Device.NAT.InterfaceSetting.{i}.Enable` | — |
| `isDynamicRoutingEnabled` | bool | — | RIP protocol; no standard TR-181 path |
| `entries` | NamedStaticRouteEntry[] | `Device.Routing.Router.{i}.IPv4Forwarding.{i}.*` | Per-entry mapping below |
| `entries[].name` | string | `Device.Routing.Router.{i}.IPv4Forwarding.{i}.Alias` | Route name → Alias |
| `entries[].ipAddress` | IPAddress | `...IPv4Forwarding.{i}.DestIPAddress` | — |
| `entries[].networkPrefixLength` | int | `...IPv4Forwarding.{i}.DestSubnetMask` | Transform: prefix → mask |
| `entries[].gateway` | IPAddress | `...IPv4Forwarding.{i}.GatewayIPAddress` | — |
| `entries[].interface` | string | `...IPv4Forwarding.{i}.Interface` | — |
| `maxStaticRouteEntries` | int | — | Capability info |

</details>

<details>
<summary>📋 GetEthernetPortConnections — Field Mapping (2 fields)</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `wanPortConnection` | EthernetPortConnection | `Device.Ethernet.Interface.{wan}.Status` + `CurrentBitRate` | Enum: None, 10Mbps..10Gbps → Status + bitrate |
| `lanPortConnections` | EthernetPortConnection[] | `Device.Ethernet.Interface.{lan_i}.Status` + `CurrentBitRate` | One per LAN port |

> EthernetPortConnection is an enum (None/10Mbps/100Mbps/1Gbps/2.5Gbps/5Gbps/10Gbps). TR-181 uses separate `Status` ("Up"/"Down") + `CurrentBitRate` (numeric) fields.

</details>

<details>
<summary>📋 GetMACAddressCloneSettings — Field Mapping (2 fields)</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `isMACAddressCloneEnabled` | bool | — | 🟡 No standard TR-181 toggle for MAC cloning |
| `macAddress` | MACAddress (opt) | `Device.Ethernet.Interface.{wan}.MACAddress` | Readable; SET requires vendor extension |

</details>

**Score: 12 ✅ / 2 🟡 / 3 ❌**

---

### 20. Router Management (2 actions)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getManagementSettings` | `Device.UserInterface.RemoteAccess.` | 🟡 | UserInterface available (123B) but limited |
| 2 | `setManagementSettings` | Same | 🟡 | SET available on UserInterface params |

<details>
<summary>📋 GetManagementSettings / SetManagementSettings — Field Mapping (4 fields)</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `canManageUsingHTTP` | bool | `Device.UserInterface.RemoteAccess.Enable` | 🟡 TR-181 has single Enable toggle |
| `canManageUsingHTTPS` | bool | `Device.UserInterface.RemoteAccess.Enable` | 🟡 No HTTP/HTTPS distinction in TR-181 |
| `canManageWirelessly` | bool | — | No TR-181 equivalent |
| `canManageRemotely` | bool | `Device.UserInterface.RemoteAccess.Enable` | 🟡 Partial — RemoteAccess covers WAN access |

> TR-181 `UserInterface.RemoteAccess` is limited (123B). JNAP provides finer-grained control (HTTP vs HTTPS, wireless vs wired) that TR-181 doesn't distinguish.

</details>

**Score: 0 ✅ / 2 🟡 / 0 ❌**

---

### 21. Router UPnP (2 actions)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getUPnPSettings` | `Device.UPnP.Device.Enable` | ❌ | fault 9005 — no UPnP module |
| 2 | `setUPnPSettings` | Same | ❌ | Same |

**Score: 0 ✅ / 0 🟡 / 2 ❌**

---

### 22. Router LEDs (2 actions)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getLedNightModeSetting` | — | ❌ | No `X_LINKSYS_COM_LED` vendor ext |
| 2 | `setLedNightModeSetting` | — | ❌ | Same |

**Score: 0 ✅ / 0 🟡 / 2 ❌**

---

### 23. Setup (13 actions)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getSimpleWiFiSettings` | `Device.WiFi.SSID.{i}.` + `AP.{i}.Security.` | ✅ | SSID + Security available (BUG-001 fixed) |
| 2 | `setSimpleWiFiSettings` | Same | ⚠️ | Same |
| 3 | `isAdminPasswordSetByUser` | — | ❌ | No `X_LINKSYS_COM_Setup.PasswordConfigured` |
| 4 | `getAutoConfigurationSettings` | — | ❌ | Linksys-proprietary |
| 5 | `setupSetAdminPassword` | `Device.Users.User.{i}.Password` | 🟡 | SET available on Users |
| 6 | `verifyRouterResetCode` | — | ❌ | Linksys-proprietary |
| 7 | `getInternetConnectionStatus` | `Device.IP.Interface.{i}.Status` | ✅ | IP.Interface Status available |
| 8 | `getMACAddress` | `Device.Ethernet.Interface.{i}.MACAddress` | ✅ | Via Ethernet Interface |
| 9 | `startBlinkNodeLed` | — | ❌ | No vendor extension |
| 10 | `stopBlinkNodeLed` | — | ❌ | Same |
| 11 | `setUserAcknowledgedAutoConfiguration` | — | ❌ | Linksys-proprietary |
| 12 | `getSelectedChannels` | `Device.WiFi.Radio.{i}.Channel` | ✅ | Channel per radio verified |
| 13 | `startAutoChannelSelection` | `Device.WiFi.Radio.{i}.AutoChannelEnable` | 🟡 | AutoChannelEnable available; explicit "start scan" may differ |

<details>
<summary>📋 GetSimpleWiFiSettings / SetSimpleWiFiSettings — Field Mapping ⚠️</summary>

> Note: This action is not in `jnap_full.md`. Field names inferred from Dart model + radio settings pattern.

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `radios[].radioID` | string | `Device.WiFi.Radio.{i}.Name` | — |
| `radios[].isEnabled` | bool | `Device.WiFi.Radio.{i}.Enable` | — |
| `radios[].mode` | WirelessMode | `Device.WiFi.Radio.{i}.OperatingStandards` | Transform needed |
| `radios[].ssid` | string | `Device.WiFi.SSID.{i}.SSID` | ✅ BUG-001 fixed |
| `radios[].broadcastSSID` | bool | `Device.WiFi.AccessPoint.{i}.SSIDAdvertisementEnabled` | — |
| `radios[].channelWidth` | WirelessChannelWidth | `Device.WiFi.Radio.{i}.OperatingChannelBandwidth` | — |
| `radios[].channel` | int | `Device.WiFi.Radio.{i}.Channel` | — |
| `radios[].security` | WirelessSecurity | `Device.WiFi.AccessPoint.{i}.Security.ModeEnabled` | — |
| `radios[].wpaPersonalSettings.passphrase` | string | `Device.WiFi.AccessPoint.{i}.Security.KeyPassphrase` | — |

</details>

<details>
<summary>📋 GetInternetConnectionStatus — Field Mapping</summary>

> Note: Not in `jnap_full.md`. Field names inferred from Dart model.

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `connectionStatus` | string | `Device.IP.Interface.{wan}.Status` | Enum mapping needed |

</details>

<details>
<summary>📋 GetMACAddress — Field Mapping</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `macAddress` | MACAddress | `Device.Ethernet.Interface.{i}.MACAddress` | Via Ethernet interface |

</details>

<details>
<summary>📋 GetSelectedChannels / StartAutoChannelSelection — Field Mapping</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `channels` (GetSelectedChannels) | int[] or ChannelInfo[] | `Device.WiFi.Radio.{i}.Channel` | One per radio |
| `isAutoChannelEnabled` (StartAutoChannelSelection input) | bool | `Device.WiFi.Radio.{i}.AutoChannelEnable` | 🟡 SET toggles auto mode; JNAP "starts scan" explicitly |

</details>

**Score: 3 ✅ / 2 🟡 / 6 ❌ / 2 ⚠️**

---

### 24. Smart Mode (2 actions)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getDeviceMode` | — | ❌ | No `X_LINKSYS_COM_SmartMode` — not registered |
| 2 | `setDeviceMode` | — | ❌ | Same |

**Score: 0 ✅ / 0 🟡 / 2 ❌**

---

### 25. VPN (10 actions)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getVPNService` | `Device.IPsec.` / `Device.X_LINKSYS_OpenVPN.` | ❌ | IPsec: fault 9005; OpenVPN registered (USP-only) but fault 9005 |
| 2 | `setVPNService` | — | ❌ | Same |
| 3 | `getVPNGateway` | — | ❌ | No IPsec tunnel data |
| 4 | `setVPNGateway` | — | ❌ | Same |
| 5 | `getVPNUser` | — | ❌ | No VPN user model |
| 6 | `setVPNUser` | — | ❌ | Same |
| 7 | `getTunneledUser` | — | ❌ | Same |
| 8 | `setTunneledUser` | — | ❌ | Same |
| 9 | `testVPNConnection` | — | ❌ | No equivalent |
| 10 | `setVPNApply` | — | ❌ | Same |

**Score: 0 ✅ / 0 🟡 / 10 ❌**

> **Note:** `Device.X_LINKSYS_OpenVPN` is registered in `bbfdm.core` services as USP-only, but currently returns fault 9005. This may indicate future OpenVPN support planned.

---

### 26. Wireless AP (3 actions)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getRadioInfo` | `Device.WiFi.Radio.{i}.` | ✅ | 2 radios, complete params + stats |
| 2 | `setRadioSettings` | Same | ✅ | SET available |
| 3 | `clientDeauth` | — | ❌ | No OPERATE command for client deauth |

<details>
<summary>📋 GetRadioInfo / SetRadioSettings — Field Mapping</summary>

**GetRadioInfo output** — `radios: RadioInfo[]`, one per physical radio:

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `radioID` | string | `Device.WiFi.Radio.{i}.Name` | Radio identifier |
| `physicalRadioID` | string | — | JNAP-internal physical ID |
| `bssid` | MACAddress | `Device.WiFi.AccessPoint.{i}.MACAddress` | BSSID → AP MAC |
| `band` | WirelessBand | `Device.WiFi.Radio.{i}.OperatingFrequencyBand` | Enum: 2.4GHz, 5GHz, 6GHz |
| `supportedModes` | WirelessMode[] | `Device.WiFi.Radio.{i}.SupportedStandards` | Enum mapping needed |
| `supportedChannels` | int[] | `Device.WiFi.Radio.{i}.PossibleChannels` | 20MHz channels |
| `supportedWideChannels` | int[] | `Device.WiFi.Radio.{i}.PossibleChannels` | 40MHz channels (subset) |
| `supportedSecurityTypes` | WirelessSecurity[] | `Device.WiFi.AccessPoint.{i}.Security.ModesSupported` | — |
| `maxRADIUSSharedKeyLength` | int | — | Capability info |
| `settings` | RadioSettings | See sub-table below | Current config |

**RadioSettings sub-fields:**

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `settings.isEnabled` | bool | `Device.WiFi.Radio.{i}.Enable` | — |
| `settings.mode` | WirelessMode | `Device.WiFi.Radio.{i}.OperatingStandards` | Transform: "802.11ax" → "bgnax" |
| `settings.ssid` | string | `Device.WiFi.SSID.{i}.SSID` | ✅ BUG-001 fixed |
| `settings.broadcastSSID` | bool | `Device.WiFi.AccessPoint.{i}.SSIDAdvertisementEnabled` | — |
| `settings.channelWidth` | WirelessChannelWidth | `Device.WiFi.Radio.{i}.OperatingChannelBandwidth` | Enum: Auto, 20MHz, 40MHz, 80MHz, 160MHz |
| `settings.channel` | int | `Device.WiFi.Radio.{i}.Channel` | 0 = auto |
| `settings.security` | WirelessSecurity | `Device.WiFi.AccessPoint.{i}.Security.ModeEnabled` | Enum mapping needed |
| `settings.wpaPersonalSettings.passphrase` | string | `Device.WiFi.AccessPoint.{i}.Security.KeyPassphrase` | — |

</details>

**Score: 2 ✅ / 0 🟡 / 1 ❌**

---

### 27. IPTV (2 actions)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getIptvSettings` | — | ❌ | No IPTV model registered |
| 2 | `setIptvSettings` | — | ❌ | Same |

**Score: 0 ✅ / 0 🟡 / 2 ❌**

---

### 28. MLO (2 actions)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getMLOSettings` | `Device.WiFi.Radio.{i}.Capabilities.WiFi7APRole.` | ❌ | No WiFi 7 capabilities on this hardware (2 radios, WiFi 6) |
| 2 | `setMLOSettings` | — | ❌ | Same |

**Score: 0 ✅ / 0 🟡 / 2 ❌** (hardware limitation, not firmware bug)

---

### 29. DFS (2 actions)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getDFSSettings` | `Device.WiFi.Radio.{i}.RegulatoryDomain` | 🟡 | RegulatoryDomain="EU"; DFS-specific toggle needs vendor ext |
| 2 | `setDFSSettings` | — | ❌ | Requires vendor extension |

<details>
<summary>📋 GetDFSSettings — Field Mapping (2 fields)</summary>

| JNAP Field | Type | TR-181 Path | Notes |
|------------|------|-------------|-------|
| `isDFSSupported` | bool | — | Capability info; inferred from radio band |
| `isDFSEnabled` | bool (opt) | `Device.WiFi.Radio.{i}.RegulatoryDomain` | 🟡 RegulatoryDomain="EU" implies DFS; no explicit toggle in TR-181 |

</details>

**Score: 0 ✅ / 1 🟡 / 1 ❌**

---

### 30. Airtime Fairness (2 actions)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `getAirtimeFairnessSettings` | — | ❌ | No `X_LINKSYS_COM_AirtimeFairness` |
| 2 | `setAirtimeFairnessSettings` | — | ❌ | Same |

**Score: 0 ✅ / 0 🟡 / 2 ❌**

---

### 31. UI Settings (1 action)

| # | JNAP Action | TR-181 Path | Status | Notes |
|---|-------------|-------------|--------|-------|
| 1 | `setRemoteSetting` | `Device.UserInterface.RemoteAccess.` | 🟡 | UserInterface available; RemoteAccess limited |

<details>
<summary>📋 SetRemoteSetting — Field Mapping (1 field)</summary>

| JNAP Field (input) | Type | TR-181 Path | Notes |
|---------------------|------|-------------|-------|
| `isEnabled` | bool | `Device.UserInterface.RemoteAccess.Enable` | 🟡 JNAP controls UI cloud proxy; TR-181 controls remote management access |

> Semantic difference: JNAP `SetRemoteSetting.isEnabled` toggles cloud UI proxy. TR-181 `RemoteAccess.Enable` toggles WAN-side management. Not a 1:1 mapping.

</details>

**Score: 0 ✅ / 1 🟡 / 0 ❌**

---

## Consolidated Score Summary

| Category | Actions | ✅ Full | 🟡 Partial | ⚠️ Bug | ❌ None |
|----------|---------|--------|-----------|---------|--------|
| 1. Core | 13 | 6 | 4 | — | 3 |
| 2. Auto Onboarding | 6 | — | — | — | 6 |
| 3. DDNS | 4 | — | — | — | 4 |
| 4. Device List | 4 | 1 | 2 | — | 1 |
| 5. Diagnostics | 7 | 5 | — | — | 2 |
| 6. Firewall | 14 | 8 | 4 | — | 2 |
| 7. Firmware Update | 6 | — | 1 | — | 5 |
| 8. Guest Network | 5 | 1 | 2 | 2 | — |
| 9. Health Check | 6 | — | — | — | 6 |
| 10. Locale/Time | 3 | 3 | — | — | — |
| 11. MAC Filter | 3 | — | — | — | 3 |
| 12. Network Connections | 1 | 1 | — | — | — |
| 13. Nodes Diagnostics | 1 | — | 1 | — | — |
| 14. Nodes Network Connections | 1 | — | 1 | — | — |
| 15. Nodes Topology | 2 | — | — | — | 2 |
| 16. Power Table | 2 | — | — | — | 2 |
| 17. Product | 1 | — | — | — | 1 |
| 18. QoS | 1 | — | — | — | 1 |
| 19. Router | 17 | 12 | 2 | — | 3 |
| 20. Router Management | 2 | — | 2 | — | — |
| 21. Router UPnP | 2 | — | — | — | 2 |
| 22. Router LEDs | 2 | — | — | — | 2 |
| 23. Setup | 13 | 3 | 2 | 2 | 6 |
| 24. Smart Mode | 2 | — | — | — | 2 |
| 25. VPN | 10 | — | — | — | 10 |
| 26. Wireless AP | 3 | 2 | — | — | 1 |
| 27. IPTV | 2 | — | — | — | 2 |
| 28. MLO | 2 | — | — | — | 2 |
| 29. DFS | 2 | — | 1 | — | 1 |
| 30. Airtime Fairness | 2 | — | — | — | 2 |
| 31. UI Settings | 1 | — | 1 | — | — |
| **TOTAL** | **140** | **42 (30%)** | **23 (16%)** | **4 (3%)** | **71 (51%)** |

---

## Category Analysis: Why 51% is Not Replaceable

### Breakdown of the 71 "Not Replaceable" Actions

| Root Cause | Count | Actions |
|------------|-------|---------|
| **Linksys-proprietary features** (no TR-181 equivalent) | 36 | Auto Onboarding (6), Health Check (6), LED (2), Smart Mode (2), Power Table (2), Product (1), Setup misc (6), VPN user/tunneled (4), IPTV (2), MLO (2), AirtimeFairness (2), clientDeauth (1) |
| **Missing bbfdm module** (fault 9005) | 21 | DDNS (4), VPN core (6), UPnP (2), QoS (1), MAC Filter (3), Firmware Update (4), Express Forwarding (1) |
| **TR-181 spec limitation** | 6 | stopPing, stopTraceroute (no cancel), deleteDevice (no Host delete), ALG (2), MAC clone set (1) |
| **Password/auth model difference** | 4 | PasswordHint, AuthStatus, IsDefault, MAC clone set |
| **Hardware limitation** | 4 | MLO/WiFi7 (router is WiFi 6) |

### Key Insight

The 51% gap is primarily from:
1. **Linksys-proprietary features** that have no standard TR-181 equivalent (26%)
2. **Missing firmware modules** that could potentially be added (15%)
3. **Protocol/spec differences** that are inherent to TR-181 (10%)

The **core networking features** (categories used most frequently in the daily UI) have much higher coverage:
- Router/WAN/LAN: **12/17 = 71%** ✅
- Firewall/NAT: **8/14 = 57%** ✅
- Device Info: **6/13 = 46%** ✅
- WiFi Radio: **2/3 = 67%** ✅
- Device List: **1/4 = 25%** ✅
- Diagnostics: **5/7 = 71%** ✅
- Time: **3/3 = 100%** ✅

---

## Detailed Data Samples

### DeviceInfo

| Parameter | Value |
|-----------|-------|
| Manufacturer | Linksys |
| ModelName | M60TB-EU |
| SerialNumber | 67A10M24F00066 |
| HardwareVersion | V1.0 |
| SoftwareVersion | 1.0.14.26013014 |
| Description | Linksys PINNACLE 2.0 |
| ProductClass | M60TB |
| UpTime | 6871 (seconds) |

Sub-objects: MemoryStatus, ProcessStatus (50+ processes), TemperatureStatus, FirmwareImage, NetworkProperties, SupportedDataModel (TR-181 v2.18.1).

### WiFi Radio

| Parameter | Radio.1 (2.4GHz) | Radio.2 (5GHz) |
|-----------|-------------------|-----------------|
| Enable | 1 | 1 |
| Status | Up | Up |
| Channel | 13 | 36 |
| OperatingFrequencyBand | 2.4GHz | 5GHz |
| OperatingChannelBandwidth | Auto (20MHz actual) | Auto (160MHz actual) |
| SupportedStandards | bg, bgn, bgnax, mixed | a, an, anac, anacax, mixed |
| TransmitPower | -1 (max) | -1 (max) |
| MaxBitRate | 574 Mbps | 2402 Mbps |
| RegulatoryDomain | EU | EU |
| Stats (Bytes/Packets) | All fields | All fields |

### WiFi AP.1 Security

| Parameter | Value |
|-----------|-------|
| ModesSupported | None, WPA2-Personal, WPA3-Personal, WPA3-Personal-Transition, Enhanced-Open |
| ModeEnabled | WPA2-Personal |
| EncryptionMode | AES |
| KeyPassphrase | (available, flagged Secure) |
| SAEPassphrase | (available, flagged Secure) |
| MFPConfig | Disabled |
| RekeyingInterval | 3600 |

### Connected Hosts

| Parameter | Host.1 |
|-----------|--------|
| PhysAddress | ba:16:44:9f:eb:8b |
| IPAddress | 192.168.1.191 |
| HostName | MAC |
| Active | 1 |
| InterfaceType | Wi-Fi |
| Layer1Interface | Device.WiFi.Radio.2 |
| AssociatedDevice | Device.WiFi.AccessPoint.2.AssociatedDevice.1 |
| DHCPClient | Device.DHCPv4.Server.Pool.1.Client.1 |
| DeviceID | CEC33C82-3CBE-4A8D-9DCE-B7952FE222CC |
| ParentNodeID | 3E68DD2F-CF4F-4E47-A99B-741213215502 |

### DHCPv4 Pool

| Parameter | Value |
|-----------|-------|
| Enable | 1 |
| MinAddress | 192.168.1.100 |
| MaxAddress | 192.168.1.249 |
| SubnetMask | 255.255.255.0 |
| DNSServers | 192.168.1.1 |
| LeaseTime | 43200 (12h) |

### Time

| Parameter | Value |
|-----------|-------|
| Enable | 1 |
| Status | Synchronized |
| CurrentLocalTime | 2026-03-02T03:34:02+00:00 |
| LocalTimeZone | GMT0BST,M3.5.0/01:00,M10.5.0/02:00 |
| NTPServer1 | 0.pool.ntp.org |

### Users

| User | Username | UserID | Enable |
|------|----------|--------|--------|
| User.1 | admin | 1000 | true |
| User.2 | user | 0 | true |

Roles: `full_access`, `extender`, `Untrusted`

### WPS

| Parameter | Value |
|-----------|-------|
| Enable | true |
| Status | Configured |
| ConfigMethodsSupported | PushButton |
| ConfigMethodsEnabled | PushButton |

---

## Firmware Bugs

### BUG-001: WiFi SSID Instance Enumeration Failure — ~~CRITICAL~~ FIXED (2026-03-04)

- **Symptom:** `Device.WiFi.SSIDNumberOfEntries = 0`; `instances Device.WiFi.SSID.` returns empty
- **Expected:** At least 4 SSID instances (matching 4 AccessPoints)
- **Resolution:** Firmware update resolved the issue. SSID instances now enumerate correctly.
- **Previous Evidence (archived):**
  - Schema registered (5 params: Alias, Enable, Status, LastChange, ...)
  - Underlying wifi daemon has SSID: `wifi.ap.ath0` → `SSID = "toob-215502"`
  - `AccessPoint.{i}.SSIDReference` = empty for all 4 APs
- **Previously affected:** 4 JNAP actions (getSimpleWiFiSettings, setSimpleWiFiSettings, getGuestRadioSettings, setGuestRadioSettings)

### BUG-002: Firewall Top-Level GET Returns Empty — LOW

- **Symptom:** `ubus call bbfdm.firewallmngr get '{"path":"Device.Firewall."}'` → `{"results":[]}`
- **But:** `Device.Firewall.Enable` returns "1"; `Device.Firewall.Level.` returns 8 entries
- **Workaround:** Query sub-objects individually

---

## bbfdm Services Registry (Complete)

From `ubus call bbfdm services '{}'`:

| Daemon | Registered Objects | Proto |
|--------|--------------------|-------|
| `bbfdm.core` | LANConfigSecurity, Schedules, Security, PacketCaptureDiag, SelfTestDiag, Syslog, **X_LINKSYS_OpenVPN** (USP only), RootDataModelVersion, **Reboot()**, **FactoryReset()** | both/usp |
| `bbfdm.sysmngr` | DeviceInfo | both |
| `bbfdm.wifidmd` | WiFi | both |
| `bbfdm.netmngr` | IP, GRE, PPP, Routing, RouterAdvertisement, IPv6rd, InterfaceStack | both |
| `bbfdm.dhcpmngr` | DHCPv4, DHCPv6 | both |
| `bbfdm.dnsmngr` | DNS | both |
| `bbfdm.firewallmngr` | Firewall, NAT | both |
| `bbfdm.hostmngr` | Hosts | both |
| `bbfdm.ethmngr` | Ethernet | both |
| `bbfdm.bridgemngr` | Bridging | both |
| `bbfdm.timemngr` | Time | both |
| `bbfdm.usermngr` | Users | both |
| `bbfdm.custommngr` | X_CISCO_COM_Custom (ClearArpTable) | both |
| `bbfdm.gateway-info` | GatewayInfo | both |
| `bbfdm.lifemotemngr` | X_LIFEMOTE_EXT (LifemoteAgent) | both |
| `bbfdm.trustdomainmngr` | X_LINKSYS_TRUSTDOMAIN (5 IPv4 trusted IPs) | both |
| `bbfdm.icwmp` | ManagementServer, CWMPManagementServer, XMPP | both |
| `bbfdm.obuspa` | USPAgent, MQTT, STOMP | cwmp |
| `bbfdm.bulkdata` | BulkData | cwmp |

**Not registered by any daemon:** QoS, DynamicDNS, UPnP, SoftwareModules, IPsec, X_LINKSYS_COM (generic)

**Interesting:** `Device.X_LINKSYS_OpenVPN` is registered as USP-only in `bbfdm.core` but currently returns fault 9005 — future VPN support may be planned.

---

## Transform Layer Notes

| JNAP Concept | TR-181 Value | Transform Required | Found In |
|-------------|-------------|-------------------|----------|
| WiFi `mode: "802.11ax"` | `OperatingStandards: "bgnax"` | Format mapping | RadioInfo, SimpleWiFiSettings |
| WAN `status: "Connected"` | `IP.Interface.Status: "Up"` | Enum mapping | GetWANStatus |
| Firewall `isEnabled` (bool) | `Firewall.Enable: "1"` | String → bool | GetFirewallSettings |
| DHCP `leaseTime` (minutes) | `LeaseTime: 43200` | Seconds → minutes (×60) | GetLANSettings |
| Radio `transmitPower` (%) | `TransmitPower: -1` | -1 = max; need value mapping | RadioInfo |
| Time zone | `LocalTimeZone: "GMT0BST,..."` | POSIX TZ string ↔ timezone ID | GetTimeSettings |
| Security mode | `ModeEnabled: "WPA2-Personal"` | Different enum names from JNAP | RadioInfo, SimpleWiFiSettings |
| Host Active | `Active: "1"` (string) | String → bool | GetDevices (Hosts) |
| Network prefix length ↔ subnet mask | `SubnetMask: "255.255.255.0"` | Prefix length int ↔ dotted mask | GetLANSettings, GetRoutingSettings |
| DNS servers (separate fields) | `DNSServers: "1.1.1.1,8.8.8.8"` | Multiple fields → comma-separated | GetLANSettings, GetWANStatus |
| EthernetPortConnection enum | `Status + CurrentBitRate` (separate) | Enum → 2 separate fields | GetEthernetPortConnections |
| Diagnostics result (text log) | Structured fields (SuccessCount, AvgTime) | Text parsing vs structured | GetPingStatus, GetTracerouteStatus |
| IPProtocol enum (TCP/UDP/Both) | `Protocol: "TCP"/"UDP"/"TCP/UDP"` | Enum string mapping | PortForwarding rules |
| DST handling | Embedded in POSIX TZ string | Boolean → TZ string component | GetTimeSettings |
| Remote management granularity | Single `RemoteAccess.Enable` | 4 JNAP bools → 1 TR-181 toggle | GetManagementSettings |

---

## Recommendations

### Phase 2 Priority: Start with High-Coverage Modules

**Tier 1 — Ready now (42 actions, 30%):**
- DeviceInfo, Radio, WAN/LAN/DHCP, Routing, Ethernet, Time, Diagnostics, Firewall rules, Connected Devices

**Tier 2 — After SSID bug fix (4 actions, 3%):**
- SimpleWiFiSettings (SSID + Security composite)
- GuestRadio/GuestNetwork settings

**Tier 3 — Needs firmware modules (21 actions, 15%):**
- DDNS, VPN, UPnP, QoS, MAC Filter, Firmware Update
- Requires coordination with firmware team

**Tier 4 — Linksys-proprietary, needs vendor extension (36 actions, 26%):**
- Auto Onboarding, Health Check, LED, Smart Mode, Power Table, Product, IPTV, MLO, DFS, AirtimeFairness
- These need `X_LINKSYS_COM_*` vendor extensions in bbfdm

**Tier 5 — Inherent TR-181 limitations (8 actions, 6%):**
- stop commands (Ping/Traceroute), deleteDevice, clientDeauth
- May need workarounds or USP extensions

### Codegen YAML Definitions to Create

| Priority | YAML File | TR-181 Paths | JNAP Actions Covered |
|----------|-----------|-------------|---------------------|
| P0 | `system_info.yaml` | DeviceInfo.* | getDeviceInfo, getHardwareInfo (already exists) |
| P0 | `wifi_radio.yaml` | WiFi.Radio.{i}.* | getRadioInfo, setRadioSettings |
| P0 | `wan_settings.yaml` | IP.Interface + PPP | getWANSettings, setWANSettings, getWANStatus |
| P0 | `lan_settings.yaml` | DHCPv4.Server.Pool + IP.Interface.1 | getLANSettings, setLANSettings |
| P0 | `connected_devices.yaml` | Hosts.Host.{i}.* | getDevices (already exists) |
| P1 | `firewall_rules.yaml` | NAT.PortMapping + PortTrigger | get/setPortForwarding, get/setPortTriggering |
| P1 | `ipv6_settings.yaml` | IP.Interface.IPv6 + DHCPv6 | getIPv6Settings, setIPv6Settings |
| P1 | `routing.yaml` | Routing.Router.IPv4Forwarding | getRoutingSettings, setRoutingSettings |
| P1 | `diagnostics.yaml` | IP.Diagnostics.IPPing() / TraceRoute() | startPing, startTraceroute |
| P1 | `time_settings.yaml` | Time.* | getTimeSettings, setTimeSettings, getLocalTime |
| P2 | `wifi_security.yaml` | WiFi.AP.{i}.Security.* | (partial getSimpleWiFiSettings) |
| P2 | `ethernet.yaml` | Ethernet.Interface.{i}.* | getEthernetPortConnections |

---

## Appendix: Data Volume by Category

| Category | Total Data Size | Richness |
|----------|----------------|----------|
| Core/DeviceInfo | 25,935B | Very rich (50+ processes, temp, memory) |
| WiFi Radio | 10,815B | Complete (2 radios, full stats) |
| WiFi AccessPoint | 23,639B | Complete (4 APs, security, AC) |
| Network/IP | 12,441B | Full (multi-interface, stats) |
| PPP | 4,691B | PPPoE data |
| Routing | 19,774B | Full routing table |
| DHCP (all) | 18,598B | Complete (v4+v6, server+client) |
| DNS | 1,813B | Adequate |
| Firewall Chain | 106,666B | Very detailed (all rules) |
| NAT | 1,871B | Interface settings |
| Hosts | 4,961B | Rich device info |
| Ethernet | 12,338B | Complete |
| Bridging | 25,397B | Detailed bridge config |
| Time | 1,056B | Complete |
| Diagnostics | 6,250B | Full diagnostic suite |
| Users | 2,383B | Admin + user accounts |
| **Total** | **~278KB** | |
