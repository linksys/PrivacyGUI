import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';

import '../../../common/config.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';

void main() async {

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
    final moreFinder = find.byIcon(LinksysIcons.moreHoriz).last;
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
    final moreFinder = find.byIcon(LinksysIcons.moreHoriz).last;
    await tester.tap(moreFinder);
    await tester.pumpAndSettle();
    final restartFinder = find.byIcon(LinksysIcons.restartAlt).last;
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
    final restartFinder = find.byIcon(LinksysIcons.restartAlt).last;
    await tester.tap(restartFinder);
    await tester.pumpAndSettle();
  }, screens: responsiveDesktopScreens);
}
