// #1323 phase 5: the acting half of "lib/core/ reports, the page layer ends the
// session".
//
// `AppConnectionStateNotifier`'s three exits — the manual one, a router back from
// a factory reset, a router back with a different serial — each used to finish with
// `ref.read(authProvider.notifier).logout()`. They now set a state and an
// `EndCause` and stop, and `endSessionIfCoreReportedOne` is the single consumer
// that turns that into a sign-out.
//
// WHY THE SUBSCRIPTION IS TESTED HERE AND NOT IN THE SHELL. `UspDashboardShell`
// needs the router, the SSE stack, the dashboard's domain-ready gate, the mascot
// controller and the theme-studio config before it renders a frame — the position
// `surface_consumers_test.dart` already takes, in its own words, is that standing
// all of that up "would produce a test whose failures are almost never about" the
// thing under test.
//
// Round 2 of this PR's review found what that split cost: every test below used to
// call the verb by hand, so *nothing* exercised the `listenManual` that makes it
// run. Measured — deleting the three lines from the shell's `initState` left all
// fourteen tests over this file and the census green while disabling every
// automatic exit from a dead session. The fix was to give the wiring a name of its
// own, `listenForCoreSessionExit`, which is a function taking a `WidgetRef` rather
// than three lines inside a `State`. So the last two groups here pump a nine-line
// `ConsumerStatefulWidget` and drive real state transitions through the real
// subscription, and the shell is left holding only the one call the census pins.
//
// The remaining join to the shell is still a census, not trust:
// `session_teardown_call_sites_test.dart` asserts that `takePendingSessionExit` has
// exactly one consumer in `lib/`, that `listenForCoreSessionExit` is defined in one
// file and called from exactly one other, and that the other is the shell.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/components/session/session_exit_sink.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/connection/services/recovery_probe_service.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:privacy_gui/core/usp/services/sse_manager.dart';
import 'package:privacy_gui/framework/mode/session_end.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

import '../../mocks/test_data/auth_test_data.dart';

class MockSseManager extends Mock implements SseManager {
  // The production notifier assigns this in `build()`. A plain `Mock` would record
  // the setter, which is harmless, but the field is what the reconnect path reads
  // back and leaving it unimplemented makes the mock's behaviour depend on
  // mocktail's setter handling rather than on this test.
  @override
  set onReconnectFailed(void Function(int)? callback) {}
}

class MockAuthNotifier extends AsyncNotifier<AuthState>
    with Mock
    implements AuthNotifier {
  @override
  Future<AuthState> build() async => AuthTestData.loggedIn();

  /// Push a new auth state, the way a real login or a hint refresh does.
  ///
  /// The only way to reach `AppConnectionStateNotifier`'s `authProvider` listener
  /// from a test: it is `ref.listen`, so it fires on an auth *transition* and there
  /// is nothing else to call.
  void emit(AuthState next) => state = AsyncData(next);
}

/// An auth notifier that writes its state the way the real one does.
///
/// Not a convenience: [MockAuthNotifier] stubs `logout` to `async {}`, so it never
/// performs `AuthNotifier.logout`'s **first statement** —
/// `state = const AsyncValue.loading()`. That statement is the whole hazard round 3
/// found, which means a mock of the funnel cannot see a defect that lives in the
/// funnel's body, no matter what the surrounding widget tree looks like. Measured
/// both ways against the unfixed code: with the stubbed mock nothing raises; with
/// this notifier it raises every time.
///
/// Kept to the one statement under test rather than mirroring the whole method. The
/// rest of `logout()` — the mode teardown, SSE disconnect, credential clearing — is
/// tested where it lives and would need the entire session stack here.
class SyncWritingAuthNotifier extends AsyncNotifier<AuthState>
    implements AuthNotifier {
  final List<EndCause> logoutCauses = [];

  @override
  Future<AuthState> build() async => AuthTestData.loggedIn();

  @override
  Future logout({EndCause cause = EndCause.sessionLost}) async {
    logoutCauses.add(cause);
    state = const AsyncValue.loading();
    state = AsyncData(AuthTestData.loggedOut());
  }

  // Everything else on `AuthNotifier` is out of this fake's scope; reaching it is a
  // test-authoring mistake and should say so rather than return null.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockRecoveryProbeService extends Mock implements RecoveryProbeService {}

/// The smallest thing that wires the sink the way the shell does.
///
/// A `ConsumerStatefulWidget` rather than a `Consumer`, because the subscription is
/// what is under test and `ref.listenManual` needs a `State` to be disposed with —
/// which is also the property the "unmounted" test below turns into a claim.
class _SubscribesToCoreSessionExit extends ConsumerStatefulWidget {
  const _SubscribesToCoreSessionExit();

  @override
  ConsumerState<_SubscribesToCoreSessionExit> createState() =>
      _SubscribesToCoreSessionExitState();
}

class _SubscribesToCoreSessionExitState
    extends ConsumerState<_SubscribesToCoreSessionExit> {
  @override
  void initState() {
    super.initState();
    listenForCoreSessionExit(ref);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  late MockAuthNotifier auth;
  late MockSseManager sse;
  late MockRecoveryProbeService probe;
  late List<Override> overrides;
  late List<Override> overridesWithoutAuth;

  setUpAll(() {
    // Only the type is used by `any(named: 'cause')`; the value never reaches an
    // argument. Without it mocktail throws from inside the verification and leaves
    // its matcher stack dirty, which breaks later stubbing in the same file rather
    // than failing where the mistake is.
    registerFallbackValue(EndCause.sessionLost);
  });

  setUp(() {
    auth = MockAuthNotifier();
    sse = MockSseManager();
    probe = MockRecoveryProbeService();
    when(() => auth.logout(cause: any(named: 'cause')))
        .thenAnswer((_) async {});
    when(() => sse.disconnect()).thenAnswer((_) async {});
    // Built once per test and reused by every `pumpScope` call in it. Identity
    // matters: the catch-up test pumps twice and needs the second pump to keep the
    // first pump's container, so that the cause decided between them is the same
    // notifier's.
    //
    // Split at the auth override because one test needs a different auth notifier
    // and the same everything-else — see [SyncWritingAuthNotifier].
    overridesWithoutAuth = [
      sseManagerProvider.overrideWithValue(sse),
      recoveryProbeServiceProvider.overrideWithValue(probe),
      sseConnectionStateProvider.overrideWith(
        (ref) => Stream.value(SseConnectionState.connected),
      ),
    ];
    overrides = [
      authProvider.overrideWith(() => auth),
      ...overridesWithoutAuth,
    ];
  });

  /// Pumps [child] under the shared scope and hands back its container.
  ///
  /// Builds the connection notifier and settles one frame before returning, so that
  /// `MockAuthNotifier.build` — which is `async`, and so resolves `authProvider`
  /// loading → data on a microtask — has landed before a test plants anything. Only
  /// determinism now: this used to be load-bearing, because a resolution that landed
  /// *after* a planted cause hit the promotion arm and cleared it, and every test in
  /// the file was one microtask away from measuring that instead of its own claim.
  /// Round 3 pointed out that a precondition a helper can arrange is not a
  /// precondition production has, and the arm is fixed rather than tiptoed around.
  /// The two tests that hold it are in `app_connection_state_provider_test.dart`:
  /// `a logged-in auth event does not un-decide a reported exit`, and
  /// `a cause planted while auth is still resolving survives it`, which reproduces
  /// exactly the ordering this helper arranges away.
  Future<ProviderContainer> pumpScope(
    WidgetTester tester,
    Widget child,
  ) async {
    await tester.pumpWidget(ProviderScope(overrides: overrides, child: child));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SizedBox)),
    );
    container.read(appConnectionStateProvider.notifier);
    await tester.pump();
    return container;
  }

  /// Pumps the smallest widget that can hand a real [WidgetRef] to the verb, and
  /// returns a callback that invokes it directly.
  ///
  /// Direct invocation is the right instrument for the read-and-clear group: the
  /// claim there is about calling the function twice, which a state transition
  /// cannot express. The subscription is covered by its own group below.
  Future<void Function()> pumpSink(WidgetTester tester) async {
    late WidgetRef captured;
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: Consumer(
          builder: (context, ref, _) {
            captured = ref;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return () => endSessionIfCoreReportedOne(captured);
  }

  group('the verb, called directly', () {
    testWidgets(
        'a reported userRequested exit ends the session with that cause',
        (tester) async {
      final sink = await pumpSink(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SizedBox)),
      );
      container.read(appConnectionStateProvider.notifier).exitToLogout();

      sink();

      verify(() => auth.logout(cause: EndCause.userRequested)).called(1);
    });

    testWidgets('nothing reported means no sign-out', (tester) async {
      final sink = await pumpSink(tester);

      sink();

      verifyNever(() => auth.logout(cause: any(named: 'cause')));
      verifyNever(() => auth.logout());
    });

    testWidgets('a reported exit is acted on exactly once', (tester) async {
      // The property that lets the subscription call this on every transition into
      // `loggedOut` without a flag of its own. `logout()` is not idempotent from
      // the user's side in Remote Assistance: `EndCause.userRequested` reaches
      // `endSessionForCA`, so a second pass is a second Guardian call for a session
      // that has already been closed.
      final sink = await pumpSink(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SizedBox)),
      );
      container.read(appConnectionStateProvider.notifier).exitToLogout();

      sink();
      sink();

      verify(() => auth.logout(cause: EndCause.userRequested)).called(1);
    });

    testWidgets('a failing sign-out does not surface as an unhandled error',
        (tester) async {
      // Round 3's other finding on this verb: the `Future` was dropped. Neither
      // call site can await — one is a Riverpod listener, the other a post-frame
      // callback — so the future stays unawaited on purpose; what it must not do is
      // reject into the zone, which in a real build is an uncaught async error and
      // here would be a failure attributed to whichever test happened to be running
      // when the microtask landed.
      //
      // `thenAnswer` returning a rejected future rather than `thenThrow`, which
      // would make the *call* throw synchronously and never reach `onError` — a
      // different defect, and not the one the fix is about.
      when(() => auth.logout(cause: any(named: 'cause')))
          .thenAnswer((_) => Future.error(Exception('logout failed')));

      final sink = await pumpSink(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SizedBox)),
      );
      container.read(appConnectionStateProvider.notifier).exitToLogout();

      sink();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('the subscription, driven by real transitions', () {
    testWidgets('a manual exit signs out without anyone calling the verb',
        (tester) async {
      // The test round 2 asked for. Nothing here touches
      // `endSessionIfCoreReportedOne`: the notifier decides, `listenManual`
      // notices, and `logout` is the observable consequence. Deleting the
      // `listenForCoreSessionExit(ref)` line out of the widget above reds this.
      final container =
          await pumpScope(tester, const _SubscribesToCoreSessionExit());

      container.read(appConnectionStateProvider.notifier).exitToLogout();
      await tester.pump();

      verify(() => auth.logout(cause: EndCause.userRequested)).called(1);
    });

    testWidgets('a second report inside the sign-out window does not double up',
        (tester) async {
      // `logout()` is async and deliberately not awaited, so there is a window
      // between the report being consumed and auth publishing `LoginType.none`.
      // Round 3 asked what a second exit decided inside that window does, and the
      // answer had no test: in Remote Assistance a second
      // `logout(cause: userRequested)` reaches `endSessionForCA` again, against a
      // Guardian session the first call has already closed.
      //
      // Two existing properties make it safe and neither is a flag, which is why no
      // `_signingOut` guard was added. The read is destructive; and Riverpod does not
      // notify when an enum state is reassigned its current value, so the second
      // `exitToLogout()` — with the state already `loggedOut` — produces no
      // transition for the subscription to see. The cause it sets is left for the
      // catch-up read, the same path as a report decided with nothing mounted.
      //
      // Which of the two this actually pins, measured rather than assumed: making
      // the read non-destructive leaves it green, because the second report never
      // reaches the listener either way. What reds it is `exitToLogout` gaining a
      // notification — `state = authenticated` before the assignment, the shape a
      // "reset, then decide" refactor produces — at which point the second report
      // does reach the listener and does sign out twice.
      final gate = Completer<void>();
      when(() => auth.logout(cause: any(named: 'cause')))
          .thenAnswer((_) => gate.future);

      final container =
          await pumpScope(tester, const _SubscribesToCoreSessionExit());
      final notifier = container.read(appConnectionStateProvider.notifier);

      notifier.exitToLogout();
      await tester.pump();
      verify(() => auth.logout(cause: EndCause.userRequested)).called(1);

      // Still inside the window: the gate is uncompleted, so `logout()` has not
      // returned.
      notifier.exitToLogout();
      await tester.pump();
      verifyNever(() => auth.logout(cause: any(named: 'cause')));

      gate.complete();
      await tester.pumpAndSettle();
      verifyNever(() => auth.logout(cause: any(named: 'cause')));
    });

    testWidgets('a serial mismatch signs out as sessionLost', (tester) async {
      // Driven through the real probe path rather than by setting the cause by
      // hand, because the pairing is the claim: the cause the core decides is the
      // cause the sign-out gets. `sessionLost` is also the load-bearing half in
      // Remote Assistance — it is what stops `RemoteSessionStrategy.end` from
      // asking Guardian to close a session against a router that never had it.
      when(() => probe.probe(healthOnly: any(named: 'healthOnly')))
          .thenAnswer((_) async => ProbeResult.serialMismatch);

      final container =
          await pumpScope(tester, const _SubscribesToCoreSessionExit());
      container.read(appConnectionStateProvider.notifier).enterWaiting(
            context: RecoveryContext(
              trigger: RecoveryTrigger.operationalReboot,
              cooldown: Duration.zero,
            ),
          );
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.loggedOut,
      );
      verify(() => auth.logout(cause: EndCause.sessionLost)).called(1);
    });

    testWidgets('an exit decided with nothing mounted is acted on at wiring',
        (tester) async {
      // Why `listenForCoreSessionExit` reads once *before* it starts listening.
      //
      // The subscription lives in a `State`, so it is gone while the shell is
      // unmounted — and two of the three exits are resolved by a `Timer.periodic`
      // on an app-lifetime notifier, whose two reporters are documented as not
      // autoDispose. So "the trigger came from a /usp* page" does not put a
      // consumer on screen when the probe answers. Without the catch-up read that
      // report is lost for good: `takePendingSessionExit` is only reachable from
      // the subscription, and reassigning `loggedOut` its current value produces no
      // second transition to key off.
      //
      // The two pumps share one `overrides` list so they share one container, which
      // is what makes the cause decided between them the same notifier's. Asserted,
      // not assumed.
      final before = await pumpScope(tester, const SizedBox.shrink());
      before.read(appConnectionStateProvider.notifier).exitToLogout();
      await tester.pump();
      verifyNever(() => auth.logout(cause: any(named: 'cause')));

      final after =
          await pumpScope(tester, const _SubscribesToCoreSessionExit());
      expect(after, same(before),
          reason: 'the second pump replaced the ProviderScope, so this test is '
              'measuring two unrelated notifiers rather than a stranded cause');

      verify(() => auth.logout(cause: EndCause.userRequested)).called(1);
    });

    testWidgets('an unread cause survives an auth event that is not a re-login',
        (tester) async {
      // The other half of the same field's lifetime, end to end. Round 2 asked what
      // becomes of a cause that is never read; the answer this test pinned was
      // "both arms of the `authProvider` listener clear it", and round 3 found that
      // the second arm clearing it is itself the defect.
      //
      // The reason that arm is reachable at all is the stranded case: `lib/core/` no
      // longer signs anyone out, so an exit decided with no consumer mounted leaves
      // the connection state at `loggedOut` while auth still holds a session. Auth
      // therefore never passes through `LoginType.none`, and any later auth
      // emission — here a password-hint refresh — lands on the promotion arm with
      // the cause still set. Nothing in arm one has run, so nothing else has decided
      // this report is stale; clearing it there sent the person back to
      // `authenticated` on a session the core had given up on, and dropped the only
      // record of why.
      //
      // Asserted through the sink rather than on the field, because the consequence
      // is the claim: the next `/usp*` page to mount still signs out, with the cause
      // the core originally decided.
      final container = await pumpScope(tester, const SizedBox.shrink());
      container.read(appConnectionStateProvider.notifier).exitToLogout();
      await tester.pump();
      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.loggedOut,
      );

      auth.emit(AuthTestData.loggedInAgain('still signed in'));
      await tester.pump();
      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.loggedOut,
        reason:
            'the promotion arm un-decided an exit the core had reported, so '
            'the rest of this test is measuring a cause that is already gone',
      );
      verifyNever(() => auth.logout(cause: any(named: 'cause')));

      final after =
          await pumpScope(tester, const _SubscribesToCoreSessionExit());
      expect(after, same(container));

      verify(() => auth.logout(cause: EndCause.userRequested)).called(1);
    });
  });

  // Round 3's Critical, confirmed by measurement rather than by argument.
  //
  // The catch-up read is reached from `initState`, so it used to run *during* the
  // build pass, and `AuthNotifier.logout`'s first statement is
  // `state = const AsyncValue.loading()`. `AuthNotifier.init` already carries a
  // comment saying that exact shape "would trigger provider notifications that cause
  // a !_dirty assertion in ProviderScope" and is written to avoid it; the catch-up
  // read was the first `initState`-time path to `logout()` in the app, so it
  // reintroduced a hazard the class had documented. The fix defers only that one
  // read by a frame, leaving the listener synchronous.
  //
  // WHY THIS IS A NEW NOTIFIER AND NOT A NEW `expect`. What made the existing five
  // subscription tests blind is [MockAuthNotifier]: `logout` is stubbed to
  // `async {}`, so it never performs the write that *is* the hazard. Measured — with
  // the fix reverted and everything below unchanged except the notifier, this test
  // passes. A mock of the funnel cannot see a defect in the funnel's body, and no
  // amount of arranging the widget tree around it helps.
  //
  // AND WHY THERE IS NO SIBLING `Consumer` HERE, which round 3 also asked for. Its
  // reasoning was that a provider write during build only raises if something
  // depends on the provider. Measured against the unfixed code, three ways: with no
  // watcher it raises `framework.dart:5551 '!_dirty': is not true` — the assertion
  // `AuthNotifier.init`'s comment names by hand — and with a `Consumer` watching
  // `authProvider` beside the wiring it raises *nothing*, whether that sibling mounts
  // in the same pump or survives from the previous one. So the watcher is not what
  // makes this visible; adding it would have shipped a test with no failing mode.
  group('the catch-up read runs after the build pass', () {
    testWidgets('a stranded cause signs out without tripping the build pass',
        (tester) async {
      final syncAuth = SyncWritingAuthNotifier();
      final scopeOverrides = [
        authProvider.overrideWith(() => syncAuth),
        ...overridesWithoutAuth,
      ];

      // Strand a cause with the wiring absent, the same setup as the catch-up test
      // above — that is the only way to reach the read at all.
      await tester.pumpWidget(ProviderScope(
        overrides: scopeOverrides,
        child: const SizedBox.shrink(),
      ));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SizedBox)),
      );
      // Built and settled *before* the cause is planted, for the reason `pumpScope`
      // documents: `build()` is async, and an auth resolution landing after the
      // cause reaches the promotion arm, which clears it.
      container.read(appConnectionStateProvider.notifier);
      await tester.pump();

      container.read(appConnectionStateProvider.notifier).exitToLogout();
      await tester.pump();
      expect(syncAuth.logoutCauses, isEmpty,
          reason:
              'the wiring was absent, so there is no stranded cause here and '
              'this test would be measuring an ordinary transition');

      await tester.pumpWidget(ProviderScope(
        overrides: scopeOverrides,
        child: const _SubscribesToCoreSessionExit(),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(syncAuth.logoutCauses, [EndCause.userRequested],
          reason: 'deferring the read must not lose it');
    });
  });
}
