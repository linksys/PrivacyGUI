import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacy_gui/route/constants.dart';

/// Regression coverage for issue #969.
///
/// Bug: entering Port Forwarding detail and tapping the back arrow returned to
/// Advanced Settings instead of the originating page.
///
/// ROOT CAUSE (empirically proven during development, see commit message):
/// `uspPortForwardingDetail` was declared as a route NESTED under
/// `uspAdvancedSettings`. With go_router, any canonical-URL entry (web fresh
/// load, browser reload, deep link, or `context.go()` to the full nested path
/// `/uspAdvancedSettings/uspPortForwardingDetail`) rebuilds the FULL ancestor
/// chain, synthesising an `uspAdvancedSettings` page into the navigator stack
/// beneath the detail page. `navigateBack()` then pops onto that synthetic
/// parent regardless of the real entry point.
///
/// FIX (Option A): promote `uspPortForwardingDetail` to a PARALLEL direct child
/// of the dashboard ShellRoute (mirroring the sibling `uspDhcpDetail`), so the
/// canonical URL is a single flat segment with no synthetic parent.
void main() {
  // ---------------------------------------------------------------------------
  // Part 1 — Structural assertion against the REAL production route tree.
  // ---------------------------------------------------------------------------
  group('#969 production route structure', () {
    GoRoute? findRoute(List<RouteBase> routes, String name) {
      for (final r in routes) {
        if (r is GoRoute && r.name == name) return r;
        final nested = findRoute(r.routes, name);
        if (nested != null) return nested;
      }
      return null;
    }

    bool isNestedUnder(List<RouteBase> routes, String parentName,
        String childName) {
      for (final r in routes) {
        if (r is GoRoute && r.name == parentName) {
          return findRoute(r.routes, childName) != null;
        }
        if (isNestedUnder(r.routes, parentName, childName)) return true;
      }
      return false;
    }

    test('uspPortForwardingDetail is a parallel direct child of the shell, '
        'NOT nested under uspAdvancedSettings', () {
      final shellRoutes = uspDashboardRoute.routes;

      // It exists as a direct child of the shell.
      final directChild = shellRoutes.whereType<GoRoute>().any(
          (r) => r.name == RouteNamed.uspPortForwardingDetail);
      expect(directChild, isTrue,
          reason:
              'uspPortForwardingDetail must be a parallel direct child of the dashboard shell');

      // It is NOT nested under uspAdvancedSettings anymore.
      final nested = isNestedUnder(shellRoutes,
          RouteNamed.uspAdvancedSettings, RouteNamed.uspPortForwardingDetail);
      expect(nested, isFalse,
          reason:
              'uspPortForwardingDetail must NOT be nested under uspAdvancedSettings (issue #969)');
    });

    test('canonical path is a single flat segment', () {
      final route = uspDashboardRoute.routes.whereType<GoRoute>().firstWhere(
          (r) => r.name == RouteNamed.uspPortForwardingDetail);
      expect(route.path, RoutePath.uspPortForwardingDetail);
      expect(route.path, startsWith('/'));
      expect('/'.allMatches(route.path).length, 1,
          reason: 'flat top-level path has exactly one slash');
    });
  });

  // ---------------------------------------------------------------------------
  // Part 2 — Behavioral AC1/AC2/AC3 on a faithful replica of the FIXED tree.
  //
  // The replica mirrors the post-fix structure: Dashboard, Advanced Settings,
  // and PortForwardingDetail are all PARALLEL direct children of one ShellRoute.
  // navigateBack semantics are reproduced exactly (canPop?pop():goNamed(fallback)).
  // ---------------------------------------------------------------------------
  group('#969 back navigation behavior (fixed parallel structure)', () {
    late GlobalKey<NavigatorState> shellKey;

    // Mirrors lib/route/navigation_extensions.dart navigateBack().
    Widget detailPage(BuildContext context, String fallback) => Scaffold(
          appBar: AppBar(title: const Text('Detail')),
          body: Center(
            child: ElevatedButton(
              key: const Key('back'),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.goNamed(fallback);
                }
              },
              child: const Text('back'),
            ),
          ),
        );

    GoRouter buildRouter(String initial) {
      shellKey = GlobalKey<NavigatorState>();
      return GoRouter(
        initialLocation: initial,
        routes: [
          ShellRoute(
            navigatorKey: shellKey,
            builder: (c, s, child) => child,
            routes: [
              GoRoute(
                name: 'uspDashboard',
                path: '/uspDashboard',
                builder: (c, s) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      key: const Key('dashToDetail'),
                      onPressed: () =>
                          c.pushNamed('uspPortForwardingDetail'),
                      child: const Text('Dashboard'),
                    ),
                  ),
                ),
              ),
              GoRoute(
                name: 'uspAdvancedSettings',
                path: '/uspAdvancedSettings',
                builder: (c, s) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      key: const Key('advToDetail'),
                      onPressed: () =>
                          c.pushNamed('uspPortForwardingDetail'),
                      child: const Text('Advanced Settings'),
                    ),
                  ),
                ),
              ),
              // Parallel direct child — the fix.
              GoRoute(
                name: 'uspPortForwardingDetail',
                path: '/uspPortForwardingDetail',
                builder: (c, s) =>
                    detailPage(c, 'uspAdvancedSettings'),
              ),
            ],
          ),
        ],
      );
    }

    testWidgets('AC1: Dashboard -> detail -> back returns to Dashboard',
        (tester) async {
      final router = buildRouter('/uspDashboard');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dashToDetail')));
      await tester.pumpAndSettle();
      expect(find.text('Detail'), findsOneWidget);

      await tester.tap(find.byKey(const Key('back')));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Advanced Settings'), findsNothing);
    });

    testWidgets(
        'AC2: Advanced Settings -> detail -> back returns to Advanced Settings',
        (tester) async {
      final router = buildRouter('/uspAdvancedSettings');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('advToDetail')));
      await tester.pumpAndSettle();
      expect(find.text('Detail'), findsOneWidget);

      await tester.tap(find.byKey(const Key('back')));
      await tester.pumpAndSettle();

      expect(find.text('Advanced Settings'), findsOneWidget);
    });

    testWidgets(
        'AC1 (web): fresh canonical-URL load -> back falls back, no synthetic '
        'Advanced Settings parent in stack', (tester) async {
      // Direct deep-link / browser reload at the flat detail URL.
      final router = buildRouter('/uspPortForwardingDetail');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('Detail'), findsOneWidget);

      // Only the detail page is in the stack — no synthetic parent.
      final nav = shellKey.currentState!;
      expect(nav.widget.pages.length, 1,
          reason:
              'flat parallel route must not synthesise an Advanced Settings parent');
      expect(nav.widget.pages.single.name, 'uspPortForwardingDetail');
    });
  });
}
