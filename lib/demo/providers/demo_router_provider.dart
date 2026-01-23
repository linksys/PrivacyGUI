import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacy_gui/route/router_logger.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/demo/theme_studio/theme_studio_fab.dart';
import 'package:privacy_gui/demo/theme_studio/theme_studio_panel.dart';
import 'package:privacy_gui/demo/providers/demo_ui_provider.dart';

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
        builder: (context, state, child) {
          return Stack(
            fit: StackFit.expand, // Ensure stack fills the screen
            children: [
              // Main Application Page Content
              child,

              // Theme Studio Panel (Animated Overlay)
              Consumer(
                builder: (context, ref, _) {
                  final isOpen = ref.watch(demoUIProvider).isThemePanelOpen;
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    top: 0,
                    bottom: 0,
                    right: isOpen ? 0 : -500,
                    width: 500,
                    child: const Material(
                      elevation: 16,
                      child: ThemeStudioPanel(),
                    ),
                  );
                },
              ),

              // Theme Studio FAB
              const Positioned(
                bottom: 16,
                right: 16,
                child: ThemeStudioFab(),
              ),
            ],
          );
        },
        routes: appRoutes, // Reuse the standard app routes
      ),
    ],
    // Reuse the exact same redirect logic as the main app
    redirect: (context, state) {
      if (state.matchedLocation == '/') {
        return router.autoConfigurationLogic(state);
      } else if (state.matchedLocation == RoutePath.localLoginPassword) {
        router.autoConfigurationLogic(state);
        return router.redirectLogic(state);
      } else if (state.matchedLocation.startsWith('/pnp')) {
        return router.goPnpPath(state);
      } else if (state.matchedLocation.startsWith('/autoParentFirstLogin')) {
        return state.uri.toString();
      }
      return router.redirectLogic(state);
    },
    debugLogDiagnostics: true,
  );
});
