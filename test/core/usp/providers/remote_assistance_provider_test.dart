import 'dart:io';

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

    test('guardianOrigin prefixes the Guardian API host with https', () {
      const config = RemoteAssistanceConfig(
        guardianBaseUrl: 'qa.guardian.tools',
        sessionId: 'session-123',
        temporaryAccessToken: 'token-abc',
      );

      expect(config.guardianOrigin, 'https://qa.guardian.tools');
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

    // The two tests that used to live here — "deactivate resets state to
    // inactive" and "deactivate invalidates uspClientProvider" — were deleted
    // with the method in #1323 phase 5 (acceptance 10). They were not testing a
    // requirement: `deactivate()` had zero production callers, and these existed
    // because `activate()` throws off the web platform, making `deactivate()` the
    // only notifier method reachable in the VM. What replaces them is the source
    // scan below, which states the requirement the method violated.

    test('no production path frees the registered UspClient façade', () {
      // Acceptance 10, and the reason `deactivate()` is gone rather than rewired.
      //
      // The façade is a wasm-bindgen handle: `UspClient.dispose()` → `free()` →
      // `__wbg_ptr = 0`. 41 call sites resolve it once inside non-autoDispose
      // provider bodies and hold it by value, so freeing it while a session is
      // live leaves every one of them calling into freed memory — `null pointer
      // passed to rust` on every USP request until the browser is refreshed. That
      // was #1322, and `activate()`'s rebind is its fix; a `deactivate()` that
      // still freed the instance re-opened the same hole from the other end.
      //
      // A SOURCE SCAN because there is nothing else that can see it. The sequence
      // compiles, it is correct in isolation (the client really is being cleaned
      // up), and it only misbehaves when *another* object still holds the handle —
      // which no unit test observes, because a VM test never has a live wasm
      // pointer to invalidate. It reproduced only in a browser, as a wave of
      // failures in features that had nothing to do with the session ending.
      // Four spellings of the same mistake, because the deleted `deactivate()`
      // used two of them in sequence and banning only the first leaves three
      // ways to write it back. `unregister` and `resetLazySingleton` both drop
      // GetIt's instance, and GetIt calls `dispose` on the way out for anything
      // registered with a disposer — so the unregister is not merely a leak, it
      // is the free. `getIt.reset(` is the same thing wholesale, and the explicit
      // `dispose()` is the free without the bookkeeping, which is worse: the
      // handle stays registered and every one of the 41 holders keeps a pointer
      // to freed memory with nothing to signal it.
      const banned = <String, String>{
        'unregister<UspClient>': 'unregisters the façade',
        'resetLazySingleton<UspClient>': 'resets the façade registration',
        'getIt<UspClient>().dispose': 'frees the façade directly',
        'getIt.reset(': 'resets all of GetIt, façade included',
      };

      final offenders = <String>[];
      for (final file in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        // Comments stripped first: this very file's `lib/` counterpart documents
        // the removed sequence in prose, naming both calls, so a scan that read
        // comments would report the explanation as the violation.
        final code = file
            .readAsStringSync()
            .split('\n')
            .map((l) => l.replaceFirst(RegExp(r'(?<!:)//.*$'), ''))
            .join('\n');
        for (final entry in banned.entries) {
          if (code.contains(entry.key)) {
            offenders.add('${file.path} (${entry.value})');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'found production code freeing or dropping the registered '
            'UspClient: $offenders. Ending a session must not free the façade — '
            'clear the *session* (RemoteSessionStrategy.end) and let the next '
            'activate() rebind the same instance. If a genuine need to tear the '
            'client down appears, it has to invalidate the 41 holders too, which '
            'means making them watch rather than read; that is a bigger change '
            'than it looks and it is not what this test is blocking.',
      );
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

    test('a fresh container starts inactive and stays inactive', () async {
      // Was 'notifier updates trigger state changes', driven by `deactivate()`.
      // With that method gone the only *state* transition is `activate()`'s, which
      // needs the web platform and a live WASM client — so what is left to assert
      // here is the seed, and that nothing else moves it. Kept rather than deleted
      // because a notifier that emitted `isActive: true` on build would send the
      // `/usp*` guard down the connected branch with no session behind it.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final states = <RemoteAssistanceState>[];
      container.listen(
        remoteAssistanceProvider,
        (_, next) => states.add(next),
        fireImmediately: true,
      );

      expect(states.single.isActive, isFalse);
      expect(states.single.config, isNull);
    });
  });
}
