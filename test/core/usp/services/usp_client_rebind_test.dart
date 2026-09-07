// #1322: a session swap must not free a `UspClient` that consumers still hold.
//
// THE DEFECT. `RemoteAssistanceNotifier.activate()` used to replace the GetIt
// singleton — `unregister<UspClient>()`, then `oldClient.dispose()`, which
// reaches `free()` on the wasm-bindgen object and zeroes its `__wbg_ptr`. But
// **41** call sites resolve the client with `ref.read(uspClientProvider)` inside
// non-autoDispose provider bodies: they bind it into a service constructor once
// and never re-read. Only the **11** `ref.watch` consumers follow a swap. So a
// second `activate()` in one page lifetime left 41 holders pointing at freed
// memory, and every USP GET through them failed instantly with
// `Error: null pointer passed to rust` until the user refreshed the browser.
//
// THE FIX THESE TESTS PIN. The façade instance becomes stable for the
// container's lifetime and its *transport* is re-pointed instead. Consumers hold
// the façade, so a swap is invisible to them; only the WASM object underneath is
// released.
//
// WHY THE TESTS LIVE HERE AND NOT ON `activate()`. #1322's AC 5 asks for "two
// consecutive `activate()` calls on one container". That is not reachable on the
// VM: `activate()` opens with `if (!kIsWeb) throw UnsupportedError(...)` — a
// guard with a test of its own in `remote_assistance_provider_test.dart` — and
// everything past it builds a wasm-bindgen object. Faking a way in would mean
// either deleting that guard or adding an injectable global, and #1474's
// falsification criterion 2 exists to stop new globals arriving for tests.
//
// So the swap is split where it is honest to split it: the *behaviour* — "a
// captured façade survives a swap and reads through the new session" — is real
// and VM-runnable here, against a fake `UspTransport`, which is the same seam
// demo mode already uses (`demo_usp_transport_composition_test.dart`). The four
// lines in `activate()` that choose register-vs-rebind are structural, and are
// guarded by `remote_assistance_swap_guard_test.dart`.
//
// The fake reproduces the production symptom rather than approximating it: a
// disposed transport throws on **every** member, before issuing a request, which
// is exactly what wasm-bindgen does with a zeroed pointer. A fake that kept
// answering after `dispose()` would let the regression pass.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/services/bridge_request_throttler.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/usp/transport/usp_transport.dart';

/// A [UspTransport] that records what it was asked to do and, once disposed,
/// fails every call the way a freed wasm-bindgen object does.
class _RecordingTransport implements UspTransport {
  _RecordingTransport(this.label);

  final String label;
  bool disposed = false;
  int disposeCount = 0;
  final List<List<String>> getCalls = [];

  /// Lets a test hold `refreshToken()` open so a reauth can be in flight across
  /// a rebind.
  Completer<void>? refreshGate;

  /// Makes reauth Stage 1 fail, so Stage 2 (full re-login) is reached.
  bool failRefresh = false;

  /// Lets a test hold `get()` open so a request can be in flight across a
  /// rebind — which is how it ends up dispatched against a freed transport.
  Completer<void>? getGate;

  /// Models a transport whose release fails (a WASM `free()` that throws).
  bool throwOnDispose = false;

  void _guard() {
    if (disposed) {
      // The production message, so a failure reads like the field report.
      throw StateError('null pointer passed to rust ($label)');
    }
  }

  @override
  bool get isAuthenticated {
    _guard();
    return true;
  }

  @override
  String? get sessionToken {
    _guard();
    return '$label-token';
  }

  @override
  Future<void> login(String password) async => _guard();

  @override
  Future<void> logout() async => _guard();

  int refreshCalls = 0;

  @override
  Future<void> refreshToken({String? token}) async {
    _guard();
    refreshCalls++;
    final gate = refreshGate;
    if (gate != null) await gate.future;
    if (failRefresh) throw StateError('refresh rejected ($label)');
  }

  @override
  Future<Map<String, String>> get(List<String> paths) async {
    _guard();
    getCalls.add(paths);
    final gate = getGate;
    if (gate != null) await gate.future;
    return {for (final p in paths) p: label};
  }

  @override
  Future<Map<String, dynamic>> set(
    Map<String, String> parameters, {
    bool allowPartial = false,
  }) async {
    _guard();
    return {
      'success': true,
      'result': {'data': label}
    };
  }

  @override
  Future<Map<String, dynamic>> setOrdered(
    List<List<Map<String, String>>> parameterGroups, {
    bool allowPartial = false,
  }) async {
    _guard();
    return {
      'success': true,
      'result': {'data': label}
    };
  }

  @override
  Future<Map<String, dynamic>> add(
    List<Map<String, dynamic>> items, {
    bool allowPartial = false,
  }) async {
    _guard();
    return {
      'success': true,
      'result': {'data': label}
    };
  }

  @override
  Future<Map<String, dynamic>> delete(
    List<String> paths, {
    bool allowPartial = false,
  }) async {
    _guard();
    return {
      'success': true,
      'result': {'data': label}
    };
  }

  @override
  Future<Map<String, dynamic>> operate(
    String command, {
    Map<String, String> args = const {},
  }) async {
    _guard();
    return {
      'success': true,
      'result': {'data': label}
    };
  }

  @override
  Future<List<Map<String, dynamic>>> listSubscriptions() async {
    _guard();
    return const [];
  }

  @override
  void dispose() {
    disposed = true;
    disposeCount++;
    if (throwOnDispose) throw StateError('free() failed ($label)');
  }
}

const _path = 'Device.DeviceInfo.Manufacturer';

void main() {
  group('rebindTransport keeps a captured façade usable across a swap', () {
    test('a reference captured before the swap reads the NEW session',
        () async {
      final first = _RecordingTransport('session-1');
      final client = UspClient.withTransport(first, baseUrl: 'https://one');

      // Stands in for the 41 `ref.read(uspClientProvider)` holders: bound once
      // into a service, never re-read.
      final captured = client;
      expect(await captured.get([_path]), {_path: 'session-1'});

      final second = _RecordingTransport('session-2');
      client.rebindTransport(second, baseUrl: 'https://two');

      // The whole issue in one assertion. Before the fix this threw
      // StateError('null pointer passed to rust (session-1)').
      expect(await captured.get([_path]), {_path: 'session-2'});
      expect(second.getCalls, [
        [_path]
      ]);
      // …and nothing further reached the old session.
      expect(first.getCalls, [
        [_path]
      ]);
    });

    test('baseUrl follows the swap', () {
      final client = UspClient.withTransport(
        _RecordingTransport('session-1'),
        baseUrl: 'https://one',
      );
      expect(client.baseUrl, 'https://one');

      client.rebindTransport(_RecordingTransport('session-2'),
          baseUrl: 'https://two');

      // A stale baseUrl is the other half of #1357's hybrid bridge: the façade
      // would answer with the previous session's Guardian origin.
      expect(client.baseUrl, 'https://two');
    });

    test('the old transport is released exactly once (AC 3: no WASM leak)', () {
      final first = _RecordingTransport('session-1');
      final client = UspClient.withTransport(first, baseUrl: 'https://one');

      client.rebindTransport(_RecordingTransport('session-2'),
          baseUrl: 'https://two');

      expect(first.disposed, isTrue,
          reason: 'the previous WASM client must be freed — the point of the '
              'fix is to free the transport instead of the façade, not to stop '
              'freeing anything');
      expect(first.disposeCount, 1);
    });

    test('the incoming transport is NOT disposed', () {
      final second = _RecordingTransport('session-2');
      UspClient.withTransport(_RecordingTransport('session-1'),
              baseUrl: 'https://one')
          .rebindTransport(second, baseUrl: 'https://two');

      expect(second.disposed, isFalse);
    });

    test('repeat activations stay safe — three swaps, one façade', () async {
      final transports = [
        _RecordingTransport('session-1'),
        _RecordingTransport('session-2'),
        _RecordingTransport('session-3'),
        _RecordingTransport('session-4'),
      ];
      final client =
          UspClient.withTransport(transports.first, baseUrl: 'https://s1');
      final captured = client;

      for (var i = 1; i < transports.length; i++) {
        client.rebindTransport(transports[i], baseUrl: 'https://s${i + 1}');
        expect(await captured.get([_path]), {_path: 'session-${i + 1}'});
      }

      // Every superseded transport freed, the live one untouched.
      expect(transports.map((t) => t.disposed).toList(),
          [true, true, true, false]);
      expect(captured.baseUrl, 'https://s4');
    });

    test('rebinding to the transport already in use does not free it',
        () async {
      final only = _RecordingTransport('session-1');
      final client = UspClient.withTransport(only, baseUrl: 'https://one');

      client.rebindTransport(only, baseUrl: 'https://one-again');

      // A self-rebind is reachable from a retry that re-runs the swap with the
      // same wasm object. Disposing here would free the live client — the bug
      // this fix exists to remove, reintroduced by the fix itself.
      expect(only.disposed, isFalse);
      expect(await client.get([_path]), {_path: 'session-1'});
      expect(client.baseUrl, 'https://one-again');
    });
  });

  // #1322 AC 4 is "local (on-router) mode behaviour unchanged", and local mode
  // never calls `activate()` — so the only shared code this change touches is
  // `reauth()`, which had no direct test of its own before this file. These pin
  // the untouched path: with no rebind, `_generation` never moves, every
  // supersession branch is dead, and the two-stage flow behaves exactly as it did.
  group('reauth on a stable connection is unchanged', () {
    test('Stage 1 success reports a refresh and does NOT reconnect SSE',
        () async {
      final transport = _RecordingTransport('session-1');
      final client = UspClient.withTransport(transport, baseUrl: 'https://one');

      var refreshSuccesses = 0;
      var sseReconnects = 0;
      var relogins = 0;
      client.onRefreshTokenSuccess = () => refreshSuccesses++;
      client.onTokenRefreshed = () => sseReconnects++;
      client.onReauthRequired = () async => relogins++;

      await client.reauth();

      expect(refreshSuccesses, 1);
      expect(relogins, 0, reason: 'Stage 2 must not run when Stage 1 works');
      expect(sseReconnects, 0,
          reason: 'a token refresh extends the same session, so SSE stays put');
      expect(client.isReauthInProgress, isFalse);
    });

    test('Stage 2 success reconnects SSE', () async {
      final client = UspClient.withTransport(
          _RecordingTransport('session-1')..failRefresh = true,
          baseUrl: 'https://one');

      var sseReconnects = 0;
      var relogins = 0;
      client.onTokenRefreshed = () => sseReconnects++;
      client.onReauthRequired = () async => relogins++;

      await client.reauth();

      expect(relogins, 1);
      expect(sseReconnects, 1,
          reason: 'a full re-login changes the session token');
      expect(client.isReauthInProgress, isFalse);
    });

    test('both stages failing forces logout and rethrows', () async {
      final client = UspClient.withTransport(
          _RecordingTransport('session-1')..failRefresh = true,
          baseUrl: 'https://one');

      var forcedLogouts = 0;
      client.onForceLogout = () => forcedLogouts++;
      client.onReauthRequired = () async => throw StateError('no stored token');

      await expectLater(client.reauth(), throwsA(isA<StateError>()));

      expect(forcedLogouts, 1);
      expect(client.isReauthInProgress, isFalse);
    });

    test('concurrent callers share one attempt', () async {
      final transport = _RecordingTransport('session-1')
        ..refreshGate = Completer<void>();
      final client = UspClient.withTransport(transport, baseUrl: 'https://one');

      final a = client.reauth();
      final b = client.reauth();
      await Future<void>.delayed(Duration.zero);
      transport.refreshGate!.complete();
      await Future.wait([a, b]);

      expect(transport.refreshCalls, 1,
          reason: 'the Completer lock exists so a burst of 401s does not '
              'refresh the token N times');
    });
  });

  group('rebindTransport resets per-session state', () {
    test('a reauth left in flight does not gate the new session', () async {
      final first = _RecordingTransport('session-1')
        ..refreshGate = Completer<void>();
      final client = UspClient.withTransport(first, baseUrl: 'https://one');

      // Stage 1 of reauth is now parked inside the old transport.
      final pending = client.reauth();
      await Future<void>.delayed(Duration.zero);
      expect(client.isReauthInProgress, isTrue);

      client.rebindTransport(_RecordingTransport('session-2'),
          baseUrl: 'https://two');

      // Left set, a later 401 on the NEW session would await the OLD session's
      // completer, and the old reauth's eventual failure would call
      // onForceLogout — logging the agent out of a session that is fine.
      expect(client.isReauthInProgress, isFalse);

      // The parked reauth must not escape as an unhandled error either.
      first.refreshGate!.complete();
      await expectLater(pending, completes);
    });

    test('a superseded reauth does not re-login the new session', () async {
      // Stage 1 succeeds here, on the transport it was issued against — the
      // repair works, for a connection that no longer exists. Every callback it
      // would normally fire addresses the *current* session, so all three must
      // stay silent.
      final first = _RecordingTransport('session-1')
        ..refreshGate = Completer<void>();
      final client = UspClient.withTransport(first, baseUrl: 'https://one');

      var relogins = 0;
      var refreshSuccesses = 0;
      var sseReconnects = 0;
      client.onReauthRequired = () async => relogins++;
      client.onRefreshTokenSuccess = () => refreshSuccesses++;
      client.onTokenRefreshed = () => sseReconnects++;

      final pending = client.reauth();
      await Future<void>.delayed(Duration.zero);

      client.rebindTransport(_RecordingTransport('session-2'),
          baseUrl: 'https://two');
      first.refreshGate!.complete();
      await pending;

      expect(relogins, 0,
          reason: 'the old connection was repaired after it stopped existing; '
              'Stage 2 would then re-authenticate the NEW connection with the '
              "old session's stored token");
      expect(refreshSuccesses, 0,
          reason: 'UspAuthCoordinator would stamp a refresh timestamp for a '
              'session that no longer exists');
      expect(sseReconnects, 0,
          reason: 'SseManager would reconnect the new session to the old '
              "session's token");
    });

    test('a superseded reauth stops before Stage 2 reaches the new connection',
        () async {
      // Stage 2 authenticates through whatever transport is current *by then*, so
      // a superseded attempt reaching it would run `restoreSession` against the
      // connection that replaced it: the old session's stored token validated
      // against the new host, and on failure cleared and force-logged-out from
      // inside the callback, where `reauth`'s own supersession check cannot see it.
      final first = _RecordingTransport('session-1')
        ..refreshGate = Completer<void>()
        ..failRefresh = true;
      final client = UspClient.withTransport(first, baseUrl: 'https://one');

      var relogins = 0;
      client.onReauthRequired = () async => relogins++;

      final pending = client.reauth();
      await Future<void>.delayed(Duration.zero);

      client.rebindTransport(_RecordingTransport('session-2'),
          baseUrl: 'https://two');
      first.refreshGate!
          .complete(); // Stage 1 now fails, as it would have anyway

      await pending;

      expect(relogins, 0);
      expect(client.isReauthInProgress, isFalse);
    });

    test('a superseded reauth failure does not force logout', () async {
      // The swap has to land *inside* Stage 2 to get here: a reauth superseded
      // any earlier abandons itself before re-logging in.
      final first = _RecordingTransport('session-1')..failRefresh = true;
      final client = UspClient.withTransport(first, baseUrl: 'https://one');

      final reloginGate = Completer<void>();
      var forcedLogouts = 0;
      client.onForceLogout = () => forcedLogouts++;
      client.onReauthRequired = () async {
        await reloginGate.future;
        throw StateError('no stored token');
      };

      final pending = client.reauth();
      await Future<void>.delayed(Duration.zero);

      client.rebindTransport(_RecordingTransport('session-2'),
          baseUrl: 'https://two');
      reloginGate.complete(); // the parked re-login now fails

      await expectLater(pending, throwsA(isA<StateError>()));

      // The worst outcome available here: an unrecoverable *old* session drags
      // the user out of a *new* one that is working. `onForceLogout` navigates to
      // the login screen, so in RA this ends a live Guardian session.
      expect(forcedLogouts, 0);
    });

    test('a re-login that lands on the NEW transport still reconnects SSE',
        () async {
      // The other side of the same coin, and the reason the `onTokenRefreshed`
      // call in `finally` is deliberately *not* gated on supersession. Stage 2
      // succeeded against the live transport, so the live session's token just
      // changed; skipping the reconnect would strand SSE on a dead token.
      final first = _RecordingTransport('session-1')..failRefresh = true;
      final client = UspClient.withTransport(first, baseUrl: 'https://one');

      final reloginGate = Completer<void>();
      var sseReconnects = 0;
      client.onTokenRefreshed = () => sseReconnects++;
      client.onReauthRequired = () => reloginGate.future;

      final pending = client.reauth();
      await Future<void>.delayed(Duration.zero);

      client.rebindTransport(_RecordingTransport('session-2'),
          baseUrl: 'https://two');
      reloginGate.complete();
      await pending;

      expect(sseReconnects, 1);
    });

    test("a superseded reauth does not release a newer reauth's lock",
        () async {
      final first = _RecordingTransport('session-1')
        ..refreshGate = Completer<void>();
      final client = UspClient.withTransport(first, baseUrl: 'https://one');

      final pendingOld = client.reauth();
      await Future<void>.delayed(Duration.zero);

      final second = _RecordingTransport('session-2')
        ..refreshGate = Completer<void>();
      client.rebindTransport(second, baseUrl: 'https://two');

      // A 401 on the NEW session starts its own reauth, and takes the lock the
      // rebind freed.
      final pendingNew = client.reauth();
      await Future<void>.delayed(Duration.zero);
      expect(client.isReauthInProgress, isTrue);

      // The abandoned attempt finishes last — which is the ordering that makes
      // this reachable at all.
      first.refreshGate!.complete();
      await pendingOld;

      expect(client.isReauthInProgress, isTrue,
          reason:
              "the new session's reauth is still in flight; handing its lock "
              'back lets a third reauth start alongside it and refresh the token '
              'twice');

      second.refreshGate!.complete();
      await pendingNew;
      expect(client.isReauthInProgress, isFalse);
    });

    test('an in-flight reauth completing after the swap leaves state clean',
        () async {
      final first = _RecordingTransport('session-1')
        ..refreshGate = Completer<void>();
      final client = UspClient.withTransport(first, baseUrl: 'https://one');

      final pending = client.reauth();
      await Future<void>.delayed(Duration.zero);

      final second = _RecordingTransport('session-2');
      client.rebindTransport(second, baseUrl: 'https://two');
      first.refreshGate!.complete();
      await pending;

      // The superseded reauth must not clear a gate it no longer owns, nor
      // leave one behind.
      expect(client.isReauthInProgress, isFalse);
      expect(await client.get([_path]), {_path: 'session-2'});
    });

    test('a reauth waiter parked on the outgoing gate is released', () async {
      // The owner of the gate is suspended on the transport the swap frees, so
      // it may never resume to settle the gate itself. Nothing above `reauth()`
      // has a timeout, so a second caller parked on that gate waits forever —
      // and it is the *new* session's 401 handler, i.e. the connection that
      // works. `refreshGate` is deliberately never completed here to model
      // exactly that.
      final first = _RecordingTransport('session-1')
        ..refreshGate = Completer<void>();
      final client = UspClient.withTransport(first, baseUrl: 'https://one');

      final owner = client.reauth();
      await Future<void>.delayed(Duration.zero);
      final waiter = client.reauth();
      await Future<void>.delayed(Duration.zero);

      client.rebindTransport(_RecordingTransport('session-2'),
          baseUrl: 'https://two');

      // Bounded so the regression reads as "it hung" in seconds rather than as
      // a 30s suite timeout with no explanation.
      await expectLater(waiter.timeout(const Duration(seconds: 5)), completes);
      // …and the retry it exists to unblock reaches the live session.
      expect(await client.get([_path]), {_path: 'session-2'});

      first.refreshGate!.complete();
      await owner;
    });

    test('the gate owner resuming after the swap does not fail on it',
        () async {
      // The other order: the rebind settles the gate, then Stage 1 finishes and
      // tries to publish its own result. A bare `complete()` there throws
      // `Future already completed` from inside the success path, which the catch
      // below reports as a reauth failure — the opposite of what happened.
      final first = _RecordingTransport('session-1')
        ..refreshGate = Completer<void>();
      final client = UspClient.withTransport(first, baseUrl: 'https://one');

      final owner = client.reauth();
      await Future<void>.delayed(Duration.zero);
      final waiter = client.reauth();
      await Future<void>.delayed(Duration.zero);

      client.rebindTransport(_RecordingTransport('session-2'),
          baseUrl: 'https://two');
      first.refreshGate!.complete();

      await expectLater(owner, completes);
      await expectLater(waiter, completes);
    });
  });

  group('rebindTransport drops the throttler dedup of the old connection', () {
    test('a value cached on the previous connection is not served again',
        () async {
      // The throttler outlives the connection (it is attached by
      // `uspClientProvider`, keyed on nothing) and its cache key is the request
      // *path*, so a 5s-TTL entry from the previous session answers the new one.
      // In Remote Assistance that is a different router, not a stale reading.
      final first = _RecordingTransport('session-1');
      final client = UspClient.withTransport(first, baseUrl: 'https://one');
      client.throttler = BridgeRequestThrottler();

      expect(await client.get([_path]), {_path: 'session-1'});

      final second = _RecordingTransport('session-2');
      client.rebindTransport(second, baseUrl: 'https://two');

      expect(await client.get([_path]), {_path: 'session-2'});
      expect(
          second.getCalls,
          [
            [_path]
          ],
          reason: 'the new session must actually be asked');
    });

    test('a new-session caller is not deduped onto a freed-transport request',
        () async {
      // In-flight dedup is worse than the cache: the action has already run, so
      // it captured the *previous* transport. Joining a new-session caller to it
      // hands them the old router's answer — the request they think they issued
      // was never sent at all.
      final first = _RecordingTransport('session-1')
        ..getGate = Completer<void>();
      final client = UspClient.withTransport(first, baseUrl: 'https://one');
      client.throttler = BridgeRequestThrottler();

      final stranded = client.get([_path]);
      // The throttler drains asynchronously; let it dispatch.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(first.getCalls, isNotEmpty,
          reason: 'must be in flight, not queued');

      final second = _RecordingTransport('session-2');
      client.rebindTransport(second, baseUrl: 'https://two');

      expect(await client.get([_path]), {_path: 'session-2'});

      first.getGate!.complete();
      await stranded; // the original caller still gets its own answer
    });

    test('a request in flight during the swap does not re-populate the cache',
        () async {
      // Dropping the dedup maps is not enough on its own: a request that was
      // already dispatched still *writes* its result to the cache when it lands,
      // so the previous connection's value comes back for another TTL — the same
      // defect, arriving a moment later and looking like a fresh read.
      final first = _RecordingTransport('session-1')
        ..getGate = Completer<void>();
      final client = UspClient.withTransport(first, baseUrl: 'https://one');
      client.throttler = BridgeRequestThrottler();

      final stranded = client.get([_path]);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final second = _RecordingTransport('session-2');
      client.rebindTransport(second, baseUrl: 'https://two');

      // Land the old request *before* the new session asks anything, so the
      // cache is the only place an answer can come from.
      first.getGate!.complete();
      expect(await stranded, {_path: 'session-1'});

      expect(await client.get([_path]), {_path: 'session-2'});
    });

    test('a retired request landing late does not evict its replacement',
        () async {
      // The interaction between the two rules above. Both the old request and its
      // new-session replacement live under the same cache key, so if the retired
      // one clears the slot on its way out it takes the live request's slot with
      // it — and the live result is then treated as retired too, and never
      // cached. Nothing breaks loudly; the session just re-asks the router for a
      // value it already has, for as long as it keeps reading that path.
      final first = _RecordingTransport('session-1')
        ..getGate = Completer<void>();
      final client = UspClient.withTransport(first, baseUrl: 'https://one');
      client.throttler = BridgeRequestThrottler();

      final stranded = client.get([_path]);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final second = _RecordingTransport('session-2')
        ..getGate = Completer<void>();
      client.rebindTransport(second, baseUrl: 'https://two');

      final live = client.get([_path]);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(second.getCalls, hasLength(1));

      // Retired first, live second — the ordering that makes this reachable.
      first.getGate!.complete();
      await stranded;
      second.getGate!.complete();
      expect(await live, {_path: 'session-2'});

      expect(await client.get([_path]), {_path: 'session-2'});
      expect(second.getCalls, hasLength(1),
          reason: 'the live result was cached, so this read is served from it');
    });
  });

  group('rebindTransport completes even when the old transport misbehaves', () {
    test('a transport that throws on release does not abort the swap', () {
      // `_client` is reassigned before the release, so an escaping exception
      // would leave `activate()` believing the rebind failed while it has fully
      // happened — the worst of both readings.
      final first = _RecordingTransport('session-1')..throwOnDispose = true;
      final client = UspClient.withTransport(first, baseUrl: 'https://one');

      final second = _RecordingTransport('session-2');
      expect(() => client.rebindTransport(second, baseUrl: 'https://two'),
          returnsNormally);

      expect(first.disposeCount, 1);
      expect(client.baseUrl, 'https://two');
    });
  });
}
