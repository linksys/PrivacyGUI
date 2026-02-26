# PrivacyGUI: Unmappable & Hardcoded Fields Tracker

**版本:** v1.0.0
**最新更新:** 2026-02-24
**用途:** 追蹤從舊有 JNAP 映射 (`jnap_tr181_mapper.dart`) 中識別出的無法直接對應 TR-181 標準的欄位。包含 hardcoded 值、vendor-specific 資料、以及需要韌體團隊協助的項目。

## 狀態說明

- 🔴 **無法對應 (Unmappable)**: TR-181 標準中不存在此概念，需 vendor extension 或 UI 捨棄
- 🟠 **Hardcoded/Mock**: PoC 中使用固定值，需找到正確 TR-181 來源或確認由 Router 提供
- 🟡 **需運算轉換 (Needs Transform)**: 有 TR-181 來源但需在 `_ext.yaml` 中定義轉換邏輯
- 🔵 **Heuristic/脆弱假設**: 使用了基於索引或慣例的推測，非正式 TR-181 對應

---

## 模組一：基礎系統與設備資訊 (GetDeviceInfo)

**來源:** `jnap_tr181_mapper.dart` `_mapDeviceInfo()` :216-233

| JNAP 欄位 | 目前處理方式 | 問題描述 | 建議解法 | 狀態 | 負責 |
|:---|:---|:---|:---|:---:|:---|
| `firmwareDate` | `''` (空字串) | TR-181 標準無此欄位 | 請韌體團隊新增 `X_LINKSYS_FirmwareDate` vendor node，或 UI 捨棄此顯示 | 🔴 | Firmware |
| `services` | hardcoded 17 個 service URL list | JNAP 特有概念，TR-181 無對應 | 在新架構中改用 `GetSupportedDM` 動態發現 device capabilities，或以 `capability_repository` 替代 | 🔴 | UI + Platform |
| `description` | `Device.DeviceInfo.Description` | 可能回傳空值，部分 Router 不實作此欄位 | 確認目標 Router 是否支援；fallback 可用 ModelName | 🟠 | Firmware |

---

## 模組二：無線網路設定 (GetRadioInfo)

**來源:** `jnap_tr181_mapper.dart` `_mapRadioInfo()` :266-354

| JNAP 欄位 | 目前處理方式 | 問題描述 | 建議解法 | 狀態 | 負責 |
|:---|:---|:---|:---|:---:|:---|
| `physicalRadioID` | hardcoded `'ath${i-1}0'` | Vendor-specific 物理介面名稱，TR-181 無此欄位 | 請韌體團隊新增 `X_LINKSYS_PhysicalRadioID`，或 UI 改用 `Radio.{i}.Name` | 🔴 | Firmware |
| `isBandSteeringSupported` | hardcoded `false` | TR-181 標準無 band steering 概念 | 請韌體團隊新增 `X_LINKSYS_BandSteeringSupported`，或透過 `GetSupportedDM` 偵測 | 🔴 | Firmware |
| `maxRADIUSSharedKeyLength` | hardcoded `64` | TR-181 無此限制欄位 | hardcode 在 definition YAML 的 `maximum_length` 約束中，或請韌體提供 | 🟠 | Platform |
| `defaultMixedMode` | 取 `supportedModes.last` | 邏輯推導，非直接 TR-181 | 可在 `_ext.yaml` transform 中定義 | 🟡 | UI |
| `supportedModes` 格式轉換 | `_convertToJnapModes()` | TR-181 `SupportedStandards` 格式為 `"b,g,n,ax"`，JNAP 為 `"802.11bgn"` | 在 `_ext.yaml` 定義 mapping transform | 🟡 | UI |
| `channelWidth` 格式 | 直接使用 TR-181 值 | TR-181 為 `"Auto"/"20MHz"` 等，JNAP 為 `"Auto"/"Standard"/"Wide"` | 在 `_ext.yaml` 定義 mapping transform | 🟡 | UI |

---

## 模組三：連線設備列表 (GetDevices)

**來源:** `jnap_tr181_mapper.dart` `_mapDevices()` :439-562

| JNAP 欄位 | 目前處理方式 | 問題描述 | 建議解法 | 狀態 | 負責 |
|:---|:---|:---|:---|:---:|:---|
| `model.deviceType` | hardcoded `'Computer'` (hosts) / `'Infrastructure'` (AP) | JNAP 特有分類，TR-181 `Host` 無 device type 欄位 | 請韌體於 `X_LINKSYS_DeviceType` 提供，或 UI 根據 `InterfaceType` + `MultiAP` 判斷 | 🔴 | Firmware/UI |
| `maxAllowedProperties` | hardcoded `10` | JNAP device property limit，TR-181 無此概念 | hardcode 於 UI 常數 | 🟠 | UI |
| `lastChangeRevision` | hardcoded `0` | JNAP revision tracking，TR-181 無對應 | 改用 subscription `ValueChange` 機制替代 revision 追蹤 | 🔴 | UI |
| `isAuthority` | 從 `BackhaulLinkType == 'None'` 推導 | JNAP 概念，表示是否為 master node | 邏輯推導可保留，在 `_ext.yaml` transform 中定義 | 🟡 | UI |
| `nodeType` (`Master`/`Slave`) | 從 `BackhaulLinkType` 推導 | JNAP 特有命名 | 在 `_ext.yaml` 定義 mapping: `None` → `Master`，其他 → `Slave` | 🟡 | UI |
| `friendlyName` (AP devices) | hardcoded `'Master Router'`/`'Mesh Node'` | PoC placeholder | 請韌體於 `X_LINKSYS_FriendlyName` 提供，或 UI 根據 Hostname/model 組合 | 🟠 | Firmware/UI |
| band 推導 (WiFi hosts) | heuristic: `ssidIndex 1/4=2.4G, 2=5G, 3=6G` | 基於 SSID index 假設，不同 Router 配置不同 | 應透過 `SSID.{i}.LowerLayers` → `Radio.{i}.OperatingFrequencyBand` 正式查詢 | 🔵 | UI |

---

## 模組四：Backhaul 資訊 (GetBackhaulInfo)

**來源:** `jnap_tr181_mapper.dart` `_mapBackhaulInfo()` :566-628

| JNAP 欄位 | 目前處理方式 | 問題描述 | 建議解法 | 狀態 | 負責 |
|:---|:---|:---|:---|:---:|:---|
| `deviceUUID` | 使用 `MACAddress` 代替 | TR-181 MultiAP `APDevice` 無 UUID/ALID 欄位 | 請韌體於 `X_LINKSYS_DeviceUUID` 提供，或統一以 MAC 作為 ID | 🔴 | Firmware |
| `ipAddress` | hardcoded mock `'192.168.1.${10+i}'` | "standard MultiAP APDevice doesn't expose IP" | 請韌體於 `X_LINKSYS_IPAddress` 或透過 `Hosts.Host` 交叉查詢 | 🔴 | Firmware |
| `parentIPAddress` | hardcoded `'192.168.1.1'` | 無 TR-181 對應 | 同上，需 Firmware 提供或交叉查詢 | 🔴 | Firmware |
| `radioID` | hardcoded `'RADIO_5GHz'` | 未從 TR-181 取得實際 backhaul radio | 應從 `BackhaulLinkType` + `Radio.OperatingFrequencyBand` 推導 | 🟠 | UI |
| `channel` | hardcoded `0` | 未查詢 backhaul channel | 可從 `Radio.{i}.Channel` 取得 | 🟠 | UI |
| `txRate` / `rxRate` | hardcoded `0` | MultiAP 標準不提供 backhaul throughput | 請韌體於 `X_LINKSYS_BackhaulTxRate`/`RxRate` 提供 | 🔴 | Firmware |
| `isMultiLinkOperation` | hardcoded `false` | WiFi 7 MLO 功能，TR-181 尚未標準化 | 待 BBF 更新或韌體提供 `X_LINKSYS_MLOEnabled` | 🔴 | Firmware |
| `speedMbps` | hardcoded `'0'` | 同 txRate/rxRate | 同上 | 🔴 | Firmware |
| RSSI → dBm 轉換 | `_mapBackhaulInfo()` 中 RCPI 公式 | TR-181 `BackhaulSignalStrength` 可能是 RCPI (0-220) 或 dBm | 需確認 Router 韌體回傳格式，在 `_ext.yaml` 定義 converter | 🟡 | Firmware/UI |

---

## 模組五：WAN 狀態 (GetWANStatus)

**來源:** `jnap_tr181_mapper.dart` `_mapWANStatus()` :633-692

| JNAP 欄位 | 目前處理方式 | 問題描述 | 建議解法 | 狀態 | 負責 |
|:---|:---|:---|:---|:---:|:---|
| `wanIPv6Status` | hardcoded `'Disconnected'` | PoC 未實作 IPv6 | 需從 `Device.IP.Interface.1.IPv6Address` 查詢 | 🟠 | UI |
| `isDetectingWANType` | hardcoded `false` | JNAP 特有狀態，TR-181 無此概念 | 由 UI 層自行管理偵測狀態，不需 TR-181 對應 | 🔴 | UI |
| `mtu` | hardcoded `1500` | 未查詢實際 MTU | 可從 `Device.IP.Interface.1.MaxMTUSize` 取得 | 🟠 | UI |
| `dhcpLeaseMinutes` | hardcoded `4320` | 未查詢實際 lease time | 可從 `Device.DHCPv4.Client.1.LeaseTimeRemaining` 取得 | 🟠 | UI |
| `dnsServer1` | fallback `'8.8.8.8'` | 未從 DHCP 取得 DNS | 可從 `Device.DHCPv4.Client.1.DNSServers` 取得 | 🟠 | UI |
| `supportedWANTypes` | hardcoded list | Router 支援的 WAN 類型，TR-181 無對應 | 請韌體於 `X_LINKSYS_SupportedWANTypes` 提供，或透過 `GetSupportedDM` 推斷 | 🔴 | Firmware |
| `supportedIPv6WANTypes` | hardcoded list | 同上 | 同上 | 🔴 | Firmware |
| `supportedWANCombinations` | hardcoded list | 同上 | 同上 | 🔴 | Firmware |
| WAN status 轉換 | `ifStatus == 'Up' ? 'Connected' : 'Disconnected'` | TR-181 `Status` 與 JNAP `wanStatus` 命名不同 | 在 `_ext.yaml` 定義 mapping transform | 🟡 | UI |

---

## 模組六：LAN 設定 (GetLANSettings)

**來源:** `jnap_tr181_mapper.dart` `_mapLANSettings()` :814-850

| JNAP 欄位 | 目前處理方式 | 問題描述 | 建議解法 | 狀態 | 負責 |
|:---|:---|:---|:---|:---:|:---|
| `minNetworkPrefixLength` | hardcoded `16` | Router 限制，TR-181 無對應 | hardcode 於 definition YAML `minimum` | 🟠 | Platform |
| `maxNetworkPrefixLength` | hardcoded `30` | 同上 | hardcode 於 definition YAML `maximum` | 🟠 | Platform |
| `minAllowedDHCPLeaseMinutes` | hardcoded `1` | 同上 | 同上 | 🟠 | Platform |
| `maxAllowedDHCPLeaseMinutes` | hardcoded `525600` | 同上 | 同上 | 🟠 | Platform |
| `maxDHCPReservationDescriptionLength` | hardcoded `63` | 同上 | 同上 | 🟠 | Platform |
| `dhcpSettings.leaseMinutes` | hardcoded `1440` | 未查詢實際值 | 可從 `Device.DHCPv4.Server.Pool.1.LeaseTime` 取得 | 🟠 | UI |
| `dhcpSettings.reservations` | hardcoded `[]` | 未查詢 DHCP reservations | 需從 `Device.DHCPv4.Server.Pool.1.StaticAddress.` 取得 | 🟠 | UI |
| `dhcpSettings.dnsServer1/2` | hardcoded `'8.8.8.8'`/`'8.8.4.4'` | 未查詢實際設定 | 可從 `Device.DHCPv4.Server.Pool.1.DNSServers` 取得 | 🟠 | UI |

---

## 模組七：時間設定 (GetTimeSettings)

**來源:** `jnap_tr181_mapper.dart` `_mapTimeSettings()` :853-869

| JNAP 欄位 | 目前處理方式 | 問題描述 | 建議解法 | 狀態 | 負責 |
|:---|:---|:---|:---|:---:|:---|
| `isDaylightSaving` | hardcoded `false` | "No easy way to tell from TR-181" | 需解析 `Device.Time.LocalTimeZone` 的 TZ string，或請韌體提供 | 🔴 | Firmware/UI |
| `dstSetting` | hardcoded `'Auto'` | JNAP 特有設定，TR-181 無對應 | 同上 | 🔴 | Firmware |
| `autoAdjustDST` | hardcoded `true` | 同上 | 同上 | 🔴 | Firmware |

---

## 模組八：Guest Network (GetGuestRadioSettings)

**來源:** `jnap_tr181_mapper.dart` `_mapGuestRadioSettings()` :871-932

| JNAP 欄位 | 目前處理方式 | 問題描述 | 建議解法 | 狀態 | 負責 |
|:---|:---|:---|:---|:---:|:---|
| `radioID` | heuristic `i % 2 == 0 ? '5GHz' : '2.4GHz'` | 基於 AP index 猜測，不可靠 | 應透過 `AccessPoint.{i}.SSIDReference` → `SSID.{i}.LowerLayers` → `Radio` chain 查詢 | 🔵 | UI |
| `guestSSID` | hardcoded `'DartSim_Guest'` | "Placeholder or need cross-ref" | 需從 `AccessPoint.{i}.SSIDReference` → `SSID.{i}.SSID` 取得 | 🟠 | UI |
| `canEnableRadio` | hardcoded `true` | 無 TR-181 對應 | hardcode 或透過 `GetSupportedDM` 檢查 | 🟠 | Platform |
| `isGuestNetworkACaptivePortal` | hardcoded `false` | 無標準 TR-181 欄位 | 請韌體於 `X_LINKSYS_CaptivePortalEnabled` 提供 | 🔴 | Firmware |
| `maxSimultaneousGuests` | hardcoded `50` | 無 TR-181 對應 | 請韌體提供或 hardcode 於 definition | 🟠 | Firmware/Platform |

---

## 模組九：MAC Filter (GetMACFilterSettings)

**來源:** `jnap_tr181_mapper.dart` `_mapMACFilterSettings()` :934-957

| JNAP 欄位 | 目前處理方式 | 問題描述 | 建議解法 | 狀態 | 負責 |
|:---|:---|:---|:---|:---:|:---|
| `maxMACAddresses` | hardcoded `32` | Router 限制，TR-181 無對應 | hardcode 於 definition YAML `maximum` | 🟠 | Platform |
| `macFilterMode` 轉換 | `isEnabled ? 'Allow' : 'Deny'` | 簡化映射，實際可能需要更複雜邏輯 | 在 `_ext.yaml` 定義 mapping transform | 🟡 | UI |

---

## 模組十：Network Connections (GetNetworkConnections2)

**來源:** `jnap_tr181_mapper.dart` `_mapNetworkConnections2()` :960-1070

| JNAP 欄位 | 目前處理方式 | 問題描述 | 建議解法 | 狀態 | 負責 |
|:---|:---|:---|:---|:---:|:---|
| band 推導 | heuristic `AP 1=2.4G, 2=5G, 3=6G` | 基於 AP index 猜測，不同 Router 不同 | 正式路徑：`AP.{i}.SSIDReference` → `SSID.LowerLayers` → `Radio.OperatingFrequencyBand` | 🔵 | UI |
| `isGuest` | heuristic `apIndex == 4` | Guest AP index 假設 | 應根據 `AccessPoint.{i}.IsolationEnable == true` 判定 | 🔵 | UI |
| `isMLOCapable` | hardcoded `false` | WiFi 7 MLO，TR-181 尚未標準化 | 待 BBF 更新或 `X_LINKSYS_MLOCapable` | 🔴 | Firmware |
| `negotiatedMbps` (wired) | hardcoded `1000` | 假設 Gigabit | 可從 `Ethernet.Interface.{i}.CurrentBitRate` 取得 | 🟠 | UI |

---

## 模組十一：Nodes Wireless Connections (GetNodesWirelessNetworkConnections2)

**來源:** `jnap_tr181_mapper.dart` `_mapNodesWirelessNetworkConnections2()` :1072-1170

| JNAP 欄位 | 目前處理方式 | 問題描述 | 建議解法 | 狀態 | 負責 |
|:---|:---|:---|:---|:---:|:---|
| `timestamp` | `DateTime.now().toIso8601String()` | Mock timestamp，非實際資料 | 可從 `AssociatedDevice.{i}.LastConnectTime` 取得 (若支援) | 🟠 | Firmware/UI |
| band 推導 | 同模組十 | 同上 | 同上 | 🔵 | UI |
| `isMLOCapable` | hardcoded `false` | 同模組十 | 同上 | 🔴 | Firmware |

---

## 模組十二：系統統計 (GetSystemStats)

**來源:** `jnap_tr181_mapper.dart` `_mapSystemStats()` :694-719

| JNAP 欄位 | 目前處理方式 | 問題描述 | 建議解法 | 狀態 | 負責 |
|:---|:---|:---|:---|:---:|:---|
| `CPULoad` 格式 | `(cpuUsage / 100).toString()` | TR-181 `CPUUsage` 為 0-100 整數，JNAP 為 0.0-1.0 字串 | 在 `_ext.yaml` 定義 formula transform | 🟡 | UI |
| `MemoryLoad` 格式 | `(total - free) / total` | 需從兩個 TR-181 值計算 | 在 `_ext.yaml` 定義 formula transform | 🟡 | UI |

---

## 統計摘要

| 狀態 | 數量 | 說明 |
|:---:|:---:|:---|
| 🔴 | **22** | 需 vendor extension (`X_LINKSYS_*`) 或架構變更 |
| 🟠 | **21** | 需找到正確 TR-181 來源或確認 hardcode 策略 |
| 🟡 | **10** | 可在 `_ext.yaml` transform 中解決 |
| 🔵 | **5** | 需修正 heuristic 為正式 TR-181 path chain 查詢 |
| **合計** | **58** | |

---

## 優先處理建議

### 高優先 — 需與韌體團隊討論的 vendor extension

以下欄位需要韌體團隊新增 `X_LINKSYS_*` TR-181 vendor node：

1. `firmwareDate` → `X_LINKSYS_FirmwareDate`
2. `physicalRadioID` → `X_LINKSYS_PhysicalRadioID`
3. `isBandSteeringSupported` → `X_LINKSYS_BandSteeringSupported`
4. Backhaul IP/UUID → `X_LINKSYS_DeviceUUID`, `X_LINKSYS_IPAddress`
5. Backhaul txRate/rxRate → `X_LINKSYS_BackhaulTxRate`/`RxRate`
6. `supportedWANTypes` → `X_LINKSYS_SupportedWANTypes`
7. `isGuestNetworkACaptivePortal` → `X_LINKSYS_CaptivePortalEnabled`
8. DST 相關設定 → `X_LINKSYS_DSTSetting`
9. MLO 相關 → `X_LINKSYS_MLOEnabled`/`MLOCapable`

### 中優先 — UI 可自行處理

1. `services` list → 改用 `GetSupportedDM`
2. `lastChangeRevision` → 改用 subscription 機制
3. `isDetectingWANType` → UI 層自行管理
4. Band / Guest heuristic → 正式 TR-181 path chain 查詢
5. 所有 `_ext.yaml` transform (🟡 項目)

### 低優先 — hardcode 至 definition YAML

1. `maxRADIUSSharedKeyLength`, `maxMACAddresses` 等限制值
2. `minNetworkPrefixLength`, `maxNetworkPrefixLength` 等範圍值
