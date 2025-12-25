# JNAP 轉 TR-181 對應報告

**日期：** 2025-12-25
**來源檔案：** `apps/PrivacyGUI/lib/core/usp/jnap_tr181_mapper.dart`

本文件詳述了 USP Client POC 專案中，將 JNAP Action 轉換為 TR-181 資料模型的對應策略實作細節。

## 概述

`JnapTr181Mapper` 類別負責處理舊版 JNAP Action 與標準 TR-181 USP 路徑之間的轉換。它支援將 JNAP Action 轉換為用於擷取資料的 USP 路徑，並將回傳的 USP `GetResponse` 轉換回 JNAP 相容的 JSON 結構。

## 資料流與轉換架構

轉換過程遵循以下三階段管線：

### 1. 請求階段：Action 路徑解析 (Action to Path Resolution)
當 App 發出 JNAP Action 請求 (例如 `GetRadioInfo`) 時，Mapper 會識別所需的 TR-181 資料路徑。

*   **邏輯**：`getTr181Paths(JNAPAction)`
*   **步驟 1**：提取基礎名稱 (Base Name)。Mapper 會去除版本後綴 (例如 `GetRadioInfo3` → `GetRadioInfo`) 以確保向下相容性。
*   **步驟 2**：查表 (Lookup)。使用預定義的註冊表 (`_actionPathMappings`) 來查找關聯的路徑。
    *   *範例*：`GetRadioInfo` → `['Device.WiFi.']`

### 2. 擷取階段：USP 執行 (USP Execution)
`UspService` 使用解析出的路徑執行標準 USP `Get` 命令。
*   原始回應包含一系列 TR-181 物件 (例如 `Device.WiFi.Radio.1.Enable`)。

### 3. 回應階段：結果映射 (Result Mapping)
原始 TR-181 資料被轉換回 UI 所預期的舊版 JNAP JSON 格式。

*   **邏輯**：`toJnapResponse(JNAPAction, UspGetResponse)`
*   **步驟 1：扁平化 (Flattening)**：階層式的 USP 回應被扁平化為鍵值對 (Key-Value Map)，以便進行 O(1) 存取。
    *   *原始資料*：`Result(path: "Device.WiFi.Radio.1.Enable", value: "true")`
    *   *扁平 Map*：`{"Device.WiFi.Radio.1.Enable": "true"}`
*   **步驟 2：分派 (Dispatch)**：使用 Action 名稱將資料路由至特定的處理函式 (例如 `_mapRadioInfo`)。
*   **步驟 3：轉換 (Transformation)**：處理函式遍歷資料 (通常會計算如 `RadioNumberOfEntries` 等項目數) 並建構巢狀的 JNAP 物件。
    *   *範例*：將 `Device.WiFi.Radio.1.OperatingStandards` ("ax") 映射為 JSON `{"mode": "802.11ax"}`。

## 支援的 Action

目前支援以下 JNAP Action：

| JNAP Action | 觸發的 TR-181 路徑 | 處理方法 (Handler) |
| :--- | :--- | :--- |
| `GetDeviceInfo` | `Device.DeviceInfo.` | `_mapDeviceInfo` |
| `GetRadioInfo` | `Device.WiFi.*` | `_mapRadioInfo` |
| `GetDevices` | `Device.Hosts.`, `Device.WiFi.MultiAP.` | `_mapDevices` |
| `GetBackhaulInfo` | `Device.WiFi.MultiAP.` | `_mapBackhaulInfo` |
| `GetWANStatus` | `Device.IP.Interface.1.`, `Device.Ethernet.Interface.1.`, `Device.DHCPv4.Client.`, `Device.Routing.Router.1.` | `_mapWANSettings` |
| `GetLANSettings` | `Device.IP.Interface.2.`, `Device.DHCPv4.` | `_mapLANSettings` |
| `GetLocalTime` / `GetTimeSettings` | `Device.Time.` | `_mapTimeSettings` |
| `GetGuestRadioSettings` | `Device.WiFi.`, `Device.WiFi.AccessPoint.`, `Device.WiFi.SSID.`, `Device.WiFi.Radio.` | `_mapGuestRadioSettings` |
| `GetMACFilterSettings` | `Device.WiFi.AccessPoint.` | `_mapMACFilterSettings` |

---

## 欄位對應細節 (Field Mapping Details)

### 1. 裝置資訊 (Device Info)
**來源：** `Device.DeviceInfo.`

| JNAP 欄位 | TR-181 欄位 | 備註 |
| :--- | :--- | :--- |
| `manufacturer` | `.Manufacturer` | - |
| `modelNumber` | `.ModelName` | - |
| `serialNumber` | `.SerialNumber` | - |
| `hardwareVersion` | `.HardwareVersion` | 預設為 "v1.0" |
| `firmwareVersion` | `.SoftwareVersion` | 預設為 "1.0.0" |
| `description` | `.Description` | - |
| `services` | - | 回傳空列表 (TR-181 中無此資訊) |

### 2. 無線設定 (Radio Settings - `GetRadioInfo`)
**來源：** `Device.WiFi.Radio.{i}`, `Device.WiFi.SSID.{i}`, `Device.WiFi.AccessPoint.{i}`

| JNAP 欄位 | TR-181 路徑/邏輯 | 備註 |
| :--- | :--- | :--- |
| `radioID` | `.Name` | 例如 "RADIO_1" |
| `supportedModes` | `.SupportedStandards` | 映射 "b,g,n,ax" -> ["802.11bgnax", ...] |
| `settings.mode` | `.OperatingStandards` | 映射 "ax" -> "802.11ax" |
| `settings.channel` | `.Channel` | - |
| `settings.channelWidth` | `.OperatingChannelBandwidth` | "Auto", "Standard" (20MHz), "Wide" (40MHz+) |
| `settings.broadcastSSID` | `AccessPoint.{i}.SSIDAdvertisementEnabled` | - |
| `settings.security` | `AccessPoint.{i}.Security.ModeEnabled` | 例如 "WPA2-Personal" |
| `supportedSecurityTypes` | `AccessPoint.{i}.Security.ModesSupported` | 分割 CSV 字串 |

### 3. 連線裝置 (Connected Devices - `GetDevices`)
**來源：** 結合 `Device.Hosts.Host.{i}` (客戶端) 與 `Device.WiFi.MultiAP.APDevice.{i}` (Mesh 節點)。

| JNAP 欄位 | TR-181 (Hosts) | TR-181 (MultiAP) | 備註 |
| :--- | :--- | :--- | :--- |
| `deviceID` | `.PhysAddress` | `.MACAddress` | Mesh 使用 MAC，因 ID/ALID 無效 |
| `friendlyName` | `.HostName` | "Master Router" / "Mesh Node" | 依據 `BackhaulLinkType` 推導 |
| `ipAddress` | `.IPAddress` | - | Mesh IP 無法直接從 APDevice 取得 |
| `isOnline` | `.Active` | `true` | 若存在於 APDevice 表中即視為上線 |
| `interfaceType` | `.InterfaceType` | "Infrastructure" | "802.11"-> "Wireless", 其他為 "Wired" |
| `parentDeviceID` | - | `.BackhaulMACAddress` | 用於建構拓樸 (Topology) |
| `model.deviceType` | "Computer" | "Infrastructure" | - |

### 4. Backhaul 資訊 (`GetBackhaulInfo`)
**來源：** `Device.WiFi.MultiAP.APDevice.{i}` (跳過 `BackhaulLinkType == None` 的 Master)

| JNAP 欄位 | TR-181 欄位 | 邏輯/轉換 |
| :--- | :--- | :--- |
| `deviceUUID` | `.MACAddress` | - |
| `connectionType` | `.BackhaulLinkType` | "Wi-Fi" -> "Wireless", 其他 -> "Wired" |
| `wirelessConnectionInfo.apRSSI` | `.BackhaulSignalStrength` | `(rssi / 2) - 110` (RCPI 轉 dBm) |
| `wirelessConnectionInfo.apBSSID` | `.BackhaulMACAddress` | - |
| `wirelessConnectionInfo.stationBSSID` | `.MACAddress` | - |
| `ipAddress` | - | 模擬為 "192.168.1.x" |

### 5. 時間設定 (Time Settings - `GetLocalTime`)
**來源：** `Device.Time.`

| JNAP 欄位 | TR-181 欄位 | 備註 |
| :--- | :--- | :--- |
| `currentTime` | `.CurrentLocalTime` | ISO 8601 字串 |
| `timeZoneID` | `.LocalTimeZone` | 例如 "Asia/Taipei" |
| `ntpServer1` | `.NTPServer1` | - |
| `ntpServer2` | `.NTPServer2` | - |
| `isDaylightSaving` | - | 固定為 `false` |

### 6. 訪客網路 (Guest Network - `GetGuestRadioSettings`)
**來源：** `Device.WiFi.AccessPoint.{i}` 且 `IsolationEnable == true`

| JNAP 欄位 | TR-181 欄位 | 備註 |
| :--- | :--- | :--- |
| `isGuestNetworkEnabled` | - | 若有任何 Guest AP 啟用則為 true |
| `radios[].isEnabled` | `.Enable` | - |
| `radios[].broadcastGuestSSID` | `.SSIDAdvertisementEnabled` | - |
| `radios[].guestPassword` | `.Security.KeyPassphrase` | - |
| `radios[].guestSSID` | `.SSIDReference` | 名稱無法直接從 AP 物件取得，使用模擬值 |

### 7. MAC 過濾 (MAC Filtering - `GetMACFilterSettings`)
**來源：** `Device.WiFi.AccessPoint.1` (假設主 AP 控制全域設定)

| JNAP 欄位 | TR-181 欄位 | 邏輯 |
| :--- | :--- | :--- |
| `isEnabled` | `.MACAddressControlEnabled` | - |
| `macFilterMode` | - | 若啟用為 "Allow"，否則為 "Deny" |
| `macAddresses` | `.AllowedMACAddress` | 分割 CSV 字串為列表 (List) |

---

## 限制與模擬行為 (Limitations & Mocking behavior)
- **模擬 IP (Mock IPs)**：TR-181 `APDevice` 物件中原生不包含 IP 位址；目前使用模擬的 "192.168.1.x" IP。
- **時間 (Time)**：日光節約時間 (DST) 設定固定為 `autoAdjustDST: true`，因為 TR-181 Time 物件較為簡單。
- **WAN IPv6**：在此 POC 中固定顯示為 "Disconnected"。
