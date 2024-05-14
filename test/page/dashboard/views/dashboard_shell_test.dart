import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg_test/flutter_svg_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/dashboard/views/dashboard_shell.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/custom_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../common/config.dart';
import '../../../common/mock_firebase_messaging.dart';
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
          const Center(child: AppText.bodyLarge('Menu View')),
    ),
    LinksysRoute(
      name: RouteNamed.dashboardHome,
      path: RoutePath.dashboardHome,
      builder: (context, state) =>
          const Center(child: AppText.bodyLarge('Home View')),
    ),
    LinksysRoute(
      name: RouteNamed.dashboardSupport,
      path: RoutePath.dashboardSupport,
      builder: (context, state) =>
          const Center(child: AppText.bodyLarge('Support View')),
    ),
  ],
);
void main() async {
  setupFirebaseMessagingMocks();
  // FirebaseMessaging? messaging;
  await Firebase.initializeApp();
  // FirebaseMessagingPlatform.instance = kMockMessagingPlatform;
  // messaging = FirebaseMessaging.instance;

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
      'Test Dashboard Navigation Rail should display on desktop variants',
      (tester) async {
    await tester.pumpWidget(
      testableRouter(
        router: GoRouter(
            routes: [mockDashboardRoute],
            initialLocation: RoutePath.dashboardHome),
      ),
    );
    await tester.pumpAndSettle();

    // Find Build Context
    final BuildContext context = tester.element(find.byType(DashboardShell));
    final asset = CustomTheme.of(context).images.linksysLogoBlack;
    final logoFinder = find.descendant(
        of: find.byType(NavigationRail), matching: find.svg(asset));
    expect(logoFinder, findsNWidgets(1));
  }, variants: responsiveDesktopVariants);

  testResponsiveWidgets(
      'Test Dashboard Navigation Rail should not display on mobile variants',
      (tester) async {
    await tester.pumpWidget(
      testableRouter(
        router: GoRouter(
            routes: [mockDashboardRoute],
            initialLocation: RoutePath.dashboardHome),
      ),
    );
    await tester.pumpAndSettle();

    // Find Build Context
    final BuildContext context = tester.element(find.byType(DashboardShell));
    final asset = CustomTheme.of(context).images.linksysLogoBlack;
    final logoFinder = find.descendant(
        of: find.byType(NavigationRail), matching: find.svg(asset));
    expect(logoFinder, findsNothing);
  }, variants: responsiveMobileVariants);
}
