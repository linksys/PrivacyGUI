import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/styled/menus/widgets/top_navigation_menu.dart';
import 'package:privacy_gui/page/components/styled/top_bar.dart';
import 'package:privacy_gui/page/dashboard/views/dashboard_shell.dart';
import 'package:privacy_gui/page/instant_verify/prototypes/mock_pivot_notifier.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/services/browser_diagnostic_service.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';

import '../../../common/di.dart';
import '../../../common/testable_router.dart';
import 'instant_test_harness.dart';

void main() {
  mockDependencyRegister();

  // The real Instant-Test route and child routes inside the dashboard shell,
  // opened from the Menu with pushNamed like every other menu tile.
  GoRouter buildRouter() => GoRouter(
        navigatorKey: shellNavigatorKey,
        initialLocation: RoutePath.dashboardMenu,
        routes: [
          ShellRoute(
            builder: (context, state, child) => DashboardShell(child: child),
            routes: [
              LinksysRoute(
                name: RouteNamed.dashboardMenu,
                path: RoutePath.dashboardMenu,
                builder: (context, state) => Scaffold(
                    body: TextButton(
                        onPressed: () =>
                            context.pushNamed(RouteNamed.menuInstantTest),
                        child: const Text('Menu page'))),
                routes: [
                  menus.firstWhere(
                      (route) => route.name == RouteNamed.menuInstantTest),
                ],
              ),
            ],
          ),
        ],
      );

  Future<GoRouter> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = buildRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(testableRouter(router: router, overrides: [
      instantVerifyPivotProvider.overrideWith(MockInstantVerifyPivotNotifier.new),
      browserDiagnosticServiceProvider
          .overrideWithValue(MockBrowserDiagnosticService()),
    ]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Menu page'));
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final target = find.text(text).last;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('menu route is a standard page: top bar, title, back to Menu',
      (tester) async {
    final router = await open(tester);
    expect(topRoute(router), RouteNamed.menuInstantTest);
    expect(find.byType(TopBar), findsOneWidget);
    expect(find.byType(TopNavigationMenu), findsOneWidget);
    expect(find.text('Back to router home'), findsNothing);
    expect(find.text('What needs help?'), findsOneWidget);
    expect(find.text('Instant-Test'), findsOneWidget);
    await tapBack(tester);
    expect(find.text('Menu page'), findsOneWidget);
  });

  testWidgets('a flow is its own page with its own title and back',
      (tester) async {
    final router = await open(tester);
    await tapText(tester, "Internet isn't working");
    expect(topRoute(router), RouteNamed.instantTestHelp);
    expect(find.byType(TopBar), findsOneWidget);
    expect(find.text("My internet isn't working"), findsOneWidget);
    expect(find.text('What needs help?'), findsNothing);
    await tapBack(tester);
    expect(topRoute(router), RouteNamed.menuInstantTest);
    expect(find.text('What needs help?'), findsOneWidget);
  });

  testWidgets('flows are addressable child routes of Instant-Test',
      (tester) async {
    final router = await open(tester);
    await tapText(tester, "Internet isn't working");
    expect(topLocation(router).path, '/dashboardMenu/menuInstantTest/help');
    expect(topLocation(router).queryParameters['flow'], '1');

    // A direct address opens the flow over Instant-Test home.
    router.go('/dashboardMenu/menuInstantTest/help?flow=4');
    await tester.pumpAndSettle();
    expect(find.text("WiFi doesn't reach a room"), findsOneWidget);
    await tapBack(tester);
    expect(find.text('What needs help?'), findsOneWidget);

    router.go('/dashboardMenu/menuInstantTest/devices');
    await tester.pumpAndSettle();
    expect(find.text('Device details'), findsOneWidget);
    router.go('/dashboardMenu/menuInstantTest/network');
    await tester.pumpAndSettle();
    expect(find.text('Network details'), findsOneWidget);
  });
}
