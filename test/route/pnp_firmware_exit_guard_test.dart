// The PnP wizard's exit guard — `/pnp/pnpConfig`'s `onExit` — by phase. It began
// as #1553's firmware lock (REQ-B2) and since #1511 P4 also refuses to leave
// while a save is in flight, and asks to log out while editing.
//
// A first-connection firmware update is locked: the router is being flashed and
// the wizard has not finished, so there is nowhere to go back to and nothing to
// go forward to. Three things enforce that, and this file measures one of them.
// The others: the shell's back policy (`pnpBackPolicy`), which turns a Back into
// a redirect to the step that saved, and `PnpFlowFrameView`'s firmware screen,
// which renders no button.

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
// WHY TWO FIRMWARE PHASES BLOCK AND NOT ONE. `WizardUpdatingFirmware` is the
// flash, and is what REQ-B2 names. `WizardCheckingFirmware` is here for a race
// rather than for a screen: leaving during the check would end the flow while
// `_checkFirmware` may still be about to write `WizardUpdatingFirmware` and
// dispatch a flash. The cost of refusing is a dead Back press during a spinner
// bounded at fifteen seconds; the cost of allowing it is a router being written
// to with the locked screen never shown. This was a review finding, not the first
// design.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
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
/// cannot start depending on the page — `PnpFlowFrameView` has its own tests, and
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
///
/// `null` for the one phase that asks instead of deciding: editing, where
/// leaving the setup is logging out (#1511 P4) — measured with the whole shell
/// in `pnp_wizard_route_test.dart`.
bool? _blocksPop(PnpPhase phase) => switch (phase) {
      // The router is mid-flash.
      WizardUpdatingFirmware() => true,

      // The stage is committed and may be about to dispatch a flash — see the
      // header. This one is a race, not a screen.
      WizardCheckingFirmware() => true,

      // In flight (#1511 P4, D7): a write or a reconnect is out, and leaving
      // would end the flow under it.
      WizardSaving() => true,
      WizardSaved() => true,
      WizardTestingReconnect() => true,
      WizardConfiguring() => null,

      // Everything else. The completion screen leads out of the wizard, and the
      // phases before it are the entry's. Your Network is past the save and the
      // acknowledge (#1511 P5): leaving it skips only the firmware offer.
      AdminCheckingInternet() => false,
      AdminInternetConnected() => false,
      AdminReadFailure() => false,
      NoInternet() => false,
      WizardInitializing() => false,
      WizardNeedsReconnect() => false,
      WizardYourNetwork() => false,
      WizardWifiReady() => false,
      WizardError() => false,
    };

/// One instance per phase, for the cases to run over.
const _phases = <PnpPhase>[
  AdminCheckingInternet(),
  AdminInternetConnected(),
  AdminReadFailure(code: 9998, detail: 'missing'),
  NoInternet(ssid: 'Linksys00123'),
  WizardInitializing(),
  WizardConfiguring(),
  WizardSaving(),
  WizardSaved(),
  WizardNeedsReconnect(newSsid: 'MyWiFi', newPassword: 'MyPass1234'),
  WizardTestingReconnect(attemptCount: 1, maxAttempts: 5),
  WizardYourNetwork(
      ready: WizardWifiReady(ssid: 'MyWiFi', password: 'MyPass1234')),
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
      expect(_phases.where((p) => _blocksPop(p) == true), hasLength(5),
          reason: 'the flash, the check that commits to it, and the three '
              'in-flight phases of the save (#1511 P4)');
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

    testWidgets('pops normally from the completion screen', (tester) async {
      // The ordinary case, and the one that makes the guard a guard rather than a
      // trap: the wizard is a flow the user leaves when it is done.
      final router = await pushWizard(tester,
          const WizardWifiReady(ssid: 'MyWiFi', password: 'MyPass1234'));

      expect(await popLeavesWizard(tester, router), isTrue);
      expect(find.text('PAGE:root'), findsOneWidget);
    });

    group('every phase', () {
      for (final phase in _phases) {
        final blocks = _blocksPop(phase);
        if (blocks == null) continue;
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
