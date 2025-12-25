# JNAP to TR-181 Mapping Report

**Date:** 2025-12-25
**Source File:** `apps/PrivacyGUI/lib/core/usp/jnap_tr181_mapper.dart`

This document details the mapping strategy implemented to convert JNAP actions to TR-181 data models for the USP client POC.

## Overview

The `JnapTr181Mapper` class handles the translation between legacy JNAP actions and standard TR-181 USP paths. It supports converting JNAP actions into TR-181 keys for fetching data, and mapping the resulting USP `GetResponse` back into JNAP-compatible JSON structures.

## Data Flow & Conversion Architecture

The conversion process follows a three-stage pipeline:

### 1. Request Phase: Action to Path Resolution
When the app requests a JNAP Action (e.g., `GetRadioInfo`), the mapper identifies the necessary TR-181 data paths.

*   **Logic**: `getTr181Paths(JNAPAction)`
*   **Step 1**: Extract Base Name. The mapper strips version suffixes (e.g., `GetRadioInfo3` → `GetRadioInfo`) to ensure backward compatibility.
*   **Step 2**: Lookup. Uses a predefined registry (`_actionPathMappings`) to find associated paths.
    *   *Example*: `GetRadioInfo` → `['Device.WiFi.']`

### 2. Fetch Phase: USP Execution
The `UspService` executes a standard USP `Get` command using the resolved paths.
*   The raw response contains a list of TR-181 objects (e.g., `Device.WiFi.Radio.1.Enable`).

### 3. Response Phase: Result Mapping
The raw TR-181 data is transformed back into the legacy JNAP JSON format expected by the UI.

*   **Logic**: `toJnapResponse(JNAPAction, UspGetResponse)`
*   **Step 1: Flattening**: The hierarchical USP response is flattened into a key-value map for O(1) access.
    *   *Raw*: `Result(path: "Device.WiFi.Radio.1.Enable", value: "true")`
    *   *Flat Map*: `{"Device.WiFi.Radio.1.Enable": "true"}`
*   **Step 2: Dispatch**: The action name is used to route data to a specific handler (e.g., `_mapRadioInfo`).
*   **Step 3: Transformation**: The handler iterates over the data (often counting entries like `RadioNumberOfEntries`) and constructs the nested JNAP object.
    *   *Example*: Maps `Device.WiFi.Radio.1.OperatingStandards` ("ax") → JSON `{"mode": "802.11ax"}`.

### ✅ Phase 1: Core Connectivity & Basic Settings (Completed)

| JNAP Action (Original) | TR-181 Root Path Used | Handler Method | Status |
| :--- | :--- | :--- | :--- |
| `GetDeviceInfo` | `Device.DeviceInfo.` | `_mapDeviceInfo` | ✅ Done |
| `GetRadioInfo` / `GetRadioInfo3` | `Device.WiFi.Radio.` | `_mapRadioInfo` | ✅ Done |
| `GetDevices` / `GetDevices3` | `Device.Hosts.`, `Device.WiFi.MultiAP.` | `_mapDevices` | ✅ Done |
| `GetBackhaulInfo` / `GetBackhaulInfo2` | `Device.WiFi.MultiAP.APDevice.` | `_mapBackhaulInfo` | ✅ Done |
| `GetWANStatus` / `GetWANStatus3` | `Device.IP.Interface.1.` | `_mapWANSettings` | ✅ Done |
| `GetLANSettings` | `Device.IP.Interface.2.` | `_mapLANSettings` | ✅ Done |
| `GetLocalTime` / `GetTimeSettings` | `Device.Time.` | `_mapTimeSettings` | ✅ Done |
| `GetGuestRadioSettings` / `GetGuestRadioSettings2` | `Device.WiFi.AccessPoint.` | `_mapGuestRadioSettings` | ✅ Done |
| `GetMACFilterSettings` | `Device.WiFi.AccessPoint.` | `_mapMACFilterSettings` | ✅ Done |
| `GetSystemStats2` | `Device.DeviceInfo.` | `_mapSystemStats` | ✅ Done |
| `GetInternetConnectionStatus` | `Device.IP.Interface.1.` | `_mapInternetConnectionStatus` | ✅ Done |
| `GetEthernetPortConnections` | `Device.Ethernet.Interface.` | `_mapEthernetPortConnections` | ✅ Done |

### ⏳ Phase 2 & Future: Pending Actions (Not Yet Mapped)

The following actions exist in the demo data but are not yet converted to USP.

| Category | JNAP Action | Expected TR-181 Path (Tentative) |
| :--- | :--- | :--- |
| **Admin & Security** | `IsAdminPasswordDefault` | `Device.UserInterface.PasswordRequired` |
| | `IsAdminPasswordSetByUser` | N/A (Logic check) |
| | `GetAdminPasswordHint` | `Device.UserInterface.PasswordReset.` |
| **Firmware** | `GetFirmwareUpdateSettings` | `Device.UserInterface.FirmwareUpdate.` |
| | `GetFirmwareUpdateStatus` | `Device.DeviceInfo.FirmwareImage.` |
| **Diagnostics (Nodes)** | `GetDeviceMode` (Master/Slave) | `Device.WiFi.MultiAP.APDevice.{i}.DeviceRole` |
| | `GetLocalDevice` | `Device.LocalAgent.ControllerEndpoint.ID` |
| **Advanced WiFi** | `GetSTABSSIDS` | `Device.WiFi.AccessPoint.{i}.AssociatedDevice.` |
| | `GetNodesWirelessNetworkConnections2` | `Device.WiFi.AccessPoint.{i}.AssociatedDevice.` |
| | `GetNetworkConnections2` | `Device.Hosts.` |
| | `GetMLOSettings` | `Device.WiFi.MultiLink.` |
| | `GetDFSSettings` | `Device.WiFi.Radio.{i}.AutoChannelEnable` |
| | `GetAirtimeFairnessSettings` | `Device.WiFi.Radio.{i}.AirtimeFairness` |
| | `GetTopologyOptimizationSettings2` | `Device.WiFi.MultiAP.Steering.` |
| **Others** | `GetPowerTableSettings` | `Device.WiFi.Radio.{i}.TransmitPower` |
| | `GetSoftSKUSettings` | `Device.DeviceInfo.` |
| | `GetLedNightModeSetting` | `Device.UserInterface.LEDs.` |
| | `GetWANExternal` | `Device.IP.Interface.1.IPv4Address.` |

---

## Field Mapping Details

### 1. Device Info
**Source:** `Device.DeviceInfo.`

| JNAP Field | TR-181 Field | Notes |
| :--- | :--- | :--- |
| `manufacturer` | `.Manufacturer` | - |
| `modelNumber` | `.ModelName` | - |
| `serialNumber` | `.SerialNumber` | - |
| `hardwareVersion` | `.HardwareVersion` | Defaults to "v1.0" |
| `firmwareVersion` | `.SoftwareVersion` | Defaults to "1.0.0" |
| `description` | `.Description` | - |
| `services` | - | Returns empty list (Not in TR-181) |

### 2. Radio Settings (`GetRadioInfo`)
**Source:** `Device.WiFi.Radio.{i}`, `Device.WiFi.SSID.{i}`, `Device.WiFi.AccessPoint.{i}`

| JNAP Field | TR-181 Path/Logic | Notes |
| :--- | :--- | :--- |
| `radioID` | `.Name` | e.g. "RADIO_1" |
| `supportedModes` | `.SupportedStandards` | Maps "b,g,n,ax" -> ["802.11bgnax", ...] |
| `settings.mode` | `.OperatingStandards` | Maps "ax" -> "802.11ax" |
| `settings.channel` | `.Channel` | - |
| `settings.channelWidth` | `.OperatingChannelBandwidth` | "Auto", "Standard" (20MHz), "Wide" (40MHz+) |
| `settings.broadcastSSID` | `AccessPoint.{i}.SSIDAdvertisementEnabled` | - |
| `settings.security` | `AccessPoint.{i}.Security.ModeEnabled` | e.g. "WPA2-Personal" |
| `supportedSecurityTypes` | `AccessPoint.{i}.Security.ModesSupported` | Split CSV string |

### 3. Connected Devices (`GetDevices`)
**Source:** Combined from `Device.Hosts.Host.{i}` (Clients) and `Device.WiFi.MultiAP.APDevice.{i}` (Mesh Nodes).

| JNAP Field | TR-181 (Hosts) | TR-181 (MultiAP) | Notes |
| :--- | :--- | :--- | :--- |
| `deviceID` | `.PhysAddress` | `.MACAddress` | Mesh uses MAC as ID/ALID is invalid |
| `friendlyName` | `.HostName` | "Master Router" / "Mesh Node" | Derived from `BackhaulLinkType` |
| `ipAddress` | `.IPAddress` | - | Mesh IP not directly available in APDevice |
| `isOnline` | `.Active` | `true` | Derived from presence in APDevice table |
| `interfaceType` | `.InterfaceType` | "Infrastructure" | "802.11"-> "Wireless", others "Wired" |
| `parentDeviceID` | - | `.BackhaulMACAddress` | Used to build topology |
| `model.deviceType` | "Computer" | "Infrastructure" | - |

### 4. Backhaul Info (`GetBackhaulInfo`)
**Source:** `Device.WiFi.MultiAP.APDevice.{i}` (Skipping Master where `BackhaulLinkType == None`)

| JNAP Field | TR-181 Field | Logic/Transformation |
| :--- | :--- | :--- |
| `deviceUUID` | `.MACAddress` | - |
| `connectionType` | `.BackhaulLinkType` | "Wi-Fi" -> "Wireless", others -> "Wired" |
| `wirelessConnectionInfo.apRSSI` | `.BackhaulSignalStrength` | `(rssi / 2) - 110` (RCPI to dBm) |
| `wirelessConnectionInfo.apBSSID` | `.BackhaulMACAddress` | - |
| `wirelessConnectionInfo.stationBSSID` | `.MACAddress` | - |
| `ipAddress` | - | Mocked as "192.168.1.x" |

### 5. Time Settings (`GetLocalTime` / `GetTimeSettings`)
**Source:** `Device.Time.`

| JNAP Field | TR-181 Field | Notes |
| :--- | :--- | :--- |
| `currentTime` | `.CurrentLocalTime` | ISO 8601 String |
| `timeZoneID` | `.LocalTimeZone` | e.g. "Asia/Taipei" |
| `ntpServer1` | `.NTPServer1` | - |
| `ntpServer2` | `.NTPServer2` | - |
| `isDaylightSaving` | - | **Hardcoded:** `false` |
| `dstSetting` | - | **Hardcoded:** `Auto` |
| `autoAdjustDST` | - | **Hardcoded:** `true` |

### 6. LAN Settings (`GetLANSettings`)
**Source:** `Device.IP.Interface.2.` (assuming LAN Bridge), `Device.DHCPv4.Server.`

| JNAP Field | TR-181 Field | Notes |
| :--- | :--- | :--- |
| `ipAddress` | `IPv4Address.1.IPAddress` | Default `192.168.1.1` if missing |
| `networkPrefixLength` | `IPv4Address.1.SubnetMask` | Converted from Subnet Mask. |
| `minNetworkPrefixLength` | - | **Hardcoded:** `16` (UI Constraint) |
| `maxNetworkPrefixLength` | - | **Hardcoded:** `30` (UI Constraint) |
| `minAllowedDHCPLeaseMinutes` | - | **Hardcoded:** `1` (UI Constraint) |
| `maxAllowedDHCPLeaseMinutes` | - | **Hardcoded:** `525600` (UI Constraint) |
| `hostName` | `Device.DeviceInfo.HostName` | Default `Linksys01234` |
| `maxDHCPReservationDescriptionLength` | - | **Hardcoded:** `63` (UI Constraint) |
| `isDHCPEnabled` | `Device.DHCPv4.Server.Enable` | Default `true` |
| `dhcpSettings.leaseMinutes` | - | **Hardcoded:** `1440` |
| `dhcpSettings.reservations` | - | **Hardcoded:** `[]` (Empty List) |
| `dhcpSettings.dnsServer1` | - | **Hardcoded:** `8.8.8.8` (Fallback if missing) |
| `dhcpSettings.dnsServer2` | - | **Hardcoded:** `8.8.4.4` (Fallback if missing) |
| `dhcpSettings.lastClientIPAddress` | `Device.DHCPv4.Server.Pool.1.MinAddress` | Default `192.168.1.2` |
| `dhcpSettings.firstClientIPAddress` | `Device.DHCPv4.Server.Pool.1.MinAddress` | Default `192.168.1.100` |

### 7. System Statistics (`GetSystemStats` / `GetSystemStats2`)
**Source:** `Device.DeviceInfo.`

| JNAP Field | TR-181 Field | Notes |
| :--- | :--- | :--- |
| `uptimeSeconds` | `Device.DeviceInfo.UpTime` | Default `0` |
| `CPULoad` | `Device.DeviceInfo.ProcessStatus.CPUUsage` | Calculated: Returns as decimal string `(value / 100).toString()` (e.g. "0.15" for 15%) for UI compatibility. |
| `MemoryLoad` | `MemoryStatus.Total`, `MemoryStatus.Free` | Calculated: `(Total - Free) / Total` formatted to 2 decimals. |

### 8. Ethernet Port Connections (`GetEthernetPortConnections`)
**Source:** `Device.Ethernet.Interface.{i}`

| JNAP Field | TR-181 Field | Notes |
| :--- | :--- | :--- |
| `wanPortConnection` | `Device.Ethernet.Interface.1.MaxBitRate` | Logic: `1000` -> "1Gbps", `100` -> "100Mbps", etc. |
| `lanPortConnections` | `Device.Ethernet.Interface.{i}.MaxBitRate` | **Dynamic Logic:** Iterates from index 3 up to `InterfaceNumberOfEntries`. Checks for existence of data keys to handle deleted/missing ports gracefully. |

### 9. Internet Connection Status (`GetInternetConnectionStatus`)
**Source:** `Device.IP.Interface.1.Status`

| JNAP Field | TR-181 Field | Notes |
| :--- | :--- | :--- |
| `connectionStatus` | `Device.IP.Interface.1.Status` | Reference: `Up` -> "InternetConnected", else "InternetDisconnected". |

### 10. Guest Network (`GetGuestRadioSettings`)
**Source:** `Device.WiFi.AccessPoint.{i}` where `IsolationEnable == true`

| JNAP Field | TR-181 Field | Notes |
| :--- | :--- | :--- |
| `isGuestNetworkEnabled` | - | Derived if any guest AP is enabled |
| `radios[].isEnabled` | `.Enable` | - |
| `radios[].broadcastGuestSSID` | `.SSIDAdvertisementEnabled` | - |
| `radios[].guestPassword` | `.Security.KeyPassphrase` | - |
| `radios[].guestSSID` | `.SSIDReference` | Name not directly in AP object, mocked/inferred |

### 11. MAC Filtering (`GetMACFilterSettings`)
**Source:** `Device.WiFi.AccessPoint.1` (Assumes global setting on main AP)

| JNAP Field | TR-181 Field | Logic |
| :--- | :--- | :--- |
| `isEnabled` | `.MACAddressControlEnabled` | - |
| `macFilterMode` | - | "Allow" if enabled, "Deny" otherwise |
| `macAddresses` | `.AllowedMACAddress` | Split CSV string into List |

### 12. Network Connections (`GetNetworkConnections`)
**Source:** `Device.Hosts.Host.` (Identity) + `Device.WiFi.AccessPoint.{i}.AssociatedDevice.` (Wireless Stats)

| JNAP Field | TR-181 Field | Logic/Notes |
| :--- | :--- | :--- |
| `connections[].macAddress` | `Hosts.Host.PhysAddress` | - |
| `connections[].ipAddress` | `Hosts.Host.IPAddress` | - |
| `connections[].negotiatedMbps` | `.AssociatedDevice.LastDataDownlinkRate` | Converted Kbps -> Mbps. Wired defaults to 1000. |
| `connections[].wireless.signalDecibels` | `.AssociatedDevice.SignalStrength` | Found by matching MAC in AssociatedDevice table. |
| `connections[].wireless.bssid` | `SSID.{i}.MACAddress` | Mapped to MAC of the SSID (not the reference path). |
| `connections[].wireless.txRate` | `.AssociatedDevice.LastDataDownlinkRate` | Raw Kbps value. |
| `connections[].wireless.rxRate` | `.AssociatedDevice.LastDataDownlinkRate` | Mocked as symmetric (same as txRate). |
| `connections[].wireless.isMLOCapable` | - | **Hardcoded:** `false` |
| `connections[].wireless.band` | Derived | Inferred from AP Index (1=2.4G, 2=5G, 3=6G). |

### 13. Node Wireless Connections (`GetNodesWirelessNetworkConnections`)
**Source:** `Device.WiFi.MultiAP.APDevice.` (Master ID) + `Device.WiFi.AccessPoint.{i}.AssociatedDevice.` (Connections)

- **Aggregation Logic:** Maps all local `AssociatedDevice` entries under the Master Node's ID found in MultiAP data (BackhaulLinkType == None).

| JNAP Field | TR-181 Field | Logic/Notes |
| :--- | :--- | :--- |
| `deviceID` | `MultiAP.APDevice.MACAddress` | Master Node ID |
| `connections[].macAddress` | `AssociatedDevice.MACAddress` | - |
| `connections[].negotiatedMbps` | `AssociatedDevice.LastDataDownlinkRate` | - |
| `connections[].wireless.signalDecibels` | `AssociatedDevice.SignalStrength` | - |
| `connections[].wireless.bssid` | `SSID.{i}.MACAddress` | Mapped to MAC of the SSID. |
| `connections[].wireless.txRate` | `AssociatedDevice.LastDataDownlinkRate` | Raw Kbps value. |
| `connections[].wireless.rxRate` | `AssociatedDevice.LastDataDownlinkRate` | Mocked as symmetric. |
| `connections[].wireless.isMLOCapable` | - | **Hardcoded:** `false` |




---

## Limitations & Mocking behavior
- **Mock IPs**: Backhaul objects in TR-181 `APDevice` do not natively expose IP addresses; simulated "192.168.1.x" IPs are used.
- **Time**: DST settings are hardcoded as `autoAdjustDST: true` as TR-181 Time object is simple.
- **WAN IPv6**: Hardcoded as "Disconnected" for this POC.

---

> Generated by Antigravity Agent
