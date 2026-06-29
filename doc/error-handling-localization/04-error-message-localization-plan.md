# Error Message Localization — 橫切重構執行規劃

> **目標：** 把所有 USP feature 的錯誤訊息統一成「Service 拋 ServiceError → Provider 透傳型別 → View 用共用 mapper + `loc(context)` 翻譯」，取代現在散落的 hard-coded 英文字串。
> **前置已完成：** `ServiceError` 子類都帶 `code`/`detail`；`Usp*FailureError` 帶 `failures` list（診斷資訊已保留）。
> **方法：** 橫切（先把 error 這條線跨所有 feature 打通），不照 PR #924，依本規劃。

---

## 0. 核心原則（討論定案）

1. **轉換點在 Service 層**：`catch (e) => throw mapUspErrorToServiceError(e)` 已存在，**不動**。Service 之後流動的一律是 `ServiceError` 物件。
2. **Provider 只透傳，不加工**：
   - fetch 失敗：`on ServiceError catch (e) => state.copyWith(error: e)`（存物件，**不再 `'$e'`**）
   - save 失敗：`rethrow`（原樣往上拋，View 的 try/catch 接）
   - **不碰 BuildContext、不轉字串、不組文案、不再呼叫 mapUspErrorToServiceError**
3. **View 是唯一 localize 的地方**：拿到 `ServiceError`（從 `state.error` 或 save 的 catch），丟給**共用 mapper** `localizeServiceError(context, error)` 取得友好字串。
4. **共用元件**：一個 mapper + 一個 fetch 失敗空狀態 widget，取代現在 18 份各自的 `_buildError` 與重複的 translate helper。

---

## 1. 現況（盤點結論）

| 層 | 現況 | 問題 |
|---|---|---|
| Service | `throw mapUspErrorToServiceError(e)` | ✅ 已正確，不動 |
| State model | 16 feature 全用 `String? errorMessage` | ❌ 型別遺失 |
| Provider (fetch) | `errorMessage: '$e'`（把 ServiceError 壓成字串） | ❌ 斷點在此 |
| Provider (save) | 已 `rethrow` | ✅ 大致正確 |
| View (fetch 空狀態) | 18 個各自的 `_buildError` 顯示 `errorMessage` 字串 | ❌ hard-coded + 重複 |
| View (save snackbar) | `showFailedSnackBar(ctx, 'Failed to save: $e')` ~10 處逐字重複 | ❌ hard-coded |
| diagnostics | provider 用 `_xxxErrorMessage(e, host)` switch on 型別、組寫死英文、壓字串 | ⚠ 已 switch 型別，但在錯的層、錯的形式 |

**關鍵斷點**：Service 給的好好的 `ServiceError`，被 Provider 的 `'$e'` 壓平 → 我們保留的 code/detail/型別全失。橫切就是打通這個斷點。

---

## 2. 要新增的 ServiceError 子類

盤點後，**只需要新增 1 個**（不照 PR #924 加 2 個）：

### `TimeoutError`（新增）
- **理由**：diagnostics 的 timeout 目前用 Dart 內建 `TimeoutException`（不是 ServiceError），所以 View 無法用型別統一翻譯。需把它收進 ServiceError 體系。
- **不叫 `DiagnosticTimeoutError`**：timeout 是通用概念（任何操作都可能 timeout），不該綁 diagnostics。放共用。
- 欄位：`super.code, super.detail`（沿用基類），可選 `operation`/`host` 視 l10n 需要——**先不加特化欄位**，l10n 文案用「操作名」當參數由 View 傳即可（見 §4）。

### ❌ 不新增 `SpeedTestStatusError`
- PR #924 為 speed test 的 `Error_NoResponse` 等 router 業務狀態建了專屬子類。
- **判定不需要**：那是 **operate 成功完成、但 router 回報業務失敗**（`downloadStatus != 'Complete'`），屬 speed test 領域邏輯，不是 transport/protocol 錯誤。**留在 diagnostics 自己用 loc() 翻譯**（speed test 專屬 l10n key），不污染 ServiceError 體系。

### 既有子類已夠用
diagnostics 的 `InvalidInputError`/`NetworkError`/`ConnectivityError` 都已存在，CRUD 的 fetch 失敗也是這些既有型別。

---

## 3. 共用元件設計（新增）

### 3.1 `localizeServiceError(BuildContext, ServiceError) → String`
位置：`lib/components/`（已定案）。放 components 而非 core，因它依賴 l10n + BuildContext，core 不該依賴 UI 層。
做法：`switch` on sealed subtypes → `loc(context).xxx`。
```dart
String localizeServiceError(BuildContext ctx, ServiceError e) => switch (e) {
  NotAuthenticatedError()    => loc(ctx).errorNotAuthenticated,
  InvalidCredentialsError()  => loc(ctx).errorInvalidCredentials,
  SessionTokenExpiredError() => loc(ctx).errorSessionExpired,
  UnauthorizedError()        => loc(ctx).errorUnauthorized,
  ResourceNotFoundError()    => loc(ctx).errorResourceNotFound,
  InvalidInputError()        => loc(ctx).errorInvalidInput,
  NetworkError()             => loc(ctx).errorNetwork,
  ConnectivityError()        => loc(ctx).errorConnectivity,
  TimeoutError()             => loc(ctx).errorTimeout,
  ServiceNotInitializedError() => loc(ctx).errorServiceNotReady,
  // batch：遍歷 failures，依 code helper 聚合（見 §3.3）
  UspCompleteFailureError(:final failures) => _localizeBatch(ctx, failures),
  UspPartialFailureError(:final failures)  => _localizeBatch(ctx, failures),
  // fallback：UnexpectedError 無型別語意，顯示 detail（若有），不附 code（code 留 log）
  UnexpectedError(:final detail) => detail ?? loc(ctx).errorUnexpected,
  _ => loc(ctx).errorUnexpected,
};
```
- sealed class 的好處：未來新增子類時 `switch` 編譯警告，強制補 l10n。
- **單一定義**，全 codebase 共用——取代 PR #924 的多份 `_translateError` 複製。

### 3.2 fetch 失敗空狀態 widget（新增）
取代 18 個各自的 `_buildError`。簽名約：
```dart
class ServiceErrorView extends StatelessWidget {
  final ServiceError error;
  final VoidCallback onRetry;
  // 顯示：loc(ctx).failedToLoadSettings 標題 + localizeServiceError(ctx,error) 細節 + retry 按鈕
}
```
- 標題用既有 `loc(ctx).failedToLoadSettings`、按鈕用既有 `loc(ctx).retry`（ARB 已有）。
- 細節用 `localizeServiceError`。

### 3.3 batch `_localizeBatch(ctx, List<UspErrorDetail>)`（策略已定案）
- **定案策略：一律顯示第一筆 `failures.first` 的具體訊息**（依其 `errorCode` 用 `UspErrorDetail` 的 `isObjectNotFound`/`isInvalidParameterValue`/`isParameterNotWritable` 等 helper 判，翻成對應 l10n 句）。
- **不用「N 項失敗」聚合句**：那種籠統訊息使用者無從修起。顯示第一筆的具體錯誤，使用者修掉後若還有第二筆，下次 save 會再顯示下一筆——仍看得到具體訊息、有跡可循。
- `failures` 為空（極端 edge case）→ 退回 `loc(ctx).errorUnexpected`。

### 3.4 save snackbar
`showFailedSnackBar(ctx, localizeServiceError(ctx, error))` 取代 `'Failed to save: $e'`。
（`showFailedSnackBar` 簽名不變，仍吃 String，只是改傳 localized 字串。）

---

## 4. 要新增的 ARB key（app_en.arb，camelCase）

通用 error（對應 §3.1 各型別）：
```
errorNotAuthenticated, errorInvalidCredentials, errorSessionExpired,
errorInvalidSessionToken, errorUnauthorized, errorResourceNotFound,
errorInvalidInput, errorNetwork, errorConnectivity, errorTimeout,
errorServiceNotReady, errorUnexpected
```
既有可重用：`failedToLoadSettings`、`retry`、`generalError`、`unknownError`、speedTest 專屬那批。

> **Note**: 原規劃的 `errorBatchPartial(count)`, `errorBatchComplete(count)` 最終未採用——batch 錯誤改為顯示第一筆的具體訊息（見 §3.3），不需要聚合 key。

---

## 5. 執行順序（feature 分批）

每個 feature 的改動都是同樣三步（state model → provider → view），故分批驗證：

| 批次 | feature | 備註 |
|---|---|---|
| **共用層先行** | `localizeServiceError` + `ServiceErrorView` + `TimeoutError` + ARB key | 地基，先做 |
| **批 1（範本）** | dmz | 最單純的 Type A，建立範本後其餘照抄 |
| **批 2（CRUD）** | dhcp, firewall, port_forwarding, local_network, internet_settings, ipv6_port_service, static_routing, wifi_settings | 機械式套範本 |
| **批 3（特殊）** | instant_privacy, instant_safety, admin | save snackbar 為主 |
| **批 4（diagnostics）** | manual_tools, speed_test | 拔 `_xxxErrorMessage` helper、TimeoutException→TimeoutError、status 留 diagnostics 自譯 |
| **批 5（其他）** | ~~firmware_update~~, system_log, dashboard | system_log/dashboard 完成；**firmware_update 跳過**（流程文案多，另開 scope 處理） |

每批：改 → `flutter analyze` → 跑該 feature test → 過了再下一批。

---

## 6. 不在本次（error 線）範圍

- 非 error 的 hard-coded 字串（section 標題、表單 label、流程文案）→ 之後「以 feature 為單位」處理（見 `03-i18n-localization-overview.md`）。
- **§2.5 的 GET 9999→9998 bug → 已決定本次先不修**（使用者尚未理解該 bug，待釐清後另議）。⚠ **已知風險**：在修掉前，GET 連線失敗(9999)會被 localize 成「輸入錯誤」(InvalidInputError)，l10n 做得再好仍是錯訊息。執行 localization 時須知此限制。
- 26 locale 的翻譯 → 英文 key 補齊後另行翻譯。

---

## 7. 決策（已定案）

1. ✅ **共用元件放 `lib/components/`**（不放 core，避免 core 依賴 UI 層）。
2. ✅ **§2.5 GET bug 本次先不修**——使用者尚未理解該 bug，待釐清。風險見 §6（GET 連線失敗會被誤譯成輸入錯誤）。
3. ✅ **batch 一律顯示第一筆的具體訊息**（不用「N 項失敗」——那無從修起；修掉第一筆後下次 save 會顯示下一筆）——見 §3.3。

---

## 8. 執行結果總結（2026-06-17 完成）

### 完成項目

All USP requests (Get/Set/Add/Operate) across feature pages now flow through a unified error handling pipeline:

- **Path 1 (fetch)**: errors stored in `state.error`, displayed via `ServiceErrorView`
- **Path 2 (save)**: errors rethrown to View, displayed via snackbar with `localizeServiceError`

| 項目 | 狀態 |
|------|------|
| `ServiceError.code` / `ServiceError.detail` diagnostic fields | ✅ |
| `TimeoutError` subtype | ✅ |
| `localizeServiceError()` central mapper (exhaustive switch) | ✅ |
| `ServiceErrorView` shared widget | ✅ |
| 12 ARB keys for error messages | ✅ |
| All feature state models: `String? errorMessage` → `ServiceError? error` | ✅ |
| Providers pass through ServiceError objects (not stringify) | ✅ |
| Views use shared components | ✅ |

### 清理項目

| 刪除的 ServiceError 子類 | 原因 |
|--------------------------|------|
| `ServiceSideEffectError` | 未使用 |
| `InvalidOtpError`, `ExpiredOtpError` | OTP 流程未走 USP，未使用 |
| `AdminAccountLockedError`, `InvalidResetCodeError`, `ConsecutiveInvalidResetCodeError`, `InvalidAdminPasswordError` | Admin-password 流程未走 USP，未使用 |

### 保留但不流到 UI 的子類

| 子類 | 位置 | 說明 |
|------|------|------|
| `StorageError` | `auth_service.dart` | 包在 `AuthFailure` Result type，不流到 View |
| `SerialNumberMismatchError` | `session_service.dart` | 被 `.onError` 吞掉，只寫 log |

這兩個在 `localizeServiceError` 有明確 case（fallback to `errorUnexpected`），但實務上不會執行到。

### 範圍外

- **firmware_update**: 流程文案多，另開 scope 處理
- **SSE subscription errors**: 另一條 error path，不在此次範圍
- **UnexpectedError**: 最終 fallback，直接顯示 `detail` 原始字串（可能是英文 firmware 技術訊息，非 localized）
- **非 error 的 hard-coded 字串**: section 標題、表單 label、流程文案 → 之後「以 feature 為單位」處理
