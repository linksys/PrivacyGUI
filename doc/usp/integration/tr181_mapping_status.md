# PrivacyGUI: JNAP to TR-181 Mapping Status

**最新更新:** 2026-02-24
**用途:** 本文件用於記錄從舊有 JNAP Actions 轉換對應至官方 TR-181 XML (`doc/usp/tr-181-2-20-0-usp-full.xml`) 的盤點狀況。
若遇到無法直接對應、需要額外 Transform 或需要 Router 韌體端開新特規節點的狀況，皆記錄於此。

## 狀態說明 (Status Criteria)
- 🟢 **直接對應 (Direct Match)**: 在 TR-181 中有完全符合的欄位與意義。
- 🟡 **需運算轉換 (Needs Transform)**: 找到對應欄位，但型別或單位不同，需在 `_ext.yaml` 處理。
- 🔴 **無法對應 (Unmappable)**: 在標準 TR-181 中找不到對應概念，需跟韌體團隊討論是否新增 Vendor Specific 節點 (如 `X_LINKSYS_...`)。

---

## 模組一：基礎系統與設備資訊 (System & Device Info)

| JNAP Action / API | 舊有使用欄位 | TR-181 對應路徑 (Base Path: `Device.DeviceInfo.`) | 狀態 | 備註 / 需進行的 Transform |
| :--- | :--- | :--- | :---: | :--- |
| `getHardwareInfo` | `manufacturer` | `Manufacturer` | 🟢 | |
| `getHardwareInfo` | `modelNumber` | `ModelName` | 🟢 | |
| `getHardwareInfo` | `firmwareVersion` | `SoftwareVersion` | 🟢 | |
| `getHardwareInfo` | `firmwareDate` | **None** | 🔴 | TR-181 標準無此欄位，確認 UI 是否絕對需要顯示？ |
| `getSystemStats` | `uptimeSeconds` | `UpTime` | 🟢 | |

---

## 模組二：網路與連線狀態 (Network & Connectivity)

| JNAP Action / API | 舊有使用欄位 | TR-181 對應路徑 | 狀態 | 備註 / 需進行的 Transform |
| :--- | :--- | :--- | :---: | :--- |
| `GetWANStatus` | `wanStatus` | `Device.IP.Interface.1.Status` | 🟡 | 需從 "Up"/"Down" 轉為 "Connected"/"Disconnected" |

---

## 模組三：無線網路設定 (WiFi Settings)

| JNAP Action / API | 舊有使用欄位 | TR-181 對應路徑 (Base Path: `Device.WiFi.`) | 狀態 | 備註 / 需進行的 Transform |
| :--- | :--- | :--- | :---: | :--- |
| `getRadioInfo` | `mode` | `Radio.{i}.OperatingStandards` | 🟡 | 需對齊 JNAP 的 `"802.11ax"` 格式 |

---

## 模組四：連線設備列表 (Connected Devices)

| JNAP Action / API | 舊有使用欄位 | TR-181 對應路徑 | 狀態 | 備註 / 需進行的 Transform |
| :--- | :--- | :--- | :---: | :--- |
| `GetDevices` | `macAddress` | `Device.Hosts.Host.{i}.PhysAddress` | 🟢 | Client 端口屬性 |

---

*(盤點期間請隨時擴充此表格)*
