import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:privacy_gui/core/utils/logger.dart';

import 'bridge_request_throttler.dart';
import '../models/usp_operation_result.dart';
import '../../errors/service_error.dart';

// Conditional import: use WASM client on Web, stub on other platforms (VM/tests).
import '../stub/usp_client_stub.dart'
    if (dart.library.js_interop) '../web/usp_client_wasm.dart';

// Export response helpers so generated code only needs one import.
export 'usp_response_helpers.dart';
// Export RequestPriority so generated fetch() methods can accept priority.
export 'bridge_request_throttler.dart' show RequestPriority;
// Export USP operation result types for application layer use.
export '../models/usp_operation_result.dart';

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
  late final UspClientWeb _client;
  final String _baseUrl;

  UspClient(String baseUrl) : _baseUrl = baseUrl {
    if (!kIsWeb) {
      throw UnsupportedError('This POC only supports Web platforms currently.');
    }
    _client = UspClientWeb(baseUrl);
  }

  static int _reqId = 0;

  String get baseUrl => _baseUrl;

  bool get isAuthenticated => _client.isAuthenticated;

  String? get sessionToken => _client.sessionToken;

  /// Callback for full re-authentication when token refresh fails.
  /// Set by [UspAuthCoordinator] to provide re-login via stored password.
  Future<void> Function()? onReauthRequired;

  /// Called after [reauth] completes successfully (either refreshToken or
  /// full re-login). Set by [SseManager] to force SSE reconnect with the
  /// new token, preventing silent subscription routing failures.
  VoidCallback? onTokenRefreshed;

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

  Future<void> refreshToken() async {
    await _client.refreshToken();
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
        logger.d('[USP][Service]Token refreshed successfully');
        _reauthInProgress!.complete();
        return;
      } catch (e) {
        logger.w('[USP][Service]Token refresh failed: $e');
      }
      // Stage 2: full re-login via stored password
      final reauth = onReauthRequired;
      if (reauth != null) {
        await reauth();
        didFullRelogin = true;
        logger.d('[USP][Service]Full re-login succeeded');
      }
      _reauthInProgress!.complete();
    } catch (e) {
      if (!_reauthInProgress!.isCompleted) {
        _reauthInProgress!.completeError(e);
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
      logger.w('[USP][Service]401 detected, attempting reauth...');
      await reauth();
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
    final id = ++_reqId;
    final sw = Stopwatch()..start();
    final rawMap = await _withAuthRetry(() => _client.getMultiple(paths));
    sw.stop();

    logger.d('[USP][Service]#$id GET ${_pathSummary(paths)} '
        '${paths.length} paths → ${rawMap.length} keys (${sw.elapsedMilliseconds}ms)');
    if (rawMap.isEmpty) {
      logger.w('[USP][Service]#$id GET response EMPTY for paths: $paths');
    } else {
      logger.d('[USP][Service]#$id ← ${_mapSummary(rawMap)}');
    }

    final Map<String, dynamic> result = {};

    // Include all returned paths (may include extra child paths)
    for (final entry in rawMap.entries) {
      result[entry.key] = _coerceValue(entry.key, entry.value);
    }

    // Ensure all requested non-wildcard paths exist in the result to prevent
    // Null Cast errors in codegen. Wildcard search paths (containing '*') are
    // expanded by the router into concrete instance paths, so the original
    // wildcard path won't appear in the response — skip those.
    for (final path in paths) {
      if (path.contains('*')) continue;
      if (!result.containsKey(path)) {
        logger.w('[USP][Service]GET missing path in response: "$path"');
      }
      result.putIfAbsent(path, () => null);
    }

    return result;
  }

  /// Coerce a raw string value from USP into the appropriate Dart type.
  /// - "true" / "false" →bool (any path)
  /// - "1" / "0" →bool (for known boolean suffixes: Enable, Active)
  /// - null →null (key absent from response)
  /// - Empty string →'' (preserve String type for generated code)
  /// - Everything else stays as String (generated code handles int parsing)
  dynamic _coerceValue(String path, String? raw) {
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

  /// Sets multiple USP parameters and returns structured operation result.
  ///
  /// Returns a Map containing:
  /// - 'overallSuccess': bool - true if all operations succeeded
  /// - 'hasAnySuccess': bool - true if at least one operation succeeded
  /// - 'hasErrors': bool - true if at least one operation failed
  /// - 'results': List<Map> - detailed results per parameter
  Future<Map<String, dynamic>> set(Map<String, dynamic> parameters,
      {bool allowPartial = false}) async {
    final id = ++_reqId;
    final sw = Stopwatch()..start();
    final Map<String, String> stringParams =
        parameters.map((key, value) => MapEntry(key, value.toString()));
    final result = await _withAuthRetry(
        () => _client.setMultiple(stringParams, allowPartial: allowPartial));
    sw.stop();
    logger.d('[USP][Service]#$id SET ${_paramSummary(parameters)} '
        '${parameters.length} params'
        '${allowPartial ? ' (allowPartial)' : ''} (${sw.elapsedMilliseconds}ms)');

    // Log result summary for WASM v0.11.0 format
    final success = result['success'] as bool? ?? false;
    final resultData =
        result['result'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final data =
        resultData['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final error = resultData['error'] as Map<String, dynamic>?;
    final hasErrors = error != null;
    logger.d(
        '[USP][Service]#$id SET result: success=$success, errors=$hasErrors, dataKeys=${data.keys.length}');

    // Log detailed results in debug mode
    if (kDebugMode) {
      if (data.isNotEmpty) {
        logger.d('[USP][Service]#$id SET data: ${data.keys.join(', ')}');
      }
      if (error != null) {
        logger.d('[USP][Service]#$id SET errors: ${error.keys.join(', ')}');
      }
    }

    return result;
  }

  Future<Map<String, dynamic>> setMultiple(Map<String, String> parameters,
      {bool allowPartial = false}) async {
    return await _withAuthRetry(
        () => _client.setMultiple(parameters, allowPartial: allowPartial));
  }

  // ===========================================================================
  // Add Operation — create new object instances
  // ===========================================================================

  /// Creates a new object instance at the given path with initial parameters.
  ///
  /// [objectPath] must end with "." (e.g., "Device.NAT.PortMapping.").
  /// [parameters] are the initial parameter values for the new instance.
  /// Returns structured operation result containing creation details.
  Future<Map<String, dynamic>> add(
      String objectPath, Map<String, dynamic> parameters) async {
    final id = ++_reqId;
    final sw = Stopwatch()..start();
    final stringParams = parameters.map((k, v) => MapEntry(k, v.toString()));
    final result =
        await _withAuthRetry(() => _client.add(objectPath, stringParams));
    sw.stop();
    final shortPath =
        objectPath.startsWith('Device.') ? objectPath.substring(7) : objectPath;

    // Extract created instance path for logging compatibility
    final success = result['success'] as bool? ?? false;
    final resultData =
        result['result'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final data =
        resultData['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    String createdPath = 'unknown';

    if (success && data.containsKey('instances')) {
      final instances = data['instances'] as List? ?? [];
      if (instances.isNotEmpty) {
        createdPath = instances.first as String? ?? 'unknown';
      }
    }

    logger.d('[USP][Service]#$id ADD $shortPath — '
        '${parameters.length} params → $createdPath (${sw.elapsedMilliseconds}ms)');

    // Log detailed results in debug mode
    if (kDebugMode) {
      final overallSuccess = result['overallSuccess'] as bool? ?? false;
      final hasErrors = result['hasErrors'] as bool? ?? false;
      final results = result['results'] as List? ?? [];

      logger.d(
          '[USP][Service]#$id ADD result: success=$overallSuccess, errors=$hasErrors, details=${results.length}');

      for (var i = 0; i < results.length; i++) {
        final detail = results[i] as Map<String, dynamic>? ?? {};
        final requestedPath = detail['requestedPath'] ?? 'unknown';
        final success = detail['success'] ?? false;

        if (success) {
          final createdInstances = detail['createdInstances'] as List? ?? [];
          logger.d(
              '[USP][Service]#$id ADD[$i] ✅ $requestedPath → ${createdInstances.length} instances created');

          for (var instance in createdInstances) {
            final instanceMap = instance as Map<String, dynamic>? ?? {};
            final affectedPath = instanceMap['affectedPath'] ?? 'unknown';
            final initialParams = instanceMap['initialParams'] as Map? ?? {};
            logger.d(
                '[USP][Service]#$id ADD[$i]   🆕 $affectedPath with ${initialParams.length} params: ${initialParams.keys.join(', ')}');
          }
        } else {
          final errorCode = detail['errorCode'] ?? 'unknown';
          final errorMessage = detail['errorMessage'] ?? 'unknown error';
          logger.w(
              '[USP][Service]#$id ADD[$i] ❌ $requestedPath → Error $errorCode: $errorMessage');
        }
      }
    }

    return result;
  }

  /// Creates multiple object instances in a single operation.
  ///
  /// Each element in [objects] should have:
  /// - `path` (String): object path ending with "."
  /// - `parameters` (Map<String, String>): initial parameter values
  ///
  /// Returns structured operation result containing creation details.
  Future<Map<String, dynamic>> addMultiple(List<Map<String, dynamic>> objects,
      {bool allowPartial = false}) async {
    final id = ++_reqId;
    final sw = Stopwatch()..start();
    final result = await _withAuthRetry(
        () => _client.addMultiple(objects, allowPartial: allowPartial));
    sw.stop();

    // Extract created count for logging compatibility
    final results = result['results'] as List? ?? [];
    final createdCount = results.where((r) => r['success'] == true).length;

    logger.d('[USP][Service]#$id ADD_MULTI ${objects.length} objects '
        '→ $createdCount created'
        '${allowPartial ? ' (allowPartial)' : ''} (${sw.elapsedMilliseconds}ms)');

    // Log detailed results in debug mode
    if (kDebugMode && results.isNotEmpty) {
      final overallSuccess = result['overallSuccess'] as bool? ?? false;
      final hasErrors = result['hasErrors'] as bool? ?? false;
      logger.d(
          '[USP][Service]#$id ADD_MULTI result: success=$overallSuccess, errors=$hasErrors');

      for (var i = 0; i < results.length; i++) {
        final detail = results[i] as Map<String, dynamic>? ?? {};
        final requestedPath = detail['requestedPath'] ?? 'unknown';
        final success = detail['success'] ?? false;

        if (success) {
          final createdInstances = detail['createdInstances'] as List? ?? [];
          logger.d(
              '[USP][Service]#$id ADD_MULTI[$i] ✅ $requestedPath → ${createdInstances.length} instances');

          for (var instance in createdInstances) {
            final instanceMap = instance as Map<String, dynamic>? ?? {};
            final affectedPath = instanceMap['affectedPath'] ?? 'unknown';
            logger.d('[USP][Service]#$id ADD_MULTI[$i]   🆕 $affectedPath');
          }
        } else {
          final errorCode = detail['errorCode'] ?? 'unknown';
          final errorMessage = detail['errorMessage'] ?? 'unknown error';
          logger.w(
              '[USP][Service]#$id ADD_MULTI[$i] ❌ $requestedPath → Error $errorCode: $errorMessage');
        }
      }
    }

    return result;
  }

  // ===========================================================================
  // Delete Operation — remove object instances
  // ===========================================================================

  /// Deletes the object instance at the given path.
  ///
  /// [path] must be a specific instance path (e.g., "Device.NAT.PortMapping.3.").
  /// Returns structured operation result containing deletion details.
  Future<Map<String, dynamic>> delete(String path) async {
    final id = ++_reqId;
    final sw = Stopwatch()..start();
    final result = await _withAuthRetry(() => _client.delete(path));
    sw.stop();
    final shortPath = path.startsWith('Device.') ? path.substring(7) : path;
    logger.d(
        '[USP][Service]#$id DELETE $shortPath (${sw.elapsedMilliseconds}ms)');

    // Log detailed results in debug mode
    if (kDebugMode) {
      final overallSuccess = result['overallSuccess'] as bool? ?? false;
      final hasErrors = result['hasErrors'] as bool? ?? false;
      final results = result['results'] as List? ?? [];

      logger.d(
          '[USP][Service]#$id DELETE result: success=$overallSuccess, errors=$hasErrors, details=${results.length}');

      for (var i = 0; i < results.length; i++) {
        final detail = results[i] as Map<String, dynamic>? ?? {};
        final requestedPath = detail['requestedPath'] ?? 'unknown';
        final success = detail['success'] ?? false;

        if (success) {
          final deletedInstances = detail['deletedInstances'] as List? ?? [];
          logger.d(
              '[USP][Service]#$id DELETE[$i] ✅ $requestedPath → ${deletedInstances.length} instances deleted');

          for (var instance in deletedInstances) {
            final instanceMap = instance as Map<String, dynamic>? ?? {};
            final affectedPath = instanceMap['affectedPath'] ?? 'unknown';
            logger.d('[USP][Service]#$id DELETE[$i]   🗑️ $affectedPath');
          }
        } else {
          final errorCode = detail['errorCode'] ?? 'unknown';
          final errorMessage = detail['errorMessage'] ?? 'unknown error';
          logger.w(
              '[USP][Service]#$id DELETE[$i] ❌ $requestedPath → Error $errorCode: $errorMessage');
        }
      }
    }

    return result;
  }

  /// Deletes multiple object instances in a single operation.
  /// Returns structured operation result containing deletion details.
  Future<Map<String, dynamic>> deleteMultiple(List<String> paths,
      {bool allowPartial = false}) async {
    final id = ++_reqId;
    final sw = Stopwatch()..start();
    final result = await _withAuthRetry(
        () => _client.deleteMultiple(paths, allowPartial: allowPartial));
    sw.stop();
    logger.d('[USP][Service]#$id DELETE_MULTI ${_pathSummary(paths)} '
        '${paths.length} paths'
        '${allowPartial ? ' (allowPartial)' : ''} (${sw.elapsedMilliseconds}ms)');

    // Log detailed results in debug mode
    if (kDebugMode) {
      final overallSuccess = result['overallSuccess'] as bool? ?? false;
      final hasErrors = result['hasErrors'] as bool? ?? false;
      final results = result['results'] as List? ?? [];

      logger.d(
          '[USP][Service]#$id DELETE_MULTI result: success=$overallSuccess, errors=$hasErrors, details=${results.length}');

      for (var i = 0; i < results.length; i++) {
        final detail = results[i] as Map<String, dynamic>? ?? {};
        final requestedPath = detail['requestedPath'] ?? 'unknown';
        final success = detail['success'] ?? false;

        if (success) {
          final deletedInstances = detail['deletedInstances'] as List? ?? [];
          logger.d(
              '[USP][Service]#$id DELETE_MULTI[$i] ✅ $requestedPath → ${deletedInstances.length} instances deleted');

          for (var instance in deletedInstances) {
            final instanceMap = instance as Map<String, dynamic>? ?? {};
            final affectedPath = instanceMap['affectedPath'] ?? 'unknown';
            logger.d('[USP][Service]#$id DELETE_MULTI[$i]   🗑️ $affectedPath');
          }
        } else {
          final errorCode = detail['errorCode'] ?? 'unknown';
          final errorMessage = detail['errorMessage'] ?? 'unknown error';
          logger.w(
              '[USP][Service]#$id DELETE_MULTI[$i] ❌ $requestedPath → Error $errorCode: $errorMessage');
        }
      }
    }

    return result;
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
    final id = ++_reqId;
    final sw = Stopwatch()..start();
    final response =
        await _withAuthRetry(() => _client.operate(command, args: args));
    sw.stop();
    logger.d('[USP][Service]#$id OPERATE $command'
        '${args.isNotEmpty ? ' — ${args.length} args' : ''}'
        ' → key=${response['commandKey']}, ${response.length} output keys'
        ' (${sw.elapsedMilliseconds}ms)');
    if (response.isNotEmpty) {
      logger.d('[USP][Service]#$id ← ${_mapSummary(response)}');
    }
    return response;
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
    final id = ++_reqId;
    final sw = Stopwatch()..start();
    const objectPath = 'Device.LocalAgent.Subscription.';

    // Step 1: Snapshot existing instance IDs
    final before =
        await _withAuthRetry(() => _client.getMultiple([objectPath]));
    final existingIds = before.keys
        .where((k) => k.endsWith('.Enable'))
        .map((k) {
          final parts = k.split('.');
          return parts.length >= 5 ? parts[parts.length - 2] : '';
        })
        .where((id) => id.isNotEmpty)
        .toSet();

    // Step 2: Add subscription instance
    final addResult = await _withAuthRetry(() => _client.add(objectPath, {}));

    // Step 3: Resolve instance path from structured result
    String instancePath;

    // Try to extract created path from structured response
    String? createdPath;
    final results = addResult['results'] as List? ?? [];
    if (results.isNotEmpty) {
      final firstResult = results.first as Map<String, dynamic>? ?? {};
      final createdInstances = firstResult['createdInstances'] as List? ?? [];
      if (createdInstances.isNotEmpty) {
        final firstInstance =
            createdInstances.first as Map<String, dynamic>? ?? {};
        createdPath = firstInstance['affectedPath'] as String?;
      }
    }

    if (createdPath != null && createdPath.startsWith('Device.')) {
      instancePath = createdPath.endsWith('.') ? createdPath : '$createdPath.';
    } else {
      // Discover new instance via GET diff
      final after =
          await _withAuthRetry(() => _client.getMultiple([objectPath]));
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
    await _withAuthRetry(() => _client.setMultiple({
          '${instancePath}Enable': 'true',
          '${instancePath}NotifType': notifType,
          '${instancePath}ReferenceList': referenceList,
        }));

    // Step 5: Read back to verify
    final verify = await _withAuthRetry(() => _client.getMultiple([
          '${instancePath}Recipient',
          '${instancePath}Enable',
          '${instancePath}NotifType',
          '${instancePath}ReferenceList',
        ]));

    sw.stop();
    final recipient = verify['${instancePath}Recipient'] ?? '';
    logger.d('[USP][Service]#$id CREATE_SUBSCRIPTION $instancePath '
        'type=$notifType ref=$referenceList → Recipient=$recipient '
        '(${sw.elapsedMilliseconds}ms)');

    return {
      'instancePath': instancePath,
      ...verify,
    };
  }

  /// Deletes an OBUSPA subscription instance.
  Future<void> deleteNotifySubscription(String instancePath) async {
    final id = ++_reqId;
    final sw = Stopwatch()..start();
    await _withAuthRetry(() => _client.delete(instancePath));
    sw.stop();
    final shortPath = instancePath.startsWith('Device.')
        ? instancePath.substring(7)
        : instancePath;
    logger.d('[USP][Service]#$id DELETE_SUBSCRIPTION $shortPath '
        '(${sw.elapsedMilliseconds}ms)');
  }

  /// Lists all OBUSPA subscriptions via the WASM client.
  ///
  /// Returns raw subscription objects from the router. Each entry typically
  /// contains fields like `instance_path`, `notif_type`, `reference_list`, etc.
  Future<List<Map<String, dynamic>>> listSubscriptions() async {
    final id = ++_reqId;
    final sw = Stopwatch()..start();
    final subs = await _withAuthRetry(() => _client.listSubscriptions());
    sw.stop();
    logger.d('[USP][Service]#$id LIST_SUBSCRIPTIONS → ${subs.length} entries '
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
    final id = ++_reqId;
    final sw = Stopwatch()..start();
    const objectPath = 'Device.LocalAgent.Subscription.';

    // Enumerate all subscription instances via GET
    final allParams =
        await _withAuthRetry(() => _client.getMultiple([objectPath]));

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
      logger.d('[USP][Service]#$id PURGE_SUBSCRIPTIONS → 0 (none found, '
          '${sw.elapsedMilliseconds}ms)');
      return 0;
    }

    // Log what we're about to delete
    for (final instId in instanceIds) {
      final prefix = '$objectPath$instId.';
      final notifType = allParams['${prefix}NotifType'] ?? '?';
      final refList = allParams['${prefix}ReferenceList'] ?? '?';
      logger.d('[USP][Service]#$id PURGE: $prefix '
          '(type=$notifType, ref=$refList)');
    }

    int deleted = 0;
    for (final instId in instanceIds) {
      final instancePath = '$objectPath$instId.';
      try {
        await _withAuthRetry(() => _client.delete(instancePath));
        deleted++;
      } catch (e) {
        logger.w('[USP][Service]#$id PURGE failed to delete '
            '$instancePath: $e');
      }
    }

    sw.stop();
    logger.d('[USP][Service]#$id PURGE_SUBSCRIPTIONS → deleted $deleted/'
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
            logger
                .w('[USP][Service]SSE subscribe re-fetch error for "$id": $e');
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
      logger.w('[USP][Service]SSE subscribe initial fetch error for "$id": $e');
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
            logger.w('[USP][Service]Subscribe poll error for "$id": $e');
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

  /// Abbreviates a list of paths for concise logging.
  ///
  /// Shows up to [max] paths with the `Device.` prefix stripped, followed by
  /// `+N more` if there are additional paths.
  static String _pathSummary(List<String> paths, {int max = 2}) {
    if (paths.isEmpty) return '[]';
    final shown = paths
        .take(max)
        .map((p) => p.startsWith('Device.') ? p.substring(7) : p)
        .toList();
    final remaining = paths.length - shown.length;
    final suffix = remaining > 0 ? ', +$remaining more' : '';
    return '[${shown.join(', ')}$suffix]';
  }

  /// Abbreviates a map of param keys for concise logging.
  static String _paramSummary(Map<String, dynamic> params, {int max = 2}) {
    if (params.isEmpty) return '[]';
    final shown = params.keys
        .take(max)
        .map((p) => p.startsWith('Device.') ? p.substring(7) : p)
        .toList();
    final remaining = params.length - shown.length;
    final suffix = remaining > 0 ? ', +$remaining more' : '';
    return '[${shown.join(', ')}$suffix]';
  }

  /// Converts a flat dot-path map into a nested JSON tree for logging.
  ///
  /// e.g. `{"Device.IP.Stats.BytesSent": "123"}` →
  /// ```json
  /// {"Device":{"IP":{"Stats":{"BytesSent":"123"}}}}
  /// ```
  static String _mapSummary(Map<String, dynamic> map) {
    final nested = <String, dynamic>{};
    for (final entry in map.entries) {
      final segments = entry.key.split('.');
      Map<String, dynamic> current = nested;
      for (var i = 0; i < segments.length - 1; i++) {
        current = current.putIfAbsent(segments[i], () => <String, dynamic>{})
            as Map<String, dynamic>;
      }
      current[segments.last] = entry.value;
    }
    return const JsonEncoder.withIndent('  ').convert(nested);
  }

  // ===========================================================================
  // Application Layer封裝方法 - 返回強型別結果
  // ===========================================================================

  /// 應用層GET操作封裝，返回強型別結構化結果
  Future<UspGetResult> getWithResult(List<String> paths,
      {RequestPriority? priority}) async {
    final id = ++_reqId;
    final sw = Stopwatch()..start();

    try {
      // 直接使用 WASM 客戶端的結構化方法
      final structuredResult = await _client.getMultipleStructured(paths);
      sw.stop();

      logger.d('[USP][Client]#$id GET_STRUCTURED ${_pathSummary(paths)} '
          '${paths.length} paths → structured result (${sw.elapsedMilliseconds}ms)');

      return UspResultParser.parseGetResult(structuredResult);
    } catch (e) {
      sw.stop();
      logger.e(
          '[USP][Client]#$id GET_STRUCTURED failed: $e (${sw.elapsedMilliseconds}ms)');
      return UspResultParser.createFailureFromException<Map<String, dynamic>>(
        e,
        paths.join(', '),
      );
    }
  }

  /// 應用層SET操作封裝，返回強型別結果
  ///
  /// [allowPartial] = false (atomic): 只返回 UspSuccess，其他情況拋出 ServiceError
  /// [allowPartial] = true (best-effort): 返回 UspSuccess 或 UspPartialSuccess，只有完全失敗才拋出 ServiceError
  Future<UspSetResult> setWithResult(Map<String, dynamic> parameters,
      {bool allowPartial = false}) async {
    try {
      final resultMap = await set(parameters, allowPartial: allowPartial);
      final result = UspResultParser.parseSetResult(resultMap);

      return switch (result) {
        UspSuccess() => result, // 總是返回成功
        UspPartialSuccess() when allowPartial => result, // 只在允許部分成功時返回
        UspPartialSuccess() => throw UspAtomicModeFailureError(
            summary: (result as UspPartialSuccess).errorSummary,
            successPaths: result.successes.map((s) => s.requestedPath).toList(),
            failedPaths: result.failures.map((f) => f.requestedPath).toList(),
          ),
        UspFailure() => throw UspCompleteFailureError(
            summary: (result as UspFailure).errorSummary,
            failedPaths: result.errors.map((e) => e.requestedPath).toList(),
          ),
      };
    } on ServiceError {
      rethrow; // 重新拋出已經是 ServiceError 的異常
    } catch (e) {
      // 轉換其他異常（如網路錯誤）為適當的 ServiceError
      throw UspCompleteFailureError(
        summary: 'Transport error: $e',
        failedPaths: parameters.keys.toList(),
      );
    }
  }

  /// 應用層ADD操作封裝，返回強型別結果
  Future<UspAddResult> addWithResult(
      String objectPath, Map<String, String> params) async {
    try {
      final resultMap = await add(objectPath, params);
      return UspResultParser.parseAddResult(resultMap);
    } catch (e) {
      return UspResultParser.createFailureFromException<List<String>>(
        e,
        objectPath,
      );
    }
  }

  /// 應用層DELETE操作封裝，返回強型別結果
  Future<UspDeleteResult> deleteWithResult(String instancePath) async {
    try {
      final resultMap = await delete(instancePath);
      return UspResultParser.parseDeleteResult(resultMap);
    } catch (e) {
      return UspResultParser.createFailureFromException<void>(
        e,
        instancePath,
      );
    }
  }

  /// 應用層批量DELETE操作封裝，返回強型別結果
  Future<UspDeleteResult> deleteMultipleWithResult(List<String> paths,
      {bool allowPartial = false}) async {
    try {
      final resultMap = await deleteMultiple(paths, allowPartial: allowPartial);
      return UspResultParser.parseDeleteResult(resultMap);
    } catch (e) {
      return UspResultParser.createFailureFromException<void>(
        e,
        paths.join(', '),
      );
    }
  }

  /// 應用層批量ADD操作封裝，返回強型別結果
  Future<UspAddResult> addMultipleWithResult(List<Map<String, dynamic>> objects,
      {bool allowPartial = false}) async {
    try {
      final resultMap = await addMultiple(objects, allowPartial: allowPartial);
      return UspResultParser.parseAddResult(resultMap);
    } catch (e) {
      return UspResultParser.createFailureFromException<List<String>>(
        e,
        objects.map((obj) => obj['path'] as String? ?? 'unknown').join(', '),
      );
    }
  }

  void dispose() {
    _client.dispose();
  }
}
