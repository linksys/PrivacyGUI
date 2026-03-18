# Domain Split Playbook

> 從 `UspDashboardNotifier` 拆出 domain 的標準化流程。
> 每個 domain 依據頁面類型選擇對應模板，按步驟執行。

---

## 第一步：判斷頁面類型

```
頁面有編輯表單（欄位 or 列表）+ Save/Cancel？
├── 是 → 編輯的是列表（add/edit/delete items）？
│         ├── 是 → Type B: FeatureState — CRUD List
│         │         累積本地變更 → batch save（addMultiple + set + delete）
│         │         範例：Port Forwarding、DHCP Reservations、
│         │                Static Routing、IPv6 Port Service、Port Triggering
│         └── 否 → Type A: FeatureState — Form
│                   表單欄位編輯 → save（set）
│                   範例：Firewall、WiFi Settings、
│                          Internet Settings、DMZ、Local Network
└── 否 → Type C: Read-Only / Toggle / Dialog Atomic
          即時操作或純顯示，不需 Preservable
          範例：System Info、LAN Info、WAN Status、Time Settings、
                 Admin、System Log、Instant Privacy
```

---

## 共用步驟（所有類型）

### Step 1: 建立 Data Provider (Layer 1)

**檔案**：`lib/usp_page/<domain>/providers/<domain>_data_provider.dart`

```dart
import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
// import codegen types...

// ── Data Model ──
class {Domain}Data extends Equatable {
  final {CodegenType1} field1;
  final {CodegenType2} field2;
  // ...

  const {Domain}Data({required this.field1, required this.field2});
  const {Domain}Data.empty() : field1 = const ..., field2 = const ...;

  @override
  List<Object?> get props => [field1, field2];
}

// ── Provider ──
final {domain}DataProvider =
    AsyncNotifierProvider<{Domain}DataNotifier, {Domain}Data>(
  {Domain}DataNotifier.new,
);

// ── Notifier (NOT autoDispose) ──
class {Domain}DataNotifier extends AsyncNotifier<{Domain}Data> {
  Timer? _debounce;

  @override
  Future<{Domain}Data> build() async {
    // SSE: 監聽相關 domain 變更
    ref.listen(sseInvalidationProvider, (prev, next) {
      final domain = next.valueOrNull;
      if (domain == InvalidationDomain.{xxx} ||
          domain == InvalidationDomain.{yyy}) {
        _debouncedInvalidate();
      }
    });
    ref.onDispose(() => _debounce?.cancel());
    return _fetch();
  }

  Future<{Domain}Data> _fetch() async {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');

    final results = await Future.wait([
      {CodegenType1}.fetch(usp),
      {CodegenType2}.fetch(usp),
    ]);

    final data = {Domain}Data(
      field1: results[0] as {CodegenType1},
      field2: results[1] as {CodegenType2},
    );

    logger.d('[USP][{Domain}Data] Fetched — ...');
    return data;
  }

  void _debouncedInvalidate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.invalidateSelf();
    });
  }
}
```

**關鍵規則**：
- `AsyncNotifier`（NOT `AsyncNotifierProvider.autoDispose`）— dashboard card 生命週期內持續存在
- SSE debounce 500ms 避免短時間大量 invalidation
- `ref.onDispose()` 清理 timer
- 無 SSE 需求的 domain（如 Time Settings）可省略 `ref.listen`

### Step 2: 更新 Dashboard Card

**檔案**：`lib/usp_page/dashboard/views/components/usp_{domain}_card.dart`

```dart
// 之前
final dashState = ref.watch(uspDashboardProvider).valueOrNull;
final data = dashState?.{domainField};

// 之後
final domainData = ref.watch({domain}DataProvider).valueOrNull;
if (domainData == null) return const SizedBox.shrink(); // 或 skeleton
```

### Step 3: 從 Dashboard Notifier 移除

**`usp_dashboard_state.dart`**：
- 移除相關欄位（raw data + UI models）
- 更新 `copyWith` + `props`

**`usp_dashboard_notifier.dart`**：
- 移除 fetch（從 `_fetchBatchN` 中移除相關呼叫）
- 移除 state 賦值
- SSE handler 改為 no-op：
  ```dart
  case InvalidationDomain.{xxx}:
    // Handled by {domain}DataProvider.
    break;
  ```
- 移除相關 mutation 方法

**`usp_sliver_dashboard_view.dart`**（如有 PDF report 等跨域引用）：
- 改為 `ref.read({domain}DataProvider).valueOrNull`
- null 時使用合理的 fallback（如 `const {UIModel}.empty()`）

### Step 4: 驗證

```bash
flutter analyze   # 0 errors
```

- [ ] Dashboard card 獨立載入
- [ ] SSE 更新正確觸發 card 刷新
- [ ] 其他 cards 不受影響

---

## Type A: FeatureState（edit form + save/cancel）

> 適用於有編輯表單、需要 dirty check、Save/Cancel 操作的頁面。

### A.1 建立 Models

**`models/{domain}_settings.dart`** — 可編輯設定

```dart
import 'package:equatable/equatable.dart';

class {Domain}Settings extends Equatable {
  final {UIModel} model;
  // 如需 save 時的額外資料（如 ruleMap），一併放入

  const {Domain}Settings({required this.model});
  const {Domain}Settings.empty() : model = const {UIModel}();

  {Domain}Settings copyWith({{UIModel}? model}) {
    return {Domain}Settings(model: model ?? this.model);
  }

  @override
  List<Object?> get props => [model];
}
```

**`models/{domain}_status.dart`** — 瞬態狀態

```dart
import 'package:equatable/equatable.dart';

class {Domain}Status extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const {Domain}Status({
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
  });

  {Domain}Status copyWith({bool? isLoading, bool? isSaving, String? errorMessage}) {
    return {Domain}Status(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, isSaving, errorMessage];
}
```

**`models/{domain}_feature_state.dart`** — 組合

```dart
import 'package:privacy_gui/usp_page/_framework/feature_state.dart';
import 'package:privacy_gui/usp_page/_framework/preservable.dart';

class {Domain}FeatureState extends FeatureState<{Domain}Settings, {Domain}Status> {
  const {Domain}FeatureState({required super.settings, required super.status});

  factory {Domain}FeatureState.initial() {
    return {Domain}FeatureState(
      settings: Preservable(
        original: {Domain}Settings.empty(),
        current: {Domain}Settings.empty(),
      ),
      status: const {Domain}Status(isLoading: true),
    );
  }

  @override
  {Domain}FeatureState copyWith({
    Preservable<{Domain}Settings>? settings,
    {Domain}Status? status,
  }) {
    return {Domain}FeatureState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() => {};
}
```

### A.2 建立 Page Notifier (Layer 2)

**`providers/usp_{domain}_notifier.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp_page/_framework/preservable_contract.dart';
import 'package:privacy_gui/usp_page/_framework/preservable_notifier_mixin.dart';

// ── Providers ──

final usp{Domain}Provider =
    AutoDisposeNotifierProvider<Usp{Domain}Notifier, {Domain}FeatureState>(
  Usp{Domain}Notifier.new,
);

final preservableUsp{Domain}Provider = AutoDisposeProvider<
    PreservableContract<{Domain}Settings, {Domain}Status>>(
  (ref) => ref.watch(usp{Domain}Provider.notifier),
);

// ── Notifier ──

class Usp{Domain}Notifier extends AutoDisposeNotifier<{Domain}FeatureState>
    with PreservableAutoDisposeNotifierMixin<
        {Domain}Settings, {Domain}Status, {Domain}FeatureState> {

  @override
  {Domain}FeatureState build() {
    // 監聽 data provider — SSE dirty guard
    ref.listen({domain}DataProvider, (_, next) {
      if (next.hasValue) onSseInvalidation();
    });
    Future.microtask(() => fetch());
    return {Domain}FeatureState.initial();
  }

  @override
  Future<({Domain}Settings?, {Domain}Status?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    try {
      final data = await ref.read({domain}DataProvider.future);
      // 轉換 codegen data → UI model
      final model = _buildUIModel(data);
      return (
        {Domain}Settings(model: model),
        const {Domain}Status(isLoading: false),
      );
    } catch (e) {
      return (null, {Domain}Status(isLoading: false, errorMessage: '$e'));
    }
  }

  @override
  Future<void> performSave() async {
    state = state.copyWith(
      status: state.status.copyWith(isSaving: true),
    );
    try {
      final usp = ref.read(uspServiceProvider)!;
      await ref.read(uspMutationLockProvider).withLock(() async {
        // 建立 SET payload + 呼叫 codegen save/update
      });
      ref.invalidate({domain}DataProvider); // 強制 data provider re-fetch
    } catch (e) {
      state = state.copyWith(
        status: state.status.copyWith(isSaving: false),
      );
      rethrow;
    }
  }

  /// 同步 UI mutation（無網路呼叫）
  void updateSetting({UIModel} Function({UIModel}) updater) {
    final current = state.settings.current;
    state = state.copyWith(
      settings: state.settings.update(
        current.copyWith(model: updater(current.model)),
      ),
    );
  }
}
```

### A.3 View — UiKitPageView + BottomBar

```dart
class Usp{Domain}View extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usp{Domain}Provider);
    final status = state.status;

    return UiKitPageView.withSliver(
      scrollable: true,
      title: '{Domain}',
      bottomBar: _buildBottomBar(context, ref, state),
      onRefresh: () => ref.read(usp{Domain}Provider.notifier).fetch(forceRemote: true),
      child: (childContext, constraints) {
        if (status.isLoading) return const Center(child: AppLoader());
        if (status.errorMessage != null) return _buildError(context, ref);
        return _buildContent(context, ref, state);
      },
    );
  }

  UiKitBottomBarConfig? _buildBottomBar(
    BuildContext context, WidgetRef ref, {Domain}FeatureState state,
  ) {
    if (!state.isDirty) return null;
    return UiKitBottomBarConfig(
      positiveLabel: 'Save',
      isPositiveEnabled: !state.status.isSaving,
      onPositiveTap: () => _onSave(context, ref),
      onNegativeTap: () => ref.read(usp{Domain}Provider.notifier).revert(),
    );
  }

  Future<void> _onSave(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(usp{Domain}Provider.notifier).save();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('{Domain} settings saved')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }
}
```

### A.4 Route Dirty Check

```dart
// route_usp_dashboard.dart
LinksysRoute(
  name: RouteNamed.usp{Domain},
  path: RouteNamed.usp{Domain},
  builder: (context, state) => const Usp{Domain}View(),
  enableDirtyCheck: true,
  preservableProvider: preservableUsp{Domain}Provider,
),
```

```dart
// router_provider.dart — 加入 import
import 'package:privacy_gui/usp_page/{domain}/providers/usp_{domain}_notifier.dart';
```

### A 類型檢查清單

- [ ] `{Domain}Data` (Layer 1) — codegen 資料 + SSE
- [ ] `{Domain}Settings` — 可編輯部分（Equatable）
- [ ] `{Domain}Status` — 瞬態部分
- [ ] `{Domain}FeatureState` — 組合 + `initial()` factory
- [ ] `Usp{Domain}Notifier` — `performFetch` + `performSave` + `updateSetting`
- [ ] `preservableUsp{Domain}Provider` — route dirty check 用
- [ ] View — `UiKitBottomBarConfig` bottom bar
- [ ] Route — `enableDirtyCheck: true`
- [ ] Dashboard card — 改用 `{domain}DataProvider`
- [ ] Dashboard notifier — 移除相關 fetch / state / SSE / mutations
- [ ] `flutter analyze` — 0 errors

---

## Type B: FeatureState — CRUD List（batch save）

> 適用於 add/edit/delete 操作的列表頁面。使用 Preservable 追蹤 original vs current，
> 所有變更累積在本地，Save 時 diff → batch 送出（`addMultiple` + `set` + `delete`）。
>
> **JNAP 參考實作**：`lib/page/advanced_settings/firewall/providers/ipv6_port_service_list_provider.dart`

### B.1 建立 Models

**`models/{domain}_item_ui.dart`** — 列表項目 UI 模型

```dart
import 'package:equatable/equatable.dart';

class {Item}UI extends Equatable {
  final String? instancePath;  // null = 新增的項目（尚未送出）
  final bool enabled;
  final String name;
  // ... 其他欄位 ...

  const {Item}UI({
    this.instancePath,
    this.enabled = true,
    required this.name,
  });

  {Item}UI copyWith({bool? enabled, String? name}) {
    return {Item}UI(
      instancePath: instancePath,
      enabled: enabled ?? this.enabled,
      name: name ?? this.name,
    );
  }

  @override
  List<Object?> get props => [instancePath, enabled, name];
}

/// Preservable 的 wrapper — 包裝 List<{Item}UI>
class {Item}UIList extends Equatable {
  final List<{Item}UI> rules;
  const {Item}UIList({required this.rules});
  const {Item}UIList.empty() : rules = const [];

  {Item}UIList copyWith({List<{Item}UI>? rules}) {
    return {Item}UIList(rules: rules ?? this.rules);
  }

  @override
  List<Object?> get props => [rules];
}
```

**`models/{domain}_list_status.dart`** — 瞬態狀態

```dart
class {Domain}ListStatus extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final int maxItems;
  final String? errorMessage;

  const {Domain}ListStatus({
    this.isLoading = true,
    this.isSaving = false,
    this.maxItems = 50,
    this.errorMessage,
  });

  // copyWith, props...
}
```

**`models/{domain}_list_feature_state.dart`** — 組合（同 Type A 模式）

```dart
class {Domain}ListFeatureState
    extends FeatureState<{Item}UIList, {Domain}ListStatus> {
  const {Domain}ListFeatureState({required super.settings, required super.status});

  factory {Domain}ListFeatureState.initial() {
    return {Domain}ListFeatureState(
      settings: Preservable(
        original: {Item}UIList.empty(),
        current: {Item}UIList.empty(),
      ),
      status: const {Domain}ListStatus(isLoading: true),
    );
  }

  // copyWith...
}
```

### B.2 建立 Page Notifier (Layer 2)

```dart
final usp{Domain}ListProvider =
    AutoDisposeNotifierProvider<Usp{Domain}ListNotifier, {Domain}ListFeatureState>(
  Usp{Domain}ListNotifier.new,
);

final preservableUsp{Domain}ListProvider = AutoDisposeProvider<PreservableContract>(
  (ref) => ref.watch(usp{Domain}ListProvider.notifier),
);

class Usp{Domain}ListNotifier extends AutoDisposeNotifier<{Domain}ListFeatureState>
    with PreservableAutoDisposeNotifierMixin<
        {Item}UIList, {Domain}ListStatus, {Domain}ListFeatureState> {

  @override
  {Domain}ListFeatureState build() {
    ref.listen({domain}DataProvider, (_, next) {
      if (next.hasValue) onSseInvalidation();  // dirty guard
    });
    Future.microtask(() => fetch());
    return {Domain}ListFeatureState.initial();
  }

  @override
  Future<({Item}UIList?, {Domain}ListStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    final data = await ref.read({domain}DataProvider.future);
    final uiList = _buildUIList(data);  // codegen → UI model 轉換
    return (uiList, const {Domain}ListStatus(isLoading: false));
  }

  // ── 本地 mutations（只改 current，不呼叫 API）──

  void addItem({Item}UI item) {
    final current = state.settings.current;
    state = state.copyWith(
      settings: state.settings.update(
        current.copyWith(rules: [...current.rules, item]),
      ),
    );
  }

  void editItem(int index, {Item}UI newItem) {
    final updatedRules = [...state.settings.current.rules];
    updatedRules[index] = newItem;
    state = state.copyWith(
      settings: state.settings.update(
        state.settings.current.copyWith(rules: updatedRules),
      ),
    );
  }

  void deleteItem({Item}UI item) {
    final updatedRules = state.settings.current.rules
        .where((r) => r != item)
        .toList();
    state = state.copyWith(
      settings: state.settings.update(
        state.settings.current.copyWith(rules: updatedRules),
      ),
    );
  }

  // ── Batch Save（diff original vs current → addMultiple + set + delete）──

  @override
  Future<void> performSave() async {
    state = state.copyWith(
      status: state.status.copyWith(isSaving: true),
    );
    try {
      final usp = ref.read(uspServiceProvider)!;
      final original = state.settings.original.rules;
      final current = state.settings.current.rules;

      await ref.read(uspMutationLockProvider).withLock(() async {
        // 1. 找出新增項目（沒有 instancePath = 本地新增）
        final toAdd = current.where((c) => c.instancePath == null).toList();

        // 2. 找出刪除項目（在 original 但不在 current）
        final currentPaths = current
            .where((c) => c.instancePath != null)
            .map((c) => c.instancePath!)
            .toSet();
        final toDelete = original
            .where((o) => o.instancePath != null &&
                !currentPaths.contains(o.instancePath))
            .toList();

        // 3. 找出修改項目（path 相同但內容不同）
        final toUpdate = current.where((c) {
          if (c.instancePath == null) return false;
          final orig = original.firstWhere(
            (o) => o.instancePath == c.instancePath,
            orElse: () => c,
          );
          return orig != c;
        }).toList();

        // 執行 batch operations
        if (toAdd.isNotEmpty) {
          await usp.addMultiple(
            toAdd.map((item) => _buildAddPayload(item)).toList(),
          );
        }
        if (toUpdate.isNotEmpty) {
          final setParams = <String, dynamic>{};
          for (final item in toUpdate) {
            setParams.addAll(_buildSetPayload(item));
          }
          await usp.set(setParams);
        }
        for (final item in toDelete) {
          await usp.delete(item.instancePath!);
        }
      });

      ref.invalidate({domain}DataProvider);  // re-fetch → original = current
    } catch (e) {
      state = state.copyWith(
        status: state.status.copyWith(isSaving: false),
      );
      rethrow;
    }
  }
}
```

**關鍵差異（vs Type A Form）**：
- Settings type 是 `{Item}UIList`（List wrapper）而非結構化欄位
- Mutations 是 `addItem` / `editItem` / `deleteItem` — 操作 list
- `performSave` 是 **diff-based**：比較 original vs current → 產生 `addMultiple` + `set` + `delete`
- 新增項目用 `instancePath == null` 辨識（尚未有 device 指派的路徑）
- `addMultiple`（`UspService.addMultiple`）— 單一 USP call 新增多筆

**共通點（同 Type A）**：
- 使用 `FeatureState` + `Preservable` + `PreservableAutoDisposeNotifierMixin`
- `isDirty()` → `original.rules != current.rules`
- SSE dirty guard → 編輯中不被覆蓋
- Route dirty check → 離開頁面前警告
- Save / Revert → batch commit / 還原至 original
- `UiKitBottomBarConfig`（Save + Cancel）

### B.3 View — 同 Type A（有 BottomBar）

```dart
class Usp{Domain}ListView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usp{Domain}ListProvider);

    return UiKitPageView.withSliver(
      scrollable: true,
      title: '{Domain}',
      bottomBar: _buildBottomBar(context, ref, state),
      child: (childContext, constraints) {
        if (state.status.isLoading) return const Center(child: AppLoader());
        return _buildList(context, ref, state.settings.current.rules);
      },
    );
  }

  UiKitBottomBarConfig? _buildBottomBar(
    BuildContext context, WidgetRef ref, {Domain}ListFeatureState state,
  ) {
    if (!state.isDirty) return null;
    return UiKitBottomBarConfig(
      positiveLabel: 'Save',
      isPositiveEnabled: !state.status.isSaving,
      onPositiveTap: () => _onSave(context, ref),
      onNegativeTap: () => ref.read(usp{Domain}ListProvider.notifier).revert(),
    );
  }
}
```

### B.4 Route Dirty Check — 同 Type A

```dart
LinksysRoute(
  name: RouteNamed.usp{Domain},
  path: RouteNamed.usp{Domain},
  builder: (context, state) => const Usp{Domain}ListView(),
  enableDirtyCheck: true,
  preservableProvider: preservableUsp{Domain}ListProvider,
),
```

### B 類型檢查清單

- [ ] `{Domain}Data` (Layer 1) — 共用步驟
- [ ] `{Item}UI` + `{Item}UIList` — 列表項目 UI 模型（`instancePath` nullable）
- [ ] `{Domain}ListStatus` — 瞬態狀態（含 `maxItems`）
- [ ] `{Domain}ListFeatureState` — 組合 + `initial()` factory
- [ ] `Usp{Domain}ListNotifier` — `addItem` / `editItem` / `deleteItem` + diff-based `performSave`
- [ ] `preservableUsp{Domain}ListProvider` — route dirty check 用
- [ ] View — `UiKitBottomBarConfig` bottom bar（Save + Cancel）
- [ ] Route — `enableDirtyCheck: true`
- [ ] Dashboard card — 改用 `{domain}DataProvider`
- [ ] Dashboard notifier — 移除相關 fetch / state / mutations
- [ ] `flutter analyze` — 0 errors

---

## Type C: Read-Only / Toggle

> 適用於純顯示或簡單 toggle（即時生效）的頁面。
> 直接消費 data provider，不需要 page notifier。

### C.1 Card / View 直接消費 Data Provider

```dart
class Usp{Domain}Card extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch({domain}DataProvider).valueOrNull;
    if (data == null) return const _Skeleton();

    // 直接從 codegen data 建構 UI
    return AppCard(
      child: Column(
        children: [
          AppText.titleMedium(data.field1.value),
          // ...
        ],
      ),
    );
  }
}
```

### C.2 如需 Toggle 操作

```dart
// 在 data provider notifier 中加入 mutation 方法
class {Domain}DataNotifier extends AsyncNotifier<{Domain}Data> {
  // ... build() + _fetch() 同共用步驟 ...

  Future<void> toggle(bool value) async {
    await ref.read(uspMutationLockProvider).withLock(() async {
      final usp = ref.read(uspServiceProvider)!;
      await {CodegenType}.save(usp, {CodegenType}(enable: value));
    });
    ref.invalidateSelf(); // re-fetch
  }
}
```

### C 類型檢查清單

- [ ] `{Domain}Data` (Layer 1) — 共用步驟
- [ ] Card / View 直接 `ref.watch({domain}DataProvider)`
- [ ] 如有 toggle → 在 data notifier 加入 mutation
- [ ] Dashboard card — 改用 `{domain}DataProvider`
- [ ] Dashboard notifier — 移除相關 fetch / state
- [ ] `flutter analyze` — 0 errors

---

## 常見陷阱

### 1. PreservableContract 型別必須一致

`_framework/preservable_contract.dart` **必須 re-export** 原始的 `lib/providers/preservable_contract.dart`，不可複製。原因：`LinksysRoute` 的 `preservableProvider` 參數期望原始型別，複製會產生不同型別。

```dart
// lib/usp_page/_framework/preservable_contract.dart
// 正確 ✓
export 'package:privacy_gui/providers/preservable_contract.dart';

// 錯誤 ✗ — 會造成型別不相容
// class PreservableContract<T, S> { ... }
```

### 2. Data Provider 必須是 NOT autoDispose

Dashboard card 在 app 生命週期內持續存在。如果 data provider 是 autoDispose，card 的 `ref.watch()` dispose 後就會丟失資料。

```dart
// 正確 ✓
final xxxDataProvider = AsyncNotifierProvider<..., ...>(...);

// 錯誤 ✗
final xxxDataProvider = AsyncNotifierProvider.autoDispose<..., ...>(...);
```

### 3. Page Notifier 用 `ref.read()` 不用 `ref.watch()`

Page notifier 從 data provider clone 資料時必須用 `ref.read`。如果 `ref.watch`，SSE 更新會直接覆蓋使用者正在編輯的資料。

```dart
// performFetch 中
// 正確 ✓ — clone，不追蹤
final data = await ref.read({domain}DataProvider.future);

// 錯誤 ✗ — SSE 會覆蓋使用者編輯
final data = await ref.watch({domain}DataProvider.future);
```

SSE 更新的正確路徑是透過 `ref.listen` + `onSseInvalidation()` dirty guard。

### 4. Save 後要 invalidate Data Provider

Save 成功後必須 `ref.invalidate({domain}DataProvider)` 讓 data provider re-fetch，這樣 dashboard card 也會更新。

### 5. Dashboard 殘留引用

移除 state 欄位後，用全域搜尋確認沒有殘留引用：

```bash
grep -rn '{removedField}' lib/usp_page/dashboard/
```

常見藏身處：PDF report (`usp_sliver_dashboard_view.dart`)、statistics page。
Null fallback 用對應 UIModel 的空建構子（如 `const {UIModel}()`）。

### 6. SSE handler 要改為 no-op 而非刪除

Dashboard notifier 的 SSE handler switch case 要保留但改為 no-op + 註解，避免 default 路徑意外觸發全域 re-fetch。

### 7. Mutation Lock 全域共享

所有 domain 的 mutation（save/add/delete）都要透過 `uspMutationLockProvider.withLock()`。WASM USP client 不支援併發呼叫。

---

## 檔案命名慣例

```
lib/usp_page/<domain>/
├── models/
│   ├── {domain}_ui_model.dart          # UI 展示模型
│   ├── {domain}_settings.dart          # Type A: 可編輯設定 wrapper
│   ├── {domain}_status.dart            # Type A: 瞬態狀態
│   └── {domain}_feature_state.dart     # Type A: FeatureState 組合
├── providers/
│   ├── {domain}_data_provider.dart     # Layer 1: 共用 data provider
│   └── usp_{domain}_notifier.dart      # Layer 2: page notifier
├── services/
│   └── usp_{domain}_service.dart       # 商業邏輯（parse / build payload）
├── views/
│   └── usp_{domain}_view.dart          # 頁面 view
└── cards/                              # Phase 5 搬移後
    └── usp_{domain}_card.dart          # Dashboard card
```

---

## 執行順序建議

每個 domain 按以下順序執行，每一步都可 `flutter analyze` 驗證：

1. 建立 `{domain}_data_provider.dart` (Layer 1)
2. 建立 models（Type A 才需要 settings/status/feature_state）
3. 建立/重寫 page notifier (Layer 2)
4. 更新 dashboard card → `ref.watch({domain}DataProvider)`
5. 從 `usp_dashboard_state.dart` 移除欄位
6. 從 `usp_dashboard_notifier.dart` 移除 fetch + SSE + mutations
7. 搜尋並修復殘留引用（PDF report 等）
8. 更新 view → `UiKitBottomBarConfig`（Type A）
9. 設定 route dirty check（Type A）
10. `flutter analyze` — 0 errors

---

## 資料流對照

### Type A (FeatureState — Form)

```
SSE → DataProvider (L1) ──watch──→ Dashboard Card
                         ──listen─→ PageNotifier (L2)
                                    ├── !isDirty → fetch()
                                    └── isDirty → skip
                                    ↓
                                    View (bottomBar: Save/Cancel)
```

### Type B (CRUD List with Preservable)

```
SSE → DataProvider (L1) ──watch──→ Dashboard Card
                         ──listen─→ ListNotifier (L2, FeatureState)
                                    ├── !isDirty → fetch()
                                    └── isDirty → skip
                                    ↓
                                    addItem/editItem/deleteItem (本地 mutation on current)
                                    ↓
                                    View (bottomBar: Save/Cancel)
                                    ↓ Save
                                    diff(original, current) → addMultiple + set + delete
```

### Type C (Read-Only)

```
SSE → DataProvider (L1) ──watch──→ Dashboard Card
                         ──watch──→ View (直接消費)
```

---

## 跨域依賴處理

> 當 Domain A 的 Data Provider 需要 Domain B 的資料時。

### 模式：`ref.read` + `ref.listen`

```dart
class EthernetDataNotifier extends AsyncNotifier<EthernetData> {
  Timer? _debounce;

  @override
  Future<EthernetData> build() async {
    // 1. 監聽依賴的 provider — 當 devices 更新時 re-fetch
    ref.listen(devicesDataProvider, (_, __) => _debouncedInvalidate());

    // 2. 監聽 SSE（本 domain）
    ref.listen(sseInvalidationProvider, (prev, next) {
      if (next.valueOrNull == InvalidationDomain.ethernet) {
        _debouncedInvalidate();
      }
    });
    ref.onDispose(() => _debounce?.cancel());
    return _fetch();
  }

  Future<EthernetData> _fetch() async {
    final usp = ref.read(uspServiceProvider)!;
    // 一次性讀取，不追蹤 — 避免循環依賴
    final devices = await ref.read(devicesDataProvider.future);
    final ethInterfaces = await EthernetInterfaces.fetch(usp);
    return EthernetData(interfaces: ethInterfaces, devices: devices);
  }

  void _debouncedInvalidate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.invalidateSelf();
    });
  }
}
```

### 關鍵規則

1. **`ref.read`（不是 `ref.watch`）**：避免 Riverpod 自動 rebuild 造成無限循環
2. **`ref.listen` 觸發 re-fetch**：保證依賴資料更新時本 provider 也更新
3. **debounce 合併**：多個 source 的 invalidation 合併成一次 re-fetch

### 已知跨域依賴

| 消費者 | 依賴 | 說明 | 解決時機 |
|--------|------|------|----------|
| `dhcp_data_provider.dart:76` | `connectedDevices` | hostname enrichment | Phase 3.2 |
| `usp_single_port_tab.dart:101` | `deviceModels` | IP 下拉選單 | Phase 3.2 |
| Ethernet Data Provider | Devices Data Provider | port ↔ device 對應 | Phase 3.3 |
| Topology Data Provider | Devices + System Info | node UI models | Phase 3.4 |

---

## PDF Report 遷移模式

> 每次從 dashboard 提取一個 domain 後，PDF report 也要同步更新。

### 5 步驟

1. **`PdfReportData` 新增 nullable 欄位**
   ```dart
   // lib/usp_page/dashboard/models/pdf_report_data.dart
   class PdfReportData {
     final UspDashboardState dashboard;
     // ... 其他 domain 欄位 ...
     final SystemInfoUIModel? systemInfo;  // ← 新增
   }
   ```

2. **`usp_sliver_dashboard_view.dart` 建構 PdfReportData**
   ```dart
   final reportData = PdfReportData(
     dashboard: state,
     // ...
     systemInfo: ref.read(systemInfoDataProvider).valueOrNull?.model,
   );
   ```

3. **PDF service 方法改簽名**
   ```dart
   // 之前
   static pw.Widget _buildDeviceInfo(UspDashboardState state) { ... }

   // 之後
   static pw.Widget _buildDeviceInfo(PdfReportData data) {
     final info = data.systemInfo;
     if (info == null) return pw.SizedBox.shrink();
     // ...
   }
   ```

4. **替換 state 存取為 data 存取**
   ```dart
   // 之前
   state.systemInfoModel.firmwareVersion

   // 之後
   data.systemInfo?.firmwareVersion ?? '--'
   ```

5. **驗證**：`flutter analyze` + 確認 PDF 輸出正常

---

## Loading Progress 管理

Dashboard notifier 使用 `UspLoadingProgress` 追蹤初始載入進度：

```dart
final uspLoadingProgressProvider = StateProvider<UspLoadingProgress>(
  (ref) => const UspLoadingProgress(),
);
```

### 規則

- `this.total` 必須等於 `_buildImpl()` 中的 `timed()` 呼叫總數
- 每次從 notifier 移除一個 batch → `total` 同步減少
- 目前（Phase 2 完成後）：**total = 8**（4 batches）

| Batch | timed() calls | 內容 |
|-------|--------------|------|
| 1 | 2 | SystemInfo（ref.read）、ConnectedDevices |
| 2 | 2 | WiFiRadios、WiFiSsids |
| 3 | 3 | WiFiAccessPoints、WiFi Clients、Ethernet |
| 4 | 1 | Mesh Nodes |

---

## Dashboard State 欄位移除標準流程

> 每次從 dashboard 提取一個 domain 後，按此順序從 state 中清除。

### 6 步驟（嚴格順序）

1. **State class field declaration** — 刪除 `final {Type} {fieldName};`
2. **Constructor parameter** — 刪除 `required this.{fieldName}` 或 `this.{fieldName} = const ...`
3. **`copyWith()` parameter** — 刪除 `{Type}? {fieldName},`
4. **`copyWith()` body** — 刪除 `{fieldName}: {fieldName} ?? this.{fieldName},`
5. **`props` list** — 刪除 `{fieldName}.items.length` 或對應 entry
6. **全域搜尋殘留引用**

### 殘留引用搜尋

```bash
# 搜尋 state 欄位名稱
grep -rn '{fieldName}' lib/usp_page/
grep -rn 'state\.{fieldName}' lib/
```

### 常見藏身處

| 位置 | 說明 |
|------|------|
| `usp_sliver_dashboard_view.dart` | PDF report 建構 |
| `usp_pdf_service.dart` | PDF 內容產生 |
| `usp_topology_view.dart` | topology 需要 system info |
| `stats_*_section.dart` | statistics 頁面 |
| `usp_network_topology_card.dart` | dashboard card |
| `node_detail_provider.dart` | device detail |

### Notifier 清理

同時從 `usp_dashboard_notifier.dart` 移除：
- `_fetchXxx()` 方法（或 `timed()` 呼叫）
- `_buildImpl()` 中的 state 賦值
- `_handleInvalidation()` 中的 SSE case（改為 no-op 註解）
- 相關 mutation 方法
- 更新 `this.total` 數字

---

## Phase 進度追蹤

### 已建立的 Data Providers

| Phase | Provider | SSE | 移除的 State Fields |
|-------|----------|-----|---------------------|
| 1 | `firewallDataProvider` | ✅ firewallRules, dmz | `firewallRules`, `dmzEntries` + UI models |
| 2.1 | `timeDataProvider` | ❌ | `timeSettings`, `timeSettingsModel` |
| 2.2 | `lanDataProvider` | ✅ lanNetworkInfo | `lanNetworkInfo`, `lanInfoModel` |
| 2.3 | `dhcpDataProvider` | ✅ dhcpClients | `dhcpClients`, `dhcpReservations` + mutations |
| 2.4 | `portForwardingDataProvider` | ✅ portForwarding | `portForwarding` + rule models + 6 mutations |
| 2.4 | `portTriggeringDataProvider` | ✅ portForwarding | `portTriggering` + rule models + 6 mutations |
| 2.5 | `wanDataProvider` | ✅ wanStatus | `wanStatus`, `wanStatusModel` + `renewWanLease()` |
| 2.6 | `systemInfoDataProvider` | ❌ | `systemInfo`, `systemInfoModel` |

### 額外提取

| Phase | Item | 說明 |
|-------|------|------|
| 2 | `uspMutationLoadingProvider` | 從 God Notifier → `usp_mutation_helper.dart` |

---

## 參考實作對照

| 類型 | Domain | 檔案路徑 |
|------|--------|----------|
| **Type A** (FeatureState — Form) | Firewall | `lib/usp_page/firewall/providers/usp_firewall_notifier.dart` |
| **Type A** (FeatureState — Form) — 先行者 | WiFi Settings | `lib/usp_page/wifi_settings/providers/usp_wifi_settings_provider.dart` |
| **Type B** (FeatureState — CRUD List) JNAP 參考 | IPv6 Port Service | `lib/page/advanced_settings/firewall/providers/ipv6_port_service_list_provider.dart` |
| **Type C** (Read-Only) | System Info | `lib/usp_page/admin/providers/system_info_data_provider.dart` |
| **Type C** (Dialog Atomic) | Time Settings | `lib/usp_page/admin/providers/time_data_provider.dart` |
| **Layer 1** (SSE) | Firewall | `lib/usp_page/firewall/providers/firewall_data_provider.dart` |
| **Layer 1** (no SSE) | Time Settings | `lib/usp_page/admin/providers/time_data_provider.dart` |
| **Layer 1** (cross-domain) | DHCP | `lib/usp_page/local_network/providers/dhcp_data_provider.dart` |
| **Mutation helper** | Shared | `lib/usp_page/dashboard/views/components/usp_mutation_helper.dart` |
| **Mutation lock** | Shared | `lib/usp/providers/usp_mutation_lock.dart` |
| **Framework mixin** | Shared | `lib/usp_page/_framework/preservable_notifier_mixin.dart` |
