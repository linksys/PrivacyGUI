import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart'
    show isUspClientFaultCode, unwrapUspClientError;
import 'package:privacy_gui/core/usp/transport/usp_transport.dart';
import 'package:privacy_gui/core/utils/logger.dart';

import 'bridge_request_throttler.dart';
import 'session_auth_gate.dart';
import 'session_restore_outcome.dart';

// Conditional import: use WASM client on Web, stub on other platforms (VM/tests).
import '../stub/usp_client_stub.dart'
    if (dart.library.js_interop) '../web/usp_client_wasm.dart';

// Export response helpers so generated code only needs one import.
export 'usp_response_helpers.dart';
// Export RequestPriority so generated fetch() methods can accept priority.
export 'bridge_request_throttler.dart' show RequestPriority;
// Export USP operation result types for application layer use.
export '../models/usp_operation_result.dart';
// Export builder for Remote Assistance mode (platform-agnostic entry point).
export '../web/usp_client_builder.dart';

// ===========================================================================
// USP Subscription types (used by codegen-generated subscribe methods)
// ===========================================================================

/// USP Notification types as defined in TR-369 §7.2
enum NotifType {
  valueChange,
  objectCreation,
  objectDeletion,
  operationComplete,
  onBoardRequest,
  event,
}

/// SSE subscription delegate. Set by [SseManager] to enable SSE-backed
/// subscriptions. When null, [UspClient.subscribe] falls back to polling.
typedef SseSubscribeDelegate = Future<
        ({void Function() removeHandler, Future<void> Function() unregister})>
    Function({
  required String subscriptionId,
  required String notifType,
  required String referenceList,
  required void Function() onNotification,
});

/// Represents an active USP subscription that delivers typed updates.
///
/// Wraps a [Stream] of parsed model objects, with the ability to cancel
/// the subscription when it is no longer needed.
class Subscription<T> {
  final String id;
  final NotifType notifType;
  final Stream<T> stream;
  final Future<void> Function() _cancel;

  Subscription({
    required this.id,
    required this.notifType,
    required this.stream,
    required Future<void> Function() cancel,
  }) : _cancel = cancel;

  /// Cancel this subscription (sends USP Unsubscribe).
  Future<void> cancel() => _cancel();
}

/// Platform-agnostic Service for interacting with the router via USP.
///
/// **This instance is meant to outlive any one connection.** The transport
/// underneath it can be swapped with [rebindTransport] / [rebindFromBuilder];
/// the façade itself must not be replaced while the app is running, and #1322 is
/// the bug report explaining why. Remote Assistance used to `dispose()` this
/// object and register a fresh one in GetIt on every `activate()`, but **41**
/// call sites resolve it with `ref.read(uspClientProvider)` in a non-autoDispose
/// provider body — they bind it into a service constructor once and never look
/// again — against **11** that `ref.watch` and would follow a swap. Freeing the
/// façade therefore left 41 services holding a wasm-bindgen object whose
/// `__wbg_ptr` had been zeroed, and every call through them died with
/// `null pointer passed to rust` until the browser was refreshed.
///
/// So `_client` and `_baseUrl` are mutable on purpose. Anything that is
/// per-*connection* rather than per-*façade* has to be reset by
/// [rebindTransport]; anything wired in from outside ([onSseSubscribe],
/// [throttler], [onReauthRequired] and friends) must not be, because their owners
/// key off this same stable instance and re-attach themselves when Riverpod
/// rebuilds them.
class UspClient {
  late UspTransport _client;
  String _baseUrl;

  /// Bumped by [rebindTransport]. Lets an async operation that started on a
  /// previous connection notice, when it finally resumes, that its session is
  /// gone — see the supersession checks in [reauth].
  int _generation = 0;

  UspClient(String baseUrl) : _baseUrl = baseUrl {
    if (!kIsWeb) {
      throw UnsupportedError('This POC only supports Web platforms currently.');
    }
    _client = UspClientWeb(baseUrl);
  }

  /// Creates a UspClient from a pre-built WASM client (via UspClientBuilder).
  /// Used for Remote Assistance mode where the client is configured with
  /// custom endpoint, auth token, and extra headers.
  UspClient.fromBuilder(dynamic jsClient, {required String baseUrl})
      : _baseUrl = baseUrl {
    if (!kIsWeb) {
      throw UnsupportedError('This POC only supports Web platforms currently.');
    }
    _client = UspClientWeb.fromJsClient(jsClient);
  }

  /// Creates a UspClient backed by an arbitrary [UspTransport] instead of the
  /// production WASM client. The transport seam lets an alternate data source
  /// (demo mode's in-Dart model, an E2E harness) drive the exact same
  /// [UspClient] behaviour without touching the production boot path. Not used
  /// by production code — `UspClient(baseUrl)` / [fromBuilder] still build
  /// `UspClientWeb`.
  UspClient.withTransport(UspTransport transport, {String baseUrl = ''})
      : _baseUrl = baseUrl {
    _client = transport;
  }

  /// Re-points this façade at a new connection, releasing the old one.
  ///
  /// This is the operation that replaces "dispose the façade and register a new
  /// one" — see the class doc and #1322. Callers keep whatever reference they
  /// already hold; only the transport underneath changes, so the 41 services that
  /// captured this object at construction time keep working and start talking to
  /// the new session on their next call.
  ///
  /// The previous transport is disposed, so the WASM client is still freed
  /// exactly once per swap and nothing leaks. Re-passing the transport already in
  /// use is a no-op rather than a self-free — that guard is for direct
  /// [rebindTransport] callers only, and [rebindFromBuilder] cannot benefit from
  /// it (see the precondition on its doc).
  ///
  /// Per-connection state is reset:
  ///
  /// - [_lastCallRetried] is only a log label.
  /// - A pending [reauth] is not. Left in place, the next 401 on the **new**
  ///   session would await the **old** session's completer, and the old attempt's
  ///   eventual failure would end the session — signing the user out of one that
  ///   was fine. Bumping [_generation] is what lets that superseded attempt
  ///   return quietly instead.
  /// - The [throttler]'s dedup levels are per-connection even though the
  ///   throttler itself is not; see [BridgeRequestThrottler.invalidateSession].
  ///
  /// **Never throws once it has taken [transport], and that is a contract the
  /// caller relies on rather than a nicety.** `RemoteAssistanceNotifier
  /// .installTransport` decides whether to `free()` the wasm handle from whether
  /// this call returned: a throw means "nobody took it, release it". So a throw
  /// *after* the assignment on the first line would make it free the handle the
  /// registered façade is now using — a double free of the live connection across
  /// the 41 services holding this object by value, which is #1322's exact field
  /// symptom (`null pointer passed to rust`) arriving from the code that exists to
  /// prevent its mirror image. The bookkeeping below therefore cannot escape;
  /// leaving one connection's dedup levels stale is the lesser failure by a wide
  /// margin. Added by #1474 phase 9, which is where the reliance was introduced.
  void rebindTransport(UspTransport transport, {required String baseUrl}) {
    final previous = _client;
    _client = transport;
    _baseUrl = baseUrl;
    _generation++;
    _lastCallRetried = false;

    try {
      // Wake anyone parked on the outgoing session's reauth gate. Its owner is
      // suspended on the transport we are about to free, so it may never resume to
      // settle the gate itself — and an awaiter of a Completer that never
      // completes waits forever, with no timeout anywhere above it.
      //
      // Completed successfully, not with an error, and that is the deliberate
      // reading: the question the gate answers is "can this client authenticate
      // now?", and after the swap the answer is yes. The waiter's caller is
      // [_withAuthRetry], which re-runs its action against the *new* transport;
      // failing it here would abort a call the new connection can serve, and if
      // the new connection cannot, its own 401 says so a moment later.
      final orphanedReauth = _reauthInProgress;
      _reauthInProgress = null;
      if (orphanedReauth != null && !orphanedReauth.isCompleted) {
        logger
            .d('$_tag Releasing a reauth gate held by the previous connection');
        orphanedReauth.complete();
      }

      throttler?.invalidateSession();
    } catch (e) {
      logger.w('$_tag Post-swap bookkeeping failed, swap stands: $e');
    }

    // Sequential to the guard above, not nested inside it, and the difference is
    // the point: a throttler that throws must not cost us the *old* transport's
    // `free()`. Nesting made one wasm leak the price of avoiding another.
    if (!identical(previous, transport)) {
      // A transport that throws on release must not abort the swap either.
      try {
        previous.dispose();
      } catch (e) {
        logger.w('$_tag Releasing the previous transport failed: $e');
      }
    }
  }

  /// [rebindTransport] for a pre-built WASM client, mirroring [fromBuilder].
  ///
  /// Transport construction has to happen inside this library: `UspClientWeb` is
  /// an implementation detail that callers cannot reach.
  ///
  /// [jsClient] must be **freshly built**. Each call wraps it in a new
  /// `UspClientWeb`, so `rebindTransport`'s identity guard never fires here and
  /// re-passing the handle the live transport is already using would `free()` it
  /// underneath the wrapper that just took it over. The one production caller
  /// builds a client immediately before calling this.
  void rebindFromBuilder(dynamic jsClient, {required String baseUrl}) {
    if (!kIsWeb) {
      throw UnsupportedError('This POC only supports Web platforms currently.');
    }
    rebindTransport(UspClientWeb.fromJsClient(jsClient), baseUrl: baseUrl);
  }

  static final _random = Random();
  static const _tag = '[USPClient]:';
  bool _lastCallRetried = false;

  /// Generates a unique request ID: LNU{HEX-MS-TIMESTAMP}{4-CHAR-RANDOM}
  /// e.g., LNU18F3A2B4C5D6E7F8
  static String _genReqId() {
    final ts =
        DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase();
    final rand =
        _random.nextInt(0xFFFF).toRadixString(16).padLeft(4, '0').toUpperCase();
    return 'LNU$ts$rand';
  }

  String _idLabel(String id) => '$id${_lastCallRetried ? '.retry' : ''}';

  String get baseUrl => _baseUrl;

  /// Identifies the current connection even when this facade is rebound in place.
  int get connectionGeneration => _generation;

  bool get isAuthenticated => _client.isAuthenticated;

  String? get sessionToken => _client.sessionToken;

  /// Whether a [reauth] call is currently in progress.
  /// Used by [UspAuthCoordinator.ensureAuth] to avoid overlapping refresh.
  bool get isReauthInProgress => _reauthInProgress != null;

  /// Callback for full re-authentication when token refresh fails.
  /// Set by [UspAuthCoordinator] to `restoreSession()`, which is **token-only**:
  /// the in-memory token first, then the one in sessionStorage. No password is
  /// stored anywhere, so this cannot re-login from credentials. What it found
  /// is [reauth]'s to act on: it ends nothing itself.
  Future<SessionRestoreOutcome> Function()? onReauthRequired;

  /// Called after [reauth] Stage 2 (full re-login) succeeds.
  /// Set by [SseManager] to force SSE reconnect with the new session token.
  /// NOT called after Stage 1 (refreshToken) — same session, no SSE reconnect needed.
  VoidCallback? onTokenRefreshed;

  /// Called after [reauth] Stage 1 (refreshToken) succeeds.
  /// Set by [UspAuthCoordinator] to update [_lastTokenRefresh] timestamp.
  /// NOT related to SSE reconnect — see [onTokenRefreshed] for that.
  VoidCallback? onRefreshTokenSuccess;

  /// What a 401 means, and who ends the session it ends (#1666).
  ///
  /// The gate answers retry, end or ignore from the mode (a Remote Assistance
  /// token cannot be refreshed) and from the session the request was sent for;
  /// see [SessionAuthGate]. This façade only acts on the answer: it retries
  /// after a [reauth], ends the session through the gate, or lets the 401 reach
  /// the caller.
  ///
  /// Attached by `UspAuthCoordinator`'s constructor, beside [onReauthRequired],
  /// because the façade is built in `di.dart` and by Remote Assistance's
  /// `activate()`, outside Riverpod. With none attached (tests that do not need
  /// one) a 401 is retried and nothing is ended: what a local session that has
  /// not begun gets.
  SessionAuthGate? _authGate;

  void attachAuthGate(SessionAuthGate gate) => _authGate = gate;

  @visibleForTesting
  SessionAuthGate? get authGate => _authGate;

  /// SSE subscription delegate. Set by [SseManager] to route subscriptions
  /// through SSE instead of polling. When null, falls back to polling.
  SseSubscribeDelegate? onSseSubscribe;

  /// Optional request throttler. When set, all [get] calls are routed through
  /// the throttler to limit concurrent outbound requests to the router.
  /// Set by [uspClientProvider] during initialization.
  BridgeRequestThrottler? throttler;

  /// Makes the next [get] of any path go to the router: drops the [throttler]'s
  /// cached results and the in-flight requests a new [get] would join
  /// ([BridgeRequestThrottler.dropSharedReads]).
  ///
  /// For a change the router announces outside a write, such as a mesh node
  /// joining or leaving (#1828). A write drops only completed results; see
  /// [_invalidatingReads]. Without a throttler there is nothing shared to drop.
  void dropSharedReads() => throttler?.dropSharedReads();

  Future<void> login(String password) async {
    await _client.login(password);
  }

  Future<void> logout() async {
    await _client.logout();
  }

  Future<void> refreshToken({String? token}) async {
    await _client.refreshToken(token: token);
  }

  // ===========================================================================
  // 401 Auth Retry
  // ===========================================================================

  Completer<void>? _reauthInProgress;

  static bool _isAuthError(Object error) {
    return error.toString().contains('HTTP 401');
  }

  /// A [rebindTransport] since an operation started means the connection it was
  /// working on is gone. Its outcome says nothing about the current session, so
  /// it must not fire session-level callbacks, and above all must not end the
  /// session.
  bool _superseded(int generation) => generation != _generation;

  /// `complete()` that tolerates the gate having already been settled.
  ///
  /// [rebindTransport] completes the gate belonging to the connection it
  /// replaces, precisely so nobody is left parked on it. This attempt may then
  /// resume and try to publish its own result; a bare `complete()` would throw
  /// `Future already completed` out of its own success path, land in the catch
  /// below, and be reported as a reauth failure.
  void _settleReauthGate(Completer<void> gate) {
    if (!gate.isCompleted) gate.complete();
  }

  /// Two-stage re-authentication: refreshToken first, then a session restore.
  /// Uses a Completer lock to prevent concurrent reauth attempts.
  ///
  /// Completes when the session can be used again and throws when it cannot;
  /// the bridge's own 401 handling reads a throw as "reauth failed". When the
  /// restore finds the credential **rejected**, the session ends through the
  /// gate (#1666), with the ticket taken when this attempt started: a reauth
  /// that outlives its session cannot end the next one. A router that could not
  /// be asked (**unreachable**) ends nothing; the request fails, and the next
  /// 401 asks again.
  ///
  /// After a restore, notifies [onTokenRefreshed] so that SSE can reconnect
  /// with the new token (prevents silent subscription routing failures when the
  /// bridge session changes), unless the session has ended meanwhile.
  Future<void> reauth() async {
    final inFlight = _reauthInProgress;
    if (inFlight != null) {
      await inFlight.future;
      return;
    }
    // Held locally, not re-read through the field: `rebindTransport` may clear or
    // replace `_reauthInProgress` at any await point below, and `!` on the field
    // would then throw from inside our own error handling.
    final gate = Completer<void>();
    final generation = _generation;
    final ticket = _authGate?.ticket;
    _reauthInProgress = gate;
    bool didFullRelogin = false;
    try {
      // Stage 1: quick token refresh (no password needed)
      try {
        await refreshToken();
        logger.d('$_tag Token refreshed successfully');
        if (!_superseded(generation)) {
          try {
            onRefreshTokenSuccess?.call();
          } catch (cbError) {
            logger.w('$_tag onRefreshTokenSuccess callback error: $cbError');
          }
        }
        _settleReauthGate(gate);
        return;
      } catch (e) {
        logger.w('$_tag Token refresh failed: $e');
      }
      // Stage 1 ran against the connection we started on — `_client` is read
      // synchronously, before any await, so a swap cannot redirect it. Stage 2 is
      // different: it goes through [onReauthRequired], which reaches
      // `UspAuthCoordinator.restoreSession` and re-authenticates whatever
      // `_client` is by then. Run superseded, it would validate the *old*
      // session's stored token against the connection that replaced it, and on
      // failure clear that token. Stop here instead; a session that genuinely
      // needs reauth will get a 401 of its own.
      if (_superseded(generation)) {
        logger.w('$_tag Reauth abandoned — its connection was replaced');
        _settleReauthGate(gate);
        return;
      }
      // Stage 2: session restore (token-only — see restoreSession). Before
      // #1666 it never failed: restoreSession returned nothing, so a restore
      // that found nothing counted as a re-login, and the request was sent
      // again and SSE reconnected while the session was ending.
      final restore = onReauthRequired;
      if (restore != null) {
        final outcome = await restore();
        if (outcome != SessionRestoreOutcome.restored) {
          throw _SessionNotRestored(outcome);
        }
        didFullRelogin = true;
        logger.d('$_tag Full re-login succeeded');
      }
      _settleReauthGate(gate);
    } catch (e) {
      if (!gate.isCompleted) {
        gate.completeError(e);
        // Only a *concurrent* reauth caller ever listens to this future, so on a
        // solo failure it has none and the error would be reported to the zone as
        // unhandled — noise that says nothing the rethrow below does not. Adding
        // a handler here does not take the error away from real listeners.
        gate.future.ignore();
      }
      // Only Stage 2 can reach here now, so a superseded failure means the swap
      // landed mid-relogin. We cannot tell "the old connection vanished" from
      // "the new one cannot authenticate", and ending the session navigates to
      // the login screen — which in Remote Assistance ends a live Guardian
      // session. Take the recoverable reading: if the new connection really is
      // broken, its own next 401 will say so.
      //
      // What is suppressed is the **session end**, not the error. The failure
      // still propagates, because the caller's request genuinely did not
      // complete; the session survives, the request does not.
      if (_superseded(generation)) {
        logger.w('$_tag Reauth failed on a superseded connection — '
            'not ending the session, reporting to the caller');
        rethrow;
      }
      // The trigger was a 401 and the refresh failed too. Only a credential
      // the router refused ends the session; a router that could not be asked
      // may answer the next request.
      if (e is _SessionNotRestored &&
          e.outcome == SessionRestoreOutcome.rejected &&
          ticket != null) {
        logger.w('$_tag The router refused every token — ending the session');
        _authGate?.end(ticket);
      } else {
        logger.w('$_tag Reauth failed, the session is left as it is: $e');
      }
      rethrow;
    } finally {
      // Only give up the lock if we still hold it. A rebind releases it, and a
      // 401 on the new connection may already have taken it — clearing it here
      // would let a third reauth start alongside that one.
      if (identical(_reauthInProgress, gate)) {
        _reauthInProgress = null;
      }
      // Notify SSE to reconnect after full re-login (new session/token).
      // Stage 1 (refreshToken) typically extends the same session, so
      // SSE reconnect is only needed after Stage 2 (full re-login).
      //
      // Not after the session has ended (#1666): `connect()` clears the
      // intentional-disconnect flag, so a reconnect that lands during or after
      // a logout reopens a stream nobody will close.
      //
      // Deliberately NOT gated on supersession, unlike everything above. Reaching
      // here past the Stage 2 bail-out means the swap landed *during* the
      // re-login, so that re-login went through the **new** transport and changed
      // the **live** session's token; suppressing the reconnect would leave SSE on
      // a dead token, the exact failure this callback exists to prevent.
      //
      // Today the only [rebindTransport] caller is Remote Assistance, and
      // `SseManager` leaves this callback null in Remote mode
      // (`HeartbeatConfig.remote.authCheckEnabled == false`), so the combination
      // is unreachable in production and this is a no-op there. Stated because the
      // ungated call looks like an oversight otherwise: it is the correct
      // behaviour for the next caller, not a live path.
      if (didFullRelogin && !(_authGate?.hasEnded ?? false)) {
        onTokenRefreshed?.call();
      }
    }
  }

  /// Wraps an async operation with the 401 decision (#1666): the gate says
  /// whether to [reauth] and retry once, to end the session, or to let the 401
  /// reach the caller. A retry that is answered 401 again reaches the caller as
  /// it is, and so does the 401 when the reauth fails.
  Future<T> _withAuthRetry<T>(Future<T> Function() action) async {
    final generation = _generation;
    final ticket = _authGate?.ticket;
    try {
      return await action();
    } catch (e, stack) {
      if (!_isAuthError(e)) rethrow;
      switch (_decideOn401(ticket, generation)) {
        case AuthDecision.ignore:
          logger.w('$_tag 401 for a session that is over or not this one — '
              'failing the request');
          rethrow;
        case AuthDecision.end:
          logger.w('$_tag 401 on a credential that cannot be refreshed — '
              'ending the session');
          _authGate!.end(ticket!);
          rethrow;
        case AuthDecision.retry:
          logger.w('$_tag 401 detected, attempting reauth...');
          try {
            await reauth();
          } catch (_) {
            // The session could not be restored: the 401 is this request's
            // answer, not the restore's failure.
            Error.throwWithStackTrace(e, stack);
          }
          _lastCallRetried = true;
          return await action();
      }
    }
  }

  /// [SessionAuthGate.decideOn401] for a request sent on connection
  /// [generation], for the session [ticket] names.
  ///
  /// A connection [rebindTransport] has since replaced answered for a token
  /// that is gone; its 401 says nothing about the current one. With no gate
  /// attached a 401 is retried, as for a local session that has not begun.
  AuthDecision _decideOn401(SessionTicket? ticket, int generation) {
    if (_superseded(generation)) return AuthDecision.ignore;
    final gate = _authGate;
    if (gate == null || ticket == null) return AuthDecision.retry;
    return gate.decideOn401(ticket);
  }

  /// Fetches multiple USP paths in a single getMultiple call.
  ///
  /// Returns a coerced `Map<String, dynamic>` where booleans and nulls are
  /// properly typed (not left as raw strings).
  ///
  /// When [throttler] is set, requests are queued through it to limit
  /// concurrent outbound requests to the router. Use [priority] to control
  /// dispatch order — heavy wildcard queries should use [RequestPriority.low]
  /// so they run after lighter queries complete (OBUSPA is single-threaded).
  Future<Map<String, dynamic>> get(
    List<String> paths, {
    RequestPriority? priority,
    bool fresh = false,
  }) async {
    if (throttler != null) {
      return throttler!.enqueue(
        cacheKey: 'usp:${fresh ? "fresh:" : ""}${paths.join(",")}',
        cacheTtl: fresh ? Duration.zero : null,
        priority: priority ?? RequestPriority.normal,
        action: () => _rawGet(paths),
      );
    }
    return _rawGet(paths);
  }

  Future<Map<String, dynamic>> _rawGet(List<String> paths) async {
    final id = _genReqId();
    _lastCallRetried = false;
    final sw = Stopwatch()..start();

    logger.d(
      '$_tag $_separator\n'
      '$_tag #$id GET (Request) → ${paths.length} paths\n'
      '${_prettyList(paths)}',
    );

    try {
      // Decoded inside the retry: a 401 is in the envelope, not thrown, and
      // [_withAuthRetry] can only see what [extractGetResult] throws (#1212).
      final rawMap = await _withAuthRetry(
          () async => extractGetResult(await _client.get(paths)));
      sw.stop();

      final label = _idLabel(id);
      logger.d(
        '$_tag $_separator\n'
        '$_tag $label GET (Response) ← ${sw.elapsedMilliseconds}ms\n'
        '${_prettyMap(rawMap)}',
      );

      if (rawMap.isEmpty) {
        if (isTableQueryOnlyRequest(paths)) {
          // A table query — a wildcard GET (e.g. Device.Firewall.DMZ.*) or an
          // object/table path (e.g. Device.IP.Interface.1.IPv6Address.) — is
          // expanded by the router across the discovered instances of a
          // multi-instance table. When that table has zero instances the
          // response is legitimately empty — the generated model iterates the
          // (empty) instance set and returns an empty list, so this is a normal
          // "no rows" outcome, not a fault. Log it at debug so it does not
          // drown real warnings.
          logger.d(
            '$_tag$label GET empty (table query, no instances): '
            '$paths',
          );
        } else {
          // At least one concrete path was requested — an empty response there
          // is genuinely unexpected and worth a warning.
          logger.w('$_tag$label GET response EMPTY for paths: $paths');
        }
        // Every requested path is absent, but the single warning above already
        // says so. Skip the per-path missing warnings (they would just repeat
        // the same paths — e.g. 9 lines for lan_network_info's concrete GET).
        return normalizeGetResponse(paths, rawMap);
      }

      // Non-empty (possibly partial) response: collect any absent concrete
      // leaves and emit ONE aggregated warning rather than one per path, so a
      // genuine partial-response warning is not diluted into a wall of lines.
      final missing = <String>[];
      final normalized = normalizeGetResponse(
        paths,
        rawMap,
        onMissingPath: missing.add,
      );
      if (missing.isNotEmpty) {
        logger.w(
          '$_tag$label GET missing ${missing.length} path(s) in '
          'response: $missing',
        );
      }
      return normalized;
    } catch (e) {
      sw.stop();
      final label = _idLabel(id);
      logger.e('$_tag$label GET ✗ (${sw.elapsedMilliseconds}ms)\n  $e');
      rethrow;
    }
  }

  /// Normalizes a raw USP GET response into the map consumed by codegen models.
  ///
  /// Two responsibilities, kept as pure logic so it is unit-testable without a
  /// live WASM client:
  /// 1. Coerce every returned value via [_coerceValue].
  /// 2. Warn (via [onMissingPath]) for each requested non-wildcard path absent
  ///    from the response — but deliberately do NOT back-fill it. Back-filling
  ///    absent paths with null used to silently suppress the codegen
  ///    required-leaf check (code 9998 → ServiceErrorView), because it flipped
  ///    `containsKey` to true without preventing any Null Cast (the real guard
  ///    is the `?? ''` on each codegen assignment). Leaving the key absent lets
  ///    the required-leaf contract fire as designed (#1184).
  ///
  /// Wildcard search paths (containing '*') and object/table paths (ending in
  /// '.', e.g. Device.IP.Interface.1.IPv6Address.) are expanded by the router
  /// into concrete instance paths, so the original requested key never appears
  /// in the response. Both are skipped by the missing-path warning — only a
  /// requested *concrete leaf* that is absent is genuinely missing.
  @visibleForTesting
  static Map<String, dynamic> normalizeGetResponse(
    List<String> paths,
    Map<String, String?> rawMap, {
    void Function(String path)? onMissingPath,
  }) {
    final Map<String, dynamic> result = {};
    for (final entry in rawMap.entries) {
      result[entry.key] = _coerceValue(entry.key, entry.value);
    }
    for (final path in paths) {
      if (_isTableExpandedPath(path)) continue;
      if (!result.containsKey(path)) {
        onMissingPath?.call(path);
      }
    }
    return result;
  }

  /// Whether a requested path is one the router expands into concrete instance
  /// paths, so the requested key itself never appears verbatim in the response.
  ///
  /// Two shapes qualify, and they must be treated identically everywhere:
  /// - a wildcard search path (contains '*', e.g. Device.Firewall.DMZ.*)
  /// - an object/table path (ends in '.', e.g. Device.IP.Interface.1.IPv6Address.)
  ///
  /// Both target a multi-instance set; an absent requested key is expected, not
  /// missing, and an empty response means the set has zero rows — not a fault.
  static bool _isTableExpandedPath(String path) =>
      path.contains('*') || path.endsWith('.');

  /// Whether every requested path is a table query the router expands
  /// (see [_isTableExpandedPath]).
  ///
  /// When such a query hits a table with zero instances the response is
  /// legitimately empty (the generated model returns an empty list), so an
  /// empty response to a table-query-only request is a normal "no rows"
  /// outcome rather than a fault. Callers use this to decide whether an empty
  /// GET response deserves a warning. An empty [paths] list is not a table
  /// query.
  @visibleForTesting
  static bool isTableQueryOnlyRequest(List<String> paths) =>
      paths.isNotEmpty && paths.every(_isTableExpandedPath);

  /// Coerce a raw string value from USP into the appropriate Dart type.
  /// - "true" / "false" →bool (any path)
  /// - "1" / "0" →bool (for known boolean suffixes: Enable, Active)
  /// - null →null (key absent from response)
  /// - Empty string →'' (preserve String type for generated code)
  /// - Everything else stays as String (generated code handles int parsing)
  static dynamic _coerceValue(String path, String? raw) {
    if (raw == null) return null;
    if (raw.isEmpty) return '';

    // Boolean coercion
    final lower = raw.toLowerCase();
    if (lower == 'true') return true;
    if (lower == 'false') return false;

    // "1"/"0" coercion for known boolean path suffixes
    final isBoolPath = path.endsWith('Enable') ||
        path.endsWith('Active') ||
        path.endsWith('Upstream');
    if (isBoolPath) {
      if (raw == '1') return true;
      if (raw == '0') return false;
    }

    return raw;
  }

  /// Sets USP parameters. Accepts two call patterns:
  ///
  /// - Single: `set('Device.X.Y', singleValue: 'value')` — sets one parameter
  /// - Batch:  `set({'Device.X.Y': value, ...}, allowPartial: true)` — sets multiple
  ///
  /// Returns structured operation result from the WASM client.
  Future<Map<String, dynamic>> set(
    Object pathOrParams, {
    dynamic singleValue,
    bool allowPartial = false,
  }) async {
    if (pathOrParams is String && singleValue != null) {
      return _invalidatingReads(
          () => _singleSet(pathOrParams, singleValue.toString()));
    } else if (pathOrParams is Map) {
      return _invalidatingReads(() => _batchSet(
          pathOrParams.cast<String, dynamic>(),
          allowPartial: allowPartial));
    }
    throw ArgumentError(
      'set() expects (String, value) or (Map<String, dynamic>)',
    );
  }

  /// Runs a write, then drops the [throttler]'s completed-GET cache.
  ///
  /// That cache answers a repeated read for 5 s and is keyed on the request's
  /// paths alone, so without this a read issued inside that window *after* a
  /// write is answered with the value from *before* it. Measured on the bench
  /// (#1660): a confirming read 1 ms after a landed `Set` of
  /// `Device.UPnP.Device.Enable` returned the old value without dispatching a
  /// GET, and the switch drew OFF on a router that was ON. Every page that
  /// saves and then re-reads goes through here.
  ///
  /// In `finally`: a write that threw may still have changed the router, and
  /// one extra GET costs less than a stale answer. Only completed results are
  /// dropped — a GET already in flight keeps its callers, the same line
  /// [BridgeRequestThrottler.clearCache] draws.
  Future<T> _invalidatingReads<T>(Future<T> Function() write) async {
    try {
      return await write();
    } finally {
      throttler?.clearCache();
    }
  }

  Future<Map<String, dynamic>> _singleSet(String path, String value) async {
    final id = _genReqId();
    _lastCallRetried = false;
    final sw = Stopwatch()..start();
    final params = {path: value};

    logger.d('$_tag#$id SET →\n${_prettyMap(params)}');

    try {
      final result = await _withAuthRetry(() async =>
          throwIfUnanswered('Set', await _client.set({path: value})));
      sw.stop();
      final label = _idLabel(id);
      logger.d(
        '$_tag$label SET ← (${sw.elapsedMilliseconds}ms)\n'
        '${_prettyMap(result)}',
      );
      return result;
    } catch (e) {
      sw.stop();
      final label = _idLabel(id);
      logger.e('$_tag$label SET ✗ (${sw.elapsedMilliseconds}ms)\n  $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _batchSet(
    Map<String, dynamic> parameters, {
    bool allowPartial = false,
  }) async {
    final id = _genReqId();
    _lastCallRetried = false;
    final sw = Stopwatch()..start();
    final Map<String, String> stringParams = parameters.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    logger.d(
      '$_tag#$id SET${allowPartial ? ' (allowPartial)' : ''} →\n'
      '${_prettyMap(parameters)}',
    );

    try {
      final result = await _withAuthRetry(
        () async => throwIfUnanswered(
            'Set', await _client.set(stringParams, allowPartial: allowPartial)),
      );
      sw.stop();
      final label = _idLabel(id);
      logger.d(
        '$_tag$label SET ← (${sw.elapsedMilliseconds}ms)\n'
        '${_prettyMap(result)}',
      );
      return result;
    } catch (e) {
      sw.stop();
      final label = _idLabel(id);
      logger.e('$_tag$label SET ✗ (${sw.elapsedMilliseconds}ms)\n  $e');
      rethrow;
    }
  }

  // ===========================================================================
  // Set Ordered — preserves parameter execution sequence
  // ===========================================================================

  /// Performs a Set whose parameter groups keep their order. Use when parameter
  /// order affects correctness (e.g., AddressingType must be set before
  /// SubnetMask).
  ///
  /// [parameterGroups] is a list of groups, where each group is a list of
  /// `{path, value}` maps. **All the groups go out in one USP Set message**, in
  /// group order: usp-client 0.16.0 does not send a Set per group (measured,
  /// `test/web/usp_write_test.mjs`). So the order holds as far as the router
  /// applies one message's objects in the order they arrive, which has not been
  /// measured, and there is no answer in which one group landed and a later
  /// one went unanswered.
  Future<Map<String, dynamic>> setOrdered(
          List<List<Map<String, String>>> parameterGroups,
          {bool allowPartial = false}) =>
      _invalidatingReads(
          () => _setOrdered(parameterGroups, allowPartial: allowPartial));

  Future<Map<String, dynamic>> _setOrdered(
      List<List<Map<String, String>>> parameterGroups,
      {bool allowPartial = false}) async {
    final id = _genReqId();
    _lastCallRetried = false;
    final sw = Stopwatch()..start();

    logger.d(
      '$_tag#$id SET_ORDERED${allowPartial ? ' (allowPartial)' : ''} →\n'
      '${_prettyJson(parameterGroups)}',
    );

    try {
      final result = await _withAuthRetry(
        () async => throwIfUnanswered(
            'Set',
            await _client.setOrdered(parameterGroups,
                allowPartial: allowPartial)),
      );
      sw.stop();
      final label = _idLabel(id);
      logger.d(
        '$_tag$label SET_ORDERED ← (${sw.elapsedMilliseconds}ms)\n'
        '${_prettyMap(result)}',
      );
      return result;
    } catch (e) {
      sw.stop();
      final label = _idLabel(id);
      logger.e('$_tag$label SET_ORDERED ✗ (${sw.elapsedMilliseconds}ms)\n  $e');
      rethrow;
    }
  }

  // ===========================================================================
  // Add Operation — create new object instances
  // ===========================================================================

  /// Creates object instances via USP Add.
  ///
  /// Each element in [items] should have:
  /// - `path` (String): object path ending with "."
  /// - `params` (Map<String, dynamic>): initial parameter values
  ///
  /// Single-item lists are optimized to use the WASM single-add method.
  Future<Map<String, dynamic>> add(
    List<Map<String, dynamic>> items, {
    bool allowPartial = false,
  }) async {
    if (items.length == 1) {
      final item = items.first;
      return _invalidatingReads(() => _singleAdd(item['path'] as String,
          item['params'] as Map<String, dynamic>? ?? {}));
    }
    return _invalidatingReads(
        () => _batchAdd(items, allowPartial: allowPartial));
  }

  Future<Map<String, dynamic>> _singleAdd(
    String objectPath,
    Map<String, dynamic> parameters,
  ) async {
    final id = _genReqId();
    _lastCallRetried = false;
    final sw = Stopwatch()..start();
    final stringParams = parameters.map((k, v) => MapEntry(k, v.toString()));
    final payload = {'path': objectPath, 'params': stringParams};

    logger.d('$_tag#$id ADD →\n${_prettyMap(payload)}');

    try {
      final result = await _withAuthRetry(
        () async => throwIfUnanswered(
            'Add',
            await _client.add([
              {'path': objectPath, 'params': stringParams},
            ])),
      );
      sw.stop();
      final label = _idLabel(id);
      logger.d(
        '$_tag$label ADD ← (${sw.elapsedMilliseconds}ms)\n'
        '${_prettyMap(result)}',
      );
      return result;
    } catch (e) {
      sw.stop();
      final label = _idLabel(id);
      logger.e('$_tag$label ADD ✗ (${sw.elapsedMilliseconds}ms)\n  $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _batchAdd(
    List<Map<String, dynamic>> objects, {
    bool allowPartial = false,
  }) async {
    final id = _genReqId();
    _lastCallRetried = false;
    final sw = Stopwatch()..start();

    logger.d(
      '$_tag#$id ADD${allowPartial ? ' (allowPartial)' : ''} →\n'
      '${_prettyJson(objects)}',
    );

    try {
      final result = await _withAuthRetry(
        () async => throwIfUnanswered(
            'Add', await _client.add(objects, allowPartial: allowPartial)),
      );
      sw.stop();
      final label = _idLabel(id);
      logger.d(
        '$_tag$label ADD ← (${sw.elapsedMilliseconds}ms)\n'
        '${_prettyMap(result)}',
      );
      return result;
    } catch (e) {
      sw.stop();
      final label = _idLabel(id);
      logger.e('$_tag$label ADD ✗ (${sw.elapsedMilliseconds}ms)\n  $e');
      rethrow;
    }
  }

  // ===========================================================================
  // Delete Operation — remove object instances
  // ===========================================================================

  /// Deletes object instances via USP Delete.
  ///
  /// Each path must be a specific instance path (e.g., "Device.NAT.PortMapping.3.").
  /// Single-item lists are optimized to use the WASM single-delete method.
  Future<Map<String, dynamic>> delete(
    List<String> paths, {
    bool allowPartial = false,
  }) async {
    if (paths.length == 1) {
      return _invalidatingReads(() => _singleDelete(paths.first));
    }
    return _invalidatingReads(
        () => _batchDelete(paths, allowPartial: allowPartial));
  }

  Future<Map<String, dynamic>> _singleDelete(String path) async {
    final id = _genReqId();
    _lastCallRetried = false;
    final sw = Stopwatch()..start();

    logger.d('$_tag#$id DELETE →\n${_prettyList([path])}');

    try {
      final result = await _withAuthRetry(() async =>
          throwIfUnanswered('Delete', await _client.delete([path])));
      sw.stop();
      final label = _idLabel(id);
      logger.d(
        '$_tag$label DELETE ← (${sw.elapsedMilliseconds}ms)\n'
        '${_prettyMap(result)}',
      );
      return result;
    } catch (e) {
      sw.stop();
      final label = _idLabel(id);
      logger.e('$_tag$label DELETE ✗ (${sw.elapsedMilliseconds}ms)\n  $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _batchDelete(
    List<String> paths, {
    bool allowPartial = false,
  }) async {
    final id = _genReqId();
    _lastCallRetried = false;
    final sw = Stopwatch()..start();

    logger.d(
      '$_tag#$id DELETE${allowPartial ? ' (allowPartial)' : ''} →\n'
      '${_prettyList(paths)}',
    );

    try {
      final result = await _withAuthRetry(
        () async => throwIfUnanswered(
            'Delete', await _client.delete(paths, allowPartial: allowPartial)),
      );
      sw.stop();
      final label = _idLabel(id);
      logger.d(
        '$_tag$label DELETE ← (${sw.elapsedMilliseconds}ms)\n'
        '${_prettyMap(result)}',
      );
      return result;
    } catch (e) {
      sw.stop();
      final label = _idLabel(id);
      logger.e('$_tag$label DELETE ✗ (${sw.elapsedMilliseconds}ms)\n  $e');
      rethrow;
    }
  }

  // ===========================================================================
  // Operate — execute USP commands
  // ===========================================================================

  /// Executes a USP Operate command on the agent.
  ///
  /// [command] is the command path (e.g., "Device.Reboot()" or
  /// "Device.IP.Diagnostics.Ping()").
  /// [args] are the input arguments for the command.
  /// Returns a flat map containing `commandKey` (for SSE correlation) and
  /// all output arguments from the Operate response.
  Future<Map<String, dynamic>> operate(
    String command, {
    Map<String, String> args = const {},
    bool retryOnAuthFailure = true,
    bool redactArguments = false,
  }) =>
      // An Operate can change data as well (SetTimeSettings, SetMACFilter).
      _invalidatingReads(() => _operate(
            command,
            args: args,
            retryOnAuthFailure: retryOnAuthFailure,
            redactArguments: redactArguments,
          ));

  Future<Map<String, dynamic>> _operate(
    String command, {
    Map<String, String> args = const {},
    bool retryOnAuthFailure = true,
    bool redactArguments = false,
  }) async {
    final id = _genReqId();
    _lastCallRetried = false;
    final sw = Stopwatch()..start();

    final payload = <String, dynamic>{
      'command': command,
      if (args.isNotEmpty) 'args': redactArguments ? '[redacted]' : args,
    };
    logger.d('$_tag#$id OPERATE →\n${_prettyMap(payload)}');

    try {
      // usp-client unified format (0.13.0; `errors` since 0.16.0):
      // { success, result: { data: { commandKey, requestPath, outputArgs }, error?, errors? } }
      // Throws when the agent refused the command — see extractOperateResult.
      //
      // Decoded inside the retry, as a Get is (#1666): the client resolves a
      // 401 into the envelope, and [_withAuthRetry] only sees what the decode
      // throws. Decoded after it, an Operate's 401 reached no session check.
      final response = retryOnAuthFailure
          ? await _withAuthRetry(() async =>
              extractOperateResult(await _client.operate(command, args: args)))
          : extractOperateResult(await _client.operate(command, args: args));
      sw.stop();
      final label = _idLabel(id);
      logger.d(
        '$_tag$label OPERATE ← (${sw.elapsedMilliseconds}ms)\n'
        '${redactArguments ? '[redacted]' : _prettyMap(response)}',
      );
      return response;
    } catch (e) {
      sw.stop();
      final label = _idLabel(id);
      logger.e(
        '$_tag$label OPERATE ✗ (${sw.elapsedMilliseconds}ms)\n  ${redactArguments ? e.runtimeType : e}',
      );
      rethrow;
    }
  }

  /// Decodes a GET's unified envelope into the flat path→value map, and
  /// **throws when the read failed as a whole**.
  ///
  /// The WASM client resolves a lost connection, a 401 and a 5xx alike as
  /// `success: false` (#1212, measured from Node against the vendored client).
  /// Reading `data` alone turned each of them into an empty answer: a
  /// required-leaf model threw 9998 ("invalid input"), a table read as
  /// "no rows", an optional leaf as "the firmware does not have it".
  ///
  /// **Only an `errors` entry of `kind: request` throws, and `success` is not
  /// the test** (usp-client 0.16.0, #1787). `request` is the call as a whole:
  /// the client's own transport (9999), decode (9998) or validation (9997)
  /// failure, or the router refusing the whole Get (a USP `Error`, with the
  /// router's code). A path the router does not have is `kind: path`, a
  /// per-path `7026`, with `success: true` when other paths were read and
  /// `success: false` when it was the only one (measured on FW 2.0.3,
  /// 2026-10-13). That is an answer — the path is absent — so the paths that
  /// were read are returned and the missing one is left out. Throwing on
  /// `success == false`, or on every requested path carrying an error, would
  /// turn "this router has no RIP" into a failure; only `kind` tells a lone
  /// 7026 from a refused Get, since both carry a router code on every
  /// requested path.
  ///
  /// It throws a string in the USP layer's own shape, as
  /// [extractOperateResult] does (see [_failedAsAWhole]), so a 401 still reads
  /// `HTTP 401` to [_isAuthError] and the usual `mapUspErrorToServiceError`
  /// classifies the rest.
  @visibleForTesting
  static Map<String, String> extractGetResult(Map<String, dynamic> raw) {
    final result = raw['result'];
    final failure = _requestFailureIn(result);
    if (failure != null) throw _failedAsAWhole('Get', failure);

    // Nothing failed as a whole, so the router answered. A lone per-path error
    // (7026) was measured with an empty `data`; whether the client can also
    // omit `data` there is not settled from its source (PR #1716 review), and
    // either way it is an answer with nothing in it — so a missing `data` reads
    // as no rows, never as a protocol failure that would make "absent" an error.
    final data = result is Map ? result['data'] : null;
    if (data is! Map) return const {};
    return {
      for (final entry in data.entries)
        entry.key?.toString() ?? '': entry.value?.toString() ?? '',
    };
  }

  /// Reads the usp-client unified Operate response: `{ success, result: { data,
  /// error? } }`.
  ///
  /// Returns `commandKey`, `requestPath` and the flattened output arguments —
  /// and **throws when the agent refused the command**.
  ///
  /// Throwing is the point (#1533). usp-client 0.13.0 reports a refusal as
  /// `success: false` with the agent's code in band, and the JS Promise
  /// *fulfils*: the reject path across the Wasm boundary replaces the agent's
  /// code with a `9999` transport sentinel, so a caller can only see the refusal
  /// by reading the value. This method used to read `data` and nothing else, so a
  /// refusal returned `{}` and every caller reported success — a firmware chunk
  /// the router rejected completed normally in the UI, with no error anywhere.
  ///
  /// It throws a **string in the USP layer's own shape**, not a [ServiceError]:
  /// `Operate failed: Operation error: … (code: N)`. That keeps two contracts
  /// intact — `parseUspError` reads it as an *operation* failure carrying the
  /// agent's code, so every existing `catch (e) => mapUspErrorToServiceError(e)`
  /// classifies it without change; and mapping to `ServiceError` stays in the
  /// service layer where constitution Article XIII puts it, not here in transport.
  @visibleForTesting
  static Map<String, dynamic> extractOperateResult(Map<String, dynamic> raw) {
    // **The refusal check runs first, and the order is the correctness.** It used
    // to sit after the `result == null` fallback, which made the guard fail *open*:
    // a `{ "success": false }` carrying no `result` returned the raw map instead of
    // throwing, and a caller reading `{}` cannot tell a refusal from a success —
    // the exact defect #1533 exists to fix, reintroduced for one response shape.
    //
    // Whether the agent can produce that shape is not something this file can
    // settle: `success` is assembled inside `usp_client_bg.wasm`, and the JS shim
    // contains no `success: false` literal to read. So the shape is neither proven
    // reachable nor proven impossible — which is the argument for checking it
    // rather than against. Four lines, and being wrong the other way means this
    // PR's own bug comes back silently.
    if (raw['success'] == false) {
      final result = raw['result'];
      // A failure of the call as a whole (usp-client 0.16.0 `kind: request`):
      // the client's own 9997–9999, or the router refusing the request, which
      // is not the command failing (#1787).
      final failure = _requestFailureIn(result);
      if (failure != null) throw _failedAsAWhole('Operate', failure);
      throw _operateRefusal(result is Map ? result['errors'] : null);
    }

    final result = raw['result'] as Map?;
    if (result == null) return raw;
    final data = result['data'] as Map?;
    if (data == null) return {};

    final output = <String, dynamic>{};
    final commandKey = data['commandKey']?.toString();
    if (commandKey != null && commandKey.isNotEmpty) {
      output['commandKey'] = commandKey;
    }
    // New in 0.13.0 (`OperateResp.req_obj_path`): the only server-assigned handle
    // for an accepted asynchronous command when not subscribed to Notify.
    final requestPath = data['requestPath']?.toString();
    if (requestPath != null && requestPath.isNotEmpty) {
      output['requestPath'] = requestPath;
    }
    final rawOutputArgs = data['outputArgs'];
    if (rawOutputArgs is Map) {
      for (final entry in rawOutputArgs.entries) {
        output[entry.key.toString()] = entry.value.toString();
      }
    }
    return output;
  }

  /// A write's envelope, or a throw when the router **never answered** it.
  ///
  /// That is an `errors` entry of `kind: request` with the client's transport
  /// code 9999: a 401, a 5xx, a lost connection, a request that timed out or a
  /// body that could not be read. Measured from Node against the vendored
  /// client for Set, setOrdered, Add and Delete (usp-client 0.16.0,
  /// 2026-11-25, #1666): each resolves with exactly that, never throws, and
  /// sends one request. Run inside [_withAuthRetry], so a 401 reads `HTTP 401`
  /// to [_isAuthError] — before this the write verbs passed the envelope
  /// through and their 401 reached no session check at all.
  ///
  /// **Everything else is returned for the caller to read, as before.** The
  /// router refusing the whole request is also `kind: request`, but with the
  /// router's own code (7005 for an atomic Set it cannot apply) — an answer,
  /// whose reason the services read from the envelope. So are an object or a
  /// parameter it refused (`kind: path` / `parameter`), and the client's
  /// decode (9998) and validation (9997) failures. Only the code tells the
  /// unanswered request from the refused one: both are `kind: request`.
  @visibleForTesting
  static Map<String, dynamic> throwIfUnanswered(
      String operation, Map<String, dynamic> raw) {
    final failure = _requestFailureIn(raw['result']);
    if (failure != null && _integerCode(failure['errorCode']) == 9999) {
      throw _failedAsAWhole(operation, failure);
    }
    return raw;
  }

  /// The first entry of a unified result's `errors` list whose `kind` is
  /// `request`, or null when the call did not fail as a whole.
  ///
  /// usp-client 0.16.0 reads `kind` from the structure of the answer, never
  /// from the shape of a path: `request` is the call as a whole (a USP
  /// `Error`, or a transport, decode, validation or session failure), `path`
  /// one requested path (a Get's 7026, an Operate's command failure).
  static Map<Object?, Object?>? _requestFailureIn(Object? result) {
    final errors = result is Map ? result['errors'] : null;
    if (errors is! List) return null;
    for (final entry in errors) {
      if (entry is Map && entry['kind'] == 'request') return entry;
    }
    return null;
  }

  /// What a Get or an Operate that failed as a whole throws, in the USP
  /// layer's own shape, so `mapUspErrorToServiceError` classifies it as it did
  /// before usp-client 0.15.0 (#1787).
  ///
  /// - 9999, the transport sentinel: the client's message with its category
  ///   restored by [unwrapUspClientError] and nothing appended, so a 401 still
  ///   reads `HTTP 401` to [_isAuthError] and the transport arm.
  /// - 9998 and 9997, the client's decode and validation failures: the same,
  ///   with the code appended for the protocol and validation arms.
  /// - Any other code is the router refusing the request as a whole. Up to
  ///   0.14.0 the client wrapped that in a 9999 whose message was
  ///   `Protocol error: … (code: N)`; it is rebuilt in that shape so it keeps
  ///   reaching `_mapProtocolError` by the router's code. That is what keeps a
  ///   7016 for a mesh node that has left reading as `ResourceNotFoundError`
  ///   (`node_action_flow.dart`), not as a command the router refused.
  static String _failedAsAWhole(String operation, Map<Object?, Object?> entry) {
    final code = _integerCode(entry['errorCode']);
    final message = entry['errorMessage']?.toString() ?? '';
    final clientMessage =
        unwrapUspClientError(message.isEmpty ? 'Request failed' : message);
    if (code == 9999) return '$operation failed: $clientMessage';
    if (code != null && isUspClientFaultCode(code)) {
      return '$operation failed: $clientMessage (code: $code)';
    }
    final why =
        message.isEmpty ? 'the router gave no reason' : _requoteCodes(message);
    final suffix = code == null ? '' : ' (code: $code)';
    return '$operation failed: Protocol error: $why$suffix';
  }

  /// An `errorCode` as an integer, or null when it is not one. It arrives
  /// untyped from a JS object, and an integral JS number can cross the interop
  /// boundary as a Dart `double` (see [_operateRefusal]).
  static int? _integerCode(Object? code) => switch (code) {
        final num n when n.isFinite && n == n.truncateToDouble() => n.toInt(),
        final String s => int.tryParse(s),
        _ => null,
      };

  /// [message] with every `(code: N)` in it requoted as `[code: N]`, so the
  /// only parenthesised code in a thrown string is the one this file appends
  /// (see [_operateRefusal]).
  static String _requoteCodes(String message) => message.replaceAllMapped(
        RegExp(r'\(code:\s*(\d+)\)'),
        (m) => '[code: ${m.group(1)}]',
      );

  /// Builds the refusal string for a command the router refused, from the
  /// unified response's `errors` list (usp-client 0.16.0, `kind: path`).
  ///
  /// Each entry carries the `path` that failed, `errorCode` and `errorMessage`.
  /// Everything is optional on purpose: a `success: false` with no readable
  /// detail must still throw, because a caller handed `{}` cannot tell a
  /// refusal from a success. A failure of the call as a whole never reaches
  /// here: [extractOperateResult] throws it through [_failedAsAWhole] first.
  static String _operateRefusal(Object? errors) {
    String? path;
    Object? code;
    String? message;

    final first = errors is List && errors.isNotEmpty ? errors.first : null;
    if (first is Map) {
      path = first['path']?.toString();
      code = first['errorCode'];
      message = first['errorMessage']?.toString();
    }

    final what = path ?? 'the command';
    // **The router's own message is requoted so it cannot be read as our suffix.**
    //
    // `parseUspError` recovers the fault code with `\(code:\s*(\d+)\)` over the whole
    // string, and this method appends its suffix *after* the message — so a vendor
    // message echoing an upstream `(code: N)` was being adopted as the code. Measured
    // on head before this change: a refusal with **no** `errorCode` whose message read
    // `upstream said (code: 9001)` parsed as fault code 9001 and mapped to
    // `UspCompleteFailureError`, telling the user "request denied" about a refusal the
    // router gave no code for. Inventing a specific wrong answer is worse than the
    // generic one it replaced.
    //
    // Requoted rather than anchoring the consumer's pattern to end-of-string, which is
    // what a reviewer proposed: **measured, that breaks the protocol path**, where the
    // code legitimately sits mid-string (`… (code: 7004) for Device.X` must still
    // parse as 7004). The producer owns this format, so the producer is where the
    // ambiguity gets removed.
    //
    // Square brackets keep every character of what the router said while leaving
    // exactly one parenthesised code in the string — ours.
    final quoted = message == null ? null : _requoteCodes(message);
    final why = (quoted == null || quoted.isEmpty)
        ? 'the router gave no reason'
        : quoted;
    // **Normalised to an integer literal, because the consumer reads it with a
    // regex.** `parseUspError` recovers the code with `\(code:\s*(\d+)\)`, and
    // `errorCode` arrives here untyped from a JS object: an integral JS number can
    // cross the interop boundary as a Dart `double`, at which point `'$code'`
    // renders `7022.0`, the `(\d+)` cannot match through the `.`, `faultCode` is
    // null, and `_mapOperationError` sends the user back to "Something went wrong"
    // — for the one code this change exists to give a message to.
    //
    // Fixed at the producer rather than by widening the regex: the regex serves
    // every USP error string, and a `(\d+(?:\.\d+)?)` there would start accepting
    // codes that are not codes. A non-integral value still falls through
    // unnormalised, which is correct — that is not a fault code, and it should not
    // be read as one.
    final codeText = switch (code) {
      null => null,
      // `isFinite` first, and it is not belt-and-braces: `double.infinity
      // .truncateToDouble()` **is** infinity, so `n == n.truncateToDouble()`
      // passes for ±Infinity and `toInt()` then throws
      // `UnsupportedError: Infinity or NaN toInt` — replacing the refusal string
      // with a crash and losing both the code and the router's message. Measured.
      // NaN is safe only by accident (`NaN != NaN` fails the guard), which is
      // exactly the kind of accident worth not relying on.
      final num n when n.isFinite && n == n.truncateToDouble() =>
        n.toInt().toString(),
      _ => code.toString(),
    };
    final suffix = codeText == null ? '' : ' (code: $codeText)';
    return 'Operate failed: Operation error: $what refused: $why$suffix';
  }

  // ===========================================================================
  // OBUSPA Subscription — Device.LocalAgent.Subscription management
  // ===========================================================================

  /// Lists all OBUSPA subscriptions via the WASM client.
  ///
  /// Returns raw subscription objects from the router. Each entry typically
  /// contains fields like `instance_path`, `notif_type`, `reference_list`, etc.
  Future<List<Map<String, dynamic>>> listSubscriptions() async {
    final id = _genReqId();
    final sw = Stopwatch()..start();
    final subs = await _withAuthRetry(() => _client.listSubscriptions());
    sw.stop();
    logger.d(
      '$_tag#$id LIST_SUBSCRIPTIONS → ${subs.length} entries '
      '(${sw.elapsedMilliseconds}ms)',
    );
    return subs;
  }

  // ===========================================================================
  // Subscribe — SSE-backed with polling fallback
  // ===========================================================================

  /// Creates a typed subscription that delivers parsed model updates via a
  /// [Stream].
  ///
  /// When [onSseSubscribe] is set (by [SseManager]), uses SSE notifications
  /// as triggers to re-fetch and emit updated data. Otherwise, falls back to
  /// periodic polling.
  Future<Subscription<T>> subscribe<T>({
    required String id,
    required NotifType notifType,
    required List<String> paths,
    required T Function(Map<String, dynamic>) parser,
    Duration interval = const Duration(seconds: 5),
  }) async {
    if (onSseSubscribe != null) {
      return _sseSubscribe(
        id: id,
        notifType: notifType,
        paths: paths,
        parser: parser,
      );
    }
    return _pollingSubscribe(
      id: id,
      notifType: notifType,
      paths: paths,
      parser: parser,
      interval: interval,
    );
  }

  /// SSE-backed subscription: registers via delegate, re-fetches on notification.
  Future<Subscription<T>> _sseSubscribe<T>({
    required String id,
    required NotifType notifType,
    required List<String> paths,
    required T Function(Map<String, dynamic>) parser,
  }) async {
    final controller = StreamController<T>.broadcast();
    Timer? debounce;

    final (:removeHandler, :unregister) = await onSseSubscribe!(
      subscriptionId: id,
      notifType: _notifTypeToString(notifType),
      referenceList: paths.first,
      onNotification: () {
        // Debounce: re-fetch after 300ms of quiet
        debounce?.cancel();
        debounce = Timer(const Duration(milliseconds: 300), () async {
          try {
            final response = await get(paths);
            final parsed = parser(response);
            if (!controller.isClosed) {
              controller.add(parsed);
            }
          } catch (e) {
            logger.w('$_tag SSE subscribe re-fetch error for "$id": $e');
          }
        });
      },
    );

    // Initial fetch
    try {
      final response = await get(paths);
      final parsed = parser(response);
      if (!controller.isClosed) {
        controller.add(parsed);
      }
    } catch (e) {
      logger.w('$_tag SSE subscribe initial fetch error for "$id": $e');
    }

    return Subscription<T>(
      id: id,
      notifType: notifType,
      stream: controller.stream,
      cancel: () async {
        debounce?.cancel();
        removeHandler();
        await unregister();
        await controller.close();
      },
    );
  }

  /// Polling fallback subscription.
  Future<Subscription<T>> _pollingSubscribe<T>({
    required String id,
    required NotifType notifType,
    required List<String> paths,
    required T Function(Map<String, dynamic>) parser,
    required Duration interval,
  }) async {
    late StreamController<T> controller;
    Timer? timer;

    controller = StreamController<T>(
      onListen: () {
        timer = Timer.periodic(interval, (_) async {
          try {
            final response = await get(paths);
            final parsed = parser(response);
            if (!controller.isClosed) {
              controller.add(parsed);
            }
          } catch (e) {
            logger.w('$_tag Subscribe poll error for "$id": $e');
          }
        });
      },
      onCancel: () {
        timer?.cancel();
      },
    );

    return Subscription<T>(
      id: id,
      notifType: notifType,
      stream: controller.stream,
      cancel: () async {
        timer?.cancel();
        await controller.close();
      },
    );
  }

  /// Converts [NotifType] enum to the USP string representation.
  static String _notifTypeToString(NotifType type) {
    switch (type) {
      case NotifType.valueChange:
        return 'ValueChange';
      case NotifType.objectCreation:
        return 'ObjectCreation';
      case NotifType.objectDeletion:
        return 'ObjectDeletion';
      case NotifType.operationComplete:
        return 'OperationComplete';
      case NotifType.onBoardRequest:
        return 'OnBoardRequest';
      case NotifType.event:
        return 'Event';
    }
  }

  // ===========================================================================
  // Log helpers
  // ===========================================================================

  static const _separator = '════════════════════════════════════════';
  static const _jsonEncoder = JsonEncoder.withIndent('  ');

  static String _prettyList(List<String> list) {
    return '  ${_jsonEncoder.convert(list).replaceAll('\n', '\n  ')}';
  }

  static String _prettyMap(Map<String, dynamic> map) {
    return '  ${_jsonEncoder.convert(map).replaceAll('\n', '\n  ')}';
  }

  static String _prettyJson(Object value) {
    return '  ${_jsonEncoder.convert(value).replaceAll('\n', '\n  ')}';
  }

  void dispose() {
    _client.dispose();
  }
}

/// [UspClient.reauth]'s failure when the session restore did not restore.
class _SessionNotRestored implements Exception {
  const _SessionNotRestored(this.outcome);

  final SessionRestoreOutcome outcome;

  @override
  String toString() => 'Session not restored (${outcome.name})';
}
