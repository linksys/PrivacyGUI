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
import 'package:privacy_gui/providers/auth/auth_provider.dart';

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
  Future<AuthState> build() async => AuthState(
        loginType: LoginType.local,
      );
}

void main() {
  late MockRecoveryProbeService mockProbe;
  late MockSseManager mockSseManager;
  late MockAuthNotifier mockAuthNotifier;

  setUp(() {
    mockProbe = MockRecoveryProbeService();
    mockSseManager = MockSseManager();
    mockAuthNotifier = MockAuthNotifier();
  });

  ProviderContainer createContainer({
    SseConnectionState sseState = SseConnectionState.connected,
  }) {
    return ProviderContainer(
      overrides: [
        recoveryProbeServiceProvider.overrideWithValue(mockProbe),
        sseManagerProvider.overrideWithValue(mockSseManager),
        sseConnectionStateProvider.overrideWith(
          (ref) => Stream.value(sseState),
        ),
        authProvider.overrideWith(() => mockAuthNotifier),
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

    test('recovery probe returning serialMismatch transitions to loggedOut',
        () async {
      when(() => mockProbe.probe())
          .thenAnswer((_) async => ProbeResult.serialMismatch);
      when(() => mockSseManager.disconnect()).thenAnswer((_) async {});
      when(() => mockAuthNotifier.logout()).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(appConnectionStateProvider.notifier).enterWaiting(
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
      verify(() => mockAuthNotifier.logout()).called(1);
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

    test('exitToLogout stops probe and transitions to loggedOut', () {
      when(() => mockSseManager.disconnect()).thenAnswer((_) async {});
      when(() => mockProbe.probe())
          .thenAnswer((_) async => ProbeResult.unreachable);
      when(() => mockAuthNotifier.logout()).thenAnswer((_) async {});

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
      verify(() => mockAuthNotifier.logout()).called(1);
    });

    test('exitToLogout from authenticated state', () {
      when(() => mockAuthNotifier.logout()).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      container.read(appConnectionStateProvider.notifier).exitToLogout();

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.loggedOut,
      );
      verify(() => mockAuthNotifier.logout()).called(1);
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
      when(() => mockAuthNotifier.logout()).thenAnswer((_) async {});
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
      when(() => mockAuthNotifier.logout()).thenAnswer((_) async {});

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
  });
}
