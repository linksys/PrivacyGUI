// #1323 phase 4, end to end: the recovery state machine in Remote Assistance.
//
// WHY A SECOND FILE RATHER THAN A GROUP IN THE FIRST ONE. `app_connection_state_
// provider_test.dart` mocks `recoveryProbeServiceProvider` outright, which is the
// right seam for its subject — the state machine's arithmetic (counters, timers,
// which `ProbeResult` leads where). It is also the seam that made the #1323 bug
// invisible: with the probe stubbed, "what does a probe actually return in RA"
// is never asked. That file is left byte-for-byte untouched by this change, and
// its 25 tests still pass, which is the evidence that phase 4 moved the mode `if`s
// without altering local behaviour.
//
// This file runs the *real* `RecoveryProbeService` against the remote profile and
// mocks one layer lower — at `uspClientProvider`. That is the only arrangement in
// which the defect is reproducible, because the defect was a composition: three
// individually reasonable steps, two of which do not apply remotely.
//
// THE BUG, AS A SEQUENCE. A support session is live. SSE drops (the router's
// uplink blips, or the agent restarts). `_onSseReconnectFailed` fires at 2
// failures and enters recovery with `RecoveryTrigger.natural`. The probe then:
//   - called `bridge.health()` on a Guardian path Guardian does not serve, so
//     every probe was `unreachable` and the app waited for a router that was
//     answering fine;
//   - and once that was fixed, called `restoreSession()` (a `temporaryAccessToken`
//     cannot be refreshed) and compared `getSerialNumber()` against a fingerprint
//     stored at *local* login — which a support session never wrote. `matches()`
//     returns false for a null stored value, so the probe reported
//     `serialMismatch`, and `_runProbe` turns that into a forced `logout()` with
//     the Guardian session still alive and the operator still on the phone.
//
// Acceptances 4, 5 and 6 of #1323 are the three tests in the first group.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/connection/services/recovery_probe_service.dart';
import 'package:privacy_gui/core/connection/services/router_fingerprint_service.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/local_mode_profile.dart';
import 'package:privacy_gui/core/mode/remote_mode_profile.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:privacy_gui/core/usp/services/sse_manager.dart';
import 'package:privacy_gui/framework/mode/session_end.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

class MockUspClient extends Mock implements UspClient {}

class MockUspBridgeClient extends Mock implements UspBridgeClient {}

class MockUspAuthCoordinator extends Mock implements UspAuthCoordinator {}

class MockRouterFingerprintService extends Mock
    implements RouterFingerprintService {}

class MockSseManager extends Mock implements SseManager {
  void Function(int)? capturedOnReconnectFailed;

  @override
  set onReconnectFailed(void Function(int)? callback) {
    capturedOnReconnectFailed = callback;
  }
}

class MockAuthNotifier extends AsyncNotifier<AuthState>
    with Mock
    implements AuthNotifier {
  @override
  Future<AuthState> build() async => AuthState(loginType: LoginType.remote);
}

const _kReachabilityPath = 'Device.DeviceInfo.SerialNumber';

void main() {
  setUpAll(() {
    // Required by the `any(named: 'cause')` matchers below. Without it mocktail
    // throws from *inside* the verification and leaves its argument-matcher stack
    // dirty, which silently disables later stubbing in this file instead of failing
    // where the mistake is.
    registerFallbackValue(EndCause.sessionLost);
  });

  late MockUspClient mockUsp;
  late MockUspBridgeClient mockBridge;
  late MockUspAuthCoordinator mockAuth;
  late MockRouterFingerprintService mockFingerprint;
  late MockSseManager mockSseManager;
  late MockAuthNotifier mockAuthNotifier;

  setUp(() {
    mockUsp = MockUspClient();
    mockBridge = MockUspBridgeClient();
    mockAuth = MockUspAuthCoordinator();
    mockFingerprint = MockRouterFingerprintService();
    mockSseManager = MockSseManager();
    mockAuthNotifier = MockAuthNotifier();

    when(() => mockSseManager.disconnect()).thenAnswer((_) async {});
    when(() => mockSseManager.connect()).thenAnswer((_) async {});
    // Stubbed even in the tests that assert it is never called: an unstubbed
    // `logout()` returns null where a Future is expected, so a regression would
    // fail with a TypeError from inside `_runProbe` instead of the `verifyNever`
    // that names the actual defect.
    //
    // Matched on `cause` rather than as a bare `logout()`, and so are the
    // `verifyNever`s. `logout({EndCause cause = EndCause.sessionLost})` has a
    // default, so `logout()` and `logout(cause: …)` are two different invocations
    // to mocktail: a bare matcher does not match a call that passed the argument.
    // Since #1323 phase 5 the only way back to a sign-out here is with a cause, so
    // the bare form would have been a stub nothing hits and — worse — three
    // `verifyNever`s that cannot fail.
    when(() => mockAuthNotifier.logout(cause: any(named: 'cause')))
        .thenAnswer((_) async {});
  });

  /// Note what is *not* overridden: `recoveryProbeServiceProvider`. The real
  /// service is built from the profile's own strategies, which is the whole
  /// subject.
  ///
  /// Both modes' dependencies are stubbed in both containers, so a probe that
  /// reaches the wrong mode's dependency gets a working mock rather than a null.
  /// A null would fail the test for the wrong reason and the `verifyNever`s below
  /// would pass vacuously.
  ProviderContainer createContainer({required bool remote}) {
    final container = ProviderContainer(overrides: [
      if (remote)
        appModeProfileProvider.overrideWithValue(const RemoteModeProfile())
      else
        appModeProfileProvider.overrideWithValue(const LocalModeProfile()),
      uspClientProvider.overrideWithValue(mockUsp),
      uspBridgeClientProvider.overrideWithValue(mockBridge),
      uspAuthCoordinatorProvider.overrideWithValue(mockAuth),
      routerFingerprintServiceProvider.overrideWithValue(mockFingerprint),
      sseManagerProvider.overrideWithValue(mockSseManager),
      sseConnectionStateProvider
          .overrideWith((ref) => Stream.value(SseConnectionState.connected)),
      authProvider.overrideWith(() => mockAuthNotifier),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  void stubRouterAnswering() {
    when(() => mockUsp.get([_kReachabilityPath]))
        .thenAnswer((_) async => {_kReachabilityPath: 'ABC123'});
    when(() => mockBridge.health()).thenAnswer((_) async => {
          'status': 'healthy',
          'agent_connected': true,
          'agent_state': 'ready',
        });
    when(() => mockAuth.restoreSession(isRecovering: true))
        .thenAnswer((_) async {});
    when(() => mockAuth.getSerialNumber()).thenAnswer((_) async => 'ABC123');
    // The stub that used to sink the session: no fingerprint was ever stored for
    // a support session, and `matches()` is false for a null stored value.
    when(() => mockFingerprint.matches(any())).thenAnswer((_) async => false);
  }

  group('Remote Assistance', () {
    test('a transient SSE drop recovers instead of logging out', () async {
      stubRouterAnswering();
      final container = createContainer(remote: true);
      final notifier = container.read(appConnectionStateProvider.notifier);

      // The `natural` trigger, reached the way production reaches it: two failed
      // SSE reconnects. Acceptance 6 — this path must be coherent in RA, and
      // before #1323 it was the one that ended the support call.
      mockSseManager.capturedOnReconnectFailed!(2);
      expect(container.read(appConnectionStateProvider),
          AppConnectionState.waitingForRecovery);

      await pumpEventQueue();

      expect(container.read(appConnectionStateProvider),
          AppConnectionState.authenticated,
          reason: 'the router was answering the whole time');
      expect(notifier.lastProbeResult, ProbeResult.recovered);
      verifyNever(() => mockAuthNotifier.logout(cause: any(named: 'cause')));
      verify(() => mockSseManager.connect()).called(1);
    });

    test('recovery does not restore the session or compare the fingerprint',
        () async {
      // Acceptance 4, stated as two `verifyNever`s rather than as the outcome
      // above, because a probe that took both steps and happened to survive them
      // is still wrong: `restoreSession` on a Guardian token is a request that
      // can only fail, and the fingerprint store has no opinion worth having
      // about a router the operator is not standing next to.
      stubRouterAnswering();
      final container = createContainer(remote: true);

      container.read(appConnectionStateProvider.notifier).enterWaiting(
            context: RecoveryContext(
              trigger: RecoveryTrigger.operationalReboot,
              cooldown: Duration.zero,
            ),
          );
      await pumpEventQueue();

      verifyNever(() =>
          mockAuth.restoreSession(isRecovering: any(named: 'isRecovering')));
      verifyNever(() => mockFingerprint.matches(any()));
      verifyNever(() => mockBridge.health());
    });

    test('never force-logs-out on ProbeResult.serialMismatch', () async {
      // Acceptance 5. The cooldown is what made this bug expensive rather than
      // merely visible: an RA recovery left past its cooldown probed
      // unattended, hit `serialMismatch`, and logged out a session nobody was
      // looking at. Asserted here as "the terminal state is unreachable", by
      // running several probe rounds' worth of event queue.
      stubRouterAnswering();
      final container = createContainer(remote: true);
      final notifier = container.read(appConnectionStateProvider.notifier);

      notifier.enterWaiting(
        context: RecoveryContext(
          trigger: RecoveryTrigger.operationalFirmwareUpgrade,
          cooldown: Duration.zero,
        ),
      );
      await pumpEventQueue();
      await notifier.retryNow();
      await pumpEventQueue();

      expect(notifier.lastProbeResult, isNot(ProbeResult.serialMismatch));
      expect(container.read(appConnectionStateProvider),
          isNot(AppConnectionState.loggedOut));
      // The decision, not just the sign-out. Since #1323 phase 5 this notifier
      // *reports* an exit for the page layer to carry out, so "did not force a
      // logout" is now two claims: nothing decided the session was over, and
      // nothing acted on it. The first is the one this acceptance is about — a
      // reported exit with no consumer mounted would leave the support session
      // looking alive while the app had already given up on it.
      expect(notifier.takePendingSessionExit(), isNull);
      verifyNever(() => mockAuthNotifier.logout(cause: any(named: 'cause')));
    });

    test('a Wi-Fi change does not enter recovery at all', () async {
      // The mode has nothing to recover from, so there is no waiting state, no
      // probe loop, and SSE is not torn down. `showRecoveryDialog` reads the
      // `false` and skips the dialog — otherwise it would open a spinner nothing
      // ever pops, because it pops on a *transition into* `authenticated` and the
      // app never left it.
      stubRouterAnswering();
      final container = createContainer(remote: true);

      final waiting =
          container.read(appConnectionStateProvider.notifier).enterWaiting(
                context: RecoveryContext(
                  trigger: RecoveryTrigger.operationalWifiChange,
                  cooldown: Duration.zero,
                ),
              );

      expect(waiting, isFalse);
      expect(container.read(appConnectionStateProvider),
          AppConnectionState.authenticated);
      verifyNever(() => mockSseManager.disconnect());
      await pumpEventQueue();
      verifyNever(() => mockUsp.get(any()));
    });
  });

  group('local mode, same triggers', () {
    // The control group. Without it, every assertion above is equally consistent
    // with "recovery was quietly weakened for everyone".
    test('a Wi-Fi change does enter recovery', () {
      stubRouterAnswering();
      final container = createContainer(remote: false);

      final waiting =
          container.read(appConnectionStateProvider.notifier).enterWaiting(
                context: RecoveryContext(
                  trigger: RecoveryTrigger.operationalWifiChange,
                  cooldown: Duration.zero,
                ),
              );

      expect(waiting, isTrue);
      expect(container.read(appConnectionStateProvider),
          AppConnectionState.waitingForRecovery);
      verify(() => mockSseManager.disconnect()).called(1);
    });

    test('a changed serial still ends the session', () async {
      // The fingerprint check is not weakened, it is scoped. Locally it still
      // does the job it was written for: the operator power-cycled one router and
      // plugged in another, or a factory reset handed the same IP to a different
      // box, and continuing to drive it with the old session's credentials is how
      // settings land on the wrong hardware.
      stubRouterAnswering();
      when(() => mockAuth.getSerialNumber()).thenAnswer((_) async => 'XYZ789');
      final container = createContainer(remote: false);
      final notifier = container.read(appConnectionStateProvider.notifier);

      notifier.enterWaiting(
        context: RecoveryContext(
          trigger: RecoveryTrigger.operationalReboot,
          cooldown: Duration.zero,
        ),
      );
      await pumpEventQueue();

      expect(notifier.lastProbeResult, ProbeResult.serialMismatch);
      expect(container.read(appConnectionStateProvider),
          AppConnectionState.loggedOut);
      // "Ends the session" is now a report rather than a call — see
      // `AppConnectionStateNotifier.takePendingSessionExit`. The scoping claim this
      // test makes is unaffected: what matters is that the local profile still
      // reaches a decided exit at all, and `EndCause.sessionLost` is the exit.
      expect(notifier.takePendingSessionExit(), EndCause.sessionLost);
      verifyNever(() => mockAuthNotifier.logout(cause: any(named: 'cause')));
    });
  });
}
