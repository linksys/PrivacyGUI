# Error Handling & Localization

USP 錯誤處理與 error 訊息在地化的文件。一條主線：**錯誤如何從 firmware 一路流到 UI，以及如何照現存 pattern 實作 error handling 並達成 localization**。

## 兩份文件

| 文件 | 回答什麼 | 何時讀 |
|---|---|---|
| 📘 [**實作指南**](error-handling-implementation-guide.md)<br>`error-handling-implementation-guide.md` | **「怎麼做」** —— 新增 USP feature 頁面時，Service／Provider／View 三層 error handling 該怎麼寫、該顯示什麼、不該顯示什麼、怎麼在地化、PR 前 checklist | 開始實作前必讀 |
| 📗 [**全鏈路參考**](usp-error-handling-reference.md)<br>`usp-error-handling-reference.md` | **「為什麼」** —— 錯誤從 firmware 經 WASM／codegen 流到 UI 的全鏈路、各層資料格式、error 來源／形式窮舉、9999／7xxx／9xxx／9998 的差別、兩條路徑成因 | 遇到困惑、要查根因時 |

> **建議讀法**：先讀 **實作指南**（足以照著寫 80% 的情境）。當你需要理解「為什麼 fetch 和 save 的錯誤形式不同」「9999 和 7xxx 差在哪」時，再翻 **全鏈路參考**。

## 現存做法的來源

error handling pipeline 的橫切重構在 **PR #953**（`feat(l10n): centralize error message localization for USP features`）。實作指南的所有 pattern 都對照 PR #953 後的當前 codebase。

## 已知未修

- **GET 9999→9998 bug**（全鏈路參考 §2.5）：GET 連線失敗（9999）在傳輸層被偽裝成「輸入錯誤」（9998）。與 localization 獨立，需另修——否則 l10n 做得再好，GET 連線失敗仍會顯示成「輸入錯誤」。實作指南 §7「已知限制」也有摘要。
