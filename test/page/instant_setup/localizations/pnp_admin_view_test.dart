import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_ui_models.dart';
import 'package:privacy_gui/page/instant_setup/pnp_admin_view.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_state.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/custom_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/progress_bar/spinner.dart';

import '../../../common/config.dart';
import '../../../common/test_helper.dart';
import '../../../common/test_responsive_widget.dart';

/// View ID: PNPA
/// Implementation file under test: lib/page/instant_setup/pnp_admin_view.dart
///
/// This file contains screenshot tests for the `PnpAdminView` widget,
/// covering various `PnpFlowStatus` states and user interactions.
///
/// **Covered Test Scenarios:**
///
/// - **`PNPA-INIT`**: Verifies loading spinner and "Initializing Admin" message on startup.
///   - `PNPA-INIT_01_initial_state`: Initial loading screen displayed.
/// - **`PNPA-NETCHK`**: Verifies "Checking Internet Connection" message while network is being checked.
///   - `PNPA-NETCHK_01_checking_internet_screen`: Checking internet connection screen displayed.
/// - **`PNPA-NETOK`**: Verifies "Internet Connected" message and continue button when online.
///   - `PNPA-NETOK_01_internet_connected_screen`: Internet connected screen displayed.
/// - **`PNPA-UNCONF`**: Verifies unconfigured router view with "Start Setup" button.
///   - `PNPA-UNCONF_01_unconfigured_router_screen`: Unconfigured router screen displayed.
/// - **`PNPA-PASSWD`**: Verifies admin password prompt with login and "Where is it?" buttons.
///   - `PNPA-PASSWD_01_password_prompt_screen`: Password prompt screen displayed.
/// - **`PNPA-PASSWD_LOGGING_IN`**: Verifies login button is disabled and processing state is shown when logging in.
///   - `PNPA-PASSWD_LOGGING_IN_01_logging_in_screen`: Logging in screen displayed.
/// - **`PNPA-PASSWD_LOGIN_FAILED`**: Verifies "Incorrect Password" error message after a failed login attempt.
///   - `PNPA-PASSWD_LOGIN_FAILED_01_failed_login_screen`: Failed login screen displayed.
/// - **`PNPA-ERROR`**: Verifies generic error page with a "Try Again" button.
///   - `PNPA-ERROR_01_generic_error_screen`: Generic error screen displayed.
/// - **`PNPA-PASSWD_MODAL`**: Verifies "Where is it?" modal appears when button is tapped on password screen.
///   - `PNPA-PASSWD_MODAL_01_where_is_it_modal`: "Where is it?" modal dialog displayed.
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
    // Mock the entry point of the PnP flow to prevent real logic execution
    // during these isolated view tests.
    when(testHelper.mockPnpNotifier.startPnpFlow(any)).thenAnswer((_) async {});
  });

  group('PnpAdminView screenshot tests based on PnpFlowStatus', () {
    // Test ID: PNPA-INIT
    testLocalizations(
        'Verify loading spinner and "Initializing Admin" message on startup',
        (tester, locale) async {
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
        locale: locale,
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AppSpinner), findsOneWidget);
      expect(find.text(testHelper.loc(context).processing), findsOneWidget);
    }, screens: screens, goldenFilename: 'PNPA-INIT_01_initial_state');

    // Test ID: PNPA-NETCHK
    testLocalizations(
        'Verify "Checking Internet Connection" message while network is being checked',
        (tester, locale) async {
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
        locale: locale,
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AppSpinner), findsOneWidget);
      expect(find.text(testHelper.loc(context).launchCheckInternet),
          findsOneWidget);
    },
        screens: screens,
        goldenFilename: 'PNPA-NETCHK_01_checking_internet_screen');

    // Test ID: PNPA-NETOK
    testLocalizations(
        'Verify "Internet Connected" message and continue button when online',
        (tester, locale) async {
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
        locale: locale,
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(LinksysIcons.globe), findsOneWidget);
      expect(find.text(testHelper.loc(context).launchInternetConnected),
          findsOneWidget);
    },
        screens: screens,
        goldenFilename: 'PNPA-NETOK_01_internet_connected_screen');

    // Test ID: PNPA-UNCONF
    testLocalizations(
        'Verify unconfigured router view with "Start Setup" button',
        (tester, locale) async {
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
        locale: locale,
        preCacheCustomImages: [deviceInfo.image],
      );

      // expect image display matched
      expect(find.image(CustomTheme.of(context).images.devices_xl.routerLn12),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpFactoryResetTitle),
          findsOneWidget);
      expect(
          find.text(testHelper.loc(context).factoryResetDesc), findsOneWidget);
      expect(
          find.widgetWithText(
              AppFilledButton, testHelper.loc(context).textContinue),
          findsOneWidget);
    },
        screens: screens,
        goldenFilename: 'PNPA-UNCONF_01_unconfigured_router_screen');

    // Test ID: PNPA-PASSWD
    testLocalizations(
        'Verify admin password prompt with login and "Where is it?" buttons',
        (tester, locale) async {
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
        locale: locale,
        preCacheCustomImages: [deviceInfo.image],
      );

      // expect image display matched
      expect(find.image(CustomTheme.of(context).images.devices_xl.routerLn12),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).welcome), findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpRouterLoginDesc),
          findsOneWidget);
      expect(
          find.byKey(const Key('admin_password_input_field')), findsOneWidget);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is AppPasswordField &&
              widget.hintText == testHelper.loc(context).routerPassword),
          findsOneWidget);
      expect(
          find.widgetWithText(AppFilledButton, testHelper.loc(context).login),
          findsOneWidget);
      expect(
          find.widgetWithText(
              AppTextButton, testHelper.loc(context).pnpRouterLoginWhereIsIt),
          findsOneWidget);
    },
        screens: screens,
        goldenFilename: 'PNPA-PASSWD_01_password_prompt_screen');

    // Test ID: PNPA-PASSWD_LOGGING_IN
    testLocalizations(
        'Verify login button is disabled and processing state is shown when logging in',
        (tester, locale) async {
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
        locale: locale,
        preCacheCustomImages: [deviceInfo.image],
      );
      // expect image display matched
      expect(find.image(CustomTheme.of(context).images.devices_xl.routerLn12),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).welcome), findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpRouterLoginDesc),
          findsOneWidget);
      expect(
          find.byKey(const Key('admin_password_input_field')), findsOneWidget);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is AppPasswordField &&
              widget.hintText == testHelper.loc(context).routerPassword),
          findsOneWidget);
      expect(
          find.widgetWithText(
              AppTextButton, testHelper.loc(context).pnpRouterLoginWhereIsIt),
          findsOneWidget);
      // next button should be disabled
      expect(
          find.widgetWithText(AppFilledButton, testHelper.loc(context).login),
          findsOneWidget);
      final widget = tester.widget(find.byType(AppFilledButton));
      expect(widget, isA<AppFilledButton>());
      expect((widget as AppFilledButton).onTap, null);
    },
        screens: screens,
        goldenFilename: 'PNPA-PASSWD_LOGGING_IN_01_logging_in_screen');

    // Test ID: PNPA-PASSWD_LOGIN_FAILED
    testLocalizations(
        'Verify "Incorrect Password" error message after a failed login attempt',
        (tester, locale) async {
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
        locale: locale,
        preCacheCustomImages: [deviceInfo.image],
      );

      // expect image display matched
      expect(find.image(CustomTheme.of(context).images.devices_xl.routerLn12),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).welcome), findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpRouterLoginDesc),
          findsOneWidget);
      expect(
          find.byKey(const Key('admin_password_input_field')), findsOneWidget);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is AppPasswordField &&
              widget.hintText == testHelper.loc(context).routerPassword),
          findsOneWidget);
      expect(
          find.widgetWithText(
              AppTextButton, testHelper.loc(context).pnpRouterLoginWhereIsIt),
          findsOneWidget);
      expect(
          find.widgetWithText(AppFilledButton, testHelper.loc(context).login),
          findsOneWidget);
      expect(
          find.text(testHelper.loc(context).incorrectPassword), findsOneWidget);
    },
        screens: screens,
        goldenFilename: 'PNPA-PASSWD_LOGIN_FAILED_01_failed_login_screen');

    // Test ID: PNPA-ERROR
    testLocalizations('Verify generic error page with a "Try Again" button',
        (tester, locale) async {
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
        locale: locale,
        preCacheCustomImages: [deviceInfo.image],
      );
      await tester.pumpAndSettle();

      expect(find.text(testHelper.loc(context).generalError), findsOneWidget);

      expect(
          find.widgetWithText(
              AppFilledButton, testHelper.loc(context).tryAgain),
          findsOneWidget);
    }, screens: screens, goldenFilename: 'PNPA-ERROR_01_generic_error_screen');

    // Test ID: PNPA-PASSWD_MODAL
    testLocalizations(
        'Verify "Where is it?" modal appears when button is tapped on password screen',
        (tester, locale) async {
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
        locale: locale,
        preCacheCustomImages: [deviceInfo.image],
      );

      expect(find.image(CustomTheme.of(context).images.devices_xl.routerLn12),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).welcome), findsOneWidget);
      expect(find.text(testHelper.loc(context).pnpRouterLoginDesc),
          findsOneWidget);
      expect(
          find.byKey(const Key('admin_password_input_field')), findsOneWidget);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is AppPasswordField &&
              widget.hintText == testHelper.loc(context).routerPassword),
          findsOneWidget);
      expect(
          find.widgetWithText(AppFilledButton, testHelper.loc(context).login),
          findsOneWidget);
      final btnFinder = find.widgetWithText(
          AppTextButton, testHelper.loc(context).pnpRouterLoginWhereIsIt);
      expect(btnFinder, findsOneWidget);

      await tester.tap(btnFinder);
      await tester.pumpAndSettle();

      // Verify that the AlertDialog is displayed after tapping the button
      expect(find.byType(AlertDialog), findsOneWidget);
      // Find the title text specifically within the AlertDialog to avoid ambiguity
      expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text(testHelper.loc(context).routerPassword),
          ),
          findsOneWidget);
      expect(find.text(testHelper.loc(context).modalRouterPasswordLocation),
          findsOneWidget);
      expect(find.widgetWithText(AppTextButton, testHelper.loc(context).close),
          findsOneWidget);
    },
        screens: screens,
        goldenFilename: 'PNPA-PASSWD_MODAL_01_where_is_it_modal');
  });
}
