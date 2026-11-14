import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_flow_plan.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_entry_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_flow_shell.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/provider_overrides/mock_common.dart';
import '../../../mocks/provider_overrides/mock_pnp.dart';
import '../../../mocks/test_data/scenes/pnp_scene_data.dart';

/// A pinned flow the test can move, the way `PnpNotifier` moves it.
class _DrivenPnp extends FixedPnpNotifier {
  _DrivenPnp() : super(PnpState.initial());

  void moveTo(PnpPhase phase) => state = state.copyWith(phase: phase);
}

const _plan = PnpFlowPlan(settingStepIds: ['wifi']);

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
    setDemoWizard(pnpNoGuestRouter);
  }
}

/// Every [PnpPhase] but the three the flow navigates on — [WizardConfiguring],
/// [WizardYourNetwork] and [NoInternet] — one instance each.
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
    const before = PnpState(phase: WizardInitializing());
    const editing = PnpState(phase: WizardConfiguring(), plan: _plan);

    test('the wizard is opened when the flow gets its plan', () {
      for (final previous in <PnpState?>[
        null,
        const PnpState(phase: AdminInternetConnected()),
        before,
      ]) {
        expect(pnpFlowDestination(previous, editing), PnpFlowDestination.wizard,
            reason: 'from $previous');
      }
    });

    test('a failed save stays on the step where Save was pressed', () {
      // The step is in the URL (#1511 P4), so returning to the form needs no
      // navigation — and must not have one, which would land on the first step.
      expect(
        pnpFlowDestination(
          const PnpState(phase: WizardSaving(), plan: _plan),
          const PnpState(
            phase: WizardConfiguring(saveError: UnexpectedError()),
            plan: _plan,
          ),
        ),
        isNull,
      );
    });

    test('Your Network is opened when the save lands (#1511 P5)', () {
      // The save is pressed on the last setting step, and the URL stays there
      // while it is out; Your Network is a step the flow moves the user to, not
      // one a Next reaches.
      const ready = WizardWifiReady(ssid: 'n', password: 'p');
      const onYourNetwork =
          PnpState(phase: WizardYourNetwork(ready: ready), plan: _plan);

      for (final previous in const <PnpPhase>[
        WizardSaved(),
        WizardTestingReconnect(attemptCount: 1, maxAttempts: 5),
      ]) {
        expect(
          pnpFlowDestination(
              PnpState(phase: previous, plan: _plan), onYourNetwork),
          PnpFlowDestination.yourNetwork,
          reason: 'from $previous',
        );
      }
      expect(
          pnpFlowDestination(
              onYourNetwork, onYourNetwork.copyWith(meshNodes: const [])),
          isNull,
          reason: 'a re-read of the nodes on Your Network is not a navigation');
    });

    test('a re-read of the nodes is not a navigation', () {
      expect(
        pnpFlowDestination(editing, editing.copyWith(meshNodes: const [])),
        isNull,
      );
    });

    test('no internet hands the user to troubleshooting, from anywhere', () {
      for (final previous in <PnpPhase?>[null, ..._phasesThatStay]) {
        expect(
          pnpFlowDestination(
            previous == null ? null : PnpState(phase: previous),
            const PnpState(phase: NoInternet()),
          ),
          PnpFlowDestination.troubleshooting,
          reason: 'from $previous',
        );
      }
    });

    test('every other phase stays where it is', () {
      for (final next in _phasesThatStay) {
        expect(pnpFlowDestination(PnpState.initial(), PnpState(phase: next)),
            isNull,
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
              builder: (_, __) => const SizedBox.shrink(),
              routes: [
                GoRoute(
                  name: RouteNamed.pnpStep('wifi'),
                  path: 'wifi',
                  builder: (_, __) => const Text('WIZARD'),
                ),
              ],
            ),
          ],
        );

    testWidgets('under the shell, reaching the form opens the wizard',
        (tester) async {
      final router = await pump(tester, [
        ShellRoute(
          builder: (_, state, child) =>
              PnpFlowShell(location: state.uri, child: child),
          routes: [pnpTree()],
        ),
        ...destinations(),
      ]);

      pnp.moveTo(const AdminInternetConnected());
      pnp.setDemoWizard(pnpNoGuestRouter);
      await tester.pump();
      await tester.pump();

      expect(location(router), '${RoutePath.pnp}/${RoutePath.pnpConfig}/wifi');
    });

    testWidgets('under the shell, no internet goes to troubleshooting as PnP',
        (tester) async {
      final router = await pump(tester, [
        ShellRoute(
          builder: (_, state, child) =>
              PnpFlowShell(location: state.uri, child: child),
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
            builder: (_, state, child) =>
                PnpFlowShell(location: state.uri, child: child),
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

      expect(location(router), '${RoutePath.pnp}/${RoutePath.pnpConfig}/wifi');
      expect(recovering.starts, 1);
    });

    testWidgets('the entry page alone no longer navigates', (tester) async {
      // The entry view's listener was one of the stitch sites; the mapping is
      // the shell's now, so without a shell nothing moves.
      final router = await pump(tester, [pnpTree(), ...destinations()]);

      pnp.moveTo(const AdminInternetConnected());
      pnp.setDemoWizard(pnpNoGuestRouter);
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
