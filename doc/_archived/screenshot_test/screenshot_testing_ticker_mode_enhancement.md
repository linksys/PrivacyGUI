# Screenshot Testing Enhancement: TickerMode Integration

## Overview

This document describes the enhancement made to the screenshot testing infrastructure to integrate `TickerMode`, following the best practices from the UI Kit library's golden test utilities.

## Motivation

### Problem
Animations and loading states (e.g., skeleton screens, loaders) can cause:
1. **Flaky Tests**: Animations may be in different states when golden files are captured
2. **Timeout Issues**: Long-running or infinite animations can cause tests to timeout
3. **Inconsistent Golden Files**: Same UI might generate different golden files depending on animation timing

### Solution
Disable animations by default during golden tests using Flutter's `TickerMode` widget, which prevents `Ticker` objects (used by animations) from running.

## Implementation

### Reference from UI Kit

The implementation is inspired by `ui_kit/generative_ui/test/utils/golden_test_utils.dart`:

```dart
GoldenTestScenario buildSafeScenario({
  required String name,
  required ThemeData theme,
  required Widget child,
  double width = 300.0,
  double height = 200.0,
  bool disableAnimation = true, // Animations disabled by default
}) {
  return GoldenTestScenario(
    name: name,
    child: SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: Theme(
          data: theme,
          child: Center(
            child: TickerMode(
              enabled: !disableAnimation, // Key feature
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}
```

### Changes Made

#### 1. TestHelper Class (`test/common/test_helper.dart`)

Added `disableAnimations` property:

```dart
class TestHelper {
  // ... existing mock providers ...

  // Screen Size
  LocalizedScreen? current;

  // Animation control - disable by default for stable golden tests
  bool disableAnimations = true;

  // ... rest of the class ...
}
```

Updated all pump methods to use the `disableAnimations` flag:

```dart
Future<BuildContext> pumpView(WidgetTester tester, {
  required Widget child,
  // ... other parameters ...
}) async {
  await tester.pumpWidget(
    testableSingleRoute(
      // ... other parameters ...
      disableAnimations: disableAnimations, // Pass flag through
      child: child,
    ),
  );
  // ... rest of the method ...
}

Future<BuildContext> pumpShellView(WidgetTester tester, {
  required Widget child,
  // ... other parameters ...
}) async {
  await tester.pumpWidget(
    testableRouteShellWidget(
      // ... other parameters ...
      disableAnimations: disableAnimations, // Pass flag through
      child: child,
    ),
  );
  // ... rest of the method ...
}

Future<BuildContext> pumpRouter(
  WidgetTester tester,
  GoRouter router, {
  required Type baseViewType,
  // ... other parameters ...
}) async {
  await tester.pumpWidget(testableRouter(
    router: router,
    // ... other parameters ...
    disableAnimations: disableAnimations, // Pass flag through
  ));
  // ... rest of the method ...
}
```

#### 2. Testable Router Functions (`test/common/testable_router.dart`)

Added `disableAnimations` parameter to all router builder functions:

```dart
Widget testableRouter({
  required GoRouter router,
  // ... other parameters ...
  bool disableAnimations = true, // New parameter
}) {
  // ... theme setup ...

  return ProviderScope(
    overrides: overrides,
    parent: provider,
    child: MaterialApp.router(
      // ... other parameters ...
      builder: (context, child) => Material(
        child: TickerMode(
          enabled: !disableAnimations, // Wrap app with TickerMode
          child: DesignSystem.init(
            context,
            AppResponsiveLayout(
              mobile: (ctx) => child ?? const SizedBox(),
              desktop: (ctx) => child ?? const SizedBox(),
            ),
          ),
        ),
      ),
      // ... router configuration ...
    ),
  );
}

Widget testableSingleRoute({
  required Widget child,
  // ... other parameters ...
  bool disableAnimations = true, // New parameter
}) {
  // ... router setup ...
  return testableRouter(
    // ... other parameters ...
    disableAnimations: disableAnimations, // Pass through
  );
}

Widget testableRouteShellWidget({
  required Widget child,
  // ... other parameters ...
  bool disableAnimations = true, // New parameter
}) {
  // ... router setup ...
  return testableRouter(
    // ... other parameters ...
    disableAnimations: disableAnimations, // Pass through
  );
}
```

#### 3. Test Framework (`test/common/test_responsive_widget.dart`)

Updated `testLocalizationsV2` to support animation control:

```dart
@isTest
void testLocalizationsV2(
  String name,
  FutureOr<void> Function(WidgetTester, LocalizedScreen) testMain, {
  String? goldenFilename,
  List<Locale>? locales,
  List<ScreenSize>? screens,
  bool? skip,
  Timeout? timeout,
  bool semanticsEnabled = true,
  Future<void> Function(WidgetTester tester)? onCompleted,
  TestHelper? helper,
  bool disableAnimations = true, // New parameter with default
}) async {
  // ... locale and screen setup ...

  testResponsiveWidgets(
    name,
    (tester) async {
      await loadTestFonts();
      final current = variants.currentValue!;
      helper?.current = current;
      helper?.disableAnimations = disableAnimations; // Set helper flag
      await tester.setScreenSize(current);
      await testMain(tester, current);
    },
    // ... rest of the configuration ...
  );
}
```

## Usage

### Default Behavior (Animations Disabled)

By default, all animations are disabled for stable golden file generation:

```dart
testLocalizationsV2(
  'Test view with animations',
  (tester, screen) async {
    // Animations are automatically disabled
    final context = await testHelper.pumpView(
      tester,
      child: const MyView(),
      locale: screen.locale,
    );

    // Test assertions...
  },
  goldenFilename: 'MYVIEW-01-stable',
  helper: testHelper,
);
```

### Enabling Animations (When Needed)

If you need to test animations explicitly:

```dart
testLocalizationsV2(
  'Test animated transitions',
  (tester, screen) async {
    final context = await testHelper.pumpView(
      tester,
      child: const MyAnimatedView(),
      locale: screen.locale,
    );

    // Enable animations for this specific interaction
    testHelper.disableAnimations = false;
    await tester.tap(find.byType(AppButton));
    await tester.pump(); // Advance animation frame
    await tester.pump(const Duration(milliseconds: 300)); // Wait for animation

    // Test assertions on animated state...
  },
  goldenFilename: 'MYVIEW-ANIM-01-midway',
  helper: testHelper,
  disableAnimations: false, // Enable animations for entire test
);
```

### Per-Test Control

You can control animations on a per-test basis:

```dart
// Test 1: Animations disabled (default)
testLocalizationsV2(
  'Static state test',
  (tester, screen) async {
    // Loaders, skeletons will not animate
  },
  goldenFilename: 'TEST-01-static',
  helper: testHelper,
);

// Test 2: Animations enabled
testLocalizationsV2(
  'Animation test',
  (tester, screen) async {
    // Animations will run
  },
  goldenFilename: 'TEST-02-animated',
  helper: testHelper,
  disableAnimations: false, // Override default
);
```

## Benefits

### 1. **Stable Golden Files**
- Animations are frozen, ensuring consistent screenshots
- Eliminates timing-dependent visual differences

### 2. **Faster Test Execution**
- No waiting for animations to complete
- Reduces test execution time

### 3. **Reduced Flakiness**
- Tests no longer fail due to animation timing issues
- More reliable CI/CD pipeline

### 4. **Better Control**
- Can enable animations when explicitly needed for animation-specific tests
- Default behavior favors stability

### 5. **Prevents Timeouts**
- Infinite animations (like loaders) won't cause tests to hang
- More predictable test behavior

## Affected Components

This enhancement automatically benefits tests for:

### Loading States
- `AppLoader` and loading spinners
- Skeleton screens
- Progress indicators

### Animated Transitions
- Page transitions
- Dialog animations
- Modal animations

### UI Kit Animated Components
- `AppExpansionPanel` expand/collapse animations
- Button press animations
- Hover effects (if any)

## Migration Guide

### Existing Tests

No changes required! All existing tests will automatically benefit from disabled animations by default.

### Tests That Need Animations

If you have tests that explicitly test animations:

**Before**:
```dart
testLocalizationsV2(
  'Test animation',
  (tester, screen) async {
    await testHelper.pumpView(tester, child: const MyView(), locale: screen.locale);

    // This might be flaky
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle(); // Wait for animation
  },
  goldenFilename: 'TEST-01',
  helper: testHelper,
);
```

**After**:
```dart
testLocalizationsV2(
  'Test animation',
  (tester, screen) async {
    await testHelper.pumpView(tester, child: const MyView(), locale: screen.locale);

    // Explicitly enable animations
    await tester.tap(find.byType(AppButton));
    await tester.pump(); // Single frame
    await tester.pump(const Duration(milliseconds: 150)); // Specific duration
  },
  goldenFilename: 'TEST-01',
  helper: testHelper,
  disableAnimations: false, // Opt-in to animations
);
```

## Technical Details

### How TickerMode Works

From Flutter documentation:

> `TickerMode` enables or disables tickers (and thus animations) for a subtree.
>
> When `enabled` is false, tickers in the subtree are not allowed to tick. This prevents animations from running, which can be useful for performance reasons or for testing.

### Widget Tree Structure

```
MaterialApp.router
  └─ Material
      └─ TickerMode (enabled: !disableAnimations)
          └─ DesignSystem.init
              └─ AppResponsiveLayout
                  └─ [Your Widget]
```

The `TickerMode` wraps the entire app content, affecting all animations within the widget tree.

### Performance Impact

- **Negligible**: `TickerMode` is a lightweight widget
- **Build time**: No significant difference
- **Test execution**: Faster due to skipped animations

## Testing the Enhancement

### Verification Steps

1. **Run existing tests**: All should pass without changes
```bash
sh ./run_generate_loc_snapshots.sh -c true -f test/page/instant_setup/localizations/pnp_admin_view_test.dart
```

2. **Test with specific locale and screen**:
```bash
sh ./run_generate_loc_snapshots.sh -c true -f test/page/dashboard/localizations/dashboard_support_view_test.dart -l "en" -s "480"
```

3. **Check golden files**: Should be identical to previous runs
```bash
ls -la snapshots/
# Verify generated files are consistent
```

4. **Verify loader stability**: Tests with `AppLoader` should generate consistent goldens

### Known Limitations

1. **CSS Animations**: Web-specific CSS animations might not be affected
2. **Timer-based Updates**: Code using `Timer` directly instead of `TickerProvider` won't be affected
3. **External Animations**: Animations from packages that don't use Flutter's ticker system

## Related Files

- `test/common/test_helper.dart`: TestHelper class with `disableAnimations` property
- `test/common/testable_router.dart`: Router builders with `TickerMode` integration
- `test/common/test_responsive_widget.dart`: Test framework with animation control
- `ui_kit/generative_ui/test/utils/golden_test_utils.dart`: Original reference implementation

## References

- [Flutter TickerMode Documentation](https://api.flutter.dev/flutter/widgets/TickerMode-class.html)
- [Flutter Animation Testing Guide](https://docs.flutter.dev/cookbook/testing/widget/animations)
- [UI Kit Golden Test Utils](../../../flutter-workspaces/ui_kit/generative_ui/test/utils/golden_test_utils.dart)

---

**Author**: Development Team
**Date**: 2025-12-19
**Related**: `screenshot_testing_knowledge_base.md`, `screenshot_testing_guideline.md`
