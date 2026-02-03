# UI Kit Migration Guide

## Overview

This document provides a comprehensive guide and component mapping for migrating from `privacygui_widgets` to `ui_kit_library`. This migration will grant the application a more modern design system, better consistency, and additional features.

## 🎯 Migration Goals

- **Design System Modernization**: Adopt ui_kit's unified design language.
- **Component Standardization**: Use a component architecture based on Atomic Design.
- **Feature Enhancement**: Gain access to more advanced components and features.
- **Maintenance Simplification**: Reduce code duplication and improve maintainability.

## 📊 Component Mapping Table

### 🎨 Theme System

| privacygui_widgets | ui_kit_library | Migration Status | Recommended Solution |
|-------------------|----------------|----------|----------|
| CustomTheme | AppTheme.create() | ✅ Direct replacement | Use AppTheme.create() |
| CustomResponsive | (None) | ❌ Keep | Continue using privacygui_widgets |
| ColorSchemes | AppColorScheme | ✅ Direct replacement | Migrate to ui_kit color system |
| TextSchemes | appTextTheme | ✅ Direct replacement | Use ui_kit text system |

**Migration Example:**
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

### 🔘 Button Components

| privacygui_widgets | ui_kit_library | Migration Status | Recommended Solution |
|-------------------|----------------|----------|----------|
| ElevatedButton | AppButton (elevated variant) | ⚡ Adapt needed | Use AppButton + Surface |
| FilledButton | AppButton (filled variant) | ⚡ Adapt needed | Use AppButton + Surface |
| FilledButtonWithLoading | AppButton + AppLoader | ⚡ Combination | Combine loading state manually |
| OutlinedButton | AppButton (outlined variant) | ⚡ Adapt needed | Use AppButton + Surface |
| TextButton | AppButton (text variant) | ⚡ Adapt needed | Use AppButton + Surface |
| TonalButton | AppButton (tonal variant) | ⚡ Adapt needed | Use AppButton + Surface |
| ToggleButton | AppButton + AppSwitch | ⚡ Combination | Combine components to implement |
| IconButton | AppIconButton | ✅ Direct replacement | Direct migration |
| PopupButton | AppPopupMenu | ✅ Direct replacement | Use AppPopupMenu |

**Migration Example:**
```dart
// Before
FilledButton(onPressed: () {}, child: Text('Button'))

// After
AppButton(
  onPressed: () {},
  child: Text('Button'),
)
```

### 📝 Input Components

| privacygui_widgets | ui_kit_library | Migration Status | Recommended Solution |
|-------------------|----------------|----------|----------|
| AppTextField | AppTextFormField | ✅ Direct replacement | Direct migration |
| AppPasswordField | AppPasswordInput | ✅ Direct replacement | Direct migration |
| PinCodeInput | AppPinInput | ✅ Direct replacement | Direct migration |
| IpFormField | AppIpv4TextField | ✅ Direct replacement | Direct migration |
| Ipv6FormField | AppIpv6TextField | ✅ Direct replacement | Direct migration |
| (None) | AppMacAddressTextField | ➕ New feature | ui_kit provides extra functionality |
| (None) | AppNumberTextField | ➕ New feature | ui_kit provides extra functionality |
| (None) | AppRangeInput | ➕ New feature | ui_kit provides extra functionality |
| InputFormatters | AppFormatters | ✅ Direct replacement | Use ui_kit formatters |
| ValidatorWidget | AppValidators | ✅ Direct replacement | Use ui_kit validators |

**Migration Example:**
```dart
// Before
AppTextField(controller: controller)

// After
AppTextFormField(controller: controller)

// IP Input Fields - Direct Mapping
IpFormField() → AppIpv4TextField()
Ipv6FormField() → AppIpv6TextField()
```

### 🎛️ Selection Components

| privacygui_widgets | ui_kit_library | Migration Status | Recommended Solution |
|-------------------|----------------|----------|----------|
| CheckBox | AppCheckbox | ✅ Direct replacement | Direct migration |
| RadioList | AppRadio | ✅ Direct replacement | Direct migration |
| Switch | AppSwitch | ✅ Direct replacement | Direct migration |
| (None) | AppSlider | ➕ New feature | ui_kit provides extra functionality |

### 📋 Dropdown Menus

| privacygui_widgets | ui_kit_library | Migration Status | Recommended Solution |
|-------------------|----------------|----------|----------|
| DropdownButton | AppDropdown | ✅ Direct replacement | Direct migration |
| DropdownMenu | AppDropdown | ✅ Direct replacement | Direct migration |

### 🃏 Card Components

| privacygui_widgets | ui_kit_library | Migration Status | Recommended Solution |
|-------------------|----------------|----------|----------|
| Card | AppCard | ✅ Direct replacement | Direct migration |
| InformationCard | AppCard + AppText | ⚡ Combination | Use AppCard combination |
| SettingCard | AppCard + AppListTile | ⚡ Combination | Use AppCard + AppListTile |
| DeviceListCard | AppCard + renderers | ⚡ Adapt needed | Use AppDataTable + CardRenderer |
| NodeListCard | AppCard + renderers | ⚡ Adapt needed | Use AppDataTable + CardRenderer |
| ListExpandCard | AppExpansionPanel | ✅ Direct replacement | Direct migration |
| ExpansionCard | AppExpansionPanel | ✅ Direct replacement | Direct migration |
| SelectionCard | AppCard + AppCheckbox | ⚡ Combination | Combine components to implement |
| ListCard | AppCard + AppListTile | ⚡ Combination | Combine components to implement |
| InfoCard | AppCard + AppText | ⚡ Combination | Combine components to implement |

**Migration Example:**
```dart
// Before
SettingCard(
  title: 'Setting Title',
  subtitle: 'Setting Description',
  trailing: Switch(),
)

// After
AppCard(
  child: AppListTile(
    title: AppText('Setting Title'),
    subtitle: AppText('Setting Description'),
    trailing: AppSwitch(),
  ),
)
```

### 🗂️ Panel Components

| privacygui_widgets | ui_kit_library | Migration Status | Recommended Solution |
|-------------------|----------------|----------|----------|
| GeneralExpansion | AppExpansionPanel | ✅ Direct replacement | Direct migration |
| GeneralSection | AppCard | ⚡ Adapt needed | Use AppCard to implement |
| PanelWithSimpleTitle | AppCard + header | ⚡ Combination | Combination implementation |
| SwitchTriggerTile | AppListTile + AppSwitch | ⚡ Combination | Combination implementation |
| PanelWithValueCheck | AppCard + validation | ⚡ Combination | Combination implementation |

### 🔧 Container Components

| privacygui_widgets | ui_kit_library | Migration Status | Recommended Solution |
|-------------------|----------------|----------|----------|
| ResponsiveLayout | (None) | ❌ Keep | Continue using privacygui_widgets |
| AnimatedMeter | AppGauge | ✅ Direct replacement | Use AppGauge from ui_kit |
| StackedListView | (None) | ❌ Keep | Continue using privacygui_widgets |
| SlideActionsContainer | AppSlideAction | ✅ Direct replacement | Direct migration |

### 🧩 Other Components

| privacygui_widgets | ui_kit_library | Migration Status | Recommended Solution |
|-------------------|----------------|----------|----------|
| AppStepper | AppStepper | ✅ Direct replacement | Direct migration |
| AppBar | AppUnifiedBar | ✅ Direct replacement | Direct migration |
| MultiplePageAlertDialog | AppDialog + AppTabs | ⚡ Combination | Combination implementation |
| BulletList | (None) | ❌ Keep | Continue using privacygui_widgets |
| TextLabel | AppText | ✅ Direct replacement | Direct migration |
| AppStyledText | AppStyledText | ✅ Direct replacement | Direct migration |
| AppText | AppText | ✅ Direct replacement | Direct migration |

### 📊 Table Components

| privacygui_widgets | ui_kit_library | Migration Status | Recommended Solution |
|-------------------|----------------|----------|----------|
| CardListSettingsView | AppDataTable + renderers | ⚡ Adapt needed | Use ui_kit table system |
| (None) | AppDataTable | ➕ New feature | ui_kit provides more powerful tables |
| (None) | CardRenderer | ➕ New feature | ui_kit provides card renderer |
| (None) | GridRenderer | ➕ New feature | ui_kit provides grid renderer |

## 🎯 Migration Strategy

### ✅ Direct Replacement (70% of components)
- **Theme System**: Directly use `AppTheme.create()`
- **Input Components**: IP, password, PIN, etc., all have corresponding components.
- **Selection Components**: Checkbox, Radio, Switch match directly.
- **Base Components**: Text, icons, cards, etc.

### ⚡ Requires Adaptation (20% of components)
- **Button Variants**: Need to be implemented through AppButton + AppSurface combinations.
- **Composite Cards**: Use AppCard + other components combination.
- **Panel Components**: Most can be implemented through combinations.

### ❌ Requires Keeping (10% of components)
```dart
// Continue using privacygui_widgets
import 'package:privacygui_widgets/theme/custom_responsive.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/container/stacked_listview.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_list.dart';
```

### ➕ Extra Features Gained
- More powerful table system (`AppDataTable`)
- Network-related input components (`AppMacAddressTextField`)
- Range input components (`AppRangeInput`)
- Advanced animation system
- Design system tokenization (Design System Tokens)

## 📋 Implementation Plan

### Phase 1: Theme System Migration (Weeks 1-2)
- [ ] Update `lib/app.dart` to use `AppTheme.create()`
- [ ] Migrate color schemes to ui_kit system
- [ ] Update text styles
- [ ] Test basic theme functionality

### Phase 2: Base Component Migration (Weeks 3-4)
- [ ] Migrate text components (`AppText`, `AppStyledText`)
- [ ] Migrate input components (`AppTextField` → `AppTextFormField`)
- [ ] Migrate selection components (`CheckBox` → `AppCheckbox`)
- [ ] Migrate dropdown menus (`DropdownButton` → `AppDropdown`)

### Phase 3: Composite Component Adaptation (Weeks 5-6)
- [ ] Adapt button components using `AppButton`
- [ ] Refactor card components using `AppCard`
- [ ] Adapt panel components
- [ ] Update navigation components

### Phase 4: Advanced Component Integration (Weeks 7-8)
- [ ] Integrate table system (`AppDataTable`)
- [ ] Migrate stepper (`AppStepper`)
- [ ] Integrate application bar (`AppUnifiedBar`)
- [ ] Test all new features

### Phase 5: Cleanup and Optimization (Weeks 9-10)
- [ ] Remove unused privacygui_widgets imports
- [ ] Optimize performance
- [ ] Complete testing
- [ ] Update documentation

## 🚨 Notes

### Dependency Management
```yaml
# pubspec.yaml
dependencies:
  ui_kit_library:
    git:
      url: https://github.com/AustinChangLinksys/ui-kit.git
      ref: main
  privacygui_widgets:
    path: plugins/widgets  # Keep necessary components
```

### Mixed Use Example
```dart
// Mixed imports
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacygui_widgets/theme/custom_responsive.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_list.dart';

// In app.dart
MaterialApp.router(
  theme: AppTheme.create(
    brightness: Brightness.light,
    seedColor: themeColor,
  ),
  builder: (context, child) => Material(
    child: CustomResponsive(  // Keep privacygui_widgets
      child: DesignSystem.init(  // Use ui_kit
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

### Performance Considerations
- ui_kit uses more modern rendering mechanisms, which may improve performance.
- Certain animations may need readjustment.
- Test memory usage.

### Testing Strategy
- Perform regression testing after each Phase is completed.
- Pay special attention to theme switching functionality.
- Verify responsive design performance on different screen sizes.
- Perform A/B testing to compare user experience.

## 🎉 Expected Benefits

### Short-term Benefits
- More consistent design language
- Refined code repetition
- Better type safety

### Long-term Benefits
- Easier to maintain and expand
- Gain new features from continuous ui_kit updates
- Better developer experience
- Improved application performance

---

**File Version**: 1.0
**Creation Date**: 2024-12-09
**Update Date**: 2024-12-09
**Owner**: Austin Chang