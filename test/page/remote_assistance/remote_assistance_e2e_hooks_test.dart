// The E2E hooks the real-router Remote Assistance spec drives both ends by.
//
// THE CONTRACT GUARDED. `R30-remote-assistance` (linksys/PrivacyGUI-RealRouter-E2E)
// walks one real RA session with both ends on screen: the customer's dialog on the
// router's own app, and the agent's confirm page in our force=remote build. Before
// these hooks it could only do that by matching copy — "Waiting for agent...",
// "Session validated. Ready to connect." — which is unlocalized today and will not
// stay that way, and the PIN it has to carry from one end to the other was six
// separate digit nodes it could only reassemble by position (Article XVI).
//
// HOW IT COULD SILENTLY REVERT. The E2E repo harvests identifiers from this
// repo's source text, so every hook is asserted here as the literal its specs
// look for; a rename would otherwise turn into a count-0 timeout on the real
// router with nothing red here.
//
// The session-chip hooks (`ra-session-chip`, `ra-session-end`) are pinned in
// `test/page/_shared/components/remote_session_chip_widget_test.dart`, beside the
// harness that already mounts that chip.
//
// Not tagged `ui`: `run_tests.sh` excludes `golden||loc||ui`, so a tagged case
// would never run in CI.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_state.dart';
import 'package:privacy_gui/core/cloud/services/remote_assistance_service.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/framework/mode/session_request.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_domain_ready_provider.dart';
import 'package:privacy_gui/page/remote_assistance/views/remote_assistance_confirm_view.dart';
import 'package:privacy_gui/page/remote_assistance/views/remote_assistance_dialog.dart';
import 'package:privacy_gui/page/remote_assistance/views/remote_assistance_session_guard.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

import '../../golden_test/golden_framework/mocks/mock_remote_assistance.dart';
import '../../mocks/provider_overrides/mock_common.dart';
import '../../mocks/provider_overrides/mock_remote_assistance_confirm.dart';
import '../../mocks/test_data/remote_assistance_test_data.dart';
import '../../util/app_test_fonts.dart';

/// The `ra-client-state-*` suffix for each session status, WRITTEN OUT.
///
/// The dialog builds its hook from `status.name`, so a test that also built it
/// from `.name` would move with any rename and stay green while the spec, which
/// waits on these literals, timed out on the real router. Written out, a rename
/// turns the matching case red here; the `keys` check below catches a status
/// added without one.
const _clientStateFor = {
  GRASessionStatus.initiate: 'initiate',
  GRASessionStatus.pending: 'pending',
  GRASessionStatus.active: 'active',
  GRASessionStatus.invalid: 'invalid',
};

/// Every `ra-client-state-*` value the dialog can show: the four session
/// statuses, plus the two states before there is a session to report.
final _allClientStates = ['loading', 'error', ..._clientStateFor.values];

/// Every `ra-confirm-state-*` value the agent's confirm page can show, written
/// out for the same reason as [_clientStateFor]. A list rather than a table
/// keyed by the state because `_ViewState` is private to the view.
///
/// `idle` is listed so the one-at-a-time checks cover it, but no test drives it:
/// it lasts one frame. Validation is scheduled for right after the first frame,
/// and a link missing its session or token renders a separate view with no card
/// and so no state hook — so there is no `idle` a spec could wait on.
const _confirmStates = [
  'idle',
  'validating',
  'validated',
  'connecting',
  'error',
];

/// Exactly one confirm-state hook on screen, and it is [state].
void _expectOnlyConfirmState(String state) {
  expect(find.bySemanticsIdentifier('ra-confirm-state-$state'), findsOneWidget);
  for (final other in _confirmStates.where((s) => s != state)) {
    expect(find.bySemanticsIdentifier('ra-confirm-state-$other'), findsNothing,
        reason: 'only the current state may be on screen');
  }
}

/// `initiateRemoteAssistance` never completes, so the dialog stays on its
/// loading branch — the state between opening it and Guardian answering.
class _NeverStarts extends FixedRemoteClientNotifier {
  _NeverStarts() : super(const RemoteClientState());
  @override
  Future<void> initiateRemoteAssistance() => Completer<void>().future;
}

/// `initiateRemoteAssistance` fails the way a rejected device token does.
class _FailsToStart extends FixedRemoteClientNotifier {
  _FailsToStart() : super(const RemoteClientState());
  @override
  Future<void> initiateRemoteAssistance() async =>
      throw const UnauthorizedError();
}

/// Starts PENDING with a PIN, goes ACTIVE when told — the moment the agent's PIN
/// lands — and INVALID when told — the moment either end ends it. Restoring finds
/// nothing, so only the first transition can open the guard's dialog.
class _GoesActive extends FixedRemoteClientNotifier {
  _GoesActive()
      : super(RemoteClientState(
          sessionInfo: RemoteAssistanceTestData.sessionWithStatus(
              GRASessionStatus.pending),
          pin: RemoteAssistanceTestData.testPin,
          expiredCountdown: 1800,
        ));
  @override
  Future<bool> checkAndRestoreSession() async => false;
  void goActive() => state = state.copyWith(
      sessionInfo: () =>
          RemoteAssistanceTestData.sessionWithStatus(GRASessionStatus.active));
  void goInvalid() => state = state.copyWith(
      sessionInfo: () =>
          RemoteAssistanceTestData.sessionWithStatus(GRASessionStatus.invalid));
}

/// Session validation that never answers, so the confirm page stays on
/// `validating` — the state between opening the agent's link and Guardian
/// answering.
class _NeverAnswers extends Fake implements RemoteAssistanceService {
  @override
  Future<GRASessionInfo> fetchSessionInfoForCA({
    required String sessionToken,
    required String sessionId,
  }) =>
      Completer<GRASessionInfo>().future;
}

/// Opening the session fails, or never finishes — the two ways Connect can not
/// reach the dashboard. `build` stays the shared fixture's unauthenticated state.
///
/// The failure lands after a delay, as a real one does: `doSomethingWithSpinner`
/// only attaches its error handler once its own ~100 ms of setup has run, so a
/// future that is already failed by then is reported as unhandled.
class _ConnectFails extends AuthNotifier {
  _ConnectFails({this.hangs = false});
  final bool hangs;
  @override
  Future<AuthState> build() => Future.value(AuthState.empty());
  @override
  Future<void> openSession(SessionRequest request) => hangs
      ? Completer<void>().future
      : Future.delayed(const Duration(milliseconds: 500),
          () => throw const UnauthorizedError());
}

RemoteClientState _clientState(GRASessionStatus status, {String? pin}) =>
    RemoteClientState(
      sessionInfo: RemoteAssistanceTestData.sessionWithStatus(status),
      pin: pin,
      expiredCountdown: 1800,
    );

/// One route, because the confirm page is a full page: `UiKitPageView` reads the
/// `GoRouter` from context and throws without one. The dialogs do not need it,
/// and a router costs them nothing.
Widget _app({required List<Override> overrides, required Widget home}) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => Scaffold(body: home)),
  ]);
  return ProviderScope(
    overrides: [...commonOverrides(), ...overrides],
    child: MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
      routerConfig: router,
    ),
  );
}

/// Opens the live customer dialog the way the support page does, over a fixed
/// client state. `FixedRemoteClientNotifier` makes `initiateRemoteAssistance` a
/// no-op, so the dialog renders that state rather than calling Guardian.
Future<void> _openClientDialog(
    WidgetTester tester, RemoteClientState state) async {
  await tester.pumpWidget(_app(
    overrides: remoteAssistanceOverrides(state),
    home: Builder(
      builder: (context) => Consumer(
        builder: (context, ref, _) => TextButton(
          onPressed: () => showRemoteAssistanceDialog(context, ref,
              credentials: RemoteAssistanceTestData.credentials()),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  // Not pumpAndSettle: the active state's header icon animates forever.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('customer dialog — one state hook per session status', () {
    test('every session status has a written-out hook suffix', () {
      expect(_clientStateFor.keys, unorderedEquals(GRASessionStatus.values),
          reason: 'a new status needs its hook value written into the table');
    });

    for (final MapEntry(key: status, value: hook) in _clientStateFor.entries) {
      testWidgets('$status carries ra-client-state-$hook', (tester) async {
        final semantics = tester.ensureSemantics();
        await _openClientDialog(
          tester,
          _clientState(status, pin: RemoteAssistanceTestData.testPin),
        );

        expect(find.bySemanticsIdentifier('ra-client-state-$hook'),
            findsOneWidget);
        // Exactly one state hook at a time — loading and error included — or the
        // spec's "wait for the next state" could be satisfied by a stale one.
        for (final other in _allClientStates.where((s) => s != hook)) {
          expect(find.bySemanticsIdentifier('ra-client-state-$other'),
              findsNothing,
              reason: 'only the current state may be on screen');
        }
        semantics.dispose();
      });
    }
  });

  group('customer dialog — the two states before there is a session', () {
    Future<void> openWith(WidgetTester tester, RemoteClientNotifier n) async {
      await tester.pumpWidget(_app(
        overrides: [remoteClientProvider.overrideWith(() => n)],
        home: Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () => showRemoteAssistanceDialog(context, ref,
                credentials: RemoteAssistanceTestData.credentials()),
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('waiting on Guardian carries ra-client-state-loading',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await openWith(tester, _NeverStarts());

      expect(find.bySemanticsIdentifier('ra-client-state-loading'),
          findsOneWidget);
      for (final other in _allClientStates.where((s) => s != 'loading')) {
        expect(
            find.bySemanticsIdentifier('ra-client-state-$other'), findsNothing);
      }
      semantics.dispose();
    });

    testWidgets('failing to start carries ra-client-state-error',
        (tester) async {
      // The reason this hook exists: a dialog that could not start used to show
      // no state hook at all, so a spec waiting for `initiate` could only time
      // out — never say "the dialog reported an error".
      final semantics = tester.ensureSemantics();
      await openWith(tester, _FailsToStart());

      expect(
          find.bySemanticsIdentifier('ra-client-state-error'), findsOneWidget);
      for (final other in _allClientStates.where((s) => s != 'error')) {
        expect(
            find.bySemanticsIdentifier('ra-client-state-$other'), findsNothing);
      }
      semantics.dispose();
    });
  });

  group('customer dialog — the PIN, as one readable node', () {
    testWidgets('the hook\'s label is exactly the whole PIN', (tester) async {
      // What the spec reads and types into the agent portal. Six separate digit
      // nodes would leave it reassembling the PIN by position.
      final semantics = tester.ensureSemantics();
      await _openClientDialog(
        tester,
        _clientState(GRASessionStatus.pending,
            pin: RemoteAssistanceTestData.testPin),
      );

      expect(
        tester.getSemantics(find.bySemanticsIdentifier('ra-client-pin')),
        isSemantics(label: RemoteAssistanceTestData.testPin),
      );
      semantics.dispose();
    });

    testWidgets('the PIN node is a leaf, so the PIN is all it says',
        (tester) async {
      // What `excludeSemantics` buys, measured rather than assumed. Without it the
      // label still reads `123456` — the digit texts merge upward either way — but
      // the node keeps a child: the tile's own node, carrying the six digits again
      // and the copy action. That child is a second thing for a screen reader to
      // land on and for a spec to find under the hook. As a leaf, the PIN is the
      // node's only content.
      final semantics = tester.ensureSemantics();
      await _openClientDialog(
        tester,
        _clientState(GRASessionStatus.pending,
            pin: RemoteAssistanceTestData.testPin),
      );

      final node =
          tester.getSemantics(find.bySemanticsIdentifier('ra-client-pin'));
      expect(node.childrenCount, 0,
          reason: 'nothing may sit under the PIN node');
      semantics.dispose();
    });

    testWidgets('copying the PIN is still offered to assistive technology',
        (tester) async {
      // `excludeSemantics` also drops the InkWell's tap action — the only way a
      // screen-reader user could copy. The hook restates it; this pins that.
      final semantics = tester.ensureSemantics();
      await _openClientDialog(
        tester,
        _clientState(GRASessionStatus.pending,
            pin: RemoteAssistanceTestData.testPin),
      );

      expect(
        tester.getSemantics(find.bySemanticsIdentifier('ra-client-pin')),
        isSemantics(isButton: true, hasTapAction: true),
      );
      semantics.dispose();
    });

    testWidgets('no PIN hook while the PIN is still being generated',
        (tester) async {
      // An empty hook would let the spec read "" as a PIN.
      final semantics = tester.ensureSemantics();
      await _openClientDialog(tester, _clientState(GRASessionStatus.pending));

      expect(find.bySemanticsIdentifier('ra-client-pin'), findsNothing);
      semantics.dispose();
    });
  });

  group('customer dialog — End Session', () {
    testWidgets('the live dialog\'s button carries ra-client-end-session',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await _openClientDialog(tester, _clientState(GRASessionStatus.active));

      expect(
          find.bySemanticsIdentifier('ra-client-end-session'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('the restored-session dialog uses the same hooks',
        (tester) async {
      // `RemoteAssistanceSessionGuard` shows this one whenever the session is
      // ACTIVE — after a reload, and also over a live dialog that has just been
      // connected (see the stacking test below). A spec must find the same
      // identifiers on it, or it needs a second set for the same screen.
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app(
        overrides:
            remoteAssistanceOverrides(_clientState(GRASessionStatus.active)),
        home: const RemoteAssistanceActiveDialog(),
      ));
      await tester.pump();

      expect(
          find.bySemanticsIdentifier('ra-client-state-active'), findsOneWidget);
      expect(
          find.bySemanticsIdentifier('ra-client-end-session'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('customer dialogs stacked — the hooks still name one node', () {
    // On R30's own path the customer has the live dialog open on the support
    // page; when the agent's PIN lands, the shared session turns ACTIVE and the
    // guard opens the restored-session dialog OVER it. Both carry the same
    // hooks. They do not collide because a covered route drops out of the
    // semantics tree — which is also the tree the web projects for Playwright —
    // so each hook resolves to the dialog on top. Pinned, because if a future
    // change made the lower dialog's semantics visible, every one of these hooks
    // would match twice and a strict locator in the spec would fail.

    /// The live dialog open under the guard, then the session turned ACTIVE so
    /// the guard has opened the restored dialog over it.
    Future<_GoesActive> openBothDialogs(WidgetTester tester) async {
      late _GoesActive notifier;
      await tester.pumpWidget(_app(
        overrides: [
          remoteClientProvider.overrideWith(() => notifier = _GoesActive()),
          // loading, then a value: the transition the guard waits for before it
          // will show anything.
          dashboardDomainReadyProvider.overrideWith((ref) async =>
              Future<void>.delayed(const Duration(milliseconds: 10))),
        ],
        home: RemoteAssistanceSessionGuard(
          child: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => showRemoteAssistanceDialog(context, ref,
                  credentials: RemoteAssistanceTestData.credentials()),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      notifier.goActive();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsNWidgets(2),
          reason: 'the premise: the guard did open a second dialog');
      return notifier;
    }

    testWidgets(
        'both open, one node per hook; closing the top restores the '
        'one below', (tester) async {
      final semantics = tester.ensureSemantics();
      await openBothDialogs(tester);

      expect(
          find.bySemanticsIdentifier('ra-client-state-active'), findsOneWidget);
      expect(
          find.bySemanticsIdentifier('ra-client-end-session'), findsOneWidget);

      Navigator.of(tester.element(find.byType(AlertDialog).last)).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
          find.bySemanticsIdentifier('ra-client-end-session'), findsOneWidget,
          reason: 'the live dialog underneath is reachable again');
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
        'when the session ends, the top dialog closes itself and the live '
        'one shows ra-client-state-invalid', (tester) async {
      // R30's last customer-side wait. The restored dialog pops itself on the
      // transition to INVALID, so the `invalid` hook the spec waits for is the
      // LIVE dialog's, uncovered — not the restored dialog's own `invalid`
      // branch, which only renders when it is opened on an already-ended session.
      final semantics = tester.ensureSemantics();
      final notifier = await openBothDialogs(tester);

      notifier.goInvalid();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsOneWidget,
          reason: 'the restored dialog closes itself on INVALID');
      expect(find.bySemanticsIdentifier('ra-client-state-invalid'),
          findsOneWidget);
      for (final other in _allClientStates.where((s) => s != 'invalid')) {
        expect(
            find.bySemanticsIdentifier('ra-client-state-$other'), findsNothing);
      }
      expect(find.bySemanticsIdentifier('ra-client-end-session'), findsNothing,
          reason: 'nothing left to end');
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('agent confirm page', () {
    // The app's fonts and a desktop viewport, because the default test font is a
    // fixed-width box per glyph: under it the ACTIVE card's `Session validated`
    // row overflows at every width up to 1440, and with the real fonts it fits at
    // 1280 — measured. Nothing here asserts layout; this only keeps a harness
    // artifact from being reported as an exception.
    setUpAll(loadAppFonts);

    Future<void> pumpConfirm(
      WidgetTester tester,
      GRASessionInfo info, {
      List<Override> overrides = const [],
    }) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(
        overrides: [
          ...remoteAssistanceConfirmOverrides(sessionInfo: info),
          ...overrides,
        ],
        home: const RemoteAssistanceConfirmView(
          sessionId: RemoteAssistanceTestData.testSessionId,
          token: RemoteAssistanceTestData.testSessionToken,
        ),
      ));
      // initState schedules validation for after the first frame; one pump runs
      // it, a second lands the service's answer.
      await tester.pump();
      await tester.pump();
    }

    /// Taps Connect and runs the clock past `doSomethingWithSpinner`'s setup
    /// (~100 ms) and [_ConnectFails]'s 500 ms, so `openSession` has been called
    /// and, for a failure, answered. Not pumpAndSettle: the spinner dialog's
    /// message stream is periodic.
    Future<void> tapConnect(WidgetTester tester) async {
      await tester.tap(find.bySemanticsIdentifier('ra-confirm-connect'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
    }

    testWidgets('while Guardian is answering: ra-confirm-state-validating',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpConfirm(tester, RemoteAssistanceTestData.activeSession(),
          overrides: [
            remoteAssistanceServiceProvider.overrideWithValue(_NeverAnswers()),
          ]);

      _expectOnlyConfirmState('validating');
      semantics.dispose();
      // The view gives validation 15 s; run past it so the timer is not left
      // pending, which the binding reports as a failure.
      await tester.pump(const Duration(seconds: 16));
    });

    testWidgets(
        'an ACTIVE session lands on ra-confirm-state-validated, with '
        'the Connect hook', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpConfirm(tester, RemoteAssistanceTestData.activeSession());

      _expectOnlyConfirmState('validated');
      expect(find.bySemanticsIdentifier('ra-confirm-connect'), findsOneWidget);
      expect(
          find.bySemanticsIdentifier('ra-confirm-error-message'), findsNothing,
          reason: 'a clean validation shows no error box');
      semantics.dispose();
      // ACTIVE starts the view's one-second countdown; unmount so the binding's
      // pending-timer check does not fail the test.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('while the session opens: ra-confirm-state-connecting',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpConfirm(tester, RemoteAssistanceTestData.activeSession(),
          overrides: [
            authProvider.overrideWith(() => _ConnectFails(hangs: true)),
          ]);

      await tapConnect(tester);

      _expectOnlyConfirmState('connecting');
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
        'a failed Connect shows ra-confirm-error-message while the state '
        'stays validated', (tester) async {
      // The reason the error box has its own hook. The card's state goes back to
      // `validated`, which is also what it read before Connect — so without this
      // a spec waiting for the dashboard could only time out, never report the
      // message on screen.
      final semantics = tester.ensureSemantics();
      await pumpConfirm(tester, RemoteAssistanceTestData.activeSession(),
          overrides: [authProvider.overrideWith(() => _ConnectFails())]);
      expect(
          find.bySemanticsIdentifier('ra-confirm-error-message'), findsNothing,
          reason: 'the premise: no error box before Connect');

      await tapConnect(tester);

      _expectOnlyConfirmState('validated');
      expect(find.bySemanticsIdentifier('ra-confirm-error-message'),
          findsOneWidget);
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
        'a session that is not ACTIVE lands on ra-confirm-state-error, '
        'with no Connect hook', (tester) async {
      // The spec must be able to tell "not connectable" from "still validating".
      final semantics = tester.ensureSemantics();
      await pumpConfirm(tester, RemoteAssistanceTestData.pendingSession());

      _expectOnlyConfirmState('error');
      expect(find.bySemanticsIdentifier('ra-confirm-connect'), findsNothing);
      expect(find.bySemanticsIdentifier('ra-confirm-error-message'),
          findsOneWidget,
          reason:
              'every error path shows the same box, so it carries the hook');
      semantics.dispose();
    });

    testWidgets('the ended surface carries ra-confirm-ended', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app(
        overrides: remoteAssistanceConfirmOverrides(
            sessionInfo: RemoteAssistanceTestData.activeSession()),
        home: const RemoteAssistanceConfirmView(
          sessionId: '',
          token: '',
          sessionEnded: true,
        ),
      ));
      await tester.pump();

      expect(find.bySemanticsIdentifier('ra-confirm-ended'), findsOneWidget);
      semantics.dispose();
    });
  });
}
