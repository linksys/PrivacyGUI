import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_ui_models.dart';
import 'package:privacy_gui/page/instant_setup/pnp_admin_view.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_state.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../common/config.dart';
import '../../../common/test_helper.dart';
import '../../../common/test_responsive_widget.dart';

void main() {
  final testHelper = TestHelper();
  final screens = responsiveAllScreens;
  final deviceInfo = PnpDeviceInfoUIModel(
    modelName: 'LN16',
    image: 'routerLn12',
    serialNumber: 'serialNumber',
    firmwareVersion: 'firmwareVersion',
  );

  setUp(() {
    testHelper.setup();
    when(testHelper.mockPnpNotifier.startPnpFlow(any)).thenAnswer((_) async {});
  });

  group('PnpAdminView screenshot tests based on PnpFlowStatus', () {
    // Test ID: PNPA-INIT
    testLocalizations(
        'Verify loading spinner and "Initializing Admin" message on startup',
        (tester, screen) async {
      when(testHelper.mockPnpNotifier.build()).thenReturn(
        PnpState(
          status: PnpFlowStatus.adminInitializing,
        ),
      );

      final context = await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: screen.locale,
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AppLoader), findsOneWidget);
      expect(find.text(testHelper.loc(context).processing), findsOneWidget);
    },
        screens: screens,
        goldenFilename: 'PNPA-INIT_01-initial_state',
        helper: testHelper);

    // Test ID: PNPA-NETCHK
    testLocalizations(
        'Verify "Checking Internet Connection" message while network is being checked',
        (tester, screen) async {
      when(testHelper.mockPnpNotifier.build()).thenReturn(
        PnpState(
          status: PnpFlowStatus.adminCheckingInternet,
        ),
      );

      final context = await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: screen.locale,
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AppLoader), findsOneWidget);
      expect(find.text(testHelper.loc(context).launchCheckInternet),
          findsOneWidget);
    },
        screens: screens,
        goldenFilename: 'PNPA-NETCHK_01-checking_internet_screen',
        helper: testHelper);

    // Test ID: PNPA-NETOK
    testLocalizations(
        'Verify "Internet Connected" message and continue button when online',
        (tester, screen) async {
      when(testHelper.mockPnpNotifier.build()).thenReturn(
        PnpState(
          status: PnpFlowStatus.adminInternetConnected,
        ),
      );

      final context = await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: screen.locale,
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(AppFontIcons.globe), findsOneWidget);
      expect(find.text(testHelper.loc(context).launchInternetConnected),
          findsOneWidget);
    },
        screens: screens,
        goldenFilename: 'PNPA-NETOK_01-internet_connected_screen',
        helper: testHelper);

    // Test ID: PNPA-UNCONF
    testLocalizations(
        'Verify unconfigured router view with "Start Setup" button',
        (tester, screen) async {
      when(testHelper.mockPnpNotifier.build()).thenReturn(
        PnpState(
          status: PnpFlowStatus.adminUnconfigured,
          deviceInfo: deviceInfo,
        ),
      );

      final context = await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: screen.locale,
        preCacheCustomImages: [deviceInfo.image],
      );

      expect(find.image(Assets.images.devicesXl.routerLn12.provider()),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpFactoryResetTitle),
          findsOneWidget);
      expect(
          find.text(testHelper.loc(context).factoryResetDesc), findsOneWidget);
      expect(
          find.widgetWithText(AppButton, testHelper.loc(context).textContinue),
          findsOneWidget);
    },
        screens: screens,
        goldenFilename: 'PNPA-UNCONF_01-unconfigured_router_screen',
        helper: testHelper);

    // Test ID: PNPA-PASSWD
    testLocalizations(
        'Verify admin password prompt with login and "Where is it?" buttons',
        (tester, screen) async {
      when(testHelper.mockPnpNotifier.build()).thenReturn(
        PnpState(
          status: PnpFlowStatus.adminAwaitingPassword,
          deviceInfo: deviceInfo,
        ),
      );

      final context = await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: screen.locale,
        preCacheCustomImages: [deviceInfo.image],
      );

      expect(find.image(Assets.images.devicesXl.routerLn12.provider()),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).welcome), findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpRouterLoginDesc),
          findsOneWidget);
      expect(
          find.byKey(const Key('admin_password_input_field')), findsOneWidget);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is AppPasswordInput &&
              widget.label == testHelper.loc(context).routerPassword),
          findsOneWidget);
      expect(find.widgetWithText(AppButton, testHelper.loc(context).login),
          findsOneWidget);
      expect(
          find.widgetWithText(
              AppButton, testHelper.loc(context).pnpRouterLoginWhereIsIt),
          findsOneWidget);
    },
        screens: screens,
        goldenFilename: 'PNPA-PASSWD_01-password_prompt_screen',
        helper: testHelper);

    // Test ID: PNPA-LOGIN_IN
    testLocalizations(
        'Verify login button is disabled and processing state is shown when logging in',
        (tester, screen) async {
      when(testHelper.mockPnpNotifier.build()).thenReturn(
        PnpState(
          status: PnpFlowStatus.adminLoggingIn,
          deviceInfo: deviceInfo,
        ),
      );

      final context = await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: screen.locale,
        preCacheCustomImages: [deviceInfo.image],
      );
      expect(find.image(Assets.images.devicesXl.routerLn12.provider()),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).welcome), findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpRouterLoginDesc),
          findsOneWidget);
      expect(
          find.byKey(const Key('admin_password_input_field')), findsOneWidget);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is AppPasswordInput &&
              widget.label == testHelper.loc(context).routerPassword),
          findsOneWidget);
      expect(
          find.widgetWithText(
              AppButton, testHelper.loc(context).pnpRouterLoginWhereIsIt),
          findsOneWidget);
      expect(find.widgetWithText(AppButton, testHelper.loc(context).login),
          findsOneWidget);
      final widget = tester.widget(
          find.widgetWithText(AppButton, testHelper.loc(context).login));
      expect(widget, isA<AppButton>());
      expect((widget as AppButton).onTap, null);
    },
        screens: screens,
        goldenFilename: 'PNPA-LOGIN_IN_01-logging_in_screen',
        helper: testHelper);

    // Test ID: PNPA-LOGIN_FAIL
    testLocalizations(
        'Verify "Incorrect Password" error message after a failed login attempt',
        (tester, screen) async {
      when(testHelper.mockPnpNotifier.build()).thenReturn(
        PnpState(
          status: PnpFlowStatus.adminLoginFailed,
          deviceInfo: deviceInfo,
          error: Exception('mock error'),
        ),
      );

      final context = await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: screen.locale,
        preCacheCustomImages: [deviceInfo.image],
      );

      expect(find.image(Assets.images.devicesXl.routerLn12.provider()),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).welcome), findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpRouterLoginDesc),
          findsOneWidget);
      expect(
          find.byKey(const Key('admin_password_input_field')), findsOneWidget);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is AppPasswordInput &&
              widget.label == testHelper.loc(context).routerPassword),
          findsOneWidget);
      expect(
          find.widgetWithText(
              AppButton, testHelper.loc(context).pnpRouterLoginWhereIsIt),
          findsOneWidget);
      expect(find.widgetWithText(AppButton, testHelper.loc(context).login),
          findsOneWidget);
      expect(
          find.text(testHelper.loc(context).incorrectPassword), findsOneWidget);
    },
        screens: screens,
        goldenFilename: 'PNPA-LOGIN_FAIL_01-failed_login_screen',
        helper: testHelper);

    // Test ID: PNPA-ERROR
    testLocalizations('Verify generic error page with a "Try Again" button',
        (tester, screen) async {
      when(testHelper.mockPnpNotifier.build()).thenReturn(
        PnpState(
          status: PnpFlowStatus.adminError,
          error: Exception('mock error'),
        ),
      );

      final context = await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: screen.locale,
        preCacheCustomImages: [deviceInfo.image],
      );
      await tester.pumpAndSettle();

      expect(find.text(testHelper.loc(context).generalError), findsOneWidget);

      expect(find.widgetWithText(AppButton, testHelper.loc(context).tryAgain),
          findsOneWidget);
    },
        screens: screens,
        goldenFilename: 'PNPA-ERROR_01-generic_error_screen',
        helper: testHelper);

    // Test ID: PNPA-PASS_MOD
    testLocalizations(
        'Verify "Where is it?" modal appears when button is tapped on password screen',
        (tester, screen) async {
      when(testHelper.mockPnpNotifier.build()).thenReturn(
        PnpState(
          status: PnpFlowStatus.adminAwaitingPassword,
          deviceInfo: deviceInfo,
        ),
      );

      final context = await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        child: const PnpAdminView(),
        locale: screen.locale,
        preCacheCustomImages: [deviceInfo.image],
      );

      expect(find.image(Assets.images.devicesXl.routerLn12.provider()),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).welcome), findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpRouterLoginDesc),
          findsOneWidget);
      expect(
          find.byKey(const Key('admin_password_input_field')), findsOneWidget);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is AppPasswordInput &&
              widget.label == testHelper.loc(context).routerPassword),
          findsOneWidget);
      expect(find.widgetWithText(AppButton, testHelper.loc(context).login),
          findsOneWidget);
      final btnFinder = find.widgetWithText(
          AppButton, testHelper.loc(context).pnpRouterLoginWhereIsIt);
      expect(btnFinder, findsOneWidget);

      await tester.tap(btnFinder);
      await tester.pumpAndSettle();

      expect(find.byType(AppDialog), findsOneWidget);
      expect(
          find.descendant(
            of: find.byType(AppDialog),
            matching: find.text(testHelper.loc(context).routerPassword),
          ),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).modalRouterPasswordLocation),
          findsOneWidget);
      expect(find.widgetWithText(AppButton, testHelper.loc(context).close),
          findsOneWidget);
    },
        screens: screens,
        goldenFilename: 'PNPA-PASS_MOD_01-where_is_it_modal',
        helper: testHelper);
  });
}
