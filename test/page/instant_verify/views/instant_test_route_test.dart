import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/styled/menus/widgets/top_navigation_menu.dart';
import 'package:privacy_gui/page/components/styled/top_bar.dart';
import 'package:privacy_gui/page/dashboard/views/dashboard_shell.dart';
import 'package:privacy_gui/page/instant_verify/prototypes/mock_pivot_notifier.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/services/browser_diagnostic_service.dart';
import 'package:privacy_gui/page/instant_verify/views/instant_test_page.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';

import '../../../common/di.dart';
import '../../../common/testable_router.dart';

void main() {
  mockDependencyRegister();

  GoRouter buildRouter() => GoRouter(
        navigatorKey: shellNavigatorKey,
        initialLocation: '/dashboardMenu',
        routes: [
          ShellRoute(
            builder: (context, state, child) => DashboardShell(child: child),
            routes: [
              LinksysRoute(
                name: RouteNamed.dashboardMenu,
                path: '/dashboardMenu',
                builder: (context, state) => Scaffold(
                    body: TextButton(
                        onPressed: () => context.go('/dashboardMenu/instantTest'),
                        child: const Text('Menu page'))),
                routes: [
                  LinksysRoute(
                    name: RouteNamed.menuInstantTest,
                    path: 'instantTest',
                    config: const LinksysRouteConfig(noNaviRail: false),
                    builder: (context, state) => const InstantTestRoutePage(),
                  ),
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

  testWidgets('menu route shows the shared top bar instead of its own home link',
      (tester) async {
    await open(tester);
    expect(find.byType(TopBar), findsOneWidget);
    expect(find.byType(TopNavigationMenu), findsOneWidget);
    expect(find.text('Back to router home'), findsNothing);
    expect(find.text('What needs help?'), findsOneWidget);
    // Standard page title row: back arrow, then the page name.
    expect(find.text('Instant-Test'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to menu'));
    await tester.pumpAndSettle();
    expect(find.text('Menu page'), findsOneWidget);
  });

  testWidgets('a flow shows only its own back control, not the menu title row',
      (tester) async {
    await open(tester);
    await tapText(tester, "Internet isn't working");
    expect(find.byTooltip('Back to menu'), findsNothing);
    expect(find.byTooltip('Back to Instant-Test'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to Instant-Test'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Back to menu'), findsOneWidget);
  });

  testWidgets('flows are addressable so browser Back returns to the results',
      (tester) async {
    final router = await open(tester);
    expect(router.routeInformationProvider.value.uri.path,
        '/dashboardMenu/instantTest');

    await tapText(tester, "Internet isn't working");
    expect(router.routeInformationProvider.value.uri.queryParameters['instant'],
        '1');
    expect(find.text("My internet isn't working"), findsOneWidget);

    // The browser reports Back as the previous address.
    router.go('/dashboardMenu/instantTest');
    await tester.pumpAndSettle();
    expect(find.text('What needs help?').hitTestable(), findsOneWidget);
    expect(find.text("My internet isn't working"), findsNothing);

    // ...and Forward as the flow's address.
    router.go('/dashboardMenu/instantTest?instant=1');
    await tester.pumpAndSettle();
    expect(find.text("My internet isn't working"), findsOneWidget);
  });
}
