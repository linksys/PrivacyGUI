# LSWF vs PrivacyGUI 功能差異比對報告

## 概述

本報告詳細比對 **LSWF (Linksys Smart WiFi Router Web UI)** 與 **PrivacyGUI (Flutter App)** 兩個專案的功能差異。

| 項目 | LSWF (Master 專案) | PrivacyGUI |
|------|-------------------|------------|
| **類型** | Web 應用程式 | Flutter 跨平台 App |
| **技術棧** | jQuery + 原生 JS | Flutter + Riverpod |
| **平台** | 瀏覽器（桌面/行動） | iOS, Android, Web |
| **API** | JNAP (HTTP) | JNAP + Linksys Cloud API |
| **功能模組數** | 18 個 | 21 個 |

---

## 功能完整度比對

### ✅ 兩者都有的功能

| 功能類別 | LSWF 實作 | PrivacyGUI 實作 | 備註 |
|---------|----------|-----------------|------|
| **登入/認證** | ✅ 完整 | ✅ 完整 | 兩者皆支援雲端和本地登入 |
| **儀表板** | ✅ Widget 系統 | ✅ Dashboard | 架構不同但功能類似 |
| **設備清單** | ✅ Device List | ✅ Instant Devices | 功能相近 |
| **網路拓撲** | ✅ Device Map | ✅ Instant Topology | 視覺化呈現 |
| **WiFi 設定** | ✅ Wireless | ✅ Incredible WiFi | 核心功能相同 |
| **WiFi 進階設定** | ✅ Advanced | ✅ WiFi Advanced Settings | **兩者都有** |
| **訪客網路** | ✅ Guest Access | ✅ Instant Privacy | 功能相近 |
| **速度測試** | ✅ Speed Test | ✅ Health Check | 功能相同 |
| **防火牆** | ✅ Security/Firewall | ✅ Firewall | 功能相同 |
| **DMZ** | ✅ Security/DMZ | ✅ DMZ | 功能相同 |
| **Port 轉發** | ✅ Security | ✅ Apps & Gaming | 功能相同 |
| **VPN** | ✅ OpenVPN | ✅ VPN Settings | 功能相同 |
| **韌體更新** | ✅ Connectivity | ✅ Firmware Update | 功能相同 |
| **節點管理** | ✅ Velop 頁面 | ✅ Nodes | Mesh 節點管理 |
| **DDNS** | ✅ Security/DDNS | ✅ DDNS Settings | 功能相同 |
| **靜態路由** | ✅ Advanced Routing | ✅ Static Routing | 功能相同 |
| **DHCP 設定** | ✅ Local Network | ✅ Local Network | 功能相同 |
| **時區設定** | ✅ Connectivity | ✅ Instant Admin | 功能相同 |
| **MAC 過濾** | ✅ Wireless/MAC Filtering | ✅ MAC Filter | 功能相同 |

---

## 🔴 LSWF 獨有功能（PrivacyGUI 缺少）

### 1. 家長控制 (Parental Controls)

| 功能 | LSWF 實作 | PrivacyGUI 狀態 |
|------|----------|-----------------|
| **設備存取時間排程** | ✅ 完整 | ❌ 未實作 |
| **網站封鎖** | ✅ 完整 | ❌ 未實作 |
| **每週排程表** | ✅ 視覺化選擇器 | ❌ 未實作 |

> **評估**: LSWF 有完整的家長控制功能（706 行 JS），PrivacyGUI 的 Instant Safety 目前只有 Safe Browsing，缺少設備級的時間控制。

---

### 2. 媒體優先順序 / QoS (Media Prioritization)

| 功能 | LSWF 實作 | PrivacyGUI 狀態 |
|------|----------|-----------------|
| **QoS 開關** | ✅ | ❌ 未實作 |
| **設備優先順序** | ✅ 拖放排序 | ❌ 未實作 |
| **應用程式優先順序** | ✅ | ❌ 未實作 |
| **遊戲優先順序** | ✅ | ❌ 未實作 |
| **頻寬設定** | ✅ 自動/手動 | ❌ 未實作 |
| **WMM 設定** | ✅ | ❌ 未實作 |
| **LVVP** | ✅ | ❌ 未實作 |

> **評估**: LSWF 有完整的 QoS 功能（2,161 行 JS），PrivacyGUI 完全缺少此功能。

---

### 3. 外部儲存 / USB 儲存

| 功能 | LSWF 實作 | PrivacyGUI 狀態 |
|------|----------|-----------------|
| **儲存裝置清單** | ✅ | ❌ 未實作 |
| **FTP 伺服器設定** | ✅ | ❌ 未實作 |
| **SMB 伺服器設定** | ✅ | ❌ 未實作 |
| **媒體伺服器** | ✅ | ❌ 未實作 |
| **USB 印表機** | ✅ VUSB | ❌ 未實作 |
| **安全移除** | ✅ | ❌ 未實作 |

> **評估**: LSWF 有完整的 USB 儲存功能，PrivacyGUI 完全缺少。

---

### 4. WPS (WiFi Protected Setup)

| 功能 | LSWF 實作 | PrivacyGUI 狀態 |
|------|----------|-----------------|
| **Push Button** | ✅ | ❌ 未實作 |
| **Router PIN** | ✅ | ❌ 未實作 |
| **Device PIN** | ✅ | ❌ 未實作 |

> **評估**: LSWF 在 Wireless 模組中有完整 WPS 功能，PrivacyGUI 完全缺少。

---

### 5. Wireless Scheduler（WiFi 排程）

| 功能 | LSWF 實作 | PrivacyGUI 狀態 |
|------|----------|-----------------|
| **WiFi 開關排程** | ✅ | ❌ 未實作 |
| **每週時間表** | ✅ | ❌ 未實作 |

---

### 6. SimpleTap (NFC)

| 功能 | LSWF 實作 | PrivacyGUI 狀態 |
|------|----------|-----------------|
| **NFC WiFi 連線** | ✅ | ❌ 未實作 |

---

### 7. VLAN Tagging

| 功能 | LSWF 實作 | PrivacyGUI 狀態 |
|------|----------|-----------------|
| **獨立 VLAN 標籤設定頁面** | ✅ 有專門頁面 | ❌ 無獨立頁面 |
| **PPPoE over VLAN** | ✅ | ✅ **已實作**（PnP 設定流程） |
| **VLAN API 支援** | ✅ | ✅ 有 `getVLANTaggingSettings`/`setVLANTaggingSettings` |

> **確認**: PrivacyGUI 在 `wan_settings.dart` 中有 `SinglePortVLANTaggingSettings` 模型，並在 PnP 設定流程的 PPPoE 設定中支援 VLAN ID（有多語系字串 `pnpPppoeAddVlan`、`pnpPppoeRemoveVlan`）。但沒有像 LSWF 那樣的獨立 VLAN Tagging 設定頁面。

---

### 8. Power Modem (DSL)

| 功能 | LSWF 實作 | PrivacyGUI 狀態 |
|------|----------|-----------------|
| **DSL Modem 設定** | ✅ | ❌ 未實作 |
| **DSL 韌體更新** | ✅ | ❌ 未實作 |

---

### 9. 進階無線設定

| 功能 | LSWF 實作 | PrivacyGUI 狀態 |
|------|----------|-----------------|
| **Airtime Fairness (ATF)** | ✅ | ❌ 未實作 |
| **Dynamic Frequency Selection (DFS)** | ✅ | ✅ **已實作** |
| **Multi-Link Operation (MLO)** | ✅ | ✅ **已實作** |
| **Client Steering** | ✅ | ✅ **已實作** |
| **Node Steering** | ✅ | ✅ **已實作** |
| **IPTV Configuration** | ✅ | ✅ **已實作** |

> **確認**: PrivacyGUI 的 `wifi_advanced_settings_view.dart` 實作了 Client Steering、Node Steering、DFS、MLO 和 IPTV 設定。僅 ATF (Airtime Fairness) 未實作。

---

### 10. 故障排除工具

| 功能 | LSWF 實作 | PrivacyGUI 狀態 |
|------|----------|-----------------|
| **系統狀態頁面** | ✅ 完整 | ❌ 未實作 |
| **Ping 測試** | ✅ | ⚠️ API 已定義（有 PingStatus 模型），UI 部分實作 |
| **Traceroute 測試** | ✅ | ⚠️ API 已定義（有 TracerouteStatus 模型），UI 未完整 |
| **設定備份/還原** | ✅ | ❌ 未實作 |
| **恢復上一版韌體** | ✅ | ❌ 未實作 |
| **系統日誌** | ✅ | ❌ 未實作 |
| **排程重啟** | ✅ | ❌ 未實作 |

> **確認**: PrivacyGUI 有 `PingStatus` 和 `TracerouteStatus` JNAP 模型，以及 `startPing`、`stopPing`、`getPingStatus`、`startTraceroute`、`getTracerouteStatus` 等 API，但 UI 僅在 PnP troubleshooter 中部分使用。

---

### 11. HomeKit 整合

| 功能 | LSWF 實作 | PrivacyGUI 狀態 |
|------|----------|-----------------|
| **HomeKit 設定** | ✅ | ❌ 未實作 |

---

### 12. 設備 WPS 新增

| 功能 | LSWF 實作 | PrivacyGUI 狀態 |
|------|----------|-----------------|
| **透過 WPS 新增設備** | ✅ Device List | ❌ 未實作 |

---

### 13. 帳戶建立/密碼重設

| 功能 | LSWF 實作 | PrivacyGUI 狀態 |
|------|----------|-----------------|
| **建立帳戶頁面** | ✅ create-account.html | ❌ 未實作（需通過 Linksys App） |
| **密碼重設頁面** | ✅ password-reset.html | ⚠️ 部分（localPasswordReset） |

---

## 🔵 PrivacyGUI 獨有功能（LSWF 缺少）

### 1. AI 助理

| 功能 | PrivacyGUI 實作 | LSWF 狀態 |
|------|----------------|-----------|
| **AI Assistant** | ✅ (開發中) | ❌ 無 |

---

### 2. 頻道搜尋器 (Channel Finder)

| 功能 | PrivacyGUI 實作 | LSWF 狀態 |
|------|----------------|-----------|
| **最佳頻道搜尋** | ✅ channelFinderOptimize | ❌ 無獨立功能 |

---

### 3. WiFi 分享

| 功能 | PrivacyGUI 實作 | LSWF 狀態 |
|------|----------------|-----------|
| **QR Code 分享** | ✅ wifiShare | ❌ 無 |
| **文字分享** | ✅ | ❌ 無 |

---

### 4. 節點燈光設定

| 功能 | PrivacyGUI 實作 | LSWF 狀態 |
|------|----------------|-----------|
| **LED 燈光控制** | ✅ nodeLightSettings | ⚠️ Activity Lights 僅開關 |

---

### 5. 通知設定

| 功能 | PrivacyGUI 實作 | LSWF 狀態 |
|------|----------------|-----------|
| **推播通知設定** | ✅ settingsNotification | ❌ 無（Web 無原生推播） |

---

### 6. 設備選擇器

| 功能 | PrivacyGUI 實作 | LSWF 狀態 |
|------|----------------|-----------|
| **通用設備選擇元件** | ✅ devicePicker | ❌ 無獨立元件 |

---

### 7. 藍牙節點配對

| 功能 | PrivacyGUI 實作 | LSWF 狀態 |
|------|----------------|-----------|
| **藍牙配對流程** | ✅ core/bluetooth | ⚠️ 透過 JNAP 間接支援 |

---

### 8. 即時設定流程 (PnP)

| 功能 | PrivacyGUI 實作 | LSWF 狀態 |
|------|----------------|-----------|
| **引導式設定** | ✅ 完整 pnp 流程 | ✅ Setup 流程（類似但實作不同） |
| **ISP 類型選擇** | ✅ pnpIspTypeSelection | ✅ 有 |
| **Modem 重啟引導** | ✅ pnpUnplugModem 等 | ✅ powercycle_modem.html |

---

## 功能覆蓋率比較

### LSWF 功能覆蓋率

```
總功能模組: 18
已實作: 18 (100%)
```

### PrivacyGUI 功能覆蓋率 (相對於 LSWF)

```
LSWF 總功能: 18
PrivacyGUI 已覆蓋: 11 (61%)
PrivacyGUI 缺少: 7 (39%)
```

### 缺少的主要功能模組：

1. ⚠️ **Parental Controls** - 家長控制
2. ⚠️ **Media Prioritization / QoS** - 媒體優先順序
3. ⚠️ **External Storage / USB Storage** - 儲存功能
4. ⚠️ **Troubleshooting** - 故障排除工具
5. ⚠️ **WPS** - WiFi Protected Setup
6. ⚠️ **Wireless Scheduler** - WiFi 排程
7. ⚠️ **VLAN Tagging** - VLAN 標籤

---

## JNAP API 使用比對

### PrivacyGUI 已使用的 JNAP API (55 個模型)

| 類別 | API 使用狀況 |
|------|-------------|
| Core | ✅ GetDeviceInfo, SetAdminPassword, Reboot |
| Router | ✅ LANSettings, WANSettings, WANStatus, DHCPClientLeases |
| Wireless | ✅ RadioInfo, RadioSettings |
| Device List | ✅ GetDevices, SetDeviceProperties |
| Firewall | ✅ FirewallSettings, DMZSettings, PortForwarding |
| Health Check | ✅ HealthCheckResults |
| Firmware | ✅ FirmwareUpdateSettings, FirmwareUpdateStatus |

### PrivacyGUI 尚未使用的 JNAP API

| 類別 | 缺少的 API |
|------|-----------|
| **QoS** | GetQoSSettings, SetQoSSettings, LVVP |
| **Parental Control** | GetParentalControlSettings, SetParentalControlSettings |
| **Storage** | FTPServerSettings, SMBServerSettings, MediaServer |
| **WPS** | StartWPSServerSession, GetWPSServerSessionStatus |
| **MAC Filter** | ⚠️ 有模型但可能未完整實作 |
| **VLAN** | GetVLANTaggingSettings, SetVLANTaggingSettings |
| **HomeKit** | GetHomeKitSettings, SetHomeKitSettings |
| **Diagnostics** | StartPing, StartTraceroute, GetPingStatus |
| **Configuration** | GetConfigurationBackup, RestoreConfiguration |
| **ATF/DFS/MLO** | 進階無線設定相關 API |

---

## 建議優先實作功能

### 高優先順序（用戶常用）

| 優先序 | 功能 | 原因 |
|--------|------|------|
| 1 | **家長控制** | 用戶常用功能，競爭對手都有 |
| 2 | **QoS / 媒體優先順序** | 進階用戶需求高 |
| 3 | **故障排除工具** | 減少客服負擔 |

### 中優先順序（特定場景）

| 優先序 | 功能 | 原因 |
|--------|------|------|
| 4 | **USB 儲存** | 有 USB 端口的路由器需要 |
| 5 | **WPS** | 簡化設備連線 |
| 6 | **Wireless Scheduler** | 節能/控制需求 |

### 低優先順序（進階功能）

| 優先序 | 功能 | 原因 |
|--------|------|------|
| 7 | **VLAN Tagging** | 企業/進階用戶 |
| 8 | **進階無線設定 (ATF/DFS/MLO)** | 專業用戶 |
| 9 | **HomeKit** | Apple 生態系整合 |
| 10 | **SimpleTap (NFC)** | 特定硬體支援 |

---

## 總結

| 指標 | LSWF | PrivacyGUI |
|------|------|------------|
| **功能完整度** | 100% | ~61% |
| **平台支援** | Web Only | iOS, Android, Web |
| **使用者體驗** | 傳統 Web UI | 現代化 App |
| **離線支援** | ❌ | ⚠️ 部分 |
| **雲端整合** | ⚠️ 有限 | ✅ 完整 |
| **AI 功能** | ❌ | ✅ 開發中 |

### 主要差距

PrivacyGUI 相較於 LSWF 主要缺少以下功能類別：

1. **控制類**: 家長控制、QoS
2. **硬體類**: USB 儲存、WPS
3. **診斷類**: 故障排除工具
4. **進階類**: VLAN、進階無線設定

這些功能在 LSWF 中都有完整實作，建議 PrivacyGUI 逐步補齊以達到功能對等。
