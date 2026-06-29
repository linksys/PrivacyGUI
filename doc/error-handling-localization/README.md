# Error Handling & Localization

USP 錯誤處理與 i18n localization 的研究、決策與執行規劃。一條主線：**錯誤如何從 firmware 一路流到 UI，以及如何讓 UI 訊息在地化**。

## 閱讀順序

| # | 文件 | 性質 | 狀態 |
|---|---|---|---|
| 01 | [usp-error-roundtrip 參考](01-usp-error-roundtrip-reference.md) | 全鏈路參考：request 每層格式、error 來源/形式窮舉、現有 handling pattern、localization 大方向 | 📖 參考 |
| 02 | [ServiceError 診斷欄位](02-serviceerror-diagnostic-fields-DONE.md) | ServiceError 加 `code`/`detail`、`Usp*FailureError` 存 `failures` list | ✅ 已完成 |
| 03 | [i18n 框架決策與 error 地基](03-i18n-localization-overview.md) | slang 不遷移決策、error 訊息地基進度、Service 層文本不在地化的判準 | 📖 參考 |
| 04 | [error message localization 執行規劃](04-error-message-localization-plan.md) | 橫切重構：error 訊息統一走 ServiceError → 共用 mapper → loc() | ✅ 已完成（PR #953） |

## 現在進行到哪

- ✅ **02 已完成**：診斷資訊（code/detail/failures）已保留在 ServiceError 上，不再流失。
- ✅ **04 已完成（PR #953）**：error 訊息這條線已橫切打通（Provider 透傳型別、View 共用 mapper + loc()），跨所有 USP feature。

## 已知未修

- **GET 9999→9998 bug**（見 01 §2.5）：GET 連線失敗被偽裝成「輸入錯誤」。與 localization 獨立，需另修，否則 l10n 會把連線失敗顯示成輸入錯誤。
