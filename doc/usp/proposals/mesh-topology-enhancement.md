# Mesh Topology Enhancement Proposal

**Author:** Austin  
**Date:** 2026-06-01  
**Status:** In Progress  
**Branch:** `feature/mesh-topology-enhancement`  
**Base:** `feature/codegen-resolve-by`

---

## 1. Background

Codegen 已新增 5 個 DataElements Backhaul 欄位，但目前 UI 層尚未使用這些資料。本提案定義如何利用新欄位改善 Mesh Topology 的呈現與使用者體驗。

### 1.1 新增 Codegen 欄位（已完成）

| 欄位 | TR-181 Path | 說明 |
|------|-------------|------|
| `backhaulBackhaulDeviceId` | `MultiAPDevice.Backhaul.BackhaulDeviceID` | 上游節點 Device ID |
| `backhaulBackhaulMacAddress` | `MultiAPDevice.Backhaul.BackhaulMACAddress` | Backhaul 連線 MAC |
| `backhaulLinkType` | `MultiAPDevice.Backhaul.LinkType` | "Wi-Fi" / "Ethernet" |
| `backhaulMacAddressMultiAp` | `MultiAPDevice.Backhaul.MACAddress` | 連接到上游的 BSSID |
| `backhaulStatsLastDataDownlinkRate` | `MultiAPDevice.Backhaul.Stats.LastDataDownlinkRate` | 下行速率 (kbps) |

### 1.2 現有問題

1. **Slave 的 Parent Node 判斷錯誤**：所有 Slave 的 parentId 硬編碼為 Master，不支援多層 Mesh (Slave → Slave → Master)
2. **Backhaul 連線類型未判斷**：全部假設為 Wi-Fi
3. **只有 Uplink 速率**：缺少 Downlink 速率顯示
4. **訊號強度缺乏視覺化**：只顯示 dBm 數值

---

## 2. Scope

### In Scope

- `NodeUIModel` 新增欄位 ✅
- `MeshTopologyBuilder` 傳遞欄位 ✅
- `UspTopologyBuilder` 修正 Parent Node 判斷 ✅
- Node Detail View UI 強化 ✅
- Topology View Detail Panel 增強 ✅
- `NodeDetailPopup` 共用元件 ✅
- 相關測試更新 ✅
- **Diagnostics 整合（新增）**

### Out of Scope

- Topology 線段樣式客製化（依 UI Kit 支援程度）

---

## 3. Diagnostics Integration (New)

### 3.1 現有 `checkMeshBackhaul()` 分析

目前 `UnifiedDiagnosticsService.checkMeshBackhaul()` 使用：
- `backhaulMediaType` — 透過字串解析判斷 wired
- `backhaulPhyRate` — PHY 速率
- `backhaulStatsLastDataUplinkRate` — 上行速率
- `backhaulStatsSignalStrength` — RSSI

### 3.2 增強項目

#### 3.2.1 使用 `backhaulLinkType` 取代字串解析

**現況**：
```dart
final wired = node.backhaulMediaType.contains('Ethernet') ||
    node.backhaulMediaType.contains('MoCA') ||
    node.backhaulMediaType.contains('G.hn');
```

**改善**：
```dart
final wired = node.backhaulLinkType == 'Ethernet';
```

#### 3.2.2 新增 Downlink Rate 顯示

**變更**：`MeshBackhaulNodeRecord` 新增 `lastDownlinkRateMbps` 欄位

```dart
class MeshBackhaulNodeRecord {
  // ...existing fields...
  final int lastUplinkRateMbps;
  final int lastDownlinkRateMbps;  // NEW
  // ...
}
```

#### 3.2.3 新增 Parent Node 追蹤

**變更**：`MeshBackhaulNodeRecord` 新增 `parentNodeId` 和 `parentLabel`

```dart
class MeshBackhaulNodeRecord {
  // ...existing fields...
  final String? parentNodeId;   // NEW: BackhaulDeviceID
  final String? parentLabel;    // NEW: Resolved parent node label
  // ...
}
```

#### 3.2.4 新增 Last Contact Time 檢查

**變更**：`MeshBackhaulNodeRecord` 新增 `lastContactTime` 和 `isStale`

```dart
class MeshBackhaulNodeRecord {
  // ...existing fields...
  final String? lastContactTime;  // NEW: ISO 8601
  final bool isStale;             // NEW: > 5 minutes since last contact
  // ...
}
```

#### 3.2.5 增強嚴重性評估

**現況**：只考慮 PHY rate 和 RSSI

**改善**：加入 downlink rate 和 stale 狀態

```dart
MeshBackhaulSeverityBucket _gradeMeshBackhaul({
  required bool wired,
  required int phyRateMbps,
  required int signalDbm,
  required int downlinkRateMbps,  // NEW
  required bool isStale,          // NEW
}) {
  // Stale node is always a warning
  if (isStale) return MeshBackhaulSeverityBucket.weak;
  
  if (wired) return MeshBackhaulSeverityBucket.healthy;

  // Check for asymmetric throughput (downlink << uplink)
  // ...existing logic...
}
```

### 3.3 UI Model 更新

**檔案**：`lib/page/unified_diagnostics/models/diagnostic_result.dart`

```dart
class MeshNodeBackhaulUIModel extends Equatable {
  // ...existing fields...
  
  // NEW fields
  final int lastDownlinkRateMbps;
  final String? parentNodeId;
  final String? parentLabel;
  final String? lastContactTime;
  final bool isStale;
  
  // ...
}
```

### 3.4 Implementation Plan

| 順序 | 項目 | 檔案 | 預估 |
|------|------|------|------|
| 1 | `MeshBackhaulNodeRecord` 新增欄位 | `unified_diagnostics_service.dart` | 0.5h |
| 2 | 更新 `checkMeshBackhaul()` 邏輯 | `unified_diagnostics_service.dart` | 1h |
| 3 | `MeshNodeBackhaulUIModel` 新增欄位 | `diagnostic_result.dart` | 0.5h |
| 4 | Notifier mapping 更新 | `unified_diagnostics_notifier.dart` | 0.5h |
| 5 | Results View UI 更新 | `diagnostic_results_view.dart` | 1h |
| 6 | 測試更新 | TBD | 1h |

**預估總時間**：4.5 小時

---

## 4. Completed Implementation Summary

### Phase 1: Topology UI (Completed ✅)

| # | 項目 | 狀態 |
|---|------|------|
| 1 | `NodeUIModel` 新增 5 欄位 | ✅ |
| 2 | `MeshTopologyBuilder` 傳遞欄位 | ✅ |
| 3 | `UspTopologyBuilder` Parent Node 判斷 | ✅ |
| 4 | `UspTopologyBuilder` Link connectionType | ✅ |
| 5 | `UspTopologyBuilder` metadata 擴充 | ✅ |
| 6 | `node_detail_provider` 新增 parentNode | ✅ |
| 7 | `usp_node_detail_view` Backhaul Card 強化 | ✅ |
| 8 | `usp_topology_view` Detail Panel 增強 | ✅ |
| 9 | `NodeDetailPopup` 共用元件 | ✅ |
| 10 | `BackhaulSignalIndicator` 視覺化 | ✅ |
| 11 | 測試更新 | ✅ |

### Phase 2: Diagnostics Integration (Completed ✅)

| # | 項目 | 狀態 |
|---|------|------|
| 1 | `MeshBackhaulNodeRecord` 新增欄位 | ✅ |
| 2 | `checkMeshBackhaul()` 邏輯更新 | ✅ |
| 3 | `MeshNodeBackhaulUIModel` 新增欄位 | ✅ |
| 4 | Notifier mapping 更新 | ✅ |
| 5 | Results View UI 更新 | ✅ |
| 6 | 測試更新 | ✅ |

---

## 5. Affected Files Summary

### Phase 1 (Completed)

| 檔案 | 變更類型 |
|------|----------|
| `lib/page/topology/models/node_ui_model.dart` | 新增欄位 |
| `lib/page/_shared/utils/mesh_topology_builder.dart` | 傳遞新欄位 |
| `lib/page/topology/helpers/usp_topology_builder.dart` | 修正 parentId 邏輯 |
| `lib/page/topology/providers/node_detail_provider.dart` | 新增 parentNode |
| `lib/page/topology/views/usp_node_detail_view.dart` | UI 強化 |
| `lib/page/topology/views/usp_topology_view.dart` | Detail Panel 增強 |
| `lib/page/topology/cards/usp_network_topology_card.dart` | 使用共用元件 |
| `lib/page/topology/views/components/node_detail_popup.dart` | **新增** 共用元件 |
| `lib/page/topology/views/components/backhaul_signal_indicator.dart` | **新增** 視覺化 |
| `lib/page/_shared/components/detail_widgets.dart` | 新增 widgets |
| `lib/page/devices/services/usp_devices_data_service.dart` | 欄位傳遞修正 |
| `lib/util/date_format_utils.dart` | 新增 formatRelativeTime |
| `test/page/_shared/utils/mesh_topology_builder_test.dart` | 測試更新 |
| `test/page/topology/helpers/usp_topology_builder_test.dart` | 測試更新 |

### Phase 2 (Pending)

| 檔案 | 變更類型 |
|------|----------|
| `lib/page/unified_diagnostics/services/unified_diagnostics_service.dart` | 增強 checkMeshBackhaul |
| `lib/page/unified_diagnostics/models/diagnostic_result.dart` | 新增欄位 |
| `lib/page/unified_diagnostics/providers/unified_diagnostics_notifier.dart` | Mapping 更新 |
| `lib/page/unified_diagnostics/views/widgets/diagnostic_results_view.dart` | UI 更新 |

---

## 6. Terminology

本專案使用 **Master/Slave** 術語，而非 Gateway/Extender：

| 角色 | 說明 |
|------|------|
| **Master** | 主路由器，`backhaulAlId` 為空 |
| **Slave** | 子節點，`backhaulAlId` 指向上游節點 |

注意：`MeshNodeType.gateway/extender` 是 UI Kit 內部枚舉，無法修改，但使用者看到的文字應顯示 Master/Slave。
