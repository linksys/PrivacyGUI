import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_state.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';

import '../../../common/config.dart';
import '../../../common/test_helper.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../test_data/dashboard_home_test_state.dart';
import '../../../test_data/instant_privacy_test_state.dart';
import '../../../test_data/safe_browsing_test_state.dart';

void main() async {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();

    
    initBetterActions();
  });
  testLocalizations('Dashboard Menu View - default', (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const DashboardMenuView(),
      locale: locale,
    );
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1440)).toList(),
    ...responsiveDesktopScreens
  ]);
  testLocalizations('Dashboard Menu View - show bottom sheet',
      (tester, locale) async {
    await testHelper.pumpShellView(
      tester,
      child: const DashboardMenuView(),
      locale: locale,
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
    await testHelper.pumpShellView(
      tester,
      child: const DashboardMenuView(),
      locale: locale,
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
    await testHelper.pumpShellView(
      tester,
      child: const DashboardMenuView(),
      locale: locale,
    );
    final restartFinder = find.byIcon(LinksysIcons.restartAlt).last;
    await tester.tap(restartFinder);
    await tester.pumpAndSettle();
  }, screens: responsiveDesktopScreens);

  testLocalizations('Dashboard Menu View - Instant-Safety status on',
      (tester, locale) async {
    when(testHelper.mockInstantSafetyNotifier.build())
        .thenReturn(InstantSafetyState.fromMap(instantSafetyTestState1));
    await testHelper.pumpShellView(
      tester,
      child: const DashboardMenuView(),
      locale: locale,
    );
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1440)).toList(),
    ...responsiveDesktopScreens
  ]);

  testLocalizations('Dashboard Menu View - Instant-Privacy status on',
      (tester, locale) async {
    when(testHelper.mockInstantPrivacyNotifier.build()).thenReturn(
        InstantPrivacyState.fromMap(instantPrivacyEnabledTestState));
    await testHelper.pumpShellView(
      tester,
      child: const DashboardMenuView(),
      locale: locale,
    );
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1440)).toList(),
    ...responsiveDesktopScreens
  ]);

  testLocalizations('Dashboard Menu View - Bridge mode',
      (tester, locale) async {
    when(testHelper.mockDashboardHomeNotifier.build()).thenReturn(
        DashboardHomeState.fromMap(dashboardHomeCherry7TestState)
            .copyWith(wanType: () => 'Bridge'));
    await testHelper.pumpShellView(
      tester,
      child: const DashboardMenuView(),
      locale: locale,
    );
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1440)).toList(),
    ...responsiveDesktopScreens
  ]);

  testLocalizations('Dashboard Menu View - Supports internal speedtest',
      (tester, locale) async {
    
    await testHelper.pumpShellView(
      tester,
      child: const DashboardMenuView(),
      locale: locale,
    );
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1440)).toList(),
    ...responsiveDesktopScreens
  ]);

  testLocalizations('Dashboard Menu View - Supports VPN',
      (tester, locale) async {
    when(testHelper.mockServiceHelper.isSupportVPN()).thenReturn(true);
   
    await testHelper.pumpShellView(
      tester,
      child: const DashboardMenuView(),
      locale: locale,
    );
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1440)).toList(),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
  ]);
}