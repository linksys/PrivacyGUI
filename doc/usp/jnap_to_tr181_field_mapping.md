# JNAP to TR-181 Field-Level Mapping Reference

**Purpose:** USP migration reference for PrivacyGUI developers

**Sources:**
- `jnap_used_api_spec.md` — JNAP API spec (request/response definitions)
- `spec/tr-181-2-20-1-usp.html` — TR-181 Device:2.20 Data Model
- `jnap_tr181_mapping.md` — JNAP to TR-181 mapping reference

**Statistics:**
- Total JNAP actions: 134
- Actions with field-level mapping: 76
- Actions requiring Vendor Extension: 56

---

## How to Read This Document

### Mapping Status

| Status | Meaning |
|--------|--------|
| **Direct** | JNAP fields map directly to TR-181 parameters |
| **Partial** | Requires combining multiple TR-181 objects or value transformation |
| **Custom** | Requires Vendor Extension (`X_LINKSYS_COM_*`) — marked but not defined |
| **N/A** | No TR-181 equivalent exists |

### Field Mapping Table Columns

| Column | Description |
|--------|------------|
| **JNAP Field** | Field name in JNAP request/response |
| **JNAP Type** | Data type in JNAP spec |
| **TR-181 Path** | Full TR-181 parameter path (`{i}` = instance number) |
| **TR-181 Type** | Data type in TR-181 spec |
| **Access** | TR-181 access mode: R (read), W (write), RW (read-write) |

### TR-181 Multi-Instance Convention

`{i}` in TR-181 paths represents an instance number (e.g., `Device.WiFi.Radio.1.`, `Device.WiFi.Radio.2.`). In USP, use partial path `Device.WiFi.Radio.` to query all instances.

### USP Command Convention

JNAP actions that map to TR-181 commands are shown with `()` suffix (e.g., `Device.Reboot()`). In USP, these are invoked via the `Operate` message. Async commands deliver results via `OperationComplete` notification.

---

## Summary Table

| # | JNAP Action | TR-181 Primary Object | Status |
|---|-------------|----------------------|--------|
| 1 | `GetDeviceInfo` | `Device.DeviceInfo.` | Direct |
| 2 | `CheckAdminPassword3` | `Device.Users.User.{i}.Password` | Partial |
| 3 | `SetAdminPassword3` | `Device.Users.User.{i}.Password` | Partial |
| 4 | `SetAdminPassword2` | `Device.Users.User.{i}.Password` | Partial |
| 5 | `GetAdminPasswordHint` | `X_LINKSYS_COM_PasswordHint` | Custom |
| 6 | `GetAdminPasswordAuthStatus` | `—` | Partial |
| 7 | `IsAdminPasswordDefault` | `X_LINKSYS_COM_IsDefaultPassword` | Custom |
| 8 | `Reboot2` | `Device.Reboot()` | Direct |
| 9 | `FactoryReset2` | `Device.FactoryReset()` | Direct |
| 10 | `Transaction` | `—` | — |
| 11 | `GetRadioInfo3` | `Device.WiFi.Radio.{i}.` | Direct |
| 12 | `SetRadioSettings3` | `Device.WiFi.Radio.{i}.` | Direct |
| 13 | `GetSimpleWiFiSettings` | `Device.WiFi.SSID.{i}.` | Partial |
| 14 | `SetSimpleWiFiSettings` | `Device.WiFi.SSID.{i}.` | Partial |
| 15 | `GetGuestRadioSettings2` | `Device.WiFi.SSID.{i}.` | Partial |
| 16 | `SetGuestRadioSettings2` | `Device.WiFi.SSID.{i}.` | Partial |
| 17 | `GetGuestNetworkSettings2` | `Device.WiFi.AccessPoint.{i}.`, `Device.DHCPv4.Server.Pool.{i}.` | Partial |
| 18 | `SetGuestNetworkSettings3` | `Device.WiFi.AccessPoint.{i}.` | Partial |
| 19 | `GetGuestNetworkClients` | `Device.WiFi.AccessPoint.{i}.AssociatedDevice.{i}.` | Direct |
| 20 | `ClientDeauth` | `Device.WiFi.AccessPoint.{i}.AssociatedDevice.{i}.MACAddress` | Partial |
| 21 | `GetMLOSettings` | `Vendor Extension` | Custom |
| 22 | `SetMLOSettings` | `Vendor Extension` | Custom |
| 23 | `GetDFSSettings` | `Device.WiFi.Radio.{i}.RegulatoryDomain` | Partial |
| 24 | `SetDFSSettings` | `Vendor Extension` | Custom |
| 25 | `GetAirtimeFairnessSettings` | `Vendor Extension` | Custom |
| 26 | `SetAirtimeFairnessSettings` | `Vendor Extension` | Custom |
| 27 | `GetWANSettings5` | `Device.IP.Interface.{i}.` | Partial |
| 28 | `SetWANSettings4` | `Device.IP.Interface.{i}.` | Partial |
| 29 | `GetWANStatus3` | `Device.IP.Interface.{i}.Status` | Direct |
| 30 | `GetWANExternal` | `Device.IP.Interface.{i}.IPv4Address.{i}.` | Partial |
| 31 | `GetLANSettings` | `Device.DHCPv4.Server.Pool.{i}.` | Partial |
| 32 | `SetLANSettings` | `Device.DHCPv4.Server.Pool.{i}.` | Partial |
| 33 | `GetIPv6Settings2` | `Device.IP.Interface.{i}.IPv6Address.{i}.` | Direct |
| 34 | `SetIPv6Settings2` | `Device.IP.Interface.{i}.IPv6Address.{i}.` | Direct |
| 35 | `RenewDHCPWANLease` | `Device.DHCPv4.Client.{i}.Renew()` | Direct |
| 36 | `RenewDHCPIPv6WANLease` | `Device.DHCPv6.Client.{i}.Renew()` | Direct |
| 37 | `GetMACAddressCloneSettings` | `Device.Ethernet.Interface.{i}.MACAddress` | Partial |
| 38 | `SetMACAddressCloneSettings` | `—` | Custom |
| 39 | `GetRoutingSettings` | `Device.Routing.Router.{i}.IPv4Forwarding.{i}.` | Direct |
| 40 | `SetRoutingSettings` | `Device.Routing.Router.{i}.IPv4Forwarding.{i}.` | Direct |
| 41 | `GetEthernetPortConnections` | `Device.Ethernet.Interface.{i}.` | Direct |
| 42 | `GetExpressForwardingSettings` | `Vendor Extension` | Custom |
| 43 | `SetExpressForwardingSettings` | `Vendor Extension` | Custom |
| 44 | `GetFirewallSettings` | `Device.Firewall.` | Partial |
| 45 | `SetFirewallSettings` | `Device.Firewall.` | Partial |
| 46 | `GetDMZSettings` | `Device.Firewall.DMZ.{i}.` | Direct |
| 47 | `SetDMZSettings` | `Device.Firewall.DMZ.{i}.` | Direct |
| 48 | `GetSinglePortForwardingRules` | `Device.NAT.PortMapping.{i}.` | Direct |
| 49 | `SetSinglePortForwardingRules` | `Device.NAT.PortMapping.{i}.` | Direct |
| 50 | `GetPortRangeForwardingRules` | `Device.NAT.PortMapping.{i}.` | Direct |
| 51 | `SetPortRangeForwardingRules` | `Device.NAT.PortMapping.{i}.` | Direct |
| 52 | `GetPortRangeTriggeringRules` | `Device.NAT.PortTrigger.{i}.` | Direct |
| 53 | `SetPortRangeTriggeringRules` | `Device.NAT.PortTrigger.{i}.` | Direct |
| 54 | `GetIPv6FirewallRules` | `Device.Firewall.Chain.{i}.Rule.{i}.` | Partial |
| 55 | `SetIPv6FirewallRules` | `Device.Firewall.Chain.{i}.Rule.{i}.` | Partial |
| 56 | `GetALGSettings` | `Device.Firewall.ConnectionTracking.` | Direct |
| 57 | `SetALGSettings` | `Device.Firewall.ConnectionTracking.` | Direct |
| 58 | `GetDevices3` | `Device.Hosts.Host.{i}.` | Direct |
| 59 | `GetLocalDevice` | `Device.Hosts.Host.{i}.` | Partial |
| 60 | `SetDeviceProperties` | `Device.Hosts.Host.{i}.` | Partial |
| 61 | `DeleteDevice` | `Device.Hosts.Host.{i}.` | N/A |
| 62 | `GetNetworkConnections2` | `Device.WiFi.AccessPoint.{i}.AssociatedDevice.{i}.`, `Device.Ethernet.Interface.{i}.` | Partial |
| 63 | `GetNodesWirelessNetworkConnections2` | `Device.WiFi.MultiAP.APDevice.{i}.` | Partial |
| 64 | `GetBackhaulInfo2` | `Device.WiFi.DataElements.Network.Device.{i}.` | Partial |
| 65 | `GetFirmwareUpdateSettings` | `Vendor Extension` | Custom |
| 66 | `SetFirmwareUpdateSettings` | `—` | Custom |
| 67 | `GetFirmwareUpdateStatus` | `Device.DeviceInfo.FirmwareImage.{i}.Status` | Partial |
| 68 | `UpdateFirmwareNow` | `Vendor Extension` | Custom |
| 69 | `GetDDNSSettings` | `Device.DynamicDNS.Client.{i}.` | Direct |
| 70 | `SetDDNSSettings` | `Device.DynamicDNS.Client.{i}.Enable` | Partial |
| 71 | `GetDDNSStatus2` | `Device.DynamicDNS.Client.{i}.Status` | Direct |
| 72 | `GetSupportedDDNSProviders` | `Vendor Extension` | Custom |
| 73 | `GetVPNUser` | `Vendor Extension` | Custom |
| 74 | `SetVPNUser` | `Vendor Extension` | Custom |
| 75 | `GetVPNGateway` | `Vendor Extension` | Custom |
| 76 | `SetVPNGateway` | `Vendor Extension` | Custom |
| 77 | `GetVPNService` | `Vendor Extension` | Custom |
| 78 | `SetVPNService` | `Vendor Extension` | Custom |
| 79 | `TestVPNConnection` | `Vendor Extension` | Custom |
| 80 | `GetTunneledUser` | `Vendor Extension` | Custom |
| 81 | `SetTunneledUser` | `Vendor Extension` | Custom |
| 82 | `SetVPNApply` | `Vendor Extension` | Custom |
| 83 | `StartPing` | `Device.IP.Diagnostics.IPPing()` | Direct |
| 84 | `GetPingStatus` | `Device.IP.Diagnostics.IPPing()` | Direct |
| 85 | `StopPing` | `Vendor Extension` | Custom |
| 86 | `StartTraceroute` | `Device.IP.Diagnostics.TraceRoute() → Input.Host` | Partial |
| 87 | `GetTracerouteStatus` | `Device.IP.Diagnostics.TraceRoute()` | Direct |
| 88 | `StopTraceroute` | `Vendor Extension` | Custom |
| 89 | `GetSystemStats2` | `Device.DeviceInfo.ProcessStatus.` | Partial |
| 90 | `RunHealthCheck` | `Device.IP.Diagnostics.SpeedTest.` | Partial |
| 91 | `GetHealthCheckStatus` | `Vendor Extension` | Custom |
| 92 | `GetHealthCheckResults` | `Vendor Extension` | Custom |
| 93 | `GetSupportedHealthCheckModules` | `Vendor Extension` | Custom |
| 94 | `GetCloseHealthCheckServers` | `Vendor Extension` | Custom |
| 95 | `StopHealthCheck` | `Vendor Extension` | Custom |
| 96 | `GetLocalTime` | `Device.Time.CurrentLocalTime` | Direct |
| 97 | `GetTimeSettings` | `Device.Time.` | Partial |
| 98 | `SetTimeSettings` | `Device.Time.` | Partial |
| 99 | `GetMACFilterSettings` | `Device.WiFi.AccessPoint.{i}.X_LINKSYS_COM_MACFilter.` | Custom |
| 100 | `SetMACFilterSettings` | `—` | Custom |
| 101 | `GetSTABSSIDS` | `—` | Partial |
| 102 | `IsAdminPasswordSetByUser` | `Vendor Extension` | Custom |
| 103 | `GetAutoConfigurationSettings` | `Vendor Extension` | Custom |
| 104 | `VerifyRouterResetCode` | `Vendor Extension` | Custom |
| 105 | `GetInternetConnectionStatus` | `Device.IP.Interface.{i}.Status` | Partial |
| 106 | `GetMACAddress` | `Device.Ethernet.Interface.{i}.MACAddress` | Partial |
| 107 | `StartBlinkingNodeLed` | `Vendor Extension` | Custom |
| 108 | `StopBlinkingNodeLed` | `Vendor Extension` | Custom |
| 109 | `SetUserAcknowledgedAutoConfiguration` | `Vendor Extension` | Custom |
| 110 | `GetSelectedChannels` | `Device.WiFi.Radio.{i}.Channel` | Direct |
| 111 | `StartAutoChannelSelection` | `Device.WiFi.Radio.{i}.AutoChannelEnable` | Partial |
| 112 | `StartBluetoothAutoOnboarding2` | `Vendor Extension` | Custom |
| 113 | `GetBluetoothAutoOnboardingStatus2` | `Vendor Extension` | Custom |
| 114 | `GetBluetoothAutoOnboardingSettings` | `Vendor Extension` | Custom |
| 115 | `SetBluetoothAutoOnboardingSettings` | `Vendor Extension` | Custom |
| 116 | `GetWiredAutoOnboardingSettings` | `Vendor Extension` | Custom |
| 117 | `SetWiredAutoOnboardingSettings` | `Vendor Extension` | Custom |
| 118 | `GetManagementSettings2` | `Device.UserInterface.` | Partial |
| 119 | `SetManagementSettings2` | `Device.UserInterface.` | Partial |
| 120 | `GetUPnPSettings` | `Device.UPnP.Device.Enable` | Direct |
| 121 | `SetUPnPSettings` | `Device.UPnP.Device.Enable` | Direct |
| 122 | `GetLedNightModeSetting` | `Vendor Extension` | Custom |
| 123 | `SetLedNightModeSetting2` | `Vendor Extension` | Custom |
| 124 | `GetTopologyOptimizationSettings2` | `Device.WiFi.MultiAP.` | Partial |
| 125 | `SetTopologyOptimizationSettings2` | `Vendor Extension` | Custom |
| 126 | `GetDeviceMode` | `Vendor Extension` | Custom |
| 127 | `SetDeviceMode` | `Vendor Extension` | Custom |
| 128 | `GetPowerTableSettings` | `Vendor Extension` | Custom |
| 129 | `SetPowerTableSettings` | `Vendor Extension` | Custom |
| 130 | `GetSoftSKUSettings` | `Vendor Extension` | Custom |
| 131 | `GetQoSSettings2` | `Device.QoS.Classification.{i}.` | Partial |
| 132 | `GetIPTVSettings` | `Vendor Extension` | Custom |
| 133 | `SetIPTVSettings` | `Vendor Extension` | Custom |
| 134 | `SetRemoteSetting` | `Vendor Extension` | Custom |

---

## 1. Core

### GetDeviceInfo

**Endpoint:** `http://linksys.com/jnap/core/GetDeviceInfo`

**Status:** Direct

**TR-181 Object(s):** `Device.DeviceInfo.`, `Device.DeviceInfo.Manufacturer`, `Device.DeviceInfo.ModelName`, `Device.DeviceInfo.SerialNumber`, `Device.DeviceInfo.HardwareVersion`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ manufacturer | string | `Device.DeviceInfo.Manufacturer` | string(:64) | R |
| ⇐ modelNumber | string | `Device.DeviceInfo.ModelName` | string(:64) | R |
| ⇐ hardwareVersion | string | `Device.DeviceInfo.HardwareVersion` | string(:64) | R |
| ⇐ description | string | `Device.DeviceInfo.Description` | string(:256) | R |
| ⇐ serialNumber | string | `Device.DeviceInfo.SerialNumber` | string(:64) | R |
| ⇐ firmwareVersion | string | `Device.DeviceInfo.SoftwareVersion` | string(:64) | R |
| ⇐ firmwareDate | DateTime | `—` | — | — |
| ⇐ services | string[] | `—` | — | — |

### CheckAdminPassword3

**Endpoint:** `http://linksys.com/jnap/core/CheckAdminPassword3`

**Status:** Partial

**TR-181 Object(s):** `Device.Users.User.{i}.Password`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ adminPassword | string | `Device.Users.User.{i}.Password` | string(:64) | W |
| ⇐ isPasswordValid | bool | `—` | — | — |
| ⇐ attemptsRemaining | int | `—` | — | — |
| ⇐ delayTimeRemaining | int | `—` | — | — |

### SetAdminPassword3

**Endpoint:** `http://linksys.com/jnap/core/SetAdminPassword3`

**Status:** Partial

**TR-181 Object(s):** `Device.Users.User.{i}.Password`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ adminPassword | string | `Device.Users.User.{i}.Password` | string(:64) | W |
| ⇒ passwordHint | string | `—` | — | — |

### SetAdminPassword2

**Endpoint:** `http://linksys.com/jnap/nodes/setup/SetAdminPassword2`

**Status:** Partial

**TR-181 Object(s):** `Device.Users.User.{i}.Password`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ isResetCodeValid | bool | `—` | — | — |
| ⇐ attemptsRemaining | int | `—` | — | — |
| ⇐ lockoutExpirationTime | DateTime | `—` | — | — |
| ⇐ isLockoutIndefinite | bool | `—` | — | — |
| ⇒ resetCode | string | `—` | — | — |
| ⇒ adminPassword | string | `Device.Users.User.{i}.Password` | string(:64) | W |
| ⇒ passwordHint | string | `—` | — | — |

### GetAdminPasswordHint

**Endpoint:** `http://linksys.com/jnap/core/GetAdminPasswordHint`

**Status:** Custom

**TR-181 Object(s):** `X_LINKSYS_COM_PasswordHint`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ passwordHint | string | `X_LINKSYS_COM_PasswordHint` | — | — |

### GetAdminPasswordAuthStatus

**Endpoint:** `http://linksys.com/jnap/core/GetAdminPasswordAuthStatus`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ attemptsRemaining | int | `—` | — | — |
| ⇐ delayTimeRemaining | int | `—` | — | — |

### IsAdminPasswordDefault

**Endpoint:** `http://linksys.com/jnap/core/IsAdminPasswordDefault`

**Status:** Custom

**TR-181 Object(s):** `X_LINKSYS_COM_IsDefaultPassword`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ isAdminPasswordDefault | bool | `X_LINKSYS_COM_IsDefaultPassword` | — | — |

### Reboot2

**Endpoint:** `http://linksys.com/jnap/core/Reboot2`

**Status:** Direct

**TR-181 Object(s):** `Device.Reboot()`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ deviceUUID | UUID | `—` | — | — |

### FactoryReset2

**Endpoint:** `http://linksys.com/jnap/core/FactoryReset2`

**Status:** Direct

**TR-181 Object(s):** `Device.FactoryReset()`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ deviceUUID | UUID | `—` | — | — |

### Transaction

> Action spec not available in `jnap_full.md`

---

## 2. WiFi / Wireless AP

### GetRadioInfo3

**Endpoint:** `http://linksys.com/jnap/wirelessap/GetRadioInfo3`

**Status:** Direct

**TR-181 Object(s):** `Device.WiFi.Radio.{i}.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ supportedBandSteeringModes | BandSteeringMode[] | `—` | — | — |
| ⇐ isBandSteeringEnabled | bool | `—` | — | — |
| ⇐ bandSteeringMode | BandSteeringMode | `—` | — | — |
| ⇐ isBandSteeringSupported | bool | `—` | — | — |
| ⇐ radios | RadioInfo2[] | `Device.WiFi.Radio.{i}.` | object(0:) | R |

**Structure: `RadioInfo2`**

| JNAP Field | TR-181 Path | TR-181 Type | Access |
|------------|-------------|-------------|--------|
| radioID | `Device.WiFi.Radio.{i}.` | object(0:) | R |
| physicalRadioID | `Device.WiFi.Radio.{i}.` | object(0:) | R |
| band | `Device.WiFi.Radio.{i}.OperatingFrequencyBand` | string | W |
| supportedModes | `Device.WiFi.Radio.{i}.OperatingStandards` | string[] | W |
| channelWidth | `Device.WiFi.Radio.{i}.OperatingChannelBandwidth` | string | W |
| channel | `Device.WiFi.Radio.{i}.Channel` | unsignedInt(1:255) | W |
| isEnabled | `Device.WiFi.Radio.{i}.Enable` | boolean | W |
| supportedChannelWidths | `Device.WiFi.Radio.{i}.SupportedOperatingChannelBandwidths` | string[] | R |
| supportedChannelsForChannelWidths | `Device.WiFi.Radio.{i}.PossibleChannels` | string[](:1024) | R |

### SetRadioSettings3

**Endpoint:** `http://linksys.com/jnap/wirelessap/SetRadioSettings3`

**Status:** Direct

**TR-181 Object(s):** `Device.WiFi.Radio.{i}.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ isBandSteeringEnabled | bool | `—` | — | — |
| ⇒ bandSteeringMode | BandSteeringMode | `—` | — | — |
| ⇒ radios | NewRadioSettings[] | `Device.WiFi.Radio.{i}.` | object(0:) | R |

### GetSimpleWiFiSettings

**Endpoint:** `http://linksys.com/jnap/nodes/setup/GetSimpleWiFiSettings`

**Status:** Partial

**TR-181 Object(s):** `Device.WiFi.SSID.{i}.`, `Device.WiFi.SSID.{i}.SSID`, `Device.WiFi.AccessPoint.{i}.Security.ModeEnabled`, `Device.WiFi.AccessPoint.{i}.Security.PreSharedKey`

> **Note:** See WiFi section above

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ simpleWiFiSettings | SimpleWiFiSettings[] | `—` | — | — |

### SetSimpleWiFiSettings

**Endpoint:** `http://linksys.com/jnap/nodes/setup/SetSimpleWiFiSettings`

**Status:** Partial

**TR-181 Object(s):** `Device.WiFi.SSID.{i}.`

> **Note:** See WiFi section above

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ simpleWiFiSettings | SimpleWiFiSettings[] | `—` | — | — |

### GetGuestRadioSettings2

**Endpoint:** `http://linksys.com/jnap/guestnetwork/GetGuestRadioSettings2`

**Status:** Partial

**TR-181 Object(s):** `Device.WiFi.SSID.{i}.`

> **Note:** Guest network SSID instances

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ isGuestNetworkACaptivePortal | bool | `—` | — | — |
| ⇐ isGuestNetworkEnabled | bool | `—` | — | — |
| ⇐ radios | GuestRadioSettings2[] | `Device.WiFi.SSID.{i}.` | object(0:) | W |
| ⇐ maxSimultaneousGuests | int | `—` | — | — |
| ⇐ guestPasswordRestrictions | GuestPasswordRestrictions | `—` | — | — |
| ⇐ maxSimultaneousGuestsLimit | int | `—` | — | — |

### SetGuestRadioSettings2

**Endpoint:** `http://linksys.com/jnap/guestnetwork/SetGuestRadioSettings2`

**Status:** Partial

**TR-181 Object(s):** `Device.WiFi.SSID.{i}.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ isGuestNetworkEnabled | bool | `—` | — | — |
| ⇒ radios | GuestRadioSettings2[] | `Device.WiFi.SSID.{i}.` | object(0:) | W |
| ⇒ maxSimultaneousGuests | int | `—` | — | — |

### GetGuestNetworkSettings2

**Endpoint:** `http://linksys.com/jnap/guestnetwork/GetGuestNetworkSettings2`

**Status:** Partial

**TR-181 Object(s):** `Device.WiFi.AccessPoint.{i}.`, `Device.DHCPv4.Server.Pool.{i}.`

> **Note:** v2 adds LAN/DHCP settings for guest network

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ ipAddress | IPAddress | `Device.IP.Interface.{i}.IPv4Address.{i}.IPAddress` | string(:45) | W |
| ⇐ networkPrefixLength | int | `Device.IP.Interface.{i}.IPv4Address.{i}.SubnetMask` | string(:45) | W |
| ⇐ minNetworkPrefixLength | int | `—` | — | — |
| ⇐ maxNetworkPrefixLength | int | `—` | — | — |
| ⇐ minAllowedLeaseHours | int | `—` | — | — |
| ⇐ maxAllowedLeaseHours | int | `—` | — | — |
| ⇐ leaseHours | int | `Device.DHCPv4.Server.Pool.{i}.LeaseTime` | int(-1:) | W |

### SetGuestNetworkSettings3

**Endpoint:** `http://linksys.com/jnap/guestnetwork/SetGuestNetworkSettings3`

**Status:** Partial

**TR-181 Object(s):** `Device.WiFi.AccessPoint.{i}.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ isGuestNetworkEnabled | bool | `Device.WiFi.AccessPoint.{i}.Enable` | boolean | W |
| ⇒ broadcastGuestSSID | bool | `—` | — | — |
| ⇒ guestSSID | string | `—` | — | — |
| ⇒ guestPassword | string | `—` | — | — |
| ⇒ maxSimultaneousGuests | int | `—` | — | — |

### GetGuestNetworkClients

**Endpoint:** `http://linksys.com/jnap/guestnetwork/GetGuestNetworkClients`

**Status:** Direct

**TR-181 Object(s):** `Device.WiFi.AccessPoint.{i}.AssociatedDevice.{i}.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ clients | AuthorizedClient[] | `Device.WiFi.AccessPoint.{i}.AssociatedDevice.{i}.` | object(0:) | R |

### ClientDeauth

**Endpoint:** `http://linksys.com/jnap/wirelessap/ClientDeauth`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ macAddress | MACAddress | `—` | — | — |

### GetMLOSettings

**Endpoint:** `http://linksys.com/jnap/wirelessap/GetMLOSettings`

**Status: Custom** — Requires Vendor Extension (X_LINKSYS_COM_WiFi.MLO)

### SetMLOSettings

**Endpoint:** `http://linksys.com/jnap/wirelessap/SetMLOSettings`

**Status: Custom** — Requires Vendor Extension (X_LINKSYS_COM_WiFi.MLO)

### GetDFSSettings

**Endpoint:** `http://linksys.com/jnap/wirelessap/GetDFSSettings`

**Status:** Partial

**TR-181 Object(s):** `Device.WiFi.Radio.{i}.RegulatoryDomain`

> **Note:** Partially maps to Device.WiFi.Radio.{i}.RegulatoryDomain

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ isDFSSupported | bool | `—` | — | — |
| ⇐ isDFSEnabled | bool | `—` | — | — |

### SetDFSSettings

**Endpoint:** `http://linksys.com/jnap/wirelessap/SetDFSSettings`

**Status: Custom** — Requires Vendor Extension

### GetAirtimeFairnessSettings

**Endpoint:** `http://linksys.com/jnap/wirelessap/GetAirtimeFairnessSettings`

**Status: Custom** — Requires Vendor Extension (X_LINKSYS_COM_AirtimeFairness)

### SetAirtimeFairnessSettings

**Endpoint:** `http://linksys.com/jnap/wirelessap/SetAirtimeFairnessSettings`

**Status: Custom** — Requires Vendor Extension (X_LINKSYS_COM_AirtimeFairness)

---

## 3. Router

### GetWANSettings5

**Endpoint:** `http://linksys.com/jnap/router/GetWANSettings5`

**Status:** Partial

**TR-181 Object(s):** `Device.IP.Interface.{i}.`, `Device.PPP.Interface.{i}.`

> **Note:** WAN type determines which TR-181 objects are relevant. v5 adds wirelessModeSettings and wanTaggingSettings

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ wanType | WANType | `Device.IP.Interface.{i}.IPv4Address.{i}.AddressingType` | string | R |
| ⇐ pppoeSettings | PPPoESettings | `Device.PPP.Interface.{i}.` | object(0:) | W |
| ⇐ tpSettings | TPSettings | `—` | — | — |
| ⇐ telstraSettings | TelstraSettings | `—` | — | — |
| ⇐ staticSettings | StaticSettings | `—` | — | — |
| ⇐ bridgeSettings | BridgeSettings | `—` | — | — |
| ⇐ dsliteSettings | DSLiteSettings | `—` | — | — |
| ⇐ wirelessModeSettings | WirelessModeSettings | `—` | — | — |
| ⇐ domainName | string | `—` | — | — |
| ⇐ mtu | int | `—` | — | — |
| ⇐ wanTaggingSettings | SinglePortVLANTaggingSettings2 | `—` | — | — |

### SetWANSettings4

**Endpoint:** `http://linksys.com/jnap/router/SetWANSettings4`

**Status:** Partial

**TR-181 Object(s):** `Device.IP.Interface.{i}.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ redirection | UIRedirection | `—` | — | — |
| ⇒ wanType | WANType | `Device.IP.Interface.{i}.IPv4Address.{i}.AddressingType` | string | R |
| ⇒ pppoeSettings | PPPoESettings | `—` | — | — |
| ⇒ tpSettings | TPSettings | `—` | — | — |
| ⇒ telstraSettings | TelstraSettings | `—` | — | — |
| ⇒ staticSettings | StaticSettings | `—` | — | — |
| ⇒ bridgeSettings | BridgeSettings | `—` | — | — |
| ⇒ dsliteSettings | DSLiteSettings | `—` | — | — |
| ⇒ wirelessModeSettings | WirelessModeSettings | `—` | — | — |
| ⇒ mtu | int | `—` | — | — |
| ⇒ wanTaggingSettings | SinglePortVLANTaggingSettings | `—` | — | — |

### GetWANStatus3

**Endpoint:** `http://linksys.com/jnap/router/GetWANStatus3`

**Status:** Direct

**TR-181 Object(s):** `Device.IP.Interface.{i}.Status`, `Device.IP.Interface.{i}.IPv4Address.{i}.IPAddress`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ supportedWANTypes | WANType[] | `—` | — | — |
| ⇐ supportedIPv6WANTypes | WANIPv6Type2[] | `—` | — | — |
| ⇐ supportedWANCombinations | SupportedWANCombination[] | `—` | — | — |
| ⇐ supportedWirelessModeSecurities | SupportedWirelessModeSecurities[] | `—` | — | — |
| ⇐ isDetectingWANType | bool | `—` | — | — |
| ⇐ detectedWANType | WANType | `—` | — | — |
| ⇐ wanStatus | WANStatus | `Device.IP.Interface.{i}.Status` | string | R |
| ⇐ wanConnection | WANConnectionInfo | `Device.IP.Interface.{i}.` | object(0:) | W |
| ⇐ state | PPPConnectionState | `—` | — | — |
| ⇐ wanIPv6Status | WANStatus | `—` | — | — |
| ⇐ linkLocalIPv6Address | IPv6Address | `—` | — | — |
| ⇐ lanPrefixAddress | IPv6Address | `—` | — | — |
| ⇐ wanIPv6Connection | WANIPv6ConnectionInfo2 | `—` | — | — |
| ⇐ wirelessConnection | WirelessConnectionInfo | `—` | — | — |
| ⇐ macAddress | MACAddress | `—` | — | — |

### GetWANExternal

**Endpoint:** `http://linksys.com/jnap/router/GetWANExternal`

**Status:** Partial

**TR-181 Object(s):** `Device.IP.Interface.{i}.IPv4Address.{i}.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ PublicWanIPv4 | IPAddress | `—` | — | — |
| ⇐ PublicWanIPv6 | IPv6Address | `—` | — | — |
| ⇐ PrivateWanIPv4 | IPAddress | `—` | — | — |
| ⇐ PrivateWanIPv6 | IPv6Address | `—` | — | — |

### GetLANSettings

**Endpoint:** `http://linksys.com/jnap/router/GetLANSettings`

**Status:** Partial

**TR-181 Object(s):** `Device.DHCPv4.Server.Pool.{i}.`, `Device.DHCPv4.Server.Pool.{i}.MinAddress`, `Device.DHCPv4.Server.Pool.{i}.MaxAddress`, `Device.IP.Interface.{i}.IPv4Address.{i}.IPAddress`, `Device.IP.Interface.{i}.IPv4Address.{i}.SubnetMask`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ ipAddress | IPAddress | `Device.IP.Interface.{i}.IPv4Address.{i}.IPAddress` | string(:45) | W |
| ⇐ networkPrefixLength | int | `Device.IP.Interface.{i}.IPv4Address.{i}.SubnetMask` | string(:45) | W |
| ⇐ minNetworkPrefixLength | int | `—` | — | — |
| ⇐ maxNetworkPrefixLength | int | `—` | — | — |
| ⇐ hostName | string | `—` | — | — |
| ⇐ minAllowedDHCPLeaseMinutes | int | `—` | — | — |
| ⇐ maxAllowedDHCPLeaseMinutes | int | `—` | — | — |
| ⇐ maxDHCPReservationDescriptionLength | int | `—` | — | — |
| ⇐ isDHCPEnabled | bool | `Device.DHCPv4.Server.Pool.{i}.Enable` | boolean | W |
| ⇐ dhcpSettings | DHCPSettings | `—` | — | — |

### SetLANSettings

**Endpoint:** `http://linksys.com/jnap/router/SetLANSettings`

**Status:** Partial

**TR-181 Object(s):** `Device.DHCPv4.Server.Pool.{i}.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ ipAddress | IPAddress | `Device.IP.Interface.{i}.IPv4Address.{i}.IPAddress` | string(:45) | W |
| ⇒ Address | Description | `—` | — | — |
| ⇒ networkPrefixLength | int | `—` | — | — |
| ⇒ hostName | string | `—` | — | — |
| ⇒ isDHCPEnabled | bool | `—` | — | — |
| ⇒ dhcpSettings | DHCPSettings | `—` | — | — |

### GetIPv6Settings2

**Endpoint:** `http://linksys.com/jnap/router/GetIPv6Settings2`

**Status:** Direct

**TR-181 Object(s):** `Device.IP.Interface.{i}.IPv6Address.{i}.`, `Device.DHCPv6.Client.{i}.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ wanType | WANIPv6Type2 | `—` | — | — |
| ⇐ ipv6AutomaticSettings | IPv6AutomaticSettings | `—` | — | — |
| ⇐ duid | string | `Device.DHCPv6.Client.{i}.DUID` | hexBinary(:130) | R |

### SetIPv6Settings2

**Endpoint:** `http://linksys.com/jnap/router/SetIPv6Settings2`

**Status:** Direct

**TR-181 Object(s):** `Device.IP.Interface.{i}.IPv6Address.{i}.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ wanType | WANIPv6Type2 | `—` | — | — |
| ⇒ ipv6AutomaticSettings | IPv6AutomaticSettings | `—` | — | — |

### RenewDHCPWANLease

**Endpoint:** `http://linksys.com/jnap/router/RenewDHCPWANLease`

**Status:** Direct

**TR-181 Object(s):** `Device.DHCPv4.Client.{i}.Renew()`

### RenewDHCPIPv6WANLease

**Endpoint:** `http://linksys.com/jnap/router/RenewDHCPIPv6WANLease`

**Status:** Direct

**TR-181 Object(s):** `Device.DHCPv6.Client.{i}.Renew()`

### GetMACAddressCloneSettings

**Endpoint:** `http://linksys.com/jnap/router/GetMACAddressCloneSettings`

**Status:** Partial

**TR-181 Object(s):** `Device.Ethernet.Interface.{i}.MACAddress`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ isMACAddressCloneEnabled | bool | `X_LINKSYS_COM_MACClone.Enable` | — | — |
| ⇐ macAddress | MACAddress | `Device.Ethernet.Interface.{i}.MACAddress` | string(:17) | R |

### SetMACAddressCloneSettings

**Endpoint:** `http://linksys.com/jnap/router/SetMACAddressCloneSettings`

**Status:** Custom

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ isMACAddressCloneEnabled | bool | `—` | — | — |
| ⇒ macAddress | MACAddress | `—` | — | — |

### GetRoutingSettings

**Endpoint:** `http://linksys.com/jnap/router/GetRoutingSettings`

**Status:** Direct

**TR-181 Object(s):** `Device.Routing.Router.{i}.IPv4Forwarding.{i}.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ isNATEnabled | bool | `—` | — | — |
| ⇐ isDynamicRoutingEnabled | bool | `—` | — | — |
| ⇐ entries | NamedStaticRouteEntry[] | `Device.Routing.Router.{i}.IPv4Forwarding.{i}.` | object(0:) | W |
| ⇐ maxStaticRouteEntries | int | `—` | — | — |

### SetRoutingSettings

**Endpoint:** `http://linksys.com/jnap/router/SetRoutingSettings`

**Status:** Direct

**TR-181 Object(s):** `Device.Routing.Router.{i}.IPv4Forwarding.{i}.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ isNATEnabled | bool | `—` | — | — |
| ⇒ isDynamicRoutingEnabled | bool | `—` | — | — |
| ⇒ entries | NamedStaticRouteEntry[] | `Device.Routing.Router.{i}.IPv4Forwarding.{i}.` | object(0:) | W |

### GetEthernetPortConnections

**Endpoint:** `http://linksys.com/jnap/router/GetEthernetPortConnections`

**Status:** Direct

**TR-181 Object(s):** `Device.Ethernet.Interface.{i}.`, `Device.Ethernet.Interface.{i}.Status`, `Device.Ethernet.Interface.{i}.DuplexMode`, `Device.Ethernet.Interface.{i}.CurrentBitRate`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ wanPortConnection | EthernetPortConnection | `—` | — | — |
| ⇐ lanPortConnections | EthernetPortConnection[] | `—` | — | — |

**Structure: `EthernetPortConnection`**

| JNAP Field | TR-181 Path | TR-181 Type | Access |
|------------|-------------|-------------|--------|
| portName | `Device.Ethernet.Interface.{i}.Name` | string(:64) | R |
| connectionState | `Device.Ethernet.Interface.{i}.Status` | string | R |
| speedMbps | `Device.Ethernet.Interface.{i}.CurrentBitRate` | unsignedInt | R |
| duplexMode | `Device.Ethernet.Interface.{i}.DuplexMode` | string | W |

### GetExpressForwardingSettings

**Endpoint:** `http://linksys.com/jnap/router/GetExpressForwardingSettings`

**Status: Custom** — Requires Vendor Extension

### SetExpressForwardingSettings

**Endpoint:** `http://linksys.com/jnap/router/SetExpressForwardingSettings`

**Status: Custom** — Requires Vendor Extension

---

## 4. Firewall

### GetFirewallSettings

**Endpoint:** `http://linksys.com/jnap/firewall/GetFirewallSettings`

**Status:** Partial

**TR-181 Object(s):** `Device.Firewall.`, `Device.Firewall.Enable`, `Device.Firewall.Policy.{i}.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ isIPv4FirewallEnabled | bool | `—` | — | — |
| ⇐ isIPv6FirewallEnabled | bool | `—` | — | — |
| ⇐ blockMulticast | bool | `Device.Firewall.Policy.{i}.` | object(0:) | W |
| ⇐ blockNATRedirection | bool | `—` | — | — |
| ⇐ blockIDENT | bool | `—` | — | — |
| ⇐ blockAnonymousRequests | bool | `Device.Firewall.Policy.{i}.` | object(0:) | W |
| ⇐ blockIPSec | bool | `Device.Firewall.Policy.{i}.` | object(0:) | W |
| ⇐ blockPPTP | bool | `—` | — | — |
| ⇐ blockL2TP | bool | `—` | — | — |

### SetFirewallSettings

**Endpoint:** `http://linksys.com/jnap/firewall/SetFirewallSettings`

**Status:** Partial

**TR-181 Object(s):** `Device.Firewall.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ isIPv4FirewallEnabled | bool | `—` | — | — |
| ⇒ isIPv6FirewallEnabled | bool | `—` | — | — |
| ⇒ blockMulticast | bool | `—` | — | — |
| ⇒ blockNATRedirection | bool | `—` | — | — |
| ⇒ blockIDENT | bool | `—` | — | — |
| ⇒ blockAnonymousRequests | bool | `—` | — | — |
| ⇒ blockIPSec | bool | `—` | — | — |
| ⇒ blockPPTP | bool | `—` | — | — |
| ⇒ blockL2TP | bool | `—` | — | — |

### GetDMZSettings

**Endpoint:** `http://linksys.com/jnap/firewall/GetDMZSettings`

**Status:** Direct

**TR-181 Object(s):** `Device.Firewall.DMZ.{i}.`, `Device.Firewall.DMZ.{i}.Enable`, `Device.Firewall.DMZ.{i}.DestIPAddress`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ isDMZEnabled | bool | `Device.Firewall.DMZ.{i}.Enable` | boolean | W |
| ⇐ sourceRestriction | DMZSourceRestriction | `Device.Firewall.DMZ.{i}.` | object(0:) | W |
| ⇐ destinationIPAddress | IPAddress | `Device.Firewall.DMZ.{i}.DestIPAddress` | — | — |
| ⇐ Address | Description | `—` | — | — |
| ⇐ destinationMACAddress | MACAddress | `—` | — | — |

### SetDMZSettings

**Endpoint:** `http://linksys.com/jnap/firewall/SetDMZSettings`

**Status:** Direct

**TR-181 Object(s):** `Device.Firewall.DMZ.{i}.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ isDMZEnabled | bool | `Device.Firewall.DMZ.{i}.Enable` | boolean | W |
| ⇒ sourceRestriction | DMZSourceRestriction | `—` | — | — |
| ⇒ destinationIPAddress | IPAddress | `Device.Firewall.DMZ.{i}.DestIPAddress` | — | — |
| ⇒ Address | Description | `—` | — | — |
| ⇒ destinationMACAddress | MACAddress | `—` | — | — |
| ⇒ Address | Description | `—` | — | — |

### GetSinglePortForwardingRules

**Endpoint:** `http://linksys.com/jnap/firewall/GetSinglePortForwardingRules`

**Status:** Direct

**TR-181 Object(s):** `Device.NAT.PortMapping.{i}.`, `Device.NAT.PortMapping.{i}.ExternalPort`, `Device.NAT.PortMapping.{i}.InternalPort`, `Device.NAT.PortMapping.{i}.InternalClient`, `Device.NAT.PortMapping.{i}.Protocol`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ rules | SinglePortForwardingRule[] | `Device.NAT.PortMapping.{i}.` | object(0:) | W |
| ⇐ maxDescriptionLength | int | `—` | — | — |
| ⇐ maxRules | int | `—` | — | — |

**Structure: `SinglePortForwardingRule`**

| JNAP Field | TR-181 Path | TR-181 Type | Access |
|------------|-------------|-------------|--------|
| isEnabled | `Device.NAT.PortMapping.{i}.Enable` | boolean | W |
| externalPort | `Device.NAT.PortMapping.{i}.ExternalPort` | unsignedInt(0:65535) | W |
| protocol | `Device.NAT.PortMapping.{i}.Protocol` | string | W |
| internalServerIPAddress | `Device.NAT.PortMapping.{i}.InternalClient` | string(:256) | W |
| internalPort | `Device.NAT.PortMapping.{i}.InternalPort` | unsignedInt(0:65535) | W |
| description | `Device.NAT.PortMapping.{i}.Description` | string(:256) | W |

### SetSinglePortForwardingRules

**Endpoint:** `http://linksys.com/jnap/firewall/SetSinglePortForwardingRules`

**Status:** Direct

**TR-181 Object(s):** `Device.NAT.PortMapping.{i}.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ rules | SinglePortForwardingRule[] | `Device.NAT.PortMapping.{i}.` | object(0:) | W |

### GetPortRangeForwardingRules

**Endpoint:** `http://linksys.com/jnap/firewall/GetPortRangeForwardingRules`

**Status:** Direct

**TR-181 Object(s):** `Device.NAT.PortMapping.{i}.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ rules | PortRangeForwardingRule[] | `Device.NAT.PortMapping.{i}.` | object(0:) | W |
| ⇐ maxDescriptionLength | int | `—` | — | — |
| ⇐ maxRules | int | `—` | — | — |

**Structure: `PortRangeForwardingRule`**

| JNAP Field | TR-181 Path | TR-181 Type | Access |
|------------|-------------|-------------|--------|
| isEnabled | `Device.NAT.PortMapping.{i}.Enable` | boolean | W |
| firstExternalPort | `Device.NAT.PortMapping.{i}.ExternalPort` | unsignedInt(0:65535) | W |
| lastExternalPort | `Device.NAT.PortMapping.{i}.ExternalPortEndRange` | unsignedInt(0:65535) | W |
| protocol | `Device.NAT.PortMapping.{i}.Protocol` | string | W |
| internalServerIPAddress | `Device.NAT.PortMapping.{i}.InternalClient` | string(:256) | W |
| description | `Device.NAT.PortMapping.{i}.Description` | string(:256) | W |

### SetPortRangeForwardingRules

**Endpoint:** `http://linksys.com/jnap/firewall/SetPortRangeForwardingRules`

**Status:** Direct

**TR-181 Object(s):** `Device.NAT.PortMapping.{i}.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ rules | PortRangeForwardingRule[] | `Device.NAT.PortMapping.{i}.` | object(0:) | W |

### GetPortRangeTriggeringRules

**Endpoint:** `http://linksys.com/jnap/firewall/GetPortRangeTriggeringRules`

**Status:** Direct

**TR-181 Object(s):** `Device.NAT.PortTrigger.{i}.`, `Device.NAT.PortTrigger.{i}.Rule.{i}.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ rules | PortRangeTriggeringRule[] | `Device.NAT.PortTrigger.{i}.` | object(0:) | W |
| ⇐ maxDescriptionLength | int | `—` | — | — |
| ⇐ maxRules | int | `—` | — | — |

### SetPortRangeTriggeringRules

**Endpoint:** `http://linksys.com/jnap/firewall/SetPortRangeTriggeringRules`

**Status:** Direct

**TR-181 Object(s):** `Device.NAT.PortTrigger.{i}.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ rules | PortRangeTriggeringRule[] | `Device.NAT.PortTrigger.{i}.` | object(0:) | W |

### GetIPv6FirewallRules

**Endpoint:** `http://linksys.com/jnap/firewall/GetIPv6FirewallRules`

**Status:** Partial

**TR-181 Object(s):** `Device.Firewall.Chain.{i}.Rule.{i}.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ rules | IPv6FirewallRule[] | `Device.Firewall.Chain.{i}.Rule.{i}.` | object(0:) | W |
| ⇐ maxPortRanges | int | `—` | — | — |
| ⇐ maxDescriptionLength | int | `—` | — | — |
| ⇐ maxRules | int | `—` | — | — |

### SetIPv6FirewallRules

**Endpoint:** `http://linksys.com/jnap/firewall/SetIPv6FirewallRules`

**Status:** Partial

**TR-181 Object(s):** `Device.Firewall.Chain.{i}.Rule.{i}.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ rules | IPv6FirewallRule[] | `Device.Firewall.Chain.{i}.Rule.{i}.` | object(0:) | W |

### GetALGSettings

**Endpoint:** `http://linksys.com/jnap/firewall/GetALGSettings`

**Status:** Direct

**TR-181 Object(s):** `Device.Firewall.ConnectionTracking.`, `Device.Firewall.ConnectionTracking.SIP.Enable`, `Device.Firewall.ConnectionTracking.H323.Enable`, `Device.Firewall.ConnectionTracking.FTP.Enable`

> **Note:** JNAP only exposes SIP. TR-181 also has H323, FTP, IRC, PPTP, TFTP under ConnectionTracking.

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ isSIPEnabled | bool | `Device.Firewall.ConnectionTracking.SIP.Enable` | boolean | W |

### SetALGSettings

**Endpoint:** `http://linksys.com/jnap/firewall/SetALGSettings`

**Status:** Direct

**TR-181 Object(s):** `Device.Firewall.ConnectionTracking.`

> **Note:** JNAP only exposes SIP. TR-181 also has H323, FTP, IRC, PPTP, TFTP under ConnectionTracking.

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ isSIPEnabled | bool | `Device.Firewall.ConnectionTracking.SIP.Enable` | boolean | W |

---

## 5. Device List

### GetDevices3

**Endpoint:** `http://linksys.com/jnap/devicelist/GetDevices3`

**Status:** Direct

**TR-181 Object(s):** `Device.Hosts.Host.{i}.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ revision | int | `—` | — | — |
| ⇐ devices | Device2[] | `Device.Hosts.Host.{i}.` | object(0:) | R |
| ⇐ deletedDeviceIDs | UUID[] | `—` | — | — |
| ⇐ ErrorInfo | string | `—` | — | — |
| ⇒ deviceIDs | UUID[] | `—` | — | — |
| ⇒ sinceRevision | int | `—` | — | — |

**Structure: `Device2`**

| JNAP Field | TR-181 Path | TR-181 Type | Access |
|------------|-------------|-------------|--------|
| deviceID | `Device.Hosts.Host.{i}.PhysAddress` | string(:64) | R |
| friendlyName | `Device.Hosts.Host.{i}.HostName` | string(:64) | R |
| ipAddress | `Device.Hosts.Host.{i}.IPAddress` | string(:45) | R |
| macAddress | `Device.Hosts.Host.{i}.PhysAddress` | string(:64) | R |
| isActive | `Device.Hosts.Host.{i}.Active` | boolean | R |
| interface | `Device.Hosts.Host.{i}.Layer1Interface` | string(:256) | R |

### GetLocalDevice

**Endpoint:** `http://linksys.com/jnap/devicelist/GetLocalDevice`

**Status:** Partial

**TR-181 Object(s):** `Device.Hosts.Host.{i}.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ deviceID | UUID | `—` | — | — |
| ⇐ ErrorInfo | string | `—` | — | — |

### SetDeviceProperties

**Endpoint:** `http://linksys.com/jnap/devicelist/SetDeviceProperties`

**Status:** Partial

**TR-181 Object(s):** `Device.Hosts.Host.{i}.`

> **Note:** Partial: custom properties need Vendor Extension

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ deviceID | UUID | `—` | — | — |
| ⇒ propertiesToRemove | string[] | `—` | — | — |
| ⇒ propertiesToModify | Property[] | `—` | — | — |

### DeleteDevice

**Endpoint:** `http://linksys.com/jnap/devicelist/DeleteDevice`

**Status:** N/A

**TR-181 Object(s):** `Device.Hosts.Host.{i}.`

> **Note:** N/A: TR-181 does not support deleting Host entries

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ deviceID | UUID | `—` | — | — |

---

## 6. Network Connections

### GetNetworkConnections2

**Endpoint:** `http://linksys.com/jnap/networkconnections/GetNetworkConnections2`

**Status:** Partial

**TR-181 Object(s):** `Device.WiFi.AccessPoint.{i}.AssociatedDevice.{i}.`, `Device.Ethernet.Interface.{i}.`

> **Note:** Combines WiFi AssociatedDevice + Ethernet Interface

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ connections | Layer2Connection2[] | `Device.WiFi.AccessPoint.{i}.AssociatedDevice.{i}.` | object(0:) | R |
| ⇒ macAddresses | MACAddress[] | `—` | — | — |

### GetNodesWirelessNetworkConnections2

**Endpoint:** `http://linksys.com/jnap/nodes/networkconnections/GetNodesWirelessNetworkConnections2`

**Status:** Partial

**TR-181 Object(s):** `Device.WiFi.MultiAP.APDevice.{i}.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ lastTriggered | DateTime | `—` | — | — |
| ⇐ nodeWirelessConnections | NodeWirelessConnection2[] | `—` | — | — |
| ⇒ macAddresses | MACAddress[] | `—` | — | — |
| ⇒ deviceIDs | UUID[] | `—` | — | — |

### GetBackhaulInfo2

**Endpoint:** `http://linksys.com/jnap/nodes/diagnostics/GetBackhaulInfo2`

**Status:** Partial

**TR-181 Object(s):** `Device.WiFi.DataElements.Network.Device.{i}.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ backhaulDevices | BackhaulDeviceInfo2[] | `Device.WiFi.DataElements.Network.Device.{i}.` | object(1:) | R |

---

## 7. Firmware Update

### GetFirmwareUpdateSettings

**Endpoint:** `http://linksys.com/jnap/firmwareupdate/GetFirmwareUpdateSettings`

**Status: Custom** — Partial: auto-update settings need Vendor Extension

### SetFirmwareUpdateSettings

**Endpoint:** `http://linksys.com/jnap/firmwareupdate/SetFirmwareUpdateSettings`

**Status:** Custom

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ updatePolicy | FirmwareUpdatePolicy | `X_LINKSYS_COM_FirmwareUpdate.Policy` | — | — |
| ⇒ autoUpdateWindow | FirmwareAutoUpdateWindow | `—` | — | — |

### GetFirmwareUpdateStatus

**Endpoint:** `http://linksys.com/jnap/nodes/firmwareupdate/GetFirmwareUpdateStatus`

**Status:** Partial

**TR-181 Object(s):** `Device.DeviceInfo.FirmwareImage.{i}.Status`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ firmwareUpdateStatus | NodeFirmwareUpdateStatus[] | `—` | — | — |

### UpdateFirmwareNow

**Endpoint:** `http://linksys.com/jnap/nodes/firmwareupdate/UpdateFirmwareNow`

**Status: Custom** — Requires Vendor Extension or Device.LocalAgent.Request.{i}.

---

## 8. DDNS

### GetDDNSSettings

**Endpoint:** `http://linksys.com/jnap/ddns/GetDDNSSettings`

**Status:** Direct

**TR-181 Object(s):** `Device.DynamicDNS.Client.{i}.`, `Device.DynamicDNS.Client.{i}.Enable`, `Device.DynamicDNS.Client.{i}.Server`, `Device.DynamicDNS.Client.{i}.Username`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ ddnsProvider | DDNSProvider | `—` | — | — |
| ⇐ dynDNSSettings | DynDNSSettings | `—` | — | — |
| ⇐ tzoSettings | TZOSettings | `—` | — | — |
| ⇐ noipSettings | NoIPSettings | `—` | — | — |

### SetDDNSSettings

**Endpoint:** `http://linksys.com/jnap/ddns/SetDDNSSettings`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ ddnsProvider | DDNSProvider | `—` | — | — |
| ⇒ dynDNSSettings | DynDNSSettings | `—` | — | — |
| ⇒ tzoSettings | TZOSettings | `—` | — | — |
| ⇒ noipSettings | NoIPSettings | `—` | — | — |

### GetDDNSStatus2

**Endpoint:** `http://linksys.com/jnap/ddns/GetDDNSStatus2`

**Status:** Direct

**TR-181 Object(s):** `Device.DynamicDNS.Client.{i}.Status`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ status | DDNSStatus2 | `Device.DynamicDNS.Client.{i}.Status` | string | R |

### GetSupportedDDNSProviders

**Endpoint:** `http://linksys.com/jnap/ddns/GetSupportedDDNSProviders`

**Status: Custom** — Requires Vendor Extension

---

## 9. VPN

### GetVPNUser

> **Status: Custom** — Requires Vendor Extension (X_LINKSYS_COM_VPN.User.{i}.)

### SetVPNUser

> **Status: Custom** — Requires Vendor Extension

### GetVPNGateway

> **Status: Custom** — Requires Vendor Extension; partial map to Device.IPsec.Tunnel.{i}.

### SetVPNGateway

> **Status: Custom** — Requires Vendor Extension

### GetVPNService

> **Status: Custom** — Requires Vendor Extension; partial map to Device.IPsec.

### SetVPNService

> **Status: Custom** — Requires Vendor Extension

### TestVPNConnection

> **Status: Custom** — Requires Vendor Extension

### GetTunneledUser

> **Status: Custom** — Requires Vendor Extension (X_LINKSYS_COM_VPN.TunneledUser.{i}.)

### SetTunneledUser

> **Status: Custom** — Requires Vendor Extension

### SetVPNApply

> **Status: Custom** — Requires Vendor Extension

---

## 10. Diagnostics & Health Check

### StartPing

**Endpoint:** `http://linksys.com/jnap/diagnostics/StartPing`

**Status:** Direct

**TR-181 Object(s):** `Device.IP.Diagnostics.IPPing()`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ host | string | `Device.IP.Diagnostics.IPPing() → Input.Host` | — | — |
| ⇒ packetSizeBytes | int | `Device.IP.Diagnostics.IPPing() → Input.DataBlockSize` | — | — |
| ⇒ pingCount | int | `Device.IP.Diagnostics.IPPing() → Input.NumberOfRepetitions` | — | — |

### GetPingStatus

**Endpoint:** `http://linksys.com/jnap/diagnostics/GetPingStatus`

**Status:** Direct

**TR-181 Object(s):** `Device.IP.Diagnostics.IPPing()`

> **Note:** Result delivered via OperationComplete notification

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ isRunning | bool | `—` | — | — |
| ⇐ pingLog | string | `—` | — | — |

### StopPing

**Endpoint:** `http://linksys.com/jnap/diagnostics/StopPing`

**Status: Custom** — TR-181 does not directly support canceling IPPing

### StartTraceroute

**Endpoint:** `http://linksys.com/jnap/diagnostics/StartTraceroute`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ host | string | `Device.IP.Diagnostics.TraceRoute() → Input.Host` | — | — |

### GetTracerouteStatus

**Endpoint:** `http://linksys.com/jnap/diagnostics/GetTracerouteStatus`

**Status:** Direct

**TR-181 Object(s):** `Device.IP.Diagnostics.TraceRoute()`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ isRunning | bool | `—` | — | — |
| ⇐ tracerouteLog | string | `—` | — | — |

### StopTraceroute

**Endpoint:** `http://linksys.com/jnap/diagnostics/StopTraceroute`

**Status: Custom** — TR-181 does not directly support canceling TraceRoute

### GetSystemStats2

**Endpoint:** `http://linksys.com/jnap/diagnostics/GetSystemStats2`

**Status:** Partial

**TR-181 Object(s):** `Device.DeviceInfo.ProcessStatus.`, `Device.DeviceInfo.ProcessStatus.CPUUsage`, `Device.DeviceInfo.MemoryStatus.Total`, `Device.DeviceInfo.MemoryStatus.Free`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ uptimeSeconds | int | `Device.DeviceInfo.UpTime` | unsignedInt | R |
| ⇐ CPULoad | string | `Device.DeviceInfo.ProcessStatus.CPUUsage` | unsignedInt(0:100) | R |
| ⇐ MemoryLoad | string | `Device.DeviceInfo.MemoryStatus.Free` | unsignedInt | R |

### RunHealthCheck

**Endpoint:** `http://linksys.com/jnap/healthcheck/RunHealthCheck`

**Status:** Partial

**TR-181 Object(s):** `Device.IP.Diagnostics.SpeedTest.`

> **Note:** Partial: maps to Device.IP.Diagnostics.SpeedTest.

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ resultID | long | `—` | — | — |
| ⇒ runHealthCheckModule | SupportedHealthCheckModule | `—` | — | — |
| ⇒ targetServerID | string | `—` | — | — |

### GetHealthCheckStatus

**Endpoint:** `http://linksys.com/jnap/healthcheck/GetHealthCheckStatus`

**Status: Custom** — Requires Vendor Extension

### GetHealthCheckResults

**Endpoint:** `http://linksys.com/jnap/healthcheck/GetHealthCheckResults`

**Status: Custom** — Requires Vendor Extension

### GetSupportedHealthCheckModules

**Endpoint:** `http://linksys.com/jnap/healthcheck/GetSupportedHealthCheckModules`

**Status: Custom** — Requires Vendor Extension

### GetCloseHealthCheckServers

**Endpoint:** `http://linksys.com/jnap/healthcheck/GetCloseHealthCheckServers`

**Status: Custom** — Requires Vendor Extension

### StopHealthCheck

**Endpoint:** `http://linksys.com/jnap/healthcheck/StopHealthCheck`

**Status: Custom** — Requires Vendor Extension

---

## 11. Time & Locale

### GetLocalTime

**Endpoint:** `http://linksys.com/jnap/locale/GetLocalTime`

**Status:** Direct

**TR-181 Object(s):** `Device.Time.CurrentLocalTime`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ currentTime | string | `—` | — | — |

### GetTimeSettings

**Endpoint:** `http://linksys.com/jnap/locale/GetTimeSettings`

**Status:** Partial

**TR-181 Object(s):** `Device.Time.`, `Device.Time.Enable`, `Device.Time.Client.{i}.Server`, `Device.Time.LocalTimeZone`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ timeZoneID | string | `—` | — | — |
| ⇐ autoAdjustForDST | bool | `Device.Time.DaylightSaving.Enable` | — | — |
| ⇐ supportedTimeZones | TimeZone[] | `—` | — | — |
| ⇐ currentTime | DateTime | `—` | — | — |

### SetTimeSettings

**Endpoint:** `http://linksys.com/jnap/locale/SetTimeSettings`

**Status:** Partial

**TR-181 Object(s):** `Device.Time.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ timeZoneID | string | `—` | — | — |
| ⇒ autoAdjustForDST | bool | `—` | — | — |

---

## 12. MAC Filter

### GetMACFilterSettings

**Endpoint:** `http://linksys.com/jnap/macfilter/GetMACFilterSettings`

**Status:** Custom

**TR-181 Object(s):** `Device.WiFi.AccessPoint.{i}.X_LINKSYS_COM_MACFilter.`, `Device.Hosts.AccessControl.{i}.`

> **Note:** Also partially maps to X_LINKSYS_COM_MACFilter

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ macFilterMode | MACFilterMode | `Device.Hosts.AccessControl.{i}.` | object(0:) | W |
| ⇐ macAddresses | MACAddress[] | `—` | — | — |
| ⇐ maxMACAddresses | int | `—` | — | — |

### SetMACFilterSettings

**Endpoint:** `http://linksys.com/jnap/macfilter/SetMACFilterSettings`

**Status:** Custom

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ macFilterMode | MACFilterMode | `Device.Hosts.AccessControl.{i}.` | object(0:) | W |
| ⇒ macAddresses | MACAddress[] | `—` | — | — |

### GetSTABSSIDS

**Endpoint:** `http://linksys.com/jnap/macfilter/GetSTABSSIDS`

> **Note:** Returns SSIDs for MAC filter configuration

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ staBSSIDS | MACAddress[] | `—` | — | — |

---

## 13. Setup & Onboarding

### IsAdminPasswordSetByUser

**Endpoint:** `http://linksys.com/jnap/nodes/setup/IsAdminPasswordSetByUser`

**Status: Custom** — Requires Vendor Extension (X_LINKSYS_COM_Setup.PasswordConfigured)

### GetAutoConfigurationSettings

**Endpoint:** `http://linksys.com/jnap/nodes/setup/GetAutoConfigurationSettings`

**Status: Custom** — Requires Vendor Extension

### VerifyRouterResetCode

**Endpoint:** `http://linksys.com/jnap/nodes/setup/VerifyRouterResetCode`

**Status: Custom** — Requires Vendor Extension

### GetInternetConnectionStatus

**Endpoint:** `http://linksys.com/jnap/nodes/setup/GetInternetConnectionStatus`

**Status:** Partial

**TR-181 Object(s):** `Device.IP.Interface.{i}.Status`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ connectionStatus | InternetConnectionStatus | `Device.IP.Interface.{i}.Status` | string | R |

### GetMACAddress

**Endpoint:** `http://linksys.com/jnap/nodes/setup/GetMACAddress`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ macAddress | MACAddress | `Device.Ethernet.Interface.{i}.MACAddress` | string(:17) | R |

### StartBlinkingNodeLed

**Endpoint:** `http://linksys.com/jnap/nodes/setup/StartBlinkingNodeLed`

**Status: Custom** — Requires Vendor Extension

### StopBlinkingNodeLed

**Endpoint:** `http://linksys.com/jnap/nodes/setup/StopBlinkingNodeLed`

**Status: Custom** — Requires Vendor Extension

### SetUserAcknowledgedAutoConfiguration

**Endpoint:** `http://linksys.com/jnap/nodes/setup/SetUserAcknowledgedAutoConfiguration`

**Status: Custom** — Requires Vendor Extension

### GetSelectedChannels

**Endpoint:** `http://linksys.com/jnap/nodes/setup/GetSelectedChannels`

**Status:** Direct

**TR-181 Object(s):** `Device.WiFi.Radio.{i}.Channel`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ isRunning | bool | `—` | — | — |
| ⇐ selectedChannels | SelectedChannels[] | `—` | — | — |

### StartAutoChannelSelection

**Endpoint:** `http://linksys.com/jnap/nodes/setup/StartAutoChannelSelection`

**Status:** Partial

**TR-181 Object(s):** `Device.WiFi.Radio.{i}.AutoChannelEnable`

---

## 14. Auto Onboarding

### StartBluetoothAutoOnboarding2

**Endpoint:** `http://linksys.com/jnap/nodes/autoonboarding/StartBluetoothAutoOnboarding2`

**Status: Custom** — Requires Vendor Extension

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ macAddresses | MACAddress[] | `—` | — | — |

### GetBluetoothAutoOnboardingStatus2

**Endpoint:** `http://linksys.com/jnap/nodes/autoonboarding/GetBluetoothAutoOnboardingStatus2`

**Status: Custom** — Requires Vendor Extension

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ autoOnboardingStatus | BTAutoOnboardingStatus2 | `—` | — | — |
| ⇐ deviceOnboardingStatus | BTDeviceOnboardingStatus[] | `—` | — | — |

### GetBluetoothAutoOnboardingSettings

**Endpoint:** `http://linksys.com/jnap/nodes/autoonboarding/GetBluetoothAutoOnboardingSettings`

**Status: Custom** — Requires Vendor Extension

### SetBluetoothAutoOnboardingSettings

**Endpoint:** `http://linksys.com/jnap/nodes/autoonboarding/SetBluetoothAutoOnboardingSettings`

**Status: Custom** — Requires Vendor Extension

### GetWiredAutoOnboardingSettings

**Endpoint:** `http://linksys.com/jnap/nodes/autoonboarding/GetWiredAutoOnboardingSettings`

**Status: Custom** — Requires Vendor Extension

### SetWiredAutoOnboardingSettings

**Endpoint:** `http://linksys.com/jnap/nodes/autoonboarding/SetWiredAutoOnboardingSettings`

**Status: Custom** — Requires Vendor Extension

---

## 15. Administration

### GetManagementSettings2

**Endpoint:** `http://linksys.com/jnap/routermanagement/GetManagementSettings2`

**Status:** Partial

**TR-181 Object(s):** `Device.UserInterface.`, `Device.UserInterface.RemoteAccess.Enable`, `Device.UserInterface.RemoteAccess.Port`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ canManageUsingHTTP | bool | `Device.UserInterface.RemoteAccess.SupportedProtocols` | — | — |
| ⇐ canManageUsingHTTPS | bool | `—` | — | — |
| ⇐ isManageWirelesslySupported | bool | `—` | — | — |
| ⇐ canManageWirelessly | bool | `—` | — | — |
| ⇐ canManageRemotely | bool | `—` | — | — |

### SetManagementSettings2

**Endpoint:** `http://linksys.com/jnap/routermanagement/SetManagementSettings2`

**Status:** Partial

**TR-181 Object(s):** `Device.UserInterface.`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ canManageUsingHTTP | bool | `—` | — | — |
| ⇒ canManageUsingHTTPS | bool | `—` | — | — |
| ⇒ canManageWirelessly | bool | `—` | — | — |
| ⇒ canManageRemotely | bool | `—` | — | — |

### GetUPnPSettings

**Endpoint:** `http://linksys.com/jnap/routerupnp/GetUPnPSettings`

**Status:** Direct

**TR-181 Object(s):** `Device.UPnP.Device.Enable`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ isUPnPEnabled | bool | `Device.UPnP.Device.Enable` | boolean | W |
| ⇐ canUsersConfigure | bool | `—` | — | — |
| ⇐ canUsersDisableWANAccess | bool | `—` | — | — |

### SetUPnPSettings

**Endpoint:** `http://linksys.com/jnap/routerupnp/SetUPnPSettings`

**Status:** Direct

**TR-181 Object(s):** `Device.UPnP.Device.Enable`

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ isUPnPEnabled | bool | `Device.UPnP.Device.Enable` | boolean | W |
| ⇒ canUsersConfigure | bool | `—` | — | — |
| ⇒ canUsersDisableWANAccess | bool | `—` | — | — |

### GetLedNightModeSetting

**Endpoint:** `http://linksys.com/jnap/routerleds/GetLedNightModeSetting`

**Status: Custom** — Requires Vendor Extension (X_LINKSYS_COM_LED.NightMode)

### SetLedNightModeSetting2

**Endpoint:** `http://linksys.com/jnap/routerleds/SetLedNightModeSetting2`

**Status: Custom** — Requires Vendor Extension (X_LINKSYS_COM_LED.NightMode)

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ Enable | bool | `—` | — | — |
| ⇒ StartingTime | int | `—` | — | — |
| ⇒ EndingTime | int | `—` | — | — |

---

## 16. Topology & Smart Mode

### GetTopologyOptimizationSettings2

**Endpoint:** `http://linksys.com/jnap/nodes/topologyoptimization/GetTopologyOptimizationSettings2`

**Status:** Partial

**TR-181 Object(s):** `Device.WiFi.MultiAP.`

> **Note:** v2 adds isNodeSteeringEnabled

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ isClientSteeringEnabled | bool | `—` | — | — |
| ⇐ isNodeSteeringEnabled | bool | `—` | — | — |

### SetTopologyOptimizationSettings2

**Endpoint:** `http://linksys.com/jnap/nodes/topologyoptimization/SetTopologyOptimizationSettings2`

**Status: Custom** — Requires Vendor Extension

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇒ isClientSteeringEnabled | bool | `—` | — | — |
| ⇒ isNodeSteeringEnabled | bool | `—` | — | — |

### GetDeviceMode

**Endpoint:** `http://linksys.com/jnap/nodes/smartmode/GetDeviceMode`

**Status: Custom** — Requires Vendor Extension (X_LINKSYS_COM_SmartMode)

### SetDeviceMode

**Endpoint:** `http://linksys.com/jnap/nodes/smartmode/SetDeviceMode`

**Status: Custom** — Requires Vendor Extension (X_LINKSYS_COM_SmartMode)

---

## 17. Other

### GetPowerTableSettings

**Endpoint:** `http://linksys.com/jnap/powertable/GetPowerTableSettings`

**Status: Custom** — Requires Vendor Extension

### SetPowerTableSettings

**Endpoint:** `http://linksys.com/jnap/powertable/SetPowerTableSettings`

**Status: Custom** — Requires Vendor Extension

### GetSoftSKUSettings

**Endpoint:** `http://linksys.com/jnap/product/GetSoftSKUSettings`

**Status: Custom** — Requires Vendor Extension

### GetQoSSettings2

**Endpoint:** `http://linksys.com/jnap/qos/GetQoSSettings2`

**Status:** Partial

**TR-181 Object(s):** `Device.QoS.Classification.{i}.`

> **Note:** v2 adds auto-assigned rules

**Field Mapping:**

| JNAP Field | JNAP Type | TR-181 Path | TR-181 Type | Access |
|------------|-----------|-------------|-------------|--------|
| ⇐ maxAutoAssignedDeviceRules | int | `—` | — | — |
| ⇐ maxAutoAssignedApplicationRules | int | `—` | — | — |
| ⇐ autoAssignedDeviceRules | QoSDeviceRule[] | `—` | — | — |
| ⇐ autoAssignedApplicationRules | QoSApplicationRule[] | `—` | — | — |

### GetIPTVSettings

> **Status: Custom** — Requires Vendor Extension (spec not in jnap_full.md)

### SetIPTVSettings

> **Status: Custom** — Requires Vendor Extension (spec not in jnap_full.md)

### SetRemoteSetting

**Endpoint:** `http://linksys.com/jnap/ui/SetRemoteSetting`

**Status: Custom** — Requires Vendor Extension

---

## Appendix A: TR-181 Type Reference

| TR-181 Type | USP Wire Type | Dart Type | Description |
|-------------|---------------|-----------|-------------|
| `string` | string | `String` | UTF-8 string |
| `string(:N)` | string | `String` | String with max length N |
| `unsignedInt` | uint32 | `int` | 0 to 4294967295 |
| `int` | int32 | `int` | Signed 32-bit integer |
| `unsignedLong` | uint64 | `int` | 0 to 18446744073709551615 |
| `long` | int64 | `int` | Signed 64-bit integer |
| `boolean` | boolean | `bool` | true/false |
| `dateTime` | string (ISO 8601) | `String` | Date/time value |
| `base64` | string | `String` | Base64-encoded binary |
| `hexBinary` | string | `String` | Hex-encoded binary |
| `string[]` | string (CSV) | `List<String>` | Comma-separated list |

### Semantic Types (shown in TR-181 spec as tooltip)

| Semantic Type | Base Type | Example |
|---------------|-----------|--------|
| `IPAddress` | string(:45) | `192.168.1.1` or IPv6 |
| `IPv4Address` | string(:15) | `192.168.1.1` |
| `IPv6Address` | string(:45) | `fe80::1` |
| `MACAddress` | string(:17) | `AA:BB:CC:DD:EE:FF` |
| `StatsCounter32` | unsignedInt | Monotonically increasing counter |
| `StatsCounter64` | unsignedLong | Monotonically increasing counter |

---

## Appendix B: Actions Requiring Vendor Extension

The following JNAP actions have no standard TR-181 equivalent and require
`X_LINKSYS_COM_*` Vendor Extensions in the USP data model.

| JNAP Action | Suggested Extension Path | Notes |
|-------------|-------------------------|-------|
| `GetAdminPasswordHint` | `X_LINKSYS_COM_DeviceInfo.PasswordHint` |  |
| `GetAirtimeFairnessSettings` | `X_LINKSYS_COM_WiFi.AirtimeFairness.` |  |
| `GetAutoConfigurationSettings` | `X_LINKSYS_COM_Setup.AutoConfiguration.` |  |
| `GetBluetoothAutoOnboardingSettings` | `X_LINKSYS_COM_AutoOnboarding.BT.` |  |
| `GetBluetoothAutoOnboardingStatus2` | `X_LINKSYS_COM_AutoOnboarding.BT.Status` |  |
| `GetCloseHealthCheckServers` | `X_LINKSYS_COM_HealthCheck.Servers.` |  |
| `GetDFSSettings` | `X_LINKSYS_COM_WiFi.DFS.` | Dynamic Frequency Selection |
| `GetDeviceMode` | `X_LINKSYS_COM_SmartMode.` | Router/Bridge/Node mode |
| `GetExpressForwardingSettings` | `X_LINKSYS_COM_Router.ExpressForwarding.` |  |
| `GetHealthCheckResults` | `X_LINKSYS_COM_HealthCheck.Results.` |  |
| `GetHealthCheckStatus` | `X_LINKSYS_COM_HealthCheck.` |  |
| `GetIPTVSettings` | `X_LINKSYS_COM_IPTV.` | Spec not in jnap_full.md |
| `GetLedNightModeSetting` | `X_LINKSYS_COM_LED.NightMode.` |  |
| `GetMLOSettings` | `X_LINKSYS_COM_WiFi.MLO.` | WiFi 7 Multi-Link Operation |
| `GetPowerTableSettings` | `X_LINKSYS_COM_PowerTable.` |  |
| `GetSoftSKUSettings` | `X_LINKSYS_COM_Product.SoftSKU.` |  |
| `GetSupportedDDNSProviders` | `X_LINKSYS_COM_DDNS.Providers.` |  |
| `GetSupportedHealthCheckModules` | `X_LINKSYS_COM_HealthCheck.Modules.` |  |
| `GetTunneledUser` | `X_LINKSYS_COM_VPN.TunneledUser.{i}.` |  |
| `GetVPNGateway` | `X_LINKSYS_COM_VPN.Gateway.` | Partial: Device.IPsec.Tunnel.{i}. |
| `GetVPNService` | `X_LINKSYS_COM_VPN.Service.` | Partial: Device.IPsec. |
| `GetVPNUser` | `X_LINKSYS_COM_VPN.User.{i}.` |  |
| `GetWiredAutoOnboardingSettings` | `X_LINKSYS_COM_AutoOnboarding.Wired.` |  |
| `IsAdminPasswordDefault` | `X_LINKSYS_COM_DeviceInfo.IsDefaultPassword` |  |
| `IsAdminPasswordSetByUser` | `X_LINKSYS_COM_Setup.PasswordConfigured` |  |
| `SetAirtimeFairnessSettings` | `X_LINKSYS_COM_WiFi.AirtimeFairness.` |  |
| `SetBluetoothAutoOnboardingSettings` | `X_LINKSYS_COM_AutoOnboarding.BT.` |  |
| `SetDFSSettings` | `X_LINKSYS_COM_WiFi.DFS.` |  |
| `SetDeviceMode` | `X_LINKSYS_COM_SmartMode.` |  |
| `SetExpressForwardingSettings` | `X_LINKSYS_COM_Router.ExpressForwarding.` |  |
| `SetIPTVSettings` | `X_LINKSYS_COM_IPTV.` |  |
| `SetLedNightModeSetting2` | `X_LINKSYS_COM_LED.NightMode.` |  |
| `SetMLOSettings` | `X_LINKSYS_COM_WiFi.MLO.` |  |
| `SetPowerTableSettings` | `X_LINKSYS_COM_PowerTable.` |  |
| `SetRemoteSetting` | `X_LINKSYS_COM_UI.RemoteSetting.` |  |
| `SetTopologyOptimizationSettings2` | `X_LINKSYS_COM_Mesh.TopologyOptimization.` |  |
| `SetUserAcknowledgedAutoConfiguration` | `X_LINKSYS_COM_Setup.UserAcknowledged` |  |
| `SetVPNApply` | `X_LINKSYS_COM_VPN.Apply()` | Command |
| `SetWiredAutoOnboardingSettings` | `X_LINKSYS_COM_AutoOnboarding.Wired.` |  |
| `StartBlinkingNodeLed` | `X_LINKSYS_COM_LED.StartBlink()` | Command |
| `StartBluetoothAutoOnboarding2` | `X_LINKSYS_COM_AutoOnboarding.BT.Start()` | Command |
| `StopBlinkingNodeLed` | `X_LINKSYS_COM_LED.StopBlink()` | Command |
| `TestVPNConnection` | `X_LINKSYS_COM_VPN.TestConnection()` | Command |
| `UpdateFirmwareNow` | `X_LINKSYS_COM_FirmwareUpdate.UpdateNow()` | Command |
| `VerifyRouterResetCode` | `X_LINKSYS_COM_Setup.VerifyResetCode()` | Command |
---
