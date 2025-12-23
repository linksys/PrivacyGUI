import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../common/config.dart';
import '../../../common/test_helper.dart';
import '../../../common/test_responsive_widget.dart';
import 'snack_bar_sample_view.dart';

// Reference to Implementation File: lib/page/components/shortcuts/snack_bar.dart
// View ID: SNACKBAR
/// | Test ID             | Description                                                                 |
/// | :------------------ | :-------------------------------------------------------------------------- |
/// | `SNACKBAR-SUCCESS`  | Verifies all success snackbar variants (Saved, Copied, etc.).               |
/// | `SNACKBAR-FAIL`     | Verifies all failure snackbar variants (Invalid password, IP errors, etc.). |

void main() {
  final testHelper = TestHelper();
  // Include both mobile and desktop screens for full coverage
  final screens = responsiveAllScreens;

  setUp(() {
    testHelper.setup();
  });

  // Test ID: SNACKBAR-SUCCESS
  testLocalizations('Snack bar - Success scenarios', (tester, screen) async {
    testHelper.disableAnimations = false;

    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: screen.locale,
    );
    await tester.pumpAndSettle();

    final successButtons = [
      'Success: Saved',
      'Success: Changes saved',
      'Success: Success!',
      'Success: Copied to clipboard!',
      'Success: Done',
      'Success: Router password updated',
    ];

    for (var i = 0; i < successButtons.length; i++) {
      final label = successButtons[i];
      final buttonFinder = find.text(label);

      await tester.scrollUntilVisible(
        buttonFinder,
        100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(buttonFinder);
      await tester.pump(); // Start animation
      await tester
          .pump(const Duration(milliseconds: 500)); // Wait for visibility

      final step = (i + 1).toString().padLeft(2, '0');
      final safeLabel = label
          .replaceAll('Success: ', '')
          .replaceAll('!', '')
          .replaceAll(' ', '_')
          .toLowerCase();
      await testHelper.takeScreenshot(
          tester, 'SNACKBAR-SUCCESS-$step-$safeLabel');

      await tester.pump(const Duration(seconds: 4)); // Wait for auto-hide
    }
  }, screens: screens, helper: testHelper);

  // Test ID: SNACKBAR-FAIL
  testLocalizations('Snack bar - Failed scenarios', (tester, screen) async {
    testHelper.disableAnimations = false;

    await testHelper.pumpShellView(
      tester,
      child: const SnackBarSampleView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: screen.locale,
    );
    await tester.pumpAndSettle();

    final failedButtons = [
      'Failed: Failed!',
      'Failed: Invalid admin password',
      'Failed: Invalid firmware file!',
      'Failed: Error manual update failed!',
      'Failed: IP address or MAC address overlap',
      'Failed: Oops, something wrong here! Please try again later',
      'Failed: Unknown error',
      'Failed: Incorrect password',
      'Failed: Too many failed attempts',
      'Failed: Invalid destination MAC address',
      'Failed: Invalid destination IP address',
      'Failed: Invalid gateway IP address',
      'Failed: Invalid IP address',
      'Failed: Invalid DNS',
      'Failed: Invalid MAC address.',
      'Failed: Invalid input',
      'Failed: The specified server IP address is not valid.',
      'Failed: Invalid destination IP address', // Duplicate text
      'Failed: The rules cannot be created',
      'Failed: Guest network names must be different',
      'Failed: Unknown error: _ErrorUnexpected',
    ];

    final startIndex = 6; // Success buttons (0-5) take up first 6 slots

    for (var i = 0; i < failedButtons.length; i++) {
      final label = failedButtons[i];
      final buttonIndex = startIndex + i;
      final buttonFinder = find.byType(AppButton).at(buttonIndex);

      await tester.scrollUntilVisible(
        buttonFinder,
        100,
        scrollable: find.byType(Scrollable).last,
      );

      await tester.tap(buttonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final step = (i + 1).toString().padLeft(2, '0');
      // Handle duplicate filenames if necessary, keeping simple for now
      // Or append index to ensure uniqueness if labels are dupes
      final safeLabel = label
          .replaceAll('Failed: ', '')
          .replaceAll('!', '')
          .replaceAll('.', '')
          .replaceAll(':', '')
          .replaceAll(' ', '_')
          .toLowerCase();

      // Truncate long labels
      final truncatedLabel =
          safeLabel.length > 30 ? safeLabel.substring(0, 30) : safeLabel;

      await testHelper.takeScreenshot(
          tester, 'SNACKBAR-FAIL-$step-${truncatedLabel}_$i');

      await tester.pump(const Duration(seconds: 4));
    }
  }, screens: screens, helper: testHelper);
}
