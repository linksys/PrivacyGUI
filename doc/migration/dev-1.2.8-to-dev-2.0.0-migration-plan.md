# dev-1.2.8 → dev-2.0.0 遷移計畫

> 建立日期：2026-02-04
> 狀態：規劃中
> 負責人：待指派

---

## 1. 概述

### 1.1 背景

`dev-1.2.8` 分支包含多項生產環境修復與新功能，需要合併至 `dev-2.0.0` 主要開發分支。由於 `dev-2.0.0` 進行了大規模的三層架構重構，直接合併會產生約 30 個檔案衝突，因此採用 **Cherry-pick 搭配手動適配** 策略。

### 1.2 分支狀態

| 分支 | 提交數 | 最後更新 | 說明 |
|------|--------|----------|------|
| `dev-1.2.8` | 9 個獨特提交 | 2026-02-03 | 生產修復分支 |
| `dev-2.0.0` | 47+ 提交 | 2026-02-04 | 三層架構重構分支 |
| 共同祖先 | `08b486f9` | - | merge 1.2.7 to main |

### 1.3 遷移策略

```
Cherry-pick 搭配手動適配
├── 階段一：乾淨新增（直接 cherry-pick）
├── 階段二：中度整合（cherry-pick + 調整）
└── 階段三：架構適配（手動重新實作）
```

---

## 2. 功能清單

### 2.1 需遷移功能總覽

| # | 功能 | PR/Commit | 風險等級 | 遷移方式 |
|---|------|-----------|----------|----------|
| F1 | PWA 安裝提示（DU 型號限定） | #609 | 🟢 低 | Cherry-pick |
| F2 | SpeedTest 錯誤處理與伺服器選擇 | #607 | 🔴 高 | 手動適配 |
| F3 | 品牌資源載入優化 | #600 | 🟡 中 | Cherry-pick + 調整 |
| F4 | 速度格式化 SI 單位 | ca1717b2 | 🟢 低 | Cherry-pick |
| F5 | SPNM62/M62 Speed Test 啟用 | 7dae63b6 | 🟢 低 | Cherry-pick |

### 2.2 功能詳細說明

#### F1: PWA 安裝提示（DU 型號限定）

**提交**: `d7d14197`

**說明**:
- 實作 PWA 安裝提示橫幅，僅在 'DU' 型號裝置顯示
- 包含 iOS 和 Mac Safari 的安裝說明頁面
- 建立 `device_features.dart` 裝置功能檢測系統

**新增檔案**:
```
lib/core/pwa/
├── pwa_install_service.dart
├── pwa_logic.dart
├── pwa_logic_stub.dart
└── pwa_logic_web.dart

lib/core/utils/device_features.dart

lib/page/components/pwa/
├── install_prompt_banner.dart
├── ios_install_instruction_sheet.dart
└── mac_safari_install_instruction_sheet.dart

web/
├── logo_icons/logo-icon-512.png
├── manifest.json (更新)
├── service_worker.js
├── index.html (更新)
└── flutter_bootstrap.js (更新)

test/
├── core/utils/device_features_test.dart
└── page/components/pwa/install_prompt_banner_test.dart
```

**相依性**: 無（獨立功能）

---

#### F2: SpeedTest 錯誤處理與伺服器選擇

**提交**: `dffec0dc`

**說明**:
- 新增 `HealthCheckServer` 模型
- 實作伺服器選擇對話框
- 處理 `SpeedTestExecutionError`
- 修復空時間戳日期解析

**受影響檔案**:
```
lib/page/health_check/
├── models/health_check_server.dart (新增)
├── providers/health_check_provider.dart (衝突)
├── providers/health_check_state.dart (衝突 - 架構不同)
├── views/speed_test_view.dart (衝突)
└── views/components/speed_test_server_selection_dialog.dart (新增)

lib/page/instant_verify/views/
├── instant_verify_view.dart (衝突)
└── components/speed_test_widget.dart (已刪除於 dev-2.0.0)

lib/page/dashboard/views/components/
└── port_and_speed.dart (已刪除於 dev-2.0.0)
```

**架構差異**:

| 項目 | dev-1.2.8 | dev-2.0.0 |
|------|-----------|-----------|
| 狀態類型 | `String step, status` | `HealthCheckStep, HealthCheckStatus` enum |
| 結果模型 | `List<HealthCheckResult>` | `SpeedTestUIModel` |
| 錯誤處理 | `JNAPError?` | `SpeedTestError?` enum |
| 伺服器列表 | `List<HealthCheckServer>` | 需整合 |

**遷移策略**: 手動將功能邏輯適配至新架構

---

#### F3: 品牌資源載入優化

**提交**: `09e12846`

**說明**:
- 新增 `BrandAssetType` 列舉
- 建立 `GlobalModelNumberProvider` 持久化型號
- 優化品牌資源路徑解析

**受影響檔案**:
```
lib/providers/
├── brand_asset_provider.dart (需合併)
└── global_model_number_provider.dart (新增)
```

**遷移策略**: Cherry-pick 後調整 Provider 註冊

---

#### F4: 速度格式化 SI 單位

**提交**: `ca1717b2`

**說明**: 將網路速度格式化從二進位（1024）改為 SI 單位（1000）

**受影響檔案**:
```
lib/utils.dart (需合併)
test/utils_test.dart (需合併)
```

**遷移策略**: 直接合併工具函式

---

#### F5: SPNM62/M62 Speed Test 啟用

**提交**: `7dae63b6`

**說明**: 為 SPNM62 和 M62 型號啟用 Speed Test 功能

**受影響檔案**: 裝置功能設定檔

**遷移策略**: 直接 cherry-pick

---

## 3. 衝突檔案清單

### 3.1 內容衝突

| 檔案 | 衝突原因 | 解決策略 |
|------|----------|----------|
| `lib/page/health_check/providers/health_check_state.dart` | 架構完全重寫 | 手動整合新欄位 |
| `lib/page/health_check/providers/health_check_provider.dart` | 服務層抽取 | 手動適配 |
| `lib/page/health_check/views/speed_test_view.dart` | UI Model 變更 | 手動適配 |
| `lib/core/jnap/providers/polling_provider.dart` | 快取邏輯變更 | 合併快取邏輯 |
| `lib/page/dashboard/providers/dashboard_home_provider.dart` | Provider 重構 | 評估後決定 |
| `lib/page/dashboard/views/dashboard_shell.dart` | 佈局變更 | 手動合併 |
| `lib/page/dashboard/views/dashboard_menu_view.dart` | 選單變更 | 手動合併 |
| `lib/providers/auth/auth_provider.dart` | 認證邏輯變更 | 審查後合併 |
| `lib/route/router_provider.dart` | 路由變更 | 審查後合併 |
| `lib/utils.dart` | SI 單位變更 | 直接採用 1.2.8 版本 |
| `pubspec.yaml` | 版本差異 | 保留 2.0.0 版本號 |

### 3.2 修改/刪除衝突

| dev-1.2.8 檔案 | dev-2.0.0 狀態 | 處理方式 |
|---------------|---------------|----------|
| `lib/page/wifi_settings/providers/wifi_list_provider.dart` | 已刪除（重構至服務層） | 分析後決定是否需要 |
| `lib/page/wifi_settings/views/wifi_list_view.dart` | 已移動至 `views/main/` | 合併至新位置 |
| `lib/page/wifi_settings/views/wifi_list_simple_mode_view.dart` | 已移動至 `views/main/` | 合併至新位置 |
| `lib/page/instant_verify/views/components/speed_test_widget.dart` | 已刪除 | 評估是否需重建 |
| `lib/page/dashboard/views/components/port_and_speed.dart` | 已刪除 | 評估是否需重建 |

---

## 4. 實作計畫

### 4.1 前置準備

```bash
# 1. 確保本地分支最新
git fetch origin

# 2. 建立遷移工作分支
git checkout dev-2.0.0
git pull origin dev-2.0.0
git checkout -b feature/merge-1.2.8-features

# 3. 確認 dev-1.2.8 提交清單
git log --oneline dev-2.0.0..origin/dev-1.2.8
```

### 4.2 階段一：乾淨新增（預計 1-2 小時）

#### 任務 1.1: PWA 功能移植

**執行步驟**:

```bash
# 複製 PWA 核心檔案
git checkout origin/dev-1.2.8 -- lib/core/pwa/
git checkout origin/dev-1.2.8 -- lib/core/utils/device_features.dart
git checkout origin/dev-1.2.8 -- lib/page/components/pwa/

# 複製 Web 資源
git checkout origin/dev-1.2.8 -- web/logo_icons/
git checkout origin/dev-1.2.8 -- web/service_worker.js

# 複製測試檔案
git checkout origin/dev-1.2.8 -- test/core/utils/device_features_test.dart
git checkout origin/dev-1.2.8 -- test/page/components/pwa/
```

**手動調整**:
1. 更新 `lib/page/components/pwa/` 的 import 路徑
2. 在 `lib/page/components/styled/top_bar.dart` 整合 PWA banner
3. 更新 `web/index.html` 和 `web/manifest.json`（手動合併）
4. 註冊 `PwaInstallService` 至 Provider 樹

**驗證**:
```bash
flutter analyze lib/core/pwa/
flutter analyze lib/page/components/pwa/
flutter test test/core/utils/device_features_test.dart
flutter test test/page/components/pwa/
```

---

#### 任務 1.2: 品牌資源 Provider 移植

**執行步驟**:

```bash
# 複製新 Provider
git checkout origin/dev-1.2.8 -- lib/providers/global_model_number_provider.dart
```

**手動調整**:
1. 檢視 `lib/providers/brand_asset_provider.dart` 差異
2. 合併 `BrandAssetType` 列舉和相關方法
3. 更新 Provider 註冊（若需要）

**驗證**:
```bash
flutter analyze lib/providers/
```

---

#### 任務 1.3: 工具函式更新

**執行步驟**:

```bash
# 查看差異
git diff dev-2.0.0 origin/dev-1.2.8 -- lib/utils.dart
```

**手動調整**:
1. 合併 SI 單位格式化函式
2. 更新相關測試

**驗證**:
```bash
flutter test test/utils_test.dart
```

---

#### 任務 1.4: 型號啟用設定

**執行步驟**:

```bash
# 查看 SPNM62/M62 相關變更
git show 7dae63b6 --stat
```

**手動調整**: 根據變更內容調整設定

---

### 4.3 階段二：中度整合（預計 2-3 小時）

#### 任務 2.1: HealthCheckServer 模型建立

**執行步驟**:

```bash
# 複製模型檔案
git checkout origin/dev-1.2.8 -- lib/page/health_check/models/health_check_server.dart
```

**手動調整**:
1. 確認模型與現有架構相容
2. 更新 barrel export 檔案

---

#### 任務 2.2: 伺服器選擇對話框移植

**執行步驟**:

```bash
# 複製 UI 元件
git checkout origin/dev-1.2.8 -- lib/page/health_check/views/components/speed_test_server_selection_dialog.dart
```

**手動調整**:
1. 調整 import 路徑
2. 確認與現有 `HealthCheckState` 相容
3. 更新對話框使用的狀態來源

---

#### 任務 2.3: 更新 HealthCheckState

**手動實作**:

在現有 `lib/page/health_check/providers/health_check_state.dart` 新增：

```dart
// 新增欄位
final List<HealthCheckServer> servers;
final HealthCheckServer? selectedServer;

// 更新 copyWith
HealthCheckState copyWith({
  // ... 現有欄位
  List<HealthCheckServer>? servers,
  HealthCheckServer? selectedServer,
}) {
  return HealthCheckState(
    // ... 現有欄位
    servers: servers ?? this.servers,
    selectedServer: selectedServer ?? this.selectedServer,
  );
}
```

---

#### 任務 2.4: 更新 SpeedTestView

**手動調整**:
1. 比對 `speed_test_view.dart` 差異
2. 整合伺服器選擇 UI
3. 適配新的狀態模型

---

### 4.4 階段三：架構適配（預計 3-4 小時）

#### 任務 3.1: SpeedTest 錯誤處理整合

**分析 dev-1.2.8 實作**:
```bash
git show dffec0dc -- lib/page/health_check/providers/health_check_provider.dart
```

**手動實作**:
1. 在 `SpeedTestError` enum 新增必要錯誤類型
2. 在 `HealthCheckProvider` 實作錯誤處理邏輯
3. 更新 UI 顯示錯誤訊息

---

#### 任務 3.2: Polling Provider 快取整合

**分析差異**:
```bash
git diff dev-2.0.0 origin/dev-1.2.8 -- lib/core/jnap/providers/polling_provider.dart
```

**手動調整**:
1. 整合 `GetCloseHealthCheckServers` 快取邏輯
2. 確保與現有 polling 機制相容

---

#### 任務 3.3: Dashboard SpeedTest Widget 評估

**決策點**:
- `lib/page/dashboard/views/components/port_and_speed.dart` 已在 dev-2.0.0 刪除
- 需評估是否需要在新架構中重建此功能

**選項**:
1. 在新 Dashboard 架構中重新實作
2. 暫時不移植此功能
3. 建立新的 Dashboard 元件

---

#### 任務 3.4: InstantVerify SpeedTest Widget 評估

**決策點**:
- `lib/page/instant_verify/views/components/speed_test_widget.dart` 已在 dev-2.0.0 刪除
- 需評估是否需要重建

---

### 4.5 驗證與收尾

#### 任務 4.1: 完整測試

```bash
# 執行所有測試
./run_tests.sh

# 執行 UI 測試
flutter test --tags ui

# 執行 health_check 相關測試
flutter test test/page/health_check/
```

#### 任務 4.2: 建置驗證

```bash
# Web 建置
./build_web.sh

# 本機執行
flutter run -d chrome
```

#### 任務 4.3: 程式碼審查

- [ ] 確認所有 import 路徑正確
- [ ] 確認無未使用的程式碼
- [ ] 確認測試覆蓋率
- [ ] 執行 `flutter analyze` 無錯誤

---

## 5. 風險評估

### 5.1 技術風險

| 風險 | 影響 | 機率 | 緩解措施 |
|------|------|------|----------|
| HealthCheckState 整合失敗 | 高 | 中 | 準備回退方案，分階段整合 |
| PWA 功能與現有架構不相容 | 中 | 低 | PWA 為獨立模組，風險可控 |
| Dashboard 功能缺失 | 中 | 中 | 記錄缺失功能，後續補齊 |
| 測試覆蓋不足 | 中 | 中 | 增加手動測試項目 |

### 5.2 回退計畫

```bash
# 如遇嚴重問題，可回退至 dev-2.0.0
git checkout dev-2.0.0
git branch -D feature/merge-1.2.8-features
```

---

## 6. 時程估計

| 階段 | 預估時間 | 說明 |
|------|----------|------|
| 前置準備 | 0.5 小時 | 環境準備、分支建立 |
| 階段一 | 1-2 小時 | 乾淨新增功能 |
| 階段二 | 2-3 小時 | 中度整合 |
| 階段三 | 3-4 小時 | 架構適配 |
| 驗證收尾 | 1-2 小時 | 測試與審查 |
| **總計** | **8-12 小時** | - |

---

## 7. 檢查清單

### 7.1 階段一完成檢查

- [ ] PWA 功能可正常運作
- [ ] device_features.dart 測試通過
- [ ] GlobalModelNumberProvider 正確註冊
- [ ] SI 單位格式化正確
- [ ] 無 analyze 錯誤

### 7.2 階段二完成檢查

- [ ] HealthCheckServer 模型可用
- [ ] 伺服器選擇對話框正常顯示
- [ ] HealthCheckState 新欄位正確運作
- [ ] SpeedTestView 可選擇伺服器

### 7.3 階段三完成檢查

- [ ] SpeedTest 錯誤正確處理並顯示
- [ ] Polling 快取正常運作
- [ ] Dashboard/InstantVerify 功能評估完成
- [ ] 所有測試通過

### 7.4 最終檢查

- [ ] `flutter analyze` 無錯誤
- [ ] `./run_tests.sh` 全部通過
- [ ] Web 建置成功
- [ ] PR 準備就緒

---

## 8. 附錄

### 8.1 相關提交 SHA

```
dev-1.2.8 獨有提交：
d7d14197 - feat: restrict PWA install banner to 'DU' models only (#609)
dffec0dc - fix: handle SpeedTestExecutionError and fix date parsing (#607)
09e12846 - Refactor: Optimize Brand Asset Loading and Fix Model Number State Loss (#600)
8f3db457 - chore: update build_web.sh
162ac087 - style: apply PR suggestions for robustness and clarity
ca1717b2 - fix: update network speed formatting to use SI units (base 1000)
7dae63b6 - fix: enable speed test for SPNM62 and M62 models
f9b41751 - init commit for 1.2.8 version
```

### 8.2 參考文件

- [架構分析文件](../architecture_analysis_2026-01-16.md)
- [服務層規格](../service-domain-specifications.md)
- [Speed Test 規格](../speedtest.md)

### 8.3 更新紀錄

| 日期 | 版本 | 變更說明 |
|------|------|----------|
| 2026-02-04 | 1.0 | 初始版本 |
