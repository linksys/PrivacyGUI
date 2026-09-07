import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacy_gui/route/router_logger.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/demo/pages/pnp_demo_launcher.dart';

/// Route path for the PnP demo launcher (demo-only).
/// Access via /demoPnpLauncher to test PnP flows.
const _demoPnpLauncher = '/demoPnpLauncher';

/// Overrides the main routerProvider for the Demo Application.
///
/// This custom router wraps all existing application routes [appRoutes] in a
/// [ShellRoute]. This allows the persistent Theme Studio Panel and FAB
/// to overlay the application content while sharing the same navigation context.
///
/// Crucially, because the Panel is part of the Route hierarchy (via Shell),
/// any [showDialog] call (which pushes a route to the Root Navigator)
/// will naturally sit ON TOP of this ShellRoute, solving Z-Index issues where
/// dialogs would otherwise appear underneath the Panel.
final demoRouterProvider = Provider<GoRouter>((ref) {
  final router = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: routerKey,
    refreshListenable: router,
    observers: [ref.read(routerLoggerProvider)],
    initialLocation: '/',
    routes: [
      ShellRoute(
        // Demo runs the SAME shells as production (UspDashboardShell etc.), so
        // the mascot-hosted Theme Studio is already available. This ShellRoute
        // is now a plain pass-through — the old demo-only Theme Studio FAB /
        // Panel overlay was removed so the demo UI matches the production build.
        builder: (context, state, child) => child,
        routes: [
          // Demo-only PnP launcher route
          GoRoute(
            path: _demoPnpLauncher,
            builder: (context, state) => const PnpDemoLauncher(),
          ),
          ...appRoutes, // Reuse the standard app routes
        ],
      ),
    ],
    redirect: (context, state) {
      if (state.matchedLocation == '/') {
        // Demo mode: go directly to USP Dashboard for UI verification.
        // Access PnP flows via /demoPnpLauncher if needed.
        return RoutePath.uspDashboard;
      } else if (state.matchedLocation == _demoPnpLauncher) {
        return state.uri.toString();
      } else if (state.matchedLocation == RoutePath.localLoginPassword) {
        router.autoConfigurationLogic(state);
        return router.redirectLogic(state);
      } else if (state.matchedLocation.startsWith('/autoParentFirstLogin')) {
        return state.uri.toString();
      } else if (state.matchedLocation.startsWith('/pnp') ||
          state.matchedLocation.startsWith('/pnpNoInternetConnection')) {
        // PnP routes — no auth required, pass through.
        return state.uri.toString();
      } else if (state.matchedLocation.startsWith('/usp')) {
        return state.uri.toString();
      }
      return router.redirectLogic(state);
    },
    debugLogDiagnostics: true,
  );
});
