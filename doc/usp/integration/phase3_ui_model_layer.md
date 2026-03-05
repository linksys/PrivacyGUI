# Phase 3：UI Model 層建立

> 文件版本：v1.0 | 日期：2026-03-05
> 前置文件：`phase2_jnap_usp_migration_plan.md`
> 憲章依據：`constitution.md` — Article V (5.3, 5.3.1, 5.3.4), Article VI, Article XI, Article III (3.3.4)

---

## 1. 背景與目標

### 1.1 現狀問題

Phase 2 建立了 USP Dashboard 獨立頁面，但 Presentation 層直接依賴 Data 層（codegen 產生的類別），違反憲章三層架構原則：

```
❌ 目前架構

Presentation (views)
  └── 直接使用 ConnectedDevice (codegen)
  └── 直接使用 WifiClient (codegen)
  └── 手動用 MAC 做 cross-reference
  └── enrichment 邏輯散落在各 widget build() 中
```

具體問題：

| 問題 | 說明 |
|---|---|
| 層級耦合 | UI widget 直接 import codegen Data Model（`connected_devices.g.dart`） |
| 參數爆炸 | `UspConnectedDevicesCard` 需 5 個參數（devices + 3 enricher map + gatewayName） |
| 邏輯散落 | WiFi/Ethernet 判斷、signal lookup、node name 解析等邏輯在各 widget 重複 |
| 可測試性差 | widget 內含轉換邏輯，難以獨立單元測試 |

### 1.2 目標架構

依照憲章 Section 5.3.1 Model Hierarchy：

```
✅ 目標架構

┌── Presentation ──────────────────────┐
│ views/ — 只使用 DeviceUIModel        │
│ ❌ 不 import codegen Data Model      │
└──────────────┬───────────────────────┘
               │ 依賴方向：向下
┌──────────────▼───────────────────────┐
│ Application ─────────────────────────│
│ providers/ — UspDashboardNotifier    │
│ services/  — UspDeviceService        │
│              (Data → UI Model 轉換)  │
│ models/    — DeviceUIModel 定義      │
└──────────────┬───────────────────────┘
               │ 依賴方向：向下
┌──────────────▼───────────────────────┐
│ Data ────────────────────────────────│
│ generated/ — ConnectedDevice, etc.   │
│ providers/ — enrichers (WifiClient)  │
└──────────────────────────────────────┘
```

### 1.3 UI Model 建立依據

依照憲章 Section 5.3.4 Decision Criteria：

| 條件 | 判定 |
|---|---|
| Collection/List Data（集合型資料） | ✅ `List<DeviceUIModel>` |
| Data Reusability（多處重用） | ✅ ConnectedDevicesCard + NetworkTopologyCard |
| Complex Nested Structures（>5 fields） | ✅ 12+ fields |
| Contains Calculation Logic（含運算邏輯） | ✅ signal quality、connection type、node name |

**結論**：應建立獨立 UI Model。

---

## 2. 影響範圍分析

### 2.1 需改造的元件

| 元件 | 目前參數 | 改造後參數 |
|---|---|---|
| `UspConnectedDevicesCard` | `devices` + `wifiClientMap` + `meshTopology` + `connectionDetailMap` + `gatewayName` | `List<DeviceUIModel>` |
| `UspNetworkTopologyCard` | `info` + `devices` + `wifiClientMap` + `meshTopology` | `info` + `List<DeviceUIModel>` + `List<MeshNodeInfo>` |
| `UspDashboardView` | 傳遞多個 map 給上述 card | 傳遞 `state.deviceModels` |
| `UspDashboardState` | 不含 UI model | 新增 `deviceModels` |
| `UspDashboardNotifier` | 直接返回 raw data | 呼叫 Service 轉換 |

### 2.2 不受影響的元件

以下 card 不使用 enricher 資料，不需要改造：

- `UspStatsPanel` — 聚合統計（device count、radio count）
- `UspConnectionStatusCard` — 簡單 active/total 顯示
- `UspSystemStatusCard` — CPU/memory/uptime（from SystemInfo）
- `UspDeviceInfoCard` — model/serial/firmware（from SystemInfo）
- `UspWifiStatusCard` — radio/SSID/AP tree（from WiFi codegen）
- `UspDhcpReservationsCard` — DHCP CRUD（from DhcpReservations codegen）
- `UspPortForwardingCard` — Port Forward CRUD（from PortForwarding codegen）
- `UspProtocolInfoCard` — 靜態顯示

---

## 3. 資料結構規格

### 3.1 `DeviceUIModel`

命名依照 Section 3.3.4（以 `UIModel` 結尾），實作 `Equatable`（Article XI）。

```dart
/// Presentation Layer Model — 整合 codegen + 所有 enricher 的 per-device 資訊。
///
/// UI widget 只依賴此 class，不直接 import codegen Data Model。
class DeviceUIModel extends Equatable {
  // ─── 基礎資訊（from ConnectedDevice codegen） ───
  final String mac;           // PhysAddress (uppercase, normalized)
  final String ip;            // IPAddress
  final String hostName;      // HostName
  final bool isActive;        // Active
  final bool isWifi;          // 從 Layer1Interface 推導

  // ─── WiFi enrichment（null if ethernet） ───
  final int? signalStrength;  // RSSI dBm (from WifiClient)
  final int? downlinkRate;    // bits/sec (from WifiClient)
  final int? uplinkRate;      // bits/sec (from WifiClient)
  final String? band;         // "2.4GHz" / "5GHz" / "6GHz" (from ClientConnectionDetail)
  final String? ssidName;     // SSID name (from ClientConnectionDetail)

  // ─── Mesh enrichment ───
  final String? parentNodeId;   // 連接到哪個 mesh node 的 device ID
  final String? parentNodeName; // mesh node 的 model name（顯示用）

  // ─── Computed getters ───

  /// Display name: hostName if available, otherwise MAC
  String get displayName => hostName.isNotEmpty ? hostName : mac;

  /// Signal quality: 0.0–1.0, mapped from RSSI
  /// -30 dBm (excellent) → 1.0, -90 dBm (poor) → 0.0
  double get signalQuality {
    if (signalStrength == null) return 0;
    return ((signalStrength! + 90) / 60).clamp(0.0, 1.0);
  }

  /// Signal level: 0 (no signal) to 3 (excellent)
  int get signalLevel {
    if (signalStrength == null) return 0;
    if (signalStrength! >= -50) return 3;
    if (signalStrength! >= -65) return 2;
    if (signalStrength! >= -80) return 1;
    return 0;
  }

  /// Total throughput in bits/sec
  int get totalThroughput => (downlinkRate ?? 0) + (uplinkRate ?? 0);

  @override
  List<Object?> get props => [
    mac, ip, hostName, isActive, isWifi,
    signalStrength, downlinkRate, uplinkRate, band, ssidName,
    parentNodeId, parentNodeName,
  ];
}
```

### 3.2 資料來源對映表

| DeviceUIModel field | Source | Lookup method |
|---|---|---|
| `mac` | `ConnectedDevice.macAddress` | Direct (uppercase) |
| `ip` | `ConnectedDevice.ipAddress` | Direct |
| `hostName` | `ConnectedDevice.hostName` | Direct |
| `isActive` | `ConnectedDevice.isActive` | Direct |
| `isWifi` | `ConnectedDevice.interface_` | Contains "WiFi" check |
| `signalStrength` | `WifiClient.signalStrength` | `wifiClientMap[MAC]` |
| `downlinkRate` | `WifiClient.lastDataDownlinkRate` | `wifiClientMap[MAC]` |
| `uplinkRate` | `WifiClient.lastDataUplinkRate` | `wifiClientMap[MAC]` |
| `band` | `ClientConnectionDetail.band` | `connectionDetailMap[MAC]` |
| `ssidName` | `ClientConnectionDetail.ssidName` | `connectionDetailMap[MAC]` |
| `parentNodeId` | `MeshTopologyInfo.clientToNodeMap` | `clientToNodeMap[MAC]` |
| `parentNodeName` | `MeshNodeInfo.model` | `nodes.where(id == parentNodeId)` or gatewayName |

---

## 4. Service 層規格

### 4.1 `UspDeviceService`

依照 Article VI：stateless、constructor injection、負責 Data → UI 轉換。

**檔案位置**: `lib/usp_page/dashboard/services/usp_device_service.dart`

```dart
final uspDeviceServiceProvider = Provider<UspDeviceService>(
  (ref) => UspDeviceService(),
);

class UspDeviceService {
  /// Transform raw codegen data + enricher maps → UI-ready device models.
  ///
  /// Filters out the router itself (empty Layer1Interface).
  /// Consolidates all per-device enrichment into a single [DeviceUIModel].
  List<DeviceUIModel> buildDeviceUIModels({
    required ConnectedDevices connectedDevices,
    required Map<String, WifiClient> wifiClientMap,
    required Map<String, ClientConnectionDetail> connectionDetailMap,
    required MeshTopologyInfo meshTopology,
    required String gatewayName,
  }) {
    return connectedDevices.items
        .where((d) => d.interface_.isNotEmpty)  // 排除 router 本身
        .map((d) => _toUIModel(d, wifiClientMap, connectionDetailMap, meshTopology, gatewayName))
        .toList();
  }

  DeviceUIModel _toUIModel(
    ConnectedDevice device,
    Map<String, WifiClient> wifiClientMap,
    Map<String, ClientConnectionDetail> connectionDetailMap,
    MeshTopologyInfo meshTopology,
    String gatewayName,
  ) {
    final mac = device.macAddress.trim().toUpperCase();
    final isWifi = device.interface_.toLowerCase().contains('wifi');
    final wifiClient = wifiClientMap[mac];
    final detail = connectionDetailMap[mac];

    // Mesh: resolve parent node name
    String? parentNodeId;
    String? parentNodeName;
    if (meshTopology.isNotEmpty) {
      parentNodeId = meshTopology.clientToNodeMap[mac];
      if (parentNodeId != null) {
        final matchingNode = meshTopology.nodes
            .where((n) => n.deviceId == parentNodeId)
            .firstOrNull;
        parentNodeName = matchingNode?.model ?? gatewayName;
      } else {
        parentNodeName = gatewayName;
      }
    }

    return DeviceUIModel(
      mac: mac,
      ip: device.ipAddress,
      hostName: device.hostName,
      isActive: device.isActive,
      isWifi: isWifi,
      signalStrength: isWifi ? wifiClient?.signalStrength : null,
      downlinkRate: isWifi ? wifiClient?.lastDataDownlinkRate : null,
      uplinkRate: isWifi ? wifiClient?.lastDataUplinkRate : null,
      band: detail?.band,
      ssidName: detail?.ssidName,
      parentNodeId: parentNodeId,
      parentNodeName: parentNodeName,
    );
  }
}
```

### 4.2 轉換邏輯說明

| 邏輯 | 說明 |
|---|---|
| Router 過濾 | `interface_.isEmpty` → 排除（router 本身的 Layer1Interface 為空） |
| WiFi 判定 | `interface_.toLowerCase().contains('wifi')` |
| Signal lookup | `wifiClientMap[MAC.toUpperCase()]` → WifiClient |
| Band/SSID lookup | `connectionDetailMap[MAC.toUpperCase()]` → ClientConnectionDetail |
| Node 解析 | `clientToNodeMap[MAC]` → nodeId → `nodes.firstWhere(id==nodeId).model` |
| Node fallback | 若 mesh 存在但 client 未在 map 中 → 使用 gatewayName |

---

## 5. 實作步驟

### Step 1: 新增 `DeviceUIModel`
- **檔案**: `lib/usp_page/dashboard/models/device_ui_model.dart`（新增）
- 內容：Section 3.1 定義

### Step 2: 新增 `UspDeviceService`
- **檔案**: `lib/usp_page/dashboard/services/usp_device_service.dart`（新增）
- 內容：Section 4.1 定義

### Step 3: 更新 `UspDashboardState`
- **檔案**: `lib/usp_page/dashboard/providers/usp_dashboard_state.dart`
- 新增 `final List<DeviceUIModel> deviceModels` 欄位
- 更新 `copyWith`、`props`

### Step 4: 更新 `UspDashboardNotifier`
- **檔案**: `lib/usp_page/dashboard/providers/usp_dashboard_notifier.dart`
- `build()` 最後呼叫 `uspDeviceServiceProvider` 轉換 UI Model
- 將 `deviceModels` 存入 state

### Step 5: 重構 `UspConnectedDevicesCard`
- **檔案**: `lib/usp_page/dashboard/views/components/usp_connected_devices_card.dart`
- 參數改為 `List<DeviceUIModel> devices`
- 移除 MAC lookup 邏輯
- 直接使用 `device.signalStrength`、`device.band`、`device.parentNodeName` 等

### Step 6: 重構 `UspNetworkTopologyCard`
- **檔案**: `lib/usp_page/dashboard/views/components/usp_network_topology_card.dart`
- 參數改為 `List<DeviceUIModel> devices` + `List<MeshNodeInfo> meshNodes`
- 使用 `device.signalQuality`、`device.totalThroughput`、`device.parentNodeId`

### Step 7: 更新 `UspDashboardView`
- **檔案**: `lib/usp_page/dashboard/views/usp_dashboard_view.dart`
- 簡化 card 呼叫：`UspConnectedDevicesCard(devices: state.deviceModels)`
- 移除 `_buildContent` 中的 `devices` local variable 和 `activeCount` 計算（改用 `state.deviceModels`）

---

## 6. 驗證標準

### 6.1 靜態分析
- `flutter analyze` 零新錯誤

### 6.2 層級隔離檢查
```bash
# Views 不應 import codegen Data Model
grep -r "import.*generated/connected_devices" lib/usp_page/dashboard/views/
grep -r "import.*generated/wifi_clients" lib/usp_page/dashboard/views/
# ✅ 應返回 0 結果

# Service 應 import codegen Data Model
grep -r "import.*generated/" lib/usp_page/dashboard/services/
# ✅ 應有結果
```

### 6.3 功能驗證
- Connected Devices card 顯示不變（hostname、IP、signal、band、SSID、parent node）
- Network Topology card 顯示不變（gateway、extenders、clients、signal quality 動畫）
- Pull-to-refresh 正常更新 UI model
- CRUD 操作（DHCP、Port Forwarding）不受影響
- 登出流程不受影響

---

## 7. 檔案清單

| 操作 | 檔案路徑 |
|---|---|
| 新增 | `lib/usp_page/dashboard/models/device_ui_model.dart` |
| 新增 | `lib/usp_page/dashboard/services/usp_device_service.dart` |
| 修改 | `lib/usp_page/dashboard/providers/usp_dashboard_state.dart` |
| 修改 | `lib/usp_page/dashboard/providers/usp_dashboard_notifier.dart` |
| 重構 | `lib/usp_page/dashboard/views/components/usp_connected_devices_card.dart` |
| 重構 | `lib/usp_page/dashboard/views/components/usp_network_topology_card.dart` |
| 修改 | `lib/usp_page/dashboard/views/usp_dashboard_view.dart` |
