import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_state.dart';
import 'package:privacy_gui/core/cloud/services/remote_assistance_service.dart';

import '../../../../mocks/test_data/remote_assistance_test_data.dart';

// =============================================================================
// Mocks
// =============================================================================

class MockRemoteAssistanceService extends Mock
    implements RemoteAssistanceService {}

// =============================================================================
// Tests
// =============================================================================

void main() {
  late MockRemoteAssistanceService mockService;

  setUp(() {
    mockService = MockRemoteAssistanceService();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        remoteAssistanceServiceProvider.overrideWithValue(mockService),
      ],
    );
  }

  group('RemoteClientNotifier', () {
    group('build', () {
      test('returns empty RemoteClientState', () {
        final container = createContainer();
        addTearDown(container.dispose);

        final state = container.read(remoteClientProvider);

        expect(state, const RemoteClientState());
        expect(state.sessionInfo, isNull);
        expect(state.pin, isNull);
        expect(state.sessions, isEmpty);
        expect(state.expiredCountdown, isNull);
      });
    });

    group('setCredentials', () {
      test('stores credentials for later API calls', () {
        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(remoteClientProvider.notifier);
        final creds = RemoteAssistanceTestData.credentials();

        // Should not throw
        expect(() => notifier.setCredentials(creds), returnsNormally);
      });
    });

    group('initiateRemoteAssistance', () {
      test('returns early without error if credentials not set', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(remoteClientProvider.notifier);

        // Should return early without throwing
        await notifier.initiateRemoteAssistance();

        // State should remain unchanged (no API calls made)
        verifyNever(() => mockService.fetchSessions(
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            ));
      });

      test('sets initiate state and starts polling when no sessions exist',
          () async {
        when(() => mockService.fetchSessions(
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).thenAnswer((_) async => []);

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(remoteClientProvider.notifier);
        notifier.setCredentials(RemoteAssistanceTestData.credentials());

        await notifier.initiateRemoteAssistance();

        final state = container.read(remoteClientProvider);
        expect(state.sessionInfo?.status, GRASessionStatus.initiate);
        expect(state.sessionInfo?.id, '');
      });

      test('fetches session info and starts polling when session exists',
          () async {
        final session = RemoteAssistanceTestData.activeSession();

        when(() => mockService.fetchSessions(
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).thenAnswer((_) async => [session]);

        when(() => mockService.fetchSessionInfo(
              sessionId: any(named: 'sessionId'),
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).thenAnswer((_) async => session);

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(remoteClientProvider.notifier);
        notifier.setCredentials(RemoteAssistanceTestData.credentials());

        await notifier.initiateRemoteAssistance();

        final state = container.read(remoteClientProvider);
        expect(state.sessions, [session]);
        expect(state.sessionInfo, session);
      });

      test('creates PIN when session is in INITIATE status', () async {
        final session = RemoteAssistanceTestData.initiateSession();

        when(() => mockService.fetchSessions(
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).thenAnswer((_) async => [session]);

        when(() => mockService.fetchSessionInfo(
              sessionId: any(named: 'sessionId'),
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).thenAnswer((_) async => session);

        when(() => mockService.createPin(
                  serialNumber: any(named: 'serialNumber'),
                  macAddress: any(named: 'macAddress'),
                  deviceUUID: any(named: 'deviceUUID'),
                ))
            .thenAnswer(
                (_) async => RemoteAssistanceTestData.createPinResult());

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(remoteClientProvider.notifier);
        notifier.setCredentials(RemoteAssistanceTestData.credentials());

        await notifier.initiateRemoteAssistance();

        verify(() => mockService.createPin(
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).called(1);

        final state = container.read(remoteClientProvider);
        expect(state.pin, RemoteAssistanceTestData.testPin);
      });

      test('creates PIN when session is PENDING without existing PIN',
          () async {
        final session = RemoteAssistanceTestData.pendingSession();

        when(() => mockService.fetchSessions(
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).thenAnswer((_) async => [session]);

        when(() => mockService.fetchSessionInfo(
              sessionId: any(named: 'sessionId'),
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).thenAnswer((_) async => session);

        when(() => mockService.createPin(
                  serialNumber: any(named: 'serialNumber'),
                  macAddress: any(named: 'macAddress'),
                  deviceUUID: any(named: 'deviceUUID'),
                ))
            .thenAnswer(
                (_) async => RemoteAssistanceTestData.createPinResult());

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(remoteClientProvider.notifier);
        notifier.setCredentials(RemoteAssistanceTestData.credentials());

        await notifier.initiateRemoteAssistance();

        verify(() => mockService.createPin(
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).called(1);
      });

      test('does not create PIN when session is ACTIVE', () async {
        final session = RemoteAssistanceTestData.activeSession();

        when(() => mockService.fetchSessions(
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).thenAnswer((_) async => [session]);

        when(() => mockService.fetchSessionInfo(
              sessionId: any(named: 'sessionId'),
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).thenAnswer((_) async => session);

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(remoteClientProvider.notifier);
        notifier.setCredentials(RemoteAssistanceTestData.credentials());

        await notifier.initiateRemoteAssistance();

        verifyNever(() => mockService.createPin(
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            ));
      });
    });

    group('endRemoteAssistance', () {
      test('clears state when no active session', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(remoteClientProvider.notifier);
        notifier.setCredentials(RemoteAssistanceTestData.credentials());

        await notifier.endRemoteAssistance();

        final state = container.read(remoteClientProvider);
        expect(state, const RemoteClientState());
      });

      test('deletes session when session is ACTIVE', () async {
        final session = RemoteAssistanceTestData.activeSession();

        when(() => mockService.fetchSessions(
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).thenAnswer((_) async => [session]);

        when(() => mockService.fetchSessionInfo(
              sessionId: any(named: 'sessionId'),
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).thenAnswer((_) async => session);

        when(() => mockService.endSession(
              sessionId: any(named: 'sessionId'),
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).thenAnswer((_) async {});

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(remoteClientProvider.notifier);
        notifier.setCredentials(RemoteAssistanceTestData.credentials());

        // Set up session state
        await notifier.initiateRemoteAssistance();

        // End session
        await notifier.endRemoteAssistance();

        verify(() => mockService.endSession(
              sessionId: RemoteAssistanceTestData.testSessionId,
              serialNumber: RemoteAssistanceTestData.testSerialNumber,
              macAddress: RemoteAssistanceTestData.testMacAddress,
              deviceUUID: RemoteAssistanceTestData.testDeviceUUID,
            )).called(1);

        final state = container.read(remoteClientProvider);
        expect(state, const RemoteClientState());
      });

      test('deletes session when session is PENDING (PIN exists server-side)',
          () async {
        final session = RemoteAssistanceTestData.pendingSession();

        when(() => mockService.fetchSessions(
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).thenAnswer((_) async => [session]);

        when(() => mockService.fetchSessionInfo(
              sessionId: any(named: 'sessionId'),
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).thenAnswer((_) async => session);

        when(() => mockService.createPin(
                  serialNumber: any(named: 'serialNumber'),
                  macAddress: any(named: 'macAddress'),
                  deviceUUID: any(named: 'deviceUUID'),
                ))
            .thenAnswer(
                (_) async => RemoteAssistanceTestData.createPinResult());

        when(() => mockService.endSession(
              sessionId: any(named: 'sessionId'),
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).thenAnswer((_) async {});

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(remoteClientProvider.notifier);
        notifier.setCredentials(RemoteAssistanceTestData.credentials());

        await notifier.initiateRemoteAssistance();
        await notifier.endRemoteAssistance();

        // PENDING now calls endSession because PIN exists server-side
        verify(() => mockService.endSession(
              sessionId: any(named: 'sessionId'),
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).called(1);

        final state = container.read(remoteClientProvider);
        expect(state, const RemoteClientState());
      });

      test('does not delete session when session is INITIATE', () async {
        final session = RemoteAssistanceTestData.initiateSession();

        when(() => mockService.fetchSessions(
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).thenAnswer((_) async => [session]);

        when(() => mockService.fetchSessionInfo(
              sessionId: any(named: 'sessionId'),
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).thenAnswer((_) async => session);

        when(() => mockService.createPin(
                  serialNumber: any(named: 'serialNumber'),
                  macAddress: any(named: 'macAddress'),
                  deviceUUID: any(named: 'deviceUUID'),
                ))
            .thenAnswer(
                (_) async => RemoteAssistanceTestData.createPinResult());

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(remoteClientProvider.notifier);
        notifier.setCredentials(RemoteAssistanceTestData.credentials());

        await notifier.initiateRemoteAssistance();
        await notifier.endRemoteAssistance();

        verifyNever(() => mockService.endSession(
              sessionId: any(named: 'sessionId'),
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            ));
      });
    });

    group('expiredCountdownTimer', () {
      test('starts countdown timer when session info is set', () async {
        final session = RemoteAssistanceTestData.activeSession();

        when(() => mockService.fetchSessions(
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).thenAnswer((_) async => [session]);

        when(() => mockService.fetchSessionInfo(
              sessionId: any(named: 'sessionId'),
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).thenAnswer((_) async => session);

        when(() => mockService.endSession(
              sessionId: any(named: 'sessionId'),
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).thenAnswer((_) async {});

        final container = createContainer();

        final notifier = container.read(remoteClientProvider.notifier);
        notifier.setCredentials(RemoteAssistanceTestData.credentials());

        await notifier.initiateRemoteAssistance();

        // Wait for timer to tick
        await Future.delayed(const Duration(milliseconds: 1100));

        final state = container.read(remoteClientProvider);
        // expiredIn is 600 (600 seconds remaining), countdown starts at 600
        // After ~1 second, should be around 599
        expect(state.expiredCountdown, isNotNull);
        expect(state.expiredCountdown, lessThan(600));

        // Clean up: end session to stop polling before container dispose
        await notifier.endRemoteAssistance();
        container.dispose();
      });

      test('countdown decrements each second', () async {
        final session = RemoteAssistanceTestData.activeSession();

        when(() => mockService.fetchSessions(
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).thenAnswer((_) async => [session]);

        when(() => mockService.fetchSessionInfo(
              sessionId: any(named: 'sessionId'),
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).thenAnswer((_) async => session);

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(remoteClientProvider.notifier);
        notifier.setCredentials(RemoteAssistanceTestData.credentials());

        await notifier.initiateRemoteAssistance();

        // Record initial countdown
        await Future.delayed(const Duration(milliseconds: 1100));
        final firstRead = container.read(remoteClientProvider).expiredCountdown;

        // Wait another second
        await Future.delayed(const Duration(milliseconds: 1000));
        final secondRead =
            container.read(remoteClientProvider).expiredCountdown;

        expect(firstRead, isNotNull);
        expect(secondRead, isNotNull);
        expect(secondRead!, lessThan(firstRead!));
      });

      test('timer is cancelled when endRemoteAssistance is called', () async {
        final session = RemoteAssistanceTestData.activeSession();

        when(() => mockService.fetchSessions(
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).thenAnswer((_) async => [session]);

        when(() => mockService.fetchSessionInfo(
              sessionId: any(named: 'sessionId'),
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).thenAnswer((_) async => session);

        when(() => mockService.endSession(
              sessionId: any(named: 'sessionId'),
              serialNumber: any(named: 'serialNumber'),
              macAddress: any(named: 'macAddress'),
              deviceUUID: any(named: 'deviceUUID'),
            )).thenAnswer((_) async {});

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(remoteClientProvider.notifier);
        notifier.setCredentials(RemoteAssistanceTestData.credentials());

        await notifier.initiateRemoteAssistance();
        await notifier.endRemoteAssistance();

        // State should be cleared
        final state = container.read(remoteClientProvider);
        expect(state.expiredCountdown, isNull);
      });
    });

    group('DeviceCredentials', () {
      test('stores all required fields', () {
        final creds = DeviceCredentials(
          serialNumber: 'SN123',
          macAddress: 'AA:BB:CC:DD:EE:FF',
          deviceUUID: 'uuid-456',
        );

        expect(creds.serialNumber, 'SN123');
        expect(creds.macAddress, 'AA:BB:CC:DD:EE:FF');
        expect(creds.deviceUUID, 'uuid-456');
      });
    });

    group('RemoteClientState', () {
      test('empty state has expected defaults', () {
        const state = RemoteClientState();

        expect(state.sessionInfo, isNull);
        expect(state.pin, isNull);
        expect(state.sessions, isEmpty);
        expect(state.expiredCountdown, isNull);
      });

      test('copyWith preserves unchanged fields', () {
        final session = RemoteAssistanceTestData.activeSession();
        final state = RemoteClientState(
          sessionInfo: session,
          pin: '123456',
          sessions: [session],
          expiredCountdown: 600,
        );

        final updated = state.copyWith(pin: () => '654321');

        expect(updated.sessionInfo, session);
        expect(updated.pin, '654321');
        expect(updated.sessions, [session]);
        expect(updated.expiredCountdown, 600);
      });

      test('copyWith can set null values', () {
        final session = RemoteAssistanceTestData.activeSession();
        final state = RemoteClientState(
          sessionInfo: session,
          pin: '123456',
        );

        final updated = state.copyWith(
          sessionInfo: () => null,
          pin: () => null,
        );

        expect(updated.sessionInfo, isNull);
        expect(updated.pin, isNull);
      });

      test('equality works correctly', () {
        final session = RemoteAssistanceTestData.activeSession();
        final state1 = RemoteClientState(
          sessionInfo: session,
          pin: '123456',
        );
        final state2 = RemoteClientState(
          sessionInfo: session,
          pin: '123456',
        );

        expect(state1, state2);
      });
    });
  });
}
