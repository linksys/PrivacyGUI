# Phase 2：JNAP → USP 遷移架構計畫

> 文件版本：v2.1 | 日期：2026-03-03
> 前置文件：`phase1_router_datamodel_validation.md`
> 變更歷史：
> - v2.1 — Step 10 完成（USP Dashboard + router redirect 修復）、Phase 2 詳細展開
> - v2.0 — 新增 E2E 測試發現、JNAP 停用環境修復、MVP 重新定義為獨立 USP Dashboard

## 背景與目標

PrivacyGUI 目前透過 `RouterRepository` 使用 JNAP（Linksys 專有協定）進行所有路由器通訊。Phase 1 資料模型驗證結果顯示：140 個 JNAP action 中，僅 **30% 可被 USP 完全取代**，51% 因 Linksys 專有 API、缺少 bbfdm 模組、TR-181 規格限制而**無法取代**。此外，USP 傳輸層目前**僅支援 Web**（WASM）。

這意味著 JNAP 必須與 USP **長期共存** — 遷移是漸進式且部分性的，而非全面替換。

**目標**：設計雙協定架構，讓 Service 層能逐步採用 USP（可用時），同時保留 JNAP 作為不支援功能及非 Web 平台的後備方案。

---

## MVP 驗收點：DeviceInfo 端對端雙協定切換

### MVP 目標

以 **DeviceInfo** 作為最小可行驗證，證明整套雙協定架構從認證→協定選擇→資料取得→UI 顯示完整可行。

### 為什麼選 DeviceInfo

- Codegen `SystemInfo` **已存在**（`lib/generated/system_info.g.dart`）
- TR-181 路徑在路由器上**已完整驗證**
- 純唯讀操作，風險最低
- UI 顯示在多處（Instant Verify、Dashboard、Admin），可驗證資料正確性
- 欄位對映明確（見下表）

### MVP 包含範圍

```
[1] 基礎建設（5 個新檔案）
    ├── ProtocolPreference（BuildConfig 擴充）
    ├── ProtocolResolver（功能→協定對應）
    ├── UspServiceProvider（Riverpod provider）
    ├── UspAuthCoordinator（認證同步）
    └── ProtocolError（錯誤包裝）

[2] 一個功能端對端：DeviceInfo
    ├── uspSystemInfoProvider（FutureProvider，USP 非同步資料源）
    ├── deviceInfoProvider 改為雙路徑（watch USP or JNAP polling）
    ├── NodeDeviceInfo 新增 .fromUsp() 工廠
    └── PollingService 條件式跳過 getDeviceInfo

[3] 建構時切換
    └── --dart-define=protocol=auto|usp_first|jnap_only
```

### 資料流追蹤驗證（已逐檔確認）

#### `deviceInfoProvider` 消費者分析

| 消費者 | 存取欄位 | 來源 |
|--------|---------|------|
| `instant_verify_view.dart:652` | `skuModelNumber` | deviceInfoProvider（SKU，保留 JNAP） |
| `instant_verify_view.dart:640,664,695` | modelNumber, serialNumber, firmwareVersion | **deviceManagerProvider**（非 deviceInfoProvider） |
| `instant_admin_view.dart:79` | `skuModelNumber?.endsWith('AH')` | deviceInfoProvider（SKU） |
| `instant_admin_view.dart:174` | `deviceInfo?.firmwareVersion` | deviceInfoProvider |
| `dashboard_home_service.dart:77-78` | `deviceInfo?.modelNumber`, `hardwareVersion` | deviceInfoProvider（port layout 判定） |
| `instant_verify_pdf_service.dart:89` | `skuModelNumber` | deviceInfoProvider（SKU） |
| `session_provider.dart:91` | `deviceInfo`（cache fallback） | deviceInfoProvider |

> **重要發現**：Instant Verify 頁面的主要裝置資訊（序號、韌體版本、型號、MAC）實際來自 `deviceManagerProvider`（`master` 物件），而非 `deviceInfoProvider`。`deviceInfoProvider` 在 UI 中的影響範圍比預期更小。

#### `SessionService` 必須保留 JNAP

`SessionService.fetchDeviceInfoAndInitializeServices()`（`lib/core/data/services/session_service.dart:140`）：
- 需要 `JnapDeviceInfoRaw.services` 清單呼叫 `buildBetterActions()` 以配置 JNAP action 路由
- **此為登入時一次性呼叫**，非輪詢
- USP `SystemInfo` 無 `services` 欄位 → **此方法不遷移**

### 欄位對映

| UI 欄位 | JNAP (NodeDeviceInfo) | USP (SystemInfo) | 狀態 |
|---------|----------------------|------------------|------|
| 製造商 | `manufacturer` | `manufacturer` | ✅ 完全對映 |
| 型號 | `modelNumber` | `modelName` | ✅ 欄位名不同但語義相同 |
| 序號 | `serialNumber` | `serialNumber` | ✅ 完全對映 |
| 硬體版本 | `hardwareVersion` | `hardwareVersion` | ✅ 完全對映 |
| 韌體版本 | `firmwareVersion` | `softwareVersion` | ✅ 欄位名不同但語義相同 |
| 韌體日期 | `firmwareDate` | ❌ TR-181 無此欄位 | 填空字串（UI 未顯示） |
| 描述 | `description` | ❌ TR-181 無此欄位 | 填空字串（UI 未顯示） |
| SKU | 來自 `getSoftSKUSettings` | ❌ | 保留 JNAP（獨立 action） |

### Provider 同步/非同步整合方案

**問題**：`deviceInfoProvider` 是同步 `Provider<DeviceInfoState>`，但 `SystemInfo.fetch()` 是非同步。

**解法**：新增 `uspSystemInfoProvider`（`FutureProvider`）作為 USP 非同步資料源，`deviceInfoProvider` 透過 `ref.watch()` 讀取已解析值：

```dart
// 新增：USP DeviceInfo 非同步資料源
final uspSystemInfoProvider = FutureProvider<SystemInfo?>((ref) async {
  final resolver = ref.watch(protocolResolverProvider);
  final usp = ref.watch(uspServiceProvider);
  if (!resolver.useUsp(ProtocolFeature.deviceInfo) || usp == null) return null;
  // watch pollingProvider 使其在每次輪詢週期重新觸發
  ref.watch(pollingProvider);
  return SystemInfo.fetch(usp);
});

// 修改：deviceInfoProvider 雙路徑
final deviceInfoProvider = Provider<DeviceInfoState>((ref) {
  final resolver = ref.watch(protocolResolverProvider);
  NodeDeviceInfo? deviceInfo;

  if (resolver.useUsp(ProtocolFeature.deviceInfo)) {
    // USP 路徑：從 uspSystemInfoProvider 讀取
    final systemInfo = ref.watch(uspSystemInfoProvider).value;
    if (systemInfo != null) {
      deviceInfo = NodeDeviceInfo.fromUsp(systemInfo);
    }
    // USP 資料尚未就緒時 deviceInfo=null → UI 顯示 '--'（與現有載入行為一致）
  } else {
    // JNAP 路徑（不變）
    final pollingData = ref.watch(pollingProvider).value;
    final output = getPollingOutput(pollingData, JNAPAction.getDeviceInfo);
    if (output != null) {
      deviceInfo = JnapDeviceInfoRaw.fromJson(output).toUIModel();
    }
  }

  // SKU 始終從 JNAP 輪詢取得
  final pollingData = ref.watch(pollingProvider).value;
  final skuOutput = getPollingOutput(pollingData, JNAPAction.getSoftSKUSettings);
  String? skuModelNumber;
  if (skuOutput != null) {
    skuModelNumber = SoftSKUSettings.fromMap(skuOutput).modelNumber;
  }

  return DeviceInfoState(deviceInfo: deviceInfo, skuModelNumber: skuModelNumber);
});
```

### MVP 修改檔案清單

| 檔案 | 操作 | 說明 |
|------|------|------|
| `lib/constants/build_config.dart` | 修改 | 新增 `ProtocolPreference` |
| `lib/core/protocol/protocol_resolver.dart` | **新增** | 功能→協定選擇 + auth 檢查 |
| `lib/core/protocol/protocol_error.dart` | **新增** | 統一錯誤型別 |
| `lib/usp/providers/usp_service_provider.dart` | **新增** | UspService Riverpod provider |
| `lib/usp/providers/usp_auth_coordinator.dart` | **新增** | 認證同步協調器 |
| `lib/di.dart` | 修改 | 條件式註冊 UspService |
| `lib/providers/auth/auth_provider.dart` | 修改 | login/logout 加入 USP 同步 |
| `lib/core/models/device_info.dart` | 修改 | 新增 `NodeDeviceInfo.fromUsp(SystemInfo)` |
| `lib/core/data/providers/device_info_provider.dart` | 修改 | 新增 `uspSystemInfoProvider` + 雙路徑 |
| `lib/core/data/services/polling_service.dart` | 修改 | 條件式跳過 `getDeviceInfo` |

#### 不需修改的檔案（已驗證）

| 檔案 | 理由 |
|------|------|
| `lib/page/instant_verify/views/instant_verify_view.dart` | 裝置資訊來自 deviceManagerProvider，僅讀 skuModelNumber |
| `lib/page/instant_admin/views/instant_admin_view.dart` | 透過 `DeviceInfoState` 介面存取，介面不變 |
| `lib/page/dashboard/providers/dashboard_home_provider.dart` | 透過 `DeviceInfoState` 介面存取，介面不變 |
| `lib/page/dashboard/services/dashboard_home_service.dart` | 透過 `NodeDeviceInfo?.field` 存取，欄位不變 |
| `lib/page/instant_verify/services/instant_verify_pdf_service.dart` | 僅讀 skuModelNumber |
| `lib/core/data/services/session_service.dart` | 保留 JNAP（需 services 清單） |
| `lib/core/data/providers/session_provider.dart` | 讀 deviceInfoProvider cache，介面不變 |

### MVP 驗收標準

1. **USP 路徑驗證**：Web build + `--dart-define=protocol=usp_first`
   - 登入路由器後，Instant Verify 頁面正確顯示裝置資訊
   - Console 可見 `[UspService.get]` log 證明走 USP 路徑
   - 資料與 JNAP 版本一致（製造商、型號、序號、韌體版本）

2. **JNAP 後備驗證**：Web build + `--dart-define=protocol=jnap_only`
   - 行為完全等同現有版本，無 regression

3. **認證同步驗證**：
   - Local login → Console 可見 USP 自動登入成功
   - 頁面重載 → USP session 自動恢復
   - Logout → USP 同步登出

4. **平台安全驗證**：iOS/Android build
   - `UspService` 為 null，所有功能走 JNAP，無異常

5. **回歸測試**：`./run_tests.sh` 全數通過

### MVP 實作順序

```
Step 1: BuildConfig + ProtocolPreference                    (基礎)     ✅ 完成
Step 2: UspServiceProvider + DI 條件式註冊                   (基礎)     ✅ 完成
Step 3: UspAuthCoordinator + AuthProvider login/logout 整合  (認證)     ✅ 完成
Step 4: ProtocolResolver + ProtocolError                    (基礎)     ✅ 完成
Step 5: NodeDeviceInfo.fromUsp(SystemInfo) 工廠方法          (資料映射)  ✅ 完成
Step 6: uspSystemInfoProvider + deviceInfoProvider 雙路徑    (功能核心)  ✅ 完成
Step 7: PollingService 條件式跳過 getDeviceInfo              (輪詢優化)  ✅ 完成
Step 8: 端對端測試                                          (驗證)     ✅ 完成
Step 9: JNAP 停用環境修復                                   (穩定性)   ✅ 完成
Step 10: USP Dashboard 獨立頁面                             (MVP 驗證)  ✅ 完成
```

> **注意**：`SessionService.fetchDeviceInfoAndInitializeServices()` 不在 MVP 範圍內，
> 該方法須保留 JNAP 以取得 `services` 清單（`buildBetterActions` 依賴）。

---

## E2E 測試發現與修復（Step 8-9）

### 測試環境

- **路由器韌體**：JNAP 完全停用、僅保留 USP 端點
- **目的**：驗證 USP-only 模式下 App 的完整流程

### 發現問題與修復

#### 問題 1：nginx 缺少 USP API 代理

**現象**：USP 登入 HTTP 404
**原因**：開發環境的 nginx 反向代理未配置 `/api/` 路徑
**修復**：在 `router.conf` 新增 `/api/` location block

#### 問題 2：登入成功後停留在登入頁

**現象**：USP 登入成功但畫面不跳轉
**原因**：
- `_doLogin()` 是 fire-and-forget（無 await、無導航）
- `RouterNotifier` 的 `_ref.listen(authProvider, ...)` 被註解掉（未啟用）
- 無任何機制在登入成功後觸發導航

**修復**：在 `LoginLocalView.build()` 加入 `ref.listen(authProvider, ...)` 監聽登入狀態變化，成功後導航至 Dashboard

**檔案**：`lib/page/login/views/login_local_view.dart`

#### 問題 3：登入後無限迴圈

**現象**：登入成功 → Dashboard → 被踢回登入 → 再次登入 → 循環
**原因**：
- `context.go('/')` 觸發 `autoConfigurationLogic` → `authCheck` → `init()`
- `init()` 在 loading ↔ data 之間切換 auth state
- `_ref.watch(authProvider.select(...))` 在 `redirectLogic` 中建立訂閱
- auth state 變化 → `routerProvider` 重建 → 新 GoRouter 從 `/` 開始 → 無限迴圈

**修復**：改用 `context.goNamed(RouteNamed.dashboardHome)` 繞過 `autoConfigurationLogic`/`init()`

**檔案**：`lib/page/login/views/login_local_view.dart`

#### 問題 4：JNAP 回應 HTML 導致 FormatException

**現象**：JNAP 停用時路由器回傳 HTML，`json.decode(html)` 拋出未捕獲的 FormatException
**原因**：`errorTest` 僅捕獲 `JNAPError`，`FormatException` 穿透未處理
**修復**：在 `jnap_spec.dart` 新增 `_decodeJson()` helper，將 FormatException 轉換為 `JNAPError(result: '_ErrorJNAPUnavailable')`

**檔案**：`lib/core/jnap/spec/jnap_spec.dart`（`HttpJNAPSpec` 和 `HttpTransactionSpec`）

#### 問題 5：JNAP 輪詢失敗觸發強制登出

**現象**：Dashboard 短暫顯示後被踢回登入頁
**原因**：`PollingNotifier._polling()` 的 `.onError` 對任何錯誤都呼叫 `logout()`
**修復**：
1. `checkDeviceMode()` 加入 try-catch，失敗回傳預設值
2. `_polling()` 的 `.onError` 區分 `_ErrorJNAPUnavailable`（不登出）vs 其他錯誤（維持登出）
3. `_additionalPolling()` 每個子任務獨立 try-catch
4. `isReady` 僅在 `data.isNotEmpty` 時設為 true，防止空資料下 Dashboard widget crash

**檔案**：
- `lib/core/data/services/polling_service.dart`
- `lib/core/data/providers/polling_provider.dart`

#### 問題 6：Dashboard widget 無法處理空資料

**現象**：`DashboardLoadingWrapper` 放行後，`internet_status.dart` 呼叫 `root.children.first` 在空 topology 上 crash
**根本原因**：現有 Dashboard 所有 widget 深度依賴 JNAP polling 資料。`DashboardLoadingWrapper` 以 `pollingProvider.isReady` 作為閘門 — JNAP 停用時 polling 永遠無資料。
**決策**：不修改現有 Dashboard widget（影響面過大），改為建立**獨立 USP Dashboard 頁面**作為 MVP 驗證入口。

### 修復後已達成的狀態

| 項目 | 狀態 |
|------|------|
| USP 登入（密碼認證） | ✅ 正常（含 JNAP 失敗時的 USP 獨立登入） |
| 登入後導航 | ✅ 正常（goNamed dashboardHome） |
| JNAP HTML 回應處理 | ✅ FormatException → JNAPError 轉換 |
| JNAP 停用不會強制登出 | ✅ _ErrorJNAPUnavailable 保持 session |
| 輪詢子任務隔離 | ✅ 個別 try-catch |
| 現有 Dashboard 顯示 | ❌ Loading tiles（JNAP 無資料，isReady=false） |
| USP 資料在 Dashboard 顯示 | ❌ 需獨立 USP Dashboard（見 Step 10） |

#### 問題 7：Stored credentials 導致 USP Dashboard 被跳過（Step 10 修復）

**現象**：USP 登入成功、USP Dashboard 路由已註冊，但 App 仍導向 `dashboardHome`
**原因**：Local storage 中有先前登入的憑證 → App 啟動時 `autoConfigurationLogic` → `authCheck` → `init()` 讀到 `loginType: local` → `_prepare(state, dashboardHome)` → 呼叫 JNAP 操作（`fetchDeviceInfoAndInitializeServices`）→ 失敗後回到 `_home('error=noDeviceInfo')`。全程完全繞過 `LoginLocalView` 的 `ref.listen`，USP Dashboard 路由從未被觸發。
**修復**：
1. `authCheck`：在 `loginType == local` 時，檢查 `protocolResolverProvider.isUspOnlyMode` → true 則直接回傳 `RoutePath.uspDashboard`，跳過整個 `_prepare()` 流程
2. GoRouter redirect：新增 `/uspDashboard` bypass 規則，避免 `redirectLogic` → `_prepare()` 的 JNAP 操作攔截

**檔案**：`lib/route/router_provider.dart`

---

## MVP 重新定義：獨立 USP Dashboard（Step 10）

### 背景

E2E 測試揭示：現有 Dashboard 所有 widget（InternetStatus、Networks、WiFiGrid、PortAndSpeed、QuickPanel）透過 `DashboardLoadingWrapper` 依賴 `pollingProvider.isReady`。當 JNAP 停用時，polling 資料永遠為空，Dashboard 永遠顯示 loading tiles。

修改現有 Dashboard 來容忍空資料不切實際 — 涉及 20+ 個 widget 的 null 保護，且與現有 JNAP 行為耦合過深。

### 方案：獨立 USP Dashboard 頁面

建立一個**不依賴 JNAP polling** 的獨立頁面，直接透過 USP codegen 取得資料並顯示。

```
USP Login → UspAuthCoordinator → navigate to USP Dashboard
                                         │
                                         ├── SystemInfo.fetch(uspService)  → 裝置資訊
                                         ├── uspService.isAuthenticated    → 連線狀態
                                         └── 獨立 UI（不依賴 pollingProvider）
```

### 設計

#### 新路由

```dart
// route_dashboard.dart 新增
LinksysRoute(
  name: RouteNamed.uspDashboard,
  path: RoutePath.uspDashboard,
  builder: (context, state) => const UspDashboardView(),
),
```

#### 導航邏輯

在 `LoginLocalView` 的登入成功監聽中，依協定模式選擇目標頁面：

```dart
ref.listen(authProvider, (previous, next) {
  if (/* login succeeded */) {
    final resolver = ref.read(protocolResolverProvider);
    if (resolver.isUspOnlyMode) {
      context.goNamed(RouteNamed.uspDashboard);
    } else {
      context.goNamed(RouteNamed.dashboardHome);
    }
  }
});
```

#### USP Dashboard 頁面結構

```dart
class UspDashboardView extends ConsumerWidget {
  // 直接 watch uspSystemInfoProvider（FutureProvider）
  // 不依賴 pollingProvider
  // 顯示：
  //   - 裝置基本資訊（型號、序號、韌體版本、硬體版本）
  //   - USP 連線狀態
  //   - 手動刷新按鈕
  //   - Logout 按鈕
}
```

#### Provider 設計（Phase 2B 更新為 AsyncNotifier）

```dart
/// USP Dashboard 專用 — AsyncNotifier 支援讀取 + 寫入操作
final uspDashboardProvider =
    AsyncNotifierProvider.autoDispose<UspDashboardNotifier, UspDashboardState>(
  UspDashboardNotifier.new,
);

class UspDashboardNotifier extends AutoDisposeAsyncNotifier<UspDashboardState> {
  @override
  Future<UspDashboardState> build() async {
    // Session restore + parallel Future.wait fetch 8 categories
  }

  // Mutation 方法：toggleWifiRadio, updateWifiRadioChannel,
  // updateTimeSettings, toggleDhcpReservation, addDhcpReservation,
  // deleteDhcpReservation, togglePortForwardingRule, addPortForwardingRule,
  // updatePortForwardingRule, deletePortForwardingRule
}
```

### 新增/修改的檔案

| 檔案 | 操作 | 說明 |
|------|------|------|
| `lib/page/usp_dashboard/views/usp_dashboard_view.dart` | **新增** | USP Dashboard 頁面 |
| `lib/page/usp_dashboard/providers/usp_dashboard_provider.dart` | **新增** | 專用 provider |
| `lib/route/constants.dart` | 修改 | 新增 `uspDashboard` 路由名稱 |
| `lib/route/router_provider.dart` | 修改 | 路由定義 + `authCheck` USP-only 分流 + redirect bypass |
| `lib/page/login/views/login_local_view.dart` | 修改 | 依協定模式選擇目標頁面 |
| `lib/core/protocol/protocol_resolver.dart` | 修改 | 新增 `isUspOnlyMode` getter |

### 更新的 MVP 驗收標準

1. **USP Dashboard 端對端**：Web build + JNAP 停用路由器
   - 登入成功 → 自動導航到 USP Dashboard
   - 頁面顯示完整裝置資訊（製造商、型號、序號、韌體版本）
   - Console 可見 `[UspService.get]` log
   - 手動刷新可重新取得資料

2. **JNAP 環境不受影響**：Web build + JNAP 正常路由器
   - 登入後導航到現有 Dashboard（非 USP Dashboard）
   - 行為完全等同修改前

3. **認證同步驗證**：
   - Local login → USP 自動登入成功
   - USP Dashboard logout → 回到登入頁
   - 頁面重載 → USP session 自動恢復

4. **回歸測試**：全部測試通過

---

## 架構決策：協定感知服務層（Protocol-Aware Service Layer）

**否決方案**：統一抽象 `IRouterRepository` 包裝兩種協定
- JNAP 是 action-based（`send(JNAPAction)`），USP 是 path-based（`get(['Device.WiFi.Radio.'])`）
- 以 30% 覆蓋率來說，強制統一介面會產生洩漏抽象且過度工程化

**採用方案**：Service 層成為**協定感知**的 — 每個 service 方法透過 `ProtocolResolver` 決定使用 JNAP 或 USP。這保留了現有模式，並支援逐功能遷移。

```
UI → Provider/Notifier → Service → ProtocolResolver → JNAP (RouterRepository)
                                                     → USP  (UspService + Codegen)
```

---

## Phase 1：基礎建設

### 1.1 在 BuildConfig 新增協定配置

**檔案**：`lib/constants/build_config.dart`

```dart
enum ProtocolPreference {
  jnapOnly,   // 強制 JNAP（行動裝置/桌面，或明確覆寫）
  uspFirst,   // 優先 USP，退回 JNAP
  uspOnly,    // 強制 USP（僅測試/驗證用）
  auto;       // 依平台決定：web → uspFirst，native → jnapOnly

  static ProtocolPreference resolve(String type) { ... }
}

// 加入 BuildConfig：
static ProtocolPreference protocolPreference = ProtocolPreference.resolve(
    const String.fromEnvironment('protocol', defaultValue: 'auto'));
```

### 1.2 建立 UspService Riverpod Provider

**新檔案**：`lib/usp/providers/usp_service_provider.dart`

```dart
final uspServiceProvider = Provider<UspService?>((ref) {
  if (!kIsWeb) return null;  // USP 僅在 Web（WASM）可用
  return getIt.isRegistered<UspService>() ? getIt<UspService>() : null;
});
```

在 `lib/di.dart` 中依平台條件式註冊。

### 1.3 建立 ProtocolResolver

**新檔案**：`lib/core/protocol/protocol_resolver.dart`

功能→協定的集中式註冊表：

```dart
enum ProtocolFeature {
  deviceInfo,
  wifiRadio,
  wifiAP,
  connectedDevices,
  dhcpReservation,
  portForwarding,
  timeSettings,
  networkDiagnostics,
  // ... 可擴充
}

class ProtocolResolver {
  final UspService? _usp;
  final ProtocolPreference _preference;

  bool useUsp(ProtocolFeature feature) {
    if (_usp == null) return false;
    if (!_usp!.isAuthenticated) return false;  // 未認證則退回 JNAP
    if (_preference == ProtocolPreference.jnapOnly) return false;
    if (_preference == ProtocolPreference.uspOnly) return true;
    return _uspSupportedFeatures.contains(feature);
  }

  // 已驗證具備 USP 支援的功能（來自 Phase 1 驗證報告）
  static const _uspSupportedFeatures = {
    ProtocolFeature.deviceInfo,
    ProtocolFeature.wifiRadio,
    ProtocolFeature.wifiAP,
    ProtocolFeature.connectedDevices,
    ProtocolFeature.dhcpReservation,
    ProtocolFeature.portForwarding,
    ProtocolFeature.timeSettings,
    ProtocolFeature.networkDiagnostics,
  };
}
```

Provider：
```dart
final protocolResolverProvider = Provider((ref) {
  return ProtocolResolver(
    ref.watch(uspServiceProvider),
    BuildConfig.protocolPreference,
  );
});
```

### 1.4 認證協調架構（Auth Coordination）

#### 現況分析

**JNAP 認證**（`lib/providers/auth/`）：
- `AuthNotifier` + `AuthService` 管理完整認證生命週期
- **三種登入模式**：
  - `localLogin(password)` → JNAP `checkAdminPassword` → 密碼存入 `FlutterSecureStorage(pLocalPassword)`
  - `cloudLogin(username, password)` → OAuth → `SessionToken` 存入 `FlutterSecureStorage(pSessionToken)`
  - `raLogin(token, networkId, sn)` → RA session token 存入 storage
- `RouterRepository._buildCommandHeader()` 依 `loginType` 組裝不同 auth header：
  - Local：`X-JNAP-Authorization: Basic base64('admin:{password}')`
  - Cloud：`Authorization: LinksysUserAuth session_token={accessToken}`
- `logout()` 清除所有 FlutterSecureStorage + SharedPreferences 憑證

**USP 認證**（`lib/usp/services/usp_service.dart`）：
- `login(password)` → 委託至 WASM `uspclient_login()` — **僅密碼登入**
- `isAuthenticated` → WASM 內部布林值
- `refreshToken()` → WASM 內部 token 刷新
- `logout()` → WASM session 失效
- **關鍵特性**：認證狀態完全封裝在 WASM 記憶體中，Dart 層無法存取 token

#### 關鍵差異與挑戰

| 面向 | JNAP | USP |
|------|------|-----|
| 認證模式 | Local + Cloud + RA | 僅 Local（密碼） |
| 憑證持久化 | FlutterSecureStorage | 無（WASM 記憶體） |
| 頁面重載後 | 自動恢復（讀 storage） | **狀態遺失** |
| Token 刷新 | Dart 層控制 | WASM 內部控制 |
| 錯誤細節 | attemptsRemaining, delayTime | Promise reject（無結構化資訊） |
| Cloud 支援 | 完整 OAuth | 不支援 |

#### 設計方案：UspAuthCoordinator

**新檔案**：`lib/usp/providers/usp_auth_coordinator.dart`

USP 認證不取代 JNAP 認證，而是作為**附加的本地認證通道**。`UspAuthCoordinator` 負責同步兩者：

```dart
class UspAuthCoordinator {
  final UspService? _usp;
  final FlutterSecureStorage _storage;

  /// JNAP localLogin 成功後呼叫 — 自動同步 USP 認證
  Future<void> syncAfterLocalLogin(String password) async {
    if (_usp == null) return;
    try {
      await _usp!.login(password);
    } catch (e) {
      // USP 登入失敗不影響 JNAP，僅記錄警告
      // ProtocolResolver 會因 isAuthenticated=false 而退回 JNAP
      logger.w('[UspAuth] USP login failed after JNAP login: $e');
    }
  }

  /// JNAP logout 時呼叫 — 同步登出 USP
  Future<void> syncAfterLogout() async {
    if (_usp == null || !_usp!.isAuthenticated) return;
    try {
      await _usp!.logout();
    } catch (e) {
      logger.w('[UspAuth] USP logout failed: $e');
    }
  }

  /// 頁面重載 / App 重啟時 — 嘗試用已存密碼重新認證 USP
  Future<void> restoreSession() async {
    if (_usp == null) return;
    if (_usp!.isAuthenticated) return;  // 已認證則跳過
    final password = await _storage.read(key: pLocalPassword);
    if (password != null && password.isNotEmpty) {
      try {
        await _usp!.login(password);
      } catch (e) {
        logger.w('[UspAuth] USP session restore failed: $e');
      }
    }
  }
}
```

#### 整合點

1. **`AuthNotifier.localLogin()` 成功後**（`lib/providers/auth/auth_provider.dart`）
2. **`AuthNotifier.logout()` 中**（`lib/providers/auth/auth_provider.dart`）
3. **App 啟動 / 頁面重載時**（路由 guard 或 `build()` 中呼叫 `restoreSession()`）
4. **`ProtocolResolver.useUsp()` 包含 `isAuthenticated` 檢查**

#### 認證模式對照表

| 使用者登入方式 | JNAP 認證 | USP 認證 | 協定選擇 |
|---------------|----------|---------|---------|
| Local login | ✅ Basic auth | ✅ 自動同步 | USP 可用 |
| Cloud login | ✅ OAuth token | ❌ 不支援 | 僅 JNAP |
| RA login | ✅ RA session | ❌ 不支援 | 僅 JNAP |
| 頁面重載（已有 local） | ✅ 讀 storage | ✅ restoreSession | USP 可用 |
| 頁面重載（已有 cloud） | ✅ 讀 storage | ❌ 無密碼可用 | 僅 JNAP |

#### USP Token 刷新策略

WASM client 內部管理 token 生命週期。Dart 層在 PollingNotifier 每次輪詢時（每 60s）呼叫 `refreshToken()`，失敗時透過 `restoreSession()` 重新登入。

### 1.5 共用領域模型層

**原則**：領域模型保持協定無關。JNAP 和 USP 兩條程式碼路徑都產出相同的領域模型。Codegen 輸出的類別作為 **USP 專用 DTO**，再映射到現有領域模型。

### Phase 1 需建立/修改的檔案（彙整）

| 檔案 | 操作 |
|------|------|
| `lib/constants/build_config.dart` | 新增 `ProtocolPreference` enum + 欄位 |
| `lib/core/protocol/protocol_resolver.dart` | **新增** — 功能→協定對應 + `isAuthenticated` 檢查 |
| `lib/usp/providers/usp_service_provider.dart` | **新增** — UspService 的 Riverpod provider |
| `lib/usp/providers/usp_auth_coordinator.dart` | **新增** — JNAP↔USP 認證同步協調器 |
| `lib/providers/auth/auth_provider.dart` | 在 `localLogin`/`logout` 加入 USP 同步 |
| `lib/di.dart` | 條件式註冊 UspService（僅 Web） |

---

## Phase 2：唯讀核心功能（首批 USP 整合）

### 每個功能的遷移模式（範本）

1. 在 `doc/usp/definitions/` 撰寫 **YAML 定義**（TR-181 路徑）
2. 執行 **codegen** → 在 `lib/generated/` 產出 Dart DTO
3. 在現有 provider 中新增 **USP 非同步資料源**（FutureProvider）
4. 修改現有 provider 為**雙路徑**（watch USP or JNAP polling）
5. 在 `PollingService.buildCoreTransactions()` 條件式跳過對應 action
6. 新增領域模型 `.fromUsp()` 工廠建構子（如需要）
7. **測試**兩條路徑

### MVP 已建立的雙路徑模板（DeviceInfo）

```dart
// Step 1: USP 非同步資料源
final uspSystemInfoProvider = FutureProvider<SystemInfo?>((ref) async {
  final resolver = ref.watch(protocolResolverProvider);
  final usp = ref.watch(uspServiceProvider);
  if (!resolver.useUsp(ProtocolFeature.deviceInfo) || usp == null) return null;
  ref.watch(pollingProvider);  // 每次輪詢週期重新觸發
  return SystemInfo.fetch(usp);
});

// Step 2: 雙路徑 provider
final deviceInfoProvider = Provider<DeviceInfoState>((ref) {
  final resolver = ref.watch(protocolResolverProvider);
  if (resolver.useUsp(ProtocolFeature.deviceInfo)) {
    // USP path
    final systemInfo = ref.watch(uspSystemInfoProvider).value;
    if (systemInfo != null) deviceInfo = NodeDeviceInfo.fromUsp(systemInfo);
  } else {
    // JNAP path (unchanged)
  }
});
```

---

### 2.1 DeviceInfo ✅（MVP 已完成）

- **Codegen**：`system_info.g.dart` — `SystemInfo.fetch()`
- **Provider**：`uspSystemInfoProvider` + `deviceInfoProvider` 雙路徑
- **PollingService**：已條件式跳過 `JNAPAction.getDeviceInfo`
- **USP Dashboard**：獨立頁面直接使用 `SystemInfo.fetch()`

---

### 2.2 Connected Devices（連線裝置）✅ 完成

**優先級**：P1 — Codegen 已存在，純唯讀

**現狀**：
- JNAP：`JNAPAction.getDevices` + `getNetworkConnections`（polling 取得）
- Codegen：`connected_devices.g.dart` — `ConnectedDevices.fetch()`（v5 已驗證）
- TR-181：`Device.Hosts.Host.{i}.` — Phase 1 驗證完整
- **已實作**：USP Dashboard 卡片，含 online/offline 篩選

**欄位對映**：

| UI 欄位 | JNAP | USP (`ConnectedDevice`) | 備註 |
|---------|------|------------------------|------|
| MAC | `macAddress` | `macAddress`（PhysAddress） | ✅ |
| IP | `ipAddress` | `ipAddress`（IPAddress） | ✅ |
| 主機名 | `hostName` | `hostName`（HostName） | ✅ |
| 連線狀態 | `isOnline` | `isActive`（Active） | ✅ 語義相同 |
| 介面 | `connections[].interface` | `interface_`（Layer1Interface） | ✅ |
| IP 來源 | N/A | `addressSource`（DHCP/Static） | 🆕 USP 額外欄位 |
| nodeDeviceId | `nodeDeviceId` | ❌ Linksys 專有 | 保留 JNAP |
| knownInterfaces | `knownInterfaces` | ❌ Linksys 專有 | 保留 JNAP |

**資料豐富度差異**：JNAP 提供 Linksys 專有欄位（`nodeDeviceId`、`knownInterfaces`、`operatingSystem`）。USP 僅提供標準 TR-181 欄位。在 USP-only 環境（USP Dashboard）使用精簡資料；在雙協定環境中可合併。

**實作步驟**：

| 步驟 | 檔案 | 操作 |
|------|------|------|
| 1 | `lib/generated/connected_devices.g.dart` | **已存在** — `ConnectedDevices.fetch()` |
| 2 | `lib/core/data/providers/usp_connected_devices_provider.dart` | **新增** — `FutureProvider<ConnectedDevices?>` |
| 3 | `lib/page/usp_dashboard/providers/usp_dashboard_provider.dart` | 修改 — state 加入 `ConnectedDevices` |
| 4 | `lib/page/usp_dashboard/views/usp_dashboard_view.dart` | 修改 — 新增連線裝置卡片 |
| 5 | `lib/core/data/services/polling_service.dart` | 修改 — 跳過 `getDevices` |

**USP Dashboard 整合策略**：先在 USP Dashboard 新增連線裝置卡片（獨立 USP 資料）。不改現有 `device_manager_provider`（太複雜）。

---

### 2.3 WiFi Radio / AP / SSID ✅ 完成

**優先級**：P1 — Phase 1 驗證完整

**現狀**：
- JNAP：`getRadioInfo` + `getGuestRadioSettings`（polling）
- Codegen：`wi_fi_radios.g.dart` + `wi_fi_access_points.g.dart` + `wi_fi_ssids.g.dart`
- TR-181：`Device.WiFi.Radio.{i}.` + `Device.WiFi.AccessPoint.{i}.` + `Device.WiFi.SSID.{i}.`
- **已實作**：3 個 YAML 定義 + codegen + USP Dashboard WiFi Status 卡片（含 Radio toggle、channel edit、AP → SSID 交叉參照）

**已知限制**：
- **BUG-001（CRITICAL）**：`Device.WiFi.SSIDNumberOfEntries = 0` — SSID 實例枚舉為空
- Radio 和 AP 不受影響，SSID 被阻擋

**需撰寫的 YAML**：

```yaml
# doc/usp/definitions/wifi/radio.yaml
name: WifiRadios
basePath: Device.WiFi.Radio
type: multi-instance
parameters:
  - name: enabled
    type: boolean
    tr181Path: Enable
  - name: channel
    type: int
    tr181Path: Channel
  - name: operatingFrequencyBand
    type: string
    tr181Path: OperatingFrequencyBand
  - name: operatingStandards
    type: string
    tr181Path: OperatingStandards
  - name: channelBandwidth
    type: string
    tr181Path: OperatingChannelBandwidth
  - name: autoChannelEnabled
    type: boolean
    tr181Path: AutoChannelEnable

# doc/usp/definitions/wifi/access_point.yaml
name: WifiAccessPoints
basePath: Device.WiFi.AccessPoint
type: multi-instance
parameters:
  - name: enabled
    type: boolean
    tr181Path: Enable
  - name: ssidReference
    type: string
    tr181Path: SSIDReference
  - name: securityMode
    type: string
    tr181Path: Security.ModeEnabled
  - name: wpaEncryption
    type: string
    tr181Path: Security.X_LINKSYS_WPAEncryption
```

**欄位對映**：

| UI 欄位 | JNAP (`RadioInfo`) | USP (`WifiRadio`) | 備註 |
|---------|--------------------|--------------------|------|
| 啟用 | `isEnabled` | `enabled` | ✅ |
| 頻段 | `radioID`/`band` | `operatingFrequencyBand` | ✅ 需轉換 |
| 頻道 | `channel` | `channel` | ✅ |
| 頻寬 | `channelWidth` | `channelBandwidth` | ✅ |
| 標準 | `supportedModes` | `operatingStandards` | ✅ |
| 自動頻道 | `autoChannelSetting` | `autoChannelEnabled` | ✅ |

**實作步驟**：

| 步驟 | 操作 |
|------|------|
| 1 | 撰寫 `radio.yaml` + `access_point.yaml` |
| 2 | 執行 codegen → 產出 `wifi_radios.g.dart` + `wifi_access_points.g.dart` |
| 3 | 新增 `uspWifiRadiosProvider` (`FutureProvider`) |
| 4 | USP Dashboard 新增 WiFi 狀態卡片 |
| 5 | PollingService 條件式跳過 `getRadioInfo` |

---

### 2.4 Time Settings（時間設定）✅ 完成

**優先級**：P1 — Phase 1 驗證 100%（3/3 actions）

**現狀**：
- JNAP：`getTimeSettings`（polling）
- Codegen：`time_settings.g.dart` — `TimeSettings.fetch()` + writable（enable、NTP 1/2）
- TR-181：`Device.Time.` — 完整驗證
- **已實作**：YAML 定義 + codegen + USP Dashboard Time Settings 卡片（含 inline enable toggle + NTP edit dialog）

**需撰寫的 YAML**：

```yaml
# doc/usp/definitions/core/time_settings.yaml
name: TimeSettings
basePath: Device.Time
type: single-instance
parameters:
  - name: ntpServer1
    type: string
    tr181Path: NTPServer1
    writable: true
  - name: ntpServer2
    type: string
    tr181Path: NTPServer2
    writable: true
  - name: localTimeZone
    type: string
    tr181Path: LocalTimeZone
    writable: true
  - name: currentLocalTime
    type: string
    tr181Path: CurrentLocalTime
  - name: status
    type: string
    tr181Path: Status
```

---

### 2.5 Port Forwarding（完整 CRUD）✅ 完成

**優先級**：P2 — Codegen 已存在，含寫入操作
- **已實作**：USP Dashboard Port Forwarding 卡片（toggle + add/edit dialog + delete with confirmation）

**現狀**：
- JNAP：`getSinglePortForwarding` / `setSinglePortForwarding`（4 actions）
- Codegen：`port_forwarding.g.dart` — `fetch()` / `update()` / `updateMany()`（v5 已驗證）
- TR-181：`Device.NAT.PortMapping.{i}.` — Phase 1 驗證完整

**Codegen API 概覽**：
- `PortForwarding.fetch(usp)` → `List<PortForwardingRule>`（GET）
- `PortForwarding.update(usp, ruleUpdate)` → 修改單條規則（SET）
- `PortForwarding.updateMany(usp, updates)` → 批量修改（SET batch）
- `usp.add('Device.NAT.PortMapping.', params)` → 新增規則（ADD）
- `usp.del('Device.NAT.PortMapping.{i}.')` → 刪除規則（DEL）

**實作策略**：Phase 2 先做唯讀（`fetch`），Phase 3 再加入寫入（`update`/`add`/`del`）。

---

### 2.6 Network Diagnostics（Ping/Traceroute）

**優先級**：P2 — Phase 1 驗證 71%

**現狀**：
- JNAP：`startPing` / `startTraceroute` / `getTracerouteStatus` / `stopPing`
- TR-181：`Device.IP.Diagnostics.IPPing()` / `TraceRoute()`
- **限制**：USP 無法 cancel 已啟動的 diagnostic（TR-181 無 stop 概念）

**USP API**：
```dart
usp.operate('Device.IP.Diagnostics.IPPing()', args: {
  'Host': '8.8.8.8',
  'NumberOfRepetitions': '4',
  'Timeout': '5000',
})
```

**實作策略**：先做 Ping（最簡單的 OPERATE），Traceroute 後續跟進。

---

### 2.7 DHCP Reservation（靜態租約）✅ 完成

**優先級**：P1 — Phase 1 驗證完整（含 ADD/DELETE）

**現狀**：
- JNAP：`getDHCPClientTable` / `setDHCPReservation`
- Codegen：`dhcp_reservations.g.dart` — `fetch()` + `update()` + `add()` + `delete()`
- TR-181：`Device.DHCPv4.Server.Pool.1.StaticAddress.{i}.`
- **已實作**：YAML 定義（`type: add` + `writable: true`）+ codegen + USP Dashboard 卡片（toggle + add dialog + delete with confirmation）

**需撰寫的 YAML**：

```yaml
# doc/usp/definitions/network/dhcp_reservation.yaml
name: DhcpReservations
basePath: Device.DHCPv4.Server.Pool.1.StaticAddress
type: multi-instance
singularName: DhcpReservation
parameters:
  - name: enabled
    type: boolean
    tr181Path: Enable
    writable: true
  - name: macAddress
    type: string
    tr181Path: Chaddr
    writable: true
  - name: ipAddress
    type: string
    tr181Path: Yiaddr
    writable: true
```

---

### 2.8 USP Dashboard 功能擴充路線圖

Phase 2 的功能以 **USP Dashboard 為主要展示介面**，逐步豐富頁面內容：

```
Step 10 (MVP ✅)
└── 裝置資訊（SystemInfo） + 系統狀態 + 協定資訊

Phase 2A: 唯讀擴充
├── 連線裝置列表（ConnectedDevices）
├── WiFi 狀態（Radio + AP，不含 SSID）
├── 時間設定顯示（TimeSettings）
└── DHCP 保留列表顯示（DhcpReservations）

Phase 2B: 寫入操作
├── WiFi 頻道/啟用切換（Radio SET）
├── DHCP 保留新增/刪除（ADD/DEL）
├── Port Forwarding CRUD
└── 時間設定修改（NTP SET）

Phase 2C: 進階操作
├── Ping 診斷（OPERATE）
├── Traceroute 診斷（OPERATE）
└── 即時裝置通知（subscribe，待 WASM 支援）
```

### Phase 2 實作進度

```
Phase 2A-1: Connected Devices（讀取）   ✅ 完成
Phase 2A-2: WiFi Radio/AP/SSID（讀取）  ✅ 完成 — 3 個 YAML + codegen + Dashboard 卡片
Phase 2A-3: Time Settings（讀取）       ✅ 完成
Phase 2A-4: DHCP Reservations（讀取）   ✅ 完成
Phase 2B-1: Port Forwarding（讀取）     ✅ 完成 — 第 8 張卡片
Phase 2B-2: WiFi SET                   ✅ 完成 — enable toggle + channel edit dialog
Phase 2B-3: DHCP CRUD                 ✅ 完成 — toggle + add dialog + delete
Phase 2B-4: Port Forwarding CRUD      ✅ 完成 — toggle + add/edit dialog + delete
Phase 2B-5: Time SET                   ✅ 完成 — inline toggle + NTP edit dialog
Phase 2C-1: Ping OPERATE              ❌ 未開始 — 需 OPERATE codegen 支援
Phase 2C-2: Traceroute OPERATE         ❌ 未開始
Phase 2C-3: Subscribe（即時通知）       ❌ 未開始 — WASM client 尚未支援
```

---

## Phase 3：寫入操作

> 已合併至 Phase 2B（見上方 2.8 路線圖）

---

## Phase 4：複雜功能

> 已合併至 Phase 2C（見上方 2.8 路線圖）

---

## Phase 5：訂閱遷移（未來）

當 USP subscribe 實作完成後，以 subscription 逐步取代 JNAP polling。

---

## 單一功能遷移檢查清單

- [ ] 從 Phase 1 驗證報告確認 TR-181 路徑可用性
- [ ] 在 `doc/usp/definitions/<category>/` 撰寫 YAML 定義
- [ ] 執行 codegen：`./tools/usp-codegen --definitions-dir ... --output-dir lib/generated/`
- [ ] 在 `ProtocolResolver` 新增 `ProtocolFeature` enum 值
- [ ] 在領域模型新增 `.fromUsp()` 工廠（或建立映射 helper）
- [ ] 修改 service 方法，檢查 `resolver.useUsp()` 並呼叫對應路徑
- [ ] 更新 `PollingService.buildCoreTransactions()` 跳過已遷移的 action
- [ ] 撰寫使用 mock UspService 的單元測試
- [ ] 使用 `--dart-define=protocol=usp_first` 在路由器上測試
- [ ] 使用 `--dart-define=protocol=jnap_only` 驗證 JNAP 後備仍正常運作

---

## 錯誤處理統一

**新檔案**：`lib/core/protocol/protocol_error.dart`

```dart
class ProtocolException implements Exception {
  final String message;
  final String? protocolErrorCode;  // JNAP result string 或 USP error code
  final Protocol source;  // jnap 或 usp
}
```

---

## 遷移優先順序（依 Phase 1 驗證結果）

| 優先級 | 功能 | JNAP Actions | USP 狀態 | Codegen |
|--------|------|-------------|----------|---------|
| P0 | DeviceInfo | 2 | ✅ 完整 | SystemInfo 已存在 |
| P0 | WiFi Radio/AP | 4 | ✅ 完整（SSID bug 除外） | 需撰寫 YAML |
| P1 | 連線裝置 | 3 | ✅ 完整 | ConnectedDevices 已存在 |
| P1 | DHCP 保留位址 | 2 | ✅ 完整 | 需撰寫 YAML |
| P1 | 時間/NTP | 2 | ✅ 完整 | 需撰寫 YAML |
| P2 | Port Forwarding | 4 | ✅ 完整 | PortForwarding 已存在 |
| P2 | 網路診斷 | 4 | ✅ 完整（Ping/Traceroute） | 需撰寫 YAML |
| P2 | WPS | 2 | ✅ 完整 | 需撰寫 YAML |
| P3 | 防火牆 | 5 | 🟡 部分（bug BUG-002） | 需撰寫 YAML |
| 延後 | VPN、Setup、Guest、MAC Filter | 30+ | ❌ 不可用 | 被阻擋 |
| 延後 | SmartMode、MLO、Backhaul | 20+ | ❌ Linksys 專有 | 被阻擋 |

---

## 驗證計畫

1. **單元測試**：Mock `UspService` 和 `ProtocolResolver`，驗證 JNAP 和 USP 兩條路徑
2. **建構時切換**：`flutter run --dart-define=protocol=usp_first` vs `jnap_only`
3. **路由器端對端**：以 Web 建構對 M60TB-EU 路由器執行，驗證 USP 資料與 JNAP 資料一致
4. **後備測試**：停用路由器上的 usp-bridge，驗證 App 優雅退回 JNAP
5. **平台測試**：在 iOS/Android 執行，驗證 JNAP-only 模式正常（UspService 為 null）
6. **回歸測試**：現有測試套件（`./run_tests.sh`）在 `protocol=jnap_only` 下必須全部通過

---

## 總結

### 已完成（Step 1-10 + Phase 2A + Phase 2B）

**Phase 1 基礎建設** ✅
- 5 個新檔案（ProtocolResolver、UspServiceProvider、UspAuthCoordinator、ProtocolPreference、ProtocolError）
- DeviceInfo 雙路徑（`uspSystemInfoProvider` + `deviceInfoProvider`）
- PollingService 條件式跳過 `getDeviceInfo`
- JNAP 停用環境穩定性修復：FormatException 處理、輪詢容錯、登入導航修正
- 認證協調 — `UspAuthCoordinator` 自動同步 JNAP↔USP 登入/登出
- 獨立 USP Dashboard — 不依賴 JNAP polling
- Router redirect 修復 — stored credentials 正確分流至 USP Dashboard

**Phase 2A 唯讀擴充** ✅
- 8 個 YAML 定義 + codegen v0.6.1 產出（SystemInfo、ConnectedDevices、WiFiRadios、WiFiSsids、WiFiAccessPoints、TimeSettings、DhcpReservations、PortForwarding）
- USP Dashboard 8 張資料卡片 + Protocol Info
- 並行 `Future.wait` fetch（WASM client 修正後支援）
- WiFi AP → SSID 交叉參照

**Phase 2B 寫入操作** ✅
- Provider 架構重構：`FutureProvider` → `AsyncNotifierProvider` + `_withLock()` 順序鎖
- WiFi Radio：enable/disable toggle + channel edit dialog
- DHCP Reservations：toggle + add dialog + delete with confirmation
- Port Forwarding：toggle + add/edit dialog + delete with confirmation
- Time Settings：inline toggle + NTP edit dialog
- `uspMutationLoadingProvider` 追蹤每張卡片的 mutation 載入狀態
- Codegen YAML 更新 `writable: true` 和 `type: add` 旗標

### 下一階段：Phase 2C 進階操作

- Ping/Traceroute 診斷（OPERATE）— 待 codegen OPERATE 支援
- 即時裝置通知（Subscribe）— 待 WASM client 支援

### 架構原則

- **善用 Codegen** — USP 資料存取透過產出的 DTO，非手寫
- **逐功能遷移** — 每個 service 方法可獨立切換
- **保留 JNAP** — 永遠可用作後備，51% 功能仍需 JNAP
- **平台安全** — USP 在非 Web 平台為 null，Cloud/RA 模式自動退回 JNAP
- **USP Dashboard 獨立** — 不改動現有 JNAP Dashboard，避免影響面過大
