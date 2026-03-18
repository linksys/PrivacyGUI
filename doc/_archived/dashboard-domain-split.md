# USP Dashboard 架構重構計畫

## 背景

`UspDashboardNotifier`（1119 行）是一個 God Notifier：一次性 fetch 17+ 資料源、包含所有 mutation 方法、管理所有 SSE invalidation。所有 card 必須等待全部 fetch 完成，任何 state 變更都觸發全部 card 重新評估。本次重構將其拆分為 domain-specific data providers，並將 USP page notifiers 遷移至 `FeatureState` + `Preservable` 框架，建立輕量的 dashboard orchestrator。

## 相關文件

| 文件 | 說明 |
|------|------|
| [domain-split-playbook.md](domain-split-playbook.md) | **標準化遷移流程** — Type A/B/C 模板、code templates、常見陷阱 |
| [phase0-1-firewall-mvp.md](phase0-1-firewall-mvp.md) | Phase 0 + 1 實作細節記錄 |

## 分支與安全策略

- **分支**：`refactor/dashboard-domain-split`（從 `feat/sse-connection-reliability` 建立）
- **框架檔案隔離**：`lib/providers/` 下的框架核心檔案複製到 `lib/usp_page/_framework/`，原始檔案不做修改，避免影響 JNAP 頁面
- **遷移流程**：所有 domain 依 [Playbook](domain-split-playbook.md) 判斷 Type A/B/C 後按步驟執行

## 架構總覽

```
Layer 3: Dashboard Orchestrator + Aggregate（Phase 4）
         ├── Auth + SSE bootstrap 協調
         ├── 批次初始化 data providers（3 個並發）
         └── Aggregate：跨 domain 摘要給 Stats Panel

Layer 2: Feature Page Notifiers（autoDispose）
         ├── ref.read(dataProvider.future) 初始化時 clone，不 watch
         ├── FeatureState<TSettings, TStatus> + Preservable
         ├── PreservableAutoDisposeNotifierMixin（fetch/save/revert）
         ├── SSE dirty guard：!isDirty → fetch；isDirty → 忽略
         └── Route dirty check 透過 preservableProvider

Layer 1: Domain Data Providers（NOT autoDispose）
         ├── 原始 codegen 資料 fetch + cache
         ├── SSE invalidation → debounce 500ms → ref.invalidateSelf()
         ├── Dashboard cards 直接 ref.watch()
         └── Page notifiers 初始化時 ref.read()
```

## 關鍵設計決策

- **Data providers**：`AsyncNotifier`（NOT autoDispose）。持有原始 codegen 資料，SSE 自動更新。
- **Page notifiers**：`AutoDisposeNotifier`（同步 build + `Future.microtask(() => fetch())`）。從 data provider clone 資料，使用 FeatureState 框架。
- **Dashboard cards**：直接 `ref.watch(domainDataProvider)`。各 card 獨立顯示 skeleton 等待載入。
- **CRUD 列表頁面**（port forwarding、DHCP reservations、static routing、IPv6 port service、port triggering）：使用 FeatureState + Preservable，本地累積 add/edit/delete → batch save（`addMultiple` + `set` + `delete` diff）。→ Playbook **Type B**
- **唯讀 / toggle / dialog atomic 頁面**（admin、system_log、instant_privacy、time settings）：不需要 FeatureState，直接消費 data provider。→ Playbook **Type C**
- **Mutation lock**：共享的 `UspMutationLock` provider（Completer-based wait queue），取代各 notifier 私有的 `_mutating` flag。

## 參考實作

| 模式 | 參考檔案 |
|------|----------|
| Type A (FeatureState — Form) — MVP | `lib/usp_page/firewall/providers/usp_firewall_notifier.dart` |
| Type A (FeatureState — Form) — 先行者 | `lib/usp_page/wifi_settings/providers/usp_wifi_settings_provider.dart` |
| Type B (FeatureState — CRUD List) JNAP 參考 | `lib/page/advanced_settings/firewall/providers/ipv6_port_service_list_provider.dart` |
| Layer 1 Data Provider | `lib/usp_page/firewall/providers/firewall_data_provider.dart` |
| 框架 mixin + SSE guard | `lib/usp_page/_framework/preservable_notifier_mixin.dart` |
| 共享 mutation lock | `lib/usp/providers/usp_mutation_lock.dart` |
| Batch add API | `lib/usp/services/usp_service.dart:291` (`addMultiple`) |
| Route dirty check | `lib/route/route_model.dart:58-74` |

---

## Phase 0：框架增強 ✅ 已完成

### 0.1 複製框架檔案到 `lib/usp_page/_framework/` ✅

| 檔案 | 處理方式 |
|------|----------|
| `_framework/preservable.dart` | 複製，import 指向 `_framework/` 內部 |
| `_framework/feature_state.dart` | 複製，import 指向 `_framework/preservable.dart` |
| `_framework/preservable_notifier_mixin.dart` | 複製 + 增強（加入 `onSseInvalidation()`） |
| `_framework/preservable_contract.dart` | **Re-export**（非複製） |

> **重要**：`preservable_contract.dart` 必須 re-export 原始的 `lib/providers/preservable_contract.dart`，因為 `LinksysRoute` 的 `preservableProvider` 參數期望原始型別。複製會產生型別不相容。

### 0.2 SSE Invalidation Guard ✅

在 `PreservableNotifierMixin` 和 `PreservableAutoDisposeNotifierMixin` 兩個 mixin 各加入：

```dart
void onSseInvalidation() {
  if (!isDirty()) {
    fetch(forceRemote: true);
  }
}
```

### 0.3 共享 USP Mutation Lock ✅

`lib/usp/providers/usp_mutation_lock.dart` — Completer-based wait queue：

```dart
class UspMutationLock {
  Completer<void>? _completer;
  bool get isLocked => _completer != null && !_completer!.isCompleted;

  Future<T> withLock<T>(Future<T> Function() action) async {
    while (isLocked) { await _completer!.future; }
    _completer = Completer<void>();
    try { return await action(); } finally { _completer!.complete(); }
  }
}
```

---

## Phase 1：MVP — Firewall Domain ✅ 已完成

> 詳細實作記錄見 [phase0-1-firewall-mvp.md](phase0-1-firewall-mvp.md)
> 遷移模式：Playbook **Type A**（FeatureState）

**選擇 Firewall 的原因**：自包含（無跨域依賴）、已有 ad-hoc dirty tracking + SSE、有 dashboard card、複雜度適中。

### 已完成項目

| 步驟 | 檔案 | 狀態 |
|------|------|------|
| Layer 1 Data Provider | `firewall/providers/firewall_data_provider.dart` | ✅ 新增 |
| FeatureState Models | `firewall/models/firewall_{settings,status,feature_state}.dart` | ✅ 新增 |
| Layer 2 Page Notifier | `firewall/providers/usp_firewall_notifier.dart` | ✅ 重寫 |
| Preservable Provider | `preservableUspFirewallProvider` | ✅ 新增 |
| Dashboard Card | `usp_firewall_overview_card.dart` | ✅ 改用 `firewallDataProvider` |
| Dashboard State | `usp_dashboard_state.dart` | ✅ 移除 firewall 欄位 |
| Dashboard Notifier | `usp_dashboard_notifier.dart` | ✅ 移除 fetch + SSE handler |
| PDF Report | `usp_sliver_dashboard_view.dart` | ✅ 改用 `firewallDataProvider` |
| Route Dirty Check | `route_usp_dashboard.dart` | ✅ `enableDirtyCheck: true` |
| View + BottomBar | `usp_firewall_view.dart` | ✅ `UiKitBottomBarConfig` |

### 驗證結果

- [x] `flutter analyze` — 0 errors
- [x] Firewall card 獨立於 dashboard 載入
- [x] FeatureState + Preservable 框架運作
- [x] SSE dirty guard 由框架提供
- [x] Route dirty check 設定完成
- [x] Bottom bar 使用 `UiKitBottomBarConfig`（Save + Cancel/Revert）
- [x] Dashboard notifier 不再管理 firewall 資料
- [x] JNAP 頁面不受影響

### MVP 過程中發現的問題（已記錄於 Playbook 常見陷阱）

1. `PreservableContract` 型別不相容 → re-export 解法
2. Dashboard state 殘留引用 → 全域搜尋 + fallback
3. Mutation lock 需要 wait queue 而非 throw-on-contention

---

## Phase 2：獨立簡單 Domain ✅ 已完成

> 每個 domain 按 [Playbook](domain-split-playbook.md) 執行。

### 2.1 Time Settings — Type C (Dialog Atomic) ✅
- **Data Provider**：`lib/usp_page/admin/providers/time_data_provider.dart`（AsyncNotifier，無 SSE）
- **Dashboard**：`usp_time_settings_card.dart` → watch `timeDataProvider`
- **Dashboard 移除**：`timeSettings`、`timeSettingsModel`、`updateTimeSettings()`
- **結論**：Time settings 的編輯是 dialog atomic mutation，不需 FeatureState

### 2.2 LAN Info — Type C (Read-Only) ✅
- **Data Provider**：`lib/usp_page/local_network/providers/lan_data_provider.dart`（LanNetworkInfo + IPv6）
- **Dashboard**：`usp_lan_info_card.dart` → watch `lanDataProvider`
- **Dashboard 移除**：`lanNetworkInfo`、`lanInfoModel`

### 2.3 DHCP — Layer 1 完成 ✅（Page Notifier 遷移 → Phase 6, Type B）
- **Data Provider**：`lib/usp_page/local_network/providers/dhcp_data_provider.dart`（DhcpClients + DhcpReservations）
- **Dashboard**：`usp_dhcp_reservations_card.dart` → watch `dhcpDataProvider`
- **Dashboard 移除**：`dhcpClients`、`dhcpReservations`、所有 DHCP mutations
- **跨域依賴**：hostname enrichment 仍透過 `uspDashboardProvider` 讀取 `connectedDevices` → Phase 3.2 解決
- **待辦**：Page notifier 遷移至 FeatureState CRUD List（Preservable + batch save）→ Phase 6

### 2.4 Port Forwarding + Port Triggering — Layer 1 完成 ✅（Page Notifier 遷移 → Phase 6, Type B）
- **Data Providers**：`port_forwarding_data_provider.dart` + `port_triggering_data_provider.dart`
- **List Notifiers**：12 個 mutation 方法搬到 domain notifiers
- **SSE**：`InvalidationDomain.portForwarding`
- **Dashboard 移除**：`portForwarding`、`portTriggering`、所有 rule models + 12 個 mutations
- **跨域依賴**：`usp_single_port_tab.dart` 仍透過 `uspDashboardProvider` 讀取 `deviceModels`（IP 下拉選單）→ Phase 3.2 解決
- **待辦**：Page notifiers 遷移至 FeatureState CRUD List（Preservable + diff-based batch save，使用 `addMultiple`）→ Phase 6

### 2.5 WAN Status — Type C (Read-Only + mutation) ✅
- **Data Provider**：`lib/usp_page/internet_settings/providers/wan_data_provider.dart`（WanStatus + gateway + IPv6）
- **Mutation**：`renewWanLease()` 搬到 WAN provider（使用 mutation lock）
- **Dashboard**：`usp_network_status_card.dart` → watch `wanDataProvider`
- **Dashboard 移除**：`wanStatus`、`wanStatusModel`、`renewWanLease()`

### 2.6 System Info — Type C (Read-Only) ✅
- **Data Provider**：`lib/usp_page/admin/providers/system_info_data_provider.dart`（SystemInfo + FirmwareImages）
- **Dashboard**：`usp_device_info_card.dart` → watch `systemInfoDataProvider`
- **Dashboard 移除**：`systemInfo`、`systemInfoModel`、`_fetchFirmwareImages()`

### 額外清理：`uspMutationLoadingProvider` 提取 ✅
- 原本定義在 `usp_dashboard_notifier.dart` — 搬到 `usp_mutation_helper.dart`
- 6 個檔案的 `usp_dashboard_notifier.dart` import 改為透過 `usp_mutation_helper.dart` 取得

### Phase 2 Dashboard State 現狀

提取 8 個 domain 後，`UspDashboardState` 僅剩：

| 類別 | 欄位 |
|------|------|
| Raw codegen | `connectedDevices`、`wifiRadios`、`wifiSsids`、`wifiAccessPoints`、`ethernetInterfaces` |
| Enrichment | `wifiClientMap`、`meshTopology`、`connectionDetailMap` |
| UI Models | `deviceModels`、`wifiRadioModels`、`ethernetPortModels`、`nodeModels` |
| Control | `isAuthenticated` |

Dashboard notifier：4 batches、8 `timed()` calls、`this.total = 8`。

### 已知跨域依賴（Phase 3 待處理）

| 檔案 | 依賴 | 解決時機 |
|------|------|----------|
| `port_forwarding/views/components/usp_single_port_tab.dart:101` | `deviceModels` — IP 下拉選單 | Phase 3.2 |
| `local_network/providers/dhcp_data_provider.dart:76` | `connectedDevices.items` — hostname enrichment | Phase 3.2 |

### Phase 2 驗證結果
- [x] `flutter analyze` — 0 errors
- [x] 各 domain data provider 建立完成
- [x] Dashboard cards 改用各自的 data provider
- [x] `UspDashboardNotifier` 縮減至僅剩 WiFi + Devices + Ethernet + Mesh
- [x] Dashboard state 欄位清理完成
- [x] PDF report 遷移完成（`PdfReportData` nullable 欄位）
- [x] `uspMutationLoadingProvider` 從 God Notifier 提取到 `usp_mutation_helper.dart`

---

## Phase 3：有交叉依賴的 Domain ✅ 已完成

### 3.1 WiFi Data Provider ✅
- **Data Provider**：`lib/usp_page/wifi_settings/providers/wifi_data_provider.dart`
- Fetch：`WiFiRadios`、`WiFiSsids`、`WiFiAccessPoints` + WiFi clients
- SSE：`wifiRadios`、`wifiSsids`、`wifiAccessPoints`、`wifiClients` domains → debounce 500ms → invalidateSelf
- Mutations：`toggleWifiRadio()` + `updateWifiRadioChannel()`
- 產生：`WifiData`（raw + enrichment maps + `radioModels`）
- 消費者：WiFi Status Card、WiFi Performance Card、WiFi Settings Provider、Stats Panel、Statistics WiFi sections、PDF report

### 3.2 Devices Data Provider ✅
- **Data Provider**：`lib/usp_page/devices/providers/devices_data_provider.dart`
- Fetch：`ConnectedDevices` + `fetchMeshNodes()` 並行
- Enrichment：`ref.read(wifiDataProvider)` 用於 WiFi client map + connection details → `buildDeviceUIModels`
- Cross-domain：`ref.read(systemInfoDataProvider)` 用於 gateway name + `buildNodeUIModels`
- SSE：`connectedDevices` → debounce 500ms → invalidateSelf
- WiFi listener：`ref.listen(wifiDataProvider)` → 重建 `deviceModels`
- 產生：`DevicesData`（`ConnectedDevices` + `MeshTopologyInfo` + `deviceModels` + `nodeModels`）
- 消費者：Connected Devices Card、Topology Card、WiFi Performance Card、Device Filter/Detail/Node Detail Providers、Device Analytics、Stats Panel、Device List View、Topology View、IPv6 Port Service View、Single Port Tab、DHCP hostname enrichment、PDF report
- **Phase 3.4（Topology）已被 3.2 吸收** — mesh topology + nodeModels 併入 `DevicesData`

### 3.3 Ethernet Data Provider ✅
- **Data Provider**：`lib/usp_page/local_network/providers/ethernet_data_provider.dart`
- Fetch：`EthernetInterfaces` + bridge port map（並行）
- Enrichment：`ref.read(devicesDataProvider)` 用於 port ↔ device 對應
- Listener：`ref.listen(devicesDataProvider)` → 重建 `ethernetPortModels`
- 產生：`EthernetData`（`EthernetInterfaces` + `bridgePortMap` + `ethernetPortModels`）
- 消費者：Ethernet Ports Card、Stats Panel、PDF report

### Phase 3 驗證
- [x] WiFi card、Connected Devices card、Ethernet card、Topology card 都獨立運作
- [x] 跨域 enrichment 正常（device → WiFi client、ethernet → device）
- [x] Dashboard state 僅剩 `isAuthenticated`
- [x] `flutter analyze` — 0 errors

---

## Phase 4：Orchestrator + 清理 ✅ 已完成

### 4.1 Dashboard Orchestrator ✅
**新增**：`lib/usp_page/dashboard/orchestrator/dashboard_orchestrator.dart`
- `DashboardOrchestrator` + `DashboardOrchestratorState`（僅 `isAuthenticated`）
- Auth 檢查 + session restore
- 批次初始化 data providers（3 個並發：systemInfo + devices + ethernet）
- SSE bootstrap + deferred subscription 註冊
- `refreshAll()`：invalidate 所有 domain providers + invalidateSelf
- `DashboardLoadingProgress` + `dashboardLoadingProgressProvider`

### 4.2 Dashboard Aggregate Provider — 跳過
- Stats Panel 已直接 watch 各 domain providers，運作良好
- 不需額外 aggregate provider — 避免 over-engineering

### 4.3 刪除 God Notifier ✅
- **已刪除**：`usp_dashboard_notifier.dart` + `usp_dashboard_state.dart`
- **已更新**：`usp_dashboard_view.dart` → watch `dashboardOrchestratorProvider`
- **已更新**：`usp_sliver_dashboard_view.dart` → use orchestrator for PDF guard + refresh
- **已更新**：Retry button 使用 `refreshAll()` 而非 simple invalidate
- **已更新**：`usp_widget_factory.dart` 注釋更新

### Phase 4 驗證
- [x] Dashboard 漸進式載入（loading progress → skeleton → data）
- [x] Pull-to-refresh 對所有 domain 生效（`refreshAll()` invalidates all）
- [x] 專案中不再有任何 `UspDashboardNotifier` / `UspDashboardState` 引用
- [x] `flutter analyze` — 0 errors

---

## Phase 5：檔案結構 — Card 搬到 Feature 旁邊 ✅ 已完成

| 來源（dashboard/views/components/） | 目標 |
|---|---|
| `usp_firewall_overview_card.dart` | `firewall/cards/` ✅ |
| `usp_time_settings_card.dart` | `admin/cards/` ✅ |
| `usp_lan_info_card.dart` | `local_network/cards/` ✅ |
| `usp_dhcp_reservations_card.dart` | `local_network/cards/` ✅ |
| `usp_ethernet_ports_card.dart` | `local_network/cards/` ✅ |
| `usp_network_status_card.dart` | `internet_settings/cards/` ✅ |
| `usp_device_info_card.dart` | `admin/cards/` ✅ |
| `usp_connected_devices_card.dart` | `devices/cards/` ✅ |
| `usp_wifi_status_card.dart` | `wifi_settings/cards/` ✅ |
| `usp_wifi_performance_card.dart` | `wifi_settings/cards/` ✅ |
| `usp_network_topology_card.dart` | `topology/cards/` ✅ |
| `usp_port_forwarding_card.dart` | `port_forwarding/cards/` ✅ |

**留在 dashboard/**：`usp_stats_panel.dart`、`usp_system_status_card.dart`、`usp_traffic_analysis_card.dart`、`usp_device_analytics_card.dart`、`usp_network_health_card.dart`、`card_skeleton.dart`、`usp_info_row.dart`、`usp_status_dot.dart`、`usp_mutation_helper.dart`

### Phase 5 驗證
- [x] `flutter analyze` — 0 errors（737 info，全部既有 lint）
- [x] `_components.dart` barrel 只保留留在 dashboard 的 components
- [x] `usp_widget_factory.dart` 改用 12 個 feature-specific import
- [x] 所有 card 內部 import 無需改動（已使用 absolute `package:` paths）

---

## Phase 6：其餘 USP Page 遷移 ✅ 已完成

> 依 [Playbook](domain-split-playbook.md) 判斷 Type 後執行。

### 6.1 Type A (Form) ✅ 已完成

| 頁面 | 狀態 |
|------|------|
| `usp_page/dmz/` | ✅ FeatureState + Preservable |
| `usp_page/local_network/` | ✅ FeatureState + Preservable |
| `usp_page/internet_settings/` | ✅ FeatureState + Preservable |

### 6.2 Type B (CRUD List) ✅ 已完成

| 頁面 | 狀態 |
|------|------|
| `usp_page/static_routing/` | ✅ FeatureState + diff-based batch save |
| `usp_page/ipv6_port_service/` | ✅ FeatureState + diff-based batch save |
| `usp_page/port_forwarding/` | ✅ Combined notifier (PF + PT), diff-based batch save |
| `usp_page/dhcp/` | ✅ Reservations-only notifier, diff-based batch save |

#### Type B 設計決策

- **Port Forwarding**：單一 combined notifier 管理 forwarding + triggering rules，避免 composite PreservableContract 複雜度
- **DHCP**：page notifier 只管 reservations；clients/server info 仍來自 Layer 1 `dhcpDataProvider`
- **Rule 識別**：Tab 內用 Equatable 物件身份（`indexOf`/`remove`），非 index（因 filtered list index ≠ full list index）
- **Save 後**：invalidate Layer 1 providers 重新 fetch → 更新 dashboard cards

#### Type B 已知問題：Bridge 批次操作

- **BUG-007**：批次 USP Add 操作有兩個獨立問題
  - **Sequential `add()`**：只有第一筆會寫入，後續筆數靜默遺失（即使加 300ms delay）
  - **`addMultiple()`**：資料正確寫入（router 端確認全部建立），但 JS WASM client Promise 永不 resolve（bridge req timeout 128s → UI 卡死）
  - 影響：所有 Type B CRUD 頁面的「一次新增多筆」場景
  - **正確修復方向**：修復 WASM client 的 `addMultiple` response handling — `addMultiple` 是資料正確的路徑
  - **Status**: Open — 300ms delay 已套用至全部 4 個 notifier，但只是防禦性措施（僅第一筆有效）
- **TODO**：調查 WASM client `addMultiple` response 為何不 resolve（可能是 response 格式解析問題）
- **TODO**：codegen 目前只生成單筆 `add()`/`delete()`，未來考慮加入 `addMany()`/`deleteMany()` wrapper

### 6.3 Type C ✅ 已完成（無需遷移）

這 5 個頁面從建立時就是獨立模式，不依賴 God Notifier，各自有獨立 provider 直接消費 codegen。確認符合 Type C 定義（不需要 FeatureState），無需額外遷移。

| 頁面 | Type | 說明 | 狀態 |
|------|------|------|------|
| `usp_page/admin/` | C | atomic 操作（密碼、重開機），唯讀顯示 | ✅ 已獨立 |
| `usp_page/system_log/` | C | 唯讀 | ✅ 已獨立 |
| `usp_page/network_diagnostics/` | C | 使用者觸發操作（Ping/Traceroute via SSE），無編輯狀態 | ✅ 已獨立 |
| `usp_page/instant_privacy/` | C | toggle 模式（MAC filter） | ✅ 已獨立 |
| `usp_page/instant_safety/` | C | toggle 模式（DNS safe browsing） | ✅ 已獨立 |

---

## 關鍵檔案

| 檔案 | 角色 |
|---|---|
| `lib/usp_page/_framework/preservable_notifier_mixin.dart` | 框架 mixin — SSE guard + fetch/save/revert |
| `lib/usp_page/_framework/feature_state.dart` | 框架 base state |
| `lib/usp_page/_framework/preservable.dart` | Dirty tracking wrapper（original/current） |
| `lib/usp_page/_framework/preservable_contract.dart` | Re-export 原始 contract（**不可複製**） |
| `lib/usp/providers/usp_mutation_lock.dart` | 共享 mutation lock（Completer-based） |
| `lib/providers/preservable_notifier_mixin.dart` | 原始框架（不修改，JNAP 頁面使用） |
| `lib/usp_page/dashboard/orchestrator/dashboard_orchestrator.dart` | ✅ Phase 4 — Dashboard Orchestrator（替換 God Notifier） |
| `lib/usp_page/wifi_settings/providers/wifi_data_provider.dart` | ✅ Phase 3.1 — Layer 1（SSE + mutations） |
| `lib/usp_page/devices/providers/devices_data_provider.dart` | ✅ Phase 3.2 — Layer 1（SSE + cross-domain enrichment） |
| `lib/usp_page/local_network/providers/ethernet_data_provider.dart` | ✅ Phase 3.3 — Layer 1（cross-domain enrichment） |
| `lib/usp_page/firewall/providers/usp_firewall_notifier.dart` | ✅ MVP 完成 — Type A 參考實作 |
| `lib/usp_page/firewall/providers/firewall_data_provider.dart` | ✅ MVP 完成 — Layer 1 參考實作（SSE） |
| `lib/usp_page/admin/providers/time_data_provider.dart` | ✅ Phase 2 — Layer 1（無 SSE） |
| `lib/usp_page/local_network/providers/lan_data_provider.dart` | ✅ Phase 2 — Layer 1（SSE） |
| `lib/usp_page/local_network/providers/dhcp_data_provider.dart` | ✅ Phase 2 — Layer 1（SSE + cross-domain） |
| `lib/usp_page/port_forwarding/providers/port_forwarding_data_provider.dart` | ✅ Phase 2 — Layer 1（SSE） |
| `lib/usp_page/port_forwarding/providers/port_triggering_data_provider.dart` | ✅ Phase 2 — Layer 1（SSE） |
| `lib/usp_page/internet_settings/providers/wan_data_provider.dart` | ✅ Phase 2 — Layer 1（SSE + mutation） |
| `lib/usp_page/admin/providers/system_info_data_provider.dart` | ✅ Phase 2 — Layer 1（無 SSE） |
| `lib/usp_page/dashboard/views/components/usp_mutation_helper.dart` | ✅ `uspMutationLoadingProvider` + mutation helper |
| `lib/usp_page/dashboard/factories/usp_widget_factory.dart` | Card 註冊表 — 每個 phase 更新 imports |
| `lib/route/route_usp_dashboard.dart` | Route 設定 — 加入 dirty checks |

## 驗證方式

每個 phase 完成後：
1. `flutter analyze` — 無錯誤
2. `./run_tests.sh` — 所有 functional tests 通過
3. 手動：開啟 dashboard → 所有可見 cards 正確渲染
4. 手動：導航至已遷移的 feature page → 編輯 → 導航離開 → dirty guard dialog 出現
5. 手動：觸發 SSE 事件 → 受影響的 card 更新，dirty page 不受影響
6. 確認 `lib/page/`（JNAP 頁面）完全不受影響

## 進度總覽

| Phase | 狀態 | 說明 |
|-------|------|------|
| 0 — 框架增強 | ✅ 已完成 | `_framework/` + SSE guard + mutation lock |
| 1 — Firewall MVP | ✅ 已完成 | 完整垂直切片，驗證 3-layer 模式 |
| 2 — 獨立簡單 Domain | ✅ 已完成 | Time / LAN / DHCP / Ports / WAN / SysInfo + mutation loading 提取 |
| 3 — 交叉依賴 Domain | ✅ 已完成 | WiFi / Devices / Ethernet（Topology 併入 Devices） |
| 4 — Orchestrator | ✅ 已完成 | 替換 God Notifier，已刪除 |
| 5 — 檔案結構 | ✅ 已完成 | Card 搬到 feature 旁邊（12 cards → 8 feature dirs） |
| 6 — 其餘 USP Page | ✅ 已完成 | Type A×3 ✅ + Type B×4 ✅（帶 BUG-007）+ Type C×5 ✅（無需遷移） |
