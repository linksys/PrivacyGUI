import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_config.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_entry_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_flow_shell.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/provider_overrides/mock_common.dart';
import '../../../mocks/provider_overrides/mock_pnp.dart';

/// A pinned flow the test can move, the way `PnpNotifier` moves it.
class _DrivenPnp extends FixedPnpNotifier {
  _DrivenPnp() : super(PnpState.initial());

  void moveTo(PnpPhase phase) => state = state.copyWith(phase: phase);
}

const _config = PnpWifiConfig(
  ssid: 'MyWiFi',
  password: 'MyPass1234',
  originalSsid: 'Linksys00123',
  originalPassword: 'factory',
);

/// A pinned flow whose entry check finds internet, the way the real one does
/// once troubleshooting has brought it back. Counts the checks.
class _RecoveringPnp extends FixedPnpNotifier {
  _RecoveringPnp() : super(const PnpState(phase: NoInternet()));

  int starts = 0;

  @override
  Future<void> startPostLoginFlow() async {
    starts++;
    state = state.copyWith(phase: const AdminCheckingInternet());
    state = state.copyWith(phase: const AdminInternetConnected());
    state = state.copyWith(phase: const WizardInitializing());
    state = state.copyWith(phase: const WizardConfiguring(wifiConfig: _config));
  }
}

/// Every [PnpPhase] but the two the flow navigates on — [WizardConfiguring] and
/// [NoInternet] — one instance each.
const _phasesThatStay = <PnpPhase>[
  AdminCheckingInternet(),
  AdminInternetConnected(),
  AdminReadFailure(code: 9998),
  WizardInitializing(),
  WizardSaving(),
  WizardSaved(),
  WizardNeedsReconnect(newSsid: 'MyWiFi', newPassword: 'MyPass1234'),
  WizardTestingReconnect(attemptCount: 1, maxAttempts: 5),
  WizardCheckingFirmware(),
  WizardUpdatingFirmware(version: '1.0.17'),
  WizardWifiReady(ssid: 'MyWiFi', password: 'MyPass1234'),
  WizardError(message: 'boom'),
];

/// One shell over the PnP flow, and one place that maps its phase to a page
/// (#1511 P2).
void main() {
  group('pnpFlowDestination — the one phase→page mapping', () {
    test('the wizard is opened once the flow reaches the form', () {
      for (final previous in <PnpPhase?>[
        null,
        const AdminInternetConnected(),
        const WizardInitializing(),
      ]) {
        expect(
          pnpFlowDestination(
              previous, const WizardConfiguring(wifiConfig: _config)),
          PnpFlowDestination.wizard,
          reason: 'from $previous',
        );
      }
    });

    test('a failed save stays on the step where Save was pressed', () {
      // Re-navigating would rebuild the wizard and reset its step to 0 — the
      // patch #1511 P4 removes once the step is in the URL.
      expect(
        pnpFlowDestination(
          const WizardSaving(),
          const WizardConfiguring(wifiConfig: _config),
        ),
        isNull,
      );
    });

    test('an edit on the form is not a navigation', () {
      expect(
        pnpFlowDestination(
          const WizardConfiguring(wifiConfig: _config),
          const WizardConfiguring(wifiConfig: _config, meshNodes: []),
        ),
        isNull,
      );
    });

    test('no internet hands the user to troubleshooting, from anywhere', () {
      for (final previous in <PnpPhase?>[null, ..._phasesThatStay]) {
        expect(
          pnpFlowDestination(previous, const NoInternet()),
          PnpFlowDestination.troubleshooting,
          reason: 'from $previous',
        );
      }
    });

    test('every other phase stays where it is', () {
      for (final next in _phasesThatStay) {
        expect(pnpFlowDestination(const AdminCheckingInternet(), next), isNull,
            reason: '$next');
      }
    });
  });

  group('the shell, not a page, navigates', () {
    late _DrivenPnp pnp;

    Future<GoRouter> pump(WidgetTester tester, List<RouteBase> routes) async {
      pnp = _DrivenPnp();
      final router = GoRouter(initialLocation: RoutePath.pnp, routes: routes);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          ...commonOverrides(),
          pnpProvider.overrideWith(() => pnp),
        ],
        child: MaterialApp.router(
          theme: AppTheme.create(brightness: Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child ?? const SizedBox.shrink(),
          ),
          routerConfig: router,
        ),
      ));
      await tester.pump();
      return router;
    }

    String location(GoRouter router) =>
        router.routerDelegate.currentConfiguration.uri.toString();

    /// The two destinations, as stubs, at their production names and paths.
    List<RouteBase> destinations() => [
          GoRoute(
            name: RouteNamed.pnpNoInternetConnection,
            path: RoutePath.pnpNoInternetConnection,
            builder: (_, __) => const Text('TROUBLESHOOTING'),
          ),
        ];

    GoRoute pnpTree() => GoRoute(
          name: RouteNamed.pnp,
          path: RoutePath.pnp,
          builder: (_, __) => const PnpEntryView(),
          routes: [
            GoRoute(
              name: RouteNamed.pnpConfig,
              path: RoutePath.pnpConfig,
              builder: (_, __) => const Text('WIZARD'),
            ),
          ],
        );

    testWidgets('under the shell, reaching the form opens the wizard',
        (tester) async {
      final router = await pump(tester, [
        ShellRoute(
          builder: (_, __, child) => PnpFlowShell(child: child),
          routes: [pnpTree()],
        ),
        ...destinations(),
      ]);

      pnp.moveTo(const AdminInternetConnected());
      pnp.moveTo(const WizardConfiguring(wifiConfig: _config));
      await tester.pump();
      await tester.pump();

      expect(location(router), '${RoutePath.pnp}/${RoutePath.pnpConfig}');
    });

    testWidgets('under the shell, no internet goes to troubleshooting as PnP',
        (tester) async {
      final router = await pump(tester, [
        ShellRoute(
          builder: (_, __, child) => PnpFlowShell(child: child),
          routes: [pnpTree()],
        ),
        ...destinations(),
      ]);

      pnp.moveTo(const NoInternet());
      await tester.pump();
      await tester.pump();

      expect(location(router),
          '/pnpNoInternetConnection/${TroubleshootingCaller.pnp}');
    });

    testWidgets(
        'a recovered troubleshooting run comes back to /pnp, whose entry '
        'restarts the flow into the wizard — once', (tester) async {
      // The link the Auto-IPoE "continue" relies on since #1511 P1 dropped its
      // own startPostLoginFlow(): PnP's troubleshooting ending only goes to
      // `/pnp`, and the entry's check is what reaches the wizard. The flow is
      // still on the `NoInternet` it handed off with.
      final recovering = _RecoveringPnp();
      final router = GoRouter(
        initialLocation:
            '/pnpNoInternetConnection/${TroubleshootingCaller.pnp}',
        routes: [
          ShellRoute(
            builder: (_, __, child) => PnpFlowShell(child: child),
            routes: [pnpTree()],
          ),
          ...destinations(),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          ...commonOverrides(),
          pnpProvider.overrideWith(() => recovering),
        ],
        child: MaterialApp.router(
          theme: AppTheme.create(brightness: Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child ?? const SizedBox.shrink(),
          ),
          routerConfig: router,
        ),
      ));
      await tester.pump();

      router.go(RoutePath.pnp); // PnP's troubleshooting ending
      for (var i = 0; i < 4; i++) {
        await tester.pump();
      }

      expect(location(router), '${RoutePath.pnp}/${RoutePath.pnpConfig}');
      expect(recovering.starts, 1);
    });

    testWidgets('the entry page alone no longer navigates', (tester) async {
      // The entry view's listener was one of the stitch sites; the mapping is
      // the shell's now, so without a shell nothing moves.
      final router = await pump(tester, [pnpTree(), ...destinations()]);

      pnp.moveTo(const AdminInternetConnected());
      pnp.moveTo(const WizardConfiguring(wifiConfig: _config));
      await tester.pump();
      pnp.moveTo(const NoInternet());
      await tester.pump();
      await tester.pump();

      expect(location(router), RoutePath.pnp);
    });
  });

  test(
      'the production table puts the /pnp tree under the shell, and '
      'troubleshooting outside it', () {
    final shells = sharedAppRoutes
        .whereType<ShellRoute>()
        .where((shell) => shell.routes.contains(pnpRoute));
    expect(shells, hasLength(1), reason: 'one shell over the PnP flow');
    expect(shells.single.routes, isNot(contains(pnpNoInternetRoute)),
        reason: 'troubleshooting is not PnP\'s: it has its own state and is '
            'entered by more than one caller');
    expect(sharedAppRoutes, contains(pnpNoInternetRoute));
    expect(sharedAppRoutes, isNot(contains(pnpRoute)),
        reason: 'the /pnp tree is registered once, inside its shell');
  });
}
