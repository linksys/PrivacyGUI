# WiFi Settings (Incredible WiFi) 模組遷移計劃

## 📋 總覽

**模組名稱**: wifi_settings (Incredible WiFi)  
**遷移方案**: 分階段遷移（Phase 1-3）  
**總檔案數**: 16+ 檔案 (10 views + 6 widgets)  
**當前狀態**: ✅ 零錯誤（僅2個 info/warning）

---

## 🎯 分階段遷移計劃

### Phase 1: 核心檔案遷移（優先級：🔴 High）

**目標**: 遷移最關鍵的4個檔案，建立遷移基礎  
**預計時間**: 45-60 分鐘  
**檔案清單**:

#### 1.1 `wifi_main_view.dart` (318 行)
**當前狀態**: 已使用 `UiKitPageView.withSliver`  
**需要遷移**:
- ✅ 移除 `privacygui_widgets` imports
- ✅ `AppTextButton` → `AppButton.text`
- ✅ `AppGap.small2()`, `AppGap.small3()`, `AppGap.medium()` → UI Kit sizes
- ✅ `AppCard` 已是 UI Kit (保持)

**遷移重點**:
```dart
// Imports
- import 'package:privacygui_widgets/widgets/_widgets.dart';
- import 'package:privacygui_widgets/widgets/card/card.dart';
+ import 'package:ui_kit_library/ui_kit.dart';

// Buttons in modals
- AppTextButton(loc(context).cancel, onTap: ...)
+ AppButton.text(label: loc(context).cancel, onTap: ...)

// Gap sizes
- AppGap.small2() → AppGap.sm()
- AppGap.small3() → AppGap.md()
- AppGap.medium() → AppGap.lg()
```

#### 1.2 `wifi_advanced_settings_view.dart` (215 行)
**需要遷移**:
- ✅ `ResponsiveLayout` → `context.isMobileLayout`
- ✅ `Spacing` → `AppSpacing`
- ✅ `AppSwitchTriggerTile` → Composed component
- ✅ `AppCard` usage

**遷移重點**:
```dart
// Responsive layout
- ResponsiveLayout.isMobileLayout(context)
+ context.isMobileLayout

// Spacing
- Spacing.medium → AppSpacing.md
- padding: EdgeInsets.all(Spacing.medium)
+ padding: EdgeInsets.all(AppSpacing.md)
```

#### 1.3 `guest_wifi_card.dart` (Widget)
**需要遷移**:
- ✅ `LinksysIcons` → `AppFontIcons`
- ✅ `Icon` → `AppIcon.font`
- ✅ `ResponsiveLayout` → `context.isMobileLayout`
- ✅ `AppListCard`, `AppSettingCard` → Composed components
- ✅ `Spacing` → `AppSpacing`

#### 1.4 `main_wifi_card.dart` (Widget)
**需要遷移**:
- ✅ `LinksysIcons` → `AppFontIcons`
- ✅ `AppListCard`, `AppSettingCard` → Composed
- ✅ `ResponsiveLayout` → Context extensions
- ✅ `Spacing` → `AppSpacing`

**Phase 1 驗證**:
```bash
flutter analyze lib/page/wifi_settings/views/wifi_main_view.dart
flutter analyze lib/page/wifi_settings/views/wifi_advanced_settings_view.dart
flutter analyze lib/page/wifi_settings/views/widgets/guest_wifi_card.dart
flutter analyze lib/page/wifi_settings/views/widgets/main_wifi_card.dart
```

---

### Phase 2: 主要視圖遷移（優先級：🟡 Medium）

**目標**: 遷移 WiFi 列表相關核心視圖  
**預計時間**: 60-75 分鐘  
**檔案清單**:

#### 2.1 `wifi_list_view.dart` (133 行)
**需要遷移**:
- ✅ Page wrapper (如有 StyledAppPageView)
- ✅ `ResponsiveLayout` → Context extensions
- ✅ `AppCard`, spacing adjustments

#### 2.2 `wifi_list_simple_mode_view.dart` (230 行)
**需要遷移**:
- ✅ `LinksysIcons` → `AppFontIcons`
- ✅ `ResponsiveLayout` → Context extensions
- ✅ `AppListCard`, `AppCard` → UI Kit / Composed
- ✅ `Spacing` → `AppSpacing`

#### 2.3 `wifi_list_advanced_mode_view.dart` (155 行)
**需要遷移**:
- ✅ Similar to simple mode
- ✅ Advanced settings cards

#### 2.4 `wifi_share_detail_view.dart` (185 行)
**需要遷移**:
- ✅ `LinksysIcons` → `AppFontIcons`
- ✅ `AppSettingCard` → Composed
- ✅ `ResponsiveLayout` → Context extensions
- ✅ QR code display (if any special components)

#### 2.5 Input Field Widgets
**2.5.1 `wifi_password_field.dart`**:
```dart
- import 'package:privacygui_widgets/widgets/input_field/app_password_field.dart';
- import 'package:privacygui_widgets/widgets/input_field/validator_widget.dart';
+ import 'package:ui_kit_library/ui_kit.dart';

- AppPasswordField → AppPasswordInput
- AppValidatorWidget → Built into AppPasswordInput
```

**2.5.2 `wifi_name_field.dart`**:
```dart
- AppTextField → AppTextFormField
- hint: → label:
```

**Phase 2 驗證**:
```bash
flutter analyze lib/page/wifi_settings/views/
```

---

### Phase 3: 剩餘檔案遷移（優先級：🟢 Low）

**目標**: 完成所有剩餘檔案遷移  
**預計時間**: 45-60 分鐘  
**檔案清單**:

#### 3.1 `mac_filtering_view.dart` (175 行)
**需要遷移**:
- ✅ Standard component replacements
- ✅ Modal dialogs

#### 3.2 `mac_filtered_devices_view.dart` (273 行)
**需要遷移**:
- ✅ `LinksysIcons` → `AppFontIcons`
- ✅ `AppListCard`, `AppSettingCard` → Composed
- ✅ Device list rendering

#### 3.3 `wifi_settings_channel_finder_view.dart` (81 行)
**需要遷移**:
- ✅ `CustomTheme` → Remove if exists
- ✅ `AppGap` → UI Kit sizes
- ✅ `AppFullScreenSpinner` → `Scaffold + AppLoader`

#### 3.4 `wifi_setting_modal_mixin.dart` (Mixin)
**需要遷移**:
- ✅ `AppTextButton` → `AppButton.text`
- ✅ Modal dialog components
- ✅ Radio list components

#### 3.5 `wifi_term_titles.dart` (460 行)
**檢查是否需要遷移**:
- 主要是資料定義，可能不需要大量遷移
- 檢查是否有 UI 元件使用

**Phase 3 驗證**:
```bash
flutter analyze lib/page/wifi_settings/
```

---

## 📋 統一遷移模式

### 1. Import 替換
```dart
// 移除所有 privacygui_widgets imports
- import 'package:privacygui_widgets/widgets/_widgets.dart';
- import 'package:privacygui_widgets/widgets/card/card.dart';
- import 'package:privacygui_widgets/widgets/card/list_card.dart';
- import 'package:privacygui_widgets/widgets/card/setting_card.dart';
- import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
- import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
- import 'package:privacygui_widgets/icons/linksys_icons.dart';
- import 'package:privacygui_widgets/widgets/input_field/app_text_field.dart';
- import 'package:privacygui_widgets/widgets/input_field/app_password_field.dart';

// 新增 UI Kit import
+ import 'package:ui_kit_library/ui_kit.dart';
```

### 2. 圖標遷移
```dart
- LinksysIcons.* → AppFontIcons.*
- Icon(LinksysIcons.wifi) → AppIcon.font(AppFontIcons.wifi)
```

### 3. 響應式佈局
```dart
- ResponsiveLayout.isMobileLayout(context) → context.isMobileLayout
- ResponsiveLayout.isOverMediumLayout(context) → !context.isMobileLayout
```

### 4. 間距系統
```dart
- Spacing.small1 → AppSpacing.xs
- Spacing.small2 → AppSpacing.sm
- Spacing.small3 → AppSpacing.md
- Spacing.medium → AppSpacing.lg
- Spacing.large1 → AppSpacing.xl
- Spacing.large2 → AppSpacing.xxl
- Spacing.large3 → AppSpacing.xxxl

- AppGap.small() → AppGap.xs()
- AppGap.small2() → AppGap.sm()
- AppGap.small3() → AppGap.md()
- AppGap.medium() → AppGap.lg()
- AppGap.large() → AppGap.xl()
- AppGap.large2() → AppGap.xxl()
- AppGap.large3() → AppGap.xxxl()
```

### 5. 按鈕元件
```dart
- AppTextButton('Label', onTap: ...) 
+ AppButton.text(label: 'Label', onTap: ...)
```

### 6. 輸入欄位
```dart
- AppTextField(hint: '...', controller: ...)
+ AppTextFormField(label: '...', controller: ...)

- AppPasswordField(validations: [...])
+ AppPasswordInput(rules: [...])
```

### 7. 卡片元件
```dart
// AppCard - 保持不變 (已是 UI Kit)
AppCard(child: ...)

// AppListCard - 需要組合
// AppSettingCard - 需要組合
// 參考: lib/page/components/composed/
```

---

## ✅ 各階段完成標準

### Phase 1 完成條件
- [ ] 4個核心檔案零 analyze 錯誤
- [ ] 所有 privacygui_widgets imports 已移除
- [ ] 手動測試主頁面和基本設定功能正常

### Phase 2 完成條件
- [ ] WiFi 列表相關視圖零錯誤
- [ ] 輸入欄位元件正常運作
- [ ] Simple/Advanced 模式切換正常

### Phase 3 完成條件
- [ ] 整個 wifi_settings 模組零錯誤
- [ ] MAC 過濾功能正常
- [ ] Channel finder 功能正常
- [ ] 所有模態對話框正常顯示

### 最終驗證
```bash
# 完整分析
flutter analyze lib/page/wifi_settings/

# 確認沒有 privacygui_widgets 殘留
grep -r "privacygui_widgets" lib/page/wifi_settings/
```

---

## 📊 進度追蹤

### Phase 1 (核心檔案)
- [ ] wifi_main_view.dart
- [ ] wifi_advanced_settings_view.dart
- [ ] guest_wifi_card.dart
- [ ] main_wifi_card.dart

### Phase 2 (主要視圖)
- [ ] wifi_list_view.dart
- [ ] wifi_list_simple_mode_view.dart
- [ ] wifi_list_advanced_mode_view.dart
- [ ] wifi_share_detail_view.dart
- [ ] wifi_password_field.dart
- [ ] wifi_name_field.dart

### Phase 3 (剩餘檔案)
- [ ] mac_filtering_view.dart
- [ ] mac_filtered_devices_view.dart
- [ ] wifi_settings_channel_finder_view.dart
- [ ] wifi_setting_modal_mixin.dart
- [ ] wifi_term_titles.dart

---

## 🎯 預期成果

完成所有階段後：
- ✅ **16+ 檔案** 完全遷移至 UI Kit
- ✅ **零錯誤** from flutter analyze
- ✅ **一致的** UI Kit 元件使用
- ✅ **移除所有** privacygui_widgets 依賴

---

*最後更新：2025-12-16*
*預計總時間：2.5-3.5 小時（分3個階段）*
