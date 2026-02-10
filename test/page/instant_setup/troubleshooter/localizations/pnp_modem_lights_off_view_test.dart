import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/pnp_modem_lights_off_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:ui_kit_library/ui_kit.dart';
import '../../../../common/config.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/test_helper.dart';

// View ID: PNPM
/// Implementation file under test: lib/page/instant_setup/troubleshooter/views/pnp_modem_lights_off_view.dart
///
/// This file contains screenshot tests for the `PnpModemLightsOffView` widget,
/// which guides the user through troubleshooting steps when modem lights are off.
///
/// | Test ID     | Description                                                                 |
/// | :---------- | :-------------------------------------------------------------------------- |
/// | `PNPM-INIT` | Verifies the initial state and the display of the tips modal.               |
void main() async {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens;

  setUp(() {
    testHelper.setup();
  });

  // Test ID: PNPM-INIT
  testThemeLocalizations(
    'Verify the initial state of the modem lights off troubleshooter and the tips modal',
    (tester, screen) async {
      final context = await testHelper.pumpView(
        tester,
        child: const PnpModemLightsOffView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: screen.locale,
      );
      await tester.pumpAndSettle();

      // Verify initial state elements
      expect(find.text(testHelper.loc(context).pnpModemLightsOffTitle),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpModemLightsOffDesc),
          findsOneWidget);
      expect(find.bySemanticsLabel('modem Device image'),
          findsOneWidget); // Verify image by semantics label
      final showTipsButton = find.widgetWithText(
          AppButton, testHelper.loc(context).pnpModemLightsOffTip);
      expect(showTipsButton, findsOneWidget);
      expect(find.widgetWithText(AppButton, testHelper.loc(context).next),
          findsOneWidget);

      // Tap "Show Tips" button and verify modal
      await tester.tap(showTipsButton);
      await tester.pumpAndSettle();

      // Take intermediate screenshot of the tips modal
      await testHelper.takeScreenshot(tester, 'PNPM-INIT_01_tips_modal');

      // Verify tips modal elements (uses AppDialog from UI Kit)
      expect(find.byType(AppDialog), findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpModemLightsOffTipTitle),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpModemLightsOffTipDesc),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpModemLightsOffTipStep1),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpModemLightsOffTipStep2),
          findsOneWidget);
      // Step 3 uses AppStyledText with HTML formatting and has a key for testing
      expect(
          tester
              .widget<AppStyledText>(
                  find.byKey(const Key('pnpModemLightsOffTipStep3')))
              .text,
          '<b>${testHelper.loc(context).pnpModemLightsOffTipStep3}</b>');
      final closeButton = find.widgetWithText(AppButton,
          testHelper.loc(context).ok); // Assuming 'close' for simple dialog
      expect(closeButton, findsOneWidget);

      // Close the modal
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Verify modal is gone and initial screen elements are still present
      expect(find.byType(AppDialog), findsNothing);
      expect(find.text(testHelper.loc(context).pnpModemLightsOffTitle),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpModemLightsOffDesc),
          findsOneWidget);
      expect(find.widgetWithText(AppButton, testHelper.loc(context).next),
          findsOneWidget);
    },
    helper: testHelper,
    screens: screens,
    goldenFilename: 'PNPM-INIT_02_final_state',
  );
}
