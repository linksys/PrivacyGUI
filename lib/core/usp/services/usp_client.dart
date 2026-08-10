import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:privacy_gui/core/usp/models/usp_operation_result.dart';
import 'package:privacy_gui/core/usp/transport/usp_transport.dart';
import 'package:privacy_gui/core/utils/logger.dart';

import 'bridge_request_throttler.dart';

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
        ({
          void Function() removeHandler,
          Future<void> Function() unregister,
        })>
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
class UspClient {
  late final UspTransport _client;
  final String _baseUrl;

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

  bool get isAuthenticated => _client.isAuthenticated;

  String? get sessionToken => _client.sessionToken;

  /// Whether a [reauth] call is currently in progress.
  /// Used by [UspAuthCoordinator.ensureAuth] to avoid overlapping refresh.
  bool get isReauthInProgress => _reauthInProgress != null;

  /// Callback for full re-authentication when token refresh fails.
  /// Set by [UspAuthCoordinator] to provide re-login via stored password.
  Future<void> Function()? onReauthRequired;

  /// Called after [reauth] Stage 2 (full re-login) succeeds.
  /// Set by [SseManager] to force SSE reconnect with the new session token.
  /// NOT called after Stage 1 (refreshToken) — same session, no SSE reconnect needed.
  VoidCallback? onTokenRefreshed;

  /// Called after [reauth] Stage 1 (refreshToken) succeeds.
  /// Set by [UspAuthCoordinator] to update [_lastTokenRefresh] timestamp.
  /// NOT related to SSE reconnect — see [onTokenRefreshed] for that.
  VoidCallback? onRefreshTokenSuccess;

  /// Called when all reauth stages fail — session is unrecoverable.
  /// Set by provider layer to trigger navigation to login screen.
  VoidCallback? onForceLogout;

  /// SSE subscription delegate. Set by [SseManager] to route subscriptions
  /// through SSE instead of polling. When null, falls back to polling.
  SseSubscribeDelegate? onSseSubscribe;

  /// Optional request throttler. When set, all [get] calls are routed through
  /// the throttler to limit concurrent outbound requests to the router.
  /// Set by [uspClientProvider] during initialization.
  BridgeRequestThrottler? throttler;

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

  /// Two-stage re-authentication: refreshToken first, then full re-login.
  /// Uses a Completer lock to prevent concurrent reauth attempts.
  ///
  /// After successful reauth, notifies [onTokenRefreshed] so that SSE can
  /// reconnect with the new token (prevents silent subscription routing
  /// failures when the bridge session changes).
  Future<void> reauth() async {
    if (_reauthInProgress != null) {
      await _reauthInProgress!.future;
      return;
    }
    _reauthInProgress = Completer<void>();
    bool didFullRelogin = false;
    try {
      // Stage 1: quick token refresh (no password needed)
      try {
        await refreshToken();
        logger.d('$_tag Token refreshed successfully');
        try {
          onRefreshTokenSuccess?.call();
        } catch (cbError) {
          logger.w('$_tag onRefreshTokenSuccess callback error: $cbError');
        }
        _reauthInProgress!.complete();
        return;
      } catch (e) {
        logger.w('$_tag Token refresh failed: $e');
      }
      // Stage 2: full re-login via stored password
      final reauth = onReauthRequired;
      if (reauth != null) {
        await reauth();
        didFullRelogin = true;
        logger.d('$_tag Full re-login succeeded');
      }
      _reauthInProgress!.complete();
    } catch (e) {
      if (!_reauthInProgress!.isCompleted) {
        _reauthInProgress!.completeError(e);
      }
      // The original trigger was a confirmed 401 (token expired/revoked).
      // Both Stage 1 (refreshToken) and Stage 2 (restoreSession) failed,
      // so the session is unrecoverable regardless of Stage 2 failure reason
      // (auth error, network error, or no stored password).
      logger.w('$_tag All reauth stages failed — forcing logout');
      try {
        onForceLogout?.call();
      } catch (cbError) {
        logger.w('$_tag onForceLogout callback error: $cbError');
      }
      rethrow;
    } finally {
      _reauthInProgress = null;
      // Notify SSE to reconnect after full re-login (new session/token).
      // Stage 1 (refreshToken) typically extends the same session, so
      // SSE reconnect is only needed after Stage 2 (full re-login).
      if (didFullRelogin) {
        onTokenRefreshed?.call();
      }
    }
  }

  /// Wraps an async operation with automatic 401 retry.
  Future<T> _withAuthRetry<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      if (!_isAuthError(e)) rethrow;
      logger.w('$_tag 401 detected, attempting reauth...');
      await reauth();
      _lastCallRetried = true;
      return await action();
    }
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
  }) async {
    if (throttler != null) {
      return throttler!.enqueue(
        cacheKey: 'usp:${paths.join(",")}',
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

    logger.d('$_tag $_separator\n'
        '$_tag #$id GET (Request) → ${paths.length} paths\n'
        '${_prettyList(paths)}');

    try {
      final rawMap = await _withAuthRetry(() => _client.get(paths));
      sw.stop();

      final label = _idLabel(id);
      logger.d('$_tag $_separator\n'
          '$_tag $label GET (Response) ← ${sw.elapsedMilliseconds}ms\n'
          '${_prettyMap(rawMap)}');

      if (rawMap.isEmpty) {
        if (isWildcardOnlyRequest(paths)) {
          // A wildcard GET (e.g. Device.Firewall.DMZ.*) is expanded by the
          // router across the discovered instances of a multi-instance table.
          // When that table has zero instances the response is legitimately
          // empty — the generated model iterates the (empty) instance set and
          // returns an empty list, so this is a normal "no rows" outcome, not
          // a fault. Log it at debug so it does not drown real warnings.
          logger.d('$_tag$label GET empty (wildcard table, no instances): '
              '$paths');
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
      final normalized =
          normalizeGetResponse(paths, rawMap, onMissingPath: missing.add);
      if (missing.isNotEmpty) {
        logger.w('$_tag$label GET missing ${missing.length} path(s) in '
            'response: $missing');
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
      if (path.contains('*') || path.endsWith('.')) continue;
      if (!result.containsKey(path)) {
        onMissingPath?.call(path);
      }
    }
    return result;
  }

  /// Whether every requested path is a wildcard query (contains '*').
  ///
  /// A wildcard GET targets a multi-instance table and the router expands it
  /// across the discovered instances. When that table has zero instances the
  /// response is legitimately empty (the generated model returns an empty
  /// list), so an empty response to a wildcard-only request is a normal
  /// "no rows" outcome rather than a fault. Callers use this to decide whether
  /// an empty GET response deserves a warning. An empty [paths] list is not a
  /// wildcard request.
  @visibleForTesting
  static bool isWildcardOnlyRequest(List<String> paths) =>
      paths.isNotEmpty && paths.every((p) => p.contains('*'));

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
  Future<Map<String, dynamic>> set(Object pathOrParams,
      {dynamic singleValue, bool allowPartial = false}) async {
    if (pathOrParams is String && singleValue != null) {
      return await _singleSet(pathOrParams, singleValue.toString());
    } else if (pathOrParams is Map) {
      return await _batchSet(pathOrParams.cast<String, dynamic>(),
          allowPartial: allowPartial);
    }
    throw ArgumentError(
        'set() expects (String, value) or (Map<String, dynamic>)');
  }

  Future<Map<String, dynamic>> _singleSet(String path, String value) async {
    final id = _genReqId();
    _lastCallRetried = false;
    final sw = Stopwatch()..start();
    final params = {path: value};

    logger.d('$_tag#$id SET →\n${_prettyMap(params)}');

    try {
      final result = await _withAuthRetry(() => _client.set({path: value}));
      sw.stop();
      final label = _idLabel(id);
      logger.d('$_tag$label SET ← (${sw.elapsedMilliseconds}ms)\n'
          '${_prettyMap(result)}');
      return result;
    } catch (e) {
      sw.stop();
      final label = _idLabel(id);
      logger.e('$_tag$label SET ✗ (${sw.elapsedMilliseconds}ms)\n  $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _batchSet(Map<String, dynamic> parameters,
      {bool allowPartial = false}) async {
    final id = _genReqId();
    _lastCallRetried = false;
    final sw = Stopwatch()..start();
    final Map<String, String> stringParams =
        parameters.map((key, value) => MapEntry(key, value.toString()));

    logger.d('$_tag#$id SET${allowPartial ? ' (allowPartial)' : ''} →\n'
        '${_prettyMap(parameters)}');

    try {
      final result = await _withAuthRetry(
          () => _client.set(stringParams, allowPartial: allowPartial));
      sw.stop();
      final label = _idLabel(id);
      logger.d('$_tag$label SET ← (${sw.elapsedMilliseconds}ms)\n'
          '${_prettyMap(result)}');
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

  /// Performs an ordered Set operation where parameter groups are processed
  /// sequentially. Each group is sent as a separate USP Set message.
  /// Use when parameter order affects correctness
  /// (e.g., AddressingType must be set before SubnetMask).
  ///
  /// [parameterGroups] is a list of groups, where each group is a list of
  /// `{path, value}` maps. Groups are processed in order; params within a
  /// group are sent together in one Set message.
  Future<Map<String, dynamic>> setOrdered(
      List<List<Map<String, String>>> parameterGroups,
      {bool allowPartial = false}) async {
    final id = _genReqId();
    _lastCallRetried = false;
    final sw = Stopwatch()..start();

    logger.d('$_tag#$id SET_ORDERED${allowPartial ? ' (allowPartial)' : ''} →\n'
        '${_prettyJson(parameterGroups)}');

    try {
      final result = await _withAuthRetry(() =>
          _client.setOrdered(parameterGroups, allowPartial: allowPartial));
      sw.stop();
      final label = _idLabel(id);
      logger.d('$_tag$label SET_ORDERED ← (${sw.elapsedMilliseconds}ms)\n'
          '${_prettyMap(result)}');
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
  Future<Map<String, dynamic>> add(List<Map<String, dynamic>> items,
      {bool allowPartial = false}) async {
    if (items.length == 1) {
      final item = items.first;
      return await _singleAdd(item['path'] as String,
          item['params'] as Map<String, dynamic>? ?? {});
    }
    return await _batchAdd(items, allowPartial: allowPartial);
  }

  Future<Map<String, dynamic>> _singleAdd(
      String objectPath, Map<String, dynamic> parameters) async {
    final id = _genReqId();
    _lastCallRetried = false;
    final sw = Stopwatch()..start();
    final stringParams = parameters.map((k, v) => MapEntry(k, v.toString()));
    final payload = {'path': objectPath, 'params': stringParams};

    logger.d('$_tag#$id ADD →\n${_prettyMap(payload)}');

    try {
      final result = await _withAuthRetry(() => _client.add([
            {'path': objectPath, 'params': stringParams}
          ]));
      sw.stop();
      final label = _idLabel(id);
      logger.d('$_tag$label ADD ← (${sw.elapsedMilliseconds}ms)\n'
          '${_prettyMap(result)}');
      return result;
    } catch (e) {
      sw.stop();
      final label = _idLabel(id);
      logger.e('$_tag$label ADD ✗ (${sw.elapsedMilliseconds}ms)\n  $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _batchAdd(List<Map<String, dynamic>> objects,
      {bool allowPartial = false}) async {
    final id = _genReqId();
    _lastCallRetried = false;
    final sw = Stopwatch()..start();

    logger.d('$_tag#$id ADD${allowPartial ? ' (allowPartial)' : ''} →\n'
        '${_prettyJson(objects)}');

    try {
      final result = await _withAuthRetry(
          () => _client.add(objects, allowPartial: allowPartial));
      sw.stop();
      final label = _idLabel(id);
      logger.d('$_tag$label ADD ← (${sw.elapsedMilliseconds}ms)\n'
          '${_prettyMap(result)}');
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
  Future<Map<String, dynamic>> delete(List<String> paths,
      {bool allowPartial = false}) async {
    if (paths.length == 1) {
      return await _singleDelete(paths.first);
    }
    return await _batchDelete(paths, allowPartial: allowPartial);
  }

  Future<Map<String, dynamic>> _singleDelete(String path) async {
    final id = _genReqId();
    _lastCallRetried = false;
    final sw = Stopwatch()..start();

    logger.d('$_tag#$id DELETE →\n${_prettyList([path])}');

    try {
      final result = await _withAuthRetry(() => _client.delete([path]));
      sw.stop();
      final label = _idLabel(id);
      logger.d('$_tag$label DELETE ← (${sw.elapsedMilliseconds}ms)\n'
          '${_prettyMap(result)}');
      return result;
    } catch (e) {
      sw.stop();
      final label = _idLabel(id);
      logger.e('$_tag$label DELETE ✗ (${sw.elapsedMilliseconds}ms)\n  $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _batchDelete(List<String> paths,
      {bool allowPartial = false}) async {
    final id = _genReqId();
    _lastCallRetried = false;
    final sw = Stopwatch()..start();

    logger.d('$_tag#$id DELETE${allowPartial ? ' (allowPartial)' : ''} →\n'
        '${_prettyList(paths)}');

    try {
      final result = await _withAuthRetry(
          () => _client.delete(paths, allowPartial: allowPartial));
      sw.stop();
      final label = _idLabel(id);
      logger.d('$_tag$label DELETE ← (${sw.elapsedMilliseconds}ms)\n'
          '${_prettyMap(result)}');
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
  Future<Map<String, dynamic>> operate(String command,
      {Map<String, String> args = const {}}) async {
    final id = _genReqId();
    _lastCallRetried = false;
    final sw = Stopwatch()..start();

    final payload = <String, dynamic>{
      'command': command,
      if (args.isNotEmpty) 'args': args
    };
    logger.d('$_tag#$id OPERATE →\n${_prettyMap(payload)}');

    try {
      final rawResponse =
          await _withAuthRetry(() => _client.operate(command, args: args));
      sw.stop();

      // Extract commandKey and outputArgs from WASM v0.11.0 unified format:
      // { success, result: { data: { commandKey, outputArgs }, error? } }
      final response = _extractOperateResult(rawResponse);
      final label = _idLabel(id);
      logger.d('$_tag$label OPERATE ← (${sw.elapsedMilliseconds}ms)\n'
          '${_prettyMap(response)}');
      return response;
    } catch (e) {
      sw.stop();
      final label = _idLabel(id);
      logger.e('$_tag$label OPERATE ✗ (${sw.elapsedMilliseconds}ms)\n  $e');
      rethrow;
    }
  }

  /// Extracts commandKey and outputArgs from WASM v0.11.0 unified format.
  Map<String, dynamic> _extractOperateResult(Map<String, dynamic> raw) {
    final result = raw['result'] as Map?;
    if (result == null) return raw; // fallback to raw if not v0.11.0 format

    final data = result['data'] as Map?;
    if (data == null) return {};

    final output = <String, dynamic>{};
    final commandKey = data['commandKey']?.toString();
    if (commandKey != null && commandKey.isNotEmpty) {
      output['commandKey'] = commandKey;
    }
    final rawOutputArgs = data['outputArgs'];
    if (rawOutputArgs is Map) {
      for (final entry in rawOutputArgs.entries) {
        output[entry.key.toString()] = entry.value.toString();
      }
    }
    return output;
  }

  // ===========================================================================
  // OBUSPA Subscription — Device.LocalAgent.Subscription management
  // ===========================================================================

  /// Creates an OBUSPA subscription via USP Add + Set.
  ///
  /// This creates a `Device.LocalAgent.Subscription.{i}` instance in OBUSPA,
  /// configures Enable/NotifType/ReferenceList, and returns the created
  /// instance path with its Recipient (auto-assigned to the calling
  /// Controller — typically Controller.2 or .3 for localui/UDS).
  ///
  /// [notifType] is the USP notification type string:
  /// "ValueChange", "ObjectCreation", "ObjectDeletion",
  /// "OperationComplete", or "Event".
  ///
  /// [referenceList] is the TR-181 path or command to monitor,
  /// e.g., "Device.IP.Diagnostics.IPPing()" for OperationComplete.
  ///
  /// Returns a map with keys: `instancePath`, `recipient`, plus the
  /// configured parameters.
  ///
  /// Throws if the Add or Set operations fail.
  Future<Map<String, String>> createNotifySubscription({
    required String notifType,
    required String referenceList,
  }) async {
    final id = _genReqId();
    final sw = Stopwatch()..start();
    const objectPath = 'Device.LocalAgent.Subscription.';

    // Step 1: Snapshot existing instance IDs
    final before = await _withAuthRetry(() => _client.get([objectPath]));
    final existingIds = before.keys
        .where((k) => k.endsWith('.Enable'))
        .map((k) {
          final parts = k.split('.');
          return parts.length >= 5 ? parts[parts.length - 2] : '';
        })
        .where((id) => id.isNotEmpty)
        .toSet();

    // Step 2: Add subscription instance
    final addResult = await _withAuthRetry(() => _client.add([
          {'path': objectPath, 'params': <String, dynamic>{}}
        ]));

    // Step 3: Resolve instance path from structured result.
    // add() returns the WASM v0.11.0 unified shape
    // {success, result: {data: {instances: [<path>, ...]}}}. Parse it via the
    // canonical UspResultParser rather than reading keys by hand (the old
    // addResult['results'] / createdInstances path was the pre-unified shape and
    // is always null now → every subscription fell through to the GET-diff).
    String instancePath;

    String? createdPath;
    final parsedAdd = UspResultParser.parseAddResult(addResult);
    if (parsedAdd is UspSuccess<List<String>>) {
      final created = parsedAdd.allCreatedInstances;
      if (created.isNotEmpty) createdPath = created.first.affectedPath;
    }

    if (createdPath != null && createdPath.startsWith('Device.')) {
      instancePath = createdPath.endsWith('.') ? createdPath : '$createdPath.';
    } else {
      // Discover new instance via GET diff
      final after = await _withAuthRetry(() => _client.get([objectPath]));
      final afterIds = after.keys
          .where((k) => k.endsWith('.Enable'))
          .map((k) {
            final parts = k.split('.');
            return parts.length >= 5 ? parts[parts.length - 2] : '';
          })
          .where((id) => id.isNotEmpty)
          .toSet();
      final newIds = afterIds.difference(existingIds);
      if (newIds.isEmpty) {
        throw StateError(
            'USP Add succeeded but no new instance found in $objectPath');
      }
      instancePath = '$objectPath${newIds.first}.';
    }

    // Step 4: Set Enable, NotifType, ReferenceList
    await _withAuthRetry(() => _client.set({
          '${instancePath}Enable': 'true',
          '${instancePath}NotifType': notifType,
          '${instancePath}ReferenceList': referenceList,
        }));

    // Step 5: Read back to verify
    final verify = await _withAuthRetry(() => _client.get([
          '${instancePath}Recipient',
          '${instancePath}Enable',
          '${instancePath}NotifType',
          '${instancePath}ReferenceList',
        ]));

    sw.stop();
    final recipient = verify['${instancePath}Recipient'] ?? '';
    logger.d('$_tag#$id CREATE_SUBSCRIPTION $instancePath '
        'type=$notifType ref=$referenceList → Recipient=$recipient '
        '(${sw.elapsedMilliseconds}ms)');

    return {
      'instancePath': instancePath,
      ...verify,
    };
  }

  /// Deletes an OBUSPA subscription instance.
  Future<void> deleteNotifySubscription(String instancePath) async {
    final id = _genReqId();
    final sw = Stopwatch()..start();
    await _withAuthRetry(() => _client.delete([instancePath]));
    sw.stop();
    final shortPath = instancePath.startsWith('Device.')
        ? instancePath.substring(7)
        : instancePath;
    logger.d('$_tag#$id DELETE_SUBSCRIPTION $shortPath '
        '(${sw.elapsedMilliseconds}ms)');
  }

  /// Lists all OBUSPA subscriptions via the WASM client.
  ///
  /// Returns raw subscription objects from the router. Each entry typically
  /// contains fields like `instance_path`, `notif_type`, `reference_list`, etc.
  Future<List<Map<String, dynamic>>> listSubscriptions() async {
    final id = _genReqId();
    final sw = Stopwatch()..start();
    final subs = await _withAuthRetry(() => _client.listSubscriptions());
    sw.stop();
    logger.d('$_tag#$id LIST_SUBSCRIPTIONS → ${subs.length} entries '
        '(${sw.elapsedMilliseconds}ms)');
    return subs;
  }

  /// Deletes all OBUSPA subscriptions on the router.
  ///
  /// Called at startup to purge stale subscriptions from previous sessions.
  /// Browser refresh doesn't trigger dispose(), so subscriptions accumulate
  /// on the router, causing duplicate SSE notifications.
  ///
  /// Uses GET-based enumeration (same proven approach as
  /// [createNotifySubscription] Step 1) rather than relying on the WASM
  /// `listSubscriptions()` output format.
  ///
  /// Returns the number of subscriptions deleted.
  Future<int> purgeAllSubscriptions() async {
    final id = _genReqId();
    final sw = Stopwatch()..start();
    const objectPath = 'Device.LocalAgent.Subscription.';

    // Enumerate all subscription instances via GET
    final allParams = await _withAuthRetry(() => _client.get([objectPath]));

    // Extract unique instance IDs from keys like
    // "Device.LocalAgent.Subscription.3.Enable"
    final instanceIds = <String>{};
    for (final key in allParams.keys) {
      final match =
          RegExp(r'Device\.LocalAgent\.Subscription\.(\d+)\.').firstMatch(key);
      if (match != null) {
        instanceIds.add(match.group(1)!);
      }
    }

    if (instanceIds.isEmpty) {
      sw.stop();
      logger.d('$_tag#$id PURGE_SUBSCRIPTIONS → 0 (none found, '
          '${sw.elapsedMilliseconds}ms)');
      return 0;
    }

    // Log what we're about to delete
    for (final instId in instanceIds) {
      final prefix = '$objectPath$instId.';
      final notifType = allParams['${prefix}NotifType'] ?? '?';
      final refList = allParams['${prefix}ReferenceList'] ?? '?';
      logger.d('$_tag#$id PURGE: $prefix '
          '(type=$notifType, ref=$refList)');
    }

    int deleted = 0;
    for (final instId in instanceIds) {
      final instancePath = '$objectPath$instId.';
      try {
        await _withAuthRetry(() => _client.delete([instancePath]));
        deleted++;
      } catch (e) {
        logger.w('$_tag#$id PURGE failed to delete '
            '$instancePath: $e');
      }
    }

    sw.stop();
    logger.d('$_tag#$id PURGE_SUBSCRIPTIONS → deleted $deleted/'
        '${instanceIds.length} (${sw.elapsedMilliseconds}ms)');
    return deleted;
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
          id: id, notifType: notifType, paths: paths, parser: parser);
    }
    return _pollingSubscribe(
        id: id,
        notifType: notifType,
        paths: paths,
        parser: parser,
        interval: interval);
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
