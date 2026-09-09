import 'dart:async';

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
import 'package:privacy_gui/providers/auth/auth_provider.dart';

import '../../../mocks/test_data/auth_test_data.dart';

class MockRecoveryProbeService extends Mock implements RecoveryProbeService {}

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
  Future<AuthState> build() async => AuthTestData.loggedIn();
}

/// Auth notifier whose state can be driven by tests to simulate a
/// logout→login cycle so `ref.listen(authProvider)` fires the transitions.
class ControllableAuthNotifier extends AsyncNotifier<AuthState>
    with Mock
    implements AuthNotifier {
  @override
  Future<AuthState> build() async => AuthTestData.loggedIn();

  void emitLoggedOut() => state = AsyncValue.data(AuthTestData.loggedOut());

  void emitLoggedIn() => state = AsyncValue.data(AuthTestData.loggedIn());

  /// A second logged-in emission that is *not* a re-login.
  ///
  /// A separate method rather than a second [emitLoggedIn] call, because that one
  /// would emit an *equal* state and Riverpod would suppress the notification —
  /// `AuthTestData.loggedInAgain` carries the whole argument.
  void emitHintRefresh() =>
      state = AsyncValue.data(AuthTestData.loggedInAgain('hint refreshed'));
}

void main() {
  late MockRecoveryProbeService mockProbe;
  late MockSseManager mockSseManager;
  late MockAuthNotifier mockAuthNotifier;

  setUpAll(() {
    // Needed by `any(named: 'cause')` in the `verifyNever` calls below, and the
    // failure without it is not local to those calls: mocktail throws from *inside*
    // the verification, which leaves its argument-matcher stack dirty and makes
    // every `when(...)` later in this file silently stop applying — 18 unrelated
    // tests failing on an unstubbed `SseManager.disconnect()`. Only the type is
    // used; the value never reaches an argument.
    registerFallbackValue(EndCause.sessionLost);
  });

  setUp(() {
    mockProbe = MockRecoveryProbeService();
    mockSseManager = MockSseManager();
    mockAuthNotifier = MockAuthNotifier();
  });

  ProviderContainer createContainer({
    SseConnectionState sseState = SseConnectionState.connected,
    AuthNotifier Function()? authNotifier,
  }) {
    return ProviderContainer(
      overrides: [
        recoveryProbeServiceProvider.overrideWithValue(mockProbe),
        sseManagerProvider.overrideWithValue(mockSseManager),
        sseConnectionStateProvider.overrideWith(
          (ref) => Stream.value(sseState),
        ),
        authProvider.overrideWith(authNotifier ?? () => mockAuthNotifier),
      ],
    );
  }

  group('AppConnectionStateNotifier', () {
    test('initial state is authenticated', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final state = container.read(appConnectionStateProvider);
      expect(state, AppConnectionState.authenticated);
    });

    test('enterWaiting transitions to waitingForRecovery', () {
      when(() => mockSseManager.disconnect()).thenAnswer((_) async {});
      when(() => mockProbe.probe())
          .thenAnswer((_) async => ProbeResult.unreachable);

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(appConnectionStateProvider.notifier).enterWaiting(
            context: RecoveryContext(
              trigger: RecoveryTrigger.operationalWifiChange,
              cooldown: Duration(seconds: 30),
            ),
          );

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.waitingForRecovery,
      );
    });

    test('enterWaiting does nothing if already in waitingForRecovery', () {
      when(() => mockSseManager.disconnect()).thenAnswer((_) async {});
      when(() => mockProbe.probe())
          .thenAnswer((_) async => ProbeResult.unreachable);

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appConnectionStateProvider.notifier);
      notifier.enterWaiting(
        context: RecoveryContext(
          trigger: RecoveryTrigger.operationalWifiChange,
          cooldown: Duration(seconds: 30),
        ),
      );
      // Second call should be a no-op
      notifier.enterWaiting(
        context: RecoveryContext(
          trigger: RecoveryTrigger.operationalReboot,
          cooldown: Duration(seconds: 30),
        ),
      );

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.waitingForRecovery,
      );
      // disconnect should only be called once (first enterWaiting)
      verify(() => mockSseManager.disconnect()).called(1);
    });

    test('reportConnectivityFailure triggers waiting when SSE is suspended',
        () async {
      when(() => mockSseManager.disconnect()).thenAnswer((_) async {});
      when(() => mockProbe.probe())
          .thenAnswer((_) async => ProbeResult.unreachable);

      final container = createContainer(
        sseState: SseConnectionState.suspended,
      );
      addTearDown(container.dispose);

      // Force the provider to build and the SSE listener to fire
      container.read(appConnectionStateProvider);
      // Allow SSE stream value to propagate through the listener
      await Future.delayed(Duration.zero);

      container
          .read(appConnectionStateProvider.notifier)
          .reportConnectivityFailure();

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.waitingForRecovery,
      );
    });

    test('reportConnectivityFailure does NOT trigger when SSE is connected',
        () async {
      final container = createContainer(
        sseState: SseConnectionState.connected,
      );
      addTearDown(container.dispose);

      // Force the provider to build
      container.read(appConnectionStateProvider);
      await Future.delayed(Duration.zero);

      container
          .read(appConnectionStateProvider.notifier)
          .reportConnectivityFailure();

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.authenticated,
      );
    });

    test(
        'reportConnectivityFailure does NOT trigger when not in authenticated state',
        () async {
      when(() => mockSseManager.disconnect()).thenAnswer((_) async {});
      when(() => mockProbe.probe())
          .thenAnswer((_) async => ProbeResult.unreachable);

      final container = createContainer(
        sseState: SseConnectionState.suspended,
      );
      addTearDown(container.dispose);

      // Force into waitingForRecovery first
      container.read(appConnectionStateProvider.notifier).enterWaiting(
            context: RecoveryContext(
              trigger: RecoveryTrigger.operationalWifiChange,
              cooldown: Duration(seconds: 30),
            ),
          );

      // Now reportConnectivityFailure should be a no-op
      container
          .read(appConnectionStateProvider.notifier)
          .reportConnectivityFailure();

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.waitingForRecovery,
      );
    });

    test('recovery probe returning recovered transitions to authenticated',
        () async {
      when(() => mockProbe.probe())
          .thenAnswer((_) async => ProbeResult.recovered);
      when(() => mockSseManager.disconnect()).thenAnswer((_) async {});
      when(() => mockSseManager.connect()).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(appConnectionStateProvider.notifier).enterWaiting(
            context: RecoveryContext(
              trigger: RecoveryTrigger.operationalWifiChange,
              cooldown: Duration.zero,
            ),
          );

      // Allow the probe to run (it's async)
      await Future.delayed(const Duration(milliseconds: 100));

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.authenticated,
      );
      verify(() => mockSseManager.connect()).called(1);
    });

    test(
        'recovery probe returning serialMismatch reports sessionLost '
        'without ending the session', () async {
      when(() => mockProbe.probe())
          .thenAnswer((_) async => ProbeResult.serialMismatch);
      when(() => mockSseManager.disconnect()).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appConnectionStateProvider.notifier);
      notifier.enterWaiting(
        context: RecoveryContext(
          trigger: RecoveryTrigger.operationalWifiChange,
          cooldown: Duration.zero,
        ),
      );

      // Allow the probe to run
      await Future.delayed(const Duration(milliseconds: 100));

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.loggedOut,
      );
      // The half #1323 phase 5 changed. A different router answered, so the
      // session is over — but signing the user out is the page layer's call, and
      // `EndCause.sessionLost` is what tells `RemoteSessionStrategy.end` not to ask
      // Guardian to close a session against a device that never had it.
      expect(notifier.takePendingSessionExit(), EndCause.sessionLost);
      verifyNever(() => mockAuthNotifier.logout());
      verifyNever(() => mockAuthNotifier.logout(cause: any(named: 'cause')));
    });

    test('recovery after a factory reset reports sessionLost', () async {
      // The `operationalFactoryReset` arm of `ProbeResult.recovered`, which had no
      // coverage here before #1323 phase 5 gave it a value to report. It is the one
      // place a *successful* probe still ends the session: the router came back,
      // and came back with nothing of the session left in it.
      when(() => mockProbe.probe())
          .thenAnswer((_) async => ProbeResult.recovered);
      when(() => mockSseManager.disconnect()).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appConnectionStateProvider.notifier);
      notifier.enterWaiting(
        context: RecoveryContext(
          trigger: RecoveryTrigger.operationalFactoryReset,
          cooldown: Duration.zero,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.loggedOut,
      );
      expect(notifier.takePendingSessionExit(), EndCause.sessionLost);
      // Not the `recovered` path's SSE reconnect: there is no session left to
      // stream into.
      verifyNever(() => mockSseManager.connect());
      verifyNever(() => mockAuthNotifier.logout());
      verifyNever(() => mockAuthNotifier.logout(cause: any(named: 'cause')));
    });

    test('recovery probe returning unreachable continues probing', () async {
      int probeCallCount = 0;
      when(() => mockProbe.probe()).thenAnswer((_) async {
        probeCallCount++;
        return ProbeResult.unreachable;
      });
      when(() => mockSseManager.disconnect()).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(appConnectionStateProvider.notifier).enterWaiting(
            context: RecoveryContext(
              trigger: RecoveryTrigger.operationalWifiChange,
              cooldown: Duration.zero,
            ),
          );

      // First probe runs immediately
      await Future.delayed(const Duration(milliseconds: 100));

      expect(probeCallCount, greaterThanOrEqualTo(1));
      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.waitingForRecovery,
      );
    });

    test('exitToLogout stops probe and reports userRequested', () {
      when(() => mockSseManager.disconnect()).thenAnswer((_) async {});
      when(() => mockProbe.probe())
          .thenAnswer((_) async => ProbeResult.unreachable);

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appConnectionStateProvider.notifier);
      notifier.enterWaiting(
        context: RecoveryContext(
          trigger: RecoveryTrigger.operationalWifiChange,
          cooldown: Duration(seconds: 30),
        ),
      );

      notifier.exitToLogout();

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.loggedOut,
      );
      // `userRequested`, not the `sessionLost` the removed bare `logout()`
      // defaulted to: the only caller is a button. Behaviourally identical today
      // because `LocalSessionStrategy.end` ignores the cause, and it is the local
      // surface that offers this affordance — but it is the truthful value, and it
      // is what makes a Remote caller release its Guardian session rather than
      // leave it open.
      expect(notifier.takePendingSessionExit(), EndCause.userRequested);
      verifyNever(() => mockAuthNotifier.logout());
      verifyNever(() => mockAuthNotifier.logout(cause: any(named: 'cause')));
    });

    test('exitToLogout from authenticated state', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appConnectionStateProvider.notifier);
      notifier.exitToLogout();

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.loggedOut,
      );
      expect(notifier.takePendingSessionExit(), EndCause.userRequested);
    });

    test('the reported exit is one-shot', () {
      // What lets the consumer key off the cause instead of the state transition.
      // `loggedOut` is also reached by `build`'s authProvider listener when
      // something else logged out, and a consumer that acted on every transition
      // would tear the session down twice. Reading clears, so the second look —
      // whether it is a second listener or a later unrelated transition — sees
      // nothing to do.
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appConnectionStateProvider.notifier);
      notifier.exitToLogout();

      expect(notifier.takePendingSessionExit(), EndCause.userRequested);
      expect(notifier.takePendingSessionExit(), isNull);
    });

    test('a logout the app did not decide reports nothing', () async {
      // The other way into `loggedOut`: auth logged itself out — an idle timeout,
      // a 401 through `sse_providers.dart`, the account menu — and this notifier
      // followed. Nothing for the consumer to do, and `logout()` again would be a
      // second teardown of a session already gone.
      final auth = ControllableAuthNotifier();
      final container = createContainer(authNotifier: () => auth);
      addTearDown(container.dispose);

      final notifier = container.read(appConnectionStateProvider.notifier);
      // `ControllableAuthNotifier.build` is async, and `build`'s listener skips a
      // loading value — so the first emit has to land after it has settled or the
      // listener never sees the transition.
      await Future.delayed(Duration.zero);
      expect(container.read(appConnectionStateProvider),
          AppConnectionState.authenticated);

      auth.emitLoggedOut();
      await Future.delayed(Duration.zero);

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.loggedOut,
      );
      expect(notifier.takePendingSessionExit(), isNull);
    });

    test('consecutiveFailures increments on each unreachable probe', () async {
      when(() => mockSseManager.disconnect()).thenAnswer((_) async {});
      when(() => mockProbe.probe())
          .thenAnswer((_) async => ProbeResult.unreachable);

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appConnectionStateProvider.notifier);
      expect(notifier.consecutiveFailures, 0);
      expect(notifier.lastProbeResult, isNull);

      notifier.enterWaiting(
        context: RecoveryContext(
          trigger: RecoveryTrigger.operationalFirmwareUpgrade,
          cooldown: Duration.zero,
        ),
      );

      // First probe fires immediately, then a periodic 10s timer kicks in.
      // We only need to observe the first one for the counter test.
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.consecutiveFailures, greaterThanOrEqualTo(1));
      expect(notifier.lastProbeResult, ProbeResult.unreachable);
    });

    test('consecutiveFailures resets to zero on recovered probe', () async {
      when(() => mockSseManager.disconnect()).thenAnswer((_) async {});
      when(() => mockSseManager.connect()).thenAnswer((_) async {});
      var callCount = 0;
      when(() => mockProbe.probe()).thenAnswer((_) async {
        callCount++;
        // First two probes fail, third recovers.
        if (callCount <= 2) return ProbeResult.unreachable;
        return ProbeResult.recovered;
      });

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appConnectionStateProvider.notifier);
      notifier.enterWaiting(
        context: RecoveryContext(
          trigger: RecoveryTrigger.operationalFirmwareUpgrade,
          cooldown: Duration.zero,
        ),
      );

      // First probe (unreachable) fires immediately on enterWaiting.
      await Future.delayed(const Duration(milliseconds: 30));
      expect(notifier.consecutiveFailures, 1);

      // Drive two manual retries — second is unreachable, third is recovered.
      await notifier.retryNow();
      expect(notifier.consecutiveFailures, 2);

      await notifier.retryNow();
      // Recovery probe transitions state, but retryNow runs the probe even
      // though state has already flipped to authenticated; the counter reset
      // happened on the recovered branch.
      expect(notifier.consecutiveFailures, 0);
      expect(notifier.lastProbeResult, ProbeResult.recovered);
    });

    test('retryNow does nothing when not in waitingForRecovery', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appConnectionStateProvider.notifier);
      // Notifier starts in `authenticated`; retryNow should be a no-op.
      await notifier.retryNow();

      verifyNever(() => mockProbe.probe());
      expect(notifier.consecutiveFailures, 0);
      expect(notifier.lastProbeResult, isNull);
    });

    test('retryNow forces an immediate probe while waiting', () async {
      when(() => mockSseManager.disconnect()).thenAnswer((_) async {});
      when(() => mockProbe.probe())
          .thenAnswer((_) async => ProbeResult.unreachable);

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appConnectionStateProvider.notifier);
      notifier.enterWaiting(
        context: RecoveryContext(
          trigger: RecoveryTrigger.operationalFirmwareUpgrade,
          // Non-zero cooldown — first probe should NOT fire immediately, so
          // retryNow's call must be the first one we observe.
          cooldown: const Duration(minutes: 5),
        ),
      );

      // No probes yet — cooldown timer is still pending.
      verifyNever(() => mockProbe.probe());

      await notifier.retryNow();

      verify(() => mockProbe.probe()).called(1);
      expect(notifier.lastProbeResult, ProbeResult.unreachable);
      expect(notifier.consecutiveFailures, 1);
    });

    test('exitToLogout resets recovery counters', () async {
      when(() => mockSseManager.disconnect()).thenAnswer((_) async {});
      when(() => mockProbe.probe())
          .thenAnswer((_) async => ProbeResult.unreachable);

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appConnectionStateProvider.notifier);
      notifier.enterWaiting(
        context: RecoveryContext(
          trigger: RecoveryTrigger.operationalFirmwareUpgrade,
          cooldown: Duration.zero,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 30));
      expect(notifier.consecutiveFailures, greaterThanOrEqualTo(1));

      notifier.exitToLogout();

      expect(notifier.consecutiveFailures, 0);
      expect(notifier.lastProbeResult, isNull);
    });

    test(
        'enterWaiting from a fresh authenticated state resets counters '
        'before kicking off probe', () async {
      when(() => mockSseManager.disconnect()).thenAnswer((_) async {});
      when(() => mockProbe.probe())
          .thenAnswer((_) async => ProbeResult.unreachable);

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appConnectionStateProvider.notifier);
      // Use a non-zero cooldown so we can read the counters BEFORE the
      // first probe fires.
      notifier.enterWaiting(
        context: RecoveryContext(
          trigger: RecoveryTrigger.operationalFirmwareUpgrade,
          cooldown: const Duration(minutes: 5),
        ),
      );

      expect(notifier.consecutiveFailures, 0);
      expect(notifier.lastProbeResult, isNull);
    });

    test('onReconnectFailed triggers enterWaiting after threshold (2) failures',
        () async {
      when(() => mockSseManager.disconnect()).thenAnswer((_) async {});
      when(() => mockProbe.probe())
          .thenAnswer((_) async => ProbeResult.unreachable);

      final container = createContainer();
      addTearDown(container.dispose);

      // Force build — this wires the callback
      container.read(appConnectionStateProvider);
      await Future.delayed(Duration.zero);

      expect(mockSseManager.capturedOnReconnectFailed, isNotNull);
      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.authenticated,
      );

      // Simulate 1st reconnect failure — below threshold, no trigger
      mockSseManager.capturedOnReconnectFailed!(1);
      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.authenticated,
      );

      // Simulate 2nd reconnect failure — reaches threshold, triggers recovery
      mockSseManager.capturedOnReconnectFailed!(2);
      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.waitingForRecovery,
      );
      expect(
        container
            .read(appConnectionStateProvider.notifier)
            .recoveryContext
            ?.trigger,
        RecoveryTrigger.natural,
      );
      verify(() => mockSseManager.disconnect()).called(1);
    });

    test('onReconnectFailed does NOT trigger if already in waitingForRecovery',
        () async {
      when(() => mockSseManager.disconnect()).thenAnswer((_) async {});
      when(() => mockProbe.probe())
          .thenAnswer((_) async => ProbeResult.unreachable);

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(appConnectionStateProvider);
      await Future.delayed(Duration.zero);

      // Manually enter waiting with a user-initiated trigger
      container.read(appConnectionStateProvider.notifier).enterWaiting(
            context: RecoveryContext(
              trigger: RecoveryTrigger.operationalWifiChange,
              cooldown: Duration(seconds: 30),
            ),
          );

      // SSE reconnect fails — should NOT overwrite existing recovery
      mockSseManager.capturedOnReconnectFailed!(2);

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.waitingForRecovery,
      );
      // Original trigger preserved
      expect(
        container
            .read(appConnectionStateProvider.notifier)
            .recoveryContext
            ?.trigger,
        RecoveryTrigger.operationalWifiChange,
      );
      // disconnect called only once (from the manual enterWaiting)
      verify(() => mockSseManager.disconnect()).called(1);
    });

    test('onReconnectFailed below threshold does NOT trigger recovery',
        () async {
      final container = createContainer();
      addTearDown(container.dispose);

      container.read(appConnectionStateProvider);
      await Future.delayed(Duration.zero);

      // Only 1 failure — below threshold
      mockSseManager.capturedOnReconnectFailed!(1);

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.authenticated,
      );
      verifyNever(() => mockSseManager.disconnect());
    });

    test('recoveryContext is cleared after ProbeResult.recovered', () async {
      when(() => mockSseManager.disconnect()).thenAnswer((_) async {});
      when(() => mockSseManager.connect()).thenAnswer((_) async {});
      when(() => mockProbe.probe(healthOnly: any(named: 'healthOnly')))
          .thenAnswer((_) async => ProbeResult.recovered);

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appConnectionStateProvider.notifier);
      notifier.enterWaiting(
        context: RecoveryContext(
          trigger: RecoveryTrigger.operationalReboot,
          cooldown: Duration.zero,
          healthOnly: true,
        ),
      );
      expect(notifier.recoveryContext, isNotNull);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.authenticated,
      );
      expect(notifier.recoveryContext, isNull);
    });

    test('recoveryContext is cleared after ProbeResult.serialMismatch',
        () async {
      when(() => mockSseManager.disconnect()).thenAnswer((_) async {});
      when(() => mockProbe.probe())
          .thenAnswer((_) async => ProbeResult.serialMismatch);

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appConnectionStateProvider.notifier);
      notifier.enterWaiting(
        context: RecoveryContext(
          trigger: RecoveryTrigger.operationalWifiChange,
          cooldown: Duration.zero,
        ),
      );
      expect(notifier.recoveryContext, isNotNull);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.loggedOut,
      );
      expect(notifier.recoveryContext, isNull);
    });

    test('recoveryContext getter exposes current context', () {
      when(() => mockSseManager.disconnect()).thenAnswer((_) async {});
      when(() => mockProbe.probe())
          .thenAnswer((_) async => ProbeResult.unreachable);

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appConnectionStateProvider.notifier);
      expect(notifier.recoveryContext, isNull);

      notifier.enterWaiting(
        context: RecoveryContext(
          trigger: RecoveryTrigger.operationalReboot,
          cooldown: Duration(seconds: 60),
          healthOnly: true,
        ),
      );

      expect(notifier.recoveryContext, isNotNull);
      expect(
          notifier.recoveryContext?.trigger, RecoveryTrigger.operationalReboot);
      expect(notifier.recoveryContext?.healthOnly, true);
    });

    // -------------------------------------------------------------------------
    // Logout → re-login within the same session (no page reload)
    // -------------------------------------------------------------------------
    group('logout → re-login (same session)', () {
      test('re-login after logout restores authenticated', () async {
        final auth = ControllableAuthNotifier();
        final container = createContainer(authNotifier: () => auth);
        addTearDown(container.dispose);

        // Force build so the authProvider listener is wired.
        container.read(appConnectionStateProvider);
        await Future.delayed(Duration.zero);
        expect(
          container.read(appConnectionStateProvider),
          AppConnectionState.authenticated,
        );

        // Logout → loggedOut.
        auth.emitLoggedOut();
        await Future.delayed(Duration.zero);
        expect(
          container.read(appConnectionStateProvider),
          AppConnectionState.loggedOut,
        );

        // Re-login without a page reload → must return to authenticated so
        // dashboard polling (traffic, system monitor) can restart. Regression
        // for the Network Health / Traffic Monitor "no data after re-login"
        // bug.
        auth.emitLoggedIn();
        await Future.delayed(Duration.zero);
        expect(
          container.read(appConnectionStateProvider),
          AppConnectionState.authenticated,
        );
      });

      test('re-login does NOT override an active waitingForRecovery', () async {
        when(() => mockSseManager.disconnect()).thenAnswer((_) async {});
        when(() => mockProbe.probe())
            .thenAnswer((_) async => ProbeResult.unreachable);

        final auth = ControllableAuthNotifier();
        final container = createContainer(authNotifier: () => auth);
        addTearDown(container.dispose);

        container.read(appConnectionStateProvider);
        await Future.delayed(Duration.zero);

        // Enter recovery (still logged in).
        container.read(appConnectionStateProvider.notifier).enterWaiting(
              context: RecoveryContext(
                trigger: RecoveryTrigger.operationalWifiChange,
                cooldown: Duration(minutes: 5),
              ),
            );
        expect(
          container.read(appConnectionStateProvider),
          AppConnectionState.waitingForRecovery,
        );

        // A logged-in auth event must not clobber the recovery state — only a
        // `loggedOut` state is allowed to flip back to authenticated.
        auth.emitLoggedIn();
        await Future.delayed(Duration.zero);
        expect(
          container.read(appConnectionStateProvider),
          AppConnectionState.waitingForRecovery,
        );
      });

      test('a logged-in auth event does not un-decide a reported exit',
          () async {
        // Round 3's arm-2 finding. The promotion above keys on
        // `state == loggedOut`, which before this PR could only mean "auth logged
        // out and this notifier followed". It now also means "this notifier decided
        // the session is over and nobody has carried it out yet" — auth is still
        // holding a session, so the next non-loading emission is not necessarily a
        // re-login. The arm used to clear the cause and promote, which consumed the
        // report on the consumer's behalf: signed in to a session the core had given
        // up on, with nothing left to re-report it. In Remote Assistance the report
        // is what releases the Guardian session, so the leak is a support session
        // left open until it expires.
        //
        // The pairing with the arm above is what makes this safe to gate rather than
        // track: a *genuine* re-login passes through a logout first, and that arm
        // clears the field unconditionally.
        final auth = ControllableAuthNotifier();
        final container = createContainer(authNotifier: () => auth);
        addTearDown(container.dispose);

        final notifier = container.read(appConnectionStateProvider.notifier);
        await Future.delayed(Duration.zero);

        // The core decides. Auth is untouched and still logged in — this is the
        // stranded-report state, reachable whenever no `/usp*` page is mounted.
        notifier.exitToLogout();
        expect(
          container.read(appConnectionStateProvider),
          AppConnectionState.loggedOut,
        );

        auth.emitHintRefresh();
        await Future.delayed(Duration.zero);

        expect(
          container.read(appConnectionStateProvider),
          AppConnectionState.loggedOut,
          reason: 'the promotion arm re-authenticated a session the core had '
              'already reported as over',
        );
        expect(notifier.takePendingSessionExit(), EndCause.userRequested,
            reason: 'the cause was dropped, so the next consumer to mount has '
                'nothing to act on and the sign-out never happens');
      });

      test('a cause planted while auth is still resolving survives it',
          () async {
        // The same arm, reached by timing rather than by a refresh — and the one
        // round 3 pointed at, because `session_exit_sink_test.dart`'s `pumpScope`
        // helper arranges this ordering away for every test in that file. `build()`
        // is `async`, so `authProvider` is still loading here; when it resolves
        // logged-in it lands on the promotion arm with the cause already set. A
        // precondition a test helper can arrange is not one production has: the same
        // race is a probe answering while a hint refresh is in flight.
        final auth = ControllableAuthNotifier();
        final container = createContainer(authNotifier: () => auth);
        addTearDown(container.dispose);

        final notifier = container.read(appConnectionStateProvider.notifier);
        notifier.exitToLogout();

        // Auth resolves *after* the report.
        await Future.delayed(Duration.zero);

        expect(
          container.read(appConnectionStateProvider),
          AppConnectionState.loggedOut,
        );
        expect(notifier.takePendingSessionExit(), EndCause.userRequested);
      });
    });
  });
}
