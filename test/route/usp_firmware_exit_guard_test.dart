// The firmware pages' exit guard, behind linksys/PrivacyGUI#1549.
//
// #1549 gave one firmware install two entry points: the OTA page checks the
// cloud and flashes what it finds, the manual page uploads a file and flashes
// that. Both drive the same notifier, so "can I navigate away mid-flash" must
// not depend on which page happened to start the flash — and before this file
// nothing checked the guard on either page.
//
// THE CLOSURE UNDER TEST IS THE PRODUCTION ONE. Both routes are pulled out of
// the real `uspDashboardRoute` and re-hosted with a stub body, so `onExit` is
// the object `lib/route/route_usp_dashboard.dart` constructed, not a copy of
// its logic. Delete `onExit:` from a route and `LinksysRoute` still supplies a
// non-null wrapper — but that wrapper returns true, the pop succeeds, and the
// case for that route fails. Swapping the body for a stub is what keeps this
// file measuring the guard rather than the page: the pages have their own
// identifier tests, and pumping them here would let a provider change red a
// routing suite.
//
// WHICH VERBS REACH THE GUARD, since only one of the three does what it looks
// like (go_router 17.5.0, read out of `delegate.dart`):
//
//   - `pop`      -> `_handlePopPageWithRouteMatch` consults `onExit` and
//                   returns false to VETO the Navigator pop. This is the case
//                   the ticket is about, and the one measured below.
//   - `goNamed`  -> `setNewRoutePath` calls `onExit` for every match that is
//                   leaving. Also a real exit; not measured here, because the
//                   product has no `go` off these pages.
//   - `pushNamed`-> zero calls. The pushed-over route stays in the match list,
//                   so the guard is deferred, not skipped
//                   (`route_model.dart:50-54`). A test that "navigated away"
//                   with a push would pass no matter what the guard said.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/router_provider.dart';

import '../mocks/provider_overrides/mock_firmware_update.dart';

/// The connection state, pinned, without the real notifier's `build`.
///
/// [AppConnectionStateNotifier.build] wires an SSE manager and two listeners. It
/// happens to survive being mounted in a widget test — the cases that do not pass
/// a state below rely on that, and get `authenticated` from the real thing — but
/// nothing here wants to depend on it staying true for the two cases that are
/// *about* a particular state.
class _PinnedConnectionNotifier extends Notifier<AppConnectionState>
    implements AppConnectionStateNotifier {
  _PinnedConnectionNotifier(this._value);

  final AppConnectionState _value;

  @override
  AppConnectionState build() => _value;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The real `GoRoute` declared for [name], found by walking the real tree.
GoRoute _realRoute(String name) {
  GoRoute? found;
  void walk(RouteBase route) {
    if (route is GoRoute && route.name == name) found = route;
    route.routes.forEach(walk);
  }

  walk(uspDashboardRoute);
  if (found == null) {
    throw StateError('no route named $name in uspDashboardRoute');
  }
  return found!;
}

/// [route]'s own guard, re-hosted over a stub body.
///
/// `onExit` is passed through by reference. Everything else about the route is
/// replaced, so this cannot accidentally start depending on the page.
GoRoute _guardOnly(GoRoute route) => GoRoute(
      name: route.name,
      path: route.path,
      onExit: route.onExit,
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text('PAGE:${route.name}')),
      ),
    );

void main() {
  /// Pushes [routeName] on top of a root page, with the notifier pinned to
  /// [state], and returns the router.
  ///
  /// A push, so that there is something to pop: this is how both pages are
  /// really entered (`firmware-card-update` and `firmware-ota-card-check` both
  /// `pushNamed`), and a pop is the only exit a user can reach from the back
  /// arrow or the browser's Back button.
  ///
  /// [connection] pins `appConnectionStateProvider`. Left unset, the real
  /// notifier runs and reports `authenticated`, which is what every phase case
  /// wants — so those cases stay a measurement of the phase alone.
  Future<GoRouter> pushOnto(
    WidgetTester tester,
    String routeName, {
    required FirmwareUpdateState state,
    AppConnectionState? connection,
  }) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          name: 'exit_guard_root',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('PAGE:root')),
          ),
        ),
        _guardOnly(_realRoute(routeName)),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...firmwareUpdateOverrides(state: state),
          if (connection != null)
            appConnectionStateProvider
                .overrideWith(() => _PinnedConnectionNotifier(connection)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    router.pushNamed(routeName);
    await tester.pumpAndSettle();
    expect(find.text('PAGE:$routeName'), findsOneWidget,
        reason: 'the push must land on $routeName before the pop is measured');
    return router;
  }

  /// Pops once and reports whether the page let go.
  Future<bool> popLeavesPage(
      WidgetTester tester, GoRouter router, String routeName) async {
    router.pop();
    // The guard runs in a microtask scheduled during the frame, so a single
    // `pump` can observe the page still mounted with the veto not yet decided.
    await tester.pumpAndSettle();
    return find.text('PAGE:$routeName').evaluate().isEmpty;
  }

  // Both firmware routes, by name, so the parity #1549 promised is one case per
  // route rather than a claim in a comment. `uspFirmwareUpdate` is the manual
  // page the ticket says the new one behaves "same as".
  const guardedRoutes = <String>[
    RouteNamed.uspFirmwareUpdate,
    RouteNamed.uspFirmwareOta,
  ];

  group('#1549 firmware exit guard', () {
    for (final routeName in guardedRoutes) {
      testWidgets('$routeName refuses to be popped while an install is running',
          (tester) async {
        final router = await pushOnto(
          tester,
          routeName,
          state: const FirmwareUpdateState(
            phase: FirmwareUpdatePhase.installing,
          ),
        );

        expect(await popLeavesPage(tester, router, routeName), isFalse,
            reason: 'a router being flashed must not be left behind by a back '
                'press — the page has to stay on screen');
        expect(find.text('PAGE:root'), findsNothing);
      });

      testWidgets('$routeName pops normally when nothing is running',
          (tester) async {
        final router = await pushOnto(
          tester,
          routeName,
          // `idle` is where a user arrives and where every terminal phase
          // returns to, so this is the ordinary case, not an edge one.
          state: const FirmwareUpdateState(),
        );

        expect(await popLeavesPage(tester, router, routeName), isTrue,
            reason: 'the guard must only block during an install, or the page '
                'becomes a trap');
        expect(find.text('PAGE:root'), findsOneWidget);
      });
    }

    // `isUpdating` is a derived predicate over eleven phases, and the split put
    // its two halves on different pages: the OTA page owns `checkingOta`, the
    // manual page owns `picking`/`validating`/`uploading`, and the six install
    // phases are shared. A per-phase case is what makes "which page blocks
    // when" a measured fact instead of a reading of the enum.
    //
    // SPELLED OUT, not derived. `blocks` used to read
    // `FirmwareUpdateState(phase: phase).isUpdating` — the same predicate the
    // production guard reads — so oracle and subject moved together: widen
    // `isUpdating` by one phase and all 22 cases silently re-derive the new
    // answer and stay green while the app has started letting a user walk out
    // mid-flash. The list below is the product decision; `isUpdating` is one
    // implementation of it, and the two are now free to disagree loudly.
    const blockedIn = <FirmwareUpdatePhase>{
      FirmwareUpdatePhase.checkingOta,
      FirmwareUpdatePhase.picking,
      FirmwareUpdatePhase.validating,
      FirmwareUpdatePhase.uploading,
      FirmwareUpdatePhase.triggering,
      FirmwareUpdatePhase.installing,
      FirmwareUpdatePhase.rebooting,
      FirmwareUpdatePhase.verifying,
    };
    const allowedIn = <FirmwareUpdatePhase>{
      FirmwareUpdatePhase.idle,
      FirmwareUpdatePhase.done,
      FirmwareUpdatePhase.failed,
    };

    test('every phase is on exactly one side of the guard', () {
      // So that a twelfth phase cannot join the enum without a decision being
      // made here. Without this, a new phase would simply fall into `allowedIn`
      // by omission and get a passing "allows a pop" case for free.
      expect({...blockedIn, ...allowedIn}, FirmwareUpdatePhase.values.toSet());
      expect(blockedIn.intersection(allowedIn), isEmpty);
    });

    group('every phase, on both pages', () {
      for (final phase in FirmwareUpdatePhase.values) {
        final blocks = blockedIn.contains(phase);
        for (final routeName in guardedRoutes) {
          testWidgets(
              '$routeName in $phase ${blocks ? 'blocks' : 'allows'} a pop',
              (tester) async {
            final router = await pushOnto(tester, routeName,
                state: FirmwareUpdateState(phase: phase));
            expect(await popLeavesPage(tester, router, routeName), !blocks);
          });
        }
      }
    });

    // A sign-out is not a navigation to argue with: the router `go`es a
    // signed-out user to the login page, `go` consults `onExit` for every
    // leaving match, and a veto strands the app on a firmware page it has no
    // session to talk to until the install phase happens to end. The 22 cases
    // above are the control group for these two — they pass no `connection`, so
    // the real notifier answers `authenticated` and the phase alone decides.
    group('a session that has ended', () {
      for (final routeName in guardedRoutes) {
        testWidgets('$routeName lets go mid-install once signed out',
            (tester) async {
          final router = await pushOnto(
            tester,
            routeName,
            state: const FirmwareUpdateState(
              phase: FirmwareUpdatePhase.installing,
            ),
            connection: AppConnectionState.loggedOut,
          );

          expect(await popLeavesPage(tester, router, routeName), isTrue,
              reason: 'the install is still running, but there is no session '
                  'left to keep the user on this page for');
        });

        // The discriminator against writing `!= authenticated`. Recovery is the
        // state the app reaches *because* the router went away mid-flash, so
        // releasing on it would unlock the guard in exactly the situation it
        // exists for.
        testWidgets('$routeName still blocks while waiting for recovery',
            (tester) async {
          final router = await pushOnto(
            tester,
            routeName,
            state: const FirmwareUpdateState(
              phase: FirmwareUpdatePhase.installing,
            ),
            connection: AppConnectionState.waitingForRecovery,
          );

          expect(await popLeavesPage(tester, router, routeName), isFalse,
              reason: 'only a sign-out releases the guard, not any non-'
                  'authenticated state');
        });
      }
    });
  });
}
