# UI Kit 元件對應表 (Component Mapping Reference)

本文檔提供完整的元件對應表，涵蓋從 `privacygui_widgets` 和 Flutter 基礎元件到 `ui_kit_library` 的遷移對照。

---

## 📚 相關文檔

- **[MIGRATION_STRATEGY.md](./MIGRATION_STRATEGY.md)** - 遷移策略和準則
- **[MIGRATION_FINISH.md](./MIGRATION_FINISH.md)** - 遷移完成狀況
- **[MIGRATION_TEST_RESULT.md](./MIGRATION_TEST_RESULT.md)** - 測試結果記錄
- **[MIGRATION_NOTES.md](./MIGRATION_NOTES.md)** - 技術備註和組合元件

---

## 🎯 核心 UI 元件對應 (Core UI Components)

### 按鈕元件 (Button Components)

| privacygui_widgets | ui_kit_library | 變更說明 | 狀態 |
|-------------------|----------------|---------|------|
| `AppTextButton('Label', onTap: ...)` | `AppButton.text(label: 'Label', onTap: ...)` | 參數名稱: `text` → `label` | ✅ |
| `AppTextButton('Label', color: error, onTap: ...)` | `AppButton.dangerText(label: 'Label', onTap: ...)` | 紅色/警告按鈕使用 dangerText 變體 | ✅ |
| `AppTextButton.noPadding('Label', onTap: ...)` | `AppButton.text(label: 'Label', onTap: ...)` | 移除 noPadding 變體，使用標準 text button | ✅ |
| `AppFilledButton('Label', onTap: ...)` | `AppButton(label: 'Label', variant: SurfaceVariant.highlight, onTap: ...)` | 使用 variant 參數替代專門類別 | ✅ |
| `AppOutlinedButton('Label', onTap: ...)` | `AppButton(label: 'Label', variant: SurfaceVariant.tonal, onTap: ...)` | 使用 variant 參數替代專門類別 | ✅ |
| `AppElevatedButton('Label', onTap: ...)` | `AppButton(label: 'Label', variant: SurfaceVariant.highlight, onTap: ...)` | 合併至標準 AppButton | ✅ |
| `AppIconButton(icon: iconData, onTap: ...)` | `AppIconButton(icon: Widget, onTap: ...)` | Icon 類型: `IconData` → `Widget` (需包裝為 `Icon()`) | ✅ |
| `AppLoadableWidget.*` | `AppButton(isLoading: ...)` 或組合元件 | 優先使用 AppButton 內建 loading | ✅ |


### 文字元件 (Text Components)

| privacygui_widgets | ui_kit_library | 變更說明 | 狀態 |
|-------------------|----------------|---------|------|
| `AppText.displayLarge('Text')` | `AppText.displayLarge('Text')` | API 相同 | ✅ |
| `AppText.headlineLarge('Text')` | `AppText.headlineLarge('Text')` | API 相同 | ✅ |
| `AppText.titleLarge('Text')` | `AppText.titleLarge('Text')` | API 相同 | ✅ |
| `AppText.bodyLarge('Text')` | `AppText.bodyLarge('Text')` | API 相同 | ✅ |
| `AppText.labelLarge('Text')` | `AppText.labelLarge('Text')` | API 相同 | ✅ |
| `AppText.bodyMedium('Text')` | `AppText.bodyMedium('Text')` | API 相同 | ✅ |
| `AppText.bodySmall('Text')` | `AppText.bodySmall('Text')` | API 相同 | ✅ |
| `AppStyledText(text, styleTags: {...})` | `AppStyledText(text: '...', onTapHandlers: {...})` | 使用內建標籤與 `onTapHandlers` 處理連結 | ✅ |

### 輸入元件 (Input Components)

| privacygui_widgets | ui_kit_library | 變更說明 | 狀態 |
|-------------------|----------------|---------|------|
| `AppTextField(controller: ..., hint: ...)` | `AppTextFormField(controller: ..., label: ...)` | 參數名稱 `hint` → `label`；不支援 `errorText`，需改用 `validator` 配合 `AutovalidateMode` | ✅ |
| `AppPasswordField(controller: ..., validations: ...)` | `AppPasswordInput(controller: ..., rules: ...)` | 參數名稱: `validations` → `rules` <br>⚠️ **注意**: 不支援 `readOnly`，需使用 `IgnorePointer` 或等待 UI Kit 擴充 | ⚠️ |
| `AppValidatorWidget(...)` | **移除** | 功能已內建於 `AppPasswordInput` | ✅ |
| `AppIPFormField(...)` | `AppIpv4TextField(...)` | 專用 IP 輸入框，移除 `privacygui_widgets` 依賴 | ✅ |
| `AppMacAddressTextField(...)` | `AppMacAddressTextField(...)` | UI Kit 版本，新增 `errorText` 與 `invalidFormatMessage` 參數 | ✅ |
| `AppDropdownButton(items: ..., onChanged: ...)` | `AppDropdown<String>(...)` | ⚠️ 如遇複雜型別顯示問題，建議轉為 `String` 處理；API 為 `items` (List) + `label` (Title) | ✅ |
| `AppCheckbox(value: ..., onChanged: ...)` | `AppCheckbox(value: ..., onChanged: ...)` | API 相同 | ✅ |
| `AppSwitch(value: ..., onChanged: ...)` | `AppSwitch(value: ..., onChanged: ...)` | 不支援 `semanticLabel` | ⚠️ |
| `AppRadio<T>(value: ..., groupValue: ...)` | `AppRadio<T>(value: ..., groupValue: ...)` | API 相同 | ✅ |

### 佈局元件 (Layout Components)

| privacygui_widgets | ui_kit_library | 變更說明 | 狀態 |
|-------------------|----------------|---------|------|
| `AppCard(child: ...)` | `AppCard(child: ...)` | 支援 `onTap`；不再內建內容Padding，需自行包 `Padding` | ✅ |
| `Container(color: ...)` | `AppSurface(child: ...)` | 用於 surface 容器 <br>⚠️ **注意**: 不支援 `borderRadius` 自訂，預設有圓角 | ⚠️ |
| `AppListCard(title: ..., trailing: ...)` | **Composed Component** | 需使用組合元件 | ✅ |
| `AppBasicLayout(content: ...)` | **移除** | 改用 `UiKitPageView` 或直接排版 | ✅ |
| `StyledAppPageView(...)` | `UiKitPageView(...)` | 完全替換 | ✅ |
| `AppExpansionCard(...)` | `AppExpansionPanel.single(...)` | API 不同，需調整參數 | ✅ |

### 導航元件 (Navigation Components)

| privacygui_widgets | ui_kit_library | 變更說明 | 狀態 |
|-------------------|----------------|---------|------|
| `AppTabBar(tabs: ...)` | `AppTabBar(tabs: ...)` | API 相同 | ✅ |
| `AppBottomNavigationBar(items: ...)` | `AppBottomNavigationBar(items: ...)` | API 相同 | ✅ |
| `AppDrawer(...)` | `AppDrawer(...)` | API 相同 | ✅ |

---

## 🎨 視覺元件對應 (Visual Components)

### 狀態和標籤元件 (Status & Label Components)

| privacygui_widgets | ui_kit_library | 變更說明 | 狀態 |
|-------------------|----------------|---------|------|
| `AppStatusLabel(isOff: bool)` | `AppBadge(label: String, color: Color)` | API 完全不同，需邏輯轉換 | ✅ |
| `AppBadge(text: ...)` | `AppBadge(label: ...)` | 參數名稱: `text` → `label` | ✅ |
| `AppChip(label: ...)` | `AppChip(label: ...)` | API 相同 | ✅ |
| `FilterChip/ChoiceChip` | `AppChipGroup(chips: [...])` | 使用 `AppChipGroup` 進行 Chips 選擇管理 | ✅ |
| `AppTooltip(message: ...)` | `AppTooltip(message: ...)` | API 相同 | ✅ |

### 載入和進度元件 (Loading & Progress Components)

| privacygui_widgets | ui_kit_library | 變更說明 | 狀態 |
|-------------------|----------------|---------|------|
| `AppSpinner()` | `AppLoader()` | 使用 UI Kit 載入器，默認 circular | ✅ |
| `AppFullScreenSpinner` | `Scaffold + Center + AppLoader()` | 組合全屏載入 | ✅ |
| `CircularProgressIndicator()` | `AppLoader()` | 圓形載入器，默認 variant | ✅ |
| `LinearProgressIndicator()` | `AppLoader(variant: LoaderVariant.linear)` | 線性進度條 | ✅ |
| `AppLinearProgressIndicator(...)` | `AppLinearProgressIndicator(...)` | API 相同 | ✅ |
| `AppProgressBar(...)` | `AppProgressBar(...)` | API 相同 | ✅ |

### 圖標和圖片元件 (Icon & Image Components)

| privacygui_widgets | ui_kit_library | 變更說明 | 狀態 |
|-------------------|----------------|---------|------|
| `LinksysIcons.wifi` | `AppFontIcons.wifi` | 圖標庫名稱變更 | ✅ |
| `Icon(LinksysIcons.wifi)` | `AppIcon.font(AppFontIcons.wifi)` | 使用專門的圖標元件 | ✅ |
| `Icon(LinksysIcons.wifi, semanticLabel: ...)` | `AppIcon.font(AppFontIcons.wifi)` | 不支援 `semanticLabel`，需外層 `Semantics` | ⚠️ |
| `CustomTheme.getRouterImage(...)` | `DeviceImageHelper.getRouterImage(...)` | 使用工具類別替代 | ✅ |

---

## 🏗️ Flutter 基礎元件對應 (Flutter Base Components)

### 文字和輸入 (Text & Input)

| Flutter 基礎元件 | ui_kit_library | 變更說明 | 狀態 |
|-----------------|----------------|---------|------|
| `Text('Hello')` | `AppText.bodyMedium('Hello')` | 使用語義化文字樣式 | ✅ |
| `TextField(...)` | `AppTextFormField(...)` | 功能更完整的表單輸入框 | ✅ |
| `TextFormField(...)` | `AppTextFormField(...)` | 直接對應 | ✅ |
| `TextButton(...)` | `AppButton.text(...)` | 使用 ui_kit 統一按鈕系統 | ✅ |
| `ElevatedButton(...)` | `AppButton(variant: SurfaceVariant.highlight)` | 使用 variant 系統 | ✅ |
| `OutlinedButton(...)` | `AppButton(variant: SurfaceVariant.tonal)` | 使用 variant 系統 | ✅ |

### 圖片和媒體 (Image & Media)

| Flutter 基礎元件 | ui_kit_library | 變更說明 | 狀態 |
|-----------------|----------------|---------|------|
| `Image.asset('path/image.png')` | `AppImage.asset(image: Assets.images.xxx)` | 使用 ui_kit Assets 系統 | ✅ |
| `Image.network('url')` | `AppImage.network(url: 'url')` | 支援暗色主題和載入狀態 | ✅ |
| `Image(image: ImageProvider)` | `AppImage.provider(imageProvider: ImageProvider)` | 完整支援 ImageProvider | ✅ |
| `SvgPicture.asset('path.svg')` | `AppSvg('path.svg')` | 統一 SVG 處理 | ✅ |
| `SvgPicture(svgLoader)` | `Assets.images.xxx.svg()` | 使用 ui_kit Assets 系統 | ✅ |

### 佈局和容器 (Layout & Container)

| Flutter 基礎元件 | ui_kit_library | 變更說明 | 狀態 |
|-----------------|----------------|---------|------|
| `Card(child: ...)` | `AppCard(child: ...)` | 使用 ui_kit 主題樣式 | ✅ |
| `Container(decoration: ...)` | `AppCard(...)` | 當用於卡片樣式時 | ✅ |
| `Padding(padding: EdgeInsets.all(16))` | `Padding(padding: EdgeInsets.all(AppSpacing.md))` | 使用 ui_kit 間距系統 | ✅ |
| `SizedBox(height: 16)` | `AppGap.md()` | 使用語義化間距 | ✅ |
| `Divider()` | `Divider()` | 保持使用 Flutter 標準 | ✅ |

### 互動元件 (Interactive Components)

| Flutter 基礎元件 | ui_kit_library | 變更說明 | 狀態 |
|-----------------|----------------|---------|------|
| `IconButton(...)` | `AppIconButton(...)` | 使用 ui_kit 主題樣式 | ✅ |
| `Switch(...)` | `AppSwitch(...)` | 使用 ui_kit 主題樣式 | ✅ |
| `Checkbox(...)` | `AppCheckbox(...)` | 使用 ui_kit 主題樣式 | ✅ |
| `Radio<T>(...)` | `AppRadio<T>(...)` | 使用 ui_kit 主題樣式 | ✅ |
| `Slider(...)` | `AppSlider(...)` | 使用 ui_kit 主題樣式 | ✅ |

---

## 🎯 間距和佈局系統對應 (Spacing & Layout System)

### 間距元件 (Gap Components)

| privacygui_widgets | ui_kit_library | 像素值 | 狀態 |
|-------------------|----------------|--------|------|
| `AppGap.small()` | `AppGap.xs()` | 4px | ✅ |
| `AppGap.small2()` | `AppGap.sm()` | 8px | ✅ |
| `AppGap.small3()` | `AppGap.md()` | 12px | ✅ |
| `AppGap.medium()` | `AppGap.lg()` | 16px | ✅ |
| `AppGap.large()` | `AppGap.xl()` | 20px | ✅ |
| `AppGap.large2()` | `AppGap.xxl()` | 24px | ✅ |
| `AppGap.large3()` | `AppGap.xxxl()` | 32px | ✅ |

### 間距常數 (Spacing Constants)

| privacygui_widgets | ui_kit_library | 像素值 | const 支援 | 狀態 |
|-------------------|----------------|--------|------------|------|
| `Spacing.zero` | `AppSpacing.zero` | 0px | ❌ | ✅ |
| `Spacing.small1` | `AppSpacing.xs` | 4px | ❌ | ✅ |
| `Spacing.small2` | `AppSpacing.sm` | 8px | ❌ | ✅ |
| `Spacing.small3` | `AppSpacing.md` | 12px | ❌ | ✅ |
| `Spacing.medium` | `AppSpacing.lg` | 16px | ❌ | ✅ |
| `Spacing.large1` | `AppSpacing.xl` | 20px | ❌ | ✅ |
| `Spacing.large2` | `AppSpacing.xxl` | 24px | ❌ | ✅ |
| `Spacing.large3` | `AppSpacing.xxxl` | 32px | ❌ | ✅ |

> [!WARNING]
> ui_kit 的 `AppSpacing` 常數**非 const**，在 const 語境中需移除 `const` 關鍵字。同理 `AppGap` 的某些構造函數 (如 `.sm()`) 可能也非 const。

### 響應式佈局 (Responsive Layout)
> ⚠️ **重要**: 使用 UI Kit 的 `AppResponsiveLayout` 系統。

| privacygui_widgets | ui_kit_library | 變更說明 | 狀態 |
|-------------------|----------------|---------|------|
| `ResponsiveLayout.isMobileLayout(context)` | `context.isMobileLayout` | 使用 Project Extension (非 UI Kit 內建 isMobile) | ✅ |
| `ResponsiveLayout.isOverMedimumLayout(context)` | `!context.isMobile` | Context extension | ✅ |
| `ResponsiveLayout` | `AppResponsiveLayout` | 元件名稱變更 | ✅ |
| `1.col` | `context.colWidth(1)` | Context extension method | ✅ |
| `2.col` | `context.colWidth(2)` | Context extension method | ✅ |
| `4.col` | `context.colWidth(4)` | Context extension method | ✅ |
| `6.col` | `context.colWidth(6)` | Context extension method | ✅ |
| `8.col` | `context.colWidth(8)` | Context extension method | ✅ |
| `12.col` | `context.colWidth(12)` | Context extension method | ✅ |
| `1.gutter` | `context.gutterWidth(1)` | Context extension method | ✅ |

---

## 🎨 主題和樣式對應 (Theme & Style)

### 顏色系統 (Color System)

| privacygui_widgets | ui_kit_library | 變更說明 | 狀態 |
|-------------------|----------------|---------|------|
| `colorSchemeExt.green` | `AppColorScheme.semanticSuccess` | 語義化顏色 | ✅ |
| `colorSchemeExt.orange` | `AppColorScheme.semanticWarning` | 語義化顏色 | ✅ |
| `colorSchemeExt.red` | `AppColorScheme.semanticDanger` | 語義化顏色 | ✅ |
| `colorSchemeExt.primaryFixed` | `colorScheme.primaryFixed` | 移至 Material 標準 | ✅ |
| `colorSchemeExt.surfaceContainer` | `colorScheme.surfaceContainer` | 移至 Material 標準 | ✅ |

### 圓角半徑 (Border Radius)

| privacygui_widgets | ui_kit_library | 像素值 | 狀態 |
|-------------------|----------------|--------|------|
| `CustomTheme.radius.small` | `BorderRadius.circular(4)` | 4px | ✅ |
| `CustomTheme.radius.medium` | `BorderRadius.circular(8)` | 8px | ✅ |
| `CustomTheme.radius.large` | `BorderRadius.circular(12)` | 12px | ✅ |

> [!NOTE]
> ui_kit 目前**沒有導出** radius 定義，使用標準 Flutter `BorderRadius.circular()` 值。

---

## 🚫 已移除或不推薦元件 (Deprecated/Removed Components)

### 完全移除的元件

| privacygui_widgets | 替代方案 | 移除原因 | 狀態 |
|-------------------|---------|---------|------|
| `AppBasicLayout` | `UiKitPageView` 或直接排版 | 佈局模式過時 | 🚫 |
| `AppFullScreenSpinner` | `Center` + `CircularProgressIndicator` | 功能過於簡單 | 🚫 |

### 不推薦使用的元件

| privacygui_widgets | ui_kit_library | 不推薦原因 | 狀態 |
|-------------------|----------------|-----------|------|
| `AppTextButton.noPadding` | `AppButton.text` | 變體過於特殊 | ⚠️ |

---

## 🔧 特殊遷移情況 (Special Migration Cases)

### 需要邏輯轉換的元件

| 元件 | 舊邏輯 | 新邏輯 | 範例 |
|-----|-------|-------|------|
| `AppStatusLabel` | `isOff: true/false` | `label: String, color: Color` | `AppBadge(label: status ? 'Off' : 'On', color: ...)` |
| `AppExpansionCard` | `children: [Widget]` | `content: Widget` | 直接傳入單一 Widget 而非列表 |

### 需要組合元件的情況

| 缺失元件 | 組合方案 | 檔案位置 | 狀態 |
|---------|---------|---------|------|
| `AppListCard` | `AppCard` + `Row` + `Column` | `lib/page/components/composed/app_list_card.dart` | ✅ |
| `AppPanelWithValueCheck` | `AppText` + `AppIcon` + `Container` | `lib/page/components/composed/app_panel_with_value_check.dart` | ✅ |
| `AppBulletList` | `Column` + `Row` + `AppText` 自訂編號列表 | 參考 `speed_test_external.dart` 中 `_buildNumberedList()` | ✅ |

### 需要工具類別的情況

| 原始功能 | 工具類別 | 檔案位置 | 狀態 |
|---------|---------|---------|------|
| `CustomTheme.getRouterImage()` | `DeviceImageHelper` | `lib/core/utils/device_image_helper.dart` | ✅ |

### 主題設定重要事項

> [!IMPORTANT]
> DI 中的 ThemeData 必須使用 `AppTheme.create()` 創建，以確保包含 `AppDesignTheme` extension。
> 否則 UI Kit 元件 (如 `AppText`, `AppSurface`) 會拋出 "AppDesignTheme extension not found" 錯誤。

```dart
// lib/di.dart - 正確的主題注入方式
final darkTheme = AppTheme.create(
  brightness: Brightness.dark,
  seedColor: AppPalette.brandPrimary,
  designThemeBuilder: (scheme) => GlassDesignTheme.dark(scheme),
);
getIt.registerSingleton<ThemeData>(darkTheme, instanceName: 'darkThemeData');
```

> [!TIP]
> 對於強制使用深色主題的區域 (如 TopBar, BottomNavigationMenu)，使用 `Theme` widget 包裹並從 DI 獲取主題。

---

## 🔧 已解耦且複製到專案中的元件 (Decoupled Components)

以下元件已從 `privacygui_widgets` 複製到專案本地 `lib/page/components/composed/` 目錄，以解除相依性：

| 原始元件 | 本地版本 | 檔案位置 | 說明 |
|---------|---------|---------|------|
| `AppSwitchTriggerTile` | `AppSwitchTriggerTile` | `lib/page/components/composed/app_switch_trigger_tile.dart` | Switch 開關觸發區塊，UI Kit 無對應 |
| `MultiplePagesAlertDialog` | `MultiplePagesAlertDialog` | `lib/page/components/composed/multiple_pages_alert_dialog.dart` | 多頁對話框，改用 `AppButton.text` |
| `AppNodeListCard` | `AppNodeListCard` | `lib/page/components/composed/app_node_list_card.dart` | Node 列表卡片，使用 `AppCard` 重組 |
| `AppPopupButton` | `AppPopupButton` | `lib/page/components/composed/app_popup_button.dart` | 複雜 Overlay 元件，已從 privacygui_widgets 複製 |

### 仍需保留 privacygui_widgets 的元件

| 元件 | 原因 | 替代方案 |
|------|------|----------|
| `neutralTonal` / `primaryTonal` | 主題顏色系統 | 優先使用 `colorScheme.surface/onSurface` 或 `AppPalette.brandPrimary`，僅無法替代時才保留 |


---

## 🎯 快速查找表 (Quick Reference)

### 最常用元件對應

| 用途 | 舊元件 | 新元件 | 快速記憶 |
|-----|-------|-------|---------|
| **按鈕** | `AppTextButton` | `AppButton.text` | 加 `.text` 後綴 |
| **填充按鈕** | `AppFilledButton` | `AppButton(variant: SurfaceVariant.highlight)` | 用 variant 參數 |
| **間距** | `AppGap.medium()` | `AppGap.lg()` | medium → lg |
| **文字** | `AppText` | `AppText` | 完全相同 |
| **輸入** | `AppTextField` | `AppTextFormField` | 加 Form 後綴 |
| **圖標** | `LinksysIcons` | `AppFontIcons` | Linksys → AppFont |
| **載入** | `AppSpinner` | `AppLoader()` | 使用 UI Kit 載入器 |
| **線性進度** | `LinearProgressIndicator` | `AppLoader(variant: LoaderVariant.linear)` | 指定 linear variant |

### 參數名稱變更對照

| 舊參數名 | 新參數名 | 元件 |
|---------|---------|------|
| `text` | `label` | `AppButton` |
| `hint` | `label` | `AppTextFormField` |
| `validations` | `rules` | `AppPasswordInput` |
| `children` | `content` | `AppExpansionPanel` |
| `styleTags` | 內建標籤 | `AppStyledText` |

---

## 📊 遷移完成度統計

### 按類別統計

| 類別 | 總數 | 已遷移 | 需組合 | 已移除 | 完成度 |
|------|------|--------|--------|--------|--------|
| **按鈕元件** | 6 | 5 | 0 | 1 | 83% |
| **文字元件** | 8 | 8 | 0 | 0 | 100% |
| **輸入元件** | 6 | 5 | 0 | 0 | 83% |
| **佈局元件** | 5 | 3 | 2 | 1 | 80% |
| **視覺元件** | 12 | 10 | 0 | 2 | 83% |
| **間距系統** | 8 | 8 | 0 | 0 | 100% |
| **響應式系統** | 6 | 6 | 0 | 0 | 100% |
| **主題系統** | 8 | 8 | 0 | 0 | 100% |

### 整體統計

- **總元件數**: 59
- **完全遷移**: 53 (90%)
- **需要組合**: 3 (5%)
- **已移除**: 4 (7%)
- **整體完成度**: 93%

---

*最後更新：2025-12-16*