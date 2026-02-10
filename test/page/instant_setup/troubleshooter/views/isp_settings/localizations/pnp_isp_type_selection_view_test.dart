import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/_internet_settings.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/providers/pnp_isp_settings_provider.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_isp_type_selection_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../../../common/config.dart';
import '../../../../../../common/test_helper.dart';
import '../../../../../../common/test_responsive_widget.dart';
import '../../../../../../test_data/internet_settings_state_data.dart';

// Implementation: lib/page/instant_setup/troubleshooter/views/isp_settings/pnp_isp_type_selection_view.dart
// View ID: PNP-ISP-SEL

// Test Cases:
// - PNP-ISP-SEL_DEFAULT: Verify the initial state where DHCP is the default.
// - PNP-ISP-SEL_DHCP-ALERT: Verify the DHCP alert dialog when another type is selected.
// - PNP-ISP-SEL_DHCP-SAVE-ERROR-GENERIC: Verify generic JNAPError during DHCP save.
// - PNP-ISP-SEL_DHCP-SAVE-ERROR-NO-INTERNET: Verify no internet connection error during DHCP save.
// - PNP-ISP-SEL_DHCP-SAVE-ERROR-SIDE-EFFECT-SUCCESS: Verify ServiceSideEffectError with JNAPSuccess during DHCP save.
// - PNP-ISP-SEL_DHCP-SAVE-ERROR-SIDE-EFFECT-OTHER: Verify ServiceSideEffectError without JNAPSuccess during DHCP save.

void main() async {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens;

  setUp(() {
    testHelper.setup();
    // Default successful save for tests that don't specifically test errors
    when(testHelper.mockPnpIspSettingsNotifier.saveAndVerifySettings(any))
        .thenAnswer((_) async {});
  });

  // Test ID: PNP-ISP-SEL_DEFAULT
  testThemeLocalizations(
    'Verify ISP type selection view default state',
    (tester, localizedScreen) async {
      final mockInternetSettingsState =
          InternetSettingsState.fromJson(internetSettingsStateData);
      when(testHelper.mockInternetSettingsNotifier.fetch(forceRemote: true))
          .thenAnswer((_) async => mockInternetSettingsState);
      when(testHelper.mockInternetSettingsNotifier.build())
          .thenReturn(mockInternetSettingsState);

      final context = await testHelper.pumpView(
        tester,
        child: const PnpIspTypeSelectionView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: localizedScreen.locale,
        overrides: [
          pnpIspSettingsProvider
              .overrideWith(() => testHelper.mockPnpIspSettingsNotifier),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text(testHelper.loc(context).pnpIspTypeSelectionTitle),
          findsOneWidget);
      expect(
          find.descendant(
              of: find.widgetWithText(
                  ISPTypeCard, testHelper.loc(context).dhcpDefault),
              matching: find.byIcon(AppFontIcons.check)),
          findsOneWidget);
    },
    helper: testHelper,
    screens: screens,
    goldenFilename: 'PNP-ISP-SEL_DEFAULT_01_initial_state',
  );

  // Test ID: PNP-ISP-SEL_DHCP-ALERT
  testThemeLocalizations(
    'Verify ISP type selection DHCP alert dialog',
    (tester, localizedScreen) async {
      final mockInternetSettingsState2 =
          InternetSettingsState.fromMap(jsonDecode(internetSettingsStateData2));
      when(testHelper.mockInternetSettingsNotifier.fetch(forceRemote: true))
          .thenAnswer((_) async => mockInternetSettingsState2);
      when(testHelper.mockInternetSettingsNotifier.build())
          .thenReturn(mockInternetSettingsState2);

      final context = await testHelper.pumpView(
        tester,
        child: const PnpIspTypeSelectionView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: localizedScreen.locale,
        overrides: [
          pnpIspSettingsProvider
              .overrideWith(() => testHelper.mockPnpIspSettingsNotifier),
        ],
      );
      await tester.pumpAndSettle();

      expect(
          find.descendant(
              of: find.widgetWithText(
                  ISPTypeCard, testHelper.loc(context).dhcpDefault),
              matching: find.byIcon(AppFontIcons.chevronRight)),
          findsOneWidget);

      final dhcpCardFinder =
          find.widgetWithText(ISPTypeCard, testHelper.loc(context).dhcpDefault);
      await tester.tap(dhcpCardFinder);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(testHelper.loc(context).settingsSaved), findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpIspTypeSelectionDhcpConfirm),
          findsOneWidget);
    },
    helper: testHelper,
    screens: screens,
    goldenFilename: 'PNP-ISP-SEL_DHCP-ALERT_01_alert_dialog',
  );

  // Test ID: PNP-ISP-SEL_DHCP-SAVE-ERROR-GENERIC
  testThemeLocalizations(
    'Verify generic JNAPError during DHCP save',
    (tester, localizedScreen) async {
      final mockInternetSettingsState2 =
          InternetSettingsState.fromMap(jsonDecode(internetSettingsStateData2));
      when(testHelper.mockInternetSettingsNotifier.fetch(forceRemote: true))
          .thenAnswer((_) async => mockInternetSettingsState2);
      when(testHelper.mockInternetSettingsNotifier.build())
          .thenReturn(mockInternetSettingsState2);

      final completer = Completer<void>();
      when(testHelper.mockPnpIspSettingsNotifier.saveAndVerifySettings(any))
          .thenAnswer((_) => completer.future);

      final context = await testHelper.pumpView(
        tester,
        child: const PnpIspTypeSelectionView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: localizedScreen.locale,
        overrides: [],
      );
      await tester.pumpAndSettle();

      // Tap DHCP card to open alert
      final dhcpCardFinder =
          find.widgetWithText(ISPTypeCard, testHelper.loc(context).dhcpDefault);
      await tester.tap(dhcpCardFinder);
      await tester.pumpAndSettle();

      // Tap OK on alert to trigger save
      await tester.tap(find.text(testHelper.loc(context).ok));
      await tester.pump(); // Show spinner

      expect(find.byType(AppFullScreenLoader), findsOneWidget);

      // Complete with generic JNAPError
      completer.completeError(JNAPError(result: '', error: 'generic error'));
      await tester.pumpAndSettle(); // Hide spinner, show error dialog

      expect(find.byType(AppFullScreenLoader), findsNothing);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(testHelper.loc(context).error), findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpErrorForStaticIpAndDhcp),
          findsOneWidget);
      verify(testHelper.mockPnpIspSettingsNotifier.saveAndVerifySettings(any))
          .called(1);
    },
    helper: testHelper,
    screens: screens,
    goldenFilename: 'PNP-ISP-SEL_DHCP-SAVE-ERROR-GENERIC_01_error_dialog',
  );

  // Test ID: PNP-ISP-SEL_DHCP-SAVE-ERROR-NO-INTERNET
  testThemeLocalizations(
    'Verify no internet connection error during DHCP save',
    (tester, localizedScreen) async {
      final mockInternetSettingsState2 =
          InternetSettingsState.fromMap(jsonDecode(internetSettingsStateData2));
      when(testHelper.mockInternetSettingsNotifier.fetch(forceRemote: true))
          .thenAnswer((_) async => mockInternetSettingsState2);
      when(testHelper.mockInternetSettingsNotifier.build())
          .thenReturn(mockInternetSettingsState2);

      final completer = Completer<void>();
      when(testHelper.mockPnpIspSettingsNotifier.saveAndVerifySettings(any))
          .thenAnswer((_) => completer.future);

      final context = await testHelper.pumpView(
        tester,
        child: const PnpIspTypeSelectionView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: localizedScreen.locale,
        overrides: [],
      );
      await tester.pumpAndSettle();

      // Tap DHCP card to open alert
      final dhcpCardFinder =
          find.widgetWithText(ISPTypeCard, testHelper.loc(context).dhcpDefault);
      await tester.tap(dhcpCardFinder);
      await tester.pumpAndSettle();

      // Tap OK on alert to trigger save
      await tester.tap(find.text(testHelper.loc(context).ok));
      await tester.pump(); // Show spinner

      expect(find.byType(AppFullScreenLoader), findsOneWidget);

      // Complete with ExceptionNoInternetConnection
      completer.completeError(ExceptionNoInternetConnection());
      await tester.pumpAndSettle(); // Hide spinner, show error dialog

      expect(find.byType(AppFullScreenLoader), findsNothing);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(testHelper.loc(context).error), findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpErrorForStaticIpAndDhcp),
          findsOneWidget);
      verify(testHelper.mockPnpIspSettingsNotifier.saveAndVerifySettings(any))
          .called(1);
    },
    helper: testHelper,
    screens: screens,
    goldenFilename: 'PNP-ISP-SEL_DHCP-SAVE-ERROR-NO-INTERNET_01_error_dialog',
  );

  // Test ID: PNP-ISP-SEL_DHCP-SAVE-ERROR-SIDE-EFFECT-SUCCESS
  testThemeLocalizations(
    'Verify ServiceSideEffectError with JNAPSuccess during DHCP save',
    (tester, localizedScreen) async {
      final mockInternetSettingsState2 =
          InternetSettingsState.fromMap(jsonDecode(internetSettingsStateData2));
      when(testHelper.mockInternetSettingsNotifier.fetch(forceRemote: true))
          .thenAnswer((_) async => mockInternetSettingsState2);
      when(testHelper.mockInternetSettingsNotifier.build())
          .thenReturn(mockInternetSettingsState2);

      final completer = Completer<void>();
      when(testHelper.mockPnpIspSettingsNotifier.saveAndVerifySettings(any))
          .thenAnswer((_) => completer.future);

      final context = await testHelper.pumpView(
        tester,
        child: const PnpIspTypeSelectionView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: localizedScreen.locale,
        overrides: [],
      );
      await tester.pumpAndSettle();

      // Tap DHCP card to open alert
      final dhcpCardFinder =
          find.widgetWithText(ISPTypeCard, testHelper.loc(context).dhcpDefault);
      await tester.tap(dhcpCardFinder);
      await tester.pumpAndSettle();

      // Tap OK on alert to trigger save
      await tester.tap(find.text(testHelper.loc(context).ok));
      await tester.pump(); // Show spinner

      expect(find.byType(AppFullScreenLoader), findsOneWidget);

      // Complete with ServiceSideEffectError with JNAPSuccess
      completer.completeError(const ServiceSideEffectError(
          JNAPSuccess(output: {}, result: 'success'),
          JNAPSuccess(output: {}, result: 'success')));
      await tester.pumpAndSettle(); // Hide spinner, show error dialog

      expect(find.byType(AppFullScreenLoader), findsNothing);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(testHelper.loc(context).error), findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpErrorForStaticIpAndDhcp),
          findsOneWidget);
      verify(testHelper.mockPnpIspSettingsNotifier.saveAndVerifySettings(any))
          .called(1);
    },
    helper: testHelper,
    screens: screens,
    goldenFilename:
        'PNP-ISP-SEL_DHCP-SAVE-ERROR-SIDE-EFFECT-SUCCESS_01_error_dialog',
  );

  // Test ID: PNP-ISP-SEL_DHCP-SAVE-ERROR-SIDE-EFFECT-OTHER
  testThemeLocalizations(
    'Verify ServiceSideEffectError without JNAPSuccess during DHCP save',
    (tester, localizedScreen) async {
      final mockInternetSettingsState2 =
          InternetSettingsState.fromMap(jsonDecode(internetSettingsStateData2));
      when(testHelper.mockInternetSettingsNotifier.fetch(forceRemote: true))
          .thenAnswer((_) async => mockInternetSettingsState2);
      when(testHelper.mockInternetSettingsNotifier.build())
          .thenReturn(mockInternetSettingsState2);

      final completer = Completer<void>();
      when(testHelper.mockPnpIspSettingsNotifier.saveAndVerifySettings(any))
          .thenAnswer((_) => completer.future);

      final context = await testHelper.pumpView(
        tester,
        child: const PnpIspTypeSelectionView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: localizedScreen.locale,
        overrides: [],
      );
      await tester.pumpAndSettle();

      // Tap DHCP card to open alert
      final dhcpCardFinder =
          find.widgetWithText(ISPTypeCard, testHelper.loc(context).dhcpDefault);
      await tester.tap(dhcpCardFinder);
      await tester.pumpAndSettle();

      // Tap OK on alert to trigger save
      await tester.tap(find.text(testHelper.loc(context).ok));
      await tester.pump(); // Show spinner

      expect(find.byType(AppFullScreenLoader), findsOneWidget);

      // Complete with ServiceSideEffectError without JNAPSuccess
      completer.completeError(const ServiceSideEffectError(
          JNAPSuccess(output: {}, result: 'success'), null));
      await tester.pumpAndSettle(); // Hide spinner, trigger navigation

      expect(find.byType(AppFullScreenLoader), findsNothing);
      verify(testHelper.mockPnpIspSettingsNotifier.saveAndVerifySettings(any))
          .called(1);
    },
    helper: testHelper,
    screens: screens,
    goldenFilename:
        'PNP-ISP-SEL_DHCP-SAVE-ERROR-SIDE-EFFECT-OTHER_01_router_not_found_alert',
  );
}
