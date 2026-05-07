@JS()
library usp_client;

import 'dart:js_interop';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// Safely converts dartify() LinkedMap<Object?, Object?> to Map<String, dynamic>.
Map<String, dynamic> _safeConvertToStringDynamicMap(dynamic input) {
  if (input == null) return <String, dynamic>{};

  if (input is Map) {
    final result = <String, dynamic>{};
    for (final entry in input.entries) {
      final key = entry.key?.toString() ?? '';
      final value = entry.value;

      if (value is Map) {
        result[key] = _safeConvertToStringDynamicMap(value);
      } else if (value is List) {
        result[key] = value
            .map((item) =>
                item is Map ? _safeConvertToStringDynamicMap(item) : item)
            .toList();
      } else {
        result[key] = value;
      }
    }
    return result;
  }

  return <String, dynamic>{};
}

/// Builds a JS options object with {allowPartial: bool}.
/// Returns null if allowPartial is false (default), so JS sees undefined.
JSAny? _buildOptions({bool allowPartial = false}) {
  if (!allowPartial) return null;
  return {'allowPartial': allowPartial}.jsify();
}

// Bind to the UspClient class exported in usp_client.js (unified API)
@JS('UspClient')
extension type UspClientJS._(JSObject _) implements JSObject {
  external factory UspClientJS(String baseUrl);

  // Unified get: accepts string or array of paths
  external JSPromise<JSAny?> get(JSAny paths);

  external bool isAuthenticated();

  @JS('getToken')
  external String? getToken();

  external JSPromise<JSAny?> subscribe(String subscriptionId);

  external JSPromise<JSAny?> unsubscribe(String subscriptionId);

  external JSPromise<JSAny?> login(String password);

  external JSPromise<JSAny?> logout();

  external JSPromise<JSAny?> refreshToken();

  // Unified set: accepts parameters object {path: value, ...} + optional options
  @JS('set')
  external JSPromise<JSAny?> set_(JSAny parameters, JSAny? options);

  // Unified add: accepts single {path, params} or array + optional options
  external JSPromise<JSAny?> add(JSAny items, JSAny? options);

  // Unified delete: accepts string or array + optional options
  @JS('delete')
  external JSPromise<JSAny?> delete_(JSAny paths, JSAny? options);

  // Ordered set: array of groups [[{path, value}, ...], ...] processed in sequence
  external JSPromise<JSAny?> setOrdered(JSAny groupsArray, bool allowPartial);

  // Operate: execute a USP command
  external JSPromise<JSAny?> operate(String command, JSAny args);

  // List all active OBUSPA subscriptions
  external JSPromise<JSAny?> listSubscriptions();

  external void free();
}

/// Dart wrapper around JS interop bindings — unified API matching JS WASM client.
class UspClientWeb {
  late final UspClientJS _client;

  UspClientWeb(String baseUrl) {
    if (kDebugMode) {
      logger.d('[WASM]Creating UspClientJS with baseUrl: $baseUrl');
    }
    try {
      _client = UspClientJS(baseUrl);
      if (kDebugMode) {
        logger.d('[WASM]UspClientJS created successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d('[WASM]Failed to create UspClientJS: $e');
      }
      rethrow;
    }
  }

  bool get isAuthenticated {
    try {
      final result = _client.isAuthenticated();
      if (kDebugMode) {
        logger.d('[WASM]isAuthenticated(): $result');
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        logger.d('[WASM]isAuthenticated() exception: $e');
      }
      return false;
    }
  }

  String? get sessionToken {
    try {
      final result = _client.getToken();
      if (kDebugMode) {
        logger.d(
            '[WASM]getToken(): ${result?.substring(0, 20)}...(${result?.length} chars)');
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        logger.d('[WASM]getToken() exception: $e');
      }
      return null;
    }
  }

  Future<void> subscribe(String subscriptionId) async {
    await _client.subscribe(subscriptionId).toDart;
  }

  Future<void> unsubscribe(String subscriptionId) async {
    await _client.unsubscribe(subscriptionId).toDart;
  }

  Future<void> login(String password) async {
    try {
      if (kDebugMode) {
        logger
            .d('[WASM]login() called with password length: ${password.length}');
      }
      final result = await _client.login(password).toDart;
      if (kDebugMode) {
        logger.d('[WASM]login() raw response: ${result?.toString() ?? 'null'}');
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d('[WASM]login() exception: $e');
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    await _client.logout().toDart;
  }

  Future<void> refreshToken() async {
    await _client.refreshToken().toDart;
  }

  // ---------------------------------------------------------------------------
  // GET — unified, always List<String>
  // ---------------------------------------------------------------------------

  Future<Map<String, String>> get(List<String> paths) async {
    final jsPaths = paths.map((p) => p.toJS).toList().toJS;

    JSAny? resultJs;
    try {
      resultJs = await _client.get(jsPaths).toDart;
    } catch (e) {
      if (kDebugMode) {
        logger.e('[WASM]GET JavaScript exception: $e');
        logger.e('[WASM]GET Exception type: ${e.runtimeType}');
        logger.e('[WASM]GET Requested paths: $paths');
      }
      rethrow;
    }

    if (kDebugMode) {
      logger.d('[WASM]GET raw response: ${resultJs?.toString() ?? 'null'}');
    }

    final map = resultJs.dartify() as Map?;

    if (kDebugMode) {
      logger.d('[WASM]GET dartified: ${jsonEncode(map)}');
    }

    if (map == null) return {};

    // Parse unified format: {success, result: {data, error?}}
    final success = map['success'] as bool? ?? false;
    final resultData = map['result'] as Map? ?? {};
    final data = resultData['data'] as Map? ?? {};

    if (kDebugMode) {
      logger.d('[WASM]GET parsing unified format, success: $success');
    }

    final result = <String, String>{};
    for (final entry in data.entries) {
      final key = entry.key?.toString() ?? '';
      final value = entry.value;
      if (kDebugMode) {
        logger.d('[WASM]GET data: $key = $value');
      }
      result[key] = value?.toString() ?? '';
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // SET — unified, always Map<String, String>
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> set(Map<String, String> parameters,
      {bool allowPartial = false}) async {
    if (kDebugMode) {
      logger.d(
          '[WASM]SET called: ${parameters.length} params, allowPartial=$allowPartial');
      logger.d('[WASM]SET params: ${parameters.toString()}');
    }

    final result = await _client
        .set_(parameters.jsify()!, _buildOptions(allowPartial: allowPartial))
        .toDart;

    if (kDebugMode) {
      logger.d('[WASM]SET raw response: ${result?.toString() ?? 'null'}');
    }

    if (result == null || result.isUndefinedOrNull) {
      throw StateError(
          'WASM client returned null/undefined - structured response required');
    }

    final map = _safeConvertToStringDynamicMap(result.dartify());
    if (kDebugMode) {
      logger.d('[WASM]SET dartified: ${jsonEncode(map)}');
    }

    return map;
  }

  // ---------------------------------------------------------------------------
  // SET ORDERED — groups of [{path, value}, ...] processed in sequence
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> setOrdered(
      List<List<Map<String, String>>> parameterGroups,
      {bool allowPartial = false}) async {
    if (kDebugMode) {
      logger.d(
          '[WASM]SET_ORDERED called: ${parameterGroups.length} groups, allowPartial=$allowPartial');
      for (var g = 0; g < parameterGroups.length; g++) {
        for (var i = 0; i < parameterGroups[g].length; i++) {
          logger.d('[WASM]SET_ORDERED[group$g][$i]: ${parameterGroups[g][i]}');
        }
      }
    }

    final jsGroups = parameterGroups
        .map((group) => group
            .map((p) => {'path': p['path'], 'value': p['value']}.jsify()!)
            .toList()
            .toJS)
        .toList()
        .toJS;

    final result = await _client.setOrdered(jsGroups, allowPartial).toDart;

    if (kDebugMode) {
      logger
          .d('[WASM]SET_ORDERED raw response: ${result?.toString() ?? 'null'}');
    }

    if (result == null || result.isUndefinedOrNull) {
      throw StateError(
          'WASM client returned null/undefined - structured response required');
    }

    final map = _safeConvertToStringDynamicMap(result.dartify());
    if (kDebugMode) {
      logger.d('[WASM]SET_ORDERED dartified: ${jsonEncode(map)}');
    }

    return map;
  }

  // ---------------------------------------------------------------------------
  // ADD — unified, always List<Map>
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> add(List<Map<String, dynamic>> items,
      {bool allowPartial = false}) async {
    if (kDebugMode) {
      logger.d(
          '[WASM]ADD called: ${items.length} items, allowPartial=$allowPartial');
      for (var i = 0; i < items.length; i++) {
        logger.d('[WASM]ADD[$i]: ${items[i]}');
      }
    }

    // Stringify all param values — Rust WASM expects JS strings, not
    // Number/Boolean.  Dart's jsify() preserves int→Number / bool→Boolean,
    // which Rust's JsValue::as_string() returns None for, falling back to
    // Debug format "JsValue(90)" and corrupting the data on the router.
    final stringified = items.map((item) {
      final params = item['params'];
      if (params is Map) {
        return {
          ...item,
          'params': params.map((k, v) => MapEntry(k, v?.toString() ?? '')),
        };
      }
      return item;
    }).toList();

    // Single item → pass as object; multiple → pass as array
    final JSAny jsItems;
    if (stringified.length == 1) {
      jsItems = stringified.first.jsify()!;
    } else {
      jsItems = stringified.jsify()!;
    }

    final result = await _client
        .add(jsItems, _buildOptions(allowPartial: allowPartial))
        .toDart;

    if (kDebugMode) {
      logger.d('[WASM]ADD raw response: ${result?.toString() ?? 'null'}');
    }

    if (result == null || result.isUndefinedOrNull) {
      throw StateError(
          'WASM client returned null/undefined - structured response required');
    }

    final map = _safeConvertToStringDynamicMap(result.dartify());

    if (kDebugMode) {
      logger.d('[WASM]ADD dartified: ${jsonEncode(map)}');
    }

    return map;
  }

  // ---------------------------------------------------------------------------
  // DELETE — unified, always List<String>
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> delete(List<String> paths,
      {bool allowPartial = false}) async {
    if (kDebugMode) {
      logger.d(
          '[WASM]DELETE called: ${paths.length} paths, allowPartial=$allowPartial');
      for (var i = 0; i < paths.length; i++) {
        logger.d('[WASM]DELETE[$i]: ${paths[i]}');
      }
    }

    try {
      // Single path → pass as string; multiple → pass as array
      final JSAny jsPaths;
      if (paths.length == 1) {
        jsPaths = paths.first.toJS;
      } else {
        jsPaths = paths.map((p) => p.toJS).toList().toJS;
      }

      final result = await _client
          .delete_(jsPaths, _buildOptions(allowPartial: allowPartial))
          .toDart;

      if (kDebugMode) {
        logger.d('[WASM]DELETE raw response: ${result?.toString() ?? 'null'}');
      }

      if (result == null || result.isUndefinedOrNull) {
        throw StateError(
            'WASM client returned null/undefined - structured response required');
      }

      final map = _safeConvertToStringDynamicMap(result.dartify());

      if (kDebugMode) {
        logger.d('[WASM]DELETE dartified: ${jsonEncode(map)}');
      }

      return map;
    } catch (e) {
      if (kDebugMode) {
        logger.d('[WASM]DELETE exception: $e');
      }
      // Return WASM v0.11.0 unified format for consistency with UspResultParser
      return {
        'success': false,
        'result': {
          'data': <String, dynamic>{},
          'error': {
            for (final path in paths)
              path: {
                'errorCode': -1,
                'errorMessage': e.toString(),
              },
          },
        },
      };
    }
  }

  // ---------------------------------------------------------------------------
  // OPERATE
  // ---------------------------------------------------------------------------

  /// Execute a USP Operate command.
  ///
  /// Returns the WASM v0.11.0 unified format:
  /// ```dart
  /// {
  ///   'success': true,
  ///   'result': {
  ///     'data': {
  ///       'commandKey': 'uuid-string',
  ///       'outputArgs': { ... }
  ///     },
  ///     'error': { ... }  // optional
  ///   }
  /// }
  /// ```
  ///
  /// Use `UspResultParser.parseOperateResult()` to extract commandKey/outputArgs.
  Future<Map<String, dynamic>> operate(String command,
      {Map<String, String> args = const {}}) async {
    final result = await _client.operate(command, args.jsify()!).toDart;

    if (kDebugMode) {
      logger.d('[WASM]OPERATE raw response: ${result?.toString() ?? 'null'}');
    }

    if (result == null || result.isUndefinedOrNull) {
      return {
        'success': false,
        'result': {'data': <String, dynamic>{}}
      };
    }

    final map = result.dartify() as Map?;

    if (kDebugMode) {
      logger.d('[WASM]OPERATE dartified: ${jsonEncode(map)}');
    }

    if (map == null) {
      return {
        'success': false,
        'result': {'data': <String, dynamic>{}}
      };
    }

    // Pass through the unified format for UspResultParser
    return Map<String, dynamic>.from(map);
  }

  // ---------------------------------------------------------------------------
  // SUBSCRIPTIONS
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> listSubscriptions() async {
    final result = await _client.listSubscriptions().toDart;

    if (kDebugMode) {
      logger.d('[WASM]LIST_SUBS raw response: ${result?.toString() ?? 'null'}');
    }

    if (result == null || result.isUndefinedOrNull) return [];

    final list = result.dartify() as List?;

    if (kDebugMode) {
      logger.d('[WASM]LIST_SUBS dartified: ${jsonEncode(list)}');
    }

    if (list == null) return [];
    return list
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .toList()
        .cast<Map<String, dynamic>>();
  }

  void dispose() {
    _client.free();
  }
}
