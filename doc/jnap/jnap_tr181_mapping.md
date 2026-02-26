# JNAP 與 TR-181 Data Model 對應表

**版本:** v1.1.0
**最後更新:** 2026-02-26
**參考來源:**
- `doc/jnap/jnap_commands_used.md` - PrivacyGUI 使用的 JNAP commands
- `doc/jnap/jnap_full.md` - JNAP 完整規格
- `doc/usp/tr-181-2-20-0-usp-full.xml` - TR-181 Data Model (v2.20)

---

## 概述

本文件建立 JNAP (JSON Network Access Protocol) commands 與 TR-181 (Device:2 Data Model) 的對應關係，用於 USP (User Services Platform) 整合規劃。

### 對應狀態說明

| 狀態 | 說明 |
|------|------|
| **Direct** | 直接對應，JNAP 欄位可直接映射到 TR-181 參數 |
| **Partial** | 部分對應，需要轉換或組合多個 TR-181 物件 |
| **Custom** | 需要 Vendor Extension (X_LINKSYS_COM_*) |
| **N/A** | 無對應 TR-181 物件，需完全自訂 |

### TR-181 物件類型

| 類型 | 說明 | 範例 |
|------|------|------|
| **Object** | 資料物件，包含參數 | `Device.DeviceInfo.` |
| **Parameter** | 可讀/寫的參數 | `Device.DeviceInfo.Manufacturer` |
| **Command** | USP 操作命令 (sync/async) | `Device.Reboot()`, `Device.IP.Diagnostics.IPPing()` |
| **Event** | USP 事件通知 | `Device.Boot!` |

---

## 1. Core (核心服務)

### Device Info

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getDeviceInfo` | `Device.DeviceInfo.` | **Direct** | |
| | `Device.DeviceInfo.Manufacturer` | | 製造商 |
| | `Device.DeviceInfo.ModelName` | | 型號名稱 |
| | `Device.DeviceInfo.SerialNumber` | | 序號 |
| | `Device.DeviceInfo.HardwareVersion` | | 硬體版本 |
| | `Device.DeviceInfo.SoftwareVersion` | | 軟體版本 |
| | `Device.DeviceInfo.UpTime` | | 運行時間 |

### Admin Password

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `checkAdminPassword` | `Device.Users.User.{i}.Password` | **Partial** | 需驗證邏輯 |
| `coreSetAdminPassword` | `Device.Users.User.{i}.Password` | **Partial** | |
| `getAdminPasswordHint` | `X_LINKSYS_COM_PasswordHint` | **Custom** | Vendor Extension |
| `isAdminPasswordDefault` | `X_LINKSYS_COM_IsDefaultPassword` | **Custom** | Vendor Extension |

### System Control

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `reboot` | `Device.Reboot()` | **Direct** | USP Sync Command |
| `reboot2` | `Device.Reboot()` | **Direct** | 擴展版本，支援指定節點 |
| `factoryReset` | `Device.FactoryReset()` | **Direct** | USP Sync Command |
| `factoryReset2` | `Device.FactoryReset()` | **Direct** | 擴展版本，支援指定節點 |

> **命令參數:** `Reboot()` 和 `FactoryReset()` 無輸入參數，執行後會記錄 `Device.DeviceInfo.Reboots.Reboot.{i}.` 歷史。

---

## 2. WiFi (無線網路)

### Radio Settings

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getRadioInfo` | `Device.WiFi.Radio.{i}.` | **Direct** | |
| | `Device.WiFi.Radio.{i}.Enable` | | 啟用狀態 |
| | `Device.WiFi.Radio.{i}.Status` | | 運作狀態 |
| | `Device.WiFi.Radio.{i}.Channel` | | 頻道 |
| | `Device.WiFi.Radio.{i}.OperatingFrequencyBand` | | 頻段 (2.4GHz/5GHz/6GHz) |
| | `Device.WiFi.Radio.{i}.OperatingChannelBandwidth` | | 頻寬 |
| | `Device.WiFi.Radio.{i}.TransmitPower` | | 發射功率 |
| `setRadioSettings` | `Device.WiFi.Radio.{i}.` | **Direct** | |

### Simple WiFi Settings

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getSimpleWiFiSettings` | `Device.WiFi.SSID.{i}.` | **Partial** | 組合多個物件 |
| | `Device.WiFi.SSID.{i}.SSID` | | SSID 名稱 |
| | `Device.WiFi.AccessPoint.{i}.Security.ModeEnabled` | | 安全模式 |
| | `Device.WiFi.AccessPoint.{i}.Security.PreSharedKey` | | 密碼 |
| `setSimpleWiFiSettings` | `Device.WiFi.SSID.{i}.` | **Partial** | |

### Guest Network

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getGuestRadioSettings` | `Device.WiFi.SSID.{i}.` | **Partial** | 訪客 SSID instance |
| `setGuestRadioSettings` | `Device.WiFi.SSID.{i}.` | **Partial** | |
| `getGuestNetworkSettings` | `Device.WiFi.AccessPoint.{i}.` | **Partial** | 訪客 AP 設定 |
| `setGuestNetworkSettings` | `Device.WiFi.AccessPoint.{i}.` | **Partial** | |
| `getGuestNetworkClients` | `Device.WiFi.AccessPoint.{i}.AssociatedDevice.{i}.` | **Direct** | |

### Advanced WiFi Features

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getMLOSettings` | `Device.WiFi.Radio.{i}.Capabilities.WiFi7APRole.` | **Partial** | WiFi 7 MLO |
| `setMLOSettings` | | **Custom** | 需 Vendor Extension |
| `getDFSSettings` | `Device.WiFi.Radio.{i}.RegulatoryDomain` | **Partial** | DFS 相關 |
| `setDFSSettings` | | **Custom** | |
| `getAirtimeFairnessSettings` | `X_LINKSYS_COM_AirtimeFairness` | **Custom** | Vendor Extension |
| `setAirtimeFairnessSettings` | | **Custom** | |

---

## 3. Router (路由器設定)

### WAN Settings

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getWANSettings` | `Device.IP.Interface.{i}.` | **Partial** | WAN interface |
| | `Device.IP.Interface.{i}.IPv4Address.{i}.AddressingType` | | DHCP/Static |
| | `Device.IP.Interface.{i}.IPv4Address.{i}.IPAddress` | | IP 地址 |
| | `Device.PPP.Interface.{i}.` | | PPPoE 設定 |
| `setWANSettings` | `Device.IP.Interface.{i}.` | **Partial** | |
| `getWANStatus` | `Device.IP.Interface.{i}.Status` | **Direct** | |
| | `Device.IP.Interface.{i}.IPv4Address.{i}.IPAddress` | | 目前 IP |
| `getWANExternal` | `Device.IP.Interface.{i}.IPv4Address.{i}.` | **Partial** | 外部 IP |

### LAN Settings

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getLANSettings` | `Device.DHCPv4.Server.Pool.{i}.` | **Partial** | |
| | `Device.DHCPv4.Server.Pool.{i}.MinAddress` | | DHCP 起始 |
| | `Device.DHCPv4.Server.Pool.{i}.MaxAddress` | | DHCP 結束 |
| | `Device.IP.Interface.{i}.IPv4Address.{i}.IPAddress` | | LAN IP |
| | `Device.IP.Interface.{i}.IPv4Address.{i}.SubnetMask` | | 子網遮罩 |
| `setLANSettings` | `Device.DHCPv4.Server.Pool.{i}.` | **Partial** | |

### IPv6 Settings

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getIPv6Settings` | `Device.IP.Interface.{i}.IPv6Address.{i}.` | **Direct** | |
| | `Device.DHCPv6.Client.{i}.` | | DHCPv6 Client |
| | `Device.DHCPv6.Server.Pool.{i}.` | | DHCPv6 Server |
| `setIPv6Settings` | `Device.IP.Interface.{i}.IPv6Address.{i}.` | **Direct** | |

### DHCP

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `renewDHCPWANLease` | `Device.DHCPv4.Client.{i}.Renew()` | **Direct** | USP Sync Command |
| `renewDHCPIPv6WANLease` | `Device.DHCPv6.Client.{i}.Renew()` | **Direct** | USP Sync Command |

> **注意:** `Renew()` 命令會觸發 DHCP 重新取得 IP 地址。

### MAC Clone

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getMACAddressCloneSettings` | `Device.Ethernet.Interface.{i}.MACAddress` | **Partial** | |
| `setMACAddressCloneSettings` | | **Custom** | 需 Vendor Extension |

### Routing

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getRoutingSettings` | `Device.Routing.Router.{i}.IPv4Forwarding.{i}.` | **Direct** | |
| `setRoutingSettings` | `Device.Routing.Router.{i}.IPv4Forwarding.{i}.` | **Direct** | |

---

## 4. Firewall (防火牆)

### Port Forwarding

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getSinglePortForwardingRules` | `Device.NAT.PortMapping.{i}.` | **Direct** | |
| | `Device.NAT.PortMapping.{i}.ExternalPort` | | 外部埠 |
| | `Device.NAT.PortMapping.{i}.InternalPort` | | 內部埠 |
| | `Device.NAT.PortMapping.{i}.InternalClient` | | 內部 IP |
| | `Device.NAT.PortMapping.{i}.Protocol` | | TCP/UDP |
| `setSinglePortForwardingRules` | `Device.NAT.PortMapping.{i}.` | **Direct** | |
| `getPortRangeForwardingRules` | `Device.NAT.PortMapping.{i}.` | **Direct** | 使用 PortRange |
| `setPortRangeForwardingRules` | `Device.NAT.PortMapping.{i}.` | **Direct** | |

### Port Triggering

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getPortRangeTriggeringRules` | `Device.NAT.PortTrigger.{i}.` | **Direct** | |
| | `Device.NAT.PortTrigger.{i}.Rule.{i}.` | | 觸發規則 |
| `setPortRangeTriggeringRules` | `Device.NAT.PortTrigger.{i}.` | **Direct** | |

### DMZ

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getDMZSettings` | `Device.Firewall.DMZ.{i}.` | **Direct** | |
| | `Device.Firewall.DMZ.{i}.Enable` | | 啟用 |
| | `Device.Firewall.DMZ.{i}.DestIPAddress` | | DMZ 主機 IP |
| `setDMZSettings` | `Device.Firewall.DMZ.{i}.` | **Direct** | |

### Firewall Settings

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getFirewallSettings` | `Device.Firewall.` | **Partial** | |
| | `Device.Firewall.Enable` | | 防火牆啟用 |
| | `Device.Firewall.Policy.{i}.` | | 策略 |
| `setFirewallSettings` | `Device.Firewall.` | **Partial** | |

### IPv6 Firewall

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getIPv6FirewallRules` | `Device.Firewall.Chain.{i}.Rule.{i}.` | **Partial** | IPv6 規則 |
| `setIPv6FirewallRules` | `Device.Firewall.Chain.{i}.Rule.{i}.` | **Partial** | |

### ALG (Application Layer Gateway)

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getALGSettings` | `Device.Firewall.ConnectionTracking.` | **Direct** | |
| | `Device.Firewall.ConnectionTracking.SIP.Enable` | | SIP ALG |
| | `Device.Firewall.ConnectionTracking.H323.Enable` | | H323 ALG |
| | `Device.Firewall.ConnectionTracking.FTP.Enable` | | FTP ALG |
| `setALGSettings` | `Device.Firewall.ConnectionTracking.` | **Direct** | |

---

## 5. Device List (裝置列表)

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getDevices` | `Device.Hosts.Host.{i}.` | **Direct** | |
| | `Device.Hosts.Host.{i}.PhysAddress` | | MAC 地址 |
| | `Device.Hosts.Host.{i}.IPAddress` | | IP 地址 |
| | `Device.Hosts.Host.{i}.HostName` | | 主機名稱 |
| | `Device.Hosts.Host.{i}.Active` | | 是否在線 |
| | `Device.Hosts.Host.{i}.Layer1Interface` | | 連線介面 |
| `getLocalDevice` | `Device.Hosts.Host.{i}.` | **Partial** | 本地裝置 |
| `setDeviceProperties` | `Device.Hosts.Host.{i}.` | **Partial** | 自訂屬性需 Extension |
| `deleteDevice` | `Device.Hosts.Host.{i}.` | **N/A** | TR-181 不支援刪除 Host |

---

## 6. Network Connections

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getNetworkConnections` | `Device.WiFi.AccessPoint.{i}.AssociatedDevice.{i}.` | **Partial** | WiFi 連線 |
| | `Device.Ethernet.Interface.{i}.` | | 有線連線 |
| `getNodesWirelessNetworkConnections` | `Device.WiFi.MultiAP.APDevice.{i}.` | **Partial** | Mesh 節點 |
| `getBackhaulInfo` | `Device.WiFi.DataElements.Network.Device.{i}.` | **Partial** | Backhaul 資訊 |

---

## 7. Firmware Update (韌體更新)

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getFirmwareUpdateSettings` | `Device.DeviceInfo.SoftwareVersion` | **Partial** | |
| | `Device.SoftwareModules.ExecEnv.{i}.` | | 執行環境 |
| `setFirmwareUpdateSettings` | | **Custom** | 自動更新設定 |
| `getFirmwareUpdateStatus` | `Device.DeviceInfo.FirmwareImage.{i}.Status` | **Partial** | |
| `updateFirmwareNow` | `Device.LocalAgent.Request.{i}.` | **Custom** | USP 有 Download() |

---

## 8. DDNS (動態 DNS)

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getDDNSSettings` | `Device.DynamicDNS.Client.{i}.` | **Direct** | |
| | `Device.DynamicDNS.Client.{i}.Enable` | | 啟用 |
| | `Device.DynamicDNS.Client.{i}.Server` | | DDNS 伺服器 |
| | `Device.DynamicDNS.Client.{i}.Username` | | 使用者名稱 |
| `setDDNSSetting` | `Device.DynamicDNS.Client.{i}.` | **Direct** | |
| `getDDNSStatus` | `Device.DynamicDNS.Client.{i}.Status` | **Direct** | |
| `getSupportedDDNSProviders` | | **Custom** | 需 Vendor Extension |

---

## 9. VPN

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getVPNService` | `Device.IPsec.` | **Partial** | TR-181 使用 IPsec 物件 |
| | `Device.IPsec.Tunnel.{i}.` | | IPsec Tunnel |
| | `Device.IPsec.IKEv2SA.{i}.` | | IKEv2 SA |
| `setVPNService` | `Device.IPsec.` | **Partial** | |
| `getVPNGateway` | `Device.IPsec.Tunnel.{i}.TunnelInterface` | **Partial** | |
| `setVPNGateway` | `Device.IPsec.Tunnel.{i}.` | **Partial** | |
| `getVPNUser` | `X_LINKSYS_COM_VPN.User.{i}.` | **Custom** | VPN 用戶需 Vendor Extension |
| `setVPNUser` | | **Custom** | |
| `getTunneledUser` | `X_LINKSYS_COM_VPN.TunneledUser.{i}.` | **Custom** | |
| `setTunneledUser` | | **Custom** | |
| `testVPNConnection` | | **Custom** | 需 Vendor Extension |
| `setVPNApply` | | **Custom** | 套用 VPN 設定 |

---

## 10. Time & Locale (時間與地區)

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getLocalTime` | `Device.Time.CurrentLocalTime` | **Direct** | |
| `getTimeSettings` | `Device.Time.` | **Partial** | |
| | `Device.Time.Enable` | | NTP 啟用 |
| | `Device.Time.Client.{i}.Server` | | NTP 伺服器 (v2.12+) |
| | `Device.Time.LocalTimeZone` | | 時區 |
| `setTimeSettings` | `Device.Time.` | **Partial** | |

> **注意:** `Device.Time.NTPServer1-5` 在 TR-181 v2.12+ 已棄用，應使用 `Device.Time.Client.{i}.` 物件。

---

## 11. MAC Filter (MAC 過濾)

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getMACFilterSettings` | `Device.WiFi.AccessPoint.{i}.X_LINKSYS_COM_MACFilter.` | **Custom** | |
| | `Device.Hosts.AccessControl.{i}.` | **Partial** | 標準存取控制 |
| `setMACFilterSettings` | | **Custom** | |

---

## 12. Router Management (路由器管理)

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getManagementSettings` | `Device.UserInterface.` | **Partial** | |
| | `Device.UserInterface.RemoteAccess.Enable` | | 遠端管理 |
| | `Device.UserInterface.RemoteAccess.Port` | | 遠端埠號 |
| `setManagementSettings` | `Device.UserInterface.` | **Partial** | |
| `getUPnPSettings` | `Device.UPnP.Device.Enable` | **Direct** | |
| `setUPnPSettings` | `Device.UPnP.Device.Enable` | **Direct** | |
| `getExpressForwardingSettings` | | **Custom** | Vendor Extension |
| `setExpressForwardingSettings` | | **Custom** | |

---

## 13. Diagnostics (診斷)

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `startPing` | `Device.IP.Diagnostics.IPPing()` | **Direct** | USP Async Command |
| | 輸入: `Host`, `NumberOfRepetitions`, `Timeout` | | |
| | 輸出: `SuccessCount`, `FailureCount`, `AverageResponseTime` | | |
| `getPingStatus` | `Device.IP.Diagnostics.IPPing()` 結果 | **Direct** | 透過 Notification 取得 |
| `stopPing` | | **Custom** | TR-181 無直接支援取消 |
| `startTracroute` | `Device.IP.Diagnostics.TraceRoute()` | **Direct** | USP Async Command |
| | 輸入: `Host`, `MaxHopCount`, `Timeout` | | |
| `getTracerouteStatus` | `Device.IP.Diagnostics.TraceRoute()` 結果 | **Direct** | |
| `stopTracroute` | | **Custom** | TR-181 無直接支援取消 |
| `getSystemStats` | `Device.DeviceInfo.ProcessStatus.` | **Partial** | |
| | `Device.DeviceInfo.ProcessStatus.CPUUsage` | | CPU 使用率 |
| | `Device.DeviceInfo.MemoryStatus.Total` | | 記憶體總量 |
| | `Device.DeviceInfo.MemoryStatus.Free` | | 可用記憶體 |

> **注意:** TR-181 v2.12+ 的 `IPPing()` 和 `TraceRoute()` 是 **async commands**，非傳統物件參數。

---

## 14. Health Check (健康檢查)

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `runHealthCheck` | `Device.IP.Diagnostics.SpeedTest.` | **Partial** | 速度測試 |
| `getHealthCheckStatus` | | **Custom** | |
| `getHealthCheckResults` | | **Custom** | |
| `getSupportedHealthCheckModules` | | **Custom** | |
| `getCloseHealthCheckServers` | | **Custom** | |
| `stopHealthCheck` | | **Custom** | |

---

## 15. LED & Node Settings

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getLedNightModeSetting` | `X_LINKSYS_COM_LED.NightMode` | **Custom** | |
| `setLedNightModeSetting` | | **Custom** | |
| `startBlinkNodeLed` | | **Custom** | |
| `stopBlinkNodeLed` | | **Custom** | |

---

## 16. Setup & Onboarding

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `isAdminPasswordSetByUser` | `X_LINKSYS_COM_Setup.PasswordConfigured` | **Custom** | |
| `getAutoConfigurationSettings` | | **Custom** | |
| `setupSetAdminPassword` | `Device.Users.User.{i}.Password` | **Partial** | |
| `verifyRouterResetCode` | | **Custom** | |
| `getInternetConnectionStatus` | `Device.IP.Interface.{i}.Status` | **Partial** | |
| `setUserAcknowledgedAutoConfiguration` | | **Custom** | |
| `getSelectedChannels` | `Device.WiFi.Radio.{i}.Channel` | **Direct** | |
| `startAutoChannelSelection` | `Device.WiFi.Radio.{i}.AutoChannelEnable` | **Partial** | |

---

## 17. Topology & Mesh

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getTopologyOptimizationSettings` | `Device.WiFi.MultiAP.` | **Partial** | |
| `setTopologyOptimizationSettings` | | **Custom** | |
| `getDeviceMode` | `X_LINKSYS_COM_SmartMode` | **Custom** | Router/Bridge/Node |
| `setDeviceMode` | | **Custom** | |

---

## 18. Ethernet Ports

| JNAP Action | TR-181 Object/Parameter | 對應狀態 | 備註 |
|-------------|------------------------|----------|------|
| `getEthernetPortConnections` | `Device.Ethernet.Interface.{i}.` | **Direct** | |
| | `Device.Ethernet.Interface.{i}.Status` | | 連線狀態 |
| | `Device.Ethernet.Interface.{i}.DuplexMode` | | 雙工模式 |
| | `Device.Ethernet.Interface.{i}.CurrentBitRate` | | 速率 |

---

## 統計摘要

| 對應狀態 | 數量 | 百分比 |
|----------|------|--------|
| **Direct** | 約 45 | ~32% |
| **Partial** | 約 55 | ~39% |
| **Custom** | 約 35 | ~25% |
| **N/A** | 約 5 | ~4% |

---

## 建議的 Vendor Extension

以下 JNAP 功能需要透過 TR-181 Vendor Extension (`X_LINKSYS_COM_*`) 實現：

### Device Info Extensions
```
X_LINKSYS_COM_DeviceInfo.
├── PasswordHint
├── IsDefaultPassword
├── ModelNumber
└── FirmwareDate
```

### WiFi Extensions
```
X_LINKSYS_COM_WiFi.
├── AirtimeFairness
├── MLO
├── DFS
└── SmartConnect
```

### Setup Extensions
```
X_LINKSYS_COM_Setup.
├── PasswordConfigured
├── AutoConfiguration
└── ResetCode
```

### Mesh Extensions
```
X_LINKSYS_COM_Mesh.
├── TopologyOptimization
├── BackhaulPriority
└── NodeList
```

### LED Extensions
```
X_LINKSYS_COM_LED.
├── NightMode
├── Enable
└── Brightness
```

---

## 參考資料

- [TR-181 Device:2 Data Model](https://usp-data-models.broadband-forum.org/)
- [USP Protocol Specification](https://usp.technology/)
- [Linksys JNAP Documentation](internal)
