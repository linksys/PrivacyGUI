# Phase 0 + Phase 1 MVP: Firewall Domain Split

> Branch: `refactor/dashboard-domain-split`
> Date: 2026-03-17

## 目標

將 Firewall domain 從 God Notifier (`UspDashboardNotifier`, 1119 行) 中拆出，作為第一個完整垂直切片（end-to-end vertical slice），驗證 3-layer 架構模式。

---

## 架構概覽

```
Layer 1: FirewallDataProvider (NOT autoDispose)
         ├── 持有原始 codegen 資料 (FirewallChainRules + Dmz)
         ├── SSE invalidation → debounce 500ms → ref.invalidateSelf()
         └── Dashboard card 直接 ref.watch()

Layer 2: UspFirewallNotifier (AutoDispose)
         ├── ref.read(firewallDataProvider.future) — clone 不 watch
         ├── FeatureState<FirewallSettings, FirewallStatus> + Preservable
         ├── PreservableAutoDisposeNotifierMixin (fetch/save/revert)
         ├── SSE dirty guard: !isDirty → re-fetch; isDirty → 忽略
         └── Route dirty check 透過 preservableUspFirewallProvider

View:    UspFirewallView (ConsumerWidget)
         ├── ref.watch(uspFirewallProvider) — 同步 state
         ├── UiKitBottomBarConfig — isDirty 時顯示 Save/Cancel
         └── UiKitPageView.withSliver 框架整合
```

---

## Phase 0: 框架增強

### 0.1 複製框架檔案到 `lib/usp_page/_framework/`

隔離原因：`lib/providers/` 下的框架為 JNAP 頁面使用，在 `_framework/` 副本上修改不影響既有頁面。

| 檔案 | 來源 | 說明 |
|------|------|------|
| `_framework/preservable.dart` | `lib/providers/preservable.dart` | Dirty-checking wrapper (`original`/`current`) |
| `_framework/feature_state.dart` | `lib/providers/feature_state.dart` | 抽象基底 `FeatureState<TSettings, TStatus>` |
| `_framework/preservable_notifier_mixin.dart` | `lib/providers/preservable_notifier_mixin.dart` | Template method mixin + SSE guard |
| `_framework/preservable_contract.dart` | Re-export | `export 'package:privacy_gui/providers/preservable_contract.dart'` |

**重要決策 — `preservable_contract.dart` 必須 re-export 而非複製**：
Route 系統 (`LinksysRoute`) 期望 `PreservableContract` 是 `lib/providers/` 的型別。如果複製成獨立類別，會產生型別不相容錯誤。因此 `_framework/preservable_contract.dart` 改為 re-export 原始檔案，確保整個 app 使用同一個 `PreservableContract` 型別。

### 0.2 為 PreservableNotifierMixin 加入 SSE dirty guard

在兩個 mixin 變體（`PreservableNotifierMixin` 和 `PreservableAutoDisposeNotifierMixin`）各加入：

```dart
/// Called when an SSE event indicates external data has changed.
/// If the user has unsaved edits (isDirty), the update is ignored
/// to avoid clobbering their work. Otherwise, re-fetches fresh data.
void onSseInvalidation() {
  if (!isDirty()) {
    fetch(forceRemote: true);
  }
}
```

### 0.3 建立共享 USP mutation lock

`lib/usp/providers/usp_mutation_lock.dart`

WASM USP client 不支援併發呼叫，需要共享鎖確保所有 domain notifier 的 mutation 順序執行。

設計選擇 — **wait-based queuing**（而非原本 dashboard notifier 的 throw-on-contention）：

```dart
class UspMutationLock {
  Completer<void>? _completer;
  bool get isLocked => _completer != null && !_completer!.isCompleted;

  Future<T> withLock<T>(Future<T> Function() action) async {
    while (isLocked) {
      await _completer!.future;  // 等待前一個 mutation 完成
    }
    _completer = Completer<void>();
    try {
      return await action();
    } finally {
      _completer!.complete();
    }
  }
}
```

---

## Phase 1: Firewall Domain — 完整垂直切片

### 1.1 Firewall Data Provider (Layer 1)

`lib/usp_page/firewall/providers/firewall_data_provider.dart`

```dart
// 資料模型 — 持有原始 codegen 資料
class FirewallData extends Equatable {
  final FirewallChainRules chainRules;
  final Dmz dmzEntries;
}

// Provider — NOT autoDispose，dashboard card 生命週期內持續存在
final firewallDataProvider =
    AsyncNotifierProvider<FirewallDataNotifier, FirewallData>(...);

// Notifier — SSE debounce + 並發 fetch
class FirewallDataNotifier extends AsyncNotifier<FirewallData> {
  Timer? _debounce;

  Future<FirewallData> build() async {
    ref.listen(sseInvalidationProvider, (prev, next) {
      final domain = next.valueOrNull;
      if (domain == InvalidationDomain.firewallRules ||
          domain == InvalidationDomain.dmz) {
        _debouncedInvalidate();  // 500ms debounce → invalidateSelf
      }
    });
    ref.onDispose(() => _debounce?.cancel());
    return _fetch();
  }

  Future<FirewallData> _fetch() async {
    final usp = ref.read(uspServiceProvider)!;
    final results = await Future.wait([
      FirewallChainRules.fetch(usp),
      Dmz.fetch(usp),
    ]);
    return FirewallData(
      chainRules: results[0] as FirewallChainRules,
      dmzEntries: results[1] as Dmz,
    );
  }
}
```

### 1.2 Firewall Models (FeatureState 拆分)

| 檔案 | 角色 |
|------|------|
| `models/firewall_settings.dart` | 可編輯設定：`FirewallUIModel` + `Map<String, FirewallChainRule> ruleMap` |
| `models/firewall_status.dart` | 瞬態狀態：`isLoading`, `isSaving`, `errorMessage` |
| `models/firewall_feature_state.dart` | 組合：`FeatureState<FirewallSettings, FirewallStatus>` |

FeatureState 的核心分離概念：

```
FirewallFeatureState
├── settings: Preservable<FirewallSettings>   ← 可編輯，追蹤 dirty
│   ├── .original: FirewallSettings           ← fetch 後的初始值
│   └── .current: FirewallSettings            ← 使用者編輯後的值
└── status: FirewallStatus                    ← 唯讀，不納入 dirty 比對
```

### 1.3 Firewall Page Notifier (Layer 2)

`lib/usp_page/firewall/providers/usp_firewall_notifier.dart`

**從**：`AutoDisposeAsyncNotifier<UspFirewallState>` + ad-hoc `_original`/`_pending`

**改為**：`AutoDisposeNotifier<FirewallFeatureState>` + `PreservableAutoDisposeNotifierMixin`

```dart
class UspFirewallNotifier extends AutoDisposeNotifier<FirewallFeatureState>
    with PreservableAutoDisposeNotifierMixin<
        FirewallSettings, FirewallStatus, FirewallFeatureState> {

  @override
  FirewallFeatureState build() {
    // 監聽 data provider 的 SSE 更新
    ref.listen(firewallDataProvider, (_, next) {
      if (next.hasValue) onSseInvalidation();  // 框架提供的 dirty guard
    });
    // 同步 build + 非同步 fetch
    Future.microtask(() => fetch());
    return FirewallFeatureState.initial();
  }

  @override
  Future<(FirewallSettings?, FirewallStatus?)> performFetch({...}) async {
    final data = await ref.read(firewallDataProvider.future);  // clone 不 watch
    final ruleMap = _svc.parseFirewallRules(data.chainRules);
    final uiModel = _svc.buildUIModel(rules: ruleMap);
    return (
      FirewallSettings(model: uiModel, ruleMap: ruleMap),
      const FirewallStatus(isLoading: false),
    );
  }

  @override
  Future<void> performSave() async {
    state = state.copyWith(status: state.status.copyWith(isSaving: true));
    await ref.read(uspMutationLockProvider).withLock(() async {
      final updates = _svc.buildSetPayload(
        original: state.settings.original.model,
        pending: state.settings.current.model,
        rules: state.settings.current.ruleMap,
      );
      await FirewallChainRules.updateMany(ref.read(uspServiceProvider)!, updates);
    });
    ref.invalidate(firewallDataProvider);  // 強制 data provider re-fetch
  }

  /// UI mutation（同步 — 無網路呼叫）
  void updateSetting(FirewallUIModel Function(FirewallUIModel) updater) {
    final current = state.settings.current;
    state = state.copyWith(
      settings: state.settings.update(
        current.copyWith(model: updater(current.model)),
      ),
    );
  }
}

/// Route dirty check 用
final preservableUspFirewallProvider = AutoDisposeProvider<
    PreservableContract<FirewallSettings, FirewallStatus>>(
  (ref) => ref.watch(uspFirewallProvider.notifier),
);
```

### 1.4 Firewall Dashboard Card (改用 Layer 1)

`lib/usp_page/dashboard/views/components/usp_firewall_overview_card.dart`

```dart
// 之前
final dashState = ref.watch(uspDashboardProvider).valueOrNull;
// firewallRules = dashState?.firewallRules
// dmzEntries = dashState?.dmzEntries

// 之後
final firewallData = ref.watch(firewallDataProvider).valueOrNull;
// firewallRules = firewallData?.chainRules.items
// dmzEntries = firewallData?.dmzEntries.items
final dashState = ref.watch(uspDashboardProvider).valueOrNull;
// portForwarding 暫時仍從 dashboard provider 讀取（Phase 2 再遷移）
```

### 1.5 從 Dashboard Notifier 移除 Firewall

**`usp_dashboard_state.dart`**：移除 `firewallRules`、`dmzEntries` 欄位 + `copyWith` + `props`

**`usp_dashboard_notifier.dart`**：
- 移除 Batch 6（`FirewallChainRules.fetch` + `Dmz.fetch`）
- SSE invalidation handler 改為 no-op：
  ```dart
  case InvalidationDomain.firewallRules:
  case InvalidationDomain.dmz:
    // Handled by firewallDataProvider — no longer in dashboard state.
    break;
  ```

**`usp_sliver_dashboard_view.dart`**：PDF report 改從 `firewallDataProvider` 讀取

### 1.6 Route Dirty Check

`lib/route/route_usp_dashboard.dart`：

```dart
LinksysRoute(
  name: RouteNamed.uspFirewall,
  path: RouteNamed.uspFirewall,
  builder: (context, state) => const UspFirewallView(),
  enableDirtyCheck: true,
  preservableProvider: preservableUspFirewallProvider,
),
```

### 1.7 Firewall View — UiKitBottomBarConfig

`lib/usp_page/firewall/views/usp_firewall_view.dart`

**從**：`_buildContent` 中的 inline save button

```dart
// 移除
if (state.isDirty) ...[
  AppGap.xl(),
  SizedBox(
    width: double.infinity,
    child: AppButton.primary(
      label: 'Save',
      onTap: disabled ? null : () => _onSave(context, ref),
    ),
  ),
],
```

**改為**：`UiKitPageView.withSliver` 的 `bottomBar` 參數

```dart
return UiKitPageView.withSliver(
  scrollable: true,
  title: 'Firewall',
  bottomBar: _buildBottomBar(context, ref, state),  // ← 新增
  // ...
);

UiKitBottomBarConfig? _buildBottomBar(
  BuildContext context, WidgetRef ref, FirewallFeatureState state,
) {
  if (!state.isDirty) return null;
  return UiKitBottomBarConfig(
    positiveLabel: 'Save',
    isPositiveEnabled: !state.status.isSaving,
    onPositiveTap: () => _onSave(context, ref),
    onNegativeTap: () => ref.read(uspFirewallProvider.notifier).revert(),
  );
}
```

---

## 新增/修改檔案清單

### 新增檔案

| 檔案 | 說明 |
|------|------|
| `lib/usp_page/_framework/preservable.dart` | Dirty-checking wrapper 副本 |
| `lib/usp_page/_framework/feature_state.dart` | FeatureState 基底類別副本 |
| `lib/usp_page/_framework/preservable_notifier_mixin.dart` | Mixin 副本 + SSE guard |
| `lib/usp_page/_framework/preservable_contract.dart` | Re-export 原始 contract |
| `lib/usp/providers/usp_mutation_lock.dart` | 共享 mutex |
| `lib/usp_page/firewall/providers/firewall_data_provider.dart` | Layer 1 data provider |
| `lib/usp_page/firewall/models/firewall_settings.dart` | 可編輯設定 wrapper |
| `lib/usp_page/firewall/models/firewall_status.dart` | 瞬態狀態 |
| `lib/usp_page/firewall/models/firewall_feature_state.dart` | 組合 FeatureState |

### 修改檔案

| 檔案 | 變更內容 |
|------|----------|
| `lib/usp_page/firewall/providers/usp_firewall_notifier.dart` | 重寫為 FeatureState + Preservable 模式 |
| `lib/usp_page/firewall/views/usp_firewall_view.dart` | 同步 state + UiKitBottomBarConfig bottom bar |
| `lib/usp_page/dashboard/providers/usp_dashboard_state.dart` | 移除 firewall 欄位 |
| `lib/usp_page/dashboard/providers/usp_dashboard_notifier.dart` | 移除 firewall fetch + SSE |
| `lib/usp_page/dashboard/views/components/usp_firewall_overview_card.dart` | 改用 firewallDataProvider |
| `lib/usp_page/dashboard/views/usp_sliver_dashboard_view.dart` | PDF report 改用 firewallDataProvider |
| `lib/route/route_usp_dashboard.dart` | 加入 dirty check 設定 |
| `lib/route/router_provider.dart` | 加入 firewall notifier import |

---

## 解決的問題

### 1. PreservableContract 型別不相容
**問題**：`_framework/PreservableContract` 和 `lib/providers/PreservableContract` 是不同型別，`LinksysRoute` 期望後者。
**解法**：`_framework/preservable_contract.dart` 改為 re-export 原始檔案。

### 2. Dashboard state 殘留引用
**問題**：移除 `firewallRules`/`dmzEntries` 後，`usp_sliver_dashboard_view.dart` 的 PDF report 仍引用。
**解法**：改為 `ref.read(firewallDataProvider).valueOrNull`，null 時使用 `const FirewallUIModel()` 和 `const DmzUIModel.disabled()` 作為 fallback。

### 3. Mutation lock 設計
**問題**：原本各 notifier 私有的 `_mutating` flag 在 throw-on-contention 時會丟失使用者操作。
**解法**：共享 `UspMutationLock` 使用 Completer-based wait queue，後到的 mutation 等待而非丟棄。

---

## 資料流圖

```
┌─────────────────────────────────────────────────┐
│                    SSE Event                     │
│          (firewallRules / dmz domain)            │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│         FirewallDataNotifier (Layer 1)           │
│  debounce 500ms → ref.invalidateSelf() → build  │
│  Future.wait([ChainRules.fetch, Dmz.fetch])      │
└────────┬───────────────────────┬────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐   ┌─────────────────────────┐
│ Dashboard Card   │   │ UspFirewallNotifier (L2) │
│ ref.watch()      │   │ ref.listen() →           │
│ → 即時更新 UI     │   │   onSseInvalidation()   │
└─────────────────┘   │   isDirty? → skip         │
                      │   !isDirty? → fetch()     │
                      └────────┬──────────────────┘
                               │
                               ▼
                      ┌─────────────────┐
                      │ UspFirewallView  │
                      │ ref.watch()      │
                      │ → Bottom Bar     │
                      │ → Toggle Rows    │
                      └─────────────────┘
```

---

## 驗證狀態

- [x] `flutter analyze` — 0 errors
- [x] Firewall card 改用 `firewallDataProvider`，獨立於 dashboard 載入
- [x] Firewall page 使用 FeatureState + Preservable 框架
- [x] SSE dirty guard：`onSseInvalidation()` 由框架提供
- [x] Route dirty check：導航離開未儲存頁面時顯示確認 dialog
- [x] Bottom bar 使用 `UiKitBottomBarConfig` 框架（Save + Cancel/Revert）
- [x] Dashboard notifier 不再 fetch/管理 firewall 資料
- [x] 原始 `lib/providers/` 框架檔案未修改（JNAP 頁面不受影響）

---

## 後續 Phase（尚未開始）

| Phase | Domain | 類型 |
|-------|--------|------|
| 2.1 | Time Settings | FeatureState（有編輯表單） |
| 2.2 | LAN Info | 唯讀 card（不需 FeatureState） |
| 2.3 | DHCP | CRUD 列表（atomic mutation） |
| 2.4 | Port Forwarding + Triggering | CRUD 列表 |
| 2.5 | WAN Status | 唯讀 + renewLease mutation |
| 2.6 | System Info | 唯讀 card |
| 3.x | WiFi / Devices / Ethernet / Topology | 有跨域依賴 |
| 4 | Orchestrator + Aggregate | 替換 God Notifier |
| 5 | Card 搬到 feature 旁邊 | 檔案結構調整 |
| 6 | 其餘 USP page 遷移 | DMZ / Local Network / Internet Settings 等 |
