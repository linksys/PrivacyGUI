import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/styled/top_bar.dart';
import 'package:privacy_gui/page/dashboard/views/dashboard_shell.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../common/config.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';

final mockDashboardRoute = ShellRoute(
  navigatorKey: shellNavigatorKey,
  builder: (BuildContext context, GoRouterState state, Widget child) =>
      DashboardShell(child: child),
  routes: [
    LinksysRoute(
      name: RouteNamed.dashboardMenu,
      path: RoutePath.dashboardMenu,
      builder: (context, state) =>
          const StyledAppPageView(child: Center(child: AppText.bodyLarge('Menu View'))),
    ),
    LinksysRoute(
      name: RouteNamed.dashboardHome,
      path: RoutePath.dashboardHome,
      builder: (context, state) =>
          StyledAppPageView(child: const Center(child: AppText.bodyLarge('Home View'))),
    ),
    LinksysRoute(
      name: RouteNamed.dashboardSupport,
      path: RoutePath.dashboardSupport,
      builder: (context, state) =>
          StyledAppPageView(child: const Center(child: AppText.bodyLarge('Support View'))),
    ),
  ],
);
void main() async {

  testResponsiveWidgets('Test Dashboard Navigations', (tester) async {
    await tester.pumpWidget(
      testableRouter(
        router: GoRouter(
            routes: [mockDashboardRoute],
            initialLocation: RoutePath.dashboardHome),
      ),
    );
    await tester.pumpAndSettle();

    // default view should be home view, verify home content
    final homeContentFinder = find.text('Home View');
    expect(homeContentFinder, findsOneWidget);
    // find menu tab and tap it.
    final menuTabFinder = find.byIcon(LinksysIcons.menu);
    expect(menuTabFinder, findsOneWidget);
    await tester.tap(menuTabFinder);
    await tester.pumpAndSettle();
    // verify menu content
    final menuContentFinder = find.text('Menu View');
    expect(menuContentFinder, findsOneWidget);
    // find support tab and tap it.
    final supportTabFinder = find.byIcon(LinksysIcons.help);
    expect(supportTabFinder, findsOneWidget);
    await tester.tap(supportTabFinder);
    await tester.pumpAndSettle();
    // verify home content
    final supportContentFinder = find.text('Support View');
    expect(supportContentFinder, findsOneWidget);
    // find home tab and tap it.
    final homeTabFinder = find.byIcon(LinksysIcons.home);
    expect(homeTabFinder, findsOneWidget);
    await tester.tap(homeTabFinder);
    await tester.pumpAndSettle();
    // verify home content again
    expect(homeTabFinder, findsOneWidget);
  });

  testResponsiveWidgets(
      'Test Dashboard Navigation should display on the top bar on desktop variants',
      (tester) async {
    await tester.pumpWidget(
      testableRouter(
        router: GoRouter(
            routes: [mockDashboardRoute],
            initialLocation: RoutePath.dashboardHome),
      ),
    );
    await tester.pumpAndSettle();

    final menuHomeFinder = find.descendant(
        of: find.byType(TopBar), matching: find.byIcon(LinksysIcons.home));
    expect(menuHomeFinder, findsNWidgets(1));
  }, variants: responsiveDesktopVariants);

  testResponsiveWidgets(
      'Test Dashboard Navigation should not display on the top bar on mobile variants',
      (tester) async {
    await tester.pumpWidget(
      testableRouter(
        router: GoRouter(
            routes: [mockDashboardRoute],
            initialLocation: RoutePath.dashboardHome),
      ),
    );
    await tester.pumpAndSettle();

    final menuHomeFinder = find.descendant(
        of: find.byType(TopBar), matching: find.byIcon(LinksysIcons.home));
    expect(menuHomeFinder, findsNothing);
  }, variants: responsiveMobileVariants);
}
