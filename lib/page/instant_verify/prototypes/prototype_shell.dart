import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/instant_verify/prototypes/mock_pivot_notifier.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/services/browser_diagnostic_service.dart';
import 'package:privacy_gui/page/instant_verify/views/help/help_page.dart';
import 'package:privacy_gui/page/instant_verify/views/instant_test_navigation.dart';
import 'package:privacy_gui/page/instant_verify/views/instant_test_page.dart';
import 'package:privacy_gui/page/instant_verify/views/my_network_tab.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'demo_controls.dart';

const _previewRoutes = InstantTestRoutes(
  home: RouteNamed.instantPrototype,
  devices: RouteNamed.instantPrototypeDevices,
  network: RouteNamed.instantPrototypeNetwork,
  help: RouteNamed.instantPrototypeHelp,
);

/// Local test builds only (registered when force=local): the Instant-Test
/// pages and their child routes, on simulated diagnostics and actions. The
/// preview never uses router data or executes router mutations.
LinksysRoute instantPrototypeRoute() => LinksysRoute(
      name: _previewRoutes.home,
      path: RoutePath.instantPrototype,
      config: const LinksysRouteConfig(noNaviRail: true),
      builder: (context, state) =>
          PrototypeRoot(state: state, child: const InstantTestPage()),
      routes: [
        LinksysRoute(
          name: _previewRoutes.devices,
          path: RoutePath.instantTestDevices,
          builder: (context, state) =>
              PrototypeRoot(state: state, child: const InstantTestDevicesPage()),
        ),
        LinksysRoute(
          name: _previewRoutes.network,
          path: RoutePath.instantTestNetwork,
          builder: (context, state) =>
              PrototypeRoot(state: state, child: const MyNetworkTab()),
        ),
        LinksysRoute(
          name: _previewRoutes.help,
          path: RoutePath.instantTestHelp,
          builder: (context, state) => PrototypeRoot(
            state: state,
            child: InstantTestHelpView(
              flow: int.tryParse(state.uri.queryParameters['flow'] ?? '') ?? 0,
            ),
          ),
        ),
      ],
    );

/// One simulated session shared by every preview page, so the pages read the
/// same results, as they share the real providers in the app.
class _PreviewSession {
  _PreviewSession(this.parent, this.configuration, this.container,
      {required this.overview, required this.probe});
  final ProviderContainer parent;
  final String configuration;
  final ProviderContainer container;
  final int overview;
  final PreviewProbeScenario probe;

  static _PreviewSession? _current;

  static const _demoKeys = {'probe', 'overview', 'progress', 'run'};

  /// A URL with demo parameters (from Demo controls or a test runner) starts a
  /// fresh session; plain page navigation keeps the current one.
  static _PreviewSession of(
      ProviderContainer parent, Map<String, String> query) {
    final current = _current;
    if (current != null &&
        current.parent == parent &&
        !query.keys.any(_demoKeys.contains)) {
      return current;
    }
    final probe = PreviewProbeScenario.values.firstWhere(
        (value) => value.name == query['probe'],
        orElse: () => PreviewProbeScenario.healthy);
    final showProgress = query['progress'] == '1';
    final parsed = int.tryParse(query['overview'] ?? '') ?? 3;
    final overview = parsed >= 0 && parsed < 5 ? parsed : 3;
    final configuration =
        '${probe.name}:$overview:$showProgress:${query['run'] ?? ''}';
    if (current != null &&
        current.parent == parent &&
        current.configuration == configuration) {
      return current;
    }
    final service = MockBrowserDiagnosticService(scenario: probe);
    final session = _PreviewSession(
      parent,
      configuration,
      ProviderContainer(parent: parent, overrides: [
        browserDiagnosticServiceProvider.overrideWithValue(service),
        instantVerifyPivotProvider.overrideWith(() =>
            MockInstantVerifyPivotNotifier(
                showProgress: showProgress,
                overviewScenario: overview,
                actionScenario: probe)),
        instantTestRoutesProvider.overrideWithValue(_previewRoutes),
      ]),
      overview: overview,
      probe: probe,
    );
    _current = session;
    // Pages of the replaced session unmount in this frame.
    if (current != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => current.container.dispose());
    }
    return session;
  }
}

/// Puts one preview page on the simulated session, with the reviewer's demo
/// controls over it.
class PrototypeRoot extends StatelessWidget {
  const PrototypeRoot({super.key, required this.state, required this.child});

  final GoRouterState state;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final session = _PreviewSession.of(
        ProviderScope.containerOf(context, listen: false),
        state.uri.queryParameters);
    return UncontrolledProviderScope(
      // A new session gives the page fresh state.
      key: ObjectKey(session.container),
      container: session.container,
      child: Stack(children: [
        child,
        Positioned(
          right: 16,
          bottom: 16,
          child: SafeArea(
            child: Material(
              elevation: 2,
              child: DemoControls(
                  overview: session.overview, probe: session.probe),
            ),
          ),
        ),
      ]),
    );
  }
}
