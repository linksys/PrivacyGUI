# 修改規劃：ServiceError 保留診斷用 code / detail

> **狀態：已完成實作。** 最終決策與下方原規劃有兩處不同，以本段為準：
> 1. **移除 5 子類的 `message` 欄位，統一用基類 `detail`**（原規劃曾傾向「不整併」，後改為整併——因 `message`/`detail` 語意重疊，且 `UnexpectedError` 這種「無法靠型別決定友好字串」的 fallback 正好該用 `detail` 顯示）。
> 2. **全部子類**都加 `{super.code, super.detail}`（含非 USP 路徑）。
>
> 實作結果：
> - 基類 `ServiceError` 加 `int? code` / `String? detail`。
> - 5 子類（InvalidInput/Network/Connectivity/ServiceNotInit/Unexpected）移除自身 `message`，toString 改讀 `detail`；InvalidInput 保留 `field`、Unexpected 保留 `originalError`。
> - `UspCompleteFailureError`/`UspPartialFailureError` 改存 `List<UspErrorDetail> failures`，`failedPaths` 變衍生 getter（向後相容）。
> - `mapUspErrorToServiceError` 各 `_mapXxx` 補傳 `code`（faultCode/httpStatus）+ `detail`。
> - 影響：lib/ ~37 建構點 + 5 讀取點（login `.detail`、diagnostics 4 處解構）+ 14 service 的 throw + test/ 建構點。全部 `message:`→`detail:`、`failedPaths:`→`failures:` 機械改名。
> - 驗證：`flutter analyze` 全專案 0 error；service/notifier 測試 1046 全過（2 個無關的 UI card 測試不計）。
> - login flow 的 `UnexpectedError.detail`（原 message，存 error code 字串做邏輯判斷）功能不變，只是欄位改名。

---

# （以下為原規劃，部分已被上方最終決策覆蓋）

# 修改規劃：ServiceError 保留診斷用 code / message

> 目標：修補「錯誤匯流到 ServiceError 後，firmware 的 code / message 流失」的問題。
> 範圍：**只做診斷層（保留 code + message 供 log/debug）**。UI 友好訊息（l10n + View）是日後另一個 scope。
> 設計決策：方案 A（基類加可選欄位）+ 路徑 2 改存 `List<UspErrorDetail>`。

---

## 一、現況問題（兩條路徑的流失）

- **路徑 1（fetch / 字串 → `mapUspErrorToServiceError`）**：`UspError` 有 `{category, faultCode, httpStatus, message, rawError}`，但映射後：
  - `InvalidInputError` / `NetworkError` / `UnexpectedError`：保留 message，**但 faultCode 丟掉**。
  - `ResourceNotFoundError()` / `UnauthorizedError()`：**空建構子，code 和 message 全丟**。
- **路徑 2（寫入 / envelope → `UspResultParser`）**：`UspErrorDetail{requestedPath, errorCode, errorMessage}` 是逐筆完整的，但轉成 `Usp*FailureError` 時：
  - `failedPaths` 只取 path → **errorCode 全丟、errorMessage 只殘存在 summary 串接字串裡**。

---

## 二、設計決策（已確認）

1. **方案 A**：基類 `ServiceError` 加**可選** `code` / `detail` 欄位，子類透過 `super(...)` 傳；不在 28 個子類各自重複宣告。
2. **路徑 2**：`UspCompleteFailureError` / `UspPartialFailureError` 改存 `List<UspErrorDetail>`（完整三元組），取代「只存 path 字串」。
3. **不在建立 object 時決定友好字串**——service 層無 `BuildContext`，l10n 屬 View scope。這兩個型別只是「容器」，未來 View 會「往裡讀 `errorCode`」決定友好字串（與其他子類「switch 型別」不同）。

---

## 三、命名：用 `code` / `detail`，不用 `message`

⚠ **不能叫 `message`**，因為會跟現有子類的 `message` 欄位衝突，且語意要區分：
- `detail`：診斷用的原始技術字串（firmware 原文 / WASM 字串），**不給使用者看**。
- `code`：診斷用的數字 code（faultCode / errorCode）。

現有子類的 `message`（`InvalidInputError.message` 等）語意是「給 toString 用的描述」，與「診斷 detail」概念重疊。處理見第四節。

---

## 四、逐項改動

### 4.1 基類 `ServiceError`（service_error.dart）

```dart
sealed class ServiceError implements Exception {
  /// 診斷用：原始 fault code（firmware 7xxx/9xxx、WASM 9999、codegen 9998 等）。null=無 code。
  final int? code;
  /// 診斷用：原始技術訊息（firmware 原文 / WASM 字串）。僅供 log/debug，不直接顯示給使用者。
  final String? detail;

  const ServiceError({this.code, this.detail});

  @override
  String toString() { /* 維持現有類名自動轉換邏輯；可在結尾附 detail 供 log */ }
}
```
- 基類 toString **維持現狀**（類名→英文），可選擇在有 `detail` 時附加 `（detail）` 方便 log；UI 不依賴它（之後走 l10n）。

### 4.2 既有帶 `message` 的子類——**維持不動（修正：不整併）**

> ⚠ 實作前盤點發現：`message:` 建構點有 **70+ 處**，且 `UnexpectedError.message` 被 `login_local_view`（JNAP 登入流程，非 USP）讀取。
> 若把 `message` 改名/整併成 `detail`，要改動 70+ caller 且風險高，**不值得**。

修正策略：**`InvalidInputError` / `NetworkError` / `UnexpectedError` / `ConnectivityError` / `ServiceNotInitializedError` 完全不動**。
它們本來就保留 `message`，**沒有流失問題**。基類新增的 `detail` 只服務「原本沒有任何訊息欄位」的子類（見 4.3）。

結果：
- `code`：所有子類可選（基類提供），純診斷。
- `detail`：給「原本連 message 都沒有」的子類用（ResourceNotFound/Unauthorized/auth 類…）。
- 已有 `message` 的子類：維持 `message`，不碰。`code` 仍可透過 super 傳（見 4.3 統一加 super）。

**保留不動的專屬欄位**：`InvalidResetCodeError.attemptsRemaining`、`SerialNumberMismatchError.expected/actual`、`UnexpectedError.originalError/message`、`StorageError.originalError`、`InvalidInputError.field/message`。

### 4.3 空建構子子類——可傳 code/detail（路徑 1 的主要修補）

`ResourceNotFoundError` / `UnauthorizedError` 等改成可選帶 super：
```dart
final class ResourceNotFoundError extends ServiceError {
  const ResourceNotFoundError({super.code, super.detail});
}
```
（其餘 auth 類 `NotAuthenticatedError` 等同樣加 `{super.code, super.detail}`，純機械式。）

### 4.4 `mapUspErrorToServiceError`（usp_error.dart）——路徑 1 傳入 code/detail

每個 `_mapXxx` 產出時帶上 `UspError` 的 `faultCode` 與 `message`：
```dart
7026 => ResourceNotFoundError(code: e.faultCode, detail: e.message),
7004 => InvalidInputError(code: e.faultCode, detail: e.message),
... // 其餘同理
```
- transport 類帶 `httpStatus`（當 code）或 `faultCode`。
- 這樣路徑 1 的 code/detail 不再流失。

### 4.5 路徑 2 兩個型別改存 `List<UspErrorDetail>`

```dart
final class UspCompleteFailureError extends ServiceError {
  final String summary;                  // 保留：人類可讀摘要（log/既有 caller）
  final List<UspErrorDetail> failures;   // 新增：完整三元組
  List<String> get failedPaths => failures.map((f) => f.requestedPath).toList(); // 衍生，向後相容
  const UspCompleteFailureError({required this.summary, required this.failures});
}
final class UspPartialFailureError extends ServiceError {
  final String summary;
  final List<String> successPaths;        // 成功只存路徑（已決定，見爭議點 1）
  final List<UspErrorDetail> failures;    // 失敗存完整三元組
  List<String> get failedPaths => failures.map((f) => f.requestedPath).toList();
  const UspPartialFailureError({required this.summary, required this.successPaths, required this.failures});
}
```
- **`failedPaths` 改為衍生 getter** → 既有讀 `.failedPaths` 的 caller（grep 確認 lib 內無人讀，只有 port_triggering view 讀的是另一個 `rule.summary`）不受影響。
- `import` `UspErrorDetail`（來自 usp_operation_result.dart）。

### 4.6 各 service 的 throw 點（14 個檔案，機械式）

現況統一是：
```dart
throw UspPartialFailureError(
  summary: '... : $errorSummary',
  successPaths: successes.map((s) => s.requestedPath).toList(),
  failedPaths: failures.map((f) => f.requestedPath).toList(),
);
```
改成直接傳 list（`failures` / `successes` 變數在 switch case 已綁定）：
```dart
throw UspPartialFailureError(
  summary: '... : $errorSummary',
  successes: successes,
  failures: failures,
);
```
- 涉及檔案（grep 確認）：admin, dmz, firewall, dhcp, instant_safety, instant_privacy, ipv6_port_service, local_network, port_forwarding, internet_settings, static_routing, wifi_settings, usp_firmware_update_service。
- **特例**：`firmware_ws_upload_strategy.dart` 是從 WS message 建（非 `UspErrorDetail`），現傳 `failedPaths: const []`——改成 `failures: const []`，summary 維持。

### 4.7 測試

- 既有 test 斷言 `isA<UspCompleteFailureError>()`、`.failedPaths`、`.summary`：因 `failedPaths` 保留為 getter、`summary` 不變，**多數測試不需改**。
- 需確認建構子改名（`failedPaths:` → `failures:`）的測試——若 test 直接 `UspCompleteFailureError(summary:..., failedPaths:...)` 建物件，要改成 `failures:`。
- 新增：驗證 code/detail 有被保留（路徑 1：map 後 code 非 null；路徑 2：failures 含完整 errorCode）。

---

## 五、爭議點 / 待你拍板

1. ~~`UspPartialFailureError.successPaths` 要不要改存 `List<UspSuccessDetail>`？~~ **已決定：維持 `successPaths`（只存路徑）**。成功項沒有 code/message 可診斷，存完整 detail 純為對稱而無實際價值。
2. ~~非 USP 子類要不要加 super？~~ **已決定：全部子類都加 `{super.code, super.detail}`**（含非 USP 路徑的 OTP/admin/Storage 等）。理由：一致性，避免日後困惑「為何這幾個有那幾個沒有」。非 USP 路徑只是暫時沒人傳值，欄位留著無害。
3. ~~基類 toString 是否附 detail？~~ **已決定：不動 toString**。維持現狀（類名→英文），`detail` 純供 logger 主動讀，不改變 `'$e'` 輸出。UI 字串是日後 l10n scope。

---

## 六、影響範圍總結

| 檔案 | 改動 |
|---|---|
| `lib/core/errors/service_error.dart` | 基類加 `code`/`detail`；~6 個子類整併 message→detail；空建構子加 super；2 個 Usp*FailureError 改存 list + getter |
| `lib/core/usp/errors/usp_error.dart` | `_mapXxx` 各 case 傳入 `code`/`detail` |
| `lib/page/*/services/*.dart`（14 檔） | throw Usp*FailureError 改傳 `failures`/`successes` |
| `test/**`（~7 檔） | 建構子參數改名處跟改；新增 code/detail 保留斷言 |

**風險**：低。`failedPaths` 用 getter 向後相容，`summary` 不變，多數 caller/test 不受影響。最大宗是 14 個 service 的機械式改名 + 確保 import。
