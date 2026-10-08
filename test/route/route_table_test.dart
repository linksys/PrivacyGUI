// The app's route table.
//
// A login that may not write is turned away from the PnP routes and cloud
// account login, and sees a blocked page in place of a few write-only flows
// (Add Nodes, manual firmware update, local password recovery) (#1637). These
// tests pin that each of those routes is still registered and resolves to the
// path it always has, so that change cannot quietly remove a route.
//
// The route objects are inspected directly rather than navigated to: the
// app-level redirect needs connectivity, auth and PnP providers wired to a real
// router, which is not what is being pinned here.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';

void main() {
  late ProviderContainer container;
  late GoRouter router;

  setUp(() {
    container = ProviderContainer();
    router = container.read(routerProvider);
  });

  tearDown(() => container.dispose());

  /// Every route in the table, flattened, keyed by name.
  Map<String, GoRoute> routesByName() {
    final result = <String, GoRoute>{};
    void walk(List<RouteBase> routes) {
      for (final route in routes) {
        if (route is GoRoute && route.name != null) {
          result[route.name!] = route;
        }
        walk(route.routes);
      }
    }

    walk(router.configuration.routes);
    return result;
  }

  test('the default build is local-capable', () {
    expect(BuildConfig.forceCommandType, ForceCommand.none);
  });

  // Routes a read-only login is redirected away from or blocked on. Each must
  // still be there, with the full path it has always had.
  const writeFlowRoutes = {
    RouteNamed.pnp: RoutePath.pnp,
    RouteNamed.pnpConfig: '${RoutePath.pnp}/${RoutePath.pnpConfig}',
    RouteNamed.pnpNoInternetConnection: RoutePath.pnpNoInternetConnection,
    RouteNamed.pnpUnplugModem:
        '${RoutePath.pnpNoInternetConnection}/${RoutePath.pnpUnplugModem}',
    RouteNamed.addNodes: RoutePath.addNodes,
    RouteNamed.cloudLoginAccount: RoutePath.cloudLoginAccount,
    RouteNamed.otpStart: '${RoutePath.cloudLoginAccount}/${RoutePath.otpStart}',
    RouteNamed.localRouterRecovery:
        '${RoutePath.localLoginPassword}/${RoutePath.localRouterRecovery}',
    RouteNamed.localPasswordReset: '${RoutePath.localLoginPassword}/'
        '${RoutePath.localRouterRecovery}/${RoutePath.localPasswordReset}',
    RouteNamed.manualFirmwareUpdate: '${RoutePath.dashboardMenu}/'
        '${RoutePath.menuInstantAdmin}/${RoutePath.manualFirmwareUpdate}',
  };

  // Settings pages that stay reachable on every login; read-only access only
  // disables their commit actions, never the route.
  const settingsRoutes = [
    RouteNamed.dashboardHome,
    RouteNamed.dashboardMenu,
    RouteNamed.menuInstantAdmin,
    RouteNamed.menuInstantTopology,
    RouteNamed.menuInstantDevices,
    RouteNamed.nodeDetails,
    RouteNamed.firmwareUpdateDetail,
    RouteNamed.settingsTimeZone,
    RouteNamed.troubleshooting,
    RouteNamed.dashboardSpeedTest,
    RouteNamed.dashboardSupport,
    RouteNamed.cloudLoginAuth,
    RouteNamed.localLoginPassword,
    RouteNamed.prepareDashboard,
    RouteNamed.selectNetwork,
  ];

  group('write-only flows stay registered', () {
    for (final MapEntry(key: name, value: path) in writeFlowRoutes.entries) {
      test(name, () {
        expect(routesByName(), contains(name));
        expect(router.namedLocation(name), path);
      });
    }
  });

  group('settings pages stay registered', () {
    for (final name in settingsRoutes) {
      test(name, () => expect(routesByName(), contains(name)));
    }
  });

  test('every route has a builder', () {
    final routes = routesByName().values.whereType<LinksysRoute>().toList();
    expect(routes, isNotEmpty);
    for (final route in routes) {
      expect(route.builder, isNotNull, reason: route.name);
    }
  });

  // A write-only flow still renders its own page with full access; the marking
  // only takes effect for a login that may not write.
  testWidgets('a LinksysRoute renders exactly what its builder returns',
      (tester) async {
    final testRouter = GoRouter(routes: [
      LinksysRoute(
        path: '/',
        config: const LinksysRouteConfig(noNaviRail: true, writeFlow: true),
        builder: (context, state) => const Text('the page'),
      ),
    ]);
    await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: testRouter)));
    await tester.pumpAndSettle();

    expect(find.text('the page'), findsOneWidget);
  });
}
