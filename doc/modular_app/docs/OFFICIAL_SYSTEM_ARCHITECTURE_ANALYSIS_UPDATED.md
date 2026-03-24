# Linksys Now - 實際系統範圍和架構分析

## 🎯 **系統真正目標** (基於官方文檔)

### **主要問題陳述**
> "The current UI, LinksysNow, is flutter based. It is also a monolith which needs to be upgraded each time a new application needs to be added."

### **核心解決方案**
> "The proposition below is to leverage this capability from openwrt to install packages live to apply this to the UI as well."

## 🏗️ **實際系統架構**

### **1. 模組化轉型目標**
```
舊架構: 單一體 Flutter 應用 (每次新增應用需要重新編譯)
     ↓
新架構: 微前端 + OpenWrt 包管理 (動態添加應用)
```

### **2. 系統分層架構** (戰略方向：USP/TR)
```
┌─────────────────────────────────────────┐
│          Privacy UI (Core Flutter)      │  <- 核心不變的UI
├─────────────────────────────────────────┤
│     Dictionary Microservice            │  <- 服務發現
├─────────────────────────────────────────┤
│  Micro Frontend 1 | Micro Frontend 2   │  <- 動態載入的UI模組
├─────────────────────────────────────────┤
│         USP/TR Model APIs               │  <- 目標架構 (標準化)
├─────────────────────────────────────────┤
│       OpenWrt Package Management        │  <- opkg 包管理
└─────────────────────────────────────────┘
```

**戰略決策**: 捨棄 JNAP，全面轉向 USP/TR Model APIs
**技術現況**: 路由器目前同時支援兩種協議，但新開發將專注於 USP/TR

## 📦 **包擴展的三種情境**

### **1. Basic 擴展**
- **範圍**: 純後端服務 + UCI 配置
- **特點**: 不涉及 USP/TR APIs 或 Privacy UI
- **部署**: 標準 OpenWrt 包構建流程

### **2. Standard 擴展** ⭐ **主要目標**
- **範圍**: 複雜服務 + 專用API + UI模組
- **技術**:
  - 新增 USP/TR Model APIs (Lua代碼)
  - 創建微前端 UI 模組
  - 更新服務發現字典
- **部署**: 類似 luci-app 包的構建流程

### **3. All-inclusive 擴展**
- **範圍**: 完全獨立的跨平台應用
- **特點**: 自帶服務和UI，完全獨立運行
- **集成**: 透過微前端架構無縫集成

## 🔍 **核心技術需求**

### **微前端架構要求**
1. **核心 Privacy UI**: Dart/Flutter (編譯型)
2. **Dictionary 微服務**: 列出所有可用擴展和選項
3. **獨立UI模組**: 每個新功能都有獨立的UI倉庫
4. **服務發現**: 安裝新UI時自動更新字典
5. **開發框架**: 統一的look and feel框架

### **動態前端發現機制**
```json
// Dictionary 服務範例
{
  "availableServices": [
    {
      "name": "AdGuard Home",
      "endpoint": "/adguard/",
      "type": "microfrontend",
      "category": "privacy"
    },
    {
      "name": "OpenVPN",
      "endpoint": "/openvpn/",
      "type": "microfrontend",
      "category": "network"
    }
  ]
}
```

### **跨前端瀏覽**
- 各前端獨立但可互相跳轉
- 不需要總是回到根 Privacy UI
- 透過字典服務獲取其他服務的端點信息

## 📱 **用戶體驗設計**

### **應用分類**
1. **核心功能** (不可刪除):
   - Network
   - Wireless
   - Speedtest

2. **預設應用** (可移除/替換):
   - OpenDNS
   - AdGuard Home
   - OpenVPN

### **UI 導航概念**
- 現有頁面保持不變
- 新增"9點"導航圖示
- 點擊後顯示應用市場/啟動器界面
- 卡片式應用展示

## 🛠️ **app_util.lua 的實際角色**

### **在整體架構中的定位**
```
OpenWrt Package Install → app_util.lua → Update Dictionary → UI Refresh
```

### **核心功能責任**
1. **配置管理**: 管理 `poc_nav1.json` 應用配置
2. **服務註冊**: 新應用安裝時更新字典服務
3. **URL 路由**: 創建 lighttpd 別名配置
4. **生命週期管理**: 應用的增刪改查操作

### **與 OpenWrt 包系統的整合**
- 在包安裝階段被調用
- 自動註冊新的微前端模組
- 更新服務發現字典
- 配置必要的網頁伺服器路由

### **API 整合策略** (戰略方向：USP/TR)
**當前實現**: 檔案型整合 (過渡方案)
```lua
-- 目前方式: 直接操作配置檔案
poc_nav1.json + lighttpd.conf
```

**目標架構**: USP/TR Model APIs
```bash
# 路由器上可用的 USP/TR 組件
/www/cgi-bin/obuspa.cgi    # USP Agent CGI 介面
127.0.0.1:8083             # usp-bridge 服務端點
/etc/config/obuspa         # USP Agent 配置
```

**遷移計劃**:
1. **第一階段** (目前): 檔案型整合，建立基礎功能
2. **第二階段**: 逐步整合 USP/TR APIs
3. **第三階段**: 完全捨棄 JNAP，純 USP/TR 架構

## 🎪 **真正的"Market"概念**

### **不是傳統的應用商店**
- **不是**: Google Play / App Store 模式
- **不是**: 下載 APK/執行檔的概念
- **不是**: 中央化的應用倉庫瀏覽

### **而是擴展包市場**
- **本質**: OpenWrt 包擴展系統
- **載體**: opkg 包管理器
- **內容**: 微前端 + 後端服務的組合包
- **安裝**: 透過 `opkg install package-name`
- **發現**: 透過自定義倉庫 (custom repo)

### **市場架構**
```
Custom Repo → Package List → opkg install → app_util.lua → Dictionary Update → UI Refresh
```

## 🔄 **系統整合流程**

### **新應用安裝流程**
1. **用戶操作**: `opkg install my-privacy-app`
2. **包安裝**: OpenWrt 安裝服務檔案和依賴
3. **後安裝腳本**: 調用 `app_util.lua new ...`
4. **配置更新**: 更新 `poc_nav1.json` 和字典服務
5. **UI 刷新**: Flutter 應用檢測到配置變更，動態載入新模組

### **微前端載入流程**
1. **Flutter 監聽**: 監聽配置檔案變更
2. **讀取字典**: 獲取新的服務端點信息
3. **動態載入**: 載入新的微前端模組
4. **UI 更新**: 在應用啟動器中顯示新應用

## 📊 **Demo vs 實際系統對比**

| 組件 | Demo 狀態 | 實際系統需求 |
|------|-----------|-------------|
| **app_util.lua** | ✅ 基礎功能完成 | 需要與 opkg 後安裝腳本整合 |
| **Flutter UI** | 🎬 概念驗證 | 需要微前端架構重構 |
| **字典服務** | ❌ 未實現 | 核心服務發現機制 |
| **微前端載入器** | ❌ 未實現 | 動態模組載入機制 |
| **Custom Repo** | ❌ 未實現 | 包分發系統 |
| **跨前端導航** | ❌ 未實現 | 前端間跳轉機制 |

## 🎯 **系統範圍總結**

### **已完成 (Demo 階段)**
- ✅ 基礎的應用配置管理
- ✅ lighttpd 路由自動配置
- ✅ JSON 配置的 CRUD 操作
- ✅ Flutter 卡片式 UI 原型

### **需要開發 (核心功能)**
- 🔧 微前端架構重構
- 🔧 字典微服務開發
- 🔧 動態前端發現機制
- 🔧 跨前端瀏覽系統
- 🔧 opkg 包整合腳本

### **需要開發 (市場功能)**
- 📦 自定義包倉庫建立
- 📦 包構建和分發流程
- 📦 開發者工具和框架
- 📦 包依賴管理系統

## 💡 **關鍵洞察**

這個系統的**真正創新**在於：

1. **突破編譯型限制**: 讓 Flutter 應用能夠動態擴展
2. **整合 OpenWrt 生態**: 利用現有的包管理基礎設施
3. **微前端革命**: 在路由器環境中實現微前端架構
4. **即插即用**: 真正實現應用的"live"安裝和移除
5. **標準化轉型**: 從 JNAP 遷移到 USP/TR 標準，提升互操作性

## 🎯 **戰略決策影響**

### **技術現況 vs 戰略方向**
- **現況**: 路由器同時支援 JNAP 和 USP/TR 兩套系統
- **決策**: 捨棄 JNAP，全面轉向 USP/TR Model APIs
- **影響**: 新開發的 app_util.lua 和套件將專注於 USP/TR 整合

### **app_util.lua 發展路徑**
```mermaid
graph LR
    A[檔案型整合<br/>(目前)] --> B[USP/TR API整合<br/>(目標)]
    B --> C[純USP/TR架構<br/>(未來)]

    style A fill:#fff8e1
    style B fill:#e3f2fd
    style C fill:#e8f5e8
```

這確實是一個**雄心勃勃且技術先進**的系統設計，遠超過簡單的應用啟動器概念！