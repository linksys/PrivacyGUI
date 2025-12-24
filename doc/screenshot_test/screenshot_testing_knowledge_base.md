# Screenshot Testing Knowledge Base

This document provides comprehensive knowledge about the screenshot testing infrastructure in the PrivacyGUI project, specifically for tests located in `test/**/localizations/` directories.

---

## Table of Contents

1. [Test Infrastructure Overview](#1-test-infrastructure-overview)
2. [Test Execution Commands](#2-test-execution-commands)
3. [Test Structure & Conventions](#3-test-structure--conventions)
4. [TestHelper Class Usage](#4-testhelper-class-usage)
5. [Writing Screenshot Tests](#5-writing-screenshot-tests)
6. [UI Kit Migration Impact](#6-ui-kit-migration-impact)
7. [Screen Sizes & Locales](#7-screen-sizes--locales)
8. [Test Verification Requirements](#8-test-verification-requirements)
9. [Known Issues & Workarounds](#9-known-issues--workarounds)
10. [Test Execution Flow](#10-test-execution-flow)
11. [Migration Testing Strategy](#11-migration-testing-strategy)
12. [Quick Reference](#12-quick-reference)

---

## 1. Test Infrastructure Overview

### Test Location Structure

All screenshot tests are organized under localization directories:
- **Pattern**: `test/**/localizations/*_test.dart`
- **Total Files**: 47 screenshot test files
- **Total Directories**: 28 localization directories
- **Naming Convention**: `test/page/{feature}/localizations/{view}_test.dart`

### Key Infrastructure Files

| File | Purpose |
|------|---------|
| `doc/screenshot_testing_guideline.md` | Complete testing guidelines and best practices |
| `test/common/test_helper.dart` | Centralized test utilities with mock setup |
| `test/common/test_responsive_widget.dart` | Test framework for localization and responsive testing |
| `test/common/config.dart` | Screen size and locale configuration |
| `test/common/screen.dart` | Screen size and localized screen models |
| `run_generate_loc_snapshots.sh` | Main test execution script |
| `test_scripts/test_result_parser.dart` | Test result parsing for HTML reports |
| `test_scripts/combine_results.dart` | Combines test results across locales |
| `test_scripts/grep_loc_fils.dart` | Extracts golden file information |

---

## 2. Test Execution Commands

### Single File Test (Recommended for Development)

```bash
sh ./run_generate_loc_snapshots.sh -c true -f {{test_path}}
```

**Parameters:**
- `-c true`: Copy golden files instead of moving them (preserves originals)
- `-f`: Target test file path
- `-l`: Locales (default: `"en"`)
- `-s`: Screen sizes (default: `"480,1280"`)
- `-v`: Version number (default: `"0.0.1.1"`)

**Examples:**

```bash
# Test single file with default settings (en locale, 480 and 1280 screens)
sh ./run_generate_loc_snapshots.sh -c true -f test/page/instant_setup/localizations/pnp_admin_view_test.dart

# Test with specific locales
sh ./run_generate_loc_snapshots.sh -c true -f test/page/login/localizations/login_local_view_test.dart -l "en,es,ja"

# Test with specific screen sizes
sh ./run_generate_loc_snapshots.sh -c true -f test/page/dashboard/localizations/dashboard_home_view_test.dart -s "480,1280,1440"
```

### Full Test Suite Execution

```bash
# Run all localization tests
sh ./run_generate_loc_snapshots.sh

# Run with specific parameters
sh ./run_generate_loc_snapshots.sh -l "en,es" -s "480,1280"
```

### Direct Flutter Test Command

```bash
# Run specific test file
flutter test test/page/instant_setup/localizations/pnp_admin_view_test.dart \
  --tags=loc \
  --update-goldens \
  --dart-define=locales="en" \
  --dart-define=screens="480,1280"
```

---

## 3. Test Structure & Conventions

### Required Documentation Header

Every screenshot test file must include documentation after imports and before `main()`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// ... other imports

/// View ID: PNPA
/// Implementation file under test: lib/page/instant_setup/pnp_admin_view.dart
///
/// This file contains screenshot tests for the `PnpAdminView` widget,
/// covering various `PnpFlowStatus` states and user interactions.
///
/// | Test ID             | Description                                                                 |
/// | :------------------ | :-------------------------------------------------------------------------- |
/// | `PNPA-INIT`         | Verifies loading spinner and "Initializing Admin" message on startup.       |
/// | `PNPA-NETCHK`       | Verifies "Checking Internet Connection" message while network is being checked. |
/// | `PNPA-NETOK`        | Verifies "Internet Connected" message and continue button when online.      |

void main() {
  // test implementation
}
```

### Naming Conventions

**View ID Rules:**
- Must be **up to 5 uppercase English letters**
- No hyphens (`-`) or underscores (`_`)
- Examples: `PNPA`, `DSUP`, `DASHH`

**Test ID Format:**
- Pattern: `{ViewID}-{SHORT_DESCRIPTION}`
- Description: Up to 10 uppercase characters, use underscores to connect words
- Examples: `PNPA-INIT`, `DSUP-EXPAND`, `DASHH-OFFLINE`

**Golden File Naming Convention:**
- Pattern: `{TestID}-{number}-{description}`
- Number: Two-digit incremental (01, 02, 03...)
- Description: Short descriptive string (lowercase with underscores)
- Examples: `PNPA-INIT-01-initial_state`, `DSUP-EXPAND-02-all_categories`

### Test Description Guidelines

- Use clear, colloquial English
- Explain the **purpose** of the test, not just the condition
- Good: `"Verify admin password prompt with login and 'Where is it?' buttons"`
- Bad: `"Test password screen"`

---

## 4. TestHelper Class Usage

### Basic Setup

```dart
void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();  // Initializes all mock providers
  });

  // test cases...
}
```

### Animation Control

The `TestHelper` includes a `disableAnimations` property that controls whether animations run during tests:

```dart
class TestHelper {
  // Animation control - disable by default for stable golden tests
  bool disableAnimations = true;  // Default: animations disabled
}
```

**Default Behavior:**
- ✅ Animations are **disabled by default** for stable golden file generation
- ✅ Loaders, skeletons, and transitions will be frozen
- ✅ Tests run faster and are more deterministic

**Enabling Animations (When Needed):**
```dart
testLocalizations(
  'Test with animation',
  (tester, locale) async {
    // Enable animations for this specific test
    testHelper.disableAnimations = false;

    final context = await testHelper.pumpView(
      tester,
      child: const MyAnimatedView(),
      locale: locale,
    );

    // Animations will now run
  },
  goldenFilename: 'TEST-ANIM-01',
);
```

**How It Works:**

The `disableAnimations` flag is passed through to a `TickerMode` widget that wraps the entire app:

```dart
MaterialApp.router
  └─ Material
      └─ TickerMode (enabled: !disableAnimations)
          └─ DesignSystem.init
              └─ [Your Widget]
```

When `disableAnimations = true`, the `TickerMode.enabled = false`, which prevents all `Ticker` objects (used by animations) from running.

### Key Methods

#### Pump Methods

```dart
// For standalone pages without shell
final context = await testHelper.pumpView(
  tester,
  child: const MyView(),
  locale: locale,
  config: LinksysRouteConfig(
    column: ColumnGrid(column: 6, centered: true),
    noNaviRail: true,
  ),
  preCacheCustomImages: ['routerLn12'], // Optional: precache router images
);

// For pages with DashboardShell
final context = await testHelper.pumpShellView(
  tester,
  child: const MyView(),
  locale: locale,
);
```

#### Utility Methods

```dart
// Get localization strings
testHelper.loc(context).someText

// Take intermediate screenshots
await testHelper.takeScreenshot(tester, 'TESTID-02-intermediate_state');
```

### Mock Provider Access

The `TestHelper` provides access to all mock notifiers:

```dart
// Mock state
when(testHelper.mockPnpNotifier.build()).thenReturn(
  PnpState(
    status: PnpFlowStatus.adminInitializing,
    deviceInfo: deviceInfo,
  ),
);

// Mock async methods
when(testHelper.mockPnpNotifier.startPnpFlow(any))
  .thenAnswer((_) async {});

// Mock service helper capabilities
when(testHelper.mockServiceHelper.isSupportGuestNetwork()).thenReturn(true);
```

### Available Mock Providers

The `TestHelper` initializes the following mock notifiers:
- Dashboard: `mockDashboardHomeNotifier`, `mockDashboardManagerNotifier`
- Device: `mockDeviceListNotifier`, `mockDeviceManagerNotifier`, `mockExternalDeviceDetailNotifier`
- WiFi: `mockWiFiBundleNotifier`
- Admin: `mockAdministrationSettingsNotifier`, `mockRouterPasswordNotifier`, `mockTimezoneNotifier`
- Firmware: `mockFirmwareUpdateNotifier`, `mockManualFirmwareUpdateNotifier`
- Network: `mockInternetSettingsNotifier`, `mockLocalNetworkSettingsNotifier`, `mockStaticRoutingNotifier`
- Security: `mockFirewallNotifier`, `mockInstantSafetyNotifier`, `mockInstantPrivacyNotifier`
- PnP: `mockPnpNotifier`, `mockPnpTroubleshooterNotifier`, `mockPnpIspSettingsNotifier`
- Nodes: `mockAddNodesNotifier`, `mockNodeDetailNotifier`
- Other: `mockHealthCheckProvider`, `mockVPNNotifier`, `mockConnectivityNotifier`

---

## 5. Writing Screenshot Tests

### Using testLocalizations

```dart
// Test ID: PNPA-INIT
testLocalizations(
  'Verify loading spinner and "Initializing Admin" message on startup',
  (tester, locale) async {
    // 1. Mock the state
    when(testHelper.mockPnpNotifier.build()).thenReturn(
      PnpState(status: PnpFlowStatus.adminInitializing),
    );

    // 2. Pump the widget
    final context = await testHelper.pumpView(
      tester,
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 6, centered: true),
        noNaviRail: true,
      ),
      child: const PnpAdminView(),
      locale: locale,
    );

    // 3. Wait for UI to stabilize (if needed)
    await tester.pump(const Duration(milliseconds: 500));

    // 4. Verify UI elements
    expect(find.byType(AppLoader), findsOneWidget);
    expect(find.text(testHelper.loc(context).processing), findsOneWidget);
  },
  screens: responsiveAllScreens,
  goldenFilename: 'PNPA-INIT-01-initial_state',
);
```

### Using testLocalizationsV2 (with Helper)

```dart
// Test ID: DSUP-DESKTOP
testLocalizationsV2(
  'dashboard support view - default desktop layout',
  (tester, screen) async {
    // Access screen info: screen.locale, screen.width, screen.height
    final context = await testHelper.pumpShellView(
      tester,
      child: const FaqListView(),
      locale: screen.locale,
    );
    final loc = testHelper.loc(context);

    // Verify UI elements
    expect(find.text(loc.faqs), findsOneWidget);
    expect(find.byType(AppExpansionPanel), findsNWidgets(5));

    // Take intermediate screenshot
    await testHelper.takeScreenshot(tester, 'DSUP-DESKTOP-01-base');

    // Interact with UI
    await tester.tap(find.byType(AppIconButton));
    await tester.pumpAndSettle();
  },
  screens: responsiveDesktopScreens,
  goldenFilename: 'DSUP-DESKTOP-02-menu_open',
  helper: testHelper, // Makes screen info available to takeScreenshot
);
```

### Handling User Interactions

```dart
testLocalizations(
  'Verify "Where is it?" modal appears when button is tapped',
  (tester, locale) async {
    when(testHelper.mockPnpNotifier.build()).thenReturn(
      PnpState(
        status: PnpFlowStatus.adminAwaitingPassword,
        deviceInfo: deviceInfo,
      ),
    );

    final context = await testHelper.pumpView(
      tester,
      child: const PnpAdminView(),
      locale: locale,
    );

    // Initial state verification
    final btnFinder = find.widgetWithText(
        AppButton, testHelper.loc(context).pnpRouterLoginWhereIsIt);
    expect(btnFinder, findsOneWidget);

    // User interaction
    await tester.tap(btnFinder);
    await tester.pumpAndSettle(); // Wait for dialog animation

    // Verify dialog appeared
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(testHelper.loc(context).routerPassword),
      ),
      findsOneWidget,
    );
  },
  screens: responsiveAllScreens,
  goldenFilename: 'PNPA-PASS_MOD-01-where_is_it_modal',
);
```

### Multiple Screenshots in One Test

```dart
testLocalizations(
  'Test multi-step interaction flow',
  (tester, locale) async {
    final context = await testHelper.pumpView(
      tester,
      child: const MyView(),
      locale: locale,
    );

    // Step 1: Initial state
    expect(find.text(testHelper.loc(context).title), findsOneWidget);
    await testHelper.takeScreenshot(tester, 'TESTID-01-initial');

    // Step 2: After interaction
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await testHelper.takeScreenshot(tester, 'TESTID-02-dialog_shown');

    // Step 3: Final state
    await tester.tap(find.text(testHelper.loc(context).confirm));
    await tester.pumpAndSettle();
    expect(find.text(testHelper.loc(context).success), findsOneWidget);
  },
  screens: responsiveAllScreens,
  goldenFilename: 'TESTID-03-final_state',
);
```

---

## 6. UI Kit Migration Impact

### Widget Library Changes

**Old Library**: `privacygui_widgets` (local plugin)
**New Library**: `ui_kit_library` (external Git repository)

### Import Statement Update

```dart
// OLD - Do not use
import 'package:privacygui_widgets/widgets.dart';

// NEW - Use this
import 'package:ui_kit_library/ui_kit.dart';
```

### Common Widget Mapping

| Component Type | UI Kit Widget |
|---------------|---------------|
| Buttons | `AppButton`, `AppFilledButton`, `AppTextButton`, `AppIconButton` |
| Inputs | `AppTextField`, `AppPasswordInput` |
| Text | `AppText` |
| Loading | `AppLoader` |
| Icons | `AppFontIcons` |
| Expansion | `AppExpansionPanel` (replaces `AppExpansionCard`) |
| Cards | `AppCard` |
| Dialogs | Standard `AlertDialog` with UI Kit styling |

### Test Assertion Updates

When updating tests after UI Kit migration:

```dart
// Check for specific UI Kit widget types
expect(find.byType(AppButton), findsOneWidget);
expect(find.byType(AppLoader), findsOneWidget);
expect(find.byType(AppPasswordInput), findsOneWidget);

// Use widgetWithText for UI Kit buttons
expect(
  find.widgetWithText(AppButton, testHelper.loc(context).login),
  findsOneWidget,
);

// Check for UI Kit icons
expect(find.byIcon(AppFontIcons.globe), findsOneWidget);

// Check widget properties
final widget = tester.widget(find.byType(AppButton));
expect(widget, isA<AppButton>());
expect((widget as AppButton).onTap, null); // Verify disabled state
```

### Known Behavior Differences

#### AppExpansionPanel vs AppExpansionCard

**Issue**: Tap behavior differs between old and new components

```dart
// This may not work as expected with AppExpansionPanel
Future<void> expandAllCategories(WidgetTester tester) async {
  final finder = find.byType(AppExpansionPanel, skipOffstage: false);
  for (var i = 0; i < finder.evaluate().length; i++) {
    await tester.tap(finder.at(i));
    await tester.pumpAndSettle();
  }
}
```

**Workaround**: Under investigation. See `MIGRATION_TEST_RESULT.md` for updates.

---

## 7. Screen Sizes & Locales

### Default Screen Configurations

#### Mobile Screens
- `device480w`: 480×932 pixels, density 1.0
- `device744w`: 744×1133 pixels, density 1.0

#### Desktop Screens
- `device1080w`: 1080×720 pixels, density 1.0
- `device1280w`: 1280×720 pixels, density 1.0
- `device1440w`: 1440×900 pixels, density 1.0

### Screen Constants

```dart
// Available in test/common/config.dart
final responsiveAllScreens = [
  ...responsiveMobileScreens,
  ...responsiveDesktopScreens,
];

final responsiveMobileScreens = [device480w, device744w];
final responsiveDesktopScreens = [device1080w, device1280w, device1440w];
```

### Supported Locales

The app supports all locales defined in `AppLocalizations.supportedLocales`.

**Default**: English (`en`)

**Common locales**:
- English: `en`
- Spanish: `es`
- Japanese: `ja`
- French: `fr`
- German: `de`
- And others as defined in the app

### Environment Variables

Tests use Dart compile-time constants:

```bash
# Specify locales
--dart-define=locales="en,es,ja"

# Specify screen sizes
--dart-define=screens="480,1280,1440"

# These are automatically set by the run_generate_loc_snapshots.sh script
```

### Custom Screen Sizes

For specific test scenarios, create custom screen configurations:

```dart
final _expandedScreens = [
  ...responsiveMobileScreens.map(
    (screen) => screen.copyWith(name: '${screen.name}-Tall', height: 1900),
  ),
  ...responsiveDesktopScreens.map(
    (screen) => screen.copyWith(name: '${screen.name}-Tall', height: 1740),
  ),
];

testLocalizationsV2(
  'Test with taller screens',
  (tester, screen) async {
    // test implementation
  },
  screens: _expandedScreens,
  goldenFilename: 'TESTID-01-expanded',
);
```

---

## 8. Test Verification Requirements

### Prerequisites Before Writing Tests

**CRITICAL**: Always read the implementation file first!

Before writing any `expect` assertions:
1. Open and study `lib/page/{path}/{view}.dart`
2. Identify widget types used (e.g., `AppButton`, not generic `Button`)
3. Note any unique `Key`s assigned to widgets
4. Find exact localization keys used
5. Check for images and their `semanticsLabel`
6. Understand UI hierarchy

### Programmatic UI Verification

**Never rely solely on screenshots.** Always include assertions:

```dart
// Good: Specific widget type verification
expect(find.byType(AppButton), findsOneWidget);
expect(find.byType(AppLoader), findsOneWidget);

// Good: Localization key verification
expect(find.text(testHelper.loc(context).welcome), findsOneWidget);

// Good: Specific key verification
expect(find.byKey(const Key('admin_password_input_field')), findsOneWidget);

// Good: Widget predicate for detailed checks
expect(
  find.byWidgetPredicate((widget) =>
    widget is AppPasswordInput &&
    widget.label == testHelper.loc(context).routerPassword
  ),
  findsOneWidget,
);

// Bad: Too generic
expect(find.text('Welcome'), findsOneWidget); // Hardcoded text
expect(find.byType(Widget), findsOneWidget); // Too generic
```

### Disambiguating Finders

When multiple widgets with the same text exist:

```dart
// Use descendant to scope search
expect(
  find.descendant(
    of: find.byType(AlertDialog),
    matching: find.text(testHelper.loc(context).routerPassword),
  ),
  findsOneWidget,
);

// Or use keys
expect(find.byKey(const Key('dialog_title')), findsOneWidget);
```

### Handling Asynchronous Operations

#### Image Loading

```dart
// Method 1: Use preCacheCustomImages parameter
final context = await testHelper.pumpView(
  tester,
  child: const PnpAdminView(),
  locale: locale,
  preCacheCustomImages: ['routerLn12', 'deviceImage'],
);

// Method 2: Use runAsync
await tester.runAsync(() async {
  await precacheImage(
    DeviceImageHelper.getRouterImage('routerLn12'),
    context,
  );
});
```

#### UI Stabilization

```dart
// After state changes or animations
await tester.pumpAndSettle();

// With specific duration
await tester.pump(const Duration(milliseconds: 500));

// Multiple pumps for complex animations
await tester.pump();
await tester.pump(const Duration(seconds: 1));
await tester.pumpAndSettle();
```

#### Animation Handling

**Default (Recommended):**
```dart
// Animations are automatically disabled, no special handling needed
testLocalizations(
  'Test loading state',
  (tester, locale) async {
    when(testHelper.mockNotifier.build())
      .thenReturn(MyState(isLoading: true));

    final context = await testHelper.pumpView(
      tester,
      child: const MyView(),
      locale: locale,
    );

    // AppLoader will be frozen, golden file will be stable
    expect(find.byType(AppLoader), findsOneWidget);
  },
  goldenFilename: 'TEST-LOADING-01',
);
```

**With Animations Enabled (Rare):**
```dart
testLocalizations(
  'Test animation sequence',
  (tester, locale) async {
    // Enable animations for this specific test
    testHelper.disableAnimations = false;

    final context = await testHelper.pumpView(
      tester,
      child: const MyAnimatedView(),
      locale: locale,
    );

    // Trigger animation
    await tester.tap(find.byType(AppButton));

    // Advance animation by specific duration
    await tester.pump();  // First frame
    await tester.pump(const Duration(milliseconds: 150));  // Mid-animation

    // Capture mid-animation state
    expect(/* animation is in progress */);
  },
  goldenFilename: 'TEST-ANIM-MIDWAY-01',
);
```

**Note:** With animations disabled (default), `pumpAndSettle()` completes immediately since there are no animations to settle.

### Image Verification

```dart
// Verify image is displayed
expect(
  find.image(Assets.images.devicesXl.routerLn12.provider()),
  findsOneWidget,
);

// Verify by semantics label
expect(
  find.bySemanticsLabel('modem Device image'),
  findsOneWidget,
);
```

---

## 9. Known Issues & Workarounds

### Current Known Issues

Documented in `MIGRATION_TEST_RESULT.md`:

| Issue | Impact | Affected Files | Status |
|-------|--------|----------------|--------|
| `AppExpansionPanel` tap behavior | `expandAllCategories` helper doesn't expand panels | `faq_list_view.dart` test | ⚠️ Under investigation |
| Golden test overflow warnings | Visual warnings in test output, no functional impact | Multiple files | ✅ Acceptable (can be ignored) |
| `MissingPluginException` for `package_info` | Some tests fail when calling `getVersion()` | Tests using build config | ⚠️ Needs plugin mock |

### AppExpansionPanel Issue Details

**Problem Description**: The `AppExpansionPanel` component in UI Kit has different tap behavior compared to the old `AppExpansionCard` from privacygui_widgets.

**Current Code**:
```dart
Future<void> expandAllCategories(WidgetTester tester) async {
  final finder = find.byType(AppExpansionPanel, skipOffstage: false);
  for (var i = 0; i < finder.evaluate().length; i++) {
    await tester.tap(finder.at(i));
    await tester.pumpAndSettle();
  }
}
```

**Expected**: All expansion panels should expand
**Actual**: Panels do not expand when tapped

**Temporary Solution**: Under investigation. May require:
1. Finding the correct tappable area within `AppExpansionPanel`
2. Using a different interaction method
3. Updating the component implementation

### Overflow Warnings

**Problem**: Some tests show overflow warnings during golden file generation

**Example Output**:
```
A RenderFlex overflowed by 42 pixels on the bottom.
```

**Impact**: Visual warning only, does not affect test pass/fail

**Action**: Record in test results, but can be ignored for now

### Animation-Related Issues

**Problem**: Animations causing flaky golden files or test timeouts

**Solution**: ✅ **Resolved** - Animations are now disabled by default using `TickerMode`

**Benefits**:
- Stable golden files (no more animation timing issues)
- Faster test execution
- No timeout issues from infinite animations (loaders, etc.)

**If you need animations**: Set `testHelper.disableAnimations = false` in your test

---

## 10. Test Execution Flow

### Script Execution Steps

When running `sh ./run_generate_loc_snapshots.sh -c true -f {file}`:

1. **Parameter Parsing**
   - Script reads `-c`, `-f`, `-l`, `-s`, `-v` flags
   - Sets defaults: locales="en", screens="480,1280", version="0.0.1.1"

2. **Directory Setup**
   ```bash
   mkdir ./snapshots/
   ```

3. **Flutter Test Execution**
   ```bash
   flutter test {file} \
     --tags=loc \
     --update-goldens \
     --dart-define=locales="en" \
     --dart-define=screens="480,1280"
   ```

   **During test execution:**
   - `TestHelper` is initialized with `disableAnimations = true`
   - `TickerMode` wraps the app with `enabled = false`
   - All animations are frozen for stable golden file generation

4. **Golden File Collection**
   - Script finds all `goldens/` directories: `find ./ -iname 'goldens' -type d`
   - Copies (with `-c true`) or moves golden PNG files to `./snapshots/`

5. **File Organization**
   ```bash
   dart run test_scripts/grep_loc_fils.dart
   ```

### Golden File Generation

During test execution:

1. **Test runs** with `testLocalizations` or `testLocalizationsV2`
2. **For each locale and screen combination**:
   - Widget is pumped with specific locale and screen size
   - Test assertions run
   - Golden file is captured: `{goldenFilename}-{screen.toShort()}.png`
   - Example: `PNPA-INIT-01-initial_state-Device480w-en.png`

3. **Files are saved** in test directory's `goldens/` subdirectory
4. **Script collects** all golden files to central `snapshots/` folder

### Output Structure

```
snapshots/
├── PNPA-INIT-01-initial_state-Device480w-en.png
├── PNPA-INIT-01-initial_state-Device1280w-en.png
├── PNPA-NETCHK-01-checking_internet-Device480w-en.png
├── PNPA-NETCHK-01-checking_internet-Device1280w-en.png
└── ... (other golden files)
```

### Test Result Parsing

For full test suite runs (without `-f` flag):

1. Tests output JSON results to `snapshots/tests.json`
2. `test_result_parser.dart` processes results per locale
3. `combine_results.dart` aggregates all results
4. HTML report is generated with test statistics

---

## 11. Migration Testing Strategy

### Per-File Migration Verification

For each view file migrated to UI Kit:

#### Step 1: Static Analysis
```bash
flutter analyze lib/path/to/migrated_file.dart
```
- ✅ **Pass Criteria**: No errors (warnings acceptable)
- ❌ **Fail**: Fix errors before proceeding

#### Step 2: Check privacygui_widgets References
```bash
grep -n "privacygui_widgets" lib/path/to/migrated_file.dart
```
- ✅ **Pass Criteria**: No output (or only `hide` statements)
- ❌ **Fail**: Update imports to use `ui_kit_library`

#### Step 3: Locate Test File

**Standard Pattern**:
```
lib/page/login/view/login_local_view.dart
→ test/page/login/localizations/login_local_view_test.dart
```

**Exceptions** (see `MIGRATION_TEST_RESULT.md`):
```
lib/page/support/faq_list_view.dart
→ test/page/dashboard/localizations/dashboard_support_view_test.dart
```

#### Step 4: Update Test File (if needed)

Check test file for outdated widget references:

```bash
grep -n "privacygui_widgets" test/path/to/test_file.dart
```

Update assertions to use UI Kit widgets:

```dart
// OLD
expect(find.byType(CustomButton), findsOneWidget);

// NEW
expect(find.byType(AppButton), findsOneWidget);
```

#### Step 5: Run Screenshot Test
```bash
sh ./run_generate_loc_snapshots.sh -c true -f test/path/to/test_file.dart
```

**Result Evaluation**:
- ✅ **Pass**: Test completes without errors
- ⚠️ **Overflow Warning**: Acceptable, record in results
- ❌ **Widget Assertion Failed**: Update test expectations
- ❌ **Other Failure**: Debug and fix

#### Step 6: Document Results

Update `MIGRATION_TEST_RESULT.md`:

```markdown
| File | Test File Path | Result | Notes |
|------|----------------|--------|-------|
| `my_view.dart` | `test/.../my_view_test.dart` | ✅ Pass | - |
| `other_view.dart` | `test/.../other_view_test.dart` | ❌ Fail | Widget assertion failed, needs update |
```

### Batch Testing Strategy

For testing multiple files:

1. **Create test list**:
   ```bash
   # List all localization tests
   find test -path "*/localizations/*_test.dart" > test_list.txt
   ```

2. **Run tests in sequence**:
   ```bash
   while read test_file; do
     echo "Testing: $test_file"
     sh ./run_generate_loc_snapshots.sh -c true -f "$test_file"
     if [ $? -eq 0 ]; then
       echo "✅ PASS: $test_file"
     else
       echo "❌ FAIL: $test_file"
     fi
   done < test_list.txt
   ```

3. **Collect results** and update documentation

---

## 12. Quick Reference

### Essential Commands

```bash
# Single file test (animations disabled by default)
sh ./run_generate_loc_snapshots.sh -c true -f test/page/login/localizations/login_local_view_test.dart

# With specific locale
sh ./run_generate_loc_snapshots.sh -c true -f test/page/login/localizations/login_local_view_test.dart -l "en"

# With multiple locales
sh ./run_generate_loc_snapshots.sh -c true -f test/page/login/localizations/login_local_view_test.dart -l "en,es,ja"

# With specific screens
sh ./run_generate_loc_snapshots.sh -c true -f test/page/login/localizations/login_local_view_test.dart -s "480,1280"

# Static analysis
flutter analyze lib/page/login/view/login_local_view.dart

# Check for old widget references
grep -rn "privacygui_widgets" lib/page/login/
grep -rn "privacygui_widgets" test/page/login/
```

### Animation Control Quick Reference

```dart
// Default: Animations disabled (recommended for golden tests)
testLocalizations(
  'Stable test',
  (tester, locale) async {
    // No special code needed - animations are automatically disabled
    final context = await testHelper.pumpView(/* ... */);
  },
  goldenFilename: 'TEST-01',
);

// Enable animations (rare, only for animation testing)
testLocalizations(
  'Animation test',
  (tester, locale) async {
    testHelper.disableAnimations = false;  // Enable animations
    final context = await testHelper.pumpView(/* ... */);
  },
  goldenFilename: 'TEST-ANIM-01',
);
```

### Test File Templates

#### Basic Test Structure
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../common/config.dart';
import '../../../common/test_helper.dart';
import '../../../common/test_responsive_widget.dart';

/// View ID: MYVIEW
/// Implementation: lib/page/my_feature/my_view.dart
///
/// | Test ID | Description |
/// | :------ | :---------- |
/// | MYVIEW-INIT | Verifies initial state |

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
  });

  testLocalizations(
    'Verify initial state',
    (tester, locale) async {
      when(testHelper.mockMyNotifier.build()).thenReturn(MyState());

      final context = await testHelper.pumpView(
        tester,
        child: const MyView(),
        locale: locale,
      );

      expect(find.byType(AppText), findsWidgets);
    },
    screens: responsiveAllScreens,
    goldenFilename: 'MYVIEW-INIT-01-initial',
  );
}
```

#### With User Interaction
```dart
testLocalizations(
  'Verify dialog appears on button tap',
  (tester, locale) async {
    when(testHelper.mockMyNotifier.build()).thenReturn(MyState());

    final context = await testHelper.pumpView(
      tester,
      child: const MyView(),
      locale: locale,
    );

    // Verify initial state
    expect(find.byType(AppButton), findsOneWidget);

    // Interact
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    // Verify result
    expect(find.byType(AlertDialog), findsOneWidget);
  },
  screens: responsiveAllScreens,
  goldenFilename: 'MYVIEW-DIALOG-01-shown',
);
```

### Example Test Files

**Well-Structured Examples to Follow**:
1. `test/page/instant_setup/localizations/pnp_admin_view_test.dart`
   - Complete documentation
   - Multiple test scenarios
   - Proper state mocking
   - User interactions

2. `test/page/dashboard/localizations/dashboard_support_view_test.dart`
   - Uses `testLocalizationsV2`
   - Helper integration
   - Intermediate screenshots

3. `test/page/instant_setup/localizations/pnp_setup_view_test.dart`
   - Complex multi-step flows
   - Image precaching
   - Detailed assertions

### Common Pitfalls

❌ **Don't**:
- Skip reading the implementation file
- Use hardcoded strings instead of localization keys
- Forget to mock provider state
- Use generic widget types in assertions
- Skip image precaching when testing views with images
- Enable animations unless specifically testing animation behavior

✅ **Do**:
- Read implementation file first
- Use `testHelper.loc(context)` for all text
- Mock all required provider states
- Use specific widget types (`AppButton`, not `Button`)
- Precache images before assertions
- Keep animations disabled (default) for stable golden files
- Use `pumpAndSettle()` after interactions (it completes immediately with animations disabled)

### Debugging Tips

**Test Fails with Widget Not Found**:
```dart
// Print widget tree
debugDumpApp();

// Find all widgets
print(find.byWidgetPredicate((w) => true).evaluate().map((e) => e.widget.runtimeType));
```

**Golden File Mismatch**:
- Check if implementation changed
- Verify screen size and locale are correct
- Review test output in `snapshots/` directory
- Use `-c true` to preserve old goldens for comparison

**Mock Not Working**:
```dart
// Verify mock is being called
verify(testHelper.mockMyNotifier.build()).called(1);

// Check provider override is registered
// Ensure provider is in testHelper.defaultOverrides
```

---

## Related Documentation

- [screenshot_testing_guideline.md](screenshot_testing_guideline.md) - Official testing guidelines
- [screenshot_testing_ticker_mode_enhancement.md](screenshot_testing_ticker_mode_enhancement.md) - Detailed TickerMode implementation guide
- [TICKER_MODE_SUMMARY.md](TICKER_MODE_SUMMARY.md) - Quick summary of TickerMode integration
- [MIGRATION_TEST_RESULT.md](../MIGRATION_TEST_RESULT.md) - Current migration test status
- [CLAUDE.md](../CLAUDE.md) - Project overview and development commands

---

**Last Updated**: 2025-12-19
**Maintained By**: Development Team
**For Questions**: Refer to related documentation or consult the team

## Appendix: TickerMode Integration

### What is TickerMode?

`TickerMode` is a Flutter widget that enables or disables tickers (and thus animations) for a subtree. When `TickerMode.enabled = false`, all animations in the widget tree below it are frozen.

### Why We Use It

**Before TickerMode Integration:**
- ❌ Flaky golden files due to animation timing
- ❌ Test timeouts from infinite animations (loaders)
- ❌ Inconsistent screenshots across test runs

**After TickerMode Integration:**
- ✅ Stable, reproducible golden files
- ✅ Faster test execution
- ✅ No timeout issues
- ✅ Consistent results every time

### Implementation Details

The `TickerMode` widget is integrated at the app level in `testable_router.dart`:

```dart
MaterialApp.router(
  builder: (context, child) => Material(
    child: TickerMode(
      enabled: !disableAnimations,  // Controlled by TestHelper
      child: DesignSystem.init(
        context,
        AppResponsiveLayout(
          mobile: (ctx) => child ?? const SizedBox(),
          desktop: (ctx) => child ?? const SizedBox(),
        ),
      ),
    ),
  ),
)
```

### Affected Components

With animations disabled (default), these components are frozen:

**Loading States:**
- `AppLoader` - No spinning
- Skeleton screens - Static
- Progress indicators - Frozen

**Transitions:**
- Page transitions - Instant
- Dialog animations - Immediate
- Modal fade-in/out - Instant

**UI Kit Components:**
- `AppExpansionPanel` - Instant expand/collapse
- Button ripples - No animation
- Any component using `AnimationController`

### When to Enable Animations

Enable animations ONLY when:
1. Explicitly testing animation behavior
2. Capturing mid-animation screenshots for documentation
3. Testing animation-dependent logic

**Example:**
```dart
testLocalizations(
  'Test expansion animation sequence',
  (tester, locale) async {
    testHelper.disableAnimations = false;  // Enable

    final context = await testHelper.pumpView(/* ... */);

    await tester.tap(find.byType(AppExpansionPanel));
    await tester.pump();  // Start animation
    await tester.pump(const Duration(milliseconds: 150));  // Mid-animation

    // Capture mid-animation state
  },
  goldenFilename: 'TEST-EXPANDING-01',
);
```

### Technical Reference

- **Flutter Docs**: [TickerMode Class](https://api.flutter.dev/flutter/widgets/TickerMode-class.html)
- **Inspiration**: `ui_kit/generative_ui/test/utils/golden_test_utils.dart`
- **Implementation**: Integrated in `test/common/testable_router.dart` and `test/common/test_helper.dart`
