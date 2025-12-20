import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/pnp_unplug_modem_view.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../common/config.dart';
import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';

/// View ID: PNPUM
/// Implementation file under test: lib/page/instant_setup/troubleshooter/views/pnp_unplug_modem_view.dart
///
/// | Test ID        | Description                                           |
/// | :------------- | :---------------------------------------------------- |
/// | `PNPUM-INIT_TIP` | Verifies the initial state and the tip dialog.        |
void main() async {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens;

  setUp(() {
    testHelper.setup();
    when(testHelper.mockPnpNotifier.checkAdminPassword(null)).thenAnswer((_) {
      throw ExceptionInvalidAdminPassword();
    });
  });

  // Test ID: PNPUM-INIT_TIP
  testLocalizationsV2(
    'Verify unplug modem view and tip dialog',
    (tester, localizedScreen) async {
      final context = await testHelper.pumpView(
        tester,
        child: const PnpUnplugModemView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: localizedScreen.locale,
      );

      // Verify initial state
      expect(find.text(testHelper.loc(context).pnpUnplugModemTitle),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpUnplugModemDesc),
          findsOneWidget);
      expect(find.bySemanticsLabel('modem Plugged image'), findsOneWidget);
      expect(
          find.text(testHelper.loc(context).pnpUnplugModemTip), findsOneWidget);
      expect(find.text(testHelper.loc(context).next), findsOneWidget);

      await testHelper.takeScreenshot(
          tester, 'PNPUM-INIT_TIP_01_initial_state');

      // Tap the tip button and verify dialog
      final tipFinder = find.text(testHelper.loc(context).pnpUnplugModemTip);
      await tester.tap(tipFinder);
      await tester.pumpAndSettle();

      expect(find.text(testHelper.loc(context).pnpUnplugModemTipTitle),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpUnplugModemTipDesc1),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpUnplugModemTipDesc2),
          findsOneWidget);
      // Find the tip image by its key (semanticsLabel may not work in dialog context)
      expect(find.byKey(const Key('pnpUnplugModemTipImage')), findsOneWidget);
    },
    helper: testHelper,
    screens: screens,
    goldenFilename: 'PNPUM-INIT_TIP_02_tip_dialog',
  );
}
