@Tags(['ui'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';

/// Regression test for issue #1421 (same class as #1029 / #1420):
///
///   "Dashboard > LAN Information > back arrow should return to the Dashboard."
///
/// Root cause: `uspLocalNetwork` used to be a **nested child** of
/// `uspAdvancedSettings` in the go_router tree. `DashboardCardTemplate` opens it
/// with `context.pushNamed(RouteNamed.uspLocalNetwork)`, and go_router resolves a
/// nested named route to its full path (`/uspAdvancedSettings/uspLocalNetwork`),
/// synthesizing `UspAdvancedSettingsView` into the navigator stack. Pressing back
/// therefore popped to Advanced Settings instead of the Dashboard.
///
/// The fix promotes `uspLocalNetwork` to a **top-level sibling** of
/// `uspDashboard` under the USP shell (mirroring `uspDeviceList`, fixed the same
/// way in #1029).
///
/// Two layers of assertion:
///  1. A STRUCTURAL check on the real production route tree (`uspDashboardRoute`)
///     — the direct guard against the fix ever regressing: `uspLocalNetwork` must
///     be a direct child of the shell and must NOT be nested under
///     `uspAdvancedSettings`.
///  2. A BEHAVIORAL check on a hermetic router that mirrors the fixed topology,
///     proving the go_router back-stack semantics the structural shape relies on
///     (per the navigation-tracing playbook: assert the real stack, don't reason
///     about it).
void main() {
  group('uspLocalNetwork route topology (#1421)', () {
    List<RouteBase> childrenOf(RouteBase route) => route.routes;

    LinksysRoute? findLinksysRoute(List<RouteBase> routes, String name) {
      for (final r in routes) {
        if (r is LinksysRoute && r.name == name) return r;
      }
      return null;
    }

    test(
        'uspLocalNetwork is a direct child of the USP shell (sibling of '
        'uspDashboard), not nested under uspAdvancedSettings', () {
      final shellChildren = childrenOf(uspDashboardRoute);

      // It lives at the shell level, alongside uspDashboard.
      final localNetwork =
          findLinksysRoute(shellChildren, RouteNamed.uspLocalNetwork);
      expect(localNetwork, isNotNull,
          reason:
              'uspLocalNetwork must be a top-level sibling under the USP shell');
      final dashboard =
          findLinksysRoute(shellChildren, RouteNamed.uspDashboard);
      expect(dashboard, isNotNull);

      // Its path is the absolute segment, matching the other siblings.
      expect(localNetwork!.path, RoutePath.uspLocalNetwork);

      // And it is NOT among the children of uspAdvancedSettings anymore.
      final advanced =
          findLinksysRoute(shellChildren, RouteNamed.uspAdvancedSettings);
      expect(advanced, isNotNull);
      final nestedUnderAdvanced =
          findLinksysRoute(childrenOf(advanced!), RouteNamed.uspLocalNetwork);
      expect(nestedUnderAdvanced, isNull,
          reason:
              'nesting uspLocalNetwork under uspAdvancedSettings is the #1421 bug');
    });
  });

  group('uspLocalNetwork dashboard-card back navigation semantics (#1421)', () {
    Widget page(String label) => Scaffold(
          appBar: AppBar(title: Text(label)),
          body: Center(child: Text('$label-body')),
        );

    // Mirrors the FIXED topology: dashboard, advanced, and localNetwork are all
    // parallel siblings.
    GoRouter buildRouter() => GoRouter(
          initialLocation: '/dashboard',
          routes: [
            GoRoute(
              name: 'dashboard',
              path: '/dashboard',
              builder: (context, state) => page('Dashboard'),
            ),
            GoRoute(
              name: 'advanced',
              path: '/advanced',
              builder: (context, state) => page('Advanced'),
            ),
            GoRoute(
              name: 'localNetwork',
              path: '/localNetwork',
              builder: (context, state) => page('LocalNetwork'),
            ),
          ],
        );

    Future<void> pump(WidgetTester tester, GoRouter router) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
    }

    testWidgets('pushNamed from Dashboard pops straight back to the Dashboard',
        (tester) async {
      final router = buildRouter();
      await pump(tester, router);
      expect(find.text('Dashboard'), findsOneWidget);

      // Dashboard card => context.pushNamed(RouteNamed.uspLocalNetwork).
      router.pushNamed('localNetwork');
      await tester.pumpAndSettle();
      expect(find.text('LocalNetwork'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();

      // Expected result from the issue: back returns to the Dashboard.
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Advanced'), findsNothing);
    });

    testWidgets(
        'does NOT regress the Advanced Settings entry: pushNamed from '
        'Advanced still pops back to Advanced', (tester) async {
      final router = buildRouter();
      await pump(tester, router);

      // Advanced Settings list => context.pushNamed(RouteNamed.uspLocalNetwork).
      router.goNamed('advanced');
      await tester.pumpAndSettle();
      expect(find.text('Advanced'), findsOneWidget);

      router.pushNamed('localNetwork');
      await tester.pumpAndSettle();
      expect(find.text('LocalNetwork'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();

      // Entering from Advanced Settings must still return to Advanced Settings.
      expect(find.text('Advanced'), findsOneWidget);
    });
  });
}
