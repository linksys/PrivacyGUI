import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_state.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_state.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_info.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_state.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/label/status_label.dart';
import '../../../common/_index.dart';
import '../../../common/test_helper.dart';
import '../../../test_data/dashboard_home_test_state.dart';
import '../../../test_data/instant_privacy_test_state.dart';
import '../../../test_data/safe_browsing_test_state.dart';

// View ID: DMENU
// Implementation: lib/page/dashboard/views/dashboard_menu_view.dart
// Summary:
// - DMENU-BASE: Default grid renders all core cards.
// - DMENU-MOBILE_MENU: Mobile overflow menu shows restart option.
// - DMENU-MOBILE_RESTART / DMENU-DESKTOP_RESTART: Confirm dialog appears from restart action.
// - DMENU-SAFETY / DMENU-PRIVACY: Instant safety/privacy cards show status & beta label.
// - DMENU-BRIDGE: Bridge mode disables safety card.
// - DMENU-SPEED_INTERNAL / DMENU-SPEED_EXTERNAL: Speed test cards appear when supported.
// - DMENU-VPN: VPN card appears when service helper allows it.

final _menuMobileScreens = responsiveMobileScreens
    .map((screen) => screen.copyWith(name: '${screen.name}-Tall', height: 1440))
    .toList();
final _menuDesktopScreens = responsiveDesktopScreens
    .map((screen) => screen.copyWith(name: '${screen.name}-Tall', height: 900))
    .toList();

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
    initBetterActions();
  });

  Future<BuildContext> pumpMenu(
    WidgetTester tester,
    LocalizedScreen screen, {
    List<Override> overrides = const [],
  }) async {
    final context = await testHelper.pumpShellView(
      tester,
      child: const DashboardMenuView(),
      locale: screen.locale,
      overrides: overrides,
    );
    await tester.pumpAndSettle();
    return context;
  }

  Future<void> openMoreMenu(WidgetTester tester) async {
    final moreFinder = find.byIcon(LinksysIcons.moreHoriz).last;
    await tester.tap(moreFinder);
    await tester.pumpAndSettle();
  }

  // Test ID: DMENU-BASE
  testLocalizationsV2(
    'dashboard menu view - default layout',
    (tester, screen) async {
      final context = await pumpMenu(tester, screen);
      final loc = testHelper.loc(context);
      // Inspect the menu options that will always be present
      expect(find.text(loc.menu), findsWidgets);
      expect(find.text(loc.incredibleWiFi), findsOneWidget);
      expect(find.text(loc.instantAdmin), findsOneWidget);
      expect(find.text(loc.instantTopology), findsOneWidget);
      expect(find.text(loc.instantSafety), findsOneWidget);
      expect(find.text(loc.instantPrivacy), findsOneWidget);
      expect(find.text(loc.instantDevices), findsOneWidget);
      expect(find.text(loc.advancedSettings), findsOneWidget);
      expect(find.text(loc.instantVerify), findsOneWidget);
    },
    screens: [..._menuMobileScreens, ..._menuDesktopScreens],
    goldenFilename: 'DMENU-BASE_01_layout',
    helper: testHelper,
  );

  // Test ID: DMENU-MOBILE_MENU
  testLocalizationsV2(
    'dashboard menu view - mobile open sheet',
    (tester, screen) async {
      final context = await pumpMenu(tester, screen);
      final loc = testHelper.loc(context);
      await openMoreMenu(tester);
      expect(find.text(loc.restartNetwork), findsOneWidget);
      expect(find.text(loc.menuSetupANewProduct), findsOneWidget);
    },
    screens: _menuMobileScreens,
    goldenFilename: 'DMENU-MOBILE_MENU_01_sheet',
    helper: testHelper,
  );

  // Test ID: DMENU-MOBILE_RESTART
  testLocalizationsV2(
    'dashboard menu view - restart dialog via mobile',
    (tester, screen) async {
      final context = await pumpMenu(tester, screen);
      final loc = testHelper.loc(context);
      await openMoreMenu(tester);
      await tester.tap(find.byIcon(LinksysIcons.restartAlt).last);
      await tester.pumpAndSettle();
      expect(find.text(loc.alertExclamation), findsOneWidget);
      expect(find.text(loc.menuRestartNetworkMessage), findsOneWidget);
    },
    screens: _menuMobileScreens,
    goldenFilename: 'DMENU-MOBILE_RESTART_01_dialog',
    helper: testHelper,
  );

  // Test ID: DMENU-DESKTOP_RESTART
  testLocalizationsV2(
    'dashboard menu view - restart dialog via desktop',
    (tester, screen) async {
      final context = await pumpMenu(tester, screen);
      final loc = testHelper.loc(context);
      await tester.tap(find.byIcon(LinksysIcons.restartAlt).last);
      await tester.pumpAndSettle();
      expect(find.text(loc.alertExclamation), findsOneWidget);
      expect(find.text(loc.menuRestartNetworkMessage), findsOneWidget);
    },
    screens: _menuDesktopScreens,
    goldenFilename: 'DMENU-DESKTOP_RESTART_01_dialog',
    helper: testHelper,
  );

  // Test ID: DMENU-SAFETY
  testLocalizationsV2(
    'dashboard menu view - instant safety status indicator',
    (tester, screen) async {
      when(testHelper.mockInstantSafetyNotifier.build()).thenReturn(
        InstantSafetyState.fromMap(instantSafetyTestState1),
      );
      final context = await pumpMenu(tester, screen);
      final loc = testHelper.loc(context);
      final statusFinder = find.descendant(
        of: find.ancestor(
          of: find.text(loc.instantSafety),
          matching: find.byType(AppMenuCard),
        ),
        matching: find.byType(AppStatusLabel),
      );
      expect(statusFinder, findsOneWidget);
    },
    screens: [..._menuMobileScreens, ..._menuDesktopScreens],
    goldenFilename: 'DMENU-SAFETY_01_status',
    helper: testHelper,
  );

  // Test ID: DMENU-PRIVACY
  testLocalizationsV2(
    'dashboard menu view - instant privacy beta label',
    (tester, screen) async {
      when(testHelper.mockInstantPrivacyNotifier.build()).thenReturn(
        InstantPrivacyState.fromMap(instantPrivacyEnabledTestState),
      );
      final context = await pumpMenu(tester, screen);
      final loc = testHelper.loc(context);
      expect(find.text(loc.instantPrivacy), findsOneWidget);
      expect(find.text('BETA'), findsWidgets);
    },
    screens: [..._menuMobileScreens, ..._menuDesktopScreens],
    goldenFilename: 'DMENU-PRIVACY_01_beta',
    helper: testHelper,
  );

  // Test ID: DMENU-BRIDGE
  testLocalizationsV2(
    'dashboard menu view - bridge mode disables safety',
    (tester, screen) async {
      when(testHelper.mockDashboardHomeNotifier.build()).thenReturn(
        DashboardHomeState.fromMap(dashboardHomeCherry7TestState)
            .copyWith(wanType: () => 'Bridge'),
      );

      final context = await pumpMenu(tester, screen);
      final loc = testHelper.loc(context);
      final opacityFinder = find.ancestor(
        of: find.text(loc.instantSafety),
        matching: find.byType(Opacity),
      );
      expect(opacityFinder, findsWidgets);
      final opacityWidget = tester.widget<Opacity>(opacityFinder.first);
      expect(opacityWidget.opacity, equals(0.3));
    },
    screens: [..._menuMobileScreens, ..._menuDesktopScreens],
    goldenFilename: 'DMENU-BRIDGE_01_disabled',
    helper: testHelper,
  );

  // Test ID: DMENU-SPEED_INTERNAL
  testLocalizationsV2(
    'dashboard menu view - internal speed test card',
    (tester, screen) async {
      when(testHelper.mockHealthCheckProvider.build()).thenReturn(
        const HealthCheckState(healthCheckModules: ['SpeedTest']),
      );
      final context = await pumpMenu(tester, screen);
      final loc = testHelper.loc(context);
      expect(find.text(loc.speedTest), findsOneWidget);
    },
    screens: [..._menuMobileScreens, ..._menuDesktopScreens],
    goldenFilename: 'DMENU-SPEED_INTERNAL_01_card',
    helper: testHelper,
  );

  // Test ID: DMENU-SPEED_EXTERNAL
  testLocalizationsV2(
    'dashboard menu view - external speed test card',
    (tester, screen) async {
      when(testHelper.mockHealthCheckProvider.build()).thenReturn(
        const HealthCheckState(),
      );
      when(testHelper.mockConnectivityNotifier.build()).thenReturn(
        const ConnectivityState(
          hasInternet: true,
          connectivityInfo: ConnectivityInfo(
            type: ConnectivityResult.wifi,
            routerType: RouterType.behindManaged,
          ),
        ),
      );
      final context = await pumpMenu(tester, screen);
      final loc = testHelper.loc(context);
      expect(find.text(loc.externalSpeedText), findsOneWidget);
    },
    screens: [..._menuMobileScreens, ..._menuDesktopScreens],
    goldenFilename: 'DMENU-SPEED_EXTERNAL_01_card',
    helper: testHelper,
  );

  // Test ID: DMENU-VPN
  testLocalizationsV2(
    'dashboard menu view - vpn card shown when supported',
    (tester, screen) async {
      when(testHelper.mockServiceHelper.isSupportVPN()).thenReturn(true);
      final context = await pumpMenu(tester, screen);
      final loc = testHelper.loc(context);
      await scrollUntil(tester, find.text(loc.vpn));
      expect(find.text(loc.vpn), findsOneWidget);
    },
    screens: [..._menuMobileScreens, ..._menuDesktopScreens],
    goldenFilename: 'DMENU-VPN_01_card',
    helper: testHelper,
  );
}
