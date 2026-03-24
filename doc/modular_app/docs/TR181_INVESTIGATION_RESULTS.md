# TR-181 路徑調查結果

## 🎯 **關鍵發現**

**用戶問題**: `□ 設計 TR-181 應用資料結構 (Device.LocalAgent.Apps.{i}) 這個是可用的嗎？`

**答案**: ❌ **不可用** - 需要調整方案

## 🔍 **實際 TR-181 結構**

### **✅ 發現的重要事實**

1. **路由器使用 `Device.USPAgent.*` 而非 `Device.LocalAgent.*`**
2. **沒有現成的 Apps 管理結構**
3. **有其他可擴展的 TR-181 路徑**

### **📊 完整的 TR-181 結構**

```bash
Device.
├── USPAgent.                    # 主要 USP 代理
│   ├── Controller.{i}.          # 控制器 (可擴展)
│   ├── ControllerTrust.
│   │   ├── Role.{i}.           # 角色管理 (可擴展)
│   │   ├── Credential.{i}.     # 憑證 (可擴展)
│   │   └── Challenge.{i}.      # 挑戰 (可擴展)
│   ├── MTP.{i}.                # 訊息傳輸協定 (可擴展)
│   └── Certificate.{i}.        # 憑證 (可擴展，但目前無項目)
├── MQTT.
│   └── Client.{i}.             # MQTT 客戶端 (可擴展)
│       └── Subscription.{i}.   # MQTT 訂閱 (可擴展)
└── STOMP.
    └── Connection.{i}.         # STOMP 連接 (可擴展)
```

## 💡 **替代方案**

既然 `Device.LocalAgent.Apps.{i}` 不存在，我們有以下選擇：

### **方案 1: 創建自定義 Vendor 擴展**
```bash
# 嘗試創建 vendor-specific 路徑
Device.X_LINKSYS_Applications.{i}.
```

### **方案 2: 使用現有可擴展路徑**
```bash
# 重用 Controller 路徑來管理應用
Device.USPAgent.Controller.{i}.ControllerCode = "LinksysApp"
Device.USPAgent.Controller.{i}.ProvisioningCode = "my-app-name"
```

### **方案 3: 使用 MQTT 路徑管理應用**
```bash
# 使用 MQTT 訂閱來追蹤應用狀態
Device.MQTT.Client.{i}.Name = "AppManager"
Device.MQTT.Client.{i}.Subscription.{i}.Topic = "linksys/apps/+/status"
```

## 🚦 **建議修正 MVP 計劃**

### **原計劃 (不可行)**
```bash
❌ Device.LocalAgent.Apps.{i}.Name
❌ Device.LocalAgent.Apps.{i}.Status
❌ Device.LocalAgent.Apps.{i}.InstallTime
❌ Device.LocalAgent.Apps.{i}.Link
```

### **修正方案 (推薦)**
```bash
# 方案 1: 先嘗試 Vendor 擴展
✅ Device.X_LINKSYS_Apps.{i}.Name
✅ Device.X_LINKSYS_Apps.{i}.Status
✅ Device.X_LINKSYS_Apps.{i}.InstallTime
✅ Device.X_LINKSYS_Apps.{i}.Link

# 方案 2: 如果不支援 vendor 擴展，使用現有路徑
✅ 直接更新 JSON 配置檔案 + MQTT 事件通知
```

## 🧪 **下一步驗證**

### **測試 1: 嘗試創建自定義路徑**
```bash
# 測試是否能添加 vendor-specific 路徑
ubus call bbfdm.obuspa add '{"path":"Device.X_LINKSYS_Apps."}'
```

### **測試 2: 如果失敗，改用 MQTT 方案**
```bash
# 完全依賴 JSON 配置 + MQTT 推送通知
# 這是最安全且確定可行的方案
```

## 📋 **結論**

**原始 TR-181 應用路徑不可用**，但我們有可行的替代方案：

1. **最佳方案**: 嘗試創建 `Device.X_LINKSYS_Apps.{i}` vendor 擴展
2. **備用方案**: 使用 MQTT 事件 + JSON 配置檔案
3. **最安全方案**: 純 JSON 配置 + 手動刷新 (如同目前實作)

MVP 計劃需要相應調整，移除對 `Device.LocalAgent.Apps.{i}` 的依賴。