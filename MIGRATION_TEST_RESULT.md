# UI Kit 遷移測試結果 (Migration Test Results)

本文檔記錄 UI Kit 遷移過程中的所有測試結果和驗證狀況。

---

## 📋 測試指引 (Testing Guidelines)

完成單檔遷移後，依照以下步驟進行驗證：

### 步驟 1：靜態分析
```bash
flutter analyze lib/path/to/migrated_file.dart
```
- ✅ **通過條件**：無 error（warning 可接受）

### 步驟 2：檢查 privacygui_widgets 引用
確認遷移的檔案中沒有任何 `privacygui_widgets` 的引用。

```bash
grep -n "privacygui_widgets" lib/path/to/migrated_file.dart
```

- ✅ **通過條件**：無輸出（或僅有 `hide` 語句）
- ❌ **若有引用**：請填寫下方「保留 privacygui_widgets 原因」表格

### 步驟 3：Golden Test 生成
執行 golden test snapshot 生成：

```bash
sh ./run_generate_loc_snapshots.sh -c true -f {{測試路徑}}
```

**測試路徑對應規則：**
```
lib/page/login/view/login_local_view.dart
→ test/page/login/view/localization/login_local_view_test.dart
```

**測試檔案例外對照表：**

| 原始檔案 | 測試檔案（非標準路徑） |
|---------|---------------------|
| `lib/page/support/faq_list_view.dart` | `test/page/dashboard/localizations/dashboard_support_view_test.dart` |

**結果處理：**
- ✅ **無錯誤**：測試通過
- ⚠️ **Overflow 錯誤**：可忽略，但需記錄於下方「測試結果」表格
- ❌ **元件斷言失敗**：需修改測試檔案，依照遷移手冊更新 `privacygui_widgets` → `ui_kit`
- ❌ **其他失敗**：標記為失敗，記錄錯誤訊息於「測試結果」表格備註欄

---

## 🔍 測試結果記錄

### 保留 privacygui_widgets 原因

| 檔案 | 保留的元件 | 原因 |
|-----|-----------|------|
| _(待新增)_ | - | - |

### 測試結果

| 檔案 | 測試檔案路徑 | 結果 | 備註 |
|-----|------------|------|------|
| `dashboard_menu_view.dart` | - | ⏳ 待測試 | - |
| `faq_list_view.dart` | `test/page/dashboard/localizations/dashboard_support_view_test.dart` | ❌ 失敗 | `AppExpansionPanel` tap 行為與 `AppExpansionCard` 不同，`expandAllCategories` 無法展開面板 |
| `networks.dart` | - | ⏳ 待測試 | - |

---

## 🚨 已知測試問題

### AppExpansionPanel vs AppExpansionCard 行為差異

**問題描述**: `AppExpansionPanel` 的 tap 行為與舊版 `AppExpansionCard` 不同，導致 `expandAllCategories` 功能無法正常展開面板。

**影響檔案**: `faq_list_view.dart`

**暫時解決方案**: 需要調整測試邏輯或元件行為以相容新的 UI Kit 實現。

### Golden Test Overflow 警告

**問題描述**: 部分遷移檔案在 golden test 中出現 Overflow 警告，但不影響功能。

**處理方式**: 記錄但可忽略，主要關注功能性錯誤。

---

## 📊 測試統計

- **總測試檔案**: 3
- **通過**: 0
- **失敗**: 1
- **待測試**: 2
- **通過率**: 0%

*最後更新：[自動生成時間]*