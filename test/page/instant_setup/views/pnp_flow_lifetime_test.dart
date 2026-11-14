import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_entry_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_flow_shell.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/provider_overrides/mock_common.dart';
import '../../../mocks/provider_overrides/mock_pnp.dart';

/// Every flow instance the container builds, and which of them are gone.
class _Instances {
  final List<_CountedPnp> built = [];
  int disposed = 0;

  int get alive => built.length - disposed;
}

/// A flow the test can move, which records being built and being disposed.
class _CountedPnp extends FixedPnpNotifier {
  _CountedPnp(this._instances) : super(PnpState.initial());

  final _Instances _instances;

  @override
  PnpState build() {
    _instances.built.add(this);
    ref.onDispose(() => _instances.disposed++);
    return PnpState.initial();
  }

  void moveTo(PnpPhase phase) => state = state.copyWith(phase: phase);
}

/// The PnP flow lives exactly as long as the user is in it (#1511 P3).
///
/// `pnpProvider` is `autoDispose`, and what keeps it alive is [PnpFlowShell]
/// watching it — so leaving the `/pnp` tree ends the flow, and coming back
/// starts a new one without anyone calling `ref.invalidate`.
void main() {
  late _Instances instances;

  Future<GoRouter> pump(WidgetTester tester) async {
    instances = _Instances();
    final router = GoRouter(
      initialLocation: '/outside',
      routes: [
        GoRoute(
          path: '/outside',
          builder: (_, __) => const Text('OUTSIDE'),
        ),
        ShellRoute(
          builder: (_, state, child) =>
              PnpFlowShell(location: state.uri, child: child),
          routes: [
            GoRoute(
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
            ),
          ],
        ),
        GoRoute(
          name: RouteNamed.pnpNoInternetConnection,
          path: RoutePath.pnpNoInternetConnection,
          builder: (_, __) => const Text('TROUBLESHOOTING'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...commonOverrides(),
        pnpProvider.overrideWith(() => _CountedPnp(instances)),
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

  /// A few frames inside PnP. Not `pumpAndSettle`: the entry page's spinner
  /// never settles.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  /// Outside PnP nothing animates, so this can settle — and it has to: Riverpod
  /// disposes an unwatched `autoDispose` provider on a later frame than the one
  /// that unmounted its last watcher, and fixed-length pumps did not reach it.
  Future<void> leave(WidgetTester tester, GoRouter router, String to) async {
    router.go(to);
    await tester.pumpAndSettle();
  }

  testWidgets('going into PnP from outside leaves one clean flow',
      (tester) async {
    // The reviewer's pin for "`PnpNotifier.build()` stays side-effect free":
    // whoever reads the flow first creates it, and only the instance the shell
    // holds may survive, at the state `build()` returns.
    final router = await pump(tester);
    expect(instances.built, isEmpty, reason: 'nothing outside PnP reads it');

    router.go(RoutePath.pnp);
    await settle(tester);

    expect(instances.alive, 1);
    expect(instances.built.last.state, PnpState.initial());
  });

  testWidgets(
      'leaving PnP after completion ends the flow, and coming back starts a '
      'new one', (tester) async {
    final router = await pump(tester);
    router.go(RoutePath.pnp);
    await settle(tester);
    final first = instances.built.last;
    first.moveTo(const WizardWifiReady(ssid: 'MyWiFi', password: 'pw'));
    await settle(tester);

    await leave(tester, router, '/outside'); // the completion screen's Done
    expect(instances.alive, 0, reason: 'nothing holds the flow outside PnP');

    router.go(RoutePath.pnp);
    await settle(tester);
    expect(instances.alive, 1);
    expect(instances.built.last, isNot(same(first)));
    expect(instances.built.last.state.phase, isA<AdminCheckingInternet>(),
        reason: 'a second run must not inherit the first run\'s phase');
  });

  testWidgets('handing off to troubleshooting ends the flow too',
      (tester) async {
    // Before the wizard starts PnP holds nothing that has to survive, and
    // troubleshooting's PnP ending comes back to `/pnp`, which re-runs the
    // entry check (#1511 P1).
    final router = await pump(tester);
    router.go(RoutePath.pnp);
    await settle(tester);

    instances.built.last.moveTo(const NoInternet());
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path,
        '/pnpNoInternetConnection/${TroubleshootingCaller.pnp}');
    expect(instances.alive, 0);
  });
}
