// Baseline for the app's route table in the default build.
//
// A read-only build is going to redirect the PnP routes and swap the builder of
// a few write-only flows (Add Nodes, manual firmware update, local password
// recovery, cloud account login and OTP). These tests pin that, in the build
// every local user gets, each of those routes is still registered, resolves to
// the page it resolves to today, and carries none of the extra config a
// read-only build will add. They exist so that change cannot quietly remove a
// route from the local build.
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

  // Routes a read-only build intends to redirect or block. In the default build
  // each must still be there, with the full path it has today.
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

  // Settings pages that stay reachable in every build; a read-only build only
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

  test('no route builds anything but what its own builder returns', () {
    // LinksysRoute wraps the builder it is given. Today that wrapper is a plain
    // pass-through; a read-only build will make it conditional. Pin the
    // pass-through by checking a route's config carries only the fields that
    // exist today, and that every LinksysRoute has a builder.
    final routes = routesByName().values.whereType<LinksysRoute>().toList();
    expect(routes, isNotEmpty);
    for (final route in routes) {
      expect(route.builder, isNotNull, reason: route.name);
      final config = route.config;
      if (config != null) {
        expect(
          config.props,
          [
            config.column,
            config.ignoreConnectivityEvent,
            config.ignoreCloudOfflineEvent,
            config.noNaviRail,
          ],
          reason: route.name,
        );
      }
    }
  });

  testWidgets('a LinksysRoute renders exactly what its builder returns',
      (tester) async {
    final testRouter = GoRouter(routes: [
      LinksysRoute(
        path: '/',
        config: const LinksysRouteConfig(noNaviRail: true),
        builder: (context, state) => const Text('the page'),
      ),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: testRouter));
    await tester.pumpAndSettle();

    expect(find.text('the page'), findsOneWidget);
  });
}
