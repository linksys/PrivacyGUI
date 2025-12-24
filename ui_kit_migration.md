# UI Kit Migration Guide

## 概述

本文件提供 privacygui_widgets 遷移至 ui_kit_library 的完整指南和元件對照表。此遷移將使應用程式獲得更現代化的設計系統、更好的一致性以及額外的功能。

## 🎯 遷移目標

- **設計系統現代化**: 採用 ui_kit 的統一設計語言
- **元件標準化**: 使用基於 Atomic Design 的元件架構
- **功能增強**: 獲得更多進階元件和功能
- **維護簡化**: 減少重複程式碼，提高可維護性

## 📊 元件對照表

### 🎨 主題系統

| privacygui_widgets | ui_kit_library | 遷移狀態 | 建議方案 |
|-------------------|----------------|----------|----------|
| CustomTheme | AppTheme.create() | ✅ 直接替換 | 使用 AppTheme.create() |
| CustomResponsive | (無) | ❌ 需保留 | 繼續使用 privacygui_widgets |
| ColorSchemes | AppColorScheme | ✅ 直接替換 | 遷移至 ui_kit 色彩系統 |
| TextSchemes | appTextTheme | ✅ 直接替換 | 使用 ui_kit 文字系統 |

**遷移範例:**
```dart
// Before (privacygui_widgets)
import 'package:privacygui_widgets/theme/_theme.dart';
theme: linksysLightThemeData.copyWith(...)

// After (ui_kit_library)
import 'package:ui_kit_library/ui_kit.dart';
theme: AppTheme.create(
  brightness: Brightness.light,
  seedColor: themeColor,
)
```

### 🔘 按鈕元件

| privacygui_widgets | ui_kit_library | 遷移狀態 | 建議方案 |
|-------------------|----------------|----------|----------|
| ElevatedButton | AppButton (elevated variant) | ⚡ 需適配 | 使用 AppButton + Surface |
| FilledButton | AppButton (filled variant) | ⚡ 需適配 | 使用 AppButton + Surface |
| FilledButtonWithLoading | AppButton + AppLoader | ⚡ 組合使用 | 自行組合 loading 狀態 |
| OutlinedButton | AppButton (outlined variant) | ⚡ 需適配 | 使用 AppButton + Surface |
| TextButton | AppButton (text variant) | ⚡ 需適配 | 使用 AppButton + Surface |
| TonalButton | AppButton (tonal variant) | ⚡ 需適配 | 使用 AppButton + Surface |
| ToggleButton | AppButton + AppSwitch | ⚡ 組合使用 | 組合元件實現 |
| IconButton | AppIconButton | ✅ 直接替換 | 直接遷移 |
| PopupButton | AppPopupMenu | ✅ 直接替換 | 使用 AppPopupMenu |

**遷移範例:**
```dart
// Before
FilledButton(onPressed: () {}, child: Text('Button'))

// After
AppButton(
  onPressed: () {},
  child: Text('Button'),
)
```

### 📝 輸入元件

| privacygui_widgets | ui_kit_library | 遷移狀態 | 建議方案 |
|-------------------|----------------|----------|----------|
| AppTextField | AppTextFormField | ✅ 直接替換 | 直接遷移 |
| AppPasswordField | AppPasswordInput | ✅ 直接替換 | 直接遷移 |
| PinCodeInput | AppPinInput | ✅ 直接替換 | 直接遷移 |
| IpFormField | AppIpv4TextField | ✅ 直接替換 | 直接遷移 |
| Ipv6FormField | AppIpv6TextField | ✅ 直接替換 | 直接遷移 |
| (無) | AppMacAddressTextField | ➕ 新增功能 | ui_kit 提供額外功能 |
| (無) | AppNumberTextField | ➕ 新增功能 | ui_kit 提供額外功能 |
| (無) | AppRangeInput | ➕ 新增功能 | ui_kit 提供額外功能 |
| InputFormatters | AppFormatters | ✅ 直接替換 | 使用 ui_kit 格式化器 |
| ValidatorWidget | AppValidators | ✅ 直接替換 | 使用 ui_kit 驗證器 |

**遷移範例:**
```dart
// Before
AppTextField(controller: controller)

// After
AppTextFormField(controller: controller)

// IP 輸入欄位 - 直接對應
IpFormField() → AppIpv4TextField()
Ipv6FormField() → AppIpv6TextField()
```

### 🎛️ 選擇元件

| privacygui_widgets | ui_kit_library | 遷移狀態 | 建議方案 |
|-------------------|----------------|----------|----------|
| CheckBox | AppCheckbox | ✅ 直接替換 | 直接遷移 |
| RadioList | AppRadio | ✅ 直接替換 | 直接遷移 |
| Switch | AppSwitch | ✅ 直接替換 | 直接遷移 |
| (無) | AppSlider | ➕ 新增功能 | ui_kit 提供額外功能 |

### 📋 下拉選單

| privacygui_widgets | ui_kit_library | 遷移狀態 | 建議方案 |
|-------------------|----------------|----------|----------|
| DropdownButton | AppDropdown | ✅ 直接替換 | 直接遷移 |
| DropdownMenu | AppDropdown | ✅ 直接替換 | 直接遷移 |

### 🃏 卡片元件

| privacygui_widgets | ui_kit_library | 遷移狀態 | 建議方案 |
|-------------------|----------------|----------|----------|
| Card | AppCard | ✅ 直接替換 | 直接遷移 |
| InformationCard | AppCard + AppText | ⚡ 組合使用 | 使用 AppCard 組合實現 |
| SettingCard | AppCard + AppListTile | ⚡ 組合使用 | 使用 AppCard + AppListTile |
| DeviceListCard | AppCard + renderers | ⚡ 需適配 | 使用 AppDataTable + CardRenderer |
| NodeListCard | AppCard + renderers | ⚡ 需適配 | 使用 AppDataTable + CardRenderer |
| ListExpandCard | AppExpansionPanel | ✅ 直接替換 | 直接遷移 |
| ExpansionCard | AppExpansionPanel | ✅ 直接替換 | 直接遷移 |
| SelectionCard | AppCard + AppCheckbox | ⚡ 組合使用 | 組合元件實現 |
| ListCard | AppCard + AppListTile | ⚡ 組合使用 | 組合元件實現 |
| InfoCard | AppCard + AppText | ⚡ 組合使用 | 組合元件實現 |

**遷移範例:**
```dart
// Before
SettingCard(
  title: '設定標題',
  subtitle: '設定說明',
  trailing: Switch(),
)

// After
AppCard(
  child: AppListTile(
    title: AppText('設定標題'),
    subtitle: AppText('設定說明'),
    trailing: AppSwitch(),
  ),
)
```

### 🗂️ 面板元件

| privacygui_widgets | ui_kit_library | 遷移狀態 | 建議方案 |
|-------------------|----------------|----------|----------|
| GeneralExpansion | AppExpansionPanel | ✅ 直接替換 | 直接遷移 |
| GeneralSection | AppCard | ⚡ 需適配 | 使用 AppCard 實現 |
| PanelWithSimpleTitle | AppCard + header | ⚡ 組合使用 | 組合實現 |
| SwitchTriggerTile | AppListTile + AppSwitch | ⚡ 組合使用 | 組合實現 |
| PanelWithValueCheck | AppCard + validation | ⚡ 組合使用 | 組合實現 |

### 🔧 容器元件

| privacygui_widgets | ui_kit_library | 遷移狀態 | 建議方案 |
|-------------------|----------------|----------|----------|
| ResponsiveLayout | (無) | ❌ 需保留 | 繼續使用 privacygui_widgets |
| AnimatedMeter | AppGauge | ✅ 直接替換 | 使用 ui_kit 的 AppGauge |
| StackedListView | (無) | ❌ 需保留 | 繼續使用 privacygui_widgets |
| SlideActionsContainer | AppSlideAction | ✅ 直接替換 | 直接遷移 |

### 🧩 其他元件

| privacygui_widgets | ui_kit_library | 遷移狀態 | 建議方案 |
|-------------------|----------------|----------|----------|
| AppStepper | AppStepper | ✅ 直接替換 | 直接遷移 |
| AppBar | AppUnifiedBar | ✅ 直接替換 | 直接遷移 |
| MultiplePageAlertDialog | AppDialog + AppTabs | ⚡ 組合使用 | 組合實現 |
| BulletList | (無) | ❌ 需保留 | 繼續使用 privacygui_widgets |
| TextLabel | AppText | ✅ 直接替換 | 直接遷移 |
| AppStyledText | AppStyledText | ✅ 直接替換 | 直接遷移 |
| AppText | AppText | ✅ 直接替換 | 直接遷移 |

### 📊 表格元件

| privacygui_widgets | ui_kit_library | 遷移狀態 | 建議方案 |
|-------------------|----------------|----------|----------|
| CardListSettingsView | AppDataTable + renderers | ⚡ 需適配 | 使用 ui_kit 表格系統 |
| (無) | AppDataTable | ➕ 新增功能 | ui_kit 提供更強大表格 |
| (無) | CardRenderer | ➕ 新增功能 | ui_kit 提供卡片渲染器 |
| (無) | GridRenderer | ➕ 新增功能 | ui_kit 提供網格渲染器 |

## 🎯 遷移策略

### ✅ 可直接替換 (70% 的元件)
- **主題系統**: 直接使用 `AppTheme.create()`
- **輸入元件**: IP、密碼、PIN 等都有對應元件
- **選擇元件**: Checkbox、Radio、Switch 直接對應
- **基礎元件**: 文字、圖標、卡片等

### ⚡ 需要適配 (20% 的元件)
- **按鈕變體**: 需要通過 AppButton + AppSurface 組合實現
- **複合卡片**: 使用 AppCard + 其他元件組合
- **面板元件**: 大部分可通過組合實現

### ❌ 需要保留 (10% 的元件)
```dart
// 繼續使用 privacygui_widgets
import 'package:privacygui_widgets/theme/custom_responsive.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/container/stacked_listview.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_list.dart';
```

### ➕ 額外獲得的功能
- 更強大的表格系統 (`AppDataTable`)
- 網路相關輸入元件 (`AppMacAddressTextField`)
- 範圍輸入元件 (`AppRangeInput`)
- 進階動畫系統
- 設計系統標記化 (Design System Tokens)

## 📋 實施計劃

### Phase 1: 主題系統遷移 (週 1-2)
- [ ] 更新 `lib/app.dart` 使用 `AppTheme.create()`
- [ ] 遷移色彩方案至 ui_kit 系統
- [ ] 更新文字樣式
- [ ] 測試基本主題功能

### Phase 2: 基礎元件遷移 (週 3-4)
- [ ] 遷移文字元件 (`AppText`, `AppStyledText`)
- [ ] 遷移輸入元件 (`AppTextField` → `AppTextFormField`)
- [ ] 遷移選擇元件 (`CheckBox` → `AppCheckbox`)
- [ ] 遷移下拉選單 (`DropdownButton` → `AppDropdown`)

### Phase 3: 複合元件適配 (週 5-6)
- [ ] 適配按鈕元件使用 `AppButton`
- [ ] 重構卡片元件使用 `AppCard`
- [ ] 適配面板元件
- [ ] 更新導航元件

### Phase 4: 進階元件整合 (週 7-8)
- [ ] 整合表格系統 (`AppDataTable`)
- [ ] 遷移步驟器 (`AppStepper`)
- [ ] 整合應用程式欄 (`AppUnifiedBar`)
- [ ] 測試所有新功能

### Phase 5: 清理和最佳化 (週 9-10)
- [ ] 移除不使用的 privacygui_widgets 導入
- [ ] 最佳化效能
- [ ] 完整測試
- [ ] 文件更新

## 🚨 注意事項

### 相依性管理
```yaml
# pubspec.yaml
dependencies:
  ui_kit_library:
    git:
      url: https://github.com/AustinChangLinksys/ui-kit.git
      ref: main
  privacygui_widgets:
    path: plugins/widgets  # 保留必要元件
```

### 混合使用範例
```dart
// 混合導入
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacygui_widgets/theme/custom_responsive.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_list.dart';

// 在 app.dart 中
MaterialApp.router(
  theme: AppTheme.create(
    brightness: Brightness.light,
    seedColor: themeColor,
  ),
  builder: (context, child) => Material(
    child: CustomResponsive(  // 保留 privacygui_widgets
      child: DesignSystem.init(  // 使用 ui_kit
        context,
        AppRootContainer(
          route: _currentRoute,
          child: child,
        ),
      ),
    ),
  ),
)
```

### 效能考量
- ui_kit 使用更現代的渲染機制，可能提升效能
- 某些動畫可能需要重新調整
- 測試記憶體使用情況

### 測試策略
- 每個 Phase 完成後進行回歸測試
- 特別注意主題切換功能
- 驗證響應式設計在不同螢幕尺寸上的表現
- 進行 A/B 測試比較使用者體驗

## 🎉 預期效益

### 短期效益
- 更一致的設計語言
- 減少程式碼重複
- 更好的類型安全

### 長期效益
- 更容易維護和擴展
- 獲得 ui_kit 持續更新的新功能
- 更好的開發者體驗
- 改善應用程式效能

---

**文件版本**: 1.0
**建立日期**: 2024-12-09
**更新日期**: 2024-12-09
**負責人**: Austin Chang