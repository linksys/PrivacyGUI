import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/services/remote_assistance_service.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_provider.dart';

class MockRemoteAssistanceService extends Mock
    implements RemoteAssistanceService {}

/// Test helper to create a [GRASessionInfo] with default values.
GRASessionInfo createTestSessionInfo({
  String id = 'test-session-id',
  String serialNumber = '65G10M27E03053',
  String modelNumber = 'LN16-EU',
  GRASessionStatus status = GRASessionStatus.active,
  int expiredIn = 600, // 600 seconds remaining (positive = time left)
  int createdAt = 1748315872000,
  int statusChangedAt = 1748315989000,
  int currentTime = 1748316924838,
}) {
  return GRASessionInfo(
    id: id,
    serialNumber: serialNumber,
    modelNumber: modelNumber,
    status: status,
    expiredIn: expiredIn,
    createdAt: createdAt,
    statusChangedAt: statusChangedAt,
    currentTime: currentTime,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  // ---------------------------------------------------------------------------
  // build
  // ---------------------------------------------------------------------------

  group('RemoteAccessNotifier - build', () {
    test('initial state is empty RemoteAccessState', () {
      final container = createContainer();

      final state = container.read(remoteAccessProvider);

      expect(state.sessionInfo, isNull);
      expect(state.sessionToken, isNull);
      expect(state.remainingSeconds, isNull);
      expect(state.expiryTime, isNull);
      container.dispose();
    });

    // Note: Storage restoration tests are skipped since they require web platform
    // and sessionStorage which is stubbed on non-web platforms.
  });

  // ---------------------------------------------------------------------------
  // updateSessionInfo
  // ---------------------------------------------------------------------------

  group('RemoteAccessNotifier - updateSessionInfo', () {
    test('updates state with session info and remaining seconds', () {
      final container = createContainer();
      final notifier = container.read(remoteAccessProvider.notifier);
      final sessionInfo = createTestSessionInfo();

      notifier.updateSessionInfo(sessionInfo, 300, sessionToken: 'test-token');

      final state = container.read(remoteAccessProvider);
      expect(state.sessionInfo, equals(sessionInfo));
      expect(state.sessionToken, 'test-token');
      expect(state.remainingSeconds, 300);
      expect(state.expiryTime, isNotNull);
      container.dispose();
    });

    test('calculates expiry time from remaining seconds', () {
      final container = createContainer();
      final notifier = container.read(remoteAccessProvider.notifier);
      final sessionInfo = createTestSessionInfo();
      final beforeUpdate = DateTime.now();

      notifier.updateSessionInfo(sessionInfo, 600);

      final state = container.read(remoteAccessProvider);
      final afterUpdate = DateTime.now();
      // Expiry time should be approximately now + 600 seconds
      expect(
        state.expiryTime!
            .isAfter(beforeUpdate.add(const Duration(seconds: 599))),
        isTrue,
      );
      expect(
        state.expiryTime!
            .isBefore(afterUpdate.add(const Duration(seconds: 601))),
        isTrue,
      );
      container.dispose();
    });

    test('clears session when info is null', () {
      final container = createContainer();
      final notifier = container.read(remoteAccessProvider.notifier);
      final sessionInfo = createTestSessionInfo();

      // First set a session
      notifier.updateSessionInfo(sessionInfo, 300, sessionToken: 'test-token');
      expect(container.read(remoteAccessProvider).sessionInfo, isNotNull);

      // Then clear it
      notifier.updateSessionInfo(null, null);

      final state = container.read(remoteAccessProvider);
      expect(state.sessionInfo, isNull);
      expect(state.sessionToken, isNull);
      expect(state.remainingSeconds, isNull);
      container.dispose();
    });

    test('clears session when remaining seconds is null', () {
      final container = createContainer();
      final notifier = container.read(remoteAccessProvider.notifier);
      final sessionInfo = createTestSessionInfo();

      // First set a session
      notifier.updateSessionInfo(sessionInfo, 300, sessionToken: 'test-token');

      // Then clear it by passing null remaining seconds
      notifier.updateSessionInfo(sessionInfo, null);

      final state = container.read(remoteAccessProvider);
      expect(state.sessionInfo, isNull);
      container.dispose();
    });

    test('preserves existing session token if not provided', () {
      final container = createContainer();
      final notifier = container.read(remoteAccessProvider.notifier);
      final sessionInfo = createTestSessionInfo();

      // Set initial session with token
      notifier.updateSessionInfo(sessionInfo, 300,
          sessionToken: 'initial-token');
      expect(
          container.read(remoteAccessProvider).sessionToken, 'initial-token');

      // Update without providing token - token should be preserved via copyWith
      final updatedInfo = createTestSessionInfo(expiredIn: 500);
      notifier.updateSessionInfo(updatedInfo, 500);

      final state = container.read(remoteAccessProvider);
      expect(state.sessionToken, 'initial-token');
      container.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // clearSession
  // ---------------------------------------------------------------------------

  group('RemoteAccessNotifier - clearSession', () {
    test('clears all session state', () {
      final container = createContainer();
      final notifier = container.read(remoteAccessProvider.notifier);
      final sessionInfo = createTestSessionInfo();

      // Set a session first
      notifier.updateSessionInfo(sessionInfo, 300, sessionToken: 'test-token');
      expect(container.read(remoteAccessProvider).sessionInfo, isNotNull);

      // Clear it
      notifier.clearSession();

      final state = container.read(remoteAccessProvider);
      expect(state.sessionInfo, isNull);
      expect(state.sessionToken, isNull);
      expect(state.remainingSeconds, isNull);
      expect(state.expiryTime, isNull);
      container.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // Timer behavior - countdown
  // ---------------------------------------------------------------------------

  group('RemoteAccessNotifier - countdown timer', () {
    test('countdown timer decrements remaining seconds every second', () {
      fakeAsync((async) {
        final container = createContainer();
        final notifier = container.read(remoteAccessProvider.notifier);
        final sessionInfo = createTestSessionInfo();

        notifier.updateSessionInfo(sessionInfo, 10, sessionToken: 'test-token');
        async.flushMicrotasks();

        expect(container.read(remoteAccessProvider).remainingSeconds, 10);

        // Advance 3 seconds
        async.elapse(const Duration(seconds: 3));

        expect(container.read(remoteAccessProvider).remainingSeconds, 7);

        container.dispose();
      });
    });

    test('countdown timer stops at zero', () {
      fakeAsync((async) {
        final container = createContainer();
        final notifier = container.read(remoteAccessProvider.notifier);
        final sessionInfo = createTestSessionInfo();

        notifier.updateSessionInfo(sessionInfo, 3, sessionToken: 'test-token');
        async.flushMicrotasks();

        // Advance past the expiry
        async.elapse(const Duration(seconds: 5));

        expect(container.read(remoteAccessProvider).remainingSeconds, 0);

        container.dispose();
      });
    });

    test('clearSession cancels countdown timer', () {
      fakeAsync((async) {
        final container = createContainer();
        final notifier = container.read(remoteAccessProvider.notifier);
        final sessionInfo = createTestSessionInfo();

        notifier.updateSessionInfo(sessionInfo, 100,
            sessionToken: 'test-token');
        async.flushMicrotasks();

        // Advance a few seconds
        async.elapse(const Duration(seconds: 2));
        expect(container.read(remoteAccessProvider).remainingSeconds, 98);

        // Clear the session
        notifier.clearSession();
        async.flushMicrotasks();

        // Advance more time - should not crash or change state
        async.elapse(const Duration(seconds: 10));

        expect(container.read(remoteAccessProvider).remainingSeconds, isNull);

        container.dispose();
      });
    });

    test('updating session info restarts countdown timer', () {
      fakeAsync((async) {
        final container = createContainer();
        final notifier = container.read(remoteAccessProvider.notifier);
        final sessionInfo = createTestSessionInfo();

        // Start with 100 seconds
        notifier.updateSessionInfo(sessionInfo, 100,
            sessionToken: 'test-token');
        async.flushMicrotasks();

        // Advance 10 seconds
        async.elapse(const Duration(seconds: 10));
        expect(container.read(remoteAccessProvider).remainingSeconds, 90);

        // Update with new session info and 50 seconds
        notifier.updateSessionInfo(sessionInfo, 50, sessionToken: 'test-token');
        async.flushMicrotasks();

        // Should reset to 50
        expect(container.read(remoteAccessProvider).remainingSeconds, 50);

        // Advance another 5 seconds
        async.elapse(const Duration(seconds: 5));
        expect(container.read(remoteAccessProvider).remainingSeconds, 45);

        container.dispose();
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Timer behavior - polling
  // ---------------------------------------------------------------------------

  group('RemoteAccessNotifier - polling timer', () {
    test('polling timer calls service every 30 seconds', () {
      fakeAsync((async) {
        when(() => mockService.fetchSessionInfoForCA(
              sessionToken: any(named: 'sessionToken'),
              sessionId: any(named: 'sessionId'),
            )).thenAnswer((_) async => createTestSessionInfo(expiredIn: 500));

        final container = createContainer();
        final notifier = container.read(remoteAccessProvider.notifier);
        final sessionInfo = createTestSessionInfo();

        notifier.updateSessionInfo(
          sessionInfo,
          600,
          sessionToken: 'test-token',
        );
        async.flushMicrotasks();

        // No poll yet
        verifyNever(() => mockService.fetchSessionInfoForCA(
              sessionToken: any(named: 'sessionToken'),
              sessionId: any(named: 'sessionId'),
            ));

        // Advance 30 seconds - first poll
        async.elapse(const Duration(seconds: 30));
        async.flushMicrotasks();

        verify(() => mockService.fetchSessionInfoForCA(
              sessionToken: 'test-token',
              sessionId: 'test-session-id',
            )).called(1);

        // Advance another 30 seconds - second poll
        async.elapse(const Duration(seconds: 30));
        async.flushMicrotasks();

        verify(() => mockService.fetchSessionInfoForCA(
              sessionToken: 'test-token',
              sessionId: 'test-session-id',
            )).called(1);

        container.dispose();
      });
    });

    test('polling updates state with fetched session info', () {
      fakeAsync((async) {
        final updatedInfo = createTestSessionInfo(
          expiredIn: 400, // 400 seconds remaining (positive = time left)
          status: GRASessionStatus.active,
        );
        when(() => mockService.fetchSessionInfoForCA(
              sessionToken: any(named: 'sessionToken'),
              sessionId: any(named: 'sessionId'),
            )).thenAnswer((_) async => updatedInfo);

        final container = createContainer();
        final notifier = container.read(remoteAccessProvider.notifier);
        final sessionInfo = createTestSessionInfo();

        notifier.updateSessionInfo(
          sessionInfo,
          600,
          sessionToken: 'test-token',
        );
        async.flushMicrotasks();

        // Advance to trigger poll
        async.elapse(const Duration(seconds: 30));
        async.flushMicrotasks();

        final state = container.read(remoteAccessProvider);
        expect(state.sessionInfo, equals(updatedInfo));
        // remainingSeconds should be updated from API response
        expect(state.remainingSeconds, 400);

        container.dispose();
      });
    });

    test('polling stops when session becomes invalid', () {
      fakeAsync((async) {
        final invalidInfo = createTestSessionInfo(
          status: GRASessionStatus.invalid,
          expiredIn: 0,
        );
        when(() => mockService.fetchSessionInfoForCA(
              sessionToken: any(named: 'sessionToken'),
              sessionId: any(named: 'sessionId'),
            )).thenAnswer((_) async => invalidInfo);

        final container = createContainer();
        final notifier = container.read(remoteAccessProvider.notifier);
        final sessionInfo = createTestSessionInfo();

        notifier.updateSessionInfo(
          sessionInfo,
          600,
          sessionToken: 'test-token',
        );
        async.flushMicrotasks();

        // First poll - returns invalid
        async.elapse(const Duration(seconds: 30));
        async.flushMicrotasks();

        verify(() => mockService.fetchSessionInfoForCA(
              sessionToken: any(named: 'sessionToken'),
              sessionId: any(named: 'sessionId'),
            )).called(1);

        // Clear mock interactions
        clearInteractions(mockService);

        // Second poll period - should not poll since session is invalid
        async.elapse(const Duration(seconds: 30));
        async.flushMicrotasks();

        verifyNever(() => mockService.fetchSessionInfoForCA(
              sessionToken: any(named: 'sessionToken'),
              sessionId: any(named: 'sessionId'),
            ));

        container.dispose();
      });
    });

    test('polling handles service errors gracefully', () {
      fakeAsync((async) {
        when(() => mockService.fetchSessionInfoForCA(
              sessionToken: any(named: 'sessionToken'),
              sessionId: any(named: 'sessionId'),
            )).thenThrow(Exception('Network error'));

        final container = createContainer();
        final notifier = container.read(remoteAccessProvider.notifier);
        final sessionInfo = createTestSessionInfo();

        notifier.updateSessionInfo(
          sessionInfo,
          600,
          sessionToken: 'test-token',
        );
        async.flushMicrotasks();

        // Advance to trigger poll - should not throw
        async.elapse(const Duration(seconds: 30));
        async.flushMicrotasks();

        // State should remain unchanged
        final state = container.read(remoteAccessProvider);
        expect(state.sessionInfo, equals(sessionInfo));
        expect(state.remainingSeconds, lessThan(600)); // countdown continued

        container.dispose();
      });
    });

    test('polling does not start without session token', () {
      fakeAsync((async) {
        final container = createContainer();
        final notifier = container.read(remoteAccessProvider.notifier);
        final sessionInfo = createTestSessionInfo();

        // Update without session token
        notifier.updateSessionInfo(sessionInfo, 600);
        async.flushMicrotasks();

        // Advance past poll interval
        async.elapse(const Duration(seconds: 60));
        async.flushMicrotasks();

        // Should not have called service
        verifyNever(() => mockService.fetchSessionInfoForCA(
              sessionToken: any(named: 'sessionToken'),
              sessionId: any(named: 'sessionId'),
            ));

        container.dispose();
      });
    });

    test('clearSession cancels polling timer', () {
      fakeAsync((async) {
        when(() => mockService.fetchSessionInfoForCA(
              sessionToken: any(named: 'sessionToken'),
              sessionId: any(named: 'sessionId'),
            )).thenAnswer((_) async => createTestSessionInfo());

        final container = createContainer();
        final notifier = container.read(remoteAccessProvider.notifier);
        final sessionInfo = createTestSessionInfo();

        notifier.updateSessionInfo(
          sessionInfo,
          600,
          sessionToken: 'test-token',
        );
        async.flushMicrotasks();

        // Advance 20 seconds (before first poll)
        async.elapse(const Duration(seconds: 20));

        // Clear session
        notifier.clearSession();
        async.flushMicrotasks();

        // Advance past when poll would have occurred
        async.elapse(const Duration(seconds: 30));
        async.flushMicrotasks();

        // Should not have called service
        verifyNever(() => mockService.fetchSessionInfoForCA(
              sessionToken: any(named: 'sessionToken'),
              sessionId: any(named: 'sessionId'),
            ));

        container.dispose();
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Timer cleanup on dispose
  // ---------------------------------------------------------------------------

  group('RemoteAccessNotifier - dispose', () {
    test('timers are cancelled when provider is disposed', () {
      fakeAsync((async) {
        when(() => mockService.fetchSessionInfoForCA(
              sessionToken: any(named: 'sessionToken'),
              sessionId: any(named: 'sessionId'),
            )).thenAnswer((_) async => createTestSessionInfo());

        final container = createContainer();
        final notifier = container.read(remoteAccessProvider.notifier);
        final sessionInfo = createTestSessionInfo();

        notifier.updateSessionInfo(
          sessionInfo,
          600,
          sessionToken: 'test-token',
        );
        async.flushMicrotasks();

        // Advance a bit
        async.elapse(const Duration(seconds: 10));

        // Dispose container
        container.dispose();

        // Advance past poll interval - should not throw or call service
        async.elapse(const Duration(seconds: 60));
        async.flushMicrotasks();

        verifyNever(() => mockService.fetchSessionInfoForCA(
              sessionToken: any(named: 'sessionToken'),
              sessionId: any(named: 'sessionId'),
            ));
      });
    });
  });

  // ---------------------------------------------------------------------------
  // expiredIn calculation
  // ---------------------------------------------------------------------------

  group('RemoteAccessNotifier - expiredIn handling', () {
    test('negative expiredIn is converted to positive remaining seconds', () {
      fakeAsync((async) {
        final infoWithNegativeExpiredIn = createTestSessionInfo(
          expiredIn: -750, // 750 seconds remaining (negative = time left)
        );
        when(() => mockService.fetchSessionInfoForCA(
              sessionToken: any(named: 'sessionToken'),
              sessionId: any(named: 'sessionId'),
            )).thenAnswer((_) async => infoWithNegativeExpiredIn);

        final container = createContainer();
        final notifier = container.read(remoteAccessProvider.notifier);
        final sessionInfo = createTestSessionInfo();

        notifier.updateSessionInfo(
          sessionInfo,
          600,
          sessionToken: 'test-token',
        );
        async.flushMicrotasks();

        // Trigger poll
        async.elapse(const Duration(seconds: 30));
        async.flushMicrotasks();

        final state = container.read(remoteAccessProvider);
        expect(state.remainingSeconds, 750);

        container.dispose();
      });
    });

    test('positive expiredIn uses abs() for forward compatibility', () {
      // Cloud API will change expiredIn from negative to positive in future.
      // Using abs() ensures both conventions work.
      fakeAsync((async) {
        final infoWithPositiveExpiredIn = createTestSessionInfo(
          expiredIn: 500, // Future format: positive = remaining seconds
        );
        when(() => mockService.fetchSessionInfoForCA(
              sessionToken: any(named: 'sessionToken'),
              sessionId: any(named: 'sessionId'),
            )).thenAnswer((_) async => infoWithPositiveExpiredIn);

        final container = createContainer();
        final notifier = container.read(remoteAccessProvider.notifier);
        final sessionInfo = createTestSessionInfo();

        notifier.updateSessionInfo(
          sessionInfo,
          600,
          sessionToken: 'test-token',
        );
        async.flushMicrotasks();

        // Trigger poll
        async.elapse(const Duration(seconds: 30));
        async.flushMicrotasks();

        final state = container.read(remoteAccessProvider);
        expect(state.remainingSeconds, 500); // abs(500) = 500

        container.dispose();
      });
    });
  });
}
