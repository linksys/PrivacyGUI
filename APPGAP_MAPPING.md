# AppGap 對照表 (AppGap Mapping Reference)

## 基本對照表 (Basic Mapping)

| privacygui_widgets | ui_kit_library | 像素值 (Pixels) | 使用場景 (Usage) |
|-------------------|----------------|----------------|------------------|
| `AppGap.small()`  | `AppGap.xs()`  | 4px           | 最小間距 (Minimal spacing) |
| `AppGap.small2()` | `AppGap.sm()`  | 8px           | 小間距 (Small spacing) |
| `AppGap.small3()` | `AppGap.md()`  | 12px          | 預設間距 (Default spacing) |
| `AppGap.medium()` | `AppGap.lg()`  | 16px          | 中等間距 (Medium spacing) |
| `AppGap.large()`  | `AppGap.xl()`  | 20px          | 大間距 (Large spacing) |
| `AppGap.large2()` | `AppGap.xxl()` | 24px          | 特大間距 (Extra large spacing) |
| `AppGap.large3()` | `AppGap.xxxl()` | 32px         | 最大間距 (Maximum spacing) |
| `AppGap.gutter()` | `AppGap.gutter()` | 16px       | 版面溝槽 (Layout gutter) |

## 常見使用場景建議 (Common Usage Recommendations)

### 表單間距 (Form Spacing)
- **表單欄位間距**: `AppGap.md()` (12px) - 表單欄位之間
- **表單區塊間距**: `AppGap.lg()` (16px) - 表單區塊之間
- **標籤與輸入框**: `AppGap.xs()` (4px) - 標籤與輸入框之間

### 卡片間距 (Card Spacing)
- **卡片內部間距**: `AppGap.lg()` (16px) - 卡片內容間距
- **卡片外部邊距**: `AppGap.sm()` (8px) - 卡片之間的間距

### 按鈕間距 (Button Spacing)
- **按鈕群組間距**: `AppGap.sm()` (8px) - 按鈕群組內按鈕間距
- **按鈕區塊間距**: `AppGap.lg()` (16px) - 按鈕區塊之間

### 版面間距 (Layout Spacing)
- **頁面區塊間距**: `AppGap.xl()` (20px) - 主要頁面區塊間
- **清單項目間距**: `AppGap.sm()` (8px) - 清單項目之間
- **主要標題間距**: `AppGap.xxxl()` (32px) - 重要標題區塊

### 元件間距 (Component Spacing)
- **圖標文字間距**: `AppGap.xs()` (4px) - 圖標與文字之間
- **開關元件間距**: `AppGap.sm()` (8px) - 開關與標籤之間

## 解決命名衝突 (Resolving Naming Conflicts)

當同時導入兩個庫時，使用 `hide` 來避免衝突：

```dart
// 隱藏 ui_kit_library 的 AppGap
import 'package:ui_kit_library/ui_kit.dart' hide AppGap;
import 'package:privacygui_widgets/widgets/gap/gap.dart';

// 或者隱藏 privacygui_widgets 的 AppGap
import 'package:privacygui_widgets/widgets/_widgets.dart' hide AppGap;
import 'package:ui_kit_library/ui_kit.dart';
```

## 使用映射工具 (Using Mapping Utilities)

```dart
import 'package:privacy_gui/util/appgap_mapping.dart';

// 取得對應間距
Widget gap = AppGapMapper.getUiKitGap('medium'); // 返回 AppGap.lg()
Widget gap2 = AppGapMapper.getPrivacyGap('lg');  // 返回 AppGap.medium()

// 使用擴展方法
Widget gap3 = 'medium'.toGap(useUiKit: true);   // ui_kit AppGap.lg()
double pixels = 'medium'.gapPixels;              // 16.0

// 轉換間距系統
String uiKitSize = 'medium'.toUiKitGap();       // 'lg'
String privacySize = 'lg'.toPrivacyGap();        // 'medium'
```

## 遷移指南 (Migration Guide)

### 步驟 1：識別現有用法
```dart
// 舊代碼 (privacygui_widgets)
const AppGap.small2(),
const AppGap.medium(),
const AppGap.large3(),
```

### 步驟 2：轉換到新格式
```dart
// 新代碼 (ui_kit_library)
AppGap.sm(),    // 替代 AppGap.small2()
AppGap.lg(),    // 替代 AppGap.medium()
AppGap.xxxl(),  // 替代 AppGap.large3()
```

### 步驟 3：更新導入語句
```dart
// 添加 hide 子句避免衝突
import 'package:ui_kit_library/ui_kit.dart' hide AppGap, AppText;
import 'package:privacygui_widgets/widgets/gap/gap.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';
```

## 常見錯誤與解決方案 (Common Issues & Solutions)

### 錯誤 1: `prefix_shadowed_by_local_declaration`
```dart
// 問題: AppGap 被本地聲明遮蔽
error - The prefix 'AppGap' can't be used here because it's shadowed by a local declaration.

// 解決方案: 使用 hide 隱藏衝突的名稱
import 'package:ui_kit_library/ui_kit.dart' hide AppGap;
```

### 錯誤 2: `ambiguous_import`
```dart
// 問題: 兩個庫都定義了相同名稱
error - The name 'AppGap' is defined in multiple libraries.

// 解決方案: 使用別名或隱藏
import 'package:ui_kit_library/ui_kit.dart' as UiKit;
import 'package:privacygui_widgets/widgets/gap/gap.dart' as PrivacyGap;
```

### 錯誤 3: 屬性名稱不匹配
```dart
// ui_kit_library 使用簡化名稱
AppGap.sm()    // ✓ 正確
AppGap.small2() // ✗ 錯誤 - 這是 privacygui_widgets 語法
```

## 最佳實踐 (Best Practices)

1. **保持一致性**: 在單一檔案中使用同一套間距系統
2. **使用語意化名稱**: 優先使用 `AppGapMapper.getRecommendedSpacing('form_field')`
3. **避免硬編碼**: 使用預定義的間距值而非自定義像素
4. **測試響應式**: 確保間距在不同螢幕尺寸下正常顯示

## 工具類使用範例 (Utility Examples)

```dart
// 取得所有可用間距
Map<String, double> gaps = AppGapMapper.getAllGapSizes();

// 驗證間距大小
bool isValid = AppGapMapper.isValidGapSize('medium'); // true

// 取得建議間距
Widget spacing = AppGapMapper.getRecommendedSpacing('form_field');

// 使用常數
Widget box = AppGapConstants.lgBox;  // SizedBox(height: 16, width: 16)
Widget vertical = AppGapConstants.lgVertical;  // SizedBox(height: 16)
```