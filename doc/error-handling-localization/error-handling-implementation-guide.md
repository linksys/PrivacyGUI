# Error Handling 實作指南（USP Feature）

> **這份文件回答「怎麼做」。** 新增一個 USP feature 頁面時，error handling 該照什麼 pattern 寫、該顯示什麼、不該顯示什麼、怎麼達成 localization。
> **背景知識（「為什麼」）** —— 錯誤如何從 firmware 流到 UI、9999/7xxx/9xxx/9998 的差別、兩條路徑的成因 —— 見 [`usp-error-handling-reference.md`](usp-error-handling-reference.md)。本文只在需要時引用，不重述。
> **現存做法的來源**：PR #953（`feat(l10n): centralize error message localization for USP features`）。本文所有 code 範例都對照當前 codebase，不是理想規劃。

---

## 0. 一分鐘總覽（TL;DR）

錯誤一條線從下往上流，**每層職責固定**：

```
Service  →  catch 任何錯誤，轉成 typed ServiceError 後拋出
            （fetch：直接 map；save：先自拋 Usp*FailureError，再用守衛放行）
   │  ServiceError 物件
   ▼
Provider →  只透傳，不加工、不碰 BuildContext、不轉字串
            fetch：把 ServiceError 存進 state.error（或讓它流進 AsyncValue.error）
            save ：rethrow
   │  ServiceError 物件
   ▼
View     →  唯一做 localization 的地方
            拿到 ServiceError → localizeServiceError(context, error) → 在地化字串
            fetch 失敗：空狀態 widget；save 失敗：snackbar
```

**三條鐵則**：
1. **Service 是錯誤轉換點**：往上流動的一律是 `ServiceError`，不是 raw 字串、不是 `Exception`。
2. **Provider 只透傳型別**：絕不 `'$e'` 壓成字串（型別一遺失，View 就無法在地化）。
3. **只有 View 做 localization**：透過唯一的中央 mapper `localizeServiceError()`。Service/Provider 沒有 `BuildContext`，也不該有。

---

## 1. Service 層：把所有錯誤轉成 ServiceError

Service 是錯誤的「收斂點」。不管底層丟字串、envelope、還是 Dart 例外，離開 Service 時**一律是 `ServiceError`**。

fetch 與 save 是**兩種不同 pattern**，差別只在一道守衛。

### 1.1 fetch（GET）—— 無守衛

範本：[`usp_dmz_service.dart`](../../lib/page/dmz/services/usp_dmz_service.dart) `fetch()`

```dart
Future<(DmzSettings, DmzStatus)> fetch() async {
  try {
    final dmzData = await Dmz.fetch(_usp);   // codegen / WASM 失敗 → 丟 raw 字串
    final uiModel = buildUIModel(dmzData);   // 純資料組裝，不會丟 ServiceError
    return (DmzSettings(model: uiModel, ...), const DmzStatus(isLoading: false));
  } catch (e) {
    throw mapUspErrorToServiceError(e);      // 直接 map，不需守衛
  }
}
```

**為何不需要守衛**：fetch 的 try 區塊裡，唯一會丟的是 codegen / WASM 的 raw 字串，以及純資料組裝（不丟 ServiceError）。`catch` 收到的 `e` 不可能是 ServiceError，所以不必檢查。

### 1.2 save（SET / ADD / DELETE）—— 有 `is ServiceError` 守衛

範本：[`usp_dmz_service.dart`](../../lib/page/dmz/services/usp_dmz_service.dart) `update()` / `add()`

```dart
Future<void> update({required String instancePath, required DmzUIModel model}) async {
  try {
    final result = await Dmz.update(_usp, [DmzEntryUpdate(...)]);
    switch (UspResultParser.parseSetResult(result)) {
      case UspSuccess():
        break;
      case UspPartialSuccess(:final errorSummary, :final successes, :final failures):
        throw UspPartialFailureError(            // ← Service 自己丟 ServiceError
          summary: 'DMZ update partial failure: $errorSummary',
          successPaths: successes.map((s) => s.requestedPath).toList(),
          failures: failures,                    // 完整 List<UspErrorDetail>，不要只存 path
        );
      case UspFailure(:final errorSummary, :final errors):
        throw UspCompleteFailureError(           // ← 同上
          summary: 'DMZ update failed: $errorSummary',
          failures: errors,
        );
    }
  } catch (e) {
    if (e is ServiceError) rethrow;              // 守衛：自拋的 ServiceError 原樣放行
    throw mapUspErrorToServiceError(e);          // 其餘 raw 字串才 map
  }
}
```

**為何需要守衛**：save 會解析 batch envelope、**主動 `throw UspPartialFailureError` / `UspCompleteFailureError`（已是 ServiceError）**。沒有守衛的話，這些自拋的 ServiceError 會被外層 catch 接住、再丟進 `mapUspErrorToServiceError`，因不符 `"{Op} failed:"` 格式被誤包成 `UnexpectedError`，語意全失。守衛讓「自己丟的 ServiceError 原樣冒上去」。

> **一句話**：守衛 =「try 區塊裡會不會自拋 ServiceError」的指標。會（save）→ 要守衛；不會（fetch）→ 不要。

### 1.3 batch 失敗一定要存完整 `failures`

`UspPartialFailureError` / `UspCompleteFailureError` 是**容器**，內含 `List<UspErrorDetail> failures`（完整 path + errorCode + errorMessage）。

- ✅ **存整個 `failures` list**（從 `UspPartialSuccess`/`UspFailure` 的 `failures`/`errors` 直接傳）。
- ❌ **不要只存 path 字串**——那樣 errorCode 流失，View 就無法依 code 在地化。
- `failedPaths` 是衍生 getter（`failures.map((f) => f.requestedPath)`），向後相容，不用自己組。

### 1.4 不要在 Service 寫死「使用者看的」錯誤訊息

Service 沒有 `BuildContext`，**不該組任何要給使用者看的文案**。
- `summary` 欄位是**給 log / debug 用**的英文摘要，不會顯示給使用者（View 不讀它）。
- 唯一從 Service 流到 UI 的「文字」是 `UnexpectedError.detail`（fallback 時 View 會顯示它）——但那是診斷字串，不是你寫死的 UI 文案。

> ⚠ **field-level 表單驗證是另一條線**，不要混淆。`validateForm()` 回的 `Map<String,String>`（如 `{'destIp': 'Invalid IP address'}`）是欄位級驗證，走 `status.fieldErrors`，**不是 ServiceError**。它的 localization 屬一般表單字串範圍，不在本文 error handling pipeline 內。

---

## 2. Provider 層：只透傳，不加工

Provider 的唯一職責是**把 Service 給的 `ServiceError` 原封不動往上送**。不碰 `BuildContext`、不轉字串、不組文案、不再呼叫 `mapUspErrorToServiceError`。

依頁面架構分兩種寫法。

### 2.1 Preservable / Notifier 頁面（state.error）

範本：[`usp_dmz_notifier.dart`](../../lib/page/dmz/providers/usp_dmz_notifier.dart)

**fetch 失敗 → 存進 `state.error`（型別，不是字串）**：

```dart
@override
Future<(DmzSettings?, DmzStatus?)> performFetch({...}) async {
  try {
    final (settings, status) = await _svc.fetch();
    return (settings, status);
  } on ServiceError catch (e) {                 // 一定 catch ServiceError 型別
    logger.e('[USP][...][DMZ]: Fetch failed', error: e);
    return (null, DmzStatus(isLoading: false, error: e));  // 存物件，不是 '$e'
  }
}
```

**save 失敗 → rethrow**（framework 的 `save()` 透明不 catch，讓 ServiceError 直穿到 View）：
save 路徑不用自己寫 catch；`PreservableAutoDisposeNotifierMixin.save()` 會讓 Service 拋的 ServiceError 直接往上。

對應的 state model：

```dart
class DmzStatus extends Equatable {
  /// Typed error from the last fetch. View localizes it via localizeServiceError.
  final ServiceError? error;            // ✅ 不是 String? errorMessage

  DmzStatus copyWith({
    ServiceError? error,
    bool clearError = false,            // ← 見下方陷阱
    ...
  }) => DmzStatus(
        error: clearError ? null : (error ?? this.error),
        ...
      );
}
```

> ⚠ **陷阱：`copyWith` 清空 error 要用 `clearError` flag**。Dart 的 `error ?? this.error` 無法區分「沒傳」和「傳 null」，所以清除錯誤狀態（例如重新 fetch 前）必須走顯式的 `clearError: true`，不能靠傳 `error: null`。

### 2.2 AsyncNotifier 頁面（AsyncValue.error）

範本：[`usp_admin_notifier.dart`](../../lib/page/admin/providers/usp_admin_notifier.dart)

這類頁面用 `AsyncNotifier`，錯誤直接讓它流進 `AsyncValue.error`：

```dart
class UspAdminNotifier extends AutoDisposeAsyncNotifier<UspAdminState> {
  @override
  Future<UspAdminState> build() async {
    try {
      final adminUser = await _svc.fetchAdmin();
      return UspAdminState(...);
    } on ServiceError catch (e) {
      logger.e(...);
      rethrow;                          // rethrow → 進 AsyncValue.error，View 用 .when(error:) 接
    }
  }
}
```

> **怎麼選**：跟著頁面既有的 state 架構走，不要為了 error handling 改架構。
> - 用 `FeatureState` / `Preservable` 的 → 2.1（state.error）。
> - 用 `AsyncNotifier` 的 → 2.2（AsyncValue.error）。
> 兩者最終都在 View 走同一個 `localizeServiceError`，只是「錯誤存哪」與「View 怎麼顯示」不同（見 §3）。

---

## 3. View 層：唯一做 localization 的地方

View 拿到 `ServiceError`，丟給中央 mapper [`localizeServiceError(context, error)`](../../lib/components/localizations/service_error_localizations.dart) 取得在地化字串。**這是全 codebase 唯一把 error 型別變成顯示字串的地方。**

### 3.1 fetch 失敗的顯示（兩種，對應 §2 兩種 provider）

**(A) state.error 頁面 → 用共用 widget [`ServiceErrorView`](../../lib/components/views/service_error_view.dart)**：

```dart
if (status.error != null) {
  return ServiceErrorView(
    error: status.error,
    onRetry: () => ref.read(uspDmzProvider.notifier).fetch(forceRemote: true),
  );
}
```

`ServiceErrorView` 內部已經呼叫 `localizeServiceError`，你不用自己譯。它顯示：error 圖示 + `loc(ctx).failedToLoadSettings` 標題 + 在地化細節 + retry 按鈕。

**(B) AsyncValue 頁面 → 在 `.when(error:)` 裡呼叫 `localizeServiceError`**：

```dart
asyncState.when(
  loading: () => const Center(child: AppLoader()),
  error: (error, stack) => _buildError(context, ref, error),  // error 是 Object
  data: (state) => _buildContent(context, ref, state),
);

Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
  return Center(child: Column(children: [
    AppIcon.font(Icons.error_outline, size: 48, color: ...error),
    AppText.titleMedium(loc(context).failedToLoadSettings),
    AppText.bodyMedium(localizeServiceError(context, error)),  // ← 在地化
    AppButton(label: loc(context).retry, onTap: () => ref.invalidate(uspAdminProvider)),
  ]));
}
```

> **為什麼有兩種？** `ServiceErrorView` 吃 `ServiceError?` 並由 `state.error` 驅動；`AsyncValue.when(error:)` 給的是 `Object error`（且 retry 用 `ref.invalidate` 而非 `fetch(forceRemote)`）。所以 AsyncValue 頁面保留各自的小 `_buildError`，但**內容必須照上面這段、一律走 `localizeServiceError`**——不要自己寫死英文。
> `localizeServiceError` 第二個參數收 `Object`（防御式）：非 ServiceError 會 fallback 到 `errorUnexpected`，所以 AsyncValue 直接把 `Object error` 丟進去是安全的。

### 3.2 save 失敗的顯示 → snackbar

範本：[`usp_dmz_view.dart`](../../lib/page/dmz/views/usp_dmz_view.dart) `_onSave`

主流寫法是 **try/catch 包 `notifier.save()`**：

```dart
Future<void> _onSave(BuildContext context, WidgetRef ref) async {
  try {
    await doSomethingWithSpinner(context, ref.read(uspDmzProvider.notifier).save());
    if (context.mounted) {
      showSuccessSnackBar(context, loc(context).dmzSettingsSaved);
    }
  } catch (e) {
    if (context.mounted) {
      showFailedSnackBar(context, localizeServiceError(context, e));  // ← 在地化
    }
  }
}
```

- ✅ `showFailedSnackBar(context, localizeServiceError(context, e))`
- ❌ `showFailedSnackBar(context, 'Failed to save: $e')`（直接攤平字串，不在地化）

`showFailedSnackBar` / `showSuccessSnackBar` 簽名是 `(BuildContext, String)`——它們吃已經譯好的字串，不負責翻譯。

> **重點是「字串一律經 `localizeServiceError`」，用哪個 snackbar API 是次要的。** 多數頁面用共用的 `showFailedSnackBar`（建議照此），少數頁面（如 [`instant_privacy_view.dart`](../../lib/page/instant_privacy/views/instant_privacy_view.dart)）直接用 `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localizeServiceError(context, e))))`。兩種都正確——關鍵不變：**顯示的字串來自 `localizeServiceError`，不是 raw `'$e'`**。

### 3.3 dashboard card 的 mutation → 用共用 helper `performUspMutation`

dashboard card（網路狀態、WiFi、port forwarding…）上的 inline 動作按鈕（如「續訂租約」、「新增保留」）**不是**自己寫 try/catch，而是呼叫共用 helper [`performUspMutation`](../../lib/page/_shared/components/usp_mutation_helper.dart)。它把「設 loading 狀態 → 跑 mutation → 成功/失敗 snackbar」包成一個入口：

```dart
// 範本：usp_network_status_card.dart 的「續訂租約」按鈕
onTap: () => performUspMutation(
  context,
  ref,
  loadingKey: 'wanRenew',                                   // 對應 uspMutationLoadingProvider
  mutation: () => ref.read(uspInternetSettingsProvider.notifier).renewDhcpLease(),
  successMessage: loc(context).xxx,                         // 傳「已 loc() 的字串」
),
```

**這不是「第三種在地化策略」——它只是 card 觸發 mutation 的便利入口。** 失敗時 helper 內部已經呼叫 `localizeServiceError`，所以：

- ✅ **你不用自己 localize 失敗訊息**——傳 `mutation` 即可，helper 會把拋出的 `ServiceError` 在地化後顯示。
- ⚠ **`successMessage` 是 as-is 顯示**（helper 不翻譯它）——所以**呼叫端要傳已經 `loc()` 過的字串**，不要傳寫死英文。
- 適用場景：dashboard card 上的單一 inline 動作（非整頁 form save）。整頁 form save 仍走 §3.2 的 view try/catch。

> 這個 helper 是 §0 那條「Service → Provider → View」主線在 card 場景的封裝：mutation 內部一樣經過 Service（拋 ServiceError）→ Provider（rethrow）→ helper 的 catch（`localizeServiceError`）。

---

## 4. 該顯示什麼／不該顯示什麼

這是本文最重要的原則。錯誤資訊分兩種用途，**永遠分開**：

| | 給使用者看（UI） | 給工程師看（log/debug） |
|---|---|---|
| 內容 | 由 **ServiceError 型別** 決定的一句 l10n 句 | `code`（fault code）、`detail`（firmware 原文 / WASM 技術字串） |
| 怎麼來 | `localizeServiceError(context, error)` | `logger.e(..., error: e)`、`'$e'`（toString） |
| 在地化 | ✅ 一定（26 locale） | ❌ 不在地化（firmware 英文技術字串，無從翻） |

**規則**：
1. **UI 顯示的訊息由型別決定**，不顯示 `detail` / `code`。使用者看到「找不到此設定」，不是 `'Unexpected error: ...(code: 7026)'`。
2. **`detail` / `code` 只進 log**。它們是診斷原料，是 firmware 英文技術字串，給使用者看既看不懂也無法在地化。
3. **唯一例外：`UnexpectedError`**。它是 fallback，沒有型別語意，所以 `localizeServiceError` 會顯示它的 `detail`（若有），否則退到 `errorUnexpected`。這是刻意的妥協——unmapped 的錯誤至少給點線索。

### 4.1 中央 mapper 長怎樣（`localizeServiceError`）

```dart
String localizeServiceError(BuildContext context, Object error) {
  final l = loc(context);
  if (error is! ServiceError) return l.errorUnexpected;   // 防御
  return switch (error) {
    NotAuthenticatedError()      => l.errorNotAuthenticated,
    InvalidCredentialsError()    => l.errorInvalidCredentials,
    SessionTokenExpiredError()   => l.errorSessionExpired,
    InvalidSessionTokenError()   => l.errorInvalidSessionToken,
    UnauthorizedError()          => l.errorUnauthorized,
    ResourceNotFoundError()      => l.errorResourceNotFound,
    InvalidInputError()          => l.errorInvalidInput,
    NetworkError()               => l.errorNetwork,
    ConnectivityError()          => l.errorConnectivity,
    TimeoutError()               => l.errorTimeout,
    ServiceNotInitializedError() => l.errorServiceNotReady,
    // batch：顯示第一筆的具體錯誤（見 §4.2）
    UspPartialFailureError(:final failures)  => _localizeBatch(context, failures),
    UspCompleteFailureError(:final failures) => _localizeBatch(context, failures),
    // fallback：唯一顯示 detail 的型別
    UnexpectedError(:final detail) => detail ?? l.errorUnexpected,
    StorageError()               => l.errorUnexpected,   // 不會到 UI（session/auth 層攔下）
    SerialNumberMismatchError()  => l.errorUnexpected,   // 同上
  };
}
```

`switch` 對 sealed `ServiceError` **窮舉**——這是設計重點：新增子類時編譯器會警告這裡少一個 case，**強制你補 l10n**，不會漏。

### 4.2 batch 錯誤：顯示第一筆的具體訊息

`Usp*FailureError` 內含多筆 `failures`。**策略：一律顯示 `failures.first` 的具體錯誤**（依其 `errorCode` 譯成對應 l10n 句）。

- ❌ 不用「N 項設定失敗」——籠統、使用者無從修起。
- ✅ 顯示第一筆的具體錯誤；使用者修掉後若還有第二筆，下次 save 會再顯示下一筆——仍有跡可循。

```dart
String _localizeFaultCode(BuildContext context, int code) => switch (code) {
  7004 || 7005 || 7006 || 9008 => loc(context).errorInvalidInput,
  7026 || 7027 || 9005 || 9007 => loc(context).errorResourceNotFound,
  9001                         => loc(context).errorUnauthorized,
  9999                         => loc(context).errorNetwork,
  _                            => loc(context).errorUnexpected,   // 未知 vendor code 不洩漏原文
};
```

---

## 5. 達成 Localization

1. **框架**：專案用 `flutter_localizations`（`loc(context).xxx`），**不用 slang**。（曾評估遷移 slang，因「無 context 翻譯」需求實測為 0、遷移成本高，ROI 為負 → 維持現狀。所有 error 文案都在 View 層用 context 翻譯。）
2. **ARB key**：error 訊息的 key 在 `lib/l10n/app_en.arb`，命名 `errorXxx`（camelCase）。現有的 12 個通用 key：
   ```
   errorNotAuthenticated, errorInvalidCredentials, errorSessionExpired,
   errorInvalidSessionToken, errorUnauthorized, errorResourceNotFound,
   errorInvalidInput, errorNetwork, errorConnectivity, errorTimeout,
   errorServiceNotReady, errorUnexpected
   ```
   外加共用：`failedToLoadSettings`、`retry`。
3. **多語**：英文 key 補進 `app_en.arb` 後，其餘 25 個 locale（`app_es.arb` / `app_ja.arb` …）一併補翻譯。

**多數情況你不用新增 error key** —— 既有 12 個型別已涵蓋常見錯誤。只有在新增 ServiceError 子類時才需要（見 §6）。

---

## 6. 新增一個 ServiceError 子類（少見）

只有當既有型別都無法表達某種錯誤語意時才做。步驟：

1. 在 [`service_error.dart`](../../lib/core/errors/service_error.dart) 新增 `final class XxxError extends ServiceError`，帶 `{super.code, super.detail}`。
2. **編譯**：`localizeServiceError` 的 `switch` 會立刻警告少一個 case（sealed 強制）。
3. 在 `app_en.arb` 新增對應的 `errorXxx` key（+ 其餘 locale 翻譯）。
4. 在 `switch` 補上 `XxxError() => l.errorXxx`。
5. 在 Service 層適當處 `throw XxxError(...)` 或在 `mapUspErrorToServiceError` 補映射。

> ⚠ 新增前先想清楚：是「真的需要新型別」還是「既有型別 + 不同 l10n 句」就夠？型別是給「整個 app 一致對待」用的，不是給單一頁面客製文案用的。

---

## 7. 重要注意事項與陷阱（Do & Don't）

| Do ✅ | Don't ❌ |
|---|---|
| Service `catch → throw mapUspErrorToServiceError(e)`（fetch） | Service 把 raw 字串／`Exception` 往上拋 |
| Service save 用 `if (e is ServiceError) rethrow` 守衛 | save 漏守衛 → 自拋的 ServiceError 被誤包成 UnexpectedError |
| batch 存完整 `failures` list | 只存 `failedPaths` 字串（errorCode 流失） |
| Provider fetch 存 `state.error = e`（型別） | Provider `errorMessage: '$e'`（型別遺失，無法在地化） |
| `copyWith` 清 error 用 `clearError: true` | 傳 `error: null` 想清空（被 `?? this.error` 吃掉，清不掉） |
| View 一律 `localizeServiceError(context, e)` | View 寫死 `'Failed to save: $e'` / `'Unable to load X'` |
| `detail`/`code` 只進 `logger.e(..., error: e)` | 把 `detail`/`code` 顯示給使用者（firmware 英文技術字串） |
| 跟著頁面既有 state 架構選 §3.1 (A) 或 (B) | 為了 error handling 改頁面架構 |

### 已知限制

- **GET 9999→9998 bug（未修）**：GET 連線失敗（9999，應為「網路錯誤」）在傳輸層第 5 層被偽裝成 9998 → 最終被在地化成「輸入錯誤」（`errorInvalidInput`）。這是 transport 層 bug，與 localization 獨立。在它修掉前，**GET 失敗的「輸入錯誤」訊息可能其實是連線問題**。根因見 [`usp-error-handling-reference.md`](usp-error-handling-reference.md) §2.5。
- **`_localizeFaultCode` 與 `_mapProtocolError` 必須同步**：fetch 路徑（字串 → `mapUspErrorToServiceError` 的 `_mapProtocolError`）與 save batch 路徑（envelope → `localizeServiceError` 裡的 `_localizeFaultCode`）對同一個 firmware code 必須給一致結果。改其中一個，另一個要一起改。`_localizeFaultCode` 的 doc comment 已標明「Mirrors `_mapProtocolError` … MUST stay in sync」；反向（`usp_error.dart` 那側）目前**沒有**回指的提醒，改 `_mapProtocolError` 時要自己記得回頭同步 `_localizeFaultCode`。

### 不在此 pipeline 範圍

- **firmware_update**：流程文案多，有自己的 exception + state-driven 錯誤顯示，另開 scope。
- **SSE subscription errors**：另一條 error path（伺服器推播），不走此 pipeline。
- **instant_setup（pnp_* wizard）**：仍用各自的 `errorMessage` + `ref.listen` 顯示，未納入。
- **field-level 表單驗證**：`validateForm` 的 `Map<String,String>` 走 `fieldErrors`，不是 ServiceError（見 §1.4）。

---

## 8. PR 前 Checklist

- [ ] Service 的 fetch `catch → throw mapUspErrorToServiceError(e)`；save 有 `is ServiceError` 守衛。
- [ ] batch 失敗存完整 `failures` list（不是只存 path）。
- [ ] state model 用 `ServiceError? error`，不是 `String? errorMessage`；`copyWith` 有 `clearError`。
- [ ] Provider 不出現 `'$e'` / `errorMessage: '...'`；fetch 存型別、save rethrow。
- [ ] View 的 fetch 失敗走 `ServiceErrorView`（state.error）或 `_buildError + localizeServiceError`（AsyncValue）。
- [ ] View 的 save 失敗走 `showFailedSnackBar(context, localizeServiceError(context, e))`。
- [ ] dashboard card 的 inline 動作用 `performUspMutation`（失敗它已自動 localize），`successMessage` 傳已 `loc()` 的字串。
- [ ] 沒有任何寫死的英文錯誤字串（`'Unable to load...'`、`'Failed to save: $e'`、`'Error: $e'`）。
- [ ] 若新增 ServiceError 子類：補 ARB key（含其餘 locale）+ `switch` case。
- [ ] `flutter analyze` 無 warning（特別是 sealed switch 的 exhaustiveness）。

---

## 附錄：關鍵檔案

| 檔案 | 角色 |
|---|---|
| [`lib/core/errors/service_error.dart`](../../lib/core/errors/service_error.dart) | sealed `ServiceError` 型別定義 |
| [`lib/core/usp/errors/usp_error.dart`](../../lib/core/usp/errors/usp_error.dart) | `mapUspErrorToServiceError`（字串 → ServiceError） |
| [`lib/components/localizations/service_error_localizations.dart`](../../lib/components/localizations/service_error_localizations.dart) | `localizeServiceError`（中央 mapper，唯一在地化點） |
| [`lib/components/views/service_error_view.dart`](../../lib/components/views/service_error_view.dart) | `ServiceErrorView`（fetch 失敗共用空狀態 widget） |
| [`lib/page/dmz/`](../../lib/page/dmz/) | Type A（state.error）完整範本：service / notifier / view |
| [`lib/page/admin/`](../../lib/page/admin/) | AsyncValue（AsyncValue.error）範本 |
| `lib/l10n/app_en.arb` | error 訊息 ARB key（`errorXxx`） |
