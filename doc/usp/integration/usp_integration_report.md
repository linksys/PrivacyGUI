# USP Integration Report

> Date: 2026-03-10 (updated) | Branch: `feat/usp-protocol-integration`
> Covers: Phase 1 (Infrastructure) + Phase 2A (Read) + Phase 2B (Write) + Phase 2C (Subscribe Infrastructure) + Phase 4A (Standalone Feature Pages) + 401 Auth Retry

---

## 1. Executive Summary

PrivacyGUI has been extended with a parallel USP (User Services Platform / TR-369) protocol stack running alongside the existing JNAP protocol. The integration provides a fully independent **USP Dashboard** that does not depend on JNAP polling, featuring 14 data cards with full CRUD capabilities for key networking features.

### Key Metrics

| Metric | Value |
|--------|-------|
| YAML definitions | 22 (was 20) |
| Generated `.g.dart` files | 23 (22 data + transforms) |
| UI model classes | 21 (across 21 files) |
| Dashboard cards | 14 |
| Dashboard dialogs | 7 |
| Standalone feature pages | 12 (Admin, DHCP Detail, Port Forwarding Detail, Devices, Topology, System Log, Firewall, DMZ, Instant Safety, Local Network, Static Routing, IPv6 Port Service) |
| Standalone dialogs | 6 (password, timezone, confirm action, DHCP edit, static route, IPv6 port rule) |
| Mutation methods | 34+ |
| TR-181 data models covered | 22 |
| Parallel fetch tasks | 15 |
| Supported CRUD operations | fetch, update, add, delete, subscribe (stub), operate |
| Infrastructure | 401 Auth Retry (two-stage reauth with Completer lock) |

### Architecture at a Glance

```
┌─────────────────────────────────────────────────────────────────┐
│                        USP Dashboard View                       │
│   14 cards + 7 dialogs + skeleton loading + responsive layout    │
├─────────────────────────────────────────────────────────────────┤
│                     UI Models (Presentation)                     │
│   21 Equatable classes with computed display properties          │
├─────────────────────────────────────────────────────────────────┤
│              UspDeviceService + Feature Services (Transform)     │
│   13 dashboard builders + 5 standalone feature services          │
├─────────────────────────────────────────────────────────────────┤
│          UspDashboardNotifier + Feature Notifiers (Orchestration)│
│   build() parallel fetch + 34 mutation methods + _withLock      │
├─────────────────────────────────────────────────────────────────┤
│                   UspDashboardState (Equatable)                  │
│   Raw codegen DTOs + UI model fields + copyWith                 │
├─────────────────────────────────────────────────────────────────┤
│                Codegen .g.dart (Data Transfer Objects)           │
│   22 files: fetch/update/add/delete/subscribe                   │
├─────────────────────────────────────────────────────────────────┤
│                      UspService (Transport)                      │
│   WASM JS interop + _coerceValue + CRUD + Operate + Subscribe   │
│   + 401 Auth Retry (_withAuthRetry + two-stage reauth)          │
├─────────────────────────────────────────────────────────────────┤
│                    WASM Client (Rust → JS)                       │
│   HTTP transport to router's usp-bridge API                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Codegen Pipeline

### 2.1 Pipeline Overview

```
YAML Definition          Codegen Binary          Generated Dart
(doc/usp/definitions/)  →  (tools/usp-codegen)  →  (lib/generated/*.g.dart)
                                                          │
                                                    UspDeviceService
                                                    (transform layer)
                                                          │
                                                     UI Models
                                                (lib/usp_page/**/models/)
```

### 2.2 Codegen CLI

```bash
./tools/usp-codegen \
  --definitions-dir doc/usp/definitions/ \
  --output-dir lib/generated/ \
  --language dart \
  --client-import 'package:privacy_gui/usp/services/usp_service.dart'
```

### 2.3 Supported Codegen Patterns

| Pattern | Description | Example |
|---------|-------------|---------|
| **Single-instance** | One object with fixed paths | `SystemInfo`, `TimeSettings` |
| **Single-instance scatter-gather** | Absolute paths across different subtrees | `LanNetworkInfo`, `WanStatus` |
| **Multi-instance** | `{i}` enumerated objects | `EthernetInterfaces`, `WiFiRadios` |
| **Multi-instance + writable** | Read + update/updateMany | `WiFiRadios`, `AdminUsers` |
| **Multi-instance + add/delete** | Full CRUD lifecycle | `DhcpReservations`, `PortForwarding` |
| **Multi-instance + nested children** | Parent-child object hierarchy | `PortTriggering` (2 levels) |
| **Multi-instance + deep nesting** | 3+ level hierarchy | `DataElementsNetwork` (4 levels) |
| **Flattened nested** | Nested instances presented flat | `WifiClients` (AP → AssociatedDevice) |
| **Subscribe** | Polling-based subscription stub | `ConnectedDevices` |

### 2.4 Generated API Surface per Pattern

```dart
// Single-instance (read-only)
class SystemInfo {
  static Future<SystemInfo> fetch(UspService client);
}

// Single-instance (writable)
class TimeSettings {
  static Future<TimeSettings> fetch(UspService client);
  static Future<void> save(UspService client, {bool? enable, ...});
}

// Multi-instance (read-only)
class EthernetInterfaces {
  final List<EthernetInterface> items;
  static Future<EthernetInterfaces> fetch(UspService client);
}

// Multi-instance (writable)
class WiFiRadios {
  static Future<WiFiRadios> fetch(UspService client);
  static Future<void> update(UspService client, WiFiRadioUpdate update);
  static Future<void> updateMany(UspService client, List<WiFiRadioUpdate> updates);
}

// Multi-instance (full CRUD)
class PortForwarding {
  static Future<PortForwarding> fetch(UspService client);
  static Future<void> update(UspService client, PortForwardingRuleUpdate update);
  static Future<String> add(UspService client, PortForwardingRuleUpdate data);
  static Future<void> delete(UspService client, String instancePath);
}

// Multi-instance + nested children
class PortTriggering {
  static Future<PortTriggering> fetch(UspService client);
  static Future<void> update(...);
  static Future<String> add(...);
  static Future<void> delete(...);
  static Future<String> addPortTriggerForwardRule(UspService client, String parentPath, ...);
  static Future<void> deletePortTriggerForwardRule(UspService client, String instancePath);
}

// Subscribe (polling stub)
class ConnectedDevices {
  static Future<ConnectedDevices> fetch(UspService client);
  static Future<Subscription<ConnectedDevices>> subscribe(UspService client);
}
```

---

## 3. YAML Definitions Inventory

### 3.1 Complete Definition List

| # | Category | YAML File | Name | TR-181 Base Path | Instance Type | Operations |
|---|----------|-----------|------|------------------|---------------|------------|
| 1 | core | `core/system_info.yaml` | SystemInfo | `Device.DeviceInfo` | Single | fetch |
| 2 | core | `core/time_settings.yaml` | TimeSettings | `Device.Time` | Single | fetch, save |
| 3 | devices | `devices/connected_devices.yaml` | ConnectedDevices | `Device.Hosts.Host` | Multi | fetch, subscribe |
| 4 | devices | `devices/wifi_clients.yaml` | WifiClients | `Device.WiFi.AccessPoint.{i}.AssociatedDevice` | Multi (flatten) | fetch |
| 5 | wifi | `wifi/wi_fi_radios.yaml` | WiFiRadios | `Device.WiFi.Radio` | Multi | fetch, update |
| 6 | wifi | `wifi/wi_fi_access_points.yaml` | WiFiAccessPoints | `Device.WiFi.AccessPoint` | Multi | fetch |
| 7 | wifi | `wifi/wi_fi_ssids.yaml` | WiFiSsids | `Device.WiFi.SSID` | Multi | fetch |
| 8 | wifi | `wifi/data_elements_network.yaml` | DataElementsNetwork | `Device.WiFi.DataElements.Network.Device` | Multi (deep nest) | fetch |
| 9 | network | `network/lan_network_info.yaml` | LanNetworkInfo | (scatter-gather) | Single | fetch, save |
| 10 | network | `network/wan_status.yaml` | WanStatus | (scatter-gather) | Single | fetch |
| 11 | network | `network/ethernet_interfaces.yaml` | EthernetInterfaces | `Device.Ethernet.Interface` | Multi | fetch |
| 12 | network | `network/dhcp_reservations.yaml` | DhcpReservations | `Device.DHCPv4.Server.Pool.1.StaticAddress` | Multi | fetch, update, add, delete |
| 13 | network | `network/dhcp_clients.yaml` | DhcpClients | `Device.DHCPv4.Server.Pool.1.Client` | Multi | fetch |
| 14 | admin | `admin/admin_users.yaml` | AdminUsers | `Device.Users.User` | Multi | fetch, update |
| 15 | firewall | `firewall/port_forwarding.yaml` | PortForwarding | `Device.NAT.PortMapping` | Multi | fetch, update, add, delete |
| 16 | firewall | `firewall/port_triggering.yaml` | PortTriggering | `Device.NAT.PortTrigger` | Multi + children | fetch, update, add, delete, child add/delete |
| 17 | firewall | `firewall/firewall_chain_rules.yaml` | FirewallChainRules | `Device.Firewall.Chain.{i}.Rule` | Multi (nested) | fetch |
| 18 | firewall | `firewall/dmz.yaml` | Dmz | `Device.Firewall.DMZ` | Multi | fetch, update, add, delete |
| 19 | core | `core/vendor_log_files.yaml` | VendorLogFiles | `Device.DeviceInfo.VendorLogFile` | Multi | fetch |
| 20 | core | `core/firmware_images.yaml` | FirmwareImages | `Device.DeviceInfo.FirmwareImage` | Multi | fetch |
| 21 | network | `network/static_routing.yaml` | StaticRouting | `Device.Routing.Router.1.IPv4Forwarding` | Multi | fetch, update, add, delete |
| 22 | firewall | `firewall/ipv6_port_service.yaml` | Ipv6PortService | `Device.Firewall.Chain.1.Rule` | Multi | fetch, update, add, delete |

### 3.2 Scatter-Gather Definitions (No Base Path)

These definitions use absolute TR-181 paths across different subtrees:

**LanNetworkInfo:**
```
Device.IP.Interface.1.IPv4Address.1.IPAddress      → ipAddress
Device.IP.Interface.1.IPv4Address.1.SubnetMask      → subnetMask
Device.DHCPv4.Server.Pool.1.Enable                  → dhcpEnabled
Device.DHCPv4.Server.Pool.1.MinAddress              → minAddress
Device.DHCPv4.Server.Pool.1.MaxAddress              → maxAddress
Device.DHCPv4.Server.Pool.1.DNSServers              → dnsServers (writable)
```

**WanStatus:**
```
Device.IP.Interface.2.Status                        → status
Device.IP.Interface.2.IPv4Address.1.IPAddress       → ipAddress
Device.IP.Interface.2.IPv4Address.1.SubnetMask      → subnetMask
Device.IP.Interface.2.IPv4Address.1.AddressingType  → addressingType
Device.IP.Interface.2.MaxMTUSize                    → maxMtuSize
```

---

## 4. TR-181 → Codegen DTO → UI Model Mapping

### 4.1 SystemInfo / Device Info

| TR-181 Path | Codegen Field | UI Model Field | Display |
|-------------|---------------|----------------|---------|
| `Device.DeviceInfo.Manufacturer` | `manufacturer` | `manufacturer` | Device Info Card |
| `Device.DeviceInfo.ModelName` | `modelName` | `modelName` | Device Info Card |
| `Device.DeviceInfo.SerialNumber` | `serialNumber` | `serialNumber` | Device Info Card |
| `Device.DeviceInfo.HardwareVersion` | `hardwareVersion` | `hardwareVersion` | Device Info Card |
| `Device.DeviceInfo.SoftwareVersion` | `softwareVersion` | `softwareVersion` | Device Info Card |
| `Device.DeviceInfo.UpTime` | `uptime` (int) | `uptime` → `formattedUptime` | System Status Card |
| `Device.DeviceInfo.MemoryStatus.Total` | `totalMemory` (int) | `totalMemory` → `memoryPercent` | System Status Card |
| `Device.DeviceInfo.MemoryStatus.Free` | `freeMemory` (int) | `freeMemory` → `memoryUsedKb` | System Status Card |
| `Device.DeviceInfo.ProcessStatus.CPUUsage` | `cpuUsage` (int) | `cpuUsage` → `cpuPercent` | System Status Card |

**Codegen DTO:** `SystemInfo` (single-instance, 9 fields)
**UI Model:** `SystemInfoUIModel` (9 fields + 5 computed getters)
**Transform:** `UspDeviceService.buildSystemInfoUIModel()`

---

### 4.2 Connected Devices

| TR-181 Path | Codegen Field | UI Model Field | Notes |
|-------------|---------------|----------------|-------|
| `Device.Hosts.Host.{i}.PhysAddress` | `macAddress` | `mac` | Primary key |
| `Device.Hosts.Host.{i}.IPAddress` | `ipAddress` | `ip` | |
| `Device.Hosts.Host.{i}.HostName` | `hostName` | `hostName` | |
| `Device.Hosts.Host.{i}.Active` | `isActive` (bool) | `isActive` | Coerced from `"1"` |
| `Device.Hosts.Host.{i}.Layer1Interface` | `interface_` | `isWifi` (derived) | Parsed to detect WiFi vs Ethernet |
| `Device.Hosts.Host.{i}.AddressSource` | `addressSource` | — | Not mapped to UI |

**WiFi Enrichment (from WifiClients):**

| TR-181 Path | Codegen Field | UI Model Field |
|-------------|---------------|----------------|
| `Device.WiFi.AccessPoint.{i}.AssociatedDevice.{j}.MACAddress` | `macAddress` | (join key) |
| `...AssociatedDevice.{j}.SignalStrength` | `signalStrength` | `signalStrength` → `signalQuality` (0.0-1.0) |
| `...AssociatedDevice.{j}.LastDataDownlinkRate` | `lastDataDownlinkRate` | `downlinkRate` |
| `...AssociatedDevice.{j}.LastDataUplinkRate` | `lastDataUplinkRate` | `uplinkRate` |

**Mesh Enrichment (from DataElementsNetwork):**

| Source | UI Model Field |
|--------|----------------|
| AP index → Radio → MeshNode matching | `parentNodeId`, `parentNodeName` |
| AP → SSID cross-reference | `band`, `ssidName` |

**Codegen DTOs:** `ConnectedDevices` + `WifiClients` + `DataElementsNetwork`
**UI Model:** `DeviceUIModel` (14 fields + 5 computed getters)
**Transform:** `UspDeviceService.buildDeviceUIModels()` — cross-references 3 data sources

---

### 4.3 WiFi Radio / Access Point / SSID

#### WiFi Radio

| TR-181 Path | Codegen Field | UI Model Field | Writable |
|-------------|---------------|----------------|----------|
| `Device.WiFi.Radio.{i}.Enable` | `enable` | `enable` | Yes |
| `Device.WiFi.Radio.{i}.Status` | `status` | — | No |
| `Device.WiFi.Radio.{i}.Channel` | `channel` | `channel` → `channelDisplay` | Yes |
| `Device.WiFi.Radio.{i}.OperatingFrequencyBand` | `operatingFrequencyBand` | `band` ("2.4GHz"/"5GHz"/"6GHz") | No |
| `Device.WiFi.Radio.{i}.OperatingChannelBandwidth` | `operatingChannelBandwidth` | `channelBandwidth` | No |
| `Device.WiFi.Radio.{i}.SupportedStandards` | `supportedStandards` | `supportedStandards` | No |
| `Device.WiFi.Radio.{i}.TransmitPower` | `transmitPower` | `transmitPower` → `txPowerDisplay` | No |
| `Device.WiFi.Radio.{i}.MaxBitRate` | `maxBitRate` | `maxBitRate` → `bitRateNormalized` | No |
| `Device.WiFi.Radio.{i}.AutoChannelEnable` | `autoChannelEnable` | `autoChannelEnable` | Yes |

#### WiFi Access Point

| TR-181 Path | Codegen Field | UI Model Field |
|-------------|---------------|----------------|
| `Device.WiFi.AccessPoint.{i}.Enable` | `enable` | `enable` |
| `Device.WiFi.AccessPoint.{i}.Status` | `status` | — |
| `Device.WiFi.AccessPoint.{i}.Security.ModeEnabled` | `securityModeEnabled` | `securityMode` |
| `Device.WiFi.AccessPoint.{i}.Security.EncryptionMode` | `encryptionMode` | `encryptionMode` |
| `Device.WiFi.AccessPoint.{i}.SSIDReference` | `ssidReference` | (join key → ssidName) |

#### WiFi SSID

| TR-181 Path | Codegen Field | UI Model Field |
|-------------|---------------|----------------|
| `Device.WiFi.SSID.{i}.SSID` | `ssid` | (resolved via AP.SSIDReference) |
| `Device.WiFi.SSID.{i}.Enable` | `enable` | — |
| `Device.WiFi.SSID.{i}.Status` | `status` | — |
| `Device.WiFi.SSID.{i}.BSSID` | `bssid` | — |
| `Device.WiFi.SSID.{i}.LowerLayers` | `lowerLayers` | (join key → Radio) |

**Cross-Reference Logic:**
```
Radio.{i} ← SSID.{j}.LowerLayers ← AP.{k}.SSIDReference → SSID.{j}.SSID
```

`UspDeviceService.buildWifiRadioUIModels()` joins all three tables:
1. For each SSID, follow `LowerLayers` to find its parent Radio
2. For each AP, follow `SSIDReference` to find its SSID name
3. Group APs by their resolved Radio, attach as `accessPoints` list

**Codegen DTOs:** `WiFiRadios` + `WiFiAccessPoints` + `WiFiSsids`
**UI Models:** `WifiRadioUIModel` (11 fields + 4 getters) + `WifiAccessPointUIModel` (4 fields)
**Transform:** `UspDeviceService.buildWifiRadioUIModels()`

---

### 4.4 Ethernet Interfaces

| TR-181 Path | Codegen Field | UI Model Field | Notes |
|-------------|---------------|----------------|-------|
| `Device.Ethernet.Interface.{i}.Name` | `name` | `name` | e.g., "eth0", "eth1" |
| `Device.Ethernet.Interface.{i}.Status` | `status` | `isUp` (derived) | `status == 'Up'` |
| `Device.Ethernet.Interface.{i}.Upstream` | `upstream` (bool) | `isWan` | Coerced via `_coerceValue()` |
| `Device.Ethernet.Interface.{i}.CurrentBitRate` | `currentBitRate` (int) | `currentBitRate` → `speedLabel` | "1 Gbps", "2.5 Gbps" |

**Additional UI Model Fields (enriched):**

| UI Model Field | Source | Logic |
|----------------|--------|-------|
| `label` | Computed | WAN → "WAN", LAN → "LAN 1", "LAN 2"... |
| `connectedDevices` | `ConnectedDevices` cross-ref | Match `interface_` path to `instancePath` |
| `isUp` (LAN override) | Wired device presence | LAN port `isUp` = has connected wired device (not just link status) |

**Codegen DTO:** `EthernetInterfaces` (multi-instance, 4 fields)
**UI Model:** `EthernetPortUIModel` (7 fields + 1 getter) + `WiredDeviceInfo` (3 fields + 1 getter)
**Transform:** `UspDeviceService.buildEthernetPortUIModels()`

---

### 4.5 WAN Status

| TR-181 Path | Codegen Field | UI Model Field |
|-------------|---------------|----------------|
| `Device.IP.Interface.2.Status` | `status` | `isUp` (derived: `status == 'Up'`) |
| `Device.IP.Interface.2.IPv4Address.1.IPAddress` | `ipAddress` | `ipAddress` |
| `Device.IP.Interface.2.IPv4Address.1.SubnetMask` | `subnetMask` | `subnetMask` |
| `Device.IP.Interface.2.IPv4Address.1.AddressingType` | `addressingType` | `addressingType` |
| `Device.IP.Interface.2.MaxMTUSize` | `maxMtuSize` | `mtu` |

**Additional field not from codegen:**

| UI Model Field | Source | Logic |
|----------------|--------|-------|
| `gateway` | `_fetchDefaultGateway()` | Queries `Device.Routing.Router.1.IPv4Forwarding.{i}.*`, finds entry with `DestIPAddress == "0.0.0.0"` and `Interface` containing `Interface.2` → extracts `GatewayIPAddress` |

**Codegen DTO:** `WanStatus` (single-instance scatter-gather, 5 fields)
**UI Model:** `WanStatusUIModel` (6 fields)
**Transform:** `UspDeviceService.buildWanStatusUIModel()`

---

### 4.6 LAN Network Info

| TR-181 Path | Codegen Field | UI Model Field |
|-------------|---------------|----------------|
| `Device.IP.Interface.1.IPv4Address.1.IPAddress` | `ipAddress` | `ipAddress` |
| `Device.IP.Interface.1.IPv4Address.1.SubnetMask` | `subnetMask` | `subnetMask` |
| `Device.DHCPv4.Server.Pool.1.Enable` | `dhcpEnabled` | `dhcpEnabled` |
| `Device.DHCPv4.Server.Pool.1.MinAddress` | `minAddress` | `minAddress` |
| `Device.DHCPv4.Server.Pool.1.MaxAddress` | `maxAddress` | `maxAddress` |
| `Device.DHCPv4.Server.Pool.1.DNSServers` | `dnsServers` | `dnsServers` |

**Codegen DTO:** `LanNetworkInfo` (single-instance scatter-gather, 6 fields)
**UI Model:** `LanInfoUIModel` (6 fields + 1 getter: `dhcpRange`)
**Transform:** `UspDeviceService.buildLanInfoUIModel()`

---

### 4.7 Time Settings

| TR-181 Path | Codegen Field | UI Model Field | Writable |
|-------------|---------------|----------------|----------|
| `Device.Time.Enable` | `enable` | `enable` | Yes |
| `Device.Time.Status` | `status` | `status` → `isSynchronized` | No |
| `Device.Time.NTPServer1` | `ntpServer1` | `ntpServer1` | Yes |
| `Device.Time.NTPServer2` | `ntpServer2` | `ntpServer2` | Yes |
| `Device.Time.LocalTimeZone` | `localTimeZone` | `localTimeZone` | Yes |
| `Device.Time.CurrentLocalTime` | `currentLocalTime` | `currentLocalTime` → `formattedDateTime` | No |

**Codegen DTO:** `TimeSettings` (single-instance, 6 fields)
**UI Model:** `TimeSettingsUIModel` (6 fields + 2 getters)
**Transform:** `UspDeviceService.buildTimeSettingsUIModel()`

---

### 4.8 DHCP Reservations

| TR-181 Path | Codegen Field | UI Model Field | Writable |
|-------------|---------------|----------------|----------|
| `Device.DHCPv4.Server.Pool.1.StaticAddress.{i}.Enable` | `enable` | `enable` | Yes |
| `...StaticAddress.{i}.Chaddr` | `chaddr` | `mac` | Yes |
| `...StaticAddress.{i}.Yiaddr` | `yiaddr` | `ip` | Yes |

**Codegen DTO:** `DhcpReservations` (multi-instance, 3 fields, full CRUD)
**UI Model:** `DhcpReservationUIModel` (4 fields: instancePath + 3 mapped)
**Transform:** `UspDeviceService.buildDhcpReservationUIModels()`

---

### 4.9 DHCP Clients

| TR-181 Path | Codegen Field | UI Model Field |
|-------------|---------------|----------------|
| `Device.DHCPv4.Server.Pool.1.Client.{i}.Chaddr` | `chaddr` | `mac` |
| `...Client.{i}.Active` | `active` | `active` |
| `...Client.{i}.IPv4Address.1.IPAddress` | `ipAddress` | `ip` |
| `...Client.{i}.IPv4Address.1.LeaseTimeRemaining` | `leaseTimeRemaining` (DateTime) | `leaseExpiry` → `leaseTimeFormatted` |

**Enrichment:** `hostName` is resolved by cross-referencing `ConnectedDevices` using MAC address.

**Codegen DTO:** `DhcpClients` (multi-instance, 4 fields)
**UI Model:** `DhcpClientUIModel` (5 fields + 3 getters)
**Transform:** `UspDeviceService.buildDhcpClientUIModels()`

---

### 4.10 Port Forwarding

| TR-181 Path | Codegen Field | UI Model Field | Writable |
|-------------|---------------|----------------|----------|
| `Device.NAT.PortMapping.{i}.Enable` | `enabled` | `enabled` | Yes |
| `...PortMapping.{i}.ExternalPort` | `externalPort` | `externalPort` | Yes |
| `...PortMapping.{i}.ExternalPortEndRange` | `externalPortEndRange` | `externalPortEndRange` | Yes |
| `...PortMapping.{i}.InternalPort` | `internalPort` | `internalPort` | Yes |
| `...PortMapping.{i}.InternalClient` | `internalClient` | `internalClient` | Yes |
| `...PortMapping.{i}.Protocol` | `protocol` | `protocol` | Yes |
| `...PortMapping.{i}.Description` | `description` | `description` | Yes |

**Port Range Classification:**
- `externalPortEndRange == 0 || == externalPort` → **Single Port**
- `externalPortEndRange > externalPort` → **Port Range**

**Codegen DTO:** `PortForwarding` (multi-instance, 7 fields, full CRUD)
**UI Model:** `PortForwardingRuleUIModel` (8 fields + 4 getters: `isSinglePort`, `isPortRange`, `portRangeDisplay`, `portSummary`)
**Transform:** `UspDeviceService.buildPortForwardingRuleUIModels()`

---

### 4.11 Port Triggering (Nested Multi-Instance)

**Parent: `Device.NAT.PortTrigger.{i}.`**

| TR-181 Path | Codegen Field | UI Model Field | Writable |
|-------------|---------------|----------------|----------|
| `...PortTrigger.{i}.Enable` | `enabled` | `enabled` | Yes |
| `...PortTrigger.{i}.Description` | `description` | `description` | Yes |
| `...PortTrigger.{i}.Port` | `triggerPort` | `triggerPort` | Yes |
| `...PortTrigger.{i}.PortEndRange` | `triggerPortEndRange` | `triggerPortEndRange` | Yes |
| `...PortTrigger.{i}.Protocol` | `triggerProtocol` | `triggerProtocol` | Yes |

**Child: `Device.NAT.PortTrigger.{i}.Rule.{j}.`**

| TR-181 Path | Codegen Field | UI Model Field | Writable |
|-------------|---------------|----------------|----------|
| `...Rule.{j}.Port` | `forwardPort` | `forwardPort` | Yes |
| `...Rule.{j}.PortEndRange` | `forwardPortEndRange` | `forwardPortEndRange` | Yes |
| `...Rule.{j}.Protocol` | `forwardProtocol` | `forwardProtocol` | Yes |

**Codegen DTO:** `PortTriggering` (multi-instance + children, full CRUD + child CRUD)
**UI Models:** `PortTriggeringRuleUIModel` (7 fields + `List<PortTriggerForwardRuleUIModel>` + 5 getters) + `PortTriggerForwardRuleUIModel` (4 fields + 1 getter)
**Transform:** `UspDeviceService.buildPortTriggeringRuleUIModels()`

---

### 4.12 Mesh Network Topology

| TR-181 Path | Codegen Field | UI Model Field |
|-------------|---------------|----------------|
| `Device.WiFi.DataElements.Network.Device.{i}.ID` | `id` | `deviceId` |
| `...Device.{i}.ManufacturerModel` | `manufacturerModel` | `model` |
| `...Device.{i}.Manufacturer` | `manufacturer` | `manufacturer` |
| `...Device.{i}.SerialNumber` | `serialNumber` | `serialNumber` |
| `...Device.{i}.SoftwareVersion` | `softwareVersion` | `softwareVersion` |
| `...Device.{i}.Radio.{j}.*` | (counted) | `radioCount` |
| (derived) | — | `isMaster` (first node = gateway) |
| (derived from ConnectedDevices) | — | `connectedDeviceCount` |

**Codegen DTO:** `DataElementsNetwork` (4-level deep nesting: Device → Radio → BSS → STA)
**UI Model:** `NodeUIModel` (8 fields + 2 getters)
**Transform:** `UspDeviceService.buildNodeUIModels()` — includes synthetic gateway fallback for non-mesh routers

---

### 4.13 Admin Users

| TR-181 Path | Codegen Field | Writable |
|-------------|---------------|----------|
| `Device.Users.User.{i}.Username` | `username` | No |
| `Device.Users.User.{i}.Password` | `password` | Yes |
| `Device.Users.User.{i}.Enable` | `enable` | No |

Used by Admin page for password change, not displayed in dashboard.

---

### 4.14 Firewall Settings

| TR-181 Path | Codegen Field | UI Model Field | Writable |
|-------------|---------------|----------------|----------|
| `Device.Firewall.Chain.1.Rule.{i}.Enable` | `enable` | (derived by Description match) | Yes |
| `Device.Firewall.Chain.1.Rule.{i}.Description` | `description` | (feature identifier key) | No |
| `Device.Firewall.Chain.1.Rule.{i}.Target` | `target` | (Accept/Drop) | No |

**Mapping Logic:** Rules are identified by `Description` field matching feature names (e.g., "SPI_IPv4", "SPI_IPv6", "IPSec_Passthrough", "PPTP_Passthrough", "L2TP_Passthrough", "AnonymousRequests", "Multicast", "IDENT"). The `UspFirewallService` maps these Description-based rules to the unified `FirewallUIModel` fields (e.g., `isIPv4FirewallEnabled`, `blockIPSec`, etc.). Toggle mutations update the individual rule's `Enable` field.

**Codegen DTO:** `FirewallChainRules` (multi-instance, 3 fields, writable Enable)
**UI Model:** `FirewallUIModel` (8 boolean fields + copyWith)
**Transform:** `UspFirewallService.buildFirewallUIModel()`

---

### 4.15 DMZ Configuration

| TR-181 Path | Codegen Field | UI Model Field | Writable |
|-------------|---------------|----------------|----------|
| `Device.Firewall.DMZ.{i}.Enable` | `enable` | `isEnabled` | Yes |
| `Device.Firewall.DMZ.{i}.DestIP` | `destIp` | `destIp` | Yes |
| `Device.Firewall.DMZ.{i}.SourcePrefix` | `sourcePrefix` | `sourceType` + `sourcePrefix` | Yes |
| `Device.Firewall.DMZ.{i}.Interface` | `interface_` | — (defaults to WAN) | Yes |
| `Device.Firewall.DMZ.{i}.Description` | `description` | — | Yes |
| `Device.Firewall.DMZ.{i}.Status` | `status` | — | No |

**Mapping Logic:** Multi-instance on router but UI treats as 0-or-1 entry. `sourcePrefix == "0.0.0.0/0"` or empty → `DmzSourceType.any`, otherwise `DmzSourceType.cidr`. Enable/disable uses add (create entry) or delete (remove entry) + toggle via update.

**Codegen DTO:** `Dmz` (multi-instance, 6 fields, full CRUD)
**UI Model:** `DmzUIModel` (4 fields + `DmzSourceType` enum + copyWith + `.disabled()` factory)
**Transform:** `UspDmzService.buildDmzUIModel()`

---

### 4.16 Local Network Settings

| TR-181 Path | Codegen Field | UI Model Field | Writable |
|-------------|---------------|----------------|----------|
| `Device.IP.Interface.1.IPv4Address.1.IPAddress` | `ipAddress` | `ipAddress` | Yes |
| `Device.IP.Interface.1.IPv4Address.1.SubnetMask` | `subnetMask` | `subnetMask` | Yes |
| `Device.DHCPv4.Server.Pool.1.Enable` | `dhcpEnabled` | `dhcpEnabled` | Yes |
| `Device.DHCPv4.Server.Pool.1.MinAddress` | `minAddress` | `minAddress` | Yes |
| `Device.DHCPv4.Server.Pool.1.MaxAddress` | `maxAddress` | `maxAddress` | Yes |
| `Device.DHCPv4.Server.Pool.1.LeaseTime` | `leaseTime` | `leaseTimeMinutes` (÷60) | Yes |
| `Device.DHCPv4.Server.Pool.1.DNSServers` | `dnsServers` | `dnsServer1/2/3` (split) | Yes |
| `Device.DNS.Client.HostName` | `hostName` | `hostName` | Yes |

**Mapping Logic:** Uses `LanNetworkInfo` codegen (scatter-gather) with extended writable fields. DNS servers stored as comma-separated string in codegen, split into 3 fields in UI model. Lease time stored in seconds (codegen) → minutes (UI). Subnet mask enforces prefix-locked octets (UI validation). Dirty guard tracks field-level changes.

**Codegen DTO:** `LanNetworkInfo` (single-instance scatter-gather, extended with lease/hostname)
**UI Model:** `LocalNetworkUIModel` (10 fields + copyWith + `.initial()` factory)
**Transform:** `UspLocalNetworkService.buildLocalNetworkUIModel()`

---

### 4.17 Static Routing

| TR-181 Path | Codegen Field | UI Model Field | Writable |
|-------------|---------------|----------------|----------|
| `Device.Routing.Router.1.IPv4Forwarding.{i}.Enable` | `enable` | `enabled` | Yes |
| `...IPv4Forwarding.{i}.DestIPAddress` | `destIpAddress` | `destIpAddress` | Yes |
| `...IPv4Forwarding.{i}.DestSubnetMask` | `destSubnetMask` | `destSubnetMask` | Yes |
| `...IPv4Forwarding.{i}.GatewayIPAddress` | `gatewayIpAddress` | `gatewayIpAddress` | Yes |
| `...IPv4Forwarding.{i}.Interface` | `interface_` | `interfaceName` + `interfacePath` | Yes |
| `...IPv4Forwarding.{i}.Origin` | `origin` | (filter key) | No |
| `...IPv4Forwarding.{i}.Alias` | `alias` | `name` | Yes |

**Mapping Logic:** The routing table contains both kernel routes (`Origin=DHCPv4`) and user-created static routes (`Origin=Static`). The service filters by `Origin == "Static"` to only show user-configurable entries. Interface path (e.g., `Device.IP.Interface.1`) is mapped to display name ("LAN"/"Internet").

**Codegen DTO:** `StaticRouting` (multi-instance, 7 fields, full CRUD)
**UI Model:** `StaticRouteUIModel` (8 fields)
**Transform:** `UspStaticRoutingService.buildStaticRouteUIModels()`

---

### 4.18 IPv6 Port Service

| TR-181 Path | Codegen Field | UI Model Field | Writable |
|-------------|---------------|----------------|----------|
| `Device.Firewall.Chain.1.Rule.{i}.Enable` | `enable` | `enabled` | Yes |
| `...Rule.{i}.Description` | `description` | `description` | Yes |
| `...Rule.{i}.IPVersion` | `ipVersion` | (filter: must be 6) | Yes |
| `...Rule.{i}.DestIP` | `destIp` | `ipv6Address` | Yes |
| `...Rule.{i}.DestPort` | `destPort` | `startPort` | Yes |
| `...Rule.{i}.DestPortRangeMax` | `destPortRangeMax` | `endPort` | Yes |
| `...Rule.{i}.Protocol` | `protocol` | `protocol` (mapped) | Yes |
| `...Rule.{i}.Target` | `target` | (filter: must be "Accept") | Yes |
| `...Rule.{i}.CreationDate` | `creationDate` | (filter: exclude system rules) | No |

**Mapping Logic:** Shares the same `Device.Firewall.Chain.1.Rule` table as Firewall Settings, but with extended fields for port/protocol management. Filters: `IPVersion == 6`, `Target == "Accept"`, `CreationDate != "0001-01-01T00:00:00Z"` (excludes firmware system rules). IANA protocol numbers mapped to display names: 6→"TCP", 17→"UDP", 255→"Both".

**Codegen DTO:** `Ipv6PortService` (multi-instance, 9 fields, full CRUD)
**UI Model:** `Ipv6PortServiceRuleUIModel` (7 fields + `portDisplay` getter)
**Transform:** `UspIpv6PortServiceService.buildRuleUIModels()`

---

### 4.19 Safe Browsing (Instant Safety)

| TR-181 Path | Source | UI Model Field |
|-------------|--------|----------------|
| `Device.DHCPv4.Server.Pool.1.DNSServers` | `LanNetworkInfo.dnsServers` | `currentDnsServers` |
| (derived) | DNS value matching | `type` (off / openDNS) |

**Mapping Logic:** Safe browsing is implemented by setting the router's DNS servers to OpenDNS Family Shield IPs (`208.67.222.123,208.67.220.123`). The service checks if the current DNS matches OpenDNS and derives the `SafeBrowsingType`. Toggle sets or clears the DNS servers via `LanNetworkInfo.save()`.

**Codegen DTO:** Reuses `LanNetworkInfo` (DNS field)
**UI Model:** `SafeBrowsingUIModel` (2 fields + `isEnabled` getter + `SafeBrowsingType` enum)
**Transform:** `InstantSafetyService.buildSafeBrowsingUIModel()`

---

## 5. UspService Transport Layer

### 5.1 Core API

```dart
class UspService {
  // Authentication
  bool get isAuthenticated;
  String? get sessionToken;
  Future<void> login(String password);
  Future<void> logout();
  Future<void> refreshToken();

  // CRUD Operations
  Future<Map<String, dynamic>> get(List<String> paths);
  Future<void> set(Map<String, dynamic> params);
  Future<String> add(String path, Map<String, dynamic> params);
  Future<void> delete(String path);

  // Batch Operations
  Future<void> addMultiple(String path, List<Map<String, dynamic>> paramsList);
  Future<void> deleteMultiple(List<String> paths);

  // Advanced
  Future<Map<String, dynamic>> operate(String command, {Map<String, String>? args});
  Future<Subscription<T>> subscribe<T>({...}); // Polling stub
}
```

### 5.2 Value Coercion (`_coerceValue`)

The WASM client returns all values as strings. `_coerceValue()` converts them to appropriate Dart types:

| Raw Value | Path Suffix | Dart Result |
|-----------|-------------|-------------|
| `"true"` / `"false"` | (any) | `bool` |
| `"1"` / `"0"` | `*Enable`, `*Active`, `*Upstream` | `bool` |
| `"1"` / `"0"` | (other) | `String` (unchanged) |
| `null` / `""` | (any) | `null` |
| (anything else) | (any) | `String` (unchanged) |

**Known Boolean Path Suffixes:** `Enable`, `Active`, `Upstream`

### 5.3 401 Auth Retry Mechanism

All `UspService` CRUD methods are wrapped with `_withAuthRetry()` for automatic re-authentication on HTTP 401 (token expiry):

```dart
Future<T> _withAuthRetry<T>(Future<T> Function() action) async {
  try {
    return await action();
  } catch (e) {
    if (!_isAuthError(e)) rethrow;
    await reauth();         // two-stage reauth
    return await action();  // retry once
  }
}
```

**Two-Stage Reauth:**
1. **Stage 1:** `refreshToken()` — fast, no password needed
2. **Stage 2:** `onReauthRequired()` callback → `UspAuthCoordinator.restoreSession()` — reads stored password from `FlutterSecureStorage`, performs full re-login

**Concurrent Protection:** `Completer<void>` lock ensures only one reauth runs at a time. Concurrent 401 errors await the same Completer.

**Detection:**
- WASM/protobuf path: `error.toString().contains('HTTP 401')`
- REST path (`UspBridgeClient`): `response.statusCode == 401`

**Wrapped Methods (11):** `getSingle`, `setSingle`, `get`, `set`, `getMultiple`, `setMultiple`, `add`, `addMultiple`, `delete`, `deleteMultiple`, `operate`

**UspBridgeClient:** Also has `_withAuthRetry()` for REST endpoints (`health`, `subscribe`, `unsubscribe`, `turboStatus`, `turboPost`) and SSE 401 reconnect in `_startSseStream`.

**Files:**
- `lib/usp/services/usp_service.dart` — `_withAuthRetry`, `reauth()`, `_reauthInProgress`
- `lib/usp/services/usp_bridge_client.dart` — REST `_withAuthRetry`, SSE 401 reconnect
- `lib/usp/providers/usp_auth_coordinator.dart` — registers `onReauthRequired` callback in constructor

### 5.4 Response Helpers (`UspResponseExtension`)

```dart
extension UspResponseExtension on Map<String, dynamic> {
  /// Parse flat USP Get response into grouped instances.
  /// Input:  {"Device.Hosts.Host.1.HostName": "PC", "Device.Hosts.Host.1.Active": true, ...}
  /// Output: [UspInstance(path: "Device.Hosts.Host.1.", params: {"HostName": "PC", "Active": true})]
  List<UspInstance> getInstances(String basePath);
}

class UspInstance {
  String get path;
  String getString(String paramName);
  bool getBool(String paramName);    // handles bool, "true", "1"
  int getInt(String paramName);      // handles int, String parsing
  double getDouble(String paramName);
}
```

---

## 6. Dashboard State Architecture

### 6.1 State Class

`UspDashboardState` holds both **raw codegen DTOs** (for mutations that need to re-send data to the router) and **UI models** (for view rendering):

```dart
class UspDashboardState extends Equatable {
  // ── Raw Codegen DTOs (used by Notifier mutations) ──
  final SystemInfo systemInfo;
  final ConnectedDevices connectedDevices;
  final WiFiRadios wifiRadios;
  final WiFiSsids wifiSsids;
  final WiFiAccessPoints wifiAccessPoints;
  final TimeSettings timeSettings;
  final DhcpClients dhcpClients;
  final DhcpReservations dhcpReservations;
  final PortForwarding portForwarding;
  final PortTriggering portTriggering;
  final WifiClients wifiClients;          // WiFi signal enricher
  final DataElementsNetwork meshNodes;     // Mesh topology enricher
  final LanNetworkInfo lanNetworkInfo;
  final EthernetInterfaces ethernetInterfaces;
  final WanStatus wanStatus;

  // ── UI Models (used by Views) ──
  final SystemInfoUIModel systemInfoModel;
  final LanInfoUIModel lanInfoModel;
  final List<DeviceUIModel> deviceModels;
  final List<WifiRadioUIModel> wifiRadioModels;
  final TimeSettingsUIModel timeSettingsModel;
  final List<DhcpClientUIModel> dhcpClientModels;
  final List<DhcpReservationUIModel> dhcpReservationModels;
  final List<PortForwardingRuleUIModel> portForwardingRuleModels;
  final List<PortTriggeringRuleUIModel> portTriggeringRuleModels;
  final List<EthernetPortUIModel> ethernetPortModels;
  final List<NodeUIModel> nodeModels;
  final WanStatusUIModel wanStatusModel;
}
```

### 6.2 Notifier Data Flow

```
build() {
  ┌──────────────────────────────────────────────────────────┐
  │  15 Parallel Future.wait Fetches                         │
  │  ├── SystemInfo.fetch(usp)                               │
  │  ├── ConnectedDevices.fetch(usp)                         │
  │  ├── WiFiRadios.fetch(usp)                               │
  │  ├── WiFiSsids.fetch(usp)                                │
  │  ├── WiFiAccessPoints.fetch(usp)                         │
  │  ├── TimeSettings.fetch(usp)                             │
  │  ├── DhcpClients.fetch(usp)                              │
  │  ├── DhcpReservations.fetch(usp)                         │
  │  ├── PortForwarding.fetch(usp)                           │
  │  ├── PortTriggering.fetch(usp)                           │
  │  ├── WifiClients.fetch(usp)        ← WiFi enricher      │
  │  ├── DataElementsNetwork.fetch(usp) ← Mesh enricher     │
  │  ├── LanNetworkInfo.fetch(usp)                           │
  │  ├── EthernetInterfaces.fetch(usp)                       │
  │  └── WanStatus.fetch(usp)                                │
  └──────────────────────────────────────────────────────────┘
                          │
                          ▼
  ┌──────────────────────────────────────────────────────────┐
  │  Post-Processing                                         │
  │  ├── Build AP→SSID→Radio connection detail map           │
  │  └── _fetchDefaultGateway(usp) → routing table query     │
  └──────────────────────────────────────────────────────────┘
                          │
                          ▼
  ┌──────────────────────────────────────────────────────────┐
  │  UspDeviceService Transform (13 builder methods)         │
  │  ├── buildSystemInfoUIModel(systemInfo)                   │
  │  ├── buildDeviceUIModels(devices, wifiClients, mesh...)   │
  │  ├── buildWifiRadioUIModels(radios, ssids, aps)           │
  │  ├── buildTimeSettingsUIModel(timeSettings)               │
  │  ├── buildDhcpClientUIModels(clients, devices)            │
  │  ├── buildDhcpReservationUIModels(reservations)           │
  │  ├── buildPortForwardingRuleUIModels(forwarding)          │
  │  ├── buildPortTriggeringRuleUIModels(triggering)          │
  │  ├── buildLanInfoUIModel(lanInfo)                         │
  │  ├── buildWanStatusUIModel(wan, gateway)                  │
  │  ├── buildEthernetPortUIModels(ethernet, devices)         │
  │  └── buildNodeUIModels(mesh, systemInfo, devices)         │
  └──────────────────────────────────────────────────────────┘
                          │
                          ▼
              UspDashboardState (raw + UI models)
```

### 6.3 Mutation Pattern

All mutations follow a consistent pattern with sequential locking:

```dart
Future<void> toggleSomething(String instancePath, bool value) async {
  await _withLock('cardKey', () async {
    // 1. Call codegen update API
    await SomeModel.update(usp, SomeModelUpdate(
      instancePath: instancePath,
      field: value,
    ));
    // 2. Re-fetch fresh data
    final fresh = await SomeModel.fetch(usp);
    // 3. Transform to UI model
    final models = service.buildSomeUIModels(fresh);
    // 4. Update state via copyWith
    state = AsyncData(state.requireValue.copyWith(
      someRaw: fresh,
      someModels: models,
    ));
  });
}
```

**`_withLock()`** ensures only one mutation runs at a time and tracks loading state via `uspMutationLoadingProvider`.

---

## 7. UI Component Inventory

### 7.1 Dashboard Cards (14)

| # | Card | Data Source | Interaction |
|---|------|------------|-------------|
| 1 | `UspStatsPanel` | deviceModels, wifiRadioModels, portForwardingRuleModels, ethernetPortModels | Read-only (4 stat tiles) |
| 2 | `UspNetworkStatusCard` | wanStatusModel | Read-only (WAN IP, subnet, type, gateway, MTU) |
| 3 | `UspNetworkTopologyCard` | nodeModels | Read-only (mesh node visualization) |
| 4 | `UspDeviceInfoCard` | systemInfoModel | Read-only (manufacturer, model, serial, HW/SW version) |
| 5 | `UspLanInfoCard` | lanInfoModel | Read-only (LAN IP, subnet, DHCP range, DNS) |
| 6 | `UspEthernetPortsCard` | ethernetPortModels | Tap → detail dialog |
| 7 | `UspSystemStatusCard` | systemInfoModel | Read-only (CPU%, memory%, uptime gauges) |
| 8 | `UspConnectedDevicesCard` | deviceModels | Read-only list (online/offline, WiFi signal) |
| 9 | `UspWifiStatusCard` | wifiRadioModels | Toggle enable, edit channel dialog |
| 10 | `UspTimeSettingsCard` | timeSettingsModel | Toggle NTP, edit NTP servers dialog |
| 11 | `UspDhcpReservationsCard` | dhcpReservationModels | Toggle, add, delete with confirmation |
| 12 | `UspPortForwardingCard` | portForwardingRuleModels | Toggle, add/edit, delete, "View All" navigation |
| 13 | `UspProtocolInfoCard` | UspService metadata | Read-only (USP endpoint, auth status, session) |
| 14 | `UspConnectionStatusCard` | (legacy, exported but unused) | — |

### 7.2 Dashboard Dialogs (7)

| # | Dialog | Feature |
|---|--------|---------|
| 1 | `wifi_channel_dialog.dart` | Edit WiFi radio channel |
| 2 | `time_settings_dialog.dart` | Edit NTP server 1 & 2 |
| 3 | `dhcp_reservation_dialog.dart` | Add/edit DHCP static lease |
| 4 | `port_forwarding_dialog.dart` | Add/edit single port forwarding rule |
| 5 | `ethernet_port_detail_dialog.dart` | View port details + connected devices |
| 6 | `port_range_forwarding_dialog.dart` | Add/edit port range forwarding rule |
| 7 | `port_triggering_dialog.dart` | Add/edit port triggering rule + forward rules |

### 7.3 Standalone Feature Pages (12)

| # | Page | Route | Feature | Interaction |
|---|------|-------|---------|-------------|
| 1 | `UspAdminView` | `/uspAdmin` | Password change, timezone, reboot, factory reset | Write |
| 2 | `UspDhcpDetailView` | `/uspDhcpDetail` | DHCP server info + reservations detail + active leases | Read + CRUD |
| 3 | `UspPortForwardingDetailView` | `/uspPortForwardingDetail` | 3-tab: Single Port / Port Range / Port Triggering | Full CRUD |
| 4 | `UspDeviceListView` | `/uspDevices` | Filterable device list (WiFi/Wired/Online/Offline) | Read-only |
| 5 | `UspTopologyView` | `/uspTopology` | Mesh node tree + node detail | Read-only |
| 6 | `UspSystemLogView` | `/uspSystemLog` | VendorLogFile metadata (graceful empty state) | Read-only |
| 7 | `UspFirewallView` | `/uspFirewall` | SPI, VPN passthrough, filter toggles | Read + Write |
| 8 | `UspDmzView` | `/uspDmz` | DMZ enable/disable, dest IP, source CIDR | Full CRUD |
| 9 | `InstantSafetyView` | `/uspInstantSafety` | OpenDNS Family Shield toggle | Write |
| 10 | `UspLocalNetworkView` | `/uspLocalNetwork` | Router IP, subnet, hostname, DHCP pool, DNS, lease time | Read + Write (dirty guard) |
| 11 | `UspStaticRoutingView` | `/uspStaticRouting` | IPv4 static routes CRUD, Origin filter, interface mapping | Full CRUD |
| 12 | `UspIpv6PortServiceView` | `/uspIpv6PortService` | IPv6 inbound port rules CRUD, IANA protocol mapping | Full CRUD |

### 7.4 Standalone Page Dialogs (6)

| # | Dialog | Page | Feature |
|---|--------|------|---------|
| 1 | `change_password_dialog.dart` | Admin | Change admin password |
| 2 | `timezone_edit_dialog.dart` | Admin | Edit timezone settings |
| 3 | `confirm_action_dialog.dart` | Admin | Confirm reboot / factory reset |
| 4 | `dhcp_reservation_edit_dialog.dart` | DHCP Detail | Add/edit DHCP reservation |
| 5 | `static_route_dialog.dart` | Static Routing | Add/edit static route |
| 6 | `ipv6_port_service_rule_dialog.dart` | IPv6 Port Service | Add/edit IPv6 port rule |

### 7.5 Port Forwarding Detail Page (3 Tabs)

| Tab | Component | Data |
|-----|-----------|------|
| Single Port | `UspSinglePortTab` | `portForwardingRuleModels.where(isSinglePort)` |
| Port Range | `UspPortRangeTab` | `portForwardingRuleModels.where(isPortRange)` |
| Port Triggering | `UspPortTriggeringTab` | `portTriggeringRuleModels` |

### 7.6 Skeleton Loading

`UspDashboardSkeleton` renders 5 skeleton templates matching dashboard layout:

| Template | Used For |
|----------|----------|
| `_SkeletonStatsPanel` | 4 stat tiles (icon + value + label) |
| `_SkeletonConnectionStatus` | Connection status row |
| `_SkeletonInfoCard(rows: N)` | DeviceInfo, LAN, Protocol, SystemStatus, Ethernet |
| `_SkeletonListCard(rows: N)` | ConnectedDevices, WiFi, DHCP, PortForwarding |
| `_SkeletonTopologyCard` | Network topology (320px placeholder) |

Loading state shows `LinearProgressIndicator` (4px) reflecting actual fetch progress (`uspLoadingProgressProvider`).

### 7.7 Responsive Layout

| Mode | Layout |
|------|--------|
| **Mobile** | Single column, all 14 cards stacked vertically |
| **Desktop** | Shared top (stats + network + topology) + 2-column: left (static info cards) / right (interactive CRUD cards) |

---

## 8. Cross-Reference and Enrichment Logic

Several UI models require cross-referencing multiple data sources:

### 8.1 Device WiFi Enrichment

```
ConnectedDevices (MAC, IP, hostname, active)
       │
       ├── JOIN by MAC ──→ WifiClients (signal, rates)
       │
       ├── JOIN by AP index ──→ WiFiAccessPoints → SSIDReference → WiFiSsids (SSID name)
       │                                         → Radio (band via LowerLayers)
       │
       └── JOIN by AP → Radio → MeshNode ──→ DataElementsNetwork (parent node ID/name)
```

### 8.2 Ethernet Port Device Mapping

```
EthernetInterfaces (name, status, upstream, bitRate)
       │
       └── JOIN by Layer1Interface ──→ ConnectedDevices (wired devices on each port)
```

For LAN ports, `isUp` is derived from wired device presence rather than link status (a LAN port with link but no host device is shown as inactive).

### 8.3 DHCP Client Hostname Resolution

```
DhcpClients (MAC, IP, active, leaseExpiry)
       │
       └── JOIN by MAC ──→ ConnectedDevices (hostname enrichment)
```

---

## 9. Bug Fixes and Technical Notes

### 9.1 Upstream Boolean Coercion (BUG — Fixed)

**Problem:** TR-181 returns `"1"`/`"0"` for `xsd:boolean` types. `_coerceValue()` only converted `"1"` → `true` for paths ending in `Enable` or `Active`, but not `Upstream`.

**Impact:** All Ethernet ports showed `upstream = false` → WAN port was misidentified as LAN.

**Fix:** Added `Upstream` to known boolean path suffixes in `_coerceValue()`:
```dart
final isBoolPath = path.endsWith('Enable') ||
    path.endsWith('Active') ||
    path.endsWith('Upstream');
```

**File:** `lib/usp/services/usp_service.dart`

### 9.2 WASM Parallel Request Support

**Problem:** WASM client initially serialized HTTP requests, causing sequential fetch of 15 categories.

**Fix:** Updated WASM client to support parallel HTTP requests, enabling `Future.wait` to execute all fetches concurrently.

### 9.3 JNAP Unavailable Environment Stability

Multiple fixes to prevent JNAP failures from crashing the app when USP is the primary protocol:

| Fix | File |
|-----|------|
| FormatException → JNAPError conversion | `jnap_spec.dart` |
| `_ErrorJNAPUnavailable` skips forced logout | `polling_provider.dart` |
| Individual try-catch in `_additionalPolling()` | `polling_service.dart` |
| `isReady` requires non-empty data | `polling_provider.dart` |
| Stored credentials USP-only bypass | `router_provider.dart` |

### 9.4 YAML `base_path` Format Migration (BUG — Fixed)

**Date:** 2026-03-09

**Problem:** 8 YAML definitions used the deprecated `base_path` + `multi_instance: true` format. For multi-instance definitions, codegen generated broken wildcard paths missing the dot separator: `Device.X.Y.*FieldName` instead of `Device.X.Y.*.FieldName`.

**Impact:**
- 4 multi-instance files generated **broken paths** (USP Get returns empty):
  - `vendor_log_files.yaml` → `*Name` instead of `*.Name`
  - `dhcp_clients.yaml` → `*Chaddr` instead of `*.Chaddr`
  - `dhcp_reservations.yaml` → `*Enable` instead of `*.Enable`
  - `admin_users.yaml` → `*Username` instead of `*.Username`
- 2 single-instance files had correct output but deprecated format:
  - `system_info.yaml` → `instance: Device.DeviceInfo` (no trailing dot)
  - `time_settings.yaml` → `instance: Device.Time` (no trailing dot)
- 1 file with dot-prefixed paths worked correctly but used old field names:
  - `wifi_clients.yaml` → `multiInstance:`, `singularName:`, `nestedPath:`
- 1 file already fixed earlier in this session:
  - `ethernet_interfaces.yaml` → `multiInstance: Device.Ethernet.Interface.`

**Fix:** Migrated all 8 YAMLs to modern format:
- Multi-instance: `base_path` + `multi_instance: true` → `multiInstance: Device.X.Y.` + `path: .FieldName`
- Single-instance: `base_path` → `instance: Device.X.Y` (no trailing dot) + `path: .FieldName`
- Deprecated fields: `singular_name` → `singularName`, `nested_path` → `nestedPath`

**Note:** `instance:` must NOT have a trailing dot (codegen inserts one), while `multiInstance:` MUST have a trailing dot (codegen inserts `*.` between it and the field path).

**Files:** 8 YAML definitions + regenerated all 20 `.g.dart` files

### 9.5 USP Auto-Logout on Navigation (BUG — Fixed)

**Date:** 2026-03-09

**Problem:** Navigating from USP Dashboard to USP Menu triggered automatic logout. Three independent root causes:

1. **Router redirect bypass too narrow:** Only `/uspDashboard` was excluded from JNAP redirect logic. Other USP routes (`/uspMenu`, `/uspDmz`, etc.) fell through to `redirectLogic()` → `_prepare()` → `checkAndStartPolling()`.
2. **JNAP polling in USP-only mode:** Polling kicked off JNAP requests that failed with `_ErrorUnauthorized`, triggering logout.
3. **Error handler too strict:** Polling error handler only tolerated `_ErrorJNAPUnavailable` but not `_ErrorUnauthorized` in USP-only mode.

**Fix (3-layer defense):**

| Layer | Fix | File |
|-------|-----|------|
| Router | `state.matchedLocation.startsWith('/usp')` bypasses ALL USP routes | `router_provider.dart` |
| Polling | `ProtocolResolver.isUspOnlyMode` → skip `checkAndStartPolling()` entirely | `polling_provider.dart` |
| Error handler | Tolerate `_ErrorUnauthorized` when `isUspOnlyMode` is true | `polling_provider.dart` |

### 9.6 Ethernet Ports Empty Card (BUG — Fixed)

**Date:** 2026-03-09

**Problem:** Ethernet Ports dashboard card showed empty despite WAN and LAN cables being connected. Root cause: `ethernet_interfaces.yaml` used old `base_path` format generating `Device.Ethernet.Interface.*Name` (invalid wildcard). USP Get returned empty response.

**SSH verification:** Router confirmed `Interface.1` (WAN eth1, 2500Mbps) and `Interface.2` (LAN eth0, 1000Mbps) present.

**Fix:** Part of the YAML format migration (9.4). Updated to `multiInstance: Device.Ethernet.Interface.` + `path: .Name` → generates `Device.Ethernet.Interface.*.Name`.

### 9.7 LAN Port Layer1Interface Mismatch (BUG — Fixed)

**Date:** 2026-03-09

**Problem:** LAN Ethernet port showed as "Up" but with no connected devices listed. The code matched `ConnectedDevice.Layer1Interface` against `Device.Ethernet.Interface.2.`, but the router's `Layer1Interface` points to a bridge port (e.g., `Device.Bridging.Bridge.1.Port.X`) instead of the physical Ethernet interface.

**Fix (2 changes in `usp_device_service.dart`):**

1. **Port status fallback:** LAN `isUp` = `wiredDevices.isNotEmpty || port.status == 'up'` (was only device-based).
2. **Device fallback:** When exact `Layer1Interface` match fails and there's a single LAN port, assign all non-WiFi active devices to that port. Non-WiFi detection: `!interface_.toLowerCase().contains('wifi')`.

**File:** `lib/usp_page/dashboard/services/usp_device_service.dart`

### 9.8 Connected Devices Card Layout Overflow (UI — Fixed)

**Date:** 2026-03-09

**Problem:** Title "Connected Devices" and online/offline status counts were on the same `Row` without `Expanded`/`Flexible`, causing overflow on narrow screens.

**Fix:** Split into two rows:
- Row 1: Title (`Expanded`) + "View All" button
- Row 2: Online/Offline status dots and counts

**File:** `lib/usp_page/dashboard/views/components/usp_connected_devices_card.dart`

---

## 10. Authentication Architecture

### 10.1 Dual-Protocol Auth Flow

```
User enters password
        │
        ├─→ JNAP: AuthNotifier.localLogin(password)
        │          └─→ checkAdminPassword → store in SecureStorage
        │
        └─→ USP: UspAuthCoordinator.syncAfterLocalLogin(password)
                   └─→ UspService.login(password) → WASM session
```

### 10.2 Session Restoration

```
Page reload / App restart
        │
        └─→ UspAuthCoordinator.restoreSession()
                   └─→ Read password from SecureStorage
                   └─→ UspService.login(password) → WASM session restored
```

### 10.3 Auth Mode Compatibility

| Login Mode | JNAP Auth | USP Auth | Protocol Available |
|------------|-----------|----------|--------------------|
| Local | Basic auth | Auto-sync | USP + JNAP |
| Cloud (OAuth) | OAuth token | Not supported | JNAP only |
| Remote Access | RA session | Not supported | JNAP only |
| Page reload (local) | SecureStorage | restoreSession | USP + JNAP |
| Page reload (cloud) | SecureStorage | No password | JNAP only |

### 10.4 Token Expiry Handling (401 Auth Retry)

```
Request fails with HTTP 401
        │
        └─→ _withAuthRetry catches 401
                   │
                   ├─ Stage 1: refreshToken() (fast, no password)
                   │    └─ Success? → retry original request
                   │    └─ Fail? → Stage 2
                   │
                   └─ Stage 2: onReauthRequired()
                              └─→ UspAuthCoordinator.restoreSession()
                              └─→ Read password from SecureStorage
                              └─→ UspService.login(password)
                              └─→ retry original request
```

**Concurrent Protection:** `Completer<void>` lock prevents N concurrent 401s from triggering N reauths — all wait for the first reauth to complete.

**Coverage:** All 11 UspService CRUD methods + all UspBridgeClient REST endpoints + SSE stream reconnect.

---

## 11. Phase Status and Blocked Items

### 11.1 Completed Phases

| Phase | Scope | Status |
|-------|-------|--------|
| Phase 1 | Infrastructure (ProtocolResolver, UspAuth, DI) | ✅ Complete |
| Phase 2A | Read-only data (8 categories) | ✅ Complete |
| Phase 2B | Write operations (21 mutations) | ✅ Complete |
| Phase 2B-9 | Dashboard skeleton loading | ✅ Complete |
| Phase 2B-10 | Network Status Card + Stats Panel | ✅ Complete |
| Phase 4A | Standalone feature pages (7 pages) | ✅ Complete (2026-03-10) |
| Infra | 401 Auth Retry (two-stage reauth) | ✅ Complete (2026-03-10) |

**Phase 4A Details:**

| Feature | Page | Date |
|---------|------|------|
| F-005: Firewall Settings | `UspFirewallView` — SPI/VPN passthrough toggles | 2026-03-09 |
| F-006: DMZ Configuration | `UspDmzView` — enable/disable, dest IP, source CIDR, CRUD | 2026-03-09 |
| F-013: Firmware Dual Image | `UspDeviceInfoCard` — Active/Boot badge, graceful fallback | 2026-03-09 |
| F-014: CPU/Memory Monitoring | `UspSystemStatusCard` — merged gauge+chart, 30s auto-refresh | 2026-03-09 |
| F-016: Local Network Settings | `UspLocalNetworkView` — router IP, hostname, DHCP, dirty guard | 2026-03-10 |
| F-015: Static Routing | `UspStaticRoutingView` — route CRUD, Origin filter, interface map | 2026-03-10 |
| F-017: IPv6 Port Service | `UspIpv6PortServiceView` — IPv6 rules CRUD, IANA protocol mapping, CreationDate filter | 2026-03-10 |

### 11.2 Blocked by usp-bridge Server

| Feature | Blocker | Description |
|---------|---------|-------------|
| Ping/Traceroute (OPERATE) | BUG-003 + BUG-004 | SSE endpoint doesn't send data; Rust client async OperateResp parsing fails |
| Subscribe (real-time notifications) | BUG-003 | SSE notification channel not functioning |
| Turbo Channel (accelerated fetch) | BUG-003 | SSE transport not working |

### 11.3 Infrastructure Ready (Waiting for Server Fix)

- `NotifType` enum + `Subscription<T>` class + typed `subscribe<T>()` — polling simulation works
- Codegen generates `Future<Subscription<T>>` + `NotifType` + `parser` for subscribe-enabled definitions
- `UspBridgeClient` with SSE `/api/v1/notifications` + subscription register/unregister
- WASM client exports `getToken()`, `subscribe()`, `unsubscribe()`

---

## 12. File Inventory Summary

### 12.1 By Layer

| Layer | Files | Location |
|-------|-------|----------|
| YAML Definitions | 22 | `doc/usp/definitions/` |
| Codegen Output | 23 | `lib/generated/` (22 data + transforms) |
| USP Service | 3 | `lib/usp/services/` |
| USP Auth | 2 | `lib/usp/providers/` |
| UI Models | 21 | `lib/usp_page/**/models/` |
| Dashboard Providers | 7 | `lib/usp_page/dashboard/providers/` |
| Dashboard Service | 1 | `lib/usp_page/dashboard/services/` |
| Dashboard Components | 20 | `lib/usp_page/dashboard/views/components/` |
| Dashboard Dialogs | 5 | `lib/usp_page/dashboard/views/dialogs/` |
| Dashboard Main View | 1 | `lib/usp_page/dashboard/views/usp_dashboard_view.dart` |
| Standalone Services | 8 | `lib/usp_page/**/services/` (excl. dashboard) |
| Standalone Providers | 11 | `lib/usp_page/**/providers/` (excl. dashboard) |
| Standalone Views | 16 | `lib/usp_page/**/views/*_view.dart` (excl. dashboard) |
| Standalone Components | 11 | `lib/usp_page/**/views/components/` (excl. dashboard) |
| Standalone Dialogs | 8 | `lib/usp_page/**/views/dialogs/` (excl. dashboard) |
| Menu | 1 | `lib/usp_page/menu/` |
| **Total** | **~160** | |

### 12.2 Codegen Definition → Generated File → UI Model Traceability

| YAML | `.g.dart` | UI Model | Dashboard Card |
|------|-----------|----------|----------------|
| `system_info.yaml` | `system_info.g.dart` | `SystemInfoUIModel` | DeviceInfo + SystemStatus |
| `time_settings.yaml` | `time_settings.g.dart` | `TimeSettingsUIModel` | TimeSettings |
| `connected_devices.yaml` | `connected_devices.g.dart` | `DeviceUIModel` | ConnectedDevices |
| `wifi_clients.yaml` | `wifi_clients.g.dart` | (enriches DeviceUIModel) | ConnectedDevices |
| `wi_fi_radios.yaml` | `wi_fi_radios.g.dart` | `WifiRadioUIModel` | WiFiStatus |
| `wi_fi_access_points.yaml` | `wi_fi_access_points.g.dart` | `WifiAccessPointUIModel` | WiFiStatus |
| `wi_fi_ssids.yaml` | `wi_fi_ssids.g.dart` | (enriches WifiRadioUIModel) | WiFiStatus |
| `data_elements_network.yaml` | `data_elements_network.g.dart` | `NodeUIModel` | NetworkTopology |
| `lan_network_info.yaml` | `lan_network_info.g.dart` | `LanInfoUIModel` | LANInfo |
| `wan_status.yaml` | `wan_status.g.dart` | `WanStatusUIModel` | NetworkStatus |
| `ethernet_interfaces.yaml` | `ethernet_interfaces.g.dart` | `EthernetPortUIModel` | EthernetPorts |
| `dhcp_reservations.yaml` | `dhcp_reservations.g.dart` | `DhcpReservationUIModel` | DHCPReservations |
| `dhcp_clients.yaml` | `dhcp_clients.g.dart` | `DhcpClientUIModel` | (enriches DHCP display) |
| `admin_users.yaml` | `admin_users.g.dart` | — | Admin page |
| `port_forwarding.yaml` | `port_forwarding.g.dart` | `PortForwardingRuleUIModel` | PortForwarding |
| `port_triggering.yaml` | `port_triggering.g.dart` | `PortTriggeringRuleUIModel` | PortTriggering |
| `firewall_chain_rules.yaml` | `firewall_chain_rules.g.dart` | `FirewallUIModel` | Firewall page |
| `dmz.yaml` | `dmz.g.dart` | `DmzUIModel` | DMZ page |
| `vendor_log_files.yaml` | `vendor_log_files.g.dart` | `LogFileUIModel` | System Log page |
| `firmware_images.yaml` | `firmware_images.g.dart` | — | DeviceInfoCard (dual image) |
| `static_routing.yaml` | `static_routing.g.dart` | `StaticRouteUIModel` | Static Routing page |
| `ipv6_port_service.yaml` | `ipv6port_service.g.dart` | `Ipv6PortServiceRuleUIModel` | IPv6 Port Service page |
