import 'dart:async';

import 'package:flutter/foundation.dart';

// Conditional import: use WASM client on Web, stub on other platforms (VM/tests).
import '../stub/usp_client_stub.dart'
    if (dart.library.js_interop) '../web/usp_client_wasm.dart';

// Export response helpers so generated code only needs one import.
export 'usp_response_helpers.dart';

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
class UspService {
  late final UspClientWeb _client;
  final String _baseUrl;

  UspService(String baseUrl) : _baseUrl = baseUrl {
    if (!kIsWeb) {
      throw UnsupportedError('This POC only supports Web platforms currently.');
    }
    _client = UspClientWeb(baseUrl);
  }

  String get baseUrl => _baseUrl;

  bool get isAuthenticated => _client.isAuthenticated;

  String? get sessionToken => _client.sessionToken;

  /// Callback for full re-authentication when token refresh fails.
  /// Set by [UspAuthCoordinator] to provide re-login via stored password.
  Future<void> Function()? onReauthRequired;

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
  Future<void> reauth() async {
    if (_reauthInProgress != null) {
      await _reauthInProgress!.future;
      return;
    }
    _reauthInProgress = Completer<void>();
    try {
      // Stage 1: quick token refresh (no password needed)
      try {
        await refreshToken();
        debugPrint('[UspService] Token refreshed successfully');
        _reauthInProgress!.complete();
        return;
      } catch (e) {
        debugPrint('[UspService] Token refresh failed: $e');
      }
      // Stage 2: full re-login via stored password
      final reauth = onReauthRequired;
      if (reauth != null) {
        await reauth();
        debugPrint('[UspService] Full re-login succeeded');
      }
      _reauthInProgress!.complete();
    } catch (e) {
      if (!_reauthInProgress!.isCompleted) {
        _reauthInProgress!.completeError(e);
      }
      rethrow;
    } finally {
      _reauthInProgress = null;
    }
  }

  /// Wraps an async operation with automatic 401 retry.
  Future<T> _withAuthRetry<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      if (!_isAuthError(e)) rethrow;
      debugPrint('[UspService] 401 detected, attempting reauth...');
      await reauth();
      return await action();
    }
  }

  // Legacy single getters if needed
  Future<String?> getSingle(String path) async {
    return _withAuthRetry(() => _client.get(path));
  }

  Future<void> setSingle(String path, String value) async {
    await _withAuthRetry(() => _client.set(path, value));
  }

  /// Fetches multiple USP paths in a single getMultiple call.
  ///
  /// Returns a coerced `Map<String, dynamic>` where booleans and nulls are
  /// properly typed (not left as raw strings).
  Future<Map<String, dynamic>> get(List<String> paths) async {
    final rawMap = await _withAuthRetry(() => _client.getMultiple(paths));

    // DEBUG: log raw response summary
    debugPrint('[UspService.get] requested ${paths.length} paths, '
        'got ${rawMap.length} keys back');
    if (rawMap.isNotEmpty) {
      final sampleKeys = rawMap.keys.take(5).toList();
      debugPrint('[UspService.get] sample response keys: $sampleKeys');
    } else {
      debugPrint('[UspService.get] response is EMPTY for paths: $paths');
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
        debugPrint(
            '[UspService.get] WARNING: missing path in response: "$path"');
      }
      result.putIfAbsent(path, () => null);
    }

    return result;
  }

  /// Coerce a raw string value from USP into the appropriate Dart type.
  /// - "true" / "false" → bool (any path)
  /// - "1" / "0" → bool (for known boolean suffixes: Enable, Active)
  /// - null → null (key absent from response)
  /// - Empty string → '' (preserve String type for generated code)
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

  Future<void> set(Map<String, dynamic> parameters,
      {bool allowPartial = false}) async {
    final Map<String, String> stringParams =
        parameters.map((key, value) => MapEntry(key, value.toString()));
    await _withAuthRetry(
        () => _client.setMultiple(stringParams, allowPartial: allowPartial));
  }

  // Legacy multiple getters
  Future<Map<String, String>> getMultiple(List<String> paths) async {
    return _withAuthRetry(() => _client.getMultiple(paths));
  }

  Future<void> setMultiple(Map<String, String> parameters,
      {bool allowPartial = false}) async {
    await _withAuthRetry(
        () => _client.setMultiple(parameters, allowPartial: allowPartial));
  }

  // ===========================================================================
  // Add Operation — create new object instances
  // ===========================================================================

  /// Creates a new object instance at the given path with initial parameters.
  ///
  /// [objectPath] must end with "." (e.g., "Device.NAT.PortMapping.").
  /// [parameters] are the initial parameter values for the new instance.
  /// Returns the full path of the created instance (e.g., "Device.NAT.PortMapping.3.").
  Future<String> add(String objectPath, Map<String, dynamic> parameters) async {
    final stringParams = parameters.map((k, v) => MapEntry(k, v.toString()));
    return _withAuthRetry(() => _client.add(objectPath, stringParams));
  }

  /// Creates multiple object instances in a single operation.
  ///
  /// Each element in [objects] should have:
  /// - `path` (String): object path ending with "."
  /// - `parameters` (Map<String, String>): initial parameter values
  ///
  /// Returns a list of created instance paths.
  Future<List<String>> addMultiple(List<Map<String, dynamic>> objects,
      {bool allowPartial = false}) async {
    return _withAuthRetry(
        () => _client.addMultiple(objects, allowPartial: allowPartial));
  }

  // ===========================================================================
  // Delete Operation — remove object instances
  // ===========================================================================

  /// Deletes the object instance at the given path.
  ///
  /// [path] must be a specific instance path (e.g., "Device.NAT.PortMapping.3.").
  Future<void> delete(String path) async {
    await _withAuthRetry(() => _client.delete(path));
  }

  /// Deletes multiple object instances in a single operation.
  Future<void> deleteMultiple(List<String> paths,
      {bool allowPartial = false}) async {
    await _withAuthRetry(
        () => _client.deleteMultiple(paths, allowPartial: allowPartial));
  }

  // ===========================================================================
  // Operate — execute USP commands
  // ===========================================================================

  /// Executes a USP Operate command on the agent.
  ///
  /// [command] is the command path (e.g., "Device.Reboot()" or
  /// "Device.IP.Diagnostics.Ping()").
  /// [args] are the input arguments for the command.
  /// Returns the output arguments from the operation, or an empty map.
  Future<Map<String, String>> operate(String command,
      {Map<String, String> args = const {}}) async {
    return _withAuthRetry(() => _client.operate(command, args: args));
  }

  // ===========================================================================
  // Subscribe — USP Notify-based subscriptions
  // ===========================================================================

  /// Creates a typed subscription that polls the given paths and delivers
  /// parsed model updates via a [Stream].
  ///
  /// In a full USP implementation this would use USP Subscribe / Notify
  /// messages (TR-369 §7.2). For this POC, we simulate it with periodic
  /// polling since the WASM client does not yet support WebSocket-based
  /// notifications.
  Future<Subscription<T>> subscribe<T>({
    required String id,
    required NotifType notifType,
    required List<String> paths,
    required T Function(Map<String, dynamic>) parser,
    Duration interval = const Duration(seconds: 5),
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
            debugPrint('[UspService.subscribe] Poll error for "$id": $e');
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

  void dispose() {
    _client.dispose();
  }
}
