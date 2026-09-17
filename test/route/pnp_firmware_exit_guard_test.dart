// The PnP wizard's exit guard, behind linksys/PrivacyGUI#1553 (REQ-B2).
//
// A first-connection firmware update is locked: the router is being flashed and
// the wizard has not finished, so there is nowhere to go back to and nothing to
// go forward to. Two things enforce that, and this file measures one of them. The
// other is not a second guard: `_buildFirmwareUpdate` renders no button, so there
// is no affordance in the page to decline. (`PnpSetupView` does pass an `onBackTap`
// closure, but it passes `appBarStyle: UiKitAppBarStyle.none` too, and
// `UiKitPageView._buildAppBarConfig()` returns null for that style before reaching
// the only line that consumes the callback — so a phase check written there would
// never run. That was measured rather than assumed, after a first attempt put one
// there.)
//
// THE CLOSURE UNDER TEST IS THE PRODUCTION ONE, the same arrangement as the
// sibling `usp_firmware_exit_guard_test.dart`: the route is pulled out of the
// real `pnpRoute` and re-hosted with a stub body, so `onExit` is the object
// `lib/route/route_pnp.dart` constructed rather than a copy of its logic. Delete
// `onExit:` from the route and `LinksysRoute` still supplies a non-null wrapper —
// but that wrapper returns true, the pop succeeds, and the cases below fail.
//
// WHY THIS GUARD IS NOT `_firmwareExitGuard`. The dashboard's two firmware pages
// key theirs on `firmwareUpdateNotifierProvider.isUpdating`, which is a property of
// a notifier the dashboard also drives: an update the user started there before
// walking into setup would lock this wizard, and `isUpdating` cannot tell whose
// install it is. The question the two guards answer is not the same question — "is
// an install running" versus "is this wizard the thing running it" — so the PnP one
// keys on the PnP phase.
//
// WHY TWO PHASES BLOCK AND NOT ONE. `WizardUpdatingFirmware` is the flash, and is
// what REQ-B2 names. `WizardCheckingFirmware` is here for a race rather than for a
// screen: popping during the check lands on `PnpEntryView`, whose `initState` calls
// `startPostLoginFlow()` and overwrites the phase, while `_checkFirmware` is still
// waiting for an answer that may be "yes" — and then writes
// `WizardUpdatingFirmware` over that flow and dispatches a flash. The cost of
// refusing is a dead Back press during a spinner bounded at fifteen seconds; the
// cost of allowing it is a router being written to with the locked screen never
// shown. This was a review finding, not the first design.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_config.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/router_provider.dart';

import '../mocks/provider_overrides/mock_pnp.dart';

/// The real `GoRoute` declared for [name], found by walking the real tree.
GoRoute _realRoute(String name) {
  GoRoute? found;
  void walk(RouteBase route) {
    if (route is GoRoute && route.name == name) found = route;
    route.routes.forEach(walk);
  }

  walk(pnpRoute);
  if (found == null) {
    throw StateError('no route named $name in pnpRoute');
  }
  return found!;
}

/// [route]'s own guard, re-hosted over a stub body.
///
/// `onExit` is passed through by reference. Everything else is replaced, so this
/// cannot start depending on the page — `PnpSetupView` has its own tests, and
/// pumping it here would let a provider change red a routing suite.
GoRoute _guardOnly(GoRoute route) => GoRoute(
      name: route.name,
      path: route.path,
      onExit: route.onExit,
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text('PAGE:${route.name}')),
      ),
    );

/// Whether a pop out of the wizard must be refused in [phase].
///
/// **The product decision, written out — not `phase is WizardUpdatingFirmware`,
/// which is what the guard itself reads.** An oracle that re-derived the
/// subject's own predicate would move with it, and the two are meant to be free
/// to disagree loudly.
///
/// The `switch` is exhaustive over a sealed class, so a new [PnpPhase] cannot be
/// added without a decision being recorded here — the compiler refuses. What it
/// does not force is a matching entry in [_phases] below, so a new phase can be
/// silently *untested*; it cannot be silently *decided*.
bool _blocksPop(PnpPhase phase) => switch (phase) {
      // The router is mid-flash.
      WizardUpdatingFirmware() => true,

      // The stage is committed and may be about to dispatch a flash — see the
      // header. This one is a race, not a screen.
      WizardCheckingFirmware() => true,

      // Everything else. The wizard is a flow a user is allowed to leave — the
      // troubleshooter branches off it, and the completion screen leads out of it.
      AdminCheckingInternet() => false,
      AdminInternetConnected() => false,
      AdminReadFailure() => false,
      NoInternet() => false,
      ModemRestartCountdown() => false,
      ModemRestartCheckingInternet() => false,
      IspSaving() => false,
      WizardInitializing() => false,
      WizardConfiguring() => false,
      WizardSaving() => false,
      WizardSaved() => false,
      WizardNeedsReconnect() => false,
      WizardTestingReconnect() => false,
      WizardWifiReady() => false,
      WizardError() => false,
    };

/// A config with no bands and nothing dirty. The guard never reads it — what is
/// being measured is which phase the wizard is in, not what is in the form.
const _emptyConfig = PnpWifiConfig(
  ssid: '',
  password: '',
  originalSsid: '',
  originalPassword: '',
);

/// One instance per phase, for the cases to run over.
const _phases = <PnpPhase>[
  AdminCheckingInternet(),
  AdminInternetConnected(),
  AdminReadFailure(code: 9998, detail: 'missing'),
  NoInternet(ssid: 'Linksys00123'),
  ModemRestartCountdown(remainingSeconds: 90),
  ModemRestartCheckingInternet(attemptCount: 3),
  IspSaving(step: IspSaveStep.saving),
  WizardInitializing(),
  WizardConfiguring(wifiConfig: _emptyConfig),
  WizardSaving(),
  WizardSaved(),
  WizardNeedsReconnect(newSsid: 'MyWiFi', newPassword: 'MyPass1234'),
  WizardTestingReconnect(attemptCount: 1, maxAttempts: 5),
  WizardCheckingFirmware(),
  WizardUpdatingFirmware(version: '1.0.17.220118'),
  WizardWifiReady(ssid: 'MyWiFi', password: 'MyPass1234'),
  WizardError(message: 'boom'),
];

void main() {
  /// Pushes the wizard on top of a root page with the phase pinned to [phase],
  /// and returns the router.
  ///
  /// A push, so that there is something to pop. `pnpConfig`'s path is relative,
  /// so it is hosted as a child of the stub root exactly as it is a child of
  /// `pnpRoute` in production.
  Future<GoRouter> pushWizard(WidgetTester tester, PnpPhase phase) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          name: 'pnp_exit_guard_root',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('PAGE:root')),
          ),
          routes: [_guardOnly(_realRoute(RouteNamed.pnpConfig))],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: pnpOverrides(PnpState(phase: phase)),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    router.pushNamed(RouteNamed.pnpConfig);
    await tester.pumpAndSettle();
    expect(find.text('PAGE:${RouteNamed.pnpConfig}'), findsOneWidget,
        reason: 'the push must land on the wizard before the pop is measured');
    return router;
  }

  /// Pops once and reports whether the wizard let go.
  Future<bool> popLeavesWizard(WidgetTester tester, GoRouter router) async {
    router.pop();
    // The guard runs in a microtask scheduled during the frame, so a single
    // `pump` can observe the page still mounted with the veto not yet decided.
    await tester.pumpAndSettle();
    return find.text('PAGE:${RouteNamed.pnpConfig}').evaluate().isEmpty;
  }

  group('#1553 PnP firmware exit guard', () {
    test('every phase in the oracle has a case to run', () {
      // The `switch` in `_blocksPop` is complete by the compiler; this is the
      // other half — that [_phases] holds one distinct phase per entry, so a
      // duplicate cannot stand in for a missing one.
      expect(_phases.map((p) => p.runtimeType).toSet().length, _phases.length);
      expect(_phases.where(_blocksPop), hasLength(2),
          reason:
              'the flash and the check that commits to it, and nothing else');
    });

    testWidgets('refuses to be popped while the router is being flashed',
        (tester) async {
      final router = await pushWizard(
          tester, const WizardUpdatingFirmware(version: '1.2'));

      expect(await popLeavesWizard(tester, router), isFalse,
          reason: 'a router being flashed mid-setup must not be left behind by '
              'a Back press — the wizard has to stay on screen');
      expect(find.text('PAGE:root'), findsNothing);
    });

    testWidgets('pops normally from the form', (tester) async {
      // The ordinary case, and the one that makes the guard a guard rather than a
      // trap: the wizard's own back arrow steps back through the form and then
      // out of it.
      final router = await pushWizard(
          tester, const WizardConfiguring(wifiConfig: _emptyConfig));

      expect(await popLeavesWizard(tester, router), isTrue);
      expect(find.text('PAGE:root'), findsOneWidget);
    });

    group('every phase', () {
      for (final phase in _phases) {
        final blocks = _blocksPop(phase);
        testWidgets(
            '${phase.runtimeType} ${blocks ? 'blocks' : 'allows'} a pop',
            (tester) async {
          final router = await pushWizard(tester, phase);
          expect(await popLeavesWizard(tester, router), !blocks);
        });
      }
    });
  });
}
