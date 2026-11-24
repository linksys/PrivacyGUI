import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';

/// Instant-Test home, as the Menu route opens it.
const instantTestHome = '/dashboardMenu/menuInstantTest';

/// The real Instant-Test route tree (home and its child routes) under a
/// stand-in Menu page.
GoRouter instantTestRouter({String initialLocation = instantTestHome}) =>
    GoRouter(
      initialLocation: initialLocation,
      routes: [
        LinksysRoute(
          name: RouteNamed.dashboardMenu,
          path: RoutePath.dashboardMenu,
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Menu page'))),
          routes: [
            menus.firstWhere((route) => route.name == RouteNamed.menuInstantTest),
          ],
        ),
      ],
    );

/// The page's back arrow (StyledAppPageView).
final backButton = find.byKey(const Key('appBarBackButton'));

/// The title row scrolls with the page, as on every StyledAppPageView.
Future<void> tapBack(WidgetTester tester) async {
  await tester.ensureVisible(backButton);
  await tester.pump();
  await tester.tap(backButton);
  await tester.pumpAndSettle();
}

/// The location of the page on top, including pushed pages.
Uri topLocation(GoRouter router) {
  final top = router.routerDelegate.currentConfiguration.last;
  return top is ImperativeRouteMatch
      ? top.matches.uri
      : router.routerDelegate.currentConfiguration.uri;
}

/// The route name of the page on top, including pushed pages.
String? topRoute(GoRouter router) {
  final top = router.routerDelegate.currentConfiguration.last;
  final route =
      top is ImperativeRouteMatch ? top.matches.last.route : top.route;
  return route.name;
}
