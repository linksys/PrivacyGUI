# UI Kit 遷移技術備註 (Migration Technical Notes)

本文檔記錄遷移過程中的技術細節、組合元件、工具類別和其他重要備註。

---

## 🧩 組合元件清單 (Composed Components)

當 ui_kit 沒有直接對應的元件，但可透過組合現有元件完成時，在 PrivacyGUI 專案建立組合元件。

### 組合元件規則
1. **統一放置**: `lib/page/components/composed/` 目錄
2. **使用 ui_kit 元件**: 完全基於 ui_kit 元件組合實作
3. **文檔說明**: 在組合元件檔案中加入完整說明
4. **後續評估**: 考慮是否需要移至 ui_kit_library

### 已建立的組合元件

| 組合元件名稱 | 檔案位置 | 組合方式 | 狀態 |
|-------------|---------|---------|------|
| `BreathDot` | `lib/page/components/composed/breath_dot.dart` | 純 Flutter 動畫元件 | ✅ 完成 |
| `AppPanelWithValueCheck` | `lib/page/components/composed/app_panel_with_value_check.dart` | `AppText` + `AppIcon.font` + `Container` + `Border` | ✅ 完成 |
| `AppListCard` | `lib/page/components/composed/app_list_card.dart` | `AppCard` + `Row` + `Column` + `AppSpacing` | ✅ 完成 |

---

## 🔧 工具類別清單 (Utility Classes)

為了支援 ui_kit 遷移而建立的工具類別。

| 工具類別名稱 | 檔案位置 | 替代功能 | 狀態 | 備註 |
|-------------|---------|---------|------|------|
| `DeviceImageHelper` | `lib/core/utils/device_image_helper.dart` | 替代 `CustomTheme.getRouterImage()` | ✅ 完成 | 🔄 **考慮遷移至 ui_kit**: 若多處使用則考慮提升為正式 ui_kit 元件 |

### DeviceImageHelper 詳細說明

**功能說明**：
- **替代 CustomTheme.getRouterImage()**: 完全重現原始邏輯
- **Assets 整合**: 使用 `Assets.images.devices.*` 和 `Assets.images.devicesXl.*`
- **類型安全**: 返回 `ImageProvider` 而非動態類型
- **效能優化**: 使用 switch 語句替代動態查找

**支援的路由器型號**：
- Standard (100x100): WHW01, WHW03, MR7350, EA8300, MX6200, WHW03B, EA9350, LN12, WHW01P, LN11, MX5300, WHW01B, MR7500, MR6350
- XL (120x120): MX6200, LN12

**Fallback 邏輯**：
1. 優先使用指定型號的 XL 版本（如果 xl=true）
2. 回退到指定型號的標準版本
3. 最終回退到 MX6200 作為預設路由器圖片

**技術備註**：
- ✅ **ImageProvider 相容**: 直接相容 Flutter Image widget
- ✅ **PNG 格式**: 避免 SVG ImageProvider 相容性問題
- 🔄 **待評估**: 考慮將 DeviceImageHelper 遷移至 ui_kit_library

---

## 🧮 本地模型清單 (Local Models)

從 privacygui_widgets 提取到 PrivacyGUI 專案的模型類別。

| 模型名稱 | 檔案位置 | 來源 | 狀態 |
|---------|---------|------|------|
| `AppSectionItemData` | `lib/page/models/app_section_item_data.dart` | 從 `privacygui_widgets` 提取 | ✅ 完成 |

---

## ⚠️ 已知限制和注意事項 (Known Limitations)

### ui_kit 限制

#### 1. Radius 定義缺失
**問題**: ui_kit_library **沒有導出** radius 相關的定義或常數。

**解決方案**: 使用標準 Flutter `BorderRadius.circular()` 值。

**常用圓角值對照**：
| 用途 | 建議值 | 說明 |
|-----|-------|------|
| 卡片 | `BorderRadius.circular(8)` | 標準卡片圓角 |
| 按鈕 | `BorderRadius.circular(6)` | 按鈕圓角 |
| 輸入框 | `BorderRadius.circular(4)` | 表單元件圓角 |
| 大型容器 | `BorderRadius.circular(12)` | 大型卡片或對話框 |

> [!WARNING]
> ui_kit 未來可能會新增 radius 定義。在該功能可用前，建議使用統一的標準值以便後續遷移。

#### 2. 部分元件 API 差異

**AppGap const 問題**：
- `privacygui_widgets`: `const AppGap.medium()`
- `ui_kit`: `AppGap.lg()` (**非 const**)
- **修正**: 必須移除 `const` 關鍵字

**AppIconButton Icon 類型**：
- 舊版: `AppIconButton(icon: LinksysIcons.refresh)` (IconData)
- 新版: `AppIconButton(icon: Icon(LinksysIcons.refresh))` (Widget)

**不支援的屬性**：
- **AppSwitch**: 新版不支援 `semanticLabel`
- **AppText**: 新版不支援 `maxLines`, `overflow`
- **AppPasswordInput**: 不支援 `focusNode`、`onValidationChanged`
- **AppTextFormField**: 不支援 `focusNode`、`helperText`、`errorText`、`onSubmitted`

### 遷移模式最佳實踐

#### 歧義導入處理 (Ambiguous Imports)
當 ui_kit 和 privacygui_widgets 都有同名元件時：
```dart
import 'package:ui_kit_library/ui_kit.dart';
// 隱藏不需要使用的那個庫的元件（通常是 privacygui_widgets）
import 'package:privacygui_widgets/widgets/buttons/button.dart' hide AppIconButton;
```

#### 嵌套滾動衝突處理
當 `UiKitPageView` 設定 `scrollable: true` 時，內部**不要**再使用 `SingleChildScrollView`：
```dart
// ❌ 錯誤：嵌套滾動
UiKitPageView(
  scrollable: true,
  child: SingleChildScrollView(child: Column(...))
)

// ✅ 正確：移除內部滾動
UiKitPageView(
  scrollable: true,
  child: Column(...)
)
```

---

## 📚 進階遷移技術

### AppStyledText 完整遷移
ui_kit 版本的 AppStyledText 使用內建標籤系統：

**標籤對照**：
```dart
// 舊版本 (privacygui_widgets)
AppStyledText(
  text,
  styleTags: {'span': TextStyle(...)},
  defaultTextStyle: textStyle,
  callbackTags: {},
);

// 新版本 (ui_kit_library) - 使用 theme 標籤
AppStyledText(text: 'Text with <color>styled</color> content')

// 新版本 - 含可點擊連結 (語法 1: Mustache 語法)
AppStyledText(
  text: 'Agree to {{terms:Terms of Service}}',
  onTapHandlers: {'terms': () => showTerms()},
)

// 新版本 - 含可點擊連結 (語法 2: HTML Anchor 語法)
// 適用於本地化字串中已包含 <a> 標籤的情況 (例如 "Learn more <a>here</a>")
AppStyledText(
  text: loc(context).descriptionWithLink, // "Click <a>here</a>"
  onTapHandlers: {
    'a': () => handleLinkClick(),
  },
)
```

**支援的內建標籤**: `<b>`, `<i>`, `<u>`, `<color>`, `<large>`, `<small>`, `<a>` (需配合 onTapHandlers)

### Focus 處理模式
當 ui_kit 元件不支援 `focusNode` 時：
```dart
// 使用 Focus widget 包裝
Focus(
  focusNode: hintFocusNode,
  child: AppTextFormField(
    controller: _hintController,
    label: loc(context).routerPasswordHintOptional,
    onChanged: (value) { ... },
  ),
),
```

---

## 🔍 除錯和診斷

### 常見問題診斷

#### 1. 元件找不到 (Component Not Found)
**症狀**: `The method 'xxx' isn't defined for the type 'yyy'`
**解決**: 檢查 import 語句，確保沒有錯誤的 `hide` 語句

#### 2. Const 錯誤
**症狀**: `const` 關鍵字錯誤
**解決**: ui_kit 的 `AppGap` 和 `AppSpacing` 不是 const，需移除 `const`

#### 3. 響應式佈局問題
**症狀**: `1.col` 等語法錯誤
**解決**: 使用 `context.colWidth(1)` 替代

### 效能監控
遷移後建議監控的指標：
- **建置時間**: ui_kit 是否影響編譯速度
- **執行時記憶體**: 新元件的記憶體使用情況
- **渲染效能**: 複雜頁面的 FPS 表現

---

## 🌐 網路拓撲遷移 (Network Topology Migration)

### ui_kit 拓撲系統概覽

ui_kit_library 提供完整的 mesh 網路拓撲視覺化系統，包含：

**核心元件**:
- `AppTopology`: 主要拓撲視覺化入口點
- `TopologyTreeView`: 行動版樹狀視圖 (< 600px)
- `TopologyGraphView`: 桌面版圖形視圖 (≥ 600px)

**資料模型**:
- `MeshTopology`: 完整的網路拓撲資料
- `MeshNode`: 網路節點 (gateway, extender, client)
- `MeshLink`: 節點間的連接關係

**視圖模式**:
- `TopologyViewMode.auto`: 自動根據螢幕寬度切換
- `TopologyViewMode.tree`: 強制樹狀視圖
- `TopologyViewMode.graph`: 強制圖形視圖

### 現有系統分析

**networks.dart 中的 TreeView**:
- 使用 `flutter_fancy_tree_view` 第三方套件
- 資料來源: `instantTopologyProvider` → `RouterTreeNode` (基於 `TopologyModel`)
- 自訂的 `TopologyNodeItem.simple` 節點渲染器

**instant_topology 目錄**:
- 完整的拓撲管理系統
- 自訂的 `AppTreeNode<T>` 抽象類別
- `TopologyModel` 資料模型 (包含 deviceId, location, status 等)
- 節點類型: `OnlineTopologyNode`, `OfflineTopologyNode`, `RouterTopologyNode`, `DeviceTopologyNode`

### 資料適配器需求

需要建立適配器將現有的 `TopologyModel` + `RouterTreeNode` 結構轉換為 ui_kit 的 `MeshTopology` + `MeshNode`:

**對應關係**:
```dart
TopologyModel.isRouter == true  → MeshNodeType.gateway
TopologyModel.isRouter == false + children.isNotEmpty → MeshNodeType.extender
TopologyModel.isRouter == false + children.isEmpty → MeshNodeType.client

TopologyModel.isOnline == true  → MeshNodeStatus.online
TopologyModel.isOnline == false → MeshNodeStatus.offline

TopologyModel.deviceId → MeshNode.id
TopologyModel.location → MeshNode.name
TopologyModel.icon → MeshNode.iconData (需要圖標映射)
```

### 遷移策略 ✅ 已完成

**正確的遷移原則**：
- **ui_kit 負責**: 視覺呈現、響應式佈局、基本互動
- **PrivacyGUI 保留**: 所有業務邏輯、資料管理、JNAP 操作

#### Phase 1: 建立資料適配器 ✅
1. ✅ 建立 `TopologyAdapter` 工具類別
2. ✅ 實作 `RouterTreeNode` → `MeshTopology` 轉換
3. ✅ 處理圖標映射和節點類型判斷
4. ✅ 修正 API 對應 (使用正確的 ConnectionType 和 RSSI 映射)

#### Phase 2: networks.dart 遷移 ✅
1. ✅ 替換 `TreeView<RouterTreeNode>` 為 `AppTopology`
2. ✅ 使用適配器轉換資料格式
3. ✅ 保持現有的互動行為 (onTap 導航)

#### Phase 3: instant_topology_view.dart 遷移 ✅
1. ✅ **只替換視覺元件**: `flutter_fancy_tree_view` → `ui_kit AppTopology`
2. ✅ **保留所有業務邏輯**: 重啟、重置、配對、LED 閃爍等
3. ✅ **保留 JNAP 操作**: polling、spinner、錯誤處理、導航
4. ✅ **保留離線節點處理**: 移除節點的完整流程
5. ✅ 移除不再需要的 `tree_node_item.dart` 和 `node_action_menu.dart`

### 技術挑戰

1. **圖標映射**: `TopologyModel.icon` (String) → `MeshNode.iconData` (IconData)
2. **節點類型推斷**: 現有系統使用 sealed class，ui_kit 使用 enum
3. **載入狀態**: 現有系統的載入處理需要適配到 ui_kit 的載入骨架
4. **回呼函數**: ui_kit 使用不同的回呼簽名 (只傳遞 nodeId)

### 遷移結果總結 ✅

**成功完成的項目**：
- ✅ **視覺系統升級**: 從 flutter_fancy_tree_view 遷移到 ui_kit AppTopology
- ✅ **保留業務邏輯**: 所有 JNAP 操作、錯誤處理、狀態管理完整保留
- ✅ **響應式設計**: ui_kit 自動提供桌面/行動版切換
- ✅ **功能完整性**: 重啟、重置、配對、LED 閃爍、離線處理全部保留
- ✅ **程式碼清理**: 移除不再需要的舊視覺元件檔案
- ✅ **架構正確**: ui_kit 專注視覺，PrivacyGUI 保留業務邏輯

**架構優勢**：
- **清晰分離**: 視覺層 (ui_kit) 與業務層 (PrivacyGUI) 責任明確
- **向後相容**: TopologyAdapter 確保現有資料結構無需改動
- **維護性**: 業務邏輯集中在 PrivacyGUI，易於維護和測試
- **升級彈性**: 未來 ui_kit 升級不影響業務邏輯

---

## 📈 未來規劃

### 候選 ui_kit 提升項目
以下項目若在多個專案中使用，建議提升為 ui_kit_library 正式元件：

1. **DeviceImageHelper**: 路由器圖片管理工具
2. **AppListCard**: 清單卡片組合元件
3. **AppPanelWithValueCheck**: 帶狀態檢查的面板元件
4. **TopologyAdapter**: 拓撲資料適配器 (若其他專案有類似需求)

### 持續改進機會
- **自動化工具**: 建立 CLI 工具協助遷移
- **程式碼生成**: 自動生成組合元件模板
- **效能優化**: 定期檢視 ui_kit 使用效能
- **拓撲系統**: 評估是否將 TopologyAdapter 提升為 ui_kit 正式元件

---

## 🔥 WiFi 設定模組遷移技術發現 (2024-12-16)

### 重大 API 變更發現

#### Provider 方法參數格式標準化
在 WiFi 設定模組遷移中發現，`WifiBundleProvider` 的 API 已從 named parameters 改為 positional parameters：

```dart
// ❌ 舊版 API (不再有效)
.setWiFiSSID(value, radioID: radio.radioID)
.setWiFiPassword(value, radioID: radio.radioID)
.setWiFiSecurityType(value, radioID: radio.radioID)

// ✅ 新版 API (當前有效)
.setWiFiSSID(value, radio.radioID)
.setWiFiPassword(value, radio.radioID)
.setWiFiSecurityType(value, radio.radioID)
```

#### 屬性名稱規範化
發現多個屬性名稱已標準化：

```dart
// 屬性更名
radio.isBroadcastSSID → radio.isBroadcast
radio.availableChannelWidths → radio.availableChannels.keys.toList()

// 方法更名
.setWiFiBroadcastSSID() → .setEnableBoardcast()
.setWiFiChannelWidth() → .setChannelWidth()
.setWiFiChannel() → .setChannel()
.showWiFiChannelModal() → .showChannelModal()
```

#### Modal 方法參數數量變更
多個 modal 方法的參數需求已變更：

```dart
// showWirelessWiFiModeModal: 3 → 5 參數
showWirelessWiFiModeModal(
  radio.wirelessMode,           // mode
  radio.defaultMixedMode,       // defaultMixedMode
  availableModes,               // list
  availableModes,               // availablelist
  (value) => {...}              // onSelected
);

// showChannelWidthModal: 3 → 4 參數
showChannelWidthModal(
  radio.channelWidth,                    // channelWidth
  radio.availableChannels.keys.toList(), // list
  radio.availableChannels.keys.toList(), // validList
  (value) => {...}                       // onSelected
);

// showChannelModal: 3 → 4 參數
showChannelModal(
  radio.channel,                               // channel
  radio.availableChannels[radio.channelWidth] ?? [], // list
  radio.radioID,                              // band
  (value) => {...}                            // onSelected
);
```

### UI Kit API 細節發現

#### AppPasswordInput 參數變更
```dart
// ❌ 舊版 privacygui_widgets
AppPasswordField(
  validations: [
    Validation(description: '...', validator: (text) => ...)
  ]
)

// ✅ 新版 ui_kit
AppPasswordInput(
  rules: [
    AppPasswordRule(label: '...', validate: (text) => ...)
  ]
)
```

#### AppIcon.font 不支援 semanticLabel
```dart
// ❌ 不支援
AppIcon.font(AppFontIcons.edit, semanticLabel: 'edit')

// ✅ 正確用法
AppIcon.font(AppFontIcons.edit)
```

#### AppTextFormField 不支援 decoration
ui_kit 的 `AppTextFormField` 不支援 `decoration` 參數，需移除此參數。

### ServiceHelper 整合模式
發現正確的 ServiceHelper 整合模式：

```dart
// 在 State class 中
class _MyWidgetState extends State<MyWidget> {
  // DI 整合
  final serviceHelper = getIt<ServiceHelper>();

  // 使用正確的方法名稱
  if (serviceHelper.isSupportMLO()) {
    // MLO 功能邏輯
  }
}

// 必要 imports
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
```

### 遷移驗證策略
建立了系統性的錯誤修正流程：
1. **Import 檢查**: 確保 ui_kit 優先導入
2. **API 對應**: 驗證所有方法呼叫的參數格式
3. **屬性驗證**: 檢查模型屬性是否更名
4. **編譯驗證**: `flutter analyze` 零錯誤目標
5. **功能驗證**: 確保 UI 行為一致

*WiFi 設定遷移完成：2024-12-16*
*最後更新：2024-12-16*