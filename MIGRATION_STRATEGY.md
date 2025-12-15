# UI Kit 遷移策略 (Migration Strategy)

本文檔提供 UI Kit 遷移的核心策略、準則和技術指引。

---

## 📚 相關文檔 (Related Documents)

> [!NOTE]
> 遷移文檔已分為多個專門文檔，請根據需要查閱：

- **[MIGRATION_STRATEGY.md](./MIGRATION_STRATEGY.md)** (本檔案) - 遷移策略、準則和技術指引
- **[MIGRATION_COMPONENT_MAPPING.md](./MIGRATION_COMPONENT_MAPPING.md)** - 完整的元件對應表和 API 對照
- **[MIGRATION_FINISH.md](./MIGRATION_FINISH.md)** - 已完成遷移的檔案清單和狀況
- **[MIGRATION_TEST_RESULT.md](./MIGRATION_TEST_RESULT.md)** - 測試結果記錄和驗證狀況
- **[MIGRATION_NOTES.md](./MIGRATION_NOTES.md)** - 組合元件、工具類別和技術備註

---

## 📋 遷移準則 (Migration Guidelines)

> [!IMPORTANT]
> **最終目標**：完全移除 `privacygui_widgets` 依賴，所有元件均使用 `ui_kit_library` 替換。

### 核心原則

1. **優先使用 ui_kit**
   - 所有新程式碼必須使用 `ui_kit_library` 元件
   - 現有程式碼在修改時應同時遷移至 ui_kit

2. **清除 privacygui_widgets 依賴**
   - 遷移完成的檔案不應再有任何 `privacygui_widgets` 導入
   - 逐步移除 `hide` 語句，直到完全不需要

3. **不確定時請詢問**
   - 若找不到匹配的 ui_kit 元件 → **請詢問**
   - 若不確定遷移方式 → **請詢問**
   - 若元件行為有差異 → **請詢問**

4. **已知 ui_kit 限制**
   - **Radius 定義缺失**: ui_kit 沒有導出 radius 相關常數，使用標準 `BorderRadius.circular()` 值
   - **部分元件暫無**: 如 `AppListCard`，需建立組合元件替代 (詳見 [MIGRATION_NOTES.md](./MIGRATION_NOTES.md))

### 必須移除的元件

> [!CAUTION]
> 以下元件必須**一律移除**，不可保留使用。

| 元件名稱 | 處理方式 |
|---------|---------|
| `AppBasicLayout` | 移除，改用 `UiKitPageView` 或直接排版 |

---

## ❌ 錯誤做法 (Wrong Approach)

```dart
// 錯誤：隱藏目標庫的元件
import 'package:ui_kit_library/ui_kit.dart' hide AppButton, AppText, AppGap;
import 'package:privacygui_widgets/widgets/_widgets.dart';

// 這樣做會繼續使用舊的 privacygui_widgets 元件！
AppText.bodyMedium('Hello'); // 使用舊版本 ❌
```

## ✅ 正確做法 (Correct Approach)

```dart
// 正確：優先使用 ui_kit，只隱藏舊庫的同名元件
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart' hide AppButton, AppText, AppGap;

// 這樣會使用新的 ui_kit 元件！
AppText.bodyMedium('Hello'); // 使用新版本 ✅
AppGap.lg();                 // 使用新版本 ✅
AppButton(label: 'Click');   // 使用新版本 ✅
```

---

## 🔄 具體遷移步驟 (Migration Steps)

### 1. 導入策略 (Import Strategy)

```dart
// 步驟 1：導入 ui_kit（不隱藏任何東西）
import 'package:ui_kit_library/ui_kit.dart';

// 步驟 2：導入 privacygui_widgets，隱藏已遷移的元件
import 'package:privacygui_widgets/widgets/_widgets.dart' hide AppButton, AppText, AppGap;

// 步驟 3：針對特定元件，只導入需要的舊元件
import 'package:privacygui_widgets/widgets/card/list_card.dart'; // AppListCard 還沒有 ui_kit 版本
```

### 2. 元件對應表 (Component Mapping)

> [!NOTE]
> 完整的元件對應表請參閱 **[MIGRATION_COMPONENT_MAPPING.md](./MIGRATION_COMPONENT_MAPPING.md)**。
> 該文檔包含 59+ 個元件的詳細對應關係，包括：
> - privacygui_widgets → ui_kit_library 對應
> - Flutter 基礎元件 → ui_kit_library 對應
> - API 參數變更說明
> - 特殊遷移情況處理

**核心元件快速對照**：
- `AppTextButton` → `AppButton.text`
- `AppFilledButton` → `AppButton(variant: SurfaceVariant.highlight)`
- `AppGap.medium()` → `AppGap.lg()`
- `AppTextField` → `AppTextFormField`
- `LinksysIcons` → `AppFontIcons`
- `ResponsiveLayout` → `context.isMobile` / `AppResponsiveLayout`

---

## 🔧 詳細遷移指南 (Detailed Migration Guide)

### 2.1 狀態標籤遷移 (AppStatusLabel → AppBadge)

```dart
// 舊版本 (privacygui_widgets)
AppStatusLabel(
  isOff: status,
)

// 新版本 (ui_kit_library)
AppBadge(
  label: status ? 'Off' : 'On',
  color: status
      ? Theme.of(context).colorScheme.outline
      : Theme.of(context).extension<AppColorScheme>()!.semanticSuccess,
)
```

### 2.2 展開面板遷移 (AppExpansionCard → AppExpansionPanel)

```dart
// 舊版本 (privacygui_widgets)
AppExpansionCard(
  title: 'Section Title',
  identifier: 'section-id',
  expandedIcon: LinksysIcons.add,
  collapsedIcon: LinksysIcons.remove,
  children: [content],
)

// 新版本 (ui_kit_library)
AppExpansionPanel.single(
  headerTitle: 'Section Title',
  content: content,  // 直接傳入 Widget，非 children list
)
```

### 2.3 響應式佈局遷移 (ResponsiveLayout → Context Extensions)

```dart
// 舊版本 (privacygui_widgets)
ResponsiveLayout.isMobileLayout(context)     // 手機判斷
ResponsiveLayout.isOverMedimumLayout(context) // 平板/桌面判斷
ResponsiveLayout.columnPadding(context)       // 間距

// 新版本 (ui_kit_library)
context.isMobile    // 手機判斷
!context.isMobile   // 平板/桌面判斷
context.isTablet    // 平板判斷
context.isDesktop   // 桌面判斷
context.colWidth(n) // n 欄位寬度
context.gutterWidth(n) // n 個間距寬度
```

### 2.4 圖標遷移 (LinksysIcons → AppFontIcons)

```dart
// 舊版本 (privacygui_widgets)
import 'package:privacygui_widgets/icons/linksys_icons.dart';
Icon(LinksysIcons.wifi, size: 24)

// 新版本 (ui_kit_library)
import 'package:ui_kit_library/ui_kit.dart';
AppIcon.font(AppFontIcons.wifi, size: 24)
// 或直接使用 IconData
Icon(AppFontIcons.wifi, size: 24)
```

### 2.5 間距常數遷移 (Spacing → AppSpacing)

```dart
// 舊版本 (privacygui_widgets)
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
EdgeInsets.all(Spacing.medium)  // 16px
EdgeInsets.all(Spacing.small2)  // 8px

// 新版本 (ui_kit_library)
import 'package:ui_kit_library/ui_kit.dart';
EdgeInsets.all(AppSpacing.md)   // 16px (注意：非 const)
EdgeInsets.all(AppSpacing.sm)   // 8px
```

> [!WARNING]
> `AppSpacing` 常數非 `const`，在 const 語境中需移除 `const` 關鍵字。

### 2.6 圓角半徑遷移 (CustomTheme.radius → 標準值)

**⚠️ ui_kit 限制發現**：ui_kit_library **沒有導出** radius 相關的定義或常數。

**遷移方式**：
```dart
// 舊版本 (privacygui_widgets CustomTheme)
CustomTheme.of(context).radius.asBorderRadius().medium
CustomTheme.of(context).radius.asBorderRadius().small

// 新版本 (標準 Flutter BorderRadius)
BorderRadius.circular(8)    // medium radius
BorderRadius.circular(4)    // small radius
BorderRadius.circular(12)   // large radius
```

**常用圓角值對照**：
| 用途 | 建議值 | 說明 |
|-----|-------|------|
| 卡片 | `BorderRadius.circular(8)` | 標準卡片圓角 |
| 按鈕 | `BorderRadius.circular(6)` | 按鈕圓角 |
| 輸入框 | `BorderRadius.circular(4)` | 表單元件圓角 |
| 大型容器 | `BorderRadius.circular(12)` | 大型卡片或對話框 |

### 2.7 設備圖片遷移 (CustomTheme.getRouterImage → DeviceImageHelper)

```dart
// 舊版本 (privacygui_widgets CustomTheme)
CustomTheme.of(context).getRouterImage(modelNumber, true)

// 新版本 (DeviceImageHelper)
DeviceImageHelper.getRouterImage(modelNumber, xl: true)
```

> [!NOTE]
> 詳細的 DeviceImageHelper 說明請參閱 [MIGRATION_NOTES.md](./MIGRATION_NOTES.md)

### 2.8 SVG 和圖片遷移 (SvgPicture/Image.asset → AppSvg/AppImage)

**✅ ui_kit 提供專門元件**：ui_kit_library 導出 `AppSvg` 和 `AppImage` 元件來處理圖片顯示。

```dart
// 舊版本 (flutter_svg / Flutter Image)
SvgPicture.asset('path/to/image.svg', width: 40, height: 40)
Image.asset('path/to/image.png', width: 100, height: 100)

// 新版本選項 1: 使用 ui_kit 專門元件
AppSvg('path/to/image.svg', width: 40, height: 40)
AppImage.asset(image: Assets.images.devices.routerMx6200, width: 100, height: 100)

// 新版本選項 2: 使用 ui_kit Assets 系統
Assets.images.imgPortOff.svg(width: 40, height: 40, semanticsLabel: 'port status')
Assets.images.devices.routerMx6200.image(width: 100, height: 100)
```

**AppImage 支援多種來源**：
- `AppImage.asset(image: AssetGenImage, ...)` - 從 ui_kit Assets 使用
- `AppImage.provider(imageProvider: ImageProvider, ...)` - 從 ImageProvider 使用
- `AppImage.network(url: String, ...)` - 從網路 URL 使用
- `AppImage.file(file: File, ...)` - 從檔案使用

**ImageProvider 處理**：
```dart
// ✅ 推薦：使用 AppImage.provider 處理 ImageProvider
AppImage.provider(
  imageProvider: DeviceImageHelper.getRouterImage('routerMX6200', xl: true),
  width: 120,
  height: 120,
  fit: BoxFit.contain,
)

// ✅ 也可以：使用標準 Flutter Image widget（但失去 ui_kit 的暗色主題支援）
Image(
  image: DeviceImageHelper.getRouterImage('routerMX6200', xl: true),
  width: 120,
  height: 120,
  fit: BoxFit.contain,
)
```

> [!NOTE]
> **重要**：AppImage **完全支援 ImageProvider**！透過 `AppImage.provider()` 工廠方法，可以處理任何 ImageProvider，包括 DeviceImageHelper.getRouterImage() 的返回值。建議使用 AppImage.provider() 以獲得 ui_kit 的暗色主題支援和一致性。

### 2.9 顏色遷移 (colorSchemeExt → ui_kit AppColorScheme)

ui_kit 使用 `AppColorScheme` 提供語義化顏色系統。遷移方式：

**✅ 遷移至 ui_kit AppColorScheme 的語義化顏色：**
```dart
// 舊版本 (privacygui_widgets colorSchemeExt)
Theme.of(context).colorSchemeExt.green    → Theme.of(context).extension<AppColorScheme>()!.semanticSuccess
Theme.of(context).colorSchemeExt.orange   → Theme.of(context).extension<AppColorScheme>()!.semanticWarning

// 其他語義化顏色
Theme.of(context).extension<AppColorScheme>()!.semanticDanger    // 🔴 危險狀態
Theme.of(context).extension<AppColorScheme>()!.semanticGlow      // ✨ 正向狀態光效
```

**🔄 遷移至 Material `colorScheme` 的標準顏色（維持不變）：**

```dart
// 舊版本 (colorSchemeExt)              // 新版本 (Material colorScheme)
colorSchemeExt.primaryFixed           → colorScheme.primaryFixed
colorSchemeExt.surfaceContainer       → colorScheme.surfaceContainer
// ... (更多對照請參閱 MIGRATION_NOTES.md)
```

---

## 📊 遷移驗證清單 (Migration Checklist)

- ✅ ui_kit_library 導入時不使用 hide
- ✅ privacygui_widgets 導入時隱藏已遷移的元件
- ✅ 按鈕使用 `AppButton` 而非 `AppTextButton`
- ✅ 間距使用 `AppGap.lg()` 而非 `AppGap.medium()`
- ✅ 按鈕屬性使用 `label` 而非 `text`
- ✅ 按鈕回調使用 `onTap` 而非 `onPressed`
- ✅ 按鈕變體使用 `SurfaceVariant` 而非 `ButtonVariant`

---

## 📚 進一步資訊

- **完整的元件對應表**: [MIGRATION_COMPONENT_MAPPING.md](./MIGRATION_COMPONENT_MAPPING.md)
- **已遷移檔案清單**: [MIGRATION_FINISH.md](./MIGRATION_FINISH.md)
- **測試結果和驗證狀況**: [MIGRATION_TEST_RESULT.md](./MIGRATION_TEST_RESULT.md)
- **組合元件和技術備註**: [MIGRATION_NOTES.md](./MIGRATION_NOTES.md)

*最後更新：[自動生成時間]*