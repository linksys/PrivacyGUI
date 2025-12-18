import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/pnp_waiting_modem_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../common/config.dart';
import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';

/// View ID: PNPWM
/// Implementation file under test: lib/page/instant_setup/troubleshooter/views/pnp_waiting_modem_view.dart
///
/// | Test ID         | Description                                                                 |
/// | :-------------- | :-------------------------------------------------------------------------- |
/// | `PNPWM-FULL_FLOW` | Verifies the full flow from countdown to checking for internet.             |
void main() async {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens;

  setUp(() {
    testHelper.setup();
    when(testHelper.mockPnpNotifier.checkAdminPassword(null)).thenAnswer((_) {
      throw ExceptionInvalidAdminPassword();
    });
    // Mock the checkInternetConnection to return a pending Future to avoid navigation
    when(testHelper.mockPnpNotifier.checkInternetConnection(any))
        .thenAnswer((_) => Completer<bool>().future);
  });

  // Test ID: PNPWM-FULL_FLOW
  testLocalizationsV2(
    'Verify waiting modem full flow',
    (tester, localizedScreen) async {
      final context = await testHelper.pumpView(
        tester,
        child: const PnpWaitingModemView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: localizedScreen.locale,
      );

      // 1. Initial state: Counting down
      await tester.pump(const Duration(seconds: 3));
      expect(find.text(testHelper.loc(context).pnpWaitingModemTitle),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpWaitingModemDesc),
          findsOneWidget);
      expect(find.byType(AppLoader), findsOneWidget);
      await testHelper.takeScreenshot(
          tester, 'PNPWM-FULL_FLOW_01_counting_down');

      // 2. State: Plug your modem back in
      await tester.pumpAndSettle(const Duration(seconds: 150));
      expect(find.text(testHelper.loc(context).pnpWaitingModemPlugBack),
          findsOneWidget);
      expect(find.bySemanticsLabel('modem Plugged image'), findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpWaitingModemPluggedIn),
          findsOneWidget);
      await testHelper.takeScreenshot(
          tester, 'PNPWM-FULL_FLOW_02_plug_back_in');

      // 3. State: Wait to start up
      final btnFinder =
          find.text(testHelper.loc(context).pnpWaitingModemPluggedIn);
      await tester.tap(btnFinder);
      await tester.pump(); // Trigger setState for _isPlugged
      expect(find.text(testHelper.loc(context).pnpWaitingModemWaitStartUp),
          findsOneWidget);
      expect(find.bySemanticsLabel('modem Waiting image'), findsOneWidget);
      await testHelper.takeScreenshot(
          tester, 'PNPWM-FULL_FLOW_03_waiting_to_start');

      // 4. State: Checking for internet
      await tester
          .pump(const Duration(seconds: 5)); // Trigger _isCheckingInternet
      expect(find.text(testHelper.loc(context).pnpWaitingModemCheckingInternet),
          findsOneWidget);
      expect(find.byType(AppLoader), findsOneWidget);
    },
    helper: testHelper,
    screens: screens,
    goldenFilename: 'PNPWM-FULL_FLOW_04_checking_internet',
  );
}
