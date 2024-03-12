import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linksys_app/page/dashboard/_dashboard.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../common/config.dart';
import '../../../common/mock_firebase_messaging.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';

void main() async {
  setupFirebaseMessagingMocks();
  // FirebaseMessaging? messaging;
  await Firebase.initializeApp();
  // FirebaseMessagingPlatform.instance = kMockMessagingPlatform;
  // messaging = FirebaseMessaging.instance;

  testLocalizations('Dashboard Menu View', (tester, locale) async {
    await tester.pumpWidget(
      testableRouteShellWidget(
        child: const DashboardMenuView(),
        locale: locale,
      ),
    );
  });
  testLocalizations('Dashboard Menu View show bottom sheet',
      (tester, locale) async {
    await tester.pumpWidget(
      testableRouteShellWidget(
        child: const DashboardMenuView(),
        locale: locale,
      ),
    );
    final moreFinder = find.byIcon(Symbols.more_horiz).last;
    await tester.tap(moreFinder);
    await tester.pumpAndSettle();
  }, screens: responsiveMobileScreens);

  testLocalizations(
      'Dashboard Menu View show restart confirm dialog on mobile varients',
      (tester, locale) async {
    await tester.pumpWidget(
      testableRouteShellWidget(
        child: const DashboardMenuView(),
        locale: locale,
      ),
    );
    final moreFinder = find.byIcon(Symbols.more_horiz).last;
    await tester.tap(moreFinder);
    await tester.pumpAndSettle();
    final restartFinder = find.byIcon(Symbols.restart_alt).last;
    await tester.tap(restartFinder);
    await tester.pumpAndSettle();
  }, screens: responsiveMobileScreens);

  testLocalizations(
      'Dashboard Menu View show restart confirm dialog on desktop varients',
      (tester, locale) async {
    await tester.pumpWidget(
      testableRouteShellWidget(
        child: const DashboardMenuView(),
        locale: locale,
      ),
    );
    final restartFinder = find.byIcon(Symbols.restart_alt).last;
    await tester.tap(restartFinder);
    await tester.pumpAndSettle();
  }, screens: responsiveDesktopScreens);
}
