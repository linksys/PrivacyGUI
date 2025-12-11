# UI Kit 遷移策略修正 (Migration Strategy Correction)

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

### 必須移除的元件

> [!CAUTION]
> 以下元件必須**一律移除**，不可保留使用。

| 元件名稱 | 處理方式 |
|---------|---------|
| `AppBasicLayout` | 移除，改用 `UiKitPageView` 或直接排版 |

### 組合元件處理

若 ui_kit 沒有直接對應的元件，但可透過組合現有元件完成：

1. **在 PrivacyGUI 專案建立組合元件**
   - 統一放置於：`lib/page/components/composed/`
   - 使用 ui_kit 元件組合實作
   
2. **記錄組合元件**
   - 在組合元件檔案中加入文件說明
   - 記錄於本文件的「組合元件清單」章節

3. **後續處理**
   - 評估是否需要移至 ui_kit_library
   - 若多處使用則考慮提升為正式 ui_kit 元件

### 組合元件清單

| 組合元件名稱 | 檔案位置 | 組合方式 | 狀態 |
|-------------|---------|---------|------|
| _(待新增)_ | - | - | - |

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

## 具體遷移步驟 (Migration Steps)

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

| 元件類型 | privacygui_widgets | ui_kit_library | 遷移狀態 |
|---------|-------------------|----------------|----------|
| **按鈕** | `AppTextButton` | `AppButton` | ✅ 已遷移 |
| **文字** | `AppText` | `AppText` | ✅ 已遷移 |
| **間距** | `AppGap.medium()` | `AppGap.lg()` | ✅ 已遷移 |
| **輸入框** | `AppTextField` | `AppTextFormField` | ✅ 已遷移 |
| **密碼框** | `AppPasswordField` | `AppPasswordInput` | ✅ 已遷移 |
| **卡片** | `AppCard` | `AppCard` | ✅ 已遷移 |
| **清單卡片** | `AppListCard` | _暫無_ | ❌ 保留舊版 |

### 3. 按鈕遷移詳細對照 (Button Migration Details)

```dart
// 舊版本 (privacygui_widgets)
AppTextButton.noPadding(
  'Button Text',
  onTap: () {},
)

// 新版本 (ui_kit_library)
AppButton(
  label: 'Button Text',
  variant: SurfaceVariant.base,  // 對應 text button 風格
  onTap: () {},
)
```

### 4. 間距遷移詳細對照 (Gap Migration Details)

```dart
// 舊版本 → 新版本 對照
const AppGap.small()   → AppGap.xs()    // 4px
const AppGap.small2()  → AppGap.sm()    // 8px
const AppGap.small3()  → AppGap.md()    // 12px
const AppGap.medium()  → AppGap.lg()    // 16px
const AppGap.large()   → AppGap.xl()    // 20px
const AppGap.large2()  → AppGap.xxl()   // 24px
const AppGap.large3()  → AppGap.xxxl()  // 32px
```

### 5. Spacing 遷移詳細對照 (Spacing Migration Details)

```dart
// 舊版本 (privacygui_widgets)
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
padding: EdgeInsets.all(Spacing.medium),

// 新版本 (ui_kit_library)
import 'package:ui_kit_library/ui_kit.dart';
padding: EdgeInsets.all(AppSpacing.medium),
```

| 舊版本 (Spacing) | 新版本 (AppSpacing) | 值 |
|-----------------|--------------------|----|
| `Spacing.zero` | `AppSpacing.zero` | 0 |
| `Spacing.small1` | `AppSpacing.small1` | 4 |
| `Spacing.small2` | `AppSpacing.small2` | 8 |
| `Spacing.small3` | `AppSpacing.small3` | 12 |
| `Spacing.medium` | `AppSpacing.medium` | 16 |
| `Spacing.large1` | `AppSpacing.large1` | 20 |
| `Spacing.large2` | `AppSpacing.large2` | 24 |
| `Spacing.large3` | `AppSpacing.large3` | 32 |
| `Spacing.large4` | `AppSpacing.large4` | 40 |
| `Spacing.large5` | `AppSpacing.large5` | 48 |

### 6. 響應式欄位遷移詳細對照 (Col Migration Details)

```dart
// 舊版本 (privacygui_widgets) - 使用 int extension
import 'package:privacygui_widgets/theme/custom_responsive.dart';

width: 4.col,      // 4 欄位寬度
width: 6.col,      // 6 欄位寬度
gap: 1.gutter,     // 1 個間距寬度

// 新版本 (ui_kit_library) - 使用 BuildContext extension
import 'package:ui_kit_library/ui_kit.dart';

width: context.colWidth(4),    // 4 欄位寬度
width: context.colWidth(6),    // 6 欄位寬度
gap: context.gutterWidth(1),   // 1 個間距寬度
```

#### Col 對照表

| 舊版本 (privacygui_widgets) | 新版本 (ui_kit_library) | 說明 |
|---------------------------|------------------------|------|
| `1.col` | `context.colWidth(1)` | 1 欄位寬度 |
| `2.col` | `context.colWidth(2)` | 2 欄位寬度 |
| `3.col` | `context.colWidth(3)` | 3 欄位寬度 |
| `4.col` | `context.colWidth(4)` | 4 欄位寬度 (常用於表單) |
| `6.col` | `context.colWidth(6)` | 6 欄位寬度 (半版) |
| `8.col` | `context.colWidth(8)` | 8 欄位寬度 |
| `12.col` | `context.colWidth(12)` | 12 欄位寬度 (全版) |
| `1.gutter` | `context.gutterWidth(1)` | 1 個間距寬度 |
| `2.gutter` | `context.gutterWidth(2)` | 2 個間距寬度 |

#### 響應式斷點對照

| 斷點 | 螢幕寬度 | 最大欄數 | 說明 |
|-----|---------|---------|------|
| **small** | ≤ 600px | 4 欄 | 手機 |
| **medium** | ≤ 905px | 8 欄 | 平板 |
| **large** | ≤ 1240px | 12 欄 | 桌面 |
| **extraLarge** | ≤ 1440px | 12 欄 | 大桌面 |
| **extraExtraLarge** | > 1440px | 12 欄 | 超大桌面 |

#### 遷移注意事項

```dart
// ⚠️ 注意：計算邏輯相同
// 公式: 欄位寬度 = 單欄寬度 × 欄數 + 間距寬度 × (欄數 - 1)

// 舊版本
4.col = _size * 4 + _gutter * 3

// 新版本
context.colWidth(4) = columnWidth * 4 + gutterWidth * 3
```

### 5. 按鈕變體對照 (Button Variant Mapping)

```dart
// 舊版本按鈕類型 → 新版本變體
AppTextButton          → SurfaceVariant.base
AppFilledButton        → SurfaceVariant.highlight
AppOutlinedButton      → SurfaceVariant.tonal
ElevatedButton         → SurfaceVariant.highlight
```

## 現有檔案修正範例 (Fixed File Examples)

### bridge_form.dart ✅
```dart
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacygui_widgets/widgets/gap/gap.dart' hide AppGap;
import 'package:privacygui_widgets/widgets/text/app_styled_text.dart' hide AppStyledText;

// 使用 ui_kit 的元件
AppGap.sm(),           // 新版間距
AppButton(             // 新版按鈕
  label: 'Text',
  variant: SurfaceVariant.base,
  onTap: () {},
),
```

### release_and_renew_view.dart ✅
```dart
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacygui_widgets/widgets/gap/gap.dart' hide AppGap;
import 'package:privacygui_widgets/widgets/text/app_text.dart' hide AppText;

// 使用 ui_kit 的元件
AppText.bodyMedium('IPv4'),  // 新版文字
AppGap.sm(),                 // 新版間距
AppButton(                   // 新版按鈕
  label: 'Release & Renew',
  variant: SurfaceVariant.base,
  size: AppButtonSize.small,
  onTap: () {},
),
```

## 遷移驗證清單 (Migration Checklist)

- ✅ ui_kit_library 導入時不使用 hide
- ✅ privacygui_widgets 導入時隱藏已遷移的元件
- ✅ 按鈕使用 `AppButton` 而非 `AppTextButton`
- ✅ 間距使用 `AppGap.lg()` 而非 `AppGap.medium()`
- ✅ 按鈕屬性使用 `label` 而非 `text`
- ✅ 按鈕回調使用 `onTap` 而非 `onPressed`
- ✅ 按鈕變體使用 `SurfaceVariant` 而非 `ButtonVariant`

## 錯誤修正總結 (Error Correction Summary)

**問題**：之前一直在隱藏 ui_kit 的元件，導致繼續使用舊的 privacygui_widgets

**解決方案**：
1. 主要使用 ui_kit_library 的元件
2. 隱藏 privacygui_widgets 的同名元件避免衝突
3. 對於 ui_kit 沒有的元件（如 AppListCard），繼續使用 privacygui_widgets

**結果**：現在正確使用了新的 ui_kit 元件，實現真正的遷移目標！

---

### login_local_view.dart ✅ (完整遷移)

這是一個完整遷移的範例檔案，**只使用 ui_kit_library**，不再需要 privacygui_widgets。

#### 導入方式
```dart
// 只需要導入 ui_kit
import 'package:ui_kit_library/ui_kit.dart';
```

#### 使用的 ui_kit 元件

| 元件 | 用途 | 程式碼範例 |
|-----|-----|-----------|
| **AppText.headlineSmall** | 登入標題 | `AppText.headlineSmall(loc(context).login)` |
| **AppText.labelMedium** | 提示標籤 | `AppText.labelMedium('Show Hint', color: ...)` |
| **AppText.bodySmall** | 密碼提示內容 | `AppText.bodySmall(_passwordHint!)` |
| **AppGap.xxxl** | 大間距 (32px) | `AppGap.xxxl()` |
| **AppGap.md** | 中間距 (12px) | `AppGap.md()` |
| **AppPasswordInput** | 密碼輸入框 | `AppPasswordInput(controller: ..., hint: ...)` |
| **AppCard** | 登入卡片容器 | `AppCard(child: Column(...))` |
| **AppButton.text** | 文字按鈕 | `AppButton.text(label: 'Forgot Password', onTap: ...)` |
| **AppButton** | 主按鈕 | `AppButton(label: 'Login', variant: SurfaceVariant.highlight)` |
| **AppFullScreenLoader** | 全螢幕載入 | `AppFullScreenLoader()` |
| **UiKitPageView** | 頁面視圖 | `UiKitPageView(appBarStyle: ..., child: ...)` |

#### 按鈕使用詳細說明

```dart
// 文字按鈕：忘記密碼
AppButton.text(
  label: loc(context).forgotPassword,
  onTap: () {
    context.pushNamed(RouteNamed.localRouterRecovery);
  },
),

// 主要按鈕：登入
AppButton(
  label: loc(context).login,
  variant: SurfaceVariant.highlight,  // 高亮風格
  size: AppButtonSize.small,
  onTap: _shouldEnableLoginButton()
      ? () { _doLogin(); }
      : null,  // null 表示停用
),
```

#### 密碼輸入框使用詳細說明

```dart
AppPasswordInput(
  controller: _passwordController,
  hint: loc(context).routerPassword,
  onChanged: (value) {
    setState(() { _shouldEnableLoginButton(); });
  },
  onSubmitted: (_) {
    if (_passwordController.text.isEmpty) return;
    _doLogin();
  },
  errorText: _errorMessage,  // 顯示錯誤訊息
),
```

#### 頁面視圖配置

```dart
UiKitPageView(
  appBarStyle: UiKitAppBarStyle.none,  // 無 App Bar
  padding: EdgeInsets.zero,
  scrollable: true,
  child: (context, constraints) => Center(
    child: SizedBox(
      width: context.colWidth(4),  // 響應式寬度
      child: AppCard(child: Column(...)),
    ),
  ),
)
```

#### 展開面板使用詳細說明

```dart
// 替換 Flutter 的 ExpansionTile
// 舊版本
ExpansionTile(
  title: AppText.labelMedium('Show Hint'),
  children: [AppText.bodySmall(hint)],
)

// 新版本 (ui_kit_library)
AppExpansionPanel.single(
  headerTitle: 'Show Hint',
  content: AppText.bodySmall(hint),
  initiallyExpanded: false,
  onPanelToggled: (_) {
    setState(() {
      _showHint = !_showHint;
    });
  },
)
```

#### 為何這是完整遷移的範例

1. ✅ **單一導入**：只需 `import 'package:ui_kit_library/ui_kit.dart'`
2. ✅ **無 hide 語句**：不再需要處理衝突
3. ✅ **統一元件風格**：所有 UI 元件來自同一個庫
4. ✅ **響應式設計**：使用 `context.colWidth()` 響應式寬度
5. ✅ **完整功能**：包含按鈕、輸入框、卡片、載入器、展開面板等