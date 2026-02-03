# AppGap Mapping Reference

## Basic Mapping

| privacygui_widgets | ui_kit_library | Pixels | Usage |
|-------------------|----------------|----------------|------------------|
| `AppGap.small()`  | `AppGap.xs()`  | 4px           | Minimal spacing |
| `AppGap.small2()` | `AppGap.sm()`  | 8px           | Small spacing |
| `AppGap.small3()` | `AppGap.md()`  | 12px          | Default spacing |
| `AppGap.medium()` | `AppGap.lg()`  | 16px          | Medium spacing |
| `AppGap.large()`  | `AppGap.xl()`  | 20px          | Large spacing |
| `AppGap.large2()` | `AppGap.xxl()` | 24px          | Extra large spacing |
| `AppGap.large3()` | `AppGap.xxxl()` | 32px         | Maximum spacing |
| `AppGap.gutter()` | `AppGap.gutter()` | 16px       | Layout gutter |

## Common Usage Recommendations

### Form Spacing
- **Form field spacing**: `AppGap.md()` (12px) - Between form fields
- **Form section spacing**: `AppGap.lg()` (16px) - Between form sections
- **Label and Input**: `AppGap.xs()` (4px) - Between label and input box

### Card Spacing
- **Internal card spacing**: `AppGap.lg()` (16px) - Padding within cards
- **External card margin**: `AppGap.sm()` (8px) - Spacing between cards

### Button Spacing
- **Button group spacing**: `AppGap.sm()` (8px) - Spacing between buttons in a group
- **Button block spacing**: `AppGap.lg()` (16px) - Between button blocks

### Layout Spacing
- **Page section spacing**: `AppGap.xl()` (20px) - Between major page sections
- **List item spacing**: `AppGap.sm()` (8px) - Between list items
- **Main heading spacing**: `AppGap.xxxl()` (32px) - For important heading sections

### Component Spacing
- **Icon and Text spacing**: `AppGap.xs()` (4px) - Between icon and text
- **Toggle component spacing**: `AppGap.sm()` (8px) - Between toggle and label

## Resolving Naming Conflicts

When importing both libraries at the same time, use `hide` to avoid conflicts:

```dart
// Hide AppGap from ui_kit_library
import 'package:ui_kit_library/ui_kit.dart' hide AppGap;
import 'package:privacygui_widgets/widgets/gap/gap.dart';

// Or hide AppGap from privacygui_widgets
import 'package:privacygui_widgets/widgets/_widgets.dart' hide AppGap;
import 'package:ui_kit_library/ui_kit.dart';
```

## Using Mapping Utilities

```dart
import 'package:privacy_gui/util/appgap_mapping.dart';

// Get corresponding gap
Widget gap = AppGapMapper.getUiKitGap('medium'); // Returns AppGap.lg()
Widget gap2 = AppGapMapper.getPrivacyGap('lg');  // Returns AppGap.medium()

// Use extension methods
Widget gap3 = 'medium'.toGap(useUiKit: true);   // ui_kit AppGap.lg()
double pixels = 'medium'.gapPixels;              // 16.0

// Convert gap systems
String uiKitSize = 'medium'.toUiKitGap();       // 'lg'
String privacySize = 'lg'.toPrivacyGap();        // 'medium'
```

## Migration Guide

### Step 1: Identify existing usage
```dart
// Old code (privacygui_widgets)
const AppGap.small2(),
const AppGap.medium(),
const AppGap.large3(),
```

### Step 2: Convert to new format
```dart
// New code (ui_kit_library)
AppGap.sm(),    // Alternative to AppGap.small2()
AppGap.lg(),    // Alternative to AppGap.medium()
AppGap.xxxl(),  // Alternative to AppGap.large3()
```

### Step 3: Update import statements
```dart
// Add hide clauses to avoid conflicts
import 'package:ui_kit_library/ui_kit.dart' hide AppGap, AppText;
import 'package:privacygui_widgets/widgets/gap/gap.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';
```

## Common Issues & Solutions

### Issue 1: `prefix_shadowed_by_local_declaration`
```dart
// Problem: AppGap is shadowed by a local declaration
error - The prefix 'AppGap' can't be used here because it's shadowed by a local declaration.

// Solution: Use hide to hide conflicting names
import 'package:ui_kit_library/ui_kit.dart' hide AppGap;
```

### Issue 2: `ambiguous_import`
```dart
// Problem: Both libraries define the same name
error - The name 'AppGap' is defined in multiple libraries.

// Solution: Use aliases or hide
import 'package:ui_kit_library/ui_kit.dart' as UiKit;
import 'package:privacygui_widgets/widgets/gap/gap.dart' as PrivacyGap;
```

### Issue 3: Property name mismatch
```dart
// ui_kit_library uses simplified names
AppGap.sm()    // ✓ Correct
AppGap.small2() // ✗ Incorrect - This is privacygui_widgets syntax
```

## Best Practices

1. **Maintain Consistency**: Use a single gap system within a single file.
2. **Use Semantic Names**: Prefer `AppGapMapper.getRecommendedSpacing('form_field')`.
3. **Avoid Hard-coding**: Use predefined gap values instead of custom pixels.
4. **Test Responsiveness**: Ensure spacing displays correctly across different screen sizes.

## Utility Examples

```dart
// Get all available gap sizes
Map<String, double> gaps = AppGapMapper.getAllGapSizes();

// Validate gap size
bool isValid = AppGapMapper.isValidGapSize('medium'); // true

// Get recommended spacing
Widget spacing = AppGapMapper.getRecommendedSpacing('form_field');

// Use constants
Widget box = AppGapConstants.lgBox;  // SizedBox(height: 16, width: 16)
Widget vertical = AppGapConstants.lgVertical;  // SizedBox(height: 16)
```