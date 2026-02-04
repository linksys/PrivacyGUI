# dev-1.2.8 遷移任務清單

> 此檔案用於追蹤遷移進度，請在完成任務後勾選對應項目。

---

## 前置準備

- [x] **P1**: 確保本地分支最新
  ```bash
  git fetch origin
  ```

- [x] **P2**: 建立遷移工作分支
  ```bash
  git checkout dev-2.0.0
  git pull origin dev-2.0.0
  git checkout -b austin/migration-1.2.8
  ```

- [x] **P3**: 確認 dev-1.2.8 提交清單
  ```bash
  git log --oneline dev-2.0.0..origin/dev-1.2.8
  ```

---

## 階段一：乾淨新增

> **狀態**: ✅ 已完成
> **提交**: `33d5f959` - feat: migrate phase 1 features from dev-1.2.8

### 任務 1.1: PWA 功能移植

- [x] **1.1.1**: 複製 PWA 核心檔案
  ```bash
  git checkout origin/dev-1.2.8 -- lib/core/pwa/
  ```

- [x] **1.1.2**: 複製 device_features.dart
  ```bash
  git checkout origin/dev-1.2.8 -- lib/core/utils/device_features.dart
  ```

- [x] **1.1.3**: 複製 PWA UI 元件
  ```bash
  git checkout origin/dev-1.2.8 -- lib/page/components/pwa/
  ```

- [x] **1.1.4**: 複製 Web 資源
  ```bash
  git checkout origin/dev-1.2.8 -- web/logo_icons/
  git checkout origin/dev-1.2.8 -- web/service_worker.js
  ```

- [x] **1.1.5**: 複製測試檔案
  ```bash
  git checkout origin/dev-1.2.8 -- test/core/utils/device_features_test.dart
  git checkout origin/dev-1.2.8 -- test/page/components/pwa/
  ```

- [x] **1.1.6**: 手動合併 `web/index.html`
  - 比對差異：`git diff dev-2.0.0 origin/dev-1.2.8 -- web/index.html`
  - 整合 PWA 相關 meta tags 和 scripts

- [x] **1.1.7**: 手動合併 `web/manifest.json`
  - 比對差異：`git diff dev-2.0.0 origin/dev-1.2.8 -- web/manifest.json`

- [x] **1.1.8**: 手動合併 `web/flutter_bootstrap.js`
  - 比對差異：`git diff dev-2.0.0 origin/dev-1.2.8 -- web/flutter_bootstrap.js`

- [x] **1.1.9**: 更新 import 路徑
  - 檢查 `lib/page/components/pwa/` 所有檔案
  - 確認 package import 正確

- [x] **1.1.10**: 整合 PWA banner 至 top_bar.dart
  - 檢視 dev-1.2.8 的整合方式
  - 在 `lib/page/components/styled/top_bar.dart` 加入 PWA banner

- [x] **1.1.11**: 執行 PWA 測試
  ```bash
  flutter test test/core/utils/device_features_test.dart
  flutter test test/page/components/pwa/
  ```

- [x] **1.1.12**: 執行 analyze
  ```bash
  flutter analyze lib/core/pwa/
  flutter analyze lib/page/components/pwa/
  ```

---

### 任務 1.2: 品牌資源 Provider 移植

- [x] **1.2.1**: 複製 GlobalModelNumberProvider
  ```bash
  git checkout origin/dev-1.2.8 -- lib/providers/global_model_number_provider.dart
  ```

- [x] **1.2.2**: 比對 brand_asset_provider.dart 差異
  ```bash
  git diff dev-2.0.0 origin/dev-1.2.8 -- lib/providers/brand_asset_provider.dart
  ```

- [x] **1.2.3**: 手動合併 BrandAssetType 列舉和相關方法

- [x] **1.2.4**: 更新 Provider 匯出（若需要）
  - 檢查 `lib/providers/_providers.dart` 或相關 barrel 檔案

- [x] **1.2.5**: 執行 analyze
  ```bash
  flutter analyze lib/providers/
  ```

---

### 任務 1.3: 工具函式更新

- [x] **1.3.1**: 比對 utils.dart 差異
  ```bash
  git diff dev-2.0.0 origin/dev-1.2.8 -- lib/utils.dart
  ```

- [x] **1.3.2**: 手動合併 SI 單位格式化函式
  - 找到 `formatSpeed` 或相關函式
  - 將 base 從 1024 改為 1000

- [x] **1.3.3**: 比對測試差異
  ```bash
  git diff dev-2.0.0 origin/dev-1.2.8 -- test/utils_test.dart
  ```

- [x] **1.3.4**: 更新測試

- [x] **1.3.5**: 執行測試
  ```bash
  flutter test test/utils_test.dart
  ```

---

### 任務 1.4: 型號啟用設定

- [x] **1.4.1**: 檢視 SPNM62/M62 變更
  ```bash
  git show 7dae63b6
  ```

- [x] **1.4.2**: 在對應設定檔案中啟用 SPNM62/M62

- [x] **1.4.3**: 驗證設定正確

---

### 階段一檢查點

- [x] 執行完整 analyze
  ```bash
  flutter analyze
  ```

- [x] 執行基本測試
  ```bash
  flutter test test/core/utils/
  flutter test test/page/components/pwa/
  flutter test test/utils_test.dart
  ```

- [x] 提交階段一變更
  ```bash
  git add .
  git commit -m "feat: migrate phase 1 features from dev-1.2.8"
  ```

---

## 階段二：中度整合

> **狀態**: ✅ 已完成
> **提交**:
> - `efd3f3ff` - feat: Add speed test server selection (Phase 2 migration from dev-1.2.8)
> - `a2db638c` - fix: Add HealthCheckManager2 service support check for server selection

### 任務 2.1: HealthCheckServer 模型建立

- [x] **2.1.1**: 複製模型檔案
  ```bash
  git checkout origin/dev-1.2.8 -- lib/page/health_check/models/health_check_server.dart
  ```

- [x] **2.1.2**: 檢查是否需要建立 models 目錄
  ```bash
  ls lib/page/health_check/models/ 2>/dev/null || mkdir -p lib/page/health_check/models/
  ```
  > 目錄已存在

- [x] **2.1.3**: 更新 barrel export
  - 若有 `_models.dart` 或 `_health_check.dart`，新增 export

- [x] **2.1.4**: 執行 analyze
  ```bash
  flutter analyze lib/page/health_check/models/
  ```

---

### 任務 2.2: 伺服器選擇對話框移植

- [x] **2.2.1**: 複製對話框元件
  ```bash
  git checkout origin/dev-1.2.8 -- lib/page/health_check/views/components/speed_test_server_selection_dialog.dart
  ```

- [x] **2.2.2**: 更新 import 路徑
  - 確認 HealthCheckServer import 正確
  - 確認 UI 元件 import 正確

- [x] **2.2.3**: 調整對話框以配合新架構
  - 檢查狀態讀取方式
  - 確認 callback 簽名正確

- [x] **2.2.4**: 執行 analyze
  ```bash
  flutter analyze lib/page/health_check/views/components/
  ```

---

### 任務 2.3: 更新 HealthCheckState

- [x] **2.3.1**: 開啟現有 HealthCheckState
  ```
  lib/page/health_check/providers/health_check_state.dart
  ```

- [x] **2.3.2**: 新增 servers 欄位
  ```dart
  final List<HealthCheckServer> servers;
  ```

- [x] **2.3.3**: 新增 selectedServer 欄位
  ```dart
  final HealthCheckServer? selectedServer;
  ```

- [x] **2.3.4**: 更新建構子
  - 在 constructor 加入新欄位
  - 設定預設值

- [x] **2.3.5**: 更新 props（Equatable）
  - 加入 servers 和 selectedServer

- [x] **2.3.6**: 更新 copyWith 方法

- [x] **2.3.7**: 更新 toMap/fromMap 方法

- [x] **2.3.8**: 執行 analyze
  ```bash
  flutter analyze lib/page/health_check/providers/health_check_state.dart
  ```

---

### 任務 2.4: 更新 HealthCheckProvider

- [x] **2.4.1**: 比對 Provider 差異
  ```bash
  git diff dev-2.0.0 origin/dev-1.2.8 -- lib/page/health_check/providers/health_check_provider.dart
  ```

- [x] **2.4.2**: 實作 loadServers 方法
  - 從 dev-1.2.8 參考 `updateServers()` 實作邏輯
  - 適配至新架構（使用 SpeedTestService）
  - 在 `loadData()` 中調用

- [x] **2.4.3**: 實作 setSelectedServer 方法

- [x] **2.4.4**: 更新測試
  ```bash
  git diff dev-2.0.0 origin/dev-1.2.8 -- test/page/health_check/
  ```
  > 修正 MockHealthCheckProvider 類別簽名：`extends HealthCheckProvider with Mock`

- [x] **2.4.5**: 執行測試
  ```bash
  flutter test test/page/health_check/
  ```
  > 3107 功能測試通過

---

### 任務 2.5: 更新 SpeedTestView

- [x] **2.5.1**: 比對 View 差異
  ```bash
  git diff dev-2.0.0 origin/dev-1.2.8 -- lib/page/health_check/views/speed_test_view.dart
  ```

- [x] **2.5.2**: 整合伺服器選擇 UI
  - 加入 AppBar action icon button (`Icons.dns_outlined`)
  - 連接 SpeedTestServerSelectionDialog
  > 與 dev-1.2.8 差異：使用 dialog 而非 dropdown

- [x] **2.5.3**: 更新狀態讀取
  - 從新的 HealthCheckState 讀取 servers 和 selectedServer

- [x] **2.5.4**: 執行 analyze
  ```bash
  flutter analyze lib/page/health_check/views/
  ```

---

### 任務 2.6: JNAP 與支援檢查

- [x] **2.6.1**: 確認 getCloseHealthCheckServers JNAP Action
  - 檔案: `lib/core/jnap/actions/jnap_action.dart:89`

- [x] **2.6.2**: 新增 HealthCheckManager2 到 JNAPService enum
  - 檔案: `lib/core/jnap/actions/jnap_service.dart:57`

- [x] **2.6.3**: 新增 isSupportHealthCheckManager2 方法
  - 檔案: `lib/core/jnap/actions/jnap_service_supported.dart:26-27`

- [x] **2.6.4**: 在 loadData/loadServers 中加入支援檢查
  ```dart
  if (serviceHelper.isSupportHealthCheckManager2()) {
    // load servers
  }
  ```

- [x] **2.6.5**: 更新 test_helper.dart 加入 mock
  ```dart
  when(mockServiceHelper.isSupportHealthCheckManager2()).thenReturn(false);
  ```

---

### 階段二檢查點

- [x] 執行 health_check 相關測試
  ```bash
  flutter test test/page/health_check/
  ```
  > 55 個 localization 測試通過

- [ ] 手動測試伺服器選擇功能
  - 啟動應用
  - 進入 Speed Test 頁面
  - 確認伺服器列表顯示
  - 確認可選擇伺服器

- [x] 提交階段二變更
  ```bash
  git add .
  git commit -m "feat: Add speed test server selection (Phase 2 migration from dev-1.2.8)"
  ```

---

## 階段三：架構適配

> **狀態**: ⏳ 待開始

### 任務 3.1: SpeedTest 錯誤處理整合

- [ ] **3.1.1**: 分析 dev-1.2.8 錯誤處理實作
  ```bash
  git show dffec0dc -- lib/page/health_check/providers/health_check_provider.dart
  ```

- [ ] **3.1.2**: 檢視現有 SpeedTestError enum
  ```
  lib/page/health_check/models/health_check_enum.dart
  ```

- [ ] **3.1.3**: 新增 SpeedTestExecutionError 類型（若需要）

- [ ] **3.1.4**: 在 Provider 實作錯誤處理邏輯
  - 捕獲 SpeedTestExecutionError
  - 更新狀態的 errorCode

- [ ] **3.1.5**: 在 UI 顯示錯誤訊息
  - 更新 SpeedTestView
  - 顯示適當的錯誤提示

- [ ] **3.1.6**: 修復空時間戳日期解析
  - 找到相關解析程式碼
  - 加入空值檢查

---

### 任務 3.2: Polling Provider 快取整合

- [ ] **3.2.1**: 比對 polling_provider.dart 差異
  ```bash
  git diff dev-2.0.0 origin/dev-1.2.8 -- lib/core/jnap/providers/polling_provider.dart
  ```

- [ ] **3.2.2**: 評估 GetCloseHealthCheckServers 快取邏輯
  - 確認是否需要整合
  - 確認與現有架構相容性

- [ ] **3.2.3**: 實作或跳過（記錄決策）

---

### 任務 3.3: Dashboard SpeedTest Widget 評估

- [ ] **3.3.1**: 檢視 dev-1.2.8 的 port_and_speed.dart
  ```bash
  git show origin/dev-1.2.8:lib/page/dashboard/views/components/port_and_speed.dart
  ```

- [ ] **3.3.2**: 評估是否需要在 dev-2.0.0 重建
  - [ ] 需要重建 → 進行 3.3.3
  - [ ] 不需要 → 記錄決策，跳過

- [ ] **3.3.3**: 在新架構中重建功能（若需要）
  - 建立新元件
  - 整合至 Dashboard

---

### 任務 3.4: InstantVerify SpeedTest Widget 評估

- [ ] **3.4.1**: 檢視 dev-1.2.8 的 speed_test_widget.dart
  ```bash
  git show origin/dev-1.2.8:lib/page/instant_verify/views/components/speed_test_widget.dart
  ```

- [ ] **3.4.2**: 比對 instant_verify_view.dart 差異
  ```bash
  git diff dev-2.0.0 origin/dev-1.2.8 -- lib/page/instant_verify/views/instant_verify_view.dart
  ```

- [ ] **3.4.3**: 評估是否需要重建
  - [ ] 需要重建 → 進行 3.4.4
  - [ ] 不需要 → 記錄決策，跳過

- [ ] **3.4.4**: 在新架構中重建功能（若需要）

---

### 階段三檢查點

- [ ] 執行完整測試
  ```bash
  ./run_tests.sh
  ```

- [ ] 手動測試錯誤處理
  - 模擬錯誤情境
  - 確認錯誤訊息正確顯示

- [ ] 提交階段三變更
  ```bash
  git add .
  git commit -m "feat: integrate speed test error handling from dev-1.2.8"
  ```

---

## 最終驗證

### 驗證 4.1: 程式碼品質

- [x] 執行 flutter analyze
  ```bash
  flutter analyze
  ```

- [ ] 確認無未使用的 import

- [ ] 確認無 TODO 遺漏

---

### 驗證 4.2: 測試通過

- [x] 執行完整測試套件
  ```bash
  ./run_tests.sh
  ```
  > 3107 功能測試通過

- [ ] 確認測試覆蓋率

---

### 驗證 4.3: 建置驗證

- [ ] Web 建置
  ```bash
  ./build_web.sh
  ```

- [ ] 本機執行測試
  ```bash
  flutter run -d chrome
  ```

---

### 驗證 4.4: 功能測試

- [ ] PWA 安裝提示
  - 使用 DU 型號測試
  - 確認 banner 顯示
  - 確認安裝說明正確

- [ ] Speed Test 伺服器選擇
  - 確認伺服器列表載入
  - 確認可選擇伺服器
  - 確認測試使用選定伺服器

- [ ] Speed Test 錯誤處理
  - 模擬錯誤情境
  - 確認錯誤訊息顯示

- [ ] 速度格式化
  - 確認使用 SI 單位（1000 base）

---

## 完成收尾

- [ ] 建立 Pull Request
  ```bash
  git push -u origin austin/migration-1.2.8
  gh pr create --title "feat: merge dev-1.2.8 features to dev-2.0.0" --body "..."
  ```

- [ ] 更新遷移計畫文件狀態

- [ ] 記錄任何未完成項目或技術債

---

## 決策記錄

### 決策 D1: Dashboard SpeedTest Widget

**日期**: ____
**決策**: [ ] 重建 / [ ] 跳過
**原因**: ____

---

### 決策 D2: InstantVerify SpeedTest Widget

**日期**: ____
**決策**: [ ] 重建 / [ ] 跳過
**原因**: ____

---

### 決策 D3: Polling Provider 快取

**日期**: ____
**決策**: [ ] 整合 / [ ] 跳過
**原因**: ____

---

### 決策 D4: Server Selection UI 差異

**日期**: 2026-02-04
**決策**: [x] 使用 Dialog (Icon Button in AppBar)
**原因**: dev-2.0.0 架構使用 UiKitPageView 與 AppBar actions，採用 dialog 方式更符合新架構設計

---

### 決策 D5: Mock 類別簽名修正

**日期**: 2026-02-04
**決策**: [x] 修改 MockHealthCheckProvider 類別簽名
**原因**: 原本 Mockito 生成的 `extends Mock implements Provider` 會缺少 Riverpod 內部方法 (`_setElement`)，改為 `extends HealthCheckProvider with Mock` 可同時繼承 Notifier 內部方法並保留 Mock 功能

---

## 問題追蹤

| # | 問題描述 | 狀態 | 解決方案 |
|---|----------|------|----------|
| 1 | MockHealthCheckProvider 缺少 `_setElement` 方法 | ✅ 已解決 | 修改 mock 類別為 `extends HealthCheckProvider with Mock` |
| 2 | test_helper 缺少 `isSupportHealthCheckManager2` mock | ✅ 已解決 | 新增 `when(mockServiceHelper.isSupportHealthCheckManager2()).thenReturn(false)` |
| 3 | speed_test_view_test.dart verify 簽名不符 | ✅ 已解決 | 更新為 `anyNamed('serverId')` |

---

## 架構差異對照表

| 功能 | dev-1.2.8 | dev-2.0.0 |
|------|-----------|-----------|
| State 型別 | `String status/step` | `HealthCheckStatus/HealthCheckStep` enum |
| Result 型別 | `List<HealthCheckResult>` | `SpeedTestUIModel?` |
| Server 載入 | `updateServers()` in View initState | `loadServers()` in Provider build() |
| Server UI | AppDropdownButton + Dialog | Icon Button + Dialog |
| Service 層 | 直接使用 Repository | SpeedTestService |
| SpeedTestWidget 位置 | instant_verify/views/components/ | health_check/widgets/ |
