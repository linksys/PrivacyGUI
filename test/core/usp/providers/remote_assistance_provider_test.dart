import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/providers/remote_assistance_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/usp/transport/usp_transport.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

class MockAuthNotifier extends Mock implements AuthNotifier {}

/// Stands in for a live connection so a `UspClient` can be registered in GetIt
/// without a wasm runtime. Nothing below calls through it.
class MockUspTransport extends Mock implements UspTransport {}

/// Counts releases instead of performing them.
///
/// The property under test is "exactly once", not "via interop" — and the real
/// implementation reaches `UspClient.fromBuilder`, which refuses off the web
/// platform, so a VM test cannot let it run and still learn anything. A subclass
/// plus a provider override rather than a mutable static hook: #1474's
/// falsification criterion 2 is that a lifecycle test needs no global.
class _CountingNotifier extends RemoteAssistanceNotifier {
  int releases = 0;
  final List<dynamic> released = [];

  @override
  void releaseOrphanedHandle(dynamic jsClient, String baseUrl) {
    releases++;
    released.add(jsClient);
  }
}

/// A release that fails, with an error nothing else in the flow throws.
///
/// The distinct type is the whole reason it is injected: the production release path
/// throws the same `UnsupportedError` as the installation it is cleaning up after,
/// so provoking it naturally would produce a test that cannot fail.
class _ExplodingReleaseNotifier extends _CountingNotifier {
  @override
  void releaseOrphanedHandle(dynamic jsClient, String baseUrl) {
    super.releaseOrphanedHandle(jsClient, baseUrl);
    throw StateError('free() on a handle that was already dead');
  }
}

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
  // installTransport — #1322's ownership question, read the other way
  // ---------------------------------------------------------------------------

  group('installTransport releases a handle nobody took', () {
    // WHAT THIS IS. #1322 fixed a handle being freed while 41 services still held
    // it. This is the same question from the other end: `activate()` builds the wasm
    // client *before* taking the mutation lock, deliberately — construction races
    // with nothing — so between `builder.build()` and a façade wrapping it, the only
    // reference to a live wasm-bindgen object is a local variable. If the critical
    // section throws, that variable goes out of scope with the object still
    // allocated and nothing left to call `free()` on. One leak per failed attempt,
    // on the path a user retries: a Guardian that rejects the token, a supporter
    // link that has expired.
    //
    // WHY IT IS TESTABLE AT ALL, given `activate()` refuses off-web on its first
    // line. The critical section is extracted into `installTransport`, and the
    // ownership rule it enforces is platform-independent. In the VM both
    // installation paths fail at their own `kIsWeb` guard — `rebindFromBuilder` and
    // `UspClient.fromBuilder` — which is a truthful "installation threw" with no
    // mock standing in for the failure. The handle is a plain sentinel because
    // nothing ever dereferences it on this path; only its identity is asserted.
    late ProviderContainer container;
    late _CountingNotifier notifier;

    /// An opaque stand-in for `UspClientBuilderJS.build()`'s return value.
    final handle = Object();

    setUp(() {
      notifier = _CountingNotifier();
      container = ProviderContainer(overrides: [
        remoteAssistanceProvider.overrideWith(() => notifier),
      ]);
      addTearDown(container.dispose);
      // Registered per test rather than in a `tearDown` reading a `late` field: a
      // leftover singleton makes the *next* test take the rebind branch, and the
      // whole point of the pair below is which branch ran.
      //
      // Restores rather than clears, and the difference is not academic. `getIt` is
      // a process-global; an unconditional `unregister` would delete whatever was
      // there before this test regardless of who put it there, and the failure it
      // causes is a *branch-coverage lie* — a later test silently taking the
      // register path — not a crash anyone would trace back here. So: remove only
      // what this test itself added.
      final preexisting =
          getIt.isRegistered<UspClient>() ? getIt<UspClient>() : null;
      addTearDown(() {
        if (getIt.isRegistered<UspClient>() &&
            !identical(getIt<UspClient>(), preexisting)) {
          getIt.unregister<UspClient>();
        }
      });
    });

    test('with nothing registered, the orphan is released exactly once',
        () async {
      // The first-activation path: `UspClient.fromBuilder` throws before anything
      // owns the handle, so the handle is an orphan and this is the only code that
      // can free it.
      await expectLater(
        container
            .read(remoteAssistanceProvider.notifier)
            .installTransport(handle, 'https://guardian.example.com'),
        throwsUnsupportedError,
      );

      expect(notifier.releases, 1);
      expect(notifier.released.single, same(handle),
          reason:
              'released something other than the handle that was passed in, '
              'which means the leaked object is still leaked and a different one '
              'was freed');
    });

    test('with a client registered, the orphan is still released exactly once',
        () async {
      // The re-activation path, and the branch where getting it wrong is worse.
      // `rebindFromBuilder` throws *before* `rebindTransport` assigns anything, so
      // the registered façade still owns its previous handle and the new one is the
      // orphan. Freeing the registered façade instead would be #1322 all over again.
      getIt.registerSingleton<UspClient>(
          UspClient.withTransport(MockUspTransport()));

      await expectLater(
        container
            .read(remoteAssistanceProvider.notifier)
            .installTransport(handle, 'https://guardian.example.com'),
        throwsUnsupportedError,
      );

      expect(notifier.releases, 1);
      expect(getIt.isRegistered<UspClient>(), isTrue,
          reason: 'a failed installation unregistered the live façade. The 41 '
              'services that resolved it hold it by value and never re-read, so '
              'this is the shape of #1322: a retry would register a second '
              'instance and leave every one of them on the first.');
    });

    test('a cleanup that fails does not replace the error the caller sees',
        () async {
      // The release path reaches interop too — it wraps the handle in a throwaway
      // `UspClient.fromBuilder` to get at `free()` — so a handle that is already
      // dead, or was never a wasm object, throws from inside the `catch`. Unguarded,
      // that second throw replaces the first: the confirm view turns whatever
      // surfaces into its "Connection failed" copy, and it would be reporting the
      // tidy-up instead of the Guardian's rejection.
      //
      // The failure is injected rather than provoked, because in the VM the
      // production release path throws the *same* `UnsupportedError` with the same
      // message as the installation it is cleaning up after — so a test that let it
      // run could not tell which one it caught, and would pass whether the guard
      // existed or not.
      final exploding = _ExplodingReleaseNotifier();
      final c = ProviderContainer(overrides: [
        remoteAssistanceProvider.overrideWith(() => exploding),
      ]);
      addTearDown(c.dispose);

      await expectLater(
        c
            .read(remoteAssistanceProvider.notifier)
            .installTransport(handle, 'https://guardian.example.com'),
        throwsUnsupportedError,
      );
      expect(exploding.releases, 1,
          reason: 'the release was never attempted, so this test is not '
              'measuring the guard');
    });

    // NOT COVERED HERE, and worth saying so rather than leaving the gap to be
    // discovered. Everything on the `handleOwned == true` side of the rule is
    // unreachable in the VM, for the same reason that makes the tests above possible:
    // wrapping the handle is what fails off-web, so the flag can never be true by the
    // time the `catch` runs. Two claims live on that side —
    //
    //   - the `pendingFacade?.dispose()` arm, which fires when a façade wrapped the
    //     handle and then `registerSingleton` threw;
    //   - that the release is *skipped* when a façade did take ownership, which is
    //     the difference between recovering a leak and double-freeing the live
    //     connection.
    //
    // Measured, not assumed: a mutation releasing unconditionally passed all three
    // tests above. Both are pinned structurally instead, in
    // `remote_assistance_swap_guard_test.dart` — the disposal census requires that
    // exact `dispose()` line, and a separate test requires the `if (!handleOwned)`
    // guard around it.
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
