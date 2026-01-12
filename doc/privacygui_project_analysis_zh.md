# PrivacyGUI 專案分析報告

## 專案概述

PrivacyGUI 是 **Linksys 路由器管理應用程式 (Flutter)**，這是一個跨平台（iOS、Android、Web）的現代化路由器管理應用，用於管理 Linksys 路由器（包括 Velop Mesh 系統）的各項功能。

---

## 技術架構

### 技術棧
| 類別 | 技術 |
|------|------|
| **框架** | Flutter 3.x |
| **狀態管理** | Riverpod |
| **路由** | go_router |
| **API 通訊** | JNAP (JSON Network Access Protocol) |
| **雲端服務** | Linksys Cloud API |
| **依賴注入** | Riverpod + GetIt |
| **本地儲存** | SharedPreferences |
| **UI 元件庫** | 自定義 ui_kit_library |

### 目錄結構
```
lib/
├── ai/                    # AI 助理功能
├── constants/             # 常數定義
├── core/                  # 核心服務層
│   ├── bluetooth/         # 藍牙通訊 (用於節點配對)
│   ├── cache/             # 快取管理
│   ├── cloud/             # 雲端服務 (Linksys Cloud API)
│   ├── http/              # HTTP 客戶端
│   ├── jnap/              # JNAP API 層 (核心)
│   └── usp/               # USP 協議支援
├── page/                  # 頁面模組 (21 個)
├── providers/             # 全域 Providers
├── route/                 # 路由定義
├── theme/                 # 主題設定
├── util/                  # 工具函式
└── validator_rules/       # 驗證規則
```

---

## 主要功能模組詳細分析

### 1. 登入與認證 (Login)

**目錄**: `lib/page/login/`

| 功能 | 說明 |
|------|------|
| **雲端登入** | 使用 Linksys 帳戶登入，支援手機/Email |
| **本地登入** | 使用路由器管理密碼登入 |
| **遠端存取** | 透過雲端遠端管理路由器 |
| **路由器復原** | 忘記密碼時的復原流程 |
| **OTP 驗證** | 雙因素驗證支援 |

#### 登入流程路由：
- `cloudLoginAccount` → `cloudLoginPassword` → `cloudRALogin`
- `localLoginPassword` → `localRouterRecovery` → `localPasswordReset`
- `otpStart` → `otpSelectMethods` → `otpInputCode`

---

### 2. 儀表板 (Dashboard)

**目錄**: `lib/page/dashboard/`

#### 子功能：
| 元件 | 說明 |
|------|------|
| **Home View** | 主頁面，顯示網路狀態、WiFi 資訊、連線設備數 |
| **Menu View** | 功能選單，進入各功能模組的入口 |
| **Support View** | 支援頁面，FAQ、客服電話 |
| **AI Assistant** | AI 助理功能（待開發） |

#### Dashboard 元件：
- **網路狀態卡片** - 顯示網路連線狀態
- **WiFi 資訊面板** - 顯示 WiFi 名稱、密碼
- **Port 狀態** - 顯示 WAN/LAN 連線狀態
- **速度測試快捷** - 快速進入速度測試
- **設備數量** - 顯示連線設備數量

---

### 3. 即時系列功能 (Instant*)

#### 3.1 Instant Verify（網路診斷）
**目錄**: `lib/page/instant_verify/`

| 功能 | 說明 |
|------|------|
| **網路測速** | 測量上傳/下載速度 |
| **連線診斷** | 檢查網路連線狀態 |
| **Port 狀態檢測** | 檢查所有端口連線 |

#### 3.2 Instant Devices（設備管理）
**目錄**: `lib/page/instant_device/`

| 功能 | 說明 |
|------|------|
| **設備清單** | 顯示所有連線設備 |
| **設備詳情** | 查看設備資訊（IP、MAC、連線類型） |
| **設備編輯** | 修改設備名稱、圖示 |
| **連線限制** | 設定設備存取權限 |

#### 3.3 Instant Topology（網路拓撲）
**目錄**: `lib/page/instant_topology/`

| 功能 | 說明 |
|------|------|
| **拓撲視覺化** | 顯示網路節點連線關係 |
| **節點資訊** | 查看各節點狀態 |
| **連線品質** | 顯示節點間連線品質 |

#### 3.4 Instant Admin（管理功能）
**目錄**: `lib/page/instant_admin/`

| 功能 | 說明 |
|------|------|
| **帳戶資訊** | 顯示 Linksys 帳戶資訊 |
| **雙因素驗證** | 設定 2FA |
| **時區設定** | 設定路由器時區 |
| **通知設定** | 設定推播通知 |

#### 3.5 Instant Safety（網路安全）
**目錄**: `lib/page/instant_safety/`

| 功能 | 說明 |
|------|------|
| **安全瀏覽** | Safe Browsing 設定 |
| **家長控制** | 設備存取時間控制 |

#### 3.6 Instant Privacy（隱私設定）
**目錄**: `lib/page/instant_privacy/`

| 功能 | 說明 |
|------|------|
| **訪客存取** | 訪客網路設定 |
| **隱私設定** | 各項隱私相關設定 |

---

### 4. WiFi 設定 (WiFi Settings)

**目錄**: `lib/page/wifi_settings/`

#### 子功能：
| 分頁 | 說明 |
|------|------|
| **Main** | 基本 WiFi 設定（SSID、密碼、安全性） |
| **Share** | WiFi 分享（QR Code、文字分享） |
| **Advanced** | 進階設定（頻道、頻寬、傳輸功率） |
| **MAC Filter** | MAC 位址過濾 |
| **Channel Finder** | 最佳頻道搜尋 |

#### WiFi 設定項目：
- **SSID** - WiFi 名稱
- **Password** - WiFi 密碼
- **Security Mode** - 安全模式（WPA2/WPA3）
- **Band Steering** - 頻段引導
- **Channel** - 頻道選擇
- **Bandwidth** - 頻寬設定（20/40/80/160 MHz）
- **Transmission Power** - 傳輸功率

---

### 5. 節點管理 (Nodes)

**目錄**: `lib/page/nodes/`

#### 子功能：
| 功能 | 說明 |
|------|------|
| **節點詳情** | 查看節點狀態、連線設備 |
| **節點名稱** | 修改節點名稱 |
| **節點燈光** | 設定節點 LED 燈光 |
| **新增節點** | 透過藍牙配對新節點 |
| **韌體更新** | 節點韌體更新 |

---

### 6. 進階設定 (Advanced Settings)

**目錄**: `lib/page/advanced_settings/`

#### 6.1 Internet Settings（網路設定）
**目錄**: `lib/page/advanced_settings/internet_settings/`

| 功能 | 說明 |
|------|------|
| **連線類型** | DHCP、Static IP、PPPoE、PPTP、L2TP、Bridge |
| **IPv4 設定** | IPv4 位址設定 |
| **IPv6 設定** | IPv6 位址設定 |
| **MAC Clone** | MAC 位址複製 |
| **MTU** | MTU 設定 |

#### 6.2 Local Network Settings（區域網路設定）
**目錄**: `lib/page/advanced_settings/local_network_settings/`

| 功能 | 說明 |
|------|------|
| **路由器 IP** | 設定路由器 IP 位址 |
| **DHCP Server** | DHCP 伺服器設定 |
| **DHCP Reservation** | DHCP 保留 IP |
| **Subnet Mask** | 子網路遮罩 |

#### 6.3 Firewall（防火牆）
**目錄**: `lib/page/advanced_settings/firewall/`

| 功能 | 說明 |
|------|------|
| **防火牆開關** | 啟用/停用防火牆 |
| **VPN Passthrough** | VPN 穿透設定（IPSec、L2TP、PPTP） |
| **IPv6 防火牆** | IPv6 防火牆規則 |
| **過濾設定** | 封包過濾設定 |

#### 6.4 DMZ
**目錄**: `lib/page/advanced_settings/dmz/`

| 功能 | 說明 |
|------|------|
| **DMZ 開關** | 啟用/停用 DMZ |
| **DMZ 主機** | 設定 DMZ 主機 IP |
| **來源限制** | 設定允許的來源 |

#### 6.5 Apps and Gaming (Port 轉發)
**目錄**: `lib/page/advanced_settings/apps_and_gaming/`

| 功能 | 說明 |
|------|------|
| **Single Port Forwarding** | 單一端口轉發 |
| **Port Range Forwarding** | 端口範圍轉發 |
| **Port Range Triggering** | 端口範圍觸發 |
| **IPv6 Port Service** | IPv6 端口服務 |
| **DDNS** | 動態 DNS 設定 |
| **UPnP** | UPnP 設定 |

#### 6.6 Static Routing（靜態路由）
**目錄**: `lib/page/advanced_settings/static_routing/`

| 功能 | 說明 |
|------|------|
| **靜態路由列表** | 顯示所有靜態路由 |
| **新增路由** | 新增靜態路由規則 |
| **編輯/刪除** | 修改或刪除路由 |

#### 6.7 Administration（管理設定）
**目錄**: `lib/page/advanced_settings/administration/`

| 功能 | 說明 |
|------|------|
| **管理密碼** | 變更路由器管理密碼 |
| **遠端管理** | 啟用/停用遠端管理 |
| **Express Forwarding** | CTF 設定 |
| **管理 Port** | 設定管理介面端口 |

---

### 7. VPN 設定

**目錄**: `lib/page/vpn/`

| 功能 | 說明 |
|------|------|
| **OpenVPN Server** | OpenVPN 伺服器設定 |
| **VPN 設定檔** | 下載 VPN 連線設定檔 |
| **連線資訊** | 顯示 VPN 連線資訊 |

---

### 8. 速度測試 (Health Check)

**目錄**: `lib/page/health_check/`

| 功能 | 說明 |
|------|------|
| **伺服器選擇** | 選擇測速伺服器 |
| **速度測試** | 執行上傳/下載速度測試 |
| **結果顯示** | 顯示測試結果 |
| **歷史記錄** | 查看測試歷史 |

---

### 9. 韌體更新 (Firmware Update)

**目錄**: `lib/page/firmware_update/`

| 功能 | 說明 |
|------|------|
| **更新檢查** | 檢查韌體更新 |
| **自動更新** | 設定自動更新 |
| **手動更新** | 手動上傳韌體 |
| **更新進度** | 顯示更新進度 |

---

### 10. PnP 設定 (Plug and Play Setup)

**目錄**: `lib/page/instant_setup/`

#### 設定流程：
1. **pnp** - 起始頁面
2. **pnpConfig** - 基本設定
3. **pnpNoInternetConnection** - 無網路連線處理
4. **pnpUnplugModem** - 拔除 Modem
5. **pnpModemLightsOff** - 等待 Modem 燈光
6. **pnpWaitingModem** - 等待 Modem 連線
7. **pnpIspTypeSelection** - ISP 類型選擇
8. **pnpPPPOE** - PPPoE 設定
9. **pnpStaticIp** - 靜態 IP 設定
10. **pnpIspAuth** - ISP 認證
11. **pnpAddNodes** - 新增節點

---

### 11. 支援 (Support)

**目錄**: `lib/page/support/`

| 功能 | 說明 |
|------|------|
| **FAQ 列表** | 常見問題列表 |
| **電話支援** | 各地區客服電話 |
| **回電預約** | 預約客服回電 |

---

## 核心服務層 (Core)

### JNAP API 層
**目錄**: `lib/core/jnap/`

#### 資料模型（55 個）：
| 類別 | 模型 |
|------|------|
| **設備** | device.dart, device_info.dart |
| **網路** | wan_settings.dart, wan_status.dart, lan_settings.dart |
| **無線** | radio_info.dart, guest_radio_settings.dart |
| **防火牆** | firewall_settings.dart, dmz_settings.dart |
| **Port 轉發** | single_port_forwarding_rule.dart, port_range_forwarding_rule.dart |
| **DHCP** | dhcp_lease.dart, set_lan_settings.dart |
| **韌體** | firmware_update_settings.dart, firmware_update_status.dart |
| **路由** | get_routing_settings.dart, advanced_routing_rule.dart |
| **其他** | health_check_result.dart, ddns_settings_model.dart, timezone.dart |

#### 主要服務：
- `router_repository.dart` - 路由器資料存取層
- `jnap_command_queue.dart` - JNAP 命令佇列
- `jnap_command_executor_mixin.dart` - JNAP 命令執行器

### Cloud API 層
**目錄**: `lib/core/cloud/`

| 服務 | 說明 |
|------|------|
| **linksys_cloud_repository.dart** | 雲端 API 存取層 |
| **linksys_device_cloud_service.dart** | 設備雲端服務 |

---

## 全域 Providers

**目錄**: `lib/providers/`

| Provider | 說明 |
|----------|------|
| **auth/** | 認證狀態管理 |
| **connectivity/** | 連線狀態管理 |
| **app_settings/** | 應用設定 |
| **redirection/** | 路由重導向 |

---

## 路由定義

**目錄**: `lib/route/`

### 主要路由區塊：

| 區塊 | 路由 |
|------|------|
| **登入** | cloudLoginAccount, localLoginPassword, otpStart |
| **儀表板** | dashboardHome, dashboardMenu, dashboardSupport, dashboardAiAssistant |
| **選單功能** | menuInstantVerify, menuInstantDevices, menuIncredibleWiFi, menuInstantTopology, menuInstantAdmin, menuInstantSafety, menuInstantPrivacy, menuAdvancedSettings |
| **設定** | settingsLocalNetwork, settingsAppsGaming, settingsFirewall, settingsDMZ, settingsAdministration, settingsStaticRouting, settingsVPN |
| **WiFi** | wifiSettingsReview, wifiShare, wifiShareDetails, wifiAdvancedSettings |
| **節點** | nodeDetails, nodeLight, addNodes, firmwareUpdateDetail |
| **PnP** | pnp, pnpConfig, pnpNoInternetConnection... |

---

## 測試架構

**目錄**: `test/`

- **單元測試** - 核心邏輯測試
- **Widget 測試** - UI 元件測試
- **Golden 測試** - 視覺回歸測試
- **整合測試** - 端對端測試

---

## 相依套件

### 自定義套件
**目錄**: `packages/`

| 套件 | 說明 |
|------|------|
| **ui_kit_library** | 自定義 UI 元件庫 |
| **generative_ui** | 生成式 UI 元件 |
| **jnap_api** | JNAP API 客戶端 |

---

## 總結

PrivacyGUI 是一個功能完整、架構清晰的 Flutter 跨平台路由器管理應用：

- **21 個頁面模組** 涵蓋路由器管理所有功能
- **55 個 JNAP 資料模型** 支援完整的 API 通訊
- **支援本地與雲端模式** 提供靈活的存取方式
- **模組化架構** 使用 Riverpod 進行狀態管理
- **完整的設定流程 (PnP)** 引導使用者完成路由器設定
- **AI 助理功能** 提供智慧化支援（開發中）

### 與 Master 專案的對應關係

| PrivacyGUI 功能 | Master 專案對應 |
|----------------|----------------|
| Instant Devices | Device List Applet |
| Incredible WiFi | Wireless Applet |
| Instant Topology | Device Map Applet |
| Speed Test | Speed Test Applet |
| Advanced Settings | Connectivity Applet |
| Firewall/DMZ/Ports | Security Applet |
| VPN | OpenVPN Applet |
