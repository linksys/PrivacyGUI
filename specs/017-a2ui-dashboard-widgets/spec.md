# Feature Specification: A2UI Dashboard Widget Extension

**Feature Branch**: `017-a2ui-dashboard-widgets`  
**Created**: 2026-01-19  
**Status**: Approved  
**Input**: User description: "透過 A2UI 協議來擴充 Dashboard Widget，保留現有原生元件，支援資料綁定與 USP 相容性設計"

## User Scenarios & Testing

### User Story 1 - 預定義 A2UI Widget 顯示於 Dashboard (Priority: P1)

系統預載 A2UI Widget 定義，使用者進入 Dashboard 時可看到這些擴充 Widget 與原生 Widget 並列顯示。

**Why this priority**: 這是 A2UI 擴充功能的核心價值驗證，確保基礎架構正確運作。

**Independent Test**: 啟動應用後，進入 Dashboard 即可驗證預定義 Widget 是否正確渲染。

**Acceptance Scenarios**:

1. **Given** 應用啟動且 A2UI Registry 已載入預定義 Widget, **When** 使用者進入 Dashboard, **Then** A2UI Widget 與原生 Widget 並列顯示於 Grid 中
2. **Given** A2UI Widget 已顯示, **When** Widget 需要顯示資料綁定值, **Then** 正確顯示來自 Router 的即時資料

---

### User Story 2 - A2UI Widget 拖拉縮放 (Priority: P1)

使用者可以在 Dashboard 編輯模式中對 A2UI Widget 進行拖拉、縮放操作，且操作受 Widget 約束限制。

**Why this priority**: 與原生 Widget 的操作一致性是核心需求。

**Independent Test**: 進入編輯模式，對 A2UI Widget 進行拖拉/縮放操作。

**Acceptance Scenarios**:

1. **Given** Dashboard 處於編輯模式, **When** 使用者拖拉 A2UI Widget, **Then** Widget 移動至新位置
2. **Given** Dashboard 處於編輯模式, **When** 使用者縮放 A2UI Widget 超出約束範圍, **Then** Widget 回彈至約束邊界

---

### User Story 3 - 資料綁定即時更新 (Priority: P2)

A2UI Widget 的資料綁定值能隨 Router 狀態變化即時更新顯示。

**Why this priority**: 確保動態資料顯示功能正確運作。

**Independent Test**: 觀察設備數量變化時 Widget 是否即時更新。

**Acceptance Scenarios**:

1. **Given** A2UI Widget 綁定 `router.deviceCount`, **When** 設備數量變化, **Then** Widget 顯示的數值即時更新

---

### User Story 4 - 版面持久化 (Priority: P2)

包含 A2UI Widget 的 Dashboard 版面可以正確儲存與載入。

**Why this priority**: 確保使用者自訂版面不會遺失。

**Independent Test**: 調整版面後重新載入頁面，確認版面維持。

**Acceptance Scenarios**:

1. **Given** 使用者調整了 A2UI Widget 位置, **When** 離開並重新進入 Dashboard, **Then** A2UI Widget 維持調整後的位置

---

### Edge Cases

- A2UI Widget 定義的 widgetId 與原生 Widget 衝突時如何處理？
- 資料路徑不存在時 Widget 如何顯示？
- Widget JSON 格式錯誤時如何優雅降級？

## Requirements

### Functional Requirements

- **FR-001**: 系統 MUST 支援從預定義 JSON 註冊 A2UI Widget
- **FR-002**: A2UI Widget MUST 能在 SliverDashboard Grid 中顯示
- **FR-003**: A2UI Widget MUST 支援拖拉/縮放操作
- **FR-004**: A2UI Widget MUST 遵守定義的 Grid 約束（min/max columns/rows）
- **FR-005**: A2UI Widget MUST 支援資料綁定（`$bind` 語法）
- **FR-006**: 資料路徑 MUST 使用點分隔抽象格式（如 `router.deviceCount`）
- **FR-007**: A2UI Widget 定義 MUST 可指定單一約束（DisplayMode 為可選）
- **FR-008**: 版面持久化 MUST 正確儲存/載入 A2UI Widget 位置與大小

### Key Entities

- **A2UIWidgetDefinition**: Widget 完整定義，包含 id、約束、模板
- **A2UITemplateNode**: 模板節點樹，定義 UI 結構
- **DataPath**: 抽象資料路徑，映射至實際資料來源

## Success Criteria

### Measurable Outcomes

- **SC-001**: 預定義 A2UI Widget 100% 正確渲染於 Dashboard
- **SC-002**: A2UI Widget 拖拉/縮放操作與原生 Widget 行為一致
- **SC-003**: 資料綁定更新延遲 < 100ms
- **SC-004**: 版面持久化成功率 100%
