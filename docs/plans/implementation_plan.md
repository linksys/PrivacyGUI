# Unified Diagnostics UI Redesign

## 背景

目前的 Diagnostics UI 全部集中在一個 **1248 行的單一檔案** ([unified_diagnostics_view.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/unified_diagnostics/views/unified_diagnostics_view.dart))。功能可以運作，但存在以下 UX 問題：

1. **結果頁面不直覺**：所有診斷結果以扁平的 Card 列表呈現，使用者無法一眼判斷「問題卡在哪個環節」
2. **執行中畫面缺乏回饋**：只有一個 `LinearProgressIndicator` + spinner，使用者不知道每一步的狀態
3. **Monolithic 檔案**：所有私有 Widget 都塞在同一個檔案裡，不利於維護和 UI 元件複用
4. **起始頁面過於簡單**：只有兩個按鈕，沒有視覺引導

## User Review Required

> [!IMPORTANT]
> **UI 設計偏好確認**：以下提案包含「網路路徑拓撲圖」的設計方向（類似 `Router → Gateway → DNS → Internet` 的視覺化節點鏈）。請確認這是否符合你期望的「直覺且清楚」的方向，或者你有其他偏好的 UI 風格（例如儀表板式、時間軸式等）。

> [!IMPORTANT]
> **Article XIV 合規確認**：計劃中所有 UI 元件皆使用 `ui_kit_library`（`AppCard`, `AppText`, `AppButton`, `AppGap`, `AppLoader` 等）。若提案中需要 UI Kit 目前沒有的元件（例如 Stepper 或 Timeline），會在實作時先停下來詢問你如何處理。

## Decisions (User Approved)

1. **結果頁面的資訊密度** → 預設收合，點擊展開 + 提供「Expand All」按鈕
2. **匯出/分享診斷報告** → ✅ 新增列印或下載功能（Phase 5）
3. **多語系** → 暫不處理，先用英文

---

## Proposed Changes

### 核心設計理念

將診斷流程視覺化為一條**網路路徑鏈 (Network Path)**，讓使用者直覺地看到：
- 每一步檢查的是什麼
- 每一步的當前狀態（等待中 / 執行中 / 通過 / 失敗 / 跳過）
- 問題卡在哪個節點

```
  [Router] ──→ [Gateway] ──→ [DNS] ──→ [Internet] ──→ [Speed]
     ✅           ✅          ⚠️          ❌
```

---

### Phase 1: 拆分 View 為模組化 Widget（結構重構）

> 不改變任何邏輯行為，純粹將 1248 行的 monolithic view 拆成可維護的獨立 Widget 檔案。

#### [MODIFY] [unified_diagnostics_view.dart](file:///Users/austin.chang/flutter-workspaces/privacyGUI/PrivacyGUI/lib/page/unified_diagnostics/views/unified_diagnostics_view.dart)
- 保留為主頁面 scaffold，只負責路由 `state.step` 到對應的子 Widget
- 移除所有私有 Widget class（`_ProblemCard`, `_FlowCard`, `_StepResultTile`, `_SpeedGauge`, `_RecommendationCard`, `_TracerouteDetailCard` 等）

#### [NEW] `lib/page/unified_diagnostics/views/widgets/diagnostic_start_view.dart`
- 起始頁面（Run Full Diagnostic + Choose Specific Issue）

#### [NEW] `lib/page/unified_diagnostics/views/widgets/diagnostic_flow_menu.dart`
- Flow 選單頁面（Internet / Device Issues / WiFi Coverage / Intermittent）

#### [NEW] `lib/page/unified_diagnostics/views/widgets/diagnostic_running_view.dart`
- 執行中頁面（步驟動畫 + 即時狀態回饋）

#### [NEW] `lib/page/unified_diagnostics/views/widgets/diagnostic_results_view.dart`
- 結果頁面（拓撲圖 + 摘要 + 建議）

#### [NEW] `lib/page/unified_diagnostics/views/widgets/step_result_tile.dart`
- 單一步驟結果的展示 Widget（可展開/收合的細節）

#### [NEW] `lib/page/unified_diagnostics/views/widgets/speed_test_result_card.dart`
- Speed Test 結果卡片（Download / Upload gauge）

#### [NEW] `lib/page/unified_diagnostics/views/widgets/recommendation_card.dart`
- 建議卡片

#### [NEW] `lib/page/unified_diagnostics/views/widgets/traceroute_detail_card.dart`
- Traceroute 詳細 hop 列表

---

### Phase 2: 重新設計「執行中」頁面

> 目標：讓使用者在診斷執行時，能即時看到每一步的進度和狀態。

#### [MODIFY] `diagnostic_running_view.dart`

**目前的問題**：
- 只有一個 spinner 和「Step X of Y」，使用者看不到每一步的狀態

**改善方向**：
- **垂直步驟列表 (Vertical Stepper)**：每個步驟顯示為一個節點
  - `○` 等待中（灰色）
  - `◎` 執行中（動畫脈衝 + 文字標籤）
  - `✅` 通過
  - `⚠️` 有警告
  - `❌` 失敗
  - `⊘` 跳過
- 已完成的步驟直接在節點旁邊顯示摘要（例如 `Gateway: 15ms`）
- 步驟之間用垂直虛線連接，形成「路徑感」

**UI 結構（偽碼）**：
```
Column(
  ── FlowHeader(icon, title)
  ── Expanded(
       ListView(
         ── StepNode(WAN Status,     ✅, "Up / 192.168.1.100")
         ── StepNode(DHCP,           ✅, "OK")  
         ── StepNode(Gateway Ping,   ◎, "Pinging 192.168.1.1...")  ← 當前步驟
         ── StepNode(DNS Ping,       ○, null)
         ── StepNode(DNS Lookup,     ○, null)
         ── StepNode(Internet Ping,  ○, null)
       )
     )
  ── CancelButton
)
```

---

### Phase 3: 重新設計「結果」頁面

> 目標：讓使用者一眼看出問題在哪、該怎麼修。

#### [MODIFY] `diagnostic_results_view.dart`

**目前的問題**：
- 所有結果以扁平 Card 列表呈現，沒有按嚴重程度分組
- 錯誤和正常的結果混在一起，使用者需要逐一掃描

**改善方向**：

1. **頂部摘要卡片 (Summary Card)**：
   - 大圖示 + 狀態文字（Issues Found / All OK）
   - 快速統計：`3 Passed, 1 Warning, 1 Failed`
   - 若有 Speed Test 結果，嵌入 Download/Upload 數據

2. **問題優先排序 (Issues First)**：
   - ❌ 錯誤在最上面（紅色邊框 Card）
   - ⚠️ 警告其次（橘色邊框 Card）
   - ✅ 通過的結果預設收合（只顯示一行摘要），點擊可展開

3. **可展開的結果 Tile**：
   - 預設：圖示 + 標題 + 一句話摘要
   - 展開後：顯示完整的 key-value 細節表格
   - 使用 `ExpansionTile` 或類似的 UI Kit 元件

4. **建議區塊重新設計**：
   - 每條建議有明確的優先級標籤
   - 若有可執行的 Action（例如 Renew DHCP），顯示操作按鈕

---

### Phase 4: 重新設計「起始」頁面

#### [MODIFY] `diagnostic_start_view.dart`

**改善方向**：
- 使用更有視覺衝擊力的圖示和排版
- 「Run Full Diagnostic」按鈕更大、更明顯
- 「Choose Specific Issue」改為可視化的圖示格子（grid layout），而非文字按鈕

---

### Phase 5: 診斷報告匯出/下載功能

#### [NEW] `lib/page/unified_diagnostics/views/widgets/diagnostic_report_export.dart`

**功能**：
- 在結果頁面的 Action 區域新增「Export Report」按鈕
- 將診斷結果格式化為可讀的純文字報告（包含時間戳、Firmware 版本、每步結果、建議）
- 使用 Flutter 的 `Share` API 或 `Clipboard` 複製到剪貼簿
- Web 平台：透過瀏覽器下載為 `.txt` 檔案

**報告格式範例**：
```
=== Linksys Network Diagnostics Report ===
Date: 2026-05-20 12:00:00
Flow: Internet Diagnostics

[✅] WAN Status: Up (192.168.1.100, DHCP)
[✅] DHCP: OK
[✅] Gateway Ping: 15ms (3/3 success)
[⚠️] DNS Ping: 120ms (3/3 success) — HIGH LATENCY
[❌] Internet Ping: Failed (0/3 success)

Speed Test: Download 85.2 Mbps / Upload N/A

Recommendations:
1. [HIGH] Internet Unreachable — Contact your ISP
2. [MED] DNS Latency — Try alternate DNS (8.8.8.8)
```

---

## 不修改的範圍

> [!NOTE]
> 本次重構**完全限縮在 `views/` 層**，以下檔案不會被修改：

- `providers/unified_diagnostics_notifier.dart` — 狀態機邏輯不變
- `services/unified_diagnostics_service.dart` — 業務邏輯不變
- `models/diagnostic_state.dart` — 狀態模型不變
- `models/diagnostic_result.dart` — 結果模型不變

這完全符合憲章 Article V Section 5.4 的三層架構原則：
> Presentation 層只負責 UI 渲染和使用者互動，不影響 Application 層。

---

## 憲章合規性檢查

| Article | 要求 | 合規性 |
|---------|------|--------|
| **Art. I** (Testing) | UI 變更需要測試 | ✅ Screenshot tests deferred (Sec 1.2)；Provider 測試已存在且通過 |
| **Art. III** (Naming) | snake_case 檔案、UpperCamelCase 類別 | ✅ 所有新檔案遵循規範 |
| **Art. V** (Simplicity) | 避免 over-engineering | ✅ 只拆分 View，不新增抽象層 |
| **Art. V Sec 5.4** (Architecture) | Views 只依賴 Providers | ✅ 不引入新的 Service 或 Model 依賴 |
| **Art. XIV** (UI Kit) | UI Kit First | ✅ 全部使用 `AppCard`, `AppText`, `AppButton` 等。若缺少元件會先詢問 |

---

## Verification Plan

### Automated Tests
```bash
# 1. 確保現有測試全部通過（純 View 重構不應破壞任何測試）
./run_tests.sh

# 2. 確保架構合規
grep -r "import.*generated/" lib/page/unified_diagnostics/views/
# ✅ 應該回傳 0 結果
```

### Manual Verification
- 在瀏覽器中啟動 Flutter Web，逐一檢查每個 Flow 的 UI 是否正確渲染
- 確認 Back 按鈕的行為在每個狀態下都正確
- 確認 Cancel 操作正確清理狀態
