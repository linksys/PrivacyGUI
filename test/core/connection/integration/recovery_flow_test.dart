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
  Future<AuthState> build() async => AuthState(
        loginType: LoginType.local,
      );
}

void main() {
  group('Recovery flow integration', () {
    test(
      'natural trigger → probe retries → recovery',
      () async {
        final mockProbe = MockRecoveryProbeService();
        final mockSse = MockSseManager();
        final mockAuth = MockAuthNotifier();

        var probeCount = 0;
        when(() => mockProbe.probe()).thenAnswer((_) async {
          probeCount++;
          return probeCount >= 2
              ? ProbeResult.recovered
              : ProbeResult.unreachable;
        });
        when(() => mockSse.connect()).thenAnswer((_) async {});
        when(() => mockSse.disconnect()).thenAnswer((_) async {});

        final container = ProviderContainer(
          overrides: [
            recoveryProbeServiceProvider.overrideWithValue(mockProbe),
            sseManagerProvider.overrideWithValue(mockSse),
            sseConnectionStateProvider.overrideWith(
              (ref) => Stream.value(SseConnectionState.suspended),
            ),
            authProvider.overrideWith(() => mockAuth),
          ],
        );
        addTearDown(container.dispose);

        // Force the provider to build so the SSE listener is wired
        container.read(appConnectionStateProvider);

        // Allow SSE state stream to propagate
        await Future.delayed(Duration.zero);

        // Simulate polling failure triggering natural entry
        container
            .read(appConnectionStateProvider.notifier)
            .reportConnectivityFailure();

        expect(
          container.read(appConnectionStateProvider),
          AppConnectionState.waitingForRecovery,
        );

        // First probe runs immediately: unreachable
        await Future.delayed(const Duration(milliseconds: 100));
        expect(probeCount, 1);
        expect(
          container.read(appConnectionStateProvider),
          AppConnectionState.waitingForRecovery,
        );

        // Second probe at ~10s: recovered
        await Future.delayed(const Duration(seconds: 11));
        expect(probeCount, greaterThanOrEqualTo(2));
        expect(
          container.read(appConnectionStateProvider),
          AppConnectionState.authenticated,
        );
        verify(() => mockSse.connect()).called(1);
      },
      timeout: Timeout(Duration(seconds: 20)),
    );

    test('operational trigger → serial mismatch → loggedOut', () async {
      final mockProbe = MockRecoveryProbeService();
      final mockSse = MockSseManager();
      final mockAuth = MockAuthNotifier();

      when(() => mockProbe.probe())
          .thenAnswer((_) async => ProbeResult.serialMismatch);
      when(() => mockSse.disconnect()).thenAnswer((_) async {});
      when(() => mockAuth.logout()).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          recoveryProbeServiceProvider.overrideWithValue(mockProbe),
          sseManagerProvider.overrideWithValue(mockSse),
          sseConnectionStateProvider.overrideWith(
            (ref) => Stream.value(SseConnectionState.connected),
          ),
          authProvider.overrideWith(() => mockAuth),
        ],
      );
      addTearDown(container.dispose);

      container.read(appConnectionStateProvider.notifier).enterWaiting(
            context: RecoveryContext(
              trigger: RecoveryTrigger.operationalWifiChange,
              cooldown: Duration.zero,
            ),
          );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.loggedOut,
      );
      verify(() => mockAuth.logout()).called(1);
    });
  });
}
