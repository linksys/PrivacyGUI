# YAML 生成計畫

**版本:** v1.4.0
**最後更新:** 2026-02-26
**參考文件:**
- `doc/jnap/jnap_tr181_mapping.md` - JNAP 與 TR-181 對應表
- `doc/usp/Specifications/usp-codegen-spec.md` - usp-codegen 規格
- `doc/usp/yaml-spec.md` - YAML 定義格式規格

---

## 0. 規格符合性分析

### 0.1 yaml-spec.md 支援的欄位

**定義檔 (Definition File):**
| 欄位 | 必填 | 說明 |
|------|------|------|
| `name` | ✅ | 模組名稱 (PascalCase) |
| `description` | ✅ | 模組說明 |
| `parameters` | ✅ | 參數定義陣列 |
| `version` | ❌ | 語意化版本號 |
| `base_path` | ❌ | TR-181 基礎路徑 |
| `category` | ❌ | 分類標籤 |
| `presets` | ❌ | 預設組態群組 |
| `subscribe` | ❌ | 訂閱配置 |

**延伸檔 (Extension File):**
| 欄位 | 必填 | 說明 |
|------|------|------|
| `name` | ✅ | 必須與定義檔 `name` 一致 |
| `transforms` | ✅ | Computed property 定義 |

### 0.2 yaml-spec.md 與 usp-codegen-spec.md 差異

經比對，以下功能在 **usp-codegen-spec.md 的 Internal Data Model (AST)** 中已定義，但 **yaml-spec.md 未文件化**：

| 功能 | usp-codegen-spec.md | yaml-spec.md | codegen v5 實作 | 狀態 |
|------|---------------------|--------------|----------------|------|
| `multi_instance` | ✅ AST line 913 | ❌ 未文件化 | ✅ **v5 完整實作** — singular/collection class + update/updateMany | 就緒 |
| `singularName` | — | ❌ 未文件化 | ✅ **v5 新增** — 解決同名衝突 | 就緒 |
| `instance` | ✅ AST line 912 | ❌ 未文件化 | ⚠️ `instance_path: "{i}"` 未經測試 | 待驗證 |
| `operations` | ✅ 有範例 (Turbo Channel) | ❌ 未文件化 | ❌ 未實作 | 需實作 codegen |
| `related` | ✅ AST 註解 line 917 | ❌ 未文件化 | ❌ 未實作 | 需實作 codegen |

> **✅ 更新 (2026-02-26 v5 驗證):** `multi_instance: true` 在 codegen v5 已完整實作。
> 生成 singular data class + collection class + `fetch()` / `update()` / `updateMany()` 方法。
> `UspResponseExtension`（`getInstances()` / `getString()` 等）已在 `lib/usp/services/usp_response_helpers.dart` 實作。
> **注意：** 不以 `s` 結尾的名稱（如 `PortForwarding`）需加 `singularName` 欄位避免衝突。

### 0.3 檔案命名慣例

根據 yaml-spec.md：
- 定義檔：`{Name}.yaml` (PascalCase)
- 延伸檔：`{Name}_ext.yaml`

**範例：**
```
definitions/
├── DeviceInfo.yaml
├── DeviceInfo_ext.yaml      # Transform 延伸
├── RadioSettings.yaml
└── RadioSettings_ext.yaml
```

---

## 1. 概述

本計畫描述如何基於 JNAP-TR181 對應表，系統性地生成 `usp-codegen` 所需的 YAML 定義檔。

### 1.1 生成目標

> **檔名慣例：** 根據 yaml-spec.md 使用 PascalCase

```
definitions/
├── core/                    # 核心服務（Direct 映射優先）
│   ├── DeviceInfo.yaml
│   ├── DeviceInfo_ext.yaml      # Transform 延伸
│   ├── SystemControl.yaml
│   ├── TimeSettings.yaml
│   └── ...
├── network/                 # 網路設定
│   ├── WANSettings.yaml
│   ├── WANSettings_ext.yaml
│   ├── LANSettings.yaml
│   ├── EthernetPorts.yaml
│   └── ...
├── wifi/                    # WiFi 設定
│   ├── RadioSettings.yaml
│   ├── WiFiBasicSettings.yaml
│   ├── GuestNetwork.yaml
│   └── ...
├── firewall/                # 防火牆
│   ├── PortForwarding.yaml
│   ├── DMZSettings.yaml
│   ├── ALGSettings.yaml
│   └── ...
├── devices/                 # 裝置管理
│   ├── ConnectedDevices.yaml
│   ├── ConnectedDevices_ext.yaml
│   └── ...
├── diagnostics/             # 診斷工具
│   ├── PingTest.yaml
│   ├── TracerouteTest.yaml
│   └── ...
└── vendor/                  # Vendor Extensions
    └── linksys/
        ├── MeshSettings.yaml
        ├── LEDSettings.yaml
        ├── AdminPassword.yaml
        └── ...
```

> **注意：** `*_ext.yaml` 為延伸檔，包含 transforms (computed properties)

### 1.2 對應狀態策略

| 狀態 | 策略 | 優先級 |
|------|------|--------|
| **Direct** | 直接生成標準 YAML，1:1 對應 TR-181 | P0 (最高) |
| **Partial** | 需組合多個 TR-181 物件，設計聚合結構 | P1 |
| **Custom** | 使用 `X_LINKSYS_COM_*` Vendor Extension | P2 |
| **N/A** | 暫不支援，需設計替代方案 | P3 |

---

## 2. Phase 0: Core Services (Direct Mapping)

優先處理 **Direct** 對應的 JNAP actions，建立基礎架構。

### 2.1 Device Info

✅ **符合 yaml-spec.md**

```yaml
# definitions/core/DeviceInfo.yaml
name: DeviceInfo
version: 1.0.0
base_path: Device.DeviceInfo
category: core
description: Device hardware and software information

parameters:
  - path: Manufacturer
    type: string
    description: Device manufacturer

  - path: ModelName
    type: string
    description: Model name

  - path: SerialNumber
    type: string
    description: Serial number

  - path: HardwareVersion
    type: string
    description: Hardware version

  - path: SoftwareVersion
    type: string
    description: Software/firmware version

  - path: UpTime
    type: int
    description: Time in seconds since last reboot
```

**對應 JNAP:** `getDeviceInfo`

### 2.2 System Control (USP Commands)

> ⚠️ **注意：** `operations` 欄位目前不在 yaml-spec.md 中，需要擴充規格。
> 以下為建議的擴充格式：

```yaml
# definitions/core/SystemControl.yaml
name: SystemControl
version: 1.0.0
base_path: Device
category: core
description: System control operations

# [需擴充規格] USP Command 定義
operations:
  - name: reboot
    command: Reboot()
    async: false
    description: Reboot the device

  - name: factoryReset
    command: FactoryReset()
    async: false
    description: Reset device to factory defaults
```

**對應 JNAP:** `reboot`, `reboot2`, `factoryReset`, `factoryReset2`

**替代方案 (符合現有規格)：** 若不擴充規格，可在 UI 層直接呼叫 `UspClient.operate()`

### 2.3 Radio Settings

✅ **符合 usp-codegen-spec.md** (`multi_instance` 在 AST 中已定義)

> ℹ️ yaml-spec.md 未文件化此欄位，但 codegen 內部已支援

```yaml
# definitions/wifi/RadioSettings.yaml
name: RadioSettings
version: 1.0.0
base_path: Device.WiFi.Radio.{i}
category: wifi
description: WiFi radio configuration

multi_instance: true

parameters:
  - path: Enable
    type: boolean
    writable: true
    description: Enable/disable radio

  - path: Status
    type: string
    description: Current radio status (Up, Down, Error)

  - path: Channel
    type: int
    writable: true
    description: Operating channel

  - path: OperatingFrequencyBand
    type: string
    description: Frequency band (2.4GHz, 5GHz, 6GHz)

  - path: OperatingChannelBandwidth
    type: string
    writable: true
    description: Channel bandwidth

  - path: TransmitPower
    type: int
    writable: true
    description: Transmit power percentage (0-100)

subscribe:
  enabled: true
  notifType: ValueChange
  id: radio-settings-01
```

**對應 JNAP:** `getRadioInfo`, `setRadioSettings`

### 2.4 Ethernet Ports

```yaml
# definitions/network/ethernet_ports.yaml
name: EthernetPorts
version: 1.0.0
base_path: Device.Ethernet.Interface
category: network
description: Ethernet port status and configuration

multi_instance: true
instance_path: "{i}"

parameters:
  - path: Status
    type: string
    description: Interface status (Up, Down, Unknown)

  - path: DuplexMode
    type: string
    description: Duplex mode (Half, Full, Auto)

  - path: CurrentBitRate
    type: int
    description: Current link speed in Mbps

  - path: MACAddress
    type: string
    description: MAC address
```

**對應 JNAP:** `getEthernetPortConnections`

### 2.5 Routing Table

```yaml
# definitions/network/routing.yaml
name: RoutingTable
singularName: Route                # v5: 必須 — 名稱不以 s 結尾
version: 1.0.0
base_path: Device.Routing.Router.1.IPv4Forwarding
category: network
description: Static IPv4 routing configuration

multi_instance: true
instance_path: "{i}"

parameters:
  - path: Enable
    type: boolean
    writable: true
    description: Enable this route

  - path: DestIPAddress
    type: string
    writable: true
    description: Destination IP address

  - path: DestSubnetMask
    type: string
    writable: true
    description: Destination subnet mask

  - path: GatewayIPAddress
    type: string
    writable: true
    description: Gateway IP address

  - path: Interface
    type: string
    writable: true
    description: Outgoing interface
```

**對應 JNAP:** `getRoutingSettings`, `setRoutingSettings`

---

## 3. Phase 1: Firewall & NAT (Direct Mapping)

### 3.1 Port Forwarding

```yaml
# definitions/firewall/port_forwarding.yaml
name: PortForwarding
singularName: PortForwardingRule   # v5: 必須 — 名稱不以 s 結尾，需手動指定
version: 1.0.0
base_path: Device.NAT.PortMapping
category: firewall
description: NAT port forwarding rules

multi_instance: true
instance_path: "{i}"

parameters:
  - path: Enable
    type: boolean
    writable: true
    description: Enable this rule

  - path: ExternalPort
    type: int
    writable: true
    description: External port number

  - path: ExternalPortEndRange
    type: int
    writable: true
    description: External port range end (for port ranges)

  - path: InternalPort
    type: int
    writable: true
    description: Internal port number

  - path: InternalClient
    type: string
    writable: true
    description: Internal client IP address

  - path: Protocol
    type: string
    writable: true
    description: Protocol (TCP, UDP, or Both)

  - path: Description
    type: string
    writable: true
    description: Rule description
```

**對應 JNAP:** `getSinglePortForwardingRules`, `setSinglePortForwardingRules`, `getPortRangeForwardingRules`, `setPortRangeForwardingRules`

### 3.2 Port Triggering

```yaml
# definitions/firewall/port_triggering.yaml
name: PortTriggering
singularName: PortTriggeringRule   # v5: 必須 — 名稱不以 s 結尾
version: 1.0.0
base_path: Device.NAT.PortTrigger
category: firewall
description: Port triggering rules

multi_instance: true
instance_path: "{i}"

parameters:
  - path: Enable
    type: boolean
    writable: true

  - path: TriggerPortStart
    type: int
    writable: true

  - path: TriggerPortEnd
    type: int
    writable: true

  - path: TriggerProtocol
    type: string
    writable: true

  - path: OpenPortStart
    type: int
    writable: true

  - path: OpenPortEnd
    type: int
    writable: true

  - path: OpenProtocol
    type: string
    writable: true
```

**對應 JNAP:** `getPortRangeTriggeringRules`, `setPortRangeTriggeringRules`

### 3.3 DMZ Settings

✅ **符合 yaml-spec.md**

```yaml
# definitions/firewall/DMZSettings.yaml
name: DMZSettings
version: 1.0.0
base_path: Device.Firewall.DMZ.1
category: firewall
description: DMZ host configuration

parameters:
  - path: Enable
    type: boolean
    writable: true
    description: Enable DMZ

  - path: DestIPAddress
    type: string
    writable: true
    description: DMZ host IP address
```

**對應 JNAP:** `getDMZSettings`, `setDMZSettings`

### 3.4 ALG Settings

```yaml
# definitions/firewall/alg_settings.yaml
name: ALGSettings
version: 1.0.0
base_path: Device.Firewall.ConnectionTracking
category: firewall
description: Application Layer Gateway settings

parameters:
  - field_name: sipEnabled
    path: SIP.Enable
    type: boolean
    writable: true
    description: SIP ALG enabled

  - field_name: h323Enabled
    path: H323.Enable
    type: boolean
    writable: true
    description: H.323 ALG enabled

  - field_name: ftpEnabled
    path: FTP.Enable
    type: boolean
    writable: true
    description: FTP ALG enabled
```

**對應 JNAP:** `getALGSettings`, `setALGSettings`

---

## 4. Phase 2: Device List & Network (Partial Mapping)

需要組合多個 TR-181 物件的定義。

### 4.1 Connected Devices

```yaml
# definitions/devices/connected_devices.yaml
name: ConnectedDevices
version: 1.0.0
base_path: Device.Hosts.Host
category: devices
description: Network connected devices

multi_instance: true
instance_path: "{i}"

parameters:
  - path: PhysAddress
    field_name: macAddress
    type: string
    description: MAC address

  - path: IPAddress
    field_name: ipAddress
    type: string
    description: IP address

  - path: HostName
    field_name: hostName
    type: string
    description: Device hostname

  - path: Active
    field_name: isActive
    type: boolean
    description: Currently connected

  - path: Layer1Interface
    field_name: interface
    type: string
    description: Connection interface (WiFi/Ethernet)

  - path: AddressSource
    field_name: addressSource
    type: string
    description: Address assignment method (DHCP, Static)

subscribe:
  enabled: true
  notifType: ObjectCreation
  id: connected-devices-01
```

**對應 JNAP:** `getDevices`, `getLocalDevice`

### 4.2 WiFi Basic Settings (Partial - 組合 SSID + AccessPoint)

✅ **符合 yaml-spec.md** (使用 presets)

```yaml
# definitions/wifi/WiFiBasicSettings.yaml
name: WiFiBasicSettings
version: 1.0.0
category: wifi
description: Basic WiFi network settings (combines SSID and AccessPoint)

# Note: No base_path - using full paths for aggregation
parameters:
  # SSID Object
  - path: Device.WiFi.SSID.1.SSID
    field_name: ssid
    type: string
    writable: true
    description: Network name

  - path: Device.WiFi.SSID.1.Enable
    field_name: enabled
    type: boolean
    writable: true
    description: Enable WiFi network

  - path: Device.WiFi.SSID.1.MACAddress
    field_name: macAddress
    type: string
    description: BSSID

  # AccessPoint.Security Object
  - path: Device.WiFi.AccessPoint.1.Security.ModeEnabled
    field_name: securityMode
    type: string
    writable: true
    description: Security mode (WPA2-Personal, WPA3-Personal, etc.)

  - path: Device.WiFi.AccessPoint.1.Security.PreSharedKey
    field_name: passphrase
    type: string
    writable: true
    sensitive: true
    description: WiFi password

subscribe:
  enabled: true
  notifType: ValueChange
  id: wifi-basic-01

presets:
  - field: securityMode
    description: WiFi security mode presets
    options:
      - id: wpa2Personal
        label: security_wpa2_personal
        values:
          - path: Device.WiFi.AccessPoint.1.Security.ModeEnabled
            value: "WPA2-Personal"

      - id: wpa3Personal
        label: security_wpa3_personal
        values:
          - path: Device.WiFi.AccessPoint.1.Security.ModeEnabled
            value: "WPA3-Personal"

      - id: wpa2wpa3Personal
        label: security_wpa2_wpa3_mixed
        values:
          - path: Device.WiFi.AccessPoint.1.Security.ModeEnabled
            value: "WPA2-WPA3-Personal"
```

**對應 JNAP:** `getSimpleWiFiSettings`, `setSimpleWiFiSettings`

### 4.3 Guest Network

```yaml
# definitions/wifi/guest_network.yaml
name: GuestNetwork
version: 1.0.0
category: wifi
description: Guest WiFi network configuration

# Guest network typically uses a different SSID instance (e.g., SSID.2)
parameters:
  - path: Device.WiFi.SSID.2.SSID
    field_name: guestSsid
    type: string
    writable: true

  - path: Device.WiFi.SSID.2.Enable
    field_name: guestEnabled
    type: boolean
    writable: true

  - path: Device.WiFi.AccessPoint.2.Security.ModeEnabled
    field_name: guestSecurityMode
    type: string
    writable: true

  - path: Device.WiFi.AccessPoint.2.Security.PreSharedKey
    field_name: guestPassphrase
    type: string
    writable: true
    sensitive: true
```

**對應 JNAP:** `getGuestRadioSettings`, `setGuestRadioSettings`, `getGuestNetworkSettings`, `setGuestNetworkSettings`

### 4.4 WAN Settings (Partial - IP + PPP)

```yaml
# definitions/network/wan_settings.yaml
name: WANSettings
version: 1.0.0
category: network
description: WAN connection configuration

parameters:
  # IP Interface
  - path: Device.IP.Interface.1.Enable
    field_name: enabled
    type: boolean
    writable: true

  - path: Device.IP.Interface.1.Status
    field_name: status
    type: string

  - path: Device.IP.Interface.1.IPv4Address.1.IPAddress
    field_name: ipAddress
    type: string
    writable: true

  - path: Device.IP.Interface.1.IPv4Address.1.SubnetMask
    field_name: subnetMask
    type: string
    writable: true

  - path: Device.IP.Interface.1.IPv4Address.1.AddressingType
    field_name: addressingType
    type: string
    writable: true
    description: DHCP or Static

  # PPPoE (optional)
  - path: Device.PPP.Interface.1.Username
    field_name: pppoeUsername
    type: string
    writable: true

  - path: Device.PPP.Interface.1.Password
    field_name: pppoePassword
    type: string
    writable: true
    sensitive: true

presets:
  - field: connectionType
    description: WAN connection type
    options:
      - id: dhcp
        label: wan_type_dhcp
        values:
          - path: Device.IP.Interface.1.IPv4Address.1.AddressingType
            value: "DHCP"

      - id: static
        label: wan_type_static
        userInputs:
          - field: staticIp
            path: Device.IP.Interface.1.IPv4Address.1.IPAddress
            type: string
            label: wan_static_ip
            validation: ipv4
          - field: staticMask
            path: Device.IP.Interface.1.IPv4Address.1.SubnetMask
            type: string
            label: wan_subnet_mask
            validation: ipv4

      - id: pppoe
        label: wan_type_pppoe
        userInputs:
          - field: pppUsername
            path: Device.PPP.Interface.1.Username
            type: string
            label: pppoe_username
          - field: pppPassword
            path: Device.PPP.Interface.1.Password
            type: string
            label: pppoe_password
            sensitive: true
```

**對應 JNAP:** `getWANSettings`, `setWANSettings`, `getWANStatus`

### 4.5 LAN Settings

```yaml
# definitions/network/lan_settings.yaml
name: LANSettings
version: 1.0.0
category: network
description: LAN and DHCP server configuration

parameters:
  # LAN IP
  - path: Device.IP.Interface.2.IPv4Address.1.IPAddress
    field_name: lanIpAddress
    type: string
    writable: true

  - path: Device.IP.Interface.2.IPv4Address.1.SubnetMask
    field_name: lanSubnetMask
    type: string
    writable: true

  # DHCP Server Pool
  - path: Device.DHCPv4.Server.Pool.1.MinAddress
    field_name: dhcpStartAddress
    type: string
    writable: true

  - path: Device.DHCPv4.Server.Pool.1.MaxAddress
    field_name: dhcpEndAddress
    type: string
    writable: true

  - path: Device.DHCPv4.Server.Pool.1.LeaseTime
    field_name: dhcpLeaseTime
    type: int
    writable: true
    description: Lease time in seconds
```

**對應 JNAP:** `getLANSettings`, `setLANSettings`

---

## 5. Phase 3: Diagnostics (USP Commands)

TR-181 診斷功能使用 USP async commands。

### 5.1 Ping Test

```yaml
# definitions/diagnostics/ping_test.yaml
name: PingTest
version: 1.0.0
base_path: Device.IP.Diagnostics
category: diagnostics
description: IP layer ping diagnostic

operations:
  - name: startPing
    command: IPPing()
    async: true
    description: Start ping test
    inputs:
      - name: Host
        type: string
        required: true
        description: Target hostname or IP

      - name: NumberOfRepetitions
        type: int
        default: 4
        description: Number of ping requests

      - name: Timeout
        type: int
        default: 1000
        description: Timeout per request in ms

    outputs:
      - name: SuccessCount
        type: int

      - name: FailureCount
        type: int

      - name: AverageResponseTime
        type: int
        description: Average RTT in ms

      - name: MinimumResponseTime
        type: int

      - name: MaximumResponseTime
        type: int
```

**對應 JNAP:** `startPing`, `getPingStatus`

### 5.2 Traceroute Test

```yaml
# definitions/diagnostics/traceroute_test.yaml
name: TracerouteTest
version: 1.0.0
base_path: Device.IP.Diagnostics
category: diagnostics
description: IP layer traceroute diagnostic

operations:
  - name: startTraceroute
    command: TraceRoute()
    async: true
    description: Start traceroute test
    inputs:
      - name: Host
        type: string
        required: true

      - name: MaxHopCount
        type: int
        default: 30

      - name: Timeout
        type: int
        default: 5000

    outputs:
      - name: ResponseTime
        type: int

      - name: RouteHops
        type: array
        description: Array of hop information
```

**對應 JNAP:** `startTracroute`, `getTracerouteStatus`

### 5.3 DHCP Renew

```yaml
# definitions/network/dhcp_operations.yaml
name: DHCPOperations
version: 1.0.0
category: network
description: DHCP client operations

operations:
  - name: renewDHCPv4
    command: Device.DHCPv4.Client.1.Renew()
    async: false
    description: Renew IPv4 DHCP lease

  - name: renewDHCPv6
    command: Device.DHCPv6.Client.1.Renew()
    async: false
    description: Renew IPv6 DHCP lease
```

**對應 JNAP:** `renewDHCPWANLease`, `renewDHCPIPv6WANLease`

---

## 6. Phase 4: Vendor Extensions (Custom)

需要 `X_LINKSYS_COM_*` 的功能。

### 6.1 Admin Password

```yaml
# definitions/vendor/linksys/admin_password.yaml
name: AdminPassword
version: 1.0.0
base_path: Device.Users.User.1
category: vendor/linksys
description: Administrator password management

parameters:
  - path: Password
    field_name: password
    type: string
    writable: true
    sensitive: true

  # Vendor Extensions
  - path: Device.X_LINKSYS_COM_DeviceInfo.PasswordHint
    field_name: passwordHint
    type: string
    writable: true

  - path: Device.X_LINKSYS_COM_DeviceInfo.IsDefaultPassword
    field_name: isDefaultPassword
    type: boolean
```

**對應 JNAP:** `checkAdminPassword`, `coreSetAdminPassword`, `getAdminPasswordHint`, `isAdminPasswordDefault`

### 6.2 LED Night Mode

```yaml
# definitions/vendor/linksys/led_settings.yaml
name: LEDSettings
version: 1.0.0
base_path: Device.X_LINKSYS_COM_LED
category: vendor/linksys
description: LED indicator settings

parameters:
  - path: Enable
    type: boolean
    writable: true
    description: LED enabled

  - path: NightMode.Enable
    field_name: nightModeEnabled
    type: boolean
    writable: true

  - path: NightMode.StartTime
    field_name: nightModeStart
    type: string
    writable: true
    description: Night mode start time (HH:MM)

  - path: NightMode.EndTime
    field_name: nightModeEnd
    type: string
    writable: true
    description: Night mode end time (HH:MM)
```

**對應 JNAP:** `getLedNightModeSetting`, `setLedNightModeSetting`

### 6.3 VPN Settings

```yaml
# definitions/vendor/linksys/vpn_settings.yaml
name: VPNSettings
version: 1.0.0
category: vendor/linksys
description: VPN configuration (IPsec + Linksys extensions)

parameters:
  # Standard IPsec
  - path: Device.IPsec.Enable
    field_name: ipsecEnabled
    type: boolean
    writable: true

  # Vendor Extensions for VPN User Management
  - path: Device.X_LINKSYS_COM_VPN.Enable
    field_name: vpnServiceEnabled
    type: boolean
    writable: true

  - path: Device.X_LINKSYS_COM_VPN.ServerAddress
    field_name: vpnServerAddress
    type: string
    writable: true

# VPN Users - multi-instance
related:
  - name: VPNUser
    base_path: Device.X_LINKSYS_COM_VPN.User
    multi_instance: true
    parameters:
      - path: Username
        type: string
        writable: true
      - path: Password
        type: string
        writable: true
        sensitive: true
      - path: Enable
        type: boolean
        writable: true
```

**對應 JNAP:** `getVPNService`, `setVPNService`, `getVPNUser`, `setVPNUser`

### 6.4 Mesh/Topology Settings

```yaml
# definitions/vendor/linksys/mesh_settings.yaml
name: MeshSettings
version: 1.0.0
category: vendor/linksys
description: Mesh network topology settings

parameters:
  # Standard MultiAP
  - path: Device.WiFi.MultiAP.APDeviceNumberOfEntries
    field_name: nodeCount
    type: int

  # Vendor Extensions
  - path: Device.X_LINKSYS_COM_Mesh.TopologyOptimization.Enable
    field_name: topologyOptimizationEnabled
    type: boolean
    writable: true

  - path: Device.X_LINKSYS_COM_Mesh.BackhaulPriority
    field_name: backhaulPriority
    type: string
    writable: true
    description: Preferred backhaul (Ethernet, WiFi5GHz, WiFi6GHz)

  - path: Device.X_LINKSYS_COM_SmartMode
    field_name: deviceMode
    type: string
    writable: true
    description: Device mode (Router, Bridge, Node)
```

**對應 JNAP:** `getTopologyOptimizationSettings`, `setTopologyOptimizationSettings`, `getDeviceMode`, `setDeviceMode`

---

## 7. Transforms 定義 (延伸檔)

> **檔名慣例：** 根據 yaml-spec.md，延伸檔命名為 `{Name}_ext.yaml`

### 7.1 Device Info Transforms

```yaml
# definitions/core/DeviceInfo_ext.yaml
name: DeviceInfo

transforms:
  - name: uptimeFormatted
    type: formula
    description: Human-readable uptime
    formula: "formatDuration(UpTime)"
    inputs:
      - UpTime
    output_type: string
```

### 7.2 WAN Settings Transforms

```yaml
# definitions/network/WANSettings_ext.yaml
name: WANSettings

transforms:
  - name: connectionTypeDisplay
    type: mapping
    description: Connection type display label
    input: addressingType
    mappings:
      DHCP: "wan_connection_dhcp"
      Static: "wan_connection_static"
      PPPoE: "wan_connection_pppoe"

  - name: statusDisplay
    type: mapping
    input: status
    mappings:
      Up: "wan_status_connected"
      Down: "wan_status_disconnected"
      Error: "wan_status_error"
```

### 7.3 Connected Devices Transforms

```yaml
# definitions/devices/ConnectedDevices_ext.yaml
name: ConnectedDevices

transforms:
  - name: connectionTypeDisplay
    type: mapping
    description: Connection type display
    input: interface
    mappings:
      "Device.WiFi.SSID.1": "connection_wifi_24ghz"
      "Device.WiFi.SSID.2": "connection_wifi_5ghz"
      "Device.Ethernet.Interface.1": "connection_ethernet"

  - name: addressSourceDisplay
    type: mapping
    input: addressSource
    mappings:
      DHCP: "address_source_dhcp"
      Static: "address_source_static"
      AutoIP: "address_source_autoip"
```

---

## 8. 生成優先級矩陣

### P0 - Direct Mapping (首批)

| 模組 | YAML 檔案 | 對應 JNAP |
|------|----------|-----------|
| DeviceInfo | `core/device_info.yaml` | getDeviceInfo |
| SystemControl | `core/system_control.yaml` | reboot, factoryReset |
| RadioSettings | `wifi/radio_settings.yaml` | getRadioInfo, setRadioSettings |
| PortForwarding | `firewall/port_forwarding.yaml` | get/setSinglePortForwardingRules |
| PortTriggering | `firewall/port_triggering.yaml` | get/setPortRangeTriggeringRules |
| DMZSettings | `firewall/dmz_settings.yaml` | get/setDMZSettings |
| ALGSettings | `firewall/alg_settings.yaml` | get/setALGSettings |
| EthernetPorts | `network/ethernet_ports.yaml` | getEthernetPortConnections |
| RoutingTable | `network/routing.yaml` | get/setRoutingSettings |
| UPnPSettings | `network/upnp_settings.yaml` | get/setUPnPSettings |
| DDNSSettings | `network/ddns_settings.yaml` | get/setDDNSSettings |
| TimeSettings | `core/time_settings.yaml` | getLocalTime, get/setTimeSettings |

### P1 - Partial Mapping (需聚合)

| 模組 | YAML 檔案 | 對應 JNAP | 備註 |
|------|----------|-----------|------|
| ConnectedDevices | `devices/connected_devices.yaml` | getDevices | Multi-instance |
| WiFiBasicSettings | `wifi/wifi_basic.yaml` | get/setSimpleWiFiSettings | SSID + AP |
| GuestNetwork | `wifi/guest_network.yaml` | get/setGuestNetworkSettings | 訪客 SSID |
| WANSettings | `network/wan_settings.yaml` | get/setWANSettings | IP + PPP |
| LANSettings | `network/lan_settings.yaml` | get/setLANSettings | IP + DHCP |
| IPv6Settings | `network/ipv6_settings.yaml` | get/setIPv6Settings | 複雜聚合 |
| FirewallSettings | `firewall/firewall_settings.yaml` | get/setFirewallSettings | Policy |

### P2 - USP Commands

| 模組 | YAML 檔案 | 對應 JNAP |
|------|----------|-----------|
| PingTest | `diagnostics/ping_test.yaml` | startPing, getPingStatus |
| TracerouteTest | `diagnostics/traceroute_test.yaml` | startTracroute |
| DHCPOperations | `network/dhcp_operations.yaml` | renewDHCPWANLease |

### P3 - Vendor Extensions

| 模組 | YAML 檔案 | 對應 JNAP |
|------|----------|-----------|
| AdminPassword | `vendor/linksys/admin_password.yaml` | checkAdminPassword 等 |
| LEDSettings | `vendor/linksys/led_settings.yaml` | get/setLedNightModeSetting |
| VPNSettings | `vendor/linksys/vpn_settings.yaml` | get/setVPNService 等 |
| MeshSettings | `vendor/linksys/mesh_settings.yaml` | getTopologyOptimizationSettings |
| AirtimeFairness | `vendor/linksys/airtime_fairness.yaml` | get/setAirtimeFairnessSettings |
| HealthCheck | `vendor/linksys/health_check.yaml` | runHealthCheck 等 |

---

## 9. 實作檢查清單

### Phase 0 (Direct)
- [ ] `core/device_info.yaml`
- [ ] `core/system_control.yaml`
- [ ] `core/time_settings.yaml`
- [ ] `wifi/radio_settings.yaml`
- [ ] `firewall/port_forwarding.yaml`
- [ ] `firewall/port_triggering.yaml`
- [ ] `firewall/dmz_settings.yaml`
- [ ] `firewall/alg_settings.yaml`
- [ ] `network/ethernet_ports.yaml`
- [ ] `network/routing.yaml`
- [ ] `network/upnp_settings.yaml`
- [ ] `network/ddns_settings.yaml`

### Phase 1 (Partial)
- [ ] `devices/connected_devices.yaml`
- [ ] `wifi/wifi_basic.yaml`
- [ ] `wifi/guest_network.yaml`
- [ ] `network/wan_settings.yaml`
- [ ] `network/lan_settings.yaml`
- [ ] `network/ipv6_settings.yaml`
- [ ] `firewall/firewall_settings.yaml`

### Phase 2 (Commands)
- [ ] `diagnostics/ping_test.yaml`
- [ ] `diagnostics/traceroute_test.yaml`
- [ ] `network/dhcp_operations.yaml`

### Phase 3 (Vendor)
- [ ] `vendor/linksys/admin_password.yaml`
- [ ] `vendor/linksys/led_settings.yaml`
- [ ] `vendor/linksys/vpn_settings.yaml`
- [ ] `vendor/linksys/mesh_settings.yaml`

---

## 10. 統計摘要

| 分類 | YAML 定義數 | 對應 JNAP 數 |
|------|------------|-------------|
| Core | 3 | ~10 |
| WiFi | 3 | ~15 |
| Network | 8 | ~25 |
| Firewall | 5 | ~15 |
| Devices | 1 | ~5 |
| Diagnostics | 3 | ~8 |
| Vendor | 5+ | ~20 |
| **Total** | **~28** | **~98** |

覆蓋率: ~70% 的 JNAP actions (98/140)

---

## 附錄: 未支援項目

以下 JNAP actions 暫不納入 YAML 生成：

1. **Transaction 相關** - `startTransaction`, `commitTransaction` (UI 層處理)
2. **Bluetooth 相關** - `getBluetoothStatus` 等 (非 TR-181)
3. **Cloud 相關** - `getCloudStatus` 等 (非 TR-181)
4. **Setup 流程** - `verifyRouterResetCode` 等 (特定流程)

---

## 附錄 B: yaml-spec.md 文件化建議

以下功能已在 **usp-codegen-spec.md Internal Data Model** 中定義，但 **yaml-spec.md 尚未文件化**：

### B.1 Multi-instance 支援 (AST line 912-913)

```yaml
# 需文件化欄位
multi_instance: boolean  # 是否為多實例物件
instance: string         # Instance 識別符 (如 "{i}")
```

**用途：** 支援 `Device.Hosts.Host.{i}.`, `Device.NAT.PortMapping.{i}.` 等

**usp-codegen-spec.md 參考：**
- Section "Multi-Instance Class" (line 469-553)
- AST `definition_t.multi_instance` (line 913)
- AST `definition_t.instance` (line 912)

### B.2 USP Operations 支援 (AST line 917 註解)

```yaml
# 需文件化區塊
operations:
  - name: string           # 操作名稱
    command: string        # USP Command 路徑 (如 "Device.Reboot()")
    async: boolean         # 是否為 async command
    description: string    # 說明
    inputs:                # 輸入參數
      - name: string
        type: string
        required: boolean
        default: any
    outputs:               # 輸出參數
      - name: string
        type: string
```

**用途：** 支援 `Reboot()`, `FactoryReset()`, `IPPing()`, `TraceRoute()`, `Renew()` 等 USP Commands

**usp-codegen-spec.md 參考：**
- Section "Turbo Channel Operation" (line 555-632)
- AST 註解提及 `operations` (line 917)

### B.3 Related Objects 支援 (AST line 917 註解)

```yaml
# 需文件化區塊
related:
  - name: string
    base_path: string
    multi_instance: boolean
    parameters: [...]
```

**用途：** 定義關聯子物件 (如 VPN Users)

### B.4 UserInput 擴充

```yaml
# 需在 userInputs 中文件化
sensitive: boolean  # 是否為敏感資料 (如密碼)
```

---

**文件版本歷史:**

| 版本 | 日期 | 變更 |
|------|------|------|
| v1.0.0 | 2026-02-26 | 初始版本 |
| v1.1.0 | 2026-02-26 | 新增規格符合性分析、擴充建議 |
| v1.2.0 | 2026-02-26 | 確認 multi_instance 在 codegen AST 已支援，更新文件化建議 |
| v1.3.0 | 2026-02-26 | 實測 codegen：multi_instance 解析正常但程式碼生成未實作 |
| v1.4.0 | 2026-02-26 | 更新 codegen v5 驗證結果：multi_instance 完整實作、需 singularName 的定義已標注 |
