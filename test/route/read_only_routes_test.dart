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

  group('app router', () {
    GoRouterState stateFor(GoRouter router, String location) => GoRouterState(
          router.configuration,
          uri: Uri.parse(location),
          matchedLocation: location,
          fullPath: location,
          pathParameters: const {},
          pageKey: ValueKey(location),
        );

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
