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

class MockSseManager extends Mock implements SseManager {}

class MockAuthNotifier extends AsyncNotifier<AuthState>
    with Mock
    implements AuthNotifier {
  @override
  Future<AuthState> build() async => AuthState.empty();
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
  });
}
