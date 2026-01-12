# Master 專案分析報告

## 專案概述

Master 專案是 **Linksys Smart WiFi Router Web UI**，這是一個基於 Web 的路由器管理介面，用於管理 Linksys 路由器（包括 Velop Mesh 系統）的各項功能。

---

## 目錄結構

```
master/
├── backend/           # Backend 靜態資源
│   ├── images/
│   └── ustatic/      # USB 驅動程式等使用者靜態檔案
│
└── rainier/          # 主要 Web 應用程式
    ├── dynamic/      # 動態頁面（HTML 模板）
    ├── static/       # 靜態資源（JS、CSS、圖片）
    ├── ustatic/      # 使用者靜態資源
    ├── hdk2/         # HDK2 相關檔案
    ├── root/         # 根目錄相關
    └── tools/        # 建構工具
```

---

## 主要功能模組 (Applets) 詳細分析

專案包含 **18 個主要功能模組**，以下為每個模組的詳細子功能說明：

---

### 1. Connectivity（網路連線設定）
**檔案**: [connectivity.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/applets/connectivity/js/connectivity.js) (4,598 行)

#### 子功能分頁：
| 分頁 | 功能說明 |
|------|---------|
| **Internet Settings** | IPv4/IPv6 連線類型設定 |
| **Local Network** | 區域網路設定（IP、DHCP） |
| **VLAN Tagging** | VLAN 標籤設定 |
| **Advanced Routing** | 進階路由表設定 |
| **Administration** | 管理設定 |
| **Power Modem** | DSL Modem 設定 |

#### Internet Settings 支援的連線類型：
- `DHCP` - 自動取得 IP
- `Static` - 靜態 IP
- `PPPoE` - PPPoE 撥號
- `PPTP` - PPTP VPN
- `L2TP` - L2TP VPN
- `Bridge` - 橋接模式
- `WirelessRepeater` - 無線中繼器
- `WirelessBridge` - 無線橋接

#### 其他功能：
- 韌體更新（自動/手動）
- 時區設定
- 路由器密碼管理
- MAC Address Clone
- MTU 設定
- Activity Lights 開關

---

### 2. Device List（設備清單）
**檔案**: [device-list.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/applets/device_list/js/device-list.js)

#### 子功能：
- **My Network** - 已連線設備清單
- **Guest Network** - 訪客網路設備
- **設備資訊編輯** - 名稱、圖示自訂
- **WPS 設備新增** - Push Button / PIN 方式
- **新增電腦/其他裝置** - 顯示 WiFi 連線資訊
- **USB 印表機設定** - VUSB 軟體下載
- **清除設備清單** - 重置所有設備資訊

#### 支援的設備圖示（55+ 種）：
Desktop、Laptop、Smartphone、Tablet、Game Console、Smart TV、Smart Speaker、Camera、Drone、Robot、Smart Watch、VR Headset、3D Printer 等

---

### 3. Device Map（設備拓撲圖）
**檔案**: [smartmap.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/applets/device_map/js/smartmap.js)

#### 子功能：
- 網路拓撲視覺化
- 節點連線狀態顯示
- 互動式設備資訊查看
- MVC 架構（Models/Views）

---

### 4. Wireless（WiFi 設定）
**檔案**: [wireless.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/applets/wireless/js/wireless.js)

#### 子功能分頁：
| 分頁 | 功能說明 |
|------|---------|
| **Wireless** | 基本 WiFi 設定 |
| **WiFi Protected Setup** | WPS 設定 |
| **MAC Filtering** | MAC 位址過濾 |
| **SimpleTap** | NFC 連線功能 |
| **Wireless Scheduler** | WiFi 排程 |
| **Advanced** | 進階無線設定 |

#### Wireless 基本設定：
- SSID（WiFi 名稱）
- WiFi 密碼
- 安全模式（WPA2/WPA3）
- Band Steering（頻段導引）
- 頻道選擇
- 頻寬設定

#### WPS 功能：
- Push Button 連線
- Router PIN
- Device PIN 註冊

#### 進階設定：
- **Airtime Fairness (ATF)** - 公平頻寬分配
- **Dynamic Frequency Selection (DFS)** - 動態頻率選擇
- **Multi-Link Operation (MLO)** - 多連結操作
- **Client Steering** - 客戶端導引
- **Node Steering** - 節點導引
- **IPTV Configuration** - IPTV 設定

---

### 5. Guest Access（訪客網路）
**檔案**: [guest-access.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/applets/guest_access/js/guest-access.js) (337 行)

#### 子功能：
- 訪客網路開關
- 訪客 SSID 設定
- 訪客密碼設定
- 最大同時連線數
- 2.4GHz / 5GHz 頻段選擇

---

### 6. Parental Controls（家長控制）
**檔案**: [parental-controls.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/applets/parental_controls/js/parental-controls.js) (706 行)

#### 子功能：
- **設備選擇** - 選擇要控制的設備
- **網路存取時間排程** - 設定上網時段
  - Never（永遠封鎖）
  - Always（永遠允許）
  - Custom（自訂時段）
- **網站封鎖** - 封鎖特定網站
- **每週排程表** - 視覺化時間選擇器

---

### 7. Media Prioritization（媒體優先順序）
**檔案**: [media-prioritization.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/applets/media_prioritization/js/media-prioritization.js) (2,161 行)

#### 子功能：
- **QoS 開關** - 啟用/停用服務品質
- **高優先順序群組** - 設定優先設備
- **設備優先順序** - 拖放排序設備
- **應用程式優先順序** - 設定應用程式規則
- **遊戲優先順序** - 線上遊戲優化

#### QoS 參數：
- 頻寬設定（自動/手動）
- 優先等級：Background、Generic、Voice、Video
- WMM 設定
- LVVP（區域語音視訊優先）

---

### 8. Speed Test（網路速度測試）
**檔案**: [speed-test.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/applets/speed_test/js/speed-test.js) (409 行)

#### 子功能：
- 伺服器選擇
- 下載速度測試
- 上傳速度測試
- 測試進度動畫
- 測試結果顯示

---

### 9. Security（安全性設定）
**檔案**: [security.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/applets/security/js/security.js) (1,755 行)

#### 子功能分頁：
| 分頁 | 功能說明 |
|------|---------|
| **Firewall** | 防火牆設定 |
| **IPv6 Firewall Rules** | IPv6 防火牆規則 |
| **DMZ** | DMZ 主機設定 |
| **Single Port Forwarding** | 單一埠轉發 |
| **Port Range Forwarding** | 埠範圍轉發 |
| **Port Range Triggering** | 埠觸發 |
| **DDNS** | 動態 DNS 設定 |

#### Firewall 設定：
- 防火牆開關
- VPN Passthrough
- 過濾規則

#### Port Forwarding 設定：
- 應用程式名稱
- 外部埠
- 內部埠
- 協定（TCP/UDP/Both）
- 目標 IP

---

### 10. Troubleshooting（故障排除）
**檔案**: [troubleshooting.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/applets/troubleshooting/js/troubleshooting.js) (2,171 行)

#### 子功能分頁：
| 分頁 | 功能說明 |
|------|---------|
| **Status** | 系統狀態顯示 |
| **Diagnostics** | 診斷工具 |
| **Logs** | 系統日誌 |

#### Status 顯示資訊：
- 路由器資訊（型號、韌體版本、序號）
- WAN 狀態（IP、連線類型、MAC）
- WiFi 狀態（所有頻段資訊）
- DHCP Client 表
- IPv6 資訊

#### 診斷工具：
- Ping 測試
- Traceroute 測試
- 設定備份/還原
- 還原上一版韌體
- 重新啟動路由器
- 恢復原廠設定
- 排程重啟設定

---

### 11. External Storage（外部儲存）
**檔案**: [external_storage.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/applets/external_storage/js/external_storage.js) (435 行)

#### 子功能：
- 儲存裝置清單顯示
- 磁碟分割區資訊
- 安全存取設定
- SMB 伺服器設定
- 安全移除裝置
- 重新整理儲存清單

---

### 12. USB Storage（USB 儲存）
**檔案**: [usb_storage.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/applets/usb_storage/js/usb_storage.js)

#### 子功能：
- USB 裝置清單
- FTP 伺服器設定
- 媒體伺服器設定
- 存取權限管理

---

### 13. OpenVPN（VPN 設定）
**檔案**: [openvpn.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/applets/openvpn/js/openvpn.js)

#### 子功能：
- OpenVPN 伺服器開關
- VPN 設定檔下載
- 連線資訊顯示

---

### 14. Diagnostics（系統診斷）
**檔案**: [diagnostics.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/applets/diagnostics/js/diagnostics.js)

#### 子功能：
- 系統診斷執行
- 診斷報告產生

---

### 15. My Account（帳戶管理）
**檔案**: [my_account.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/applets/my_account/js/my_account.js)

#### 子功能：
- 帳戶資訊顯示
- 帳戶設定管理

---

### 16. Network Health（網路健康）
**檔案**: [widget.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/applets/network_health/js/widget.js)

#### 子功能：
- 網路健康狀態 Widget
- 連線品質顯示

---

### 17. LSWF Info（Smart WiFi 資訊）
**檔案**: [widget.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/applets/LSWF_info/js/widget.js)

#### 子功能：
- Linksys Smart WiFi 版本資訊
- 路由器資訊 Widget 

---

## 頁面分類

### 1. 認證與帳戶管理頁面

| 頁面 | 說明 |
|-----|------|
| `login.html` / `login-simple.html` | 登入頁面 |
| `create-account.html` / `create-account-simple.html` | 建立帳戶 |
| `password-reset.html` / `password-reset-simple.html` | 密碼重設 |
| `change-password.html` / `change-password-simple.html` | 變更密碼 |
| `change-admin-password.html` | 變更管理員密碼 |
| `account-verification.html` / `account-verification-simple.html` | 帳戶驗證 |
| `account-lockout.html` / `account-lockout-simple.html` | 帳戶鎖定 |
| `account-security-lock.html` | 安全鎖定 |
| `mfa-challenge.html` | 多因素認證 |
| `recovery-pin.html` | 恢復 PIN |
| `agent-login.html` | 代理登入 |
| `guest-login.html` | 訪客登入 |

### 2. 主要導覽頁面

| 頁面 | 說明 |
|-----|------|
| `index.html` | 入口頁面 |
| `home.html` | 首頁儀表板（Widget 容器） |
| `welcome.html` | 歡迎頁面 |
| `help.html` | 說明頁面 |
| `components.html` | UI 元件庫 |

### 3. 錯誤與狀態頁面

| 頁面 | 說明 |
|-----|------|
| `404.html` | 404 錯誤頁面 |
| `502.html` | 502 錯誤頁面 |
| `internet-down.html` | 網路中斷 |
| `internet-blocked.html` | 網路封鎖 |
| `site-blocked.html` | 網站封鎖 |
| `browser-unsupported.html` | 瀏覽器不支援 |
| `cookies-disabled.html` | Cookie 已停用 |
| `script-disabled.html` | JavaScript 已停用 |
| `unsecured.html` | 不安全連線 |

### 4. Setup 流程頁面 (`dynamic/setup/`)

| 頁面 | 說明 |
|-----|------|
| `welcome.html` | 設定歡迎 |
| `account_intro.html` | 帳戶介紹 |
| `check_internet.html` | 檢查網路連線 |
| `check_router_settings.html` | 檢查路由器設定 |
| `change_radio_settings.html` | 變更無線設定 |
| `change_router_password.html` | 變更路由器密碼 |
| `powercycle_modem.html` | 重啟 Modem |
| `update.html` | 韌體更新 |
| `congratulations.html` | 設定完成 |
| `pm_dsl_*.html` | DSL 相關設定頁面 |

### 5. 進階無線設定

檔案: `advanced-wireless.html`

提供完整的無線進階設定功能。

### 6. Velop 專用頁面 (`dynamic/velop/`)

| 頁面 | 說明 |
|-----|------|
| `blocking.html` | 封鎖頁面 |
| `cf/` | Content Filtering 相關頁面 |

---

## 核心 JavaScript 架構

### 主要 JS 檔案

| 檔案 | 大小 | 功能 |
|-----|------|------|
| [globals.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/js/globals.js) | 70KB | 全域設定、網路初始化、應用程式建構 |
| [ui.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/js/ui.js) | 156KB | UI 元件、對話框、表單處理 |
| [jnap.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/js/jnap.js) | 23KB | JNAP API 通訊層 |
| [devices.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/js/devices.js) | 46KB | 設備管理邏輯 |
| [connect.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/js/connect.js) | 27KB | 連線管理 |
| [account.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/js/account.js) | 43KB | 帳戶管理 |
| [login.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/js/login.js) | 22KB | 登入邏輯 |
| [widget-manager.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/js/widget-manager.js) | 24KB | Widget 管理器 |
| [applet-manager.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/js/applet-manager.js) | 9KB | Applet 管理器 |
| [wireless-util.js](file:///Users/austin.chang/Downloads/loc/cloud_services/docroot/master/rainier/static/js/wireless-util.js) | 26KB | 無線網路工具函式 |

### 工具函式

| 檔案 | 功能 |
|-----|------|
| `util.js` | 通用工具函式 |
| `validation.js` | 表單驗證 |
| `data-bind.js` | 資料綁定 |
| `session.js` | Session 管理 |
| `language.js` | 多國語系 |
| `browser.js` | 瀏覽器偵測 |

### 第三方函式庫 (`static/js/lib/`)

專案使用多個 JavaScript 函式庫支援前端功能。

---

## 支援的路由器型號

從 `globals.js` 識別出支援的型號包括：

- **EA 系列**: EA7200, EA7300, EA7400, EA7500, EA8100, EA8250, EA8300, EA8500, EA9200, EA9350, EA9500
- **WRT 系列**: WRT1200AC, WRT1900AC, WRT1900ACS, WRT3200ACM
- **Velop 系列**: 透過 Mesh 相關功能支援

---

## 主要 UI 功能特點

### Device List 功能
- 設備清單顯示（線上/離線狀態）
- 設備圖示自訂（55+ 種設備圖示）
- 設備名稱編輯
- WPS 設備新增
- USB 印表機設定
- 設備清單清除

### Wireless 設定功能
- 多頻段設定（2.4GHz / 5GHz / 6GHz）
- Band Steering 選項
- WPS 設定（Push Button / Router PIN / Device PIN）
- MAC Filtering
- Wireless Scheduler
- 進階設定：
  - Airtime Fairness (ATF)
  - Dynamic Frequency Selection (DFS)
  - Multi-Link Operation (MLO)
  - Client Steering
  - Node Steering
  - IPTV Configuration

---

## 國際化支援

- `dynamic/localized/` - 動態頁面多語系
- `dynamic/setup/localized/` - Setup 流程多語系
- `dynamic/velop/localized/` - Velop 專用多語系
- 每個 applet 都有獨立的 `localized/` 目錄

頁面使用 `{{key}}` 格式標記可翻譯字串。

---

## 技術特點

1. **JNAP API**: 使用 Linksys JNAP 協定與路由器通訊
2. **Widget 架構**: 首頁使用可配置的 Widget 系統
3. **Applet 架構**: 功能模組化設計，每個功能都是獨立的 applet
4. **響應式設計**: 支援不同螢幕尺寸
5. **本地/遠端模式**: 支援本地存取和雲端遠端存取

---

## 建構系統

- 使用 `Makefile` 和 `Makefile.build` 進行建構
- `tools/` 目錄包含建構工具
- 靜態資源會被快取至 `/ui/static/cache/` 路徑

---

## JNAP API 完整清單

JNAP (JSON Network Access Protocol) 是 Linksys 路由器的核心通訊協定。以下列出各功能模組使用的主要 JNAP API：

### 核心層 (Core)

| API 端點 | 說明 |
|---------|------|
| `/jnap/core/GetDeviceInfo` | 取得設備資訊 |
| `/jnap/core/SetAdminPassword` | 設定管理員密碼 |
| `/jnap/core/SetAdminPassword2` | 設定管理員密碼（含 hint） |
| `/jnap/core/Reboot` | 重新啟動路由器 |
| `/jnap/core/FactoryReset` | 恢復原廠設定 |
| `/jnap/core/SetUnsecuredWiFiWarning` | 設定不安全 WiFi 警告 |
| `/jnap/core/Transaction` | 批次交易呼叫 |
| `/jnap/core/CheckAdminPassword` | 驗證管理員密碼 |
| `/jnap/core/IsAdminPasswordDefault` | 檢查密碼是否為預設值 |

---

### 路由器設定 (Router)

| API 端點 | 說明 |
|---------|------|
| `/jnap/router/GetLANSettings` | 取得區域網路設定 |
| `/jnap/router/SetLANSettings` | 設定區域網路 |
| `/jnap/router/GetWANSettings` | 取得 WAN 設定 |
| `/jnap/router/SetWANSettings` | 設定 WAN |
| `/jnap/router/GetWANStatus` | 取得 WAN 狀態 |
| `/jnap/router/GetDHCPClientLeases` | 取得 DHCP 用戶端租約 |
| `/jnap/router/SetDHCPReservation` | 設定 DHCP 保留 |
| `/jnap/router/GetRoutingSettings` | 取得路由設定 |
| `/jnap/router/SetRoutingSettings` | 設定路由 |
| `/jnap/router/GetExpressForwarding` | 取得 CTF 設定 |
| `/jnap/router/SetExpressForwarding` | 設定 CTF |

---

### 無線網路 (Wireless AP)

| API 端點 | 說明 |
|---------|------|
| `/jnap/wirelessap/GetRadioInfo` | 取得無線電資訊 |
| `/jnap/wirelessap/SetRadioSettings` | 設定無線電 |
| `/jnap/wirelessap/GetAdvancedRadioInfo` | 取得進階無線資訊 |
| `/jnap/wirelessap/SetAdvancedRadioSettings` | 設定進階無線 |
| `/jnap/wirelessap/StartWPSServerSession` | 啟動 WPS 伺服器 |
| `/jnap/wirelessap/StopWPSServerSession` | 停止 WPS 伺服器 |
| `/jnap/wirelessap/GetWPSServerSessionStatus` | 取得 WPS 狀態 |
| `/jnap/wirelessap/IsWPSServerAvailable` | 檢查 WPS 是否可用 |
| `/jnap/wirelessap/GetAirtimeFairnessSettings` | 取得 ATF 設定 |
| `/jnap/wirelessap/SetAirtimeFairnessSettings` | 設定 ATF |

#### 晶片商專用 API

| 晶片商 | API 路徑前綴 |
|-------|------------|
| **Broadcom** | `/jnap/wirelessap/broadcom/GetAdvancedSettings`, `SetAdvancedSettings`, `GetTxBFSettings` |
| **Marvell** | `/jnap/wirelessap/marvell/GetAdvancedSettings`, `SetTxBFSettings` |
| **Qualcomm** | `/jnap/wirelessap/qualcomm/GetAdvancedRadioSettings` |
| **MediaTek** | `/jnap/wirelessap/mediatek/GetAdvancedSettings`, `SetAdvancedSettings2` |

---

### 設備清單 (Device List)

| API 端點 | 說明 |
|---------|------|
| `/jnap/devicelist/GetDevices` | 取得設備清單 |
| `/jnap/devicelist/GetDevices3` | 取得設備清單 v3 |
| `/jnap/devicelist/SetDeviceProperties` | 設定設備屬性 |
| `/jnap/devicelist/DeleteDevice` | 刪除設備 |
| `/jnap/devicelist/ClearDeviceList` | 清除設備清單 |

---

### 訪客網路 (Guest Network)

| API 端點 | 說明 |
|---------|------|
| `/jnap/guestnetwork/GetGuestNetworkSettings` | 取得訪客網路設定 |
| `/jnap/guestnetwork/GetGuestNetworkSettings2` | 取得訪客網路設定 v2 |
| `/jnap/guestnetwork/SetGuestNetworkSettings` | 設定訪客網路 |
| `/jnap/guestnetwork/GetGuestRadioSettings` | 取得訪客無線設定 |
| `/jnap/guestnetwork/SetGuestRadioSettings` | 設定訪客無線 |
| `/jnap/guestnetwork/GetGuestNetworkClients` | 取得訪客網路用戶端 |
| `/jnap/guestnetwork/Authenticate` | 訪客認證 |

---

### 防火牆與安全性 (Firewall)

| API 端點 | 說明 |
|---------|------|
| `/jnap/firewall/GetFirewallSettings` | 取得防火牆設定 |
| `/jnap/firewall/SetFirewallSettings` | 設定防火牆 |
| `/jnap/firewall/GetDMZSettings` | 取得 DMZ 設定 |
| `/jnap/firewall/SetDMZSettings` | 設定 DMZ |
| `/jnap/firewall/GetSinglePortForwardingRules` | 取得單一埠轉發規則 |
| `/jnap/firewall/SetSinglePortForwardingRules` | 設定單一埠轉發 |
| `/jnap/firewall/GetPortRangeForwardingRules` | 取得埠範圍轉發 |
| `/jnap/firewall/SetPortRangeForwardingRules` | 設定埠範圍轉發 |
| `/jnap/firewall/GetPortRangeTriggeringRules` | 取得埠觸發規則 |
| `/jnap/firewall/SetPortRangeTriggeringRules` | 設定埠觸發 |
| `/jnap/firewall/GetIPv6FirewallRules` | 取得 IPv6 防火牆規則 |

---

### MAC 過濾 (MAC Filter)

| API 端點 | 說明 |
|---------|------|
| `/jnap/macfilter/GetMACFilterSettings` | 取得 MAC 過濾設定 |
| `/jnap/macfilter/SetMACFilterSettings` | 設定 MAC 過濾 |

---

### 家長控制 (Parental Control)

| API 端點 | 說明 |
|---------|------|
| `/jnap/parentalcontrol/GetParentalControlSettings` | 取得家長控制設定 |
| `/jnap/parentalcontrol/SetParentalControlSettings` | 設定家長控制 |

---

### QoS / 媒體優先順序

| API 端點 | 說明 |
|---------|------|
| `/jnap/qos/GetQoSSettings` | 取得 QoS 設定 |
| `/jnap/qos/SetQoSSettings` | 設定 QoS |
| `/jnap/qos/GetWLANQoSSettings` | 取得 WLAN QoS 設定 |
| `/jnap/qos/SetWLANQoSSettings` | 設定 WLAN QoS |
| `/jnap/qos/calibration/BeginDownloadCalibration` | 開始下載校準 |
| `/jnap/qos/calibration/EndDownloadCalibration` | 結束下載校準 |
| `/jnap/lvvp/GetLVVPSettings` | 取得語音視訊優先設定 |
| `/jnap/lvvp/SetLVVPSettings` | 設定語音視訊優先 |

---

### 速度測試 (Health Check)

| API 端點 | 說明 |
|---------|------|
| `/jnap/healthcheck/GetCloseHealthCheckServers` | 取得鄰近測速伺服器 |
| `/jnap/healthcheck/RunHealthCheck` | 執行健康檢查 |
| `/jnap/healthcheck/GetHealthCheckResults` | 取得健康檢查結果 |

---

### 儲存裝置 (Storage)

| API 端點 | 說明 |
|---------|------|
| `/jnap/storage/GetFTPServerSettings` | 取得 FTP 伺服器設定 |
| `/jnap/storage/SetFTPServerSettings` | 設定 FTP 伺服器 |
| `/jnap/storage/GetSMBServerSettings` | 取得 SMB 伺服器設定 |
| `/jnap/storage/SetSMBServerSettings` | 設定 SMB 伺服器 |
| `/jnap/nodes/storage/GetNodesPartitions` | 取得節點分割區 |
| `/jnap/nodes/storage/GetStorageCapabilities` | 取得儲存能力 |
| `/jnap/nodes/storage/RemoveStorageDevice` | 移除儲存裝置 |

---

### 韌體更新 (Firmware Update)

| API 端點 | 說明 |
|---------|------|
| `/jnap/firmwareupdate/GetFirmwareUpdateSettings` | 取得韌體更新設定 |
| `/jnap/firmwareupdate/SetFirmwareUpdateSettings` | 設定韌體更新 |
| `/jnap/firmwareupdate/UpdateFirmwareNow` | 立即更新韌體 |
| `/jnap/firmwareupdate/GetFirmwareUpdateStatus` | 取得韌體更新狀態 |

---

### OpenVPN

| API 端點 | 說明 |
|---------|------|
| `/jnap/openvpn/GetOpenVPNSettings` | 取得 OpenVPN 設定 |
| `/jnap/openvpn/SetOpenVPNSettings` | 設定 OpenVPN |
| `/jnap/openvpn/DownloadClientConnectionProfile` | 下載用戶端設定檔 |

---

### DDNS

| API 端點 | 說明 |
|---------|------|
| `/jnap/ddns/GetDDNSSettings` | 取得 DDNS 設定 |
| `/jnap/ddns/SetDDNSSettings` | 設定 DDNS |
| `/jnap/ddns/GetDDNSStatus` | 取得 DDNS 狀態 |

---

### HomeKit 整合

| API 端點 | 說明 |
|---------|------|
| `/jnap/homekit/GetHomeKitSettings` | 取得 HomeKit 設定 |
| `/jnap/homekit/SetHomeKitSettings` | 設定 HomeKit |

---

### 節點管理 (Nodes)

| API 端點 | 說明 |
|---------|------|
| `/jnap/nodes/setup/SetAdminPassword` | 設定節點管理員密碼 |
| `/jnap/nodes/networkconnections/GetNetworkConnections` | 取得網路連線 |
| `/jnap/nodes/topologyoptimization/GetTopologyOptimizationSettings` | 取得拓撲優化設定 |
| `/jnap/nodes/topologyoptimization/SetTopologyOptimizationSettings` | 設定拓撲優化 |

---

### 其他 API

| 類別 | API 範例 |
|-----|---------|
| **VLAN** | `/jnap/vln/GetVLANTaggingSettings`, `SetVLANTaggingSettings` |
| **時間設定** | `/jnap/locale/GetTimeSettings`, `SetTimeSettings` |
| **診斷** | `/jnap/diagnostics/StartPing`, `StartTraceroute`, `GetPingStatus` |
| **配置備份** | `/jnap/core/GetConfigurationBackup`, `RestoreConfiguration` |
| **Mesh** | `/jnap/nodes/bluetooth/StartBluetoothClientSession` |
| **DFS** | `/jnap/wirelessap/GetDFSSettings`, `SetDFSSettings` |
| **MLO** | `/jnap/wirelessap/GetMLOSettings`, `SetMLOSettings` |

---

## 總結

Master 專案是一個成熟的路由器管理 Web 應用程式，具有：

- **18 個功能模組** 覆蓋路由器所有管理功能
- **40+ HTML 頁面** 提供完整的使用者介面
- **完整的認證流程** 包含登入、MFA、帳戶管理
- **Setup Wizard** 引導使用者完成初始設定
- **多國語系支援** 支援全球化部署
- **模組化架構** 易於維護和擴展
