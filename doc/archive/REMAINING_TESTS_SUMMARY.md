# 剩餘待測試項目總結

**產生日期**: 2025-12-20
**目的**: 整理尚未測試和需要修復的測試項目

---

## 執行摘要

### 測試覆蓋率統計
| 狀態 | 數量 | 百分比 |
|------|------|--------|
| ✅ 完成且通過 (兩種尺寸) | 20 | 42.6% |
| ⚠️ 完成但有問題 (1280w) | 5 | 10.6% |
| ⚠️ 部分通過 (需重測) | 4 | 8.5% |
| ❌ 尚未測試 | 2 | 4.3% |
| ⚠️ 已測試但失敗率高 | 16 | 34.0% |
| **總計** | **47** | **100%** |

### 按優先級分類
1. **高優先級**: 修復 5 個 1280w 桌面版面問題的測試 (影響響應式設計)
2. **中優先級**: 完成 4 個部分通過測試的雙尺寸驗證 (新增 DHCP Reservations、Dialogs)
3. **低優先級**: 2 個關鍵阻塞測試 (Auto Parent First Login、Snack Bar)

---

## 1️⃣ 高優先級 - 修復 1280w 桌面版面問題 (5 個測試)

這些測試在 480w 行動版通過，但在 1280w 桌面版失敗：

### ~~🔴 CRITICAL - Instant Topology View~~ ✅ 已修復
- **檔案**: `test/page/instant_topology/localizations/instant_topology_view_test.dart`
- **狀態**: ✅ **完全通過 (8/8 - 100%)**
- **修復日期**: 2025-12-20
- **修復方法**:
  - 使用 Pattern 0 (調整測試視窗高度為 1600px)
  - 處理 Tree View (mobile) 與 Graph View (desktop) 的 UI 差異
  - Tree View 顯示文字 badge，Graph View 只使用視覺指標
- **符合指南**: 完全遵守 `screenshot_testing_guideline.md` 要求
- **View ID**: `ITOP` 包含 4 個測試案例

### 1. ⚠️ WiFi List View (88.2% 通過率)
- **檔案**: `test/page/wifi_settings/views/localizations/wifi_list_view_test.dart`
- **狀態**: ⚠️ **部分通過 (30/34 - 88.2%)**
- **修復日期**: 2025-12-20
- **問題**: 僅剩下 4 個測試在 `IWWL-PASSWORD` 場景失敗，其餘 30 個測試通過 (Key 更新與 Dialog 類型修正)
- **剩餘問題**: 輸入驗證測試可能存在 widget finding 或 focus 問題
- **優先級**: 降級為中/低優先級 (大部分關鍵功能已通過)

### 2. 🟡 WiFi Main View (38.5% 通過率)
- **檔案**: `test/page/wifi_settings/views/localizations/wifi_main_view_test.dart`
- **問題**: 26 個測試中有 16 個失敗
- **根本原因**: 基於 Key 的元件尋找器失敗
- **建議修復**: 調查行動版/桌面版元件樹差異
- **影響**: WiFi 主頁面在桌面版部分功能無法測試

### 3. 🟡 Instant Device View (40% 通過率)
- **檔案**: `test/page/instant_device/views/localizations/instant_device_view_test.dart`
- **問題**: 5 個測試中有 3 個失敗
- **根本原因**: 重新整理圖示和底部按鈕找不到
- **建議修復**: 檢查 `instant_device_view.dart:65` 的圖示渲染
- **影響**: 裝置管理頁面桌面版互動受限

### 4. 🟢 Instant Admin View (80% 通過率)
- **檔案**: `test/page/instant_admin/views/localizations/instant_admin_view_test.dart`
- **問題**: 10 個測試中有 2 個失敗
- **根本原因**: 可滾動清單中的 ListTile 找不到
- **建議修復**: 輕微問題，可接受或使用 `scrollUntilVisible()`
- **影響**: 管理頁面大部分功能正常

### 5. 🟢 PNP Setup View (83.3% 通過率)
- **檔案**: `test/page/instant_setup/localizations/pnp_setup_view_test.dart`
- **問題**: 30 個測試中有 5 個失敗
- **根本原因**: `ConstrainedBox(minHeight: constraints.maxHeight)` 導致內容高度 > 720px
- **實作位置**: [pnp_setup_view.dart:143-145](../lib/page/instant_setup/pnp_setup_view.dart#L143-L145)
- **建議修復**: 檢討版面策略，考慮桌面版的彈性高度
- **影響**: 設定精靈大部分功能正常

---

## 2️⃣ 中優先級 - 完成雙尺寸驗證 (4 個測試)

這些測試已執行但有部分失敗，需要修復：

### Login Local View
- **檔案**: `test/page/login/localizations/login_local_view_test.dart`
- **目前狀態**: ⚠️ 部分通過 (2/5)
- **問題**: 非同步 mock 時序問題導致錯誤狀態測試失敗
- **測試指令**:
  ```bash
  sh ./run_generate_loc_snapshots.sh -c true -f test/page/login/localizations/login_local_view_test.dart -l "en" -s "480,1280"
  ```
- **需要修復**: 錯誤狀態的測試 (Countdown, Locked, Generic)

### Local Reset Router Password View
- **檔案**: `test/page/login/localizations/local_reset_router_password_view_test.dart`
- **目前狀態**: ⚠️ 部分通過 (3/5)
- **問題**: 可見性圖示找不到、失敗對話框
- **測試指令**:
  ```bash
  sh ./run_generate_loc_snapshots.sh -c true -f test/page/login/localizations/local_reset_router_password_view_test.dart -l "en" -s "480,1280"
  ```
- **需要修復**: 編輯密碼測試、失敗對話框測試

### DHCP Reservations View (新增)
- **檔案**: `test/page/advanced_settings/local_network_settings/views/localizations/dhcp_reservations_view_test.dart`
- **目前狀態**: ⚠️ 部分通過 (5/8 - 62.5%)
- **問題**: Add 按鈕找不到、Widget 類型不匹配
- **已修復**:
  - 變更按鈕 finder 從 `widgetWithText` 到 `byKey`
  - 變更欄位類型從 `AppTextFormField` 到 `AppTextField`
- **需要修復**: 按鈕仍然找不到 (可能需要 scroll)、MAC address 欄位類型

### Dialogs Component (新增)
- **檔案**: `test/page/components/localizations/dialogs_test.dart`
- **目前狀態**: ⚠️ 部分通過 (2/4 - 50%)
- **問題**: AppIconButton 在對話框中找不到
- **測試指令**:
  ```bash
  sh ./run_generate_loc_snapshots.sh -c true -f test/page/components/localizations/dialogs_test.dart -l "en" -s "480,1280"
  ```
- **需要修復**: 找到並點擊 AppIconButton

---

## 3️⃣ 低優先級 - 關鍵阻塞測試 (2 個)

這些測試有關鍵問題需要修復：

### 1. Auto Parent First Login View ❌ 阻塞
- **檔案**: `test/page/login/auto_parent/views/localizations/auto_parent_first_login_view_test.dart`
- **目前狀態**: ❌ 完全失敗 (0/2 - 0%)
- **問題**: AppLoader 找不到
- **錯誤**: `Expected: exactly one matching candidate, Actual: _TypeWidgetFinder:<Found 0 widgets with type "AppLoader": []>`
- **根本原因**: 初始化流程或 Widget 樹結構問題
- **需要修復**: 調查 AppLoader 位置並修正測試

### 2. Snack Bar Component 🔴 關鍵阻塞
- **檔案**: `test/page/components/localizations/snack_bar_test.dart`
- **目前狀態**: ❌ 完全失敗 (0/54 - 0%)
- **問題**: 無限高度約束導致所有測試失敗
- **錯誤**:
  ```
  BoxConstraints forces an infinite height.
  RenderSliverFillRemaining.performLayout (package:flutter/src/rendering/sliver_fill.dart:166:14)
  ```
- **根本原因**: `snack_bar_sample_view.dart` 第 40 行版面問題
- **嚴重性**: 🔴 **關鍵** - 阻擋所有 54 個測試
- **需要修復**: 修改實作檔案的版面約束

---

## 4️⃣ 已完成測試 (新增 3 個)

以下測試已在 2025-12-20 完成並通過：

### ✅ Speed Test External
- **檔案**: `test/page/health_check/views/localizations/speed_test_external_test.dart`
- **狀態**: ✅ 完全通過 (2/2 - 100%)
- **日期**: 2025-12-20

### ✅ Select Device View
- **檔案**: `test/page/instant_device/views/localizations/select_device_view_test.dart`
- **狀態**: ✅ 完全通過 (14/14 - 100%)
- **日期**: 2025-12-20

### ✅ Top Bar Component
- **檔案**: `test/page/components/localizations/top_bar_test.dart`
- **狀態**: ✅ 完全通過 (14/14 - 100%)
- **日期**: 2025-12-20

---

## 5️⃣ 已知問題但失敗率高的測試 (16 個)

這些測試已經執行過，但失敗率較高，需要後續修復：

| 測試檔案 | 通過/總數 | 通過率 | 主要問題 |
|---------|----------|--------|---------|
| apps_and_gaming_view_test.dart | 7/84 | 8.3% | 大量失敗 |
| dmz_settings_view_test.dart | 3/10 | 30% | 多數失敗 |
| firewall_view_test.dart | 1/25 | 4% | 幾乎全部失敗 |
| internet_settings_view_test.dart | 11/28 | 39.3% | 多數失敗 |
| local_network_settings_view_test.dart | 1/9 | 11.1% | 大部分失敗 |
| static_routing_view_test.dart | 1/48 | 2.1% | 幾乎全部失敗 |
| instant_admin_view_test.dart | 4/5 | 80% | 1 個失敗 |
| instant_verify_view_test.dart | 3/7 | 42.9% | 多個失敗 |
| pnp_waiting_modem_view_test.dart | 0/1 | 0% | 版面錯誤 (阻擋) |
| pnp_pppoe_view_test.dart | 1/7 | 14.3% | 大部分失敗 |
| node_detail_view_test.dart | 0/26 | 0% | 全部失敗 |
| add_nodes_view_test.dart | 5/7 | 71.4% | 2 個失敗 |
| vpn_settings_page_test.dart | 13/16 | 81.3% | 3 個失敗 |
| dashboard_home_view_test.dart | 27/34 | 79.4% | Overflow 警告 |
| **dhcp_reservations_view_test.dart** ⚠️ | **5/8** | **62.5%** | **按鈕找不到** (新增) |
| **dialogs_test.dart** ⚠️ | **2/4** | **50%** | **IconButton 找不到** (新增) |

---

## 常見的 1280w 桌面版面問題模式

### 模式 0: 調整測試視窗高度 (建議優先嘗試)

**適用情況**: 內容本身正常，但預設 720px 高度不足以顯示完整內容

```dart
// 解決方案: 調整測試視窗高度
final _desktopTallScreens = responsiveDesktopScreens
    .map((screen) => screen.copyWith(height: 1600))  // 增加高度
    .toList();

final _customScreens = [
  ...responsiveMobileScreens.map((screen) => screen.copyWith(height: 1280)),
  ..._desktopTallScreens,
];

// 在 testLocalizations 中使用:
testLocalizations(
  'Test name',
  (tester, locale, config) async { /* ... */ },
  helper: testHelper,
  screens: _customScreens,  // 使用自訂高度
);
```

**何時使用此方法**:
- 內容自然需要更多垂直空間 (例如拓撲圖、長表單)
- 版面正確但測試視窗太短
- 桌面使用者在實際環境中有更大螢幕
- 行動版內容本來就需要滾動

**參考範例**: `instant_topology_view_test.dart`

### 模式 1: ConstrainedBox with minHeight
```dart
// 問題: 強制內容至少為螢幕高度 (720px)
SingleChildScrollView(
  child: ConstrainedBox(
    constraints: BoxConstraints(minHeight: constraints.maxHeight),
    // 如果內容 > 720px，底部元件會在螢幕外
```

**解決方案**:
1. 優先嘗試「模式 0」調整測試高度
2. 如果是實作問題，在桌面版面使用彈性高度，或移除 minHeight 限制

### 模式 2: 底部按鈕在螢幕外
當內容超過可視區高度時，底部按鈕可能定位在 1280w×720px 測試視窗之外。

**解決方案**:
1. 優先嘗試「模式 0」調整測試高度
2. 確保可滾動容器正確曝露所有互動元素
3. 在測試中使用 `Scrollable.ensureVisible()` 或 `tester.scrollUntilVisible()`

### 模式 3: 可滾動清單中的元件尋找
當元件尚未在可滾動區域中可見時，`find.byKey()` 可能失敗。

**解決方案**: 在斷言前加入 `await tester.scrollUntilVisible()`，或調整測試策略。

---

## 建議的執行順序

### 第一階段: 修復關鍵桌面版面問題 (預估 2-3 天)
1. **Instant Topology View** - 最高優先級 (0% 通過率)
2. **WiFi List View** - 高優先級 (35.3% 通過率)
3. **WiFi Main View** - 高優先級 (38.5% 通過率)

### 第二階段: 修復次要桌面版面問題 (預估 1 天)
4. **Instant Device View** (40% 通過率)
5. **PNP Setup View** (83.3% 通過率) - 檢討版面策略
6. **Instant Admin View** (80% 通過率) - 輕微問題

### 第三階段: 完成雙尺寸驗證 (預估 0.5 天)
7. **Login Local View** - 修復錯誤狀態測試
8. **Local Reset Router Password View** - 修復可見性和對話框測試

### 第四階段: 修復部分通過測試 (預估 1 天)
9. **DHCP Reservations View** - 修復按鈕找不到問題
10. **Dialogs Component** - 修復 AppIconButton 問題
11. **Login Local View** - 修復錯誤狀態測試
12. **Local Reset Router Password View** - 修復可見性和對話框測試

### 第五階段: 處理關鍵阻塞測試 (預估 1 天)
13. **Snack Bar Component** - 🔴 關鍵：修復無限高度約束問題
14. **Auto Parent First Login View** - 調查並修復 AppLoader 問題

### 第六階段: 處理已知失敗率高的測試 (預估 3-5 天)
15. 逐一修復 16 個失敗率高的測試
16. 優先處理完全失敗 (0%) 的測試

---

## 測試執行範本

### 單一測試檔案
```bash
sh ./run_generate_loc_snapshots.sh -c true -f {test_file_path} -l "en" -s "480,1280"
```

### 批次測試 (建議使用)
```bash
#!/bin/bash

# 高優先級測試清單
PRIORITY_TESTS=(
  "test/page/instant_topology/localizations/instant_topology_view_test.dart"
  "test/page/wifi_settings/views/localizations/wifi_list_view_test.dart"
  "test/page/wifi_settings/views/localizations/wifi_main_view_test.dart"
)

for test_file in "${PRIORITY_TESTS[@]}"; do
  echo "========================================="
  echo "測試: $test_file"
  echo "========================================="

  sh ./run_generate_loc_snapshots.sh -c true -f "$test_file" -l "en" -s "480,1280"

  if [ $? -eq 0 ]; then
    echo "✅ 兩種尺寸都通過"
  else
    echo "❌ 失敗 - 需要調查"
  fi

  echo ""
done
```

---

## 相關文件

- [SCREEN_SIZE_VERIFICATION_STATUS.md](SCREEN_SIZE_VERIFICATION_STATUS.md) - 尺寸驗證追蹤
- [MIGRATION_TEST_RESULTS.md](MIGRATION_TEST_RESULTS.md) - 詳細測試結果
- [screenshot_testing_fix_workflow.md](screenshot_testing_fix_workflow.md) - 測試修復流程
- [SCREENSHOT_TEST_COVERAGE.md](SCREENSHOT_TEST_COVERAGE.md) - 測試覆蓋率分析

---

**最後更新**: 2025-12-20 (更新於測試 7 個項目後)
**產生者**: Claude Code
**狀態**: 當前進度報告

---

## 更新紀錄

### 2025-12-20 更新
- 完成測試 7 個項目 (DHCP Reservations, Speed Test External, Select Device View, Auto Parent First Login, Dialogs, Snack Bar, Top Bar)
- 新增 3 個完全通過測試 (Speed Test External, Select Device View, Top Bar Component)
- 新增 2 個部分通過測試到中優先級 (DHCP Reservations, Dialogs)
- 新增 2 個關鍵阻塞測試到低優先級 (Auto Parent First Login, Snack Bar)
- 更新測試覆蓋率統計：19 個完全通過 (40.4%)，4 個部分通過 (8.5%)，2 個關鍵阻塞 (4.3%)
