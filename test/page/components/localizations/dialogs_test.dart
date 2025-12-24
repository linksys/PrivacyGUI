import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../common/_index.dart';
import '../../../common/test_helper.dart';

// Test Harness Widget Class
// We use a class instead of a function returning Builder to avoid runtimeType ambiguity
// in TestHelper.pumpView's finder logic.
class DialogTestHarness extends StatelessWidget {
  final Future<void> Function(BuildContext context) onTrigger;

  const DialogTestHarness({super.key, required this.onTrigger});

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      return Center(
        child: AppButton.text(
          label: 'Show Dialog',
          onTap: () => onTrigger(context),
        ),
      );
    });
  }
}

// Reference to Implementation File: lib/page/components/shortcuts/dialogs.dart
// View ID: DIALOGS
/// | Test ID             | Description                                                                 |
/// | :------------------ | :-------------------------------------------------------------------------- |
/// | `DIALOGS-UNSAVED`   | Verifies "Unsaved Changes" dialog appears with correct text and buttons.    |

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
  });

  // Test ID: DIALOGS-UNSAVED
  testLocalizations('Dialog - You have unsaved changes',
      (tester, screen) async {
    // Enable animations to ensure Dialog transition completes and becomes visible
    testHelper.disableAnimations = false;

    await testHelper.pumpView(
      tester,
      child: DialogTestHarness(
        onTrigger: (context) => showUnsavedAlert(context),
      ),
      locale: screen.locale,
    );

    // Tap the harness button to trigger the dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Capture context for localization lookup
    final context = tester.element(find.byType(AppDialog));

    // Verify the Dialog UI using Keys and Localized Strings
    expect(find.byType(AppDialog), findsOneWidget);

    // Title & Description
    expect(
        find.text(testHelper.loc(context).unsavedChangesTitle), findsOneWidget);
    expect(
        find.text(testHelper.loc(context).unsavedChangesDesc), findsOneWidget);

    // Buttons (Keys + Text)
    expect(find.byKey(const Key('unsavedAlert_goBackButton')), findsOneWidget);
    expect(find.text(testHelper.loc(context).goBack), findsOneWidget);

    expect(find.byKey(const Key('unsavedAlert_discardButton')), findsOneWidget);
    expect(find.text(testHelper.loc(context).discardChanges), findsOneWidget);

    await testHelper.takeScreenshot(tester, 'DIALOGS-UNSAVED-01-initial_state');
  }, helper: testHelper);
}
