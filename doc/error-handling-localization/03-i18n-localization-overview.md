# i18n 框架決策與 Error 訊息地基

> **範圍：** 本檔只保留與 **error handling localization** 直接相關的部分（i18n 框架選型、error 訊息地基進度）。
> 原檔的全專案一般 hardcoded strings 稽核（~460 筆 title/label/流程文案）已移除——那屬於一般 i18n 工作，與 error handling 無關。
> **方法回顧：** error 訊息的地基（ServiceError 型別化）是整個 i18n 計畫中與 error handling 交集的部分，已於近期重構完成（見 §2）。

---

## 1. 框架決策：維持 flutter_localizations（不遷移 slang）

error 訊息的 localization 走的是專案既有的 **flutter_localizations**（`loc(context).xxx`）機制，**不遷移 slang**。

- 遷移 slang 的觸發動機是「無 context 翻譯」，但本專案此需求**實測為 0**——所有錯誤文案都可（且應）在 View 層用 context 翻譯，notifier/service 只回型別（見 §2 的 ServiceError 重構）。
- flutter_localizations **也能**無 context（`AppLocalizations.delegate.load` 等），非 slang 獨佔。
- 遷移成本中-大（361 處呼叫改寫 + 12 個 rich-text key 需重新設計 parser + 單作者 bus-factor 風險），換到的主要是 DX 甜度 → ROI 為負。
- 結論：**不遷移**。真問題是「開發紀律 + notifier 架構」，不是框架。

> 對 error handling 的意涵：所有 error 訊息一律用 `loc(context).errorXxx`，由 View 層翻譯。

---

## 2. Error 訊息地基（已完成）

「真正該做的事」之一是**重構 notifier/service 錯誤模型，讓 View 用 `loc()` 翻譯**。這部分的地基已重構完成：

- `ServiceError` 基類加 `code` / `detail`（診斷用），移除 5 子類各自的 `message`、統一 `detail`。
- `mapUspErrorToServiceError` 各 `_mapXxx` 保留 `code` + `detail`。
- `UspCompleteFailureError` / `UspPartialFailureError` 改存 `List<UspErrorDetail> failures`（完整 path+code+message）。
- **結果：firmware fault code / 原始訊息不再流失到 ServiceError**——View 之後能依型別 + code 產出在地化訊息。

> 完整設計見 `02-serviceerror-diagnostic-fields-DONE.md`；localization 大方向見 `01-usp-error-roundtrip-reference.md` §4；橫切執行規劃見 `04-error-message-localization-plan.md`。

---

## 3. Error 訊息樣本（重構前的痛點，已解決）

重構前散落各 view 的 hard-coded 英文錯誤訊息（high 嚴重度，使用者最常見）：

```
dmz/usp_dmz_view.dart        'Unable to load DMZ settings'
firewall/usp_firewall_view.dart  'Unable to load firewall settings'
dashboard/usp_dashboard_view.dart  'Unable to load USP data'
instant_privacy_view.dart    'Failed to enable Instant Privacy: $e'
```

這些已由 04 的橫切重構統一成：fetch 失敗走 `ServiceErrorView`、save 失敗走 `localizeServiceError` + snackbar，全部 `loc(context)` 在地化。

---

## 4. 根因（為何錯誤訊息會散落寫死）

- **USP 遷移頁面未沿用 l10n 慣例**：`loc(context)` 機制健全，但新 USP feature 快速開發時直接寫死英文、未補 ARB key。
- **notifier 直接組裝錯誤文案**（架構缺口）：~35–40 個 notifier 在無 context 處寫死英文錯誤——這是 §2 重構在解的問題，非框架問題。

---

## 5. 判準邊界：Service 層 error 文本不在地化

| 類別 | 範例 | 處置 |
|---|---|---|
| Service 層 error 文本（firmware 原文 / WASM 技術字串） | `ServiceNotInitializedError('USP service not available')`、firmware fault message | **不在地化**（自 firmware、非 App 決定；存在 `detail` 供 log/debug，不直接顯示給使用者） |

> 對應原則：UI 顯示的訊息由 **ServiceError 型別** 決定（一句 l10n），`detail`/`code` 純診斷。唯一例外是 `UnexpectedError`（fallback 無型別語意）可退而顯示 `detail`。詳見 `01` §4.1。
