import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/providers/remote_assistance_provider.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

class MockAuthNotifier extends Mock implements AuthNotifier {}

void main() {
  setUpAll(() {
    registerFallbackValue(LoginType.none);
  });
  // ---------------------------------------------------------------------------
  // RemoteAssistanceConfig
  // ---------------------------------------------------------------------------

  group('RemoteAssistanceConfig', () {
    test('constructs with required parameters', () {
      const config = RemoteAssistanceConfig(
        guardianBaseUrl: 'api.example.com',
        sessionId: 'session-123',
        temporaryAccessToken: 'token-abc',
      );

      expect(config.guardianBaseUrl, 'api.example.com');
      expect(config.sessionId, 'session-123');
      expect(config.temporaryAccessToken, 'token-abc');
      expect(config.clientTypeId, isNull);
    });

    test('constructs with optional clientTypeId', () {
      const config = RemoteAssistanceConfig(
        guardianBaseUrl: 'api.example.com',
        sessionId: 'session-123',
        temporaryAccessToken: 'token-abc',
        clientTypeId: 'client-type-456',
      );

      expect(config.clientTypeId, 'client-type-456');
    });

    test('uspEndpoint returns correct path format', () {
      const config = RemoteAssistanceConfig(
        guardianBaseUrl: 'api.example.com',
        sessionId: 'abc-123-def',
        temporaryAccessToken: 'token-abc',
      );

      expect(
        config.uspEndpoint,
        '/v1/guardians/remote-assistances/sessions/abc-123-def/actions/usp',
      );
    });

    test('toString provides readable representation', () {
      const config = RemoteAssistanceConfig(
        guardianBaseUrl: 'api.example.com',
        sessionId: 'session-123',
        temporaryAccessToken: 'token-abc',
      );

      expect(
        config.toString(),
        'RemoteAssistanceConfig(session=session-123, url=api.example.com)',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // RemoteAssistanceState
  // ---------------------------------------------------------------------------

  group('RemoteAssistanceState', () {
    test('default constructor creates inactive state', () {
      const state = RemoteAssistanceState();

      expect(state.isActive, false);
      expect(state.config, isNull);
    });

    test('constructor with parameters', () {
      const config = RemoteAssistanceConfig(
        guardianBaseUrl: 'api.example.com',
        sessionId: 'session-123',
        temporaryAccessToken: 'token-abc',
      );
      const state = RemoteAssistanceState(isActive: true, config: config);

      expect(state.isActive, true);
      expect(state.config, config);
    });

    test('copyWith creates new instance with updated values', () {
      const config = RemoteAssistanceConfig(
        guardianBaseUrl: 'api.example.com',
        sessionId: 'session-123',
        temporaryAccessToken: 'token-abc',
      );
      const state = RemoteAssistanceState();

      final updated = state.copyWith(isActive: true, config: config);

      expect(updated.isActive, true);
      expect(updated.config, config);
      // Original unchanged
      expect(state.isActive, false);
      expect(state.config, isNull);
    });

    test('copyWith preserves existing values when not specified', () {
      const config = RemoteAssistanceConfig(
        guardianBaseUrl: 'api.example.com',
        sessionId: 'session-123',
        temporaryAccessToken: 'token-abc',
      );
      const state = RemoteAssistanceState(isActive: true, config: config);

      final updated = state.copyWith();

      expect(updated.isActive, true);
      expect(updated.config, config);
    });

    test('toString provides readable representation', () {
      const state = RemoteAssistanceState();

      expect(
        state.toString(),
        'RemoteAssistanceState(active=false, config=null)',
      );
    });

    test('toString with active state', () {
      const config = RemoteAssistanceConfig(
        guardianBaseUrl: 'api.example.com',
        sessionId: 'session-123',
        temporaryAccessToken: 'token-abc',
      );
      const state = RemoteAssistanceState(isActive: true, config: config);

      expect(
        state.toString(),
        'RemoteAssistanceState(active=true, config=RemoteAssistanceConfig(session=session-123, url=api.example.com))',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // RemoteAssistanceNotifier
  // ---------------------------------------------------------------------------

  group('RemoteAssistanceNotifier', () {
    late ProviderContainer container;
    late MockAuthNotifier mockAuthNotifier;

    setUp(() {
      mockAuthNotifier = MockAuthNotifier();

      // Mock setLoginType for activate tests
      when(() => mockAuthNotifier.setLoginType(any())).thenReturn(null);

      container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => mockAuthNotifier),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('build returns inactive state', () {
      final state = container.read(remoteAssistanceProvider);

      expect(state.isActive, false);
      expect(state.config, isNull);
    });

    test('deactivate resets state to inactive', () {
      // First manually set an active state via notifier
      final notifier = container.read(remoteAssistanceProvider.notifier);

      // Call deactivate
      notifier.deactivate();

      final state = container.read(remoteAssistanceProvider);
      expect(state.isActive, false);
      expect(state.config, isNull);
    });

    // activate() requires web platform and WASM — test the platform check
    test('activate throws UnsupportedError on non-web platform', () async {
      const config = RemoteAssistanceConfig(
        guardianBaseUrl: 'api.example.com',
        sessionId: 'session-123',
        temporaryAccessToken: 'token-abc',
      );

      final notifier = container.read(remoteAssistanceProvider.notifier);

      // Since we're running in VM (not web), kIsWeb is false
      // and activate should throw UnsupportedError
      expect(
        () => notifier.activate(config),
        throwsA(isA<UnsupportedError>().having(
          (e) => e.message,
          'message',
          'Remote Assistance is only supported on Web',
        )),
      );
    });

    test('state remains unchanged after failed activate', () async {
      const config = RemoteAssistanceConfig(
        guardianBaseUrl: 'api.example.com',
        sessionId: 'session-123',
        temporaryAccessToken: 'token-abc',
      );

      final notifier = container.read(remoteAssistanceProvider.notifier);

      try {
        await notifier.activate(config);
      } catch (_) {
        // Expected to throw
      }

      final state = container.read(remoteAssistanceProvider);
      expect(state.isActive, false);
      expect(state.config, isNull);
    });

    test('authProvider setLoginType not called after failed activate',
        () async {
      const config = RemoteAssistanceConfig(
        guardianBaseUrl: 'api.example.com',
        sessionId: 'session-123',
        temporaryAccessToken: 'token-abc',
      );

      final notifier = container.read(remoteAssistanceProvider.notifier);

      try {
        await notifier.activate(config);
      } catch (_) {
        // Expected to throw
      }

      verifyNever(() => mockAuthNotifier.setLoginType(any()));
    });
  });

  // ---------------------------------------------------------------------------
  // Provider integration
  // ---------------------------------------------------------------------------

  group('remoteAssistanceProvider integration', () {
    test('provider is a NotifierProvider', () {
      expect(
          remoteAssistanceProvider,
          isA<
              NotifierProvider<RemoteAssistanceNotifier,
                  RemoteAssistanceState>>());
    });

    test('multiple reads return same state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state1 = container.read(remoteAssistanceProvider);
      final state2 = container.read(remoteAssistanceProvider);

      expect(identical(state1, state2), isTrue);
    });

    test('notifier updates trigger state changes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final states = <RemoteAssistanceState>[];
      container.listen(
        remoteAssistanceProvider,
        (_, next) => states.add(next),
        fireImmediately: true,
      );

      final notifier = container.read(remoteAssistanceProvider.notifier);
      notifier.deactivate();

      // Initial state + state after deactivate
      expect(states.length, greaterThanOrEqualTo(1));
      expect(states.last.isActive, false);
    });
  });
}
