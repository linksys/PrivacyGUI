import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_provider.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_state.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/_index.dart';
import '../../../mocks/connectivity_notifier_mocks.dart';
import '../../../test_data/_index.dart';

void main() async {
  late InstantPrivacyNotifier mockInstantPrivacyNotifier;
  late InstantSafetyNotifier mockInstantSafetyNotifier;
  late ConnectivityNotifier mockConnectivityNotifier;
  late DashboardHomeNotifier mockDashboardHomeNotifier;

  mockDependencyRegister();
  ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  Widget testableWidget(Locale locale) => testableRouteShellWidget(
        child: const DashboardMenuView(),
        locale: locale,
        overrides: [
          instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
          instantSafetyProvider.overrideWith(() => mockInstantSafetyNotifier),
          connectivityProvider.overrideWith(() => mockConnectivityNotifier),
          dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
        ],
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockInstantPrivacyNotifier = MockInstantPrivacyNotifier();
    mockInstantSafetyNotifier = MockInstantSafetyNotifier();
    mockConnectivityNotifier = MockConnectivityNotifier();
    mockDashboardHomeNotifier = MockDashboardHomeNotifier();

    when(mockInstantSafetyNotifier.build())
        .thenReturn(InstantSafetyState.fromMap(instantSafetyTestState));
    when(mockInstantPrivacyNotifier.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyTestState));
    when(mockConnectivityNotifier.build()).thenReturn(ConnectivityState(
        hasInternet: true,
        connectivityInfo:
            ConnectivityInfo(routerType: RouterType.behindManaged)));
    when(mockDashboardHomeNotifier.build())
        .thenReturn(DashboardHomeState.fromMap(dashboardHomeCherry7TestState));
    initBetterActions();
  });
  testLocalizations('Dashboard Menu View - default', (tester, locale) async {
    await tester.pumpWidget(
      testableWidget(locale),
    );
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1440)).toList(),
    ...responsiveDesktopScreens
  ]);
  testLocalizations('Dashboard Menu View - show bottom sheet',
      (tester, locale) async {
    await tester.pumpWidget(
      testableWidget(locale),
    );
    final moreFinder = find.byIcon(LinksysIcons.moreHoriz).last;
    await tester.tap(moreFinder);
    await tester.pumpAndSettle();
  },
      screens: responsiveMobileScreens
          .map((e) => e.copyWith(height: 1440))
          .toList());

  testLocalizations(
      'Dashboard Menu View - show restart confirm dialog on mobile varients',
      (tester, locale) async {
    await tester.pumpWidget(
      testableWidget(locale),
    );
    final moreFinder = find.byIcon(LinksysIcons.moreHoriz).last;
    await tester.tap(moreFinder);
    await tester.pumpAndSettle();
    final restartFinder = find.byIcon(LinksysIcons.restartAlt).last;
    await tester.tap(restartFinder);
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1440)).toList(),
  ]);

  testLocalizations(
      'Dashboard Menu View - show restart confirm dialog on desktop varients',
      (tester, locale) async {
    await tester.pumpWidget(
      testableWidget(locale),
    );
    final restartFinder = find.byIcon(LinksysIcons.restartAlt).last;
    await tester.tap(restartFinder);
    await tester.pumpAndSettle();
  }, screens: responsiveDesktopScreens);

  testLocalizations('Dashboard Menu View - Instant-Safety status on',
      (tester, locale) async {
    when(mockInstantSafetyNotifier.build())
        .thenReturn(InstantSafetyState.fromMap(instantSafetyTestState1));
    await tester.pumpWidget(
      testableWidget(locale),
    );
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1440)).toList(),
    ...responsiveDesktopScreens
  ]);

  testLocalizations('Dashboard Menu View - Instant-Privacy status on',
      (tester, locale) async {
    when(mockInstantPrivacyNotifier.build()).thenReturn(
        InstantPrivacyState.fromMap(instantPrivacyEnabledTestState));
    await tester.pumpWidget(
      testableWidget(locale),
    );
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1440)).toList(),
    ...responsiveDesktopScreens
  ]);

  testLocalizations('Dashboard Menu View - Bridge mode',
      (tester, locale) async {
    when(mockDashboardHomeNotifier.build()).thenReturn(
        DashboardHomeState.fromMap(dashboardHomeCherry7TestState)
            .copyWith(wanType: () => 'Bridge'));
    await tester.pumpWidget(
      testableWidget(locale),
    );
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1440)).toList(),
    ...responsiveDesktopScreens
  ]);

  testLocalizations('Dashboard Menu View - Supports internal speedtest',
      (tester, locale) async {
    when(mockDashboardHomeNotifier.build()).thenReturn(
        DashboardHomeState.fromMap(dashboardHomeCherry7TestState)
            .copyWith(isHealthCheckSupported: true));
    await tester.pumpWidget(
      testableWidget(locale),
    );
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1440)).toList(),
    ...responsiveDesktopScreens
  ]);

  testLocalizations('Dashboard Menu View - Supports VPN',
      (tester, locale) async {
    when(mockServiceHelper.isSupportVPN()).thenReturn(true);
    when(mockDashboardHomeNotifier.build()).thenReturn(
        DashboardHomeState.fromMap(dashboardHomePinnacleTestState)
            .copyWith(isHealthCheckSupported: true));
    await tester.pumpWidget(
      testableWidget(locale),
    );
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1440)).toList(),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
  ]);
}
