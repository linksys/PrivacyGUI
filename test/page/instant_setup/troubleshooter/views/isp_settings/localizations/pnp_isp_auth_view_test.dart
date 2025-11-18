import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_isp_auth_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

import '../../../../../../common/config.dart';
import '../../../../../../common/test_helper.dart';
import '../../../../../../common/test_responsive_widget.dart';

// Implementation: lib/page/instant_setup/troubleshooter/views/isp_settings/pnp_isp_auth_view.dart
// View ID: PNP-ISP-AUTH

// Test Cases:
// - PNP-ISP-AUTH_FULL-FLOW: Verify the UI flow, dialog, and login logic (success and failure).

void main() async {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens;

  setUp(() {
    testHelper.setup();
  });

  // Test ID: PNP-ISP-AUTH_FULL-FLOW
  testLocalizationsV2(
    'Verify ISP Auth view UI flow and error handling',
    (tester, localizedScreen) async {
      final context = await testHelper.pumpView(
        tester,
        child: const PnpIspAuthView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: localizedScreen.locale,
      );
      await tester.pumpAndSettle();

      // --- Step 1: Initial State ---
      expect(find.text(testHelper.loc(context).pnpIspSettingsAuthTitle),
          findsOneWidget);
      expect(find.byType(AppPasswordField), findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpRouterLoginWhereIsIt),
          findsOneWidget);
      expect(find.widgetWithText(AppFilledButton, testHelper.loc(context).next),
          findsOneWidget);
      await testHelper.takeScreenshot(
          tester, 'PNP-ISP-AUTH_FULL-FLOW_01_initial_state');

      // --- Step 2: "Where is it?" Dialog ---
      await tester
          .tap(find.text(testHelper.loc(context).pnpRouterLoginWhereIsIt));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(testHelper.loc(context).routerPassword), findsOneWidget);
      expect(find.text(testHelper.loc(context).modalRouterPasswordLocation),
          findsOneWidget);
      await testHelper.takeScreenshot(
          tester, 'PNP-ISP-AUTH_FULL-FLOW_02_where_is_it_dialog');

      await tester.tap(find.text(testHelper.loc(context).close));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);

      // --- Step 3: Login Failure (Incorrect Password) ---
      when(testHelper.mockPnpNotifier.checkAdminPassword(any))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 10));
        throw ExceptionInvalidAdminPassword();
      });

      await tester.enterText(find.byType(AppPasswordField), 'wrong_password');
      await tester.tap(
          find.widgetWithText(AppFilledButton, testHelper.loc(context).next));
      await tester.pump(); // Show spinner
      expect(find.byType(AppFullScreenSpinner), findsOneWidget);
      await tester.pumpAndSettle(); // Wait for error handling

      expect(find.text(testHelper.loc(context).errorIncorrectPassword),
          findsOneWidget);
      await testHelper.takeScreenshot(
          tester, 'PNP-ISP-AUTH_FULL-FLOW_03_incorrect_password');

      // --- Step 4: Login Success ---
      when(testHelper.mockPnpNotifier.checkAdminPassword(any))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 1000));
      });

      await tester.enterText(find.byType(AppPasswordField), 'correct_password');
      await tester.tap(
          find.widgetWithText(AppFilledButton, testHelper.loc(context).next));
      await tester.pump();
      await testHelper.takeScreenshot(
          tester, 'PNP-ISP-AUTH_FULL-FLOW_04_spinner');

      // Show spinner
      expect(find.byType(AppFullScreenSpinner), findsOneWidget);
      await tester.pumpAndSettle(); // Wait for pop to be called
    },
    helper: testHelper,
    screens: screens,
  );
}
