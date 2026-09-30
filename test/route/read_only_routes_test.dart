// How a read-only build keeps the viewer out of flows that only write.
//
// Two mechanisms, chosen by how a flow is entered:
//
// - Flows reached with goNamed or a typed URL (PnP, cloud account login and
//   its OTP steps) are redirected to the dashboard. PnP in particular must not
//   be entered at all: besides its writes it flips the login to local and
//   pauses polling, neither of which the transport guard would see.
// - Flows pushed from inside the app, whose callers await a result (Add
//   Nodes, manual firmware update, local password recovery), keep their route
//   but render a blocked page. A redirect would push some other page in their
//   place and hand the caller a result it does not expect.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/read_only/read_only_blocked_view.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';
import 'package:privacy_gui/providers/read_only/read_only_mode_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';

import '../common/di.dart';
import '../common/testable_router.dart';

void main() {
  mockDependencyRegister();

  group('readOnlyRedirect', () {
    const blocked = [
      RoutePath.pnp,
      '${RoutePath.pnp}/${RoutePath.pnpConfig}',
      RoutePath.pnpNoInternetConnection,
      '${RoutePath.pnpNoInternetConnection}/${RoutePath.pnpUnplugModem}',
      RoutePath.cloudLoginAccount,
      '${RoutePath.cloudLoginAccount}/${RoutePath.otpStart}',
    ];
    const allowed = [
      '/',
      RoutePath.dashboardHome,
      RoutePath.dashboardMenu,
      RoutePath.cloudLoginAuth,
      RoutePath.localLoginPassword,
      RoutePath.prepareDashboard,
      RoutePath.selectNetwork,
      RoutePath.addNodes,
    ];

    for (final location in blocked) {
      test('sends $location to the dashboard', () {
        expect(readOnlyRedirect(location), RoutePath.dashboardHome);
      });
    }

    for (final location in allowed) {
      test('leaves $location alone', () {
        expect(readOnlyRedirect(location), isNull);
      });
    }
  });

  GoRouterState stateFor(GoRouter router, String location) => GoRouterState(
        router.configuration,
        uri: Uri.parse(location),
        matchedLocation: location,
        fullPath: location,
        pathParameters: const {},
        pageKey: ValueKey(location),
      );

  group('app router', () {
    testWidgets('a read-only build redirects PnP before anything else runs',
        (tester) async {
      final container = ProviderContainer(
          overrides: [readOnlyModeProvider.overrideWithValue(true)]);
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      late BuildContext context;
      await tester.pumpWidget(Builder(builder: (c) {
        context = c;
        return const SizedBox();
      }));

      for (final location in [
        RoutePath.pnp,
        RoutePath.pnpNoInternetConnection,
        RoutePath.cloudLoginAccount,
      ]) {
        expect(
            await router.configuration
                .topRedirect(context, stateFor(router, location)),
            RoutePath.dashboardHome,
            reason: location);
      }
    });
  });

  group('landing on /', () {
    // An unconfigured router makes '/' elect PnP, and electing it logs the
    // user out before the redirect could turn PnP away. A read-only build must
    // not even ask.
    test('a writable build on the LAN asks whether the router needs setup', () {
      expect(
          shouldCheckForPnp(
              readOnly: false,
              routerType: RouterType.behindManaged,
              loginType: LoginType.none),
          isTrue);
      expect(
          shouldCheckForPnp(
              readOnly: false,
              routerType: RouterType.others,
              loginType: LoginType.none,
              force: ForceCommand.local),
          isTrue);
    });

    test('a remote login does not ask', () {
      expect(
          shouldCheckForPnp(
              readOnly: false,
              routerType: RouterType.behindManaged,
              loginType: LoginType.remote),
          isFalse);
    });

    test('a read-only build never asks', () {
      for (final routerType in RouterType.values) {
        for (final force in ForceCommand.values) {
          expect(
              shouldCheckForPnp(
                  readOnly: true,
                  routerType: routerType,
                  loginType: LoginType.none,
                  force: force),
              isFalse,
              reason: '$routerType $force');
        }
      }
    });
  });

  group('write-only flows', () {
    Widget app({required bool readOnly, required bool writeFlow}) =>
        testableRouter(
          overrides: [readOnlyModeProvider.overrideWithValue(readOnly)],
          router: GoRouter(routes: [
            LinksysRoute(
              path: '/',
              config: LinksysRouteConfig(writeFlow: writeFlow),
              builder: (context, state) => const Text('the flow'),
            ),
          ]),
        );

    testWidgets('render normally in a writable build', (tester) async {
      await tester.pumpWidget(app(readOnly: false, writeFlow: true));
      await tester.pumpAndSettle();
      expect(find.text('the flow'), findsOneWidget);
    });

    testWidgets('render a blocked page in a read-only build', (tester) async {
      await tester.pumpWidget(app(readOnly: true, writeFlow: true));
      await tester.pumpAndSettle();
      expect(find.text('the flow'), findsNothing);
      expect(find.byType(ReadOnlyBlockedView), findsOneWidget);
    });

    testWidgets('other routes are untouched in a read-only build',
        (tester) async {
      await tester.pumpWidget(app(readOnly: true, writeFlow: false));
      await tester.pumpAndSettle();
      expect(find.text('the flow'), findsOneWidget);
    });

    test('are the routes the app pushes into', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final writeFlows = <String>[];
      void walk(List<RouteBase> routes) {
        for (final route in routes) {
          if (route is LinksysRoute && route.config?.writeFlow == true) {
            writeFlows.add(route.name!);
          }
          walk(route.routes);
        }
      }

      walk(container.read(routerProvider).configuration.routes);
      expect(writeFlows.toSet(), {
        RouteNamed.addNodes,
        RouteNamed.manualFirmwareUpdate,
        RouteNamed.localRouterRecovery,
        RouteNamed.localPasswordReset,
      });
    });
  });
}
