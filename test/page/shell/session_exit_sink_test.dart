// #1323 phase 5: the acting half of "lib/core/ reports, the page layer ends the
// session".
//
// `AppConnectionStateNotifier`'s three exits — the manual one, a router back from
// a factory reset, a router back with a different serial — each used to finish with
// `ref.read(authProvider.notifier).logout()`. They now set a state and an
// `EndCause` and stop, and `endSessionIfCoreReportedOne` is the single consumer
// that turns that into a sign-out.
//
// WHY THIS TESTS A FUNCTION AND NOT THE SHELL. `UspDashboardShell` needs the
// router, the SSE stack, the dashboard's domain-ready gate, the mascot controller
// and the theme-studio config before it renders a frame — the position
// `surface_consumers_test.dart` already takes, in its own words, is that standing
// all of that up "would produce a test whose failures are almost never about" the
// thing under test. So the shell's `initState` holds the trigger and this holds the
// behaviour, split the same way `pushHealthActionTarget` already is in that file.
//
// The two halves are joined by a census rather than by trust:
// `session_teardown_call_sites_test.dart` asserts that `takePendingSessionExit` has
// exactly one consumer in `lib/`, and that it is this shell. That is what makes
// "the shell calls it" checkable without pumping the shell — and it is the
// assertion that matters most here, because a report nobody consumes fails *open*:
// auth would stay logged in while the connection state said the session was over.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/connection/services/recovery_probe_service.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:privacy_gui/core/usp/services/sse_manager.dart';
import 'package:privacy_gui/framework/mode/session_end.dart';
import 'package:privacy_gui/page/shell/usp_dashboard_shell.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

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
  Future<AuthState> build() async => AuthState(loginType: LoginType.local);
}

class MockRecoveryProbeService extends Mock implements RecoveryProbeService {}

void main() {
  late MockAuthNotifier auth;
  late MockSseManager sse;
  late MockRecoveryProbeService probe;

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
  });

  /// Pumps the smallest widget that can hand a real [WidgetRef] to the function
  /// under test, and returns a callback that invokes it.
  ///
  /// A widget rather than a bare `ProviderContainer` because the signature takes
  /// `WidgetRef` — which is not an accident of convenience: the caller is a
  /// `listenManual` inside a `ConsumerState`, and a helper typed for `Ref` would
  /// not have fitted it without a second adapter.
  Future<void Function()> pumpSink(WidgetTester tester) async {
    late WidgetRef captured;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => auth),
          sseManagerProvider.overrideWithValue(sse),
          recoveryProbeServiceProvider.overrideWithValue(probe),
          sseConnectionStateProvider.overrideWith(
            (ref) => Stream.value(SseConnectionState.connected),
          ),
        ],
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

  testWidgets('a reported userRequested exit ends the session with that cause',
      (tester) async {
    final sink = await pumpSink(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SizedBox)),
    );
    container.read(appConnectionStateProvider.notifier).exitToLogout();

    sink();

    verify(() => auth.logout(cause: EndCause.userRequested)).called(1);
  });

  testWidgets('a serial mismatch ends the session as sessionLost',
      (tester) async {
    // Driven through the real probe path rather than by setting the cause by hand,
    // because the pairing is the claim: the cause the core decides is the cause the
    // sign-out gets. `sessionLost` is also the load-bearing half in Remote
    // Assistance — it is what stops `RemoteSessionStrategy.end` from asking Guardian
    // to close a session against a router that never had it.
    when(() => probe.probe(healthOnly: any(named: 'healthOnly')))
        .thenAnswer((_) async => ProbeResult.serialMismatch);

    final sink = await pumpSink(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SizedBox)),
    );
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

    sink();

    verify(() => auth.logout(cause: EndCause.sessionLost)).called(1);
  });

  testWidgets('nothing reported means no sign-out', (tester) async {
    final sink = await pumpSink(tester);

    sink();

    verifyNever(() => auth.logout(cause: any(named: 'cause')));
    verifyNever(() => auth.logout());
  });

  testWidgets('a reported exit is acted on exactly once', (tester) async {
    // The property that lets the shell call this on every transition into
    // `loggedOut` without a flag of its own. `logout()` is not idempotent from the
    // user's side in Remote Assistance: `EndCause.userRequested` reaches
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
}
