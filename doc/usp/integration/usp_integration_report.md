# USP Integration Report

> Date: 2026-03-06 | Branch: `feat/usp-protocol-integration`
> Covers: Phase 1 (Infrastructure) + Phase 2A (Read) + Phase 2B (Write) + Phase 2C (Subscribe Infrastructure)

---

## 1. Executive Summary

PrivacyGUI has been extended with a parallel USP (User Services Platform / TR-369) protocol stack running alongside the existing JNAP protocol. The integration provides a fully independent **USP Dashboard** that does not depend on JNAP polling, featuring 14 data cards with full CRUD capabilities for key networking features.

### Key Metrics

| Metric | Value |
|--------|-------|
| YAML definitions | 16 |
| Generated `.g.dart` files | 17 (16 data + 1 transforms) |
| UI model classes | 15 (across 13 files) |
| Dashboard cards | 14 |
| Dashboard dialogs | 7 |
| Mutation methods | 21 |
| TR-181 data models covered | 16 |
| Parallel fetch tasks | 15 |
| Supported CRUD operations | fetch, update, add, delete, subscribe (stub) |

### Architecture at a Glance

```
┌─────────────────────────────────────────────────────────────────┐
│                        USP Dashboard View                       │
│   14 cards + 7 dialogs + skeleton loading + responsive layout   │
├─────────────────────────────────────────────────────────────────┤
│                     UI Models (Presentation)                     │
│   15 Equatable classes with computed display properties          │
├─────────────────────────────────────────────────────────────────┤
│                     UspDeviceService (Transform)                 │
│   13 builder methods: codegen DTO → UI Model                    │
├─────────────────────────────────────────────────────────────────┤
│                  UspDashboardNotifier (Orchestration)            │
│   build() parallel fetch + 21 mutation methods + _withLock      │
├─────────────────────────────────────────────────────────────────┤
│                   UspDashboardState (Equatable)                  │
│   Raw codegen DTOs + UI model fields + copyWith                 │
├─────────────────────────────────────────────────────────────────┤
│                Codegen .g.dart (Data Transfer Objects)           │
│   17 files: fetch/update/add/delete/subscribe                   │
├─────────────────────────────────────────────────────────────────┤
│                      UspService (Transport)                      │
│   WASM JS interop + _coerceValue + CRUD + Operate + Subscribe   │
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

### 5.3 Response Helpers (`UspResponseExtension`)

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

### 7.2 Dialogs (7)

| # | Dialog | Feature |
|---|--------|---------|
| 1 | `wifi_channel_dialog.dart` | Edit WiFi radio channel |
| 2 | `time_settings_dialog.dart` | Edit NTP server 1 & 2 |
| 3 | `dhcp_reservation_dialog.dart` | Add/edit DHCP static lease |
| 4 | `port_forwarding_dialog.dart` | Add/edit single port forwarding rule |
| 5 | `ethernet_port_detail_dialog.dart` | View port details + connected devices |
| 6 | `port_range_forwarding_dialog.dart` | Add/edit port range forwarding rule |
| 7 | `port_triggering_dialog.dart` | Add/edit port triggering rule + forward rules |

### 7.3 Port Forwarding Detail Page (3 Tabs)

| Tab | Component | Data |
|-----|-----------|------|
| Single Port | `UspSinglePortTab` | `portForwardingRuleModels.where(isSinglePort)` |
| Port Range | `UspPortRangeTab` | `portForwardingRuleModels.where(isPortRange)` |
| Port Triggering | `UspPortTriggeringTab` | `portTriggeringRuleModels` |

### 7.4 Skeleton Loading

`UspDashboardSkeleton` renders 5 skeleton templates matching dashboard layout:

| Template | Used For |
|----------|----------|
| `_SkeletonStatsPanel` | 4 stat tiles (icon + value + label) |
| `_SkeletonConnectionStatus` | Connection status row |
| `_SkeletonInfoCard(rows: N)` | DeviceInfo, LAN, Protocol, SystemStatus, Ethernet |
| `_SkeletonListCard(rows: N)` | ConnectedDevices, WiFi, DHCP, PortForwarding |
| `_SkeletonTopologyCard` | Network topology (320px placeholder) |

Loading state shows `LinearProgressIndicator` (4px) reflecting actual fetch progress (`uspLoadingProgressProvider`).

### 7.5 Responsive Layout

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
| YAML Definitions | 16 | `doc/usp/definitions/` |
| Codegen Output | 17 | `lib/generated/` |
| USP Service | 3 | `lib/usp/services/` |
| UI Models | 13 | `lib/usp_page/**/models/` |
| Dashboard State | 1 | `lib/usp_page/dashboard/providers/usp_dashboard_state.dart` |
| Dashboard Notifier | 1 | `lib/usp_page/dashboard/providers/usp_dashboard_notifier.dart` |
| Dashboard Service | 1 | `lib/usp_page/dashboard/services/usp_device_service.dart` |
| Dashboard Components | 19 | `lib/usp_page/dashboard/views/components/` |
| Dashboard Dialogs | 5 | `lib/usp_page/dashboard/views/dialogs/` |
| Dashboard Main View | 1 | `lib/usp_page/dashboard/views/usp_dashboard_view.dart` |
| Port Forwarding Detail | 7 | `lib/usp_page/port_forwarding/` |
| Menu | 1 | `lib/usp_page/menu/` |
| **Total** | **~85** | |

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
