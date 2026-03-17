# Test File Template

Basic structure for a new screenshot test file:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../common/config.dart';
import '../../../common/test_helper.dart';
import '../../../common/test_responsive_widget.dart';

/// View ID: MYVIEW
/// Implementation: lib/page/{feature}/{view}.dart
///
/// | Test ID | Description |
/// | :------ | :---------- |
/// | MYVIEW-INIT | Verifies initial state |

void main() {
  final testHelper = TestHelper();
  
  setUp(() => testHelper.setup());

  // Test ID: MYVIEW-INIT
  testLocalizations(
    'Verify initial state',
    (tester, locale) async {
      // 1. Mock the state
      when(testHelper.mockMyNotifier.build()).thenReturn(MyState());
      when(testHelper.mockMyNotifier.state).thenReturn(MyState());
      
      // 2. Pump the widget
      final context = await testHelper.pumpView(
        tester,
        child: const MyView(),
        locale: locale,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
      );
      
      // 3. Verify UI elements
      expect(find.byType(AppButton), findsOneWidget);
      expect(find.text(testHelper.loc(context).title), findsOneWidget);
    },
    screens: responsiveAllScreens,
    goldenFilename: 'MYVIEW-INIT-01-initial',
  );
}
```

# User Interaction Pattern

```dart
// Test ID: MYVIEW-DIALOG
testLocalizations(
  'Verify dialog appears on button tap',
  (tester, locale) async {
    when(testHelper.mockMyNotifier.build()).thenReturn(MyState());

    final context = await testHelper.pumpView(
      tester,
      child: const MyView(),
      locale: locale,
    );

    // Find and tap button
    final btnFinder = find.widgetWithText(
      AppButton,
      testHelper.loc(context).openDialog,
    );
    await tester.tap(btnFinder);
    await tester.pumpAndSettle();

    // Verify dialog appeared
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(testHelper.loc(context).dialogTitle),
      ),
      findsOneWidget,
    );
  },
  screens: responsiveAllScreens,
  goldenFilename: 'MYVIEW-DIALOG-01-shown',
);
```

# Multiple Screenshots Pattern

```dart
testLocalizations(
  'Test multi-step flow',
  (tester, locale) async {
    final context = await testHelper.pumpView(
      tester,
      child: const MyView(),
      locale: locale,
    );

    // Step 1: Initial
    await testHelper.takeScreenshot(tester, 'MYVIEW-FLOW-01-initial');

    // Step 2: After interaction
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();
    await testHelper.takeScreenshot(tester, 'MYVIEW-FLOW-02-after_tap');
  },
  screens: responsiveAllScreens,
  goldenFilename: 'MYVIEW-FLOW-03-final',
);
```

# Shell View Pattern (with Dashboard navigation)

```dart
final context = await testHelper.pumpShellView(
  tester,
  child: const MyView(),
  locale: locale,
);
```
