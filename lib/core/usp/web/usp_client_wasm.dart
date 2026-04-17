@JS()
library usp_client;

import 'dart:js_interop';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// 將 dartify() 返回的 LinkedMap<Object?, Object?> 安全轉換為 Map<String, dynamic>
/// 用於處理 WASM v0.11.0 UnifiedResponse 格式的型別轉換問題
Map<String, dynamic> _safeConvertToStringDynamicMap(dynamic input) {
  if (input == null) return <String, dynamic>{};

  if (input is Map) {
    final result = <String, dynamic>{};
    for (final entry in input.entries) {
      final key = entry.key?.toString() ?? '';
      final value = entry.value;

      // 遞歸轉換嵌套 Map
      if (value is Map) {
        result[key] = _safeConvertToStringDynamicMap(value);
      } else if (value is List) {
        result[key] = value.map((item) =>
          item is Map ? _safeConvertToStringDynamicMap(item) : item
        ).toList();
      } else {
        result[key] = value;
      }
    }
    return result;
  }

  // 如果不是 Map，返回空 Map
  return <String, dynamic>{};
}

// Bind to the UspClient class exported in usp_client.js
@JS('UspClient')
extension type UspClientJS._(JSObject _) implements JSObject {
  external factory UspClientJS(String baseUrl);

  external JSPromise<JSAny?> get(String path);

  // Expects an array of paths, returns an object with path-value pairs
  external JSPromise<JSAny?> getMultiple(JSArray<JSString> paths);

  external bool isAuthenticated();

  @JS('getToken')
  external String? getToken();

  external JSPromise<JSAny?> subscribe(String subscriptionId);

  external JSPromise<JSAny?> unsubscribe(String subscriptionId);

  external JSPromise<JSAny?> login(String password);

  external JSPromise<JSAny?> logout();

  external JSPromise<JSAny?> refreshToken();

  external JSPromise<JSAny?> set(String path, String value);

  external JSPromise<JSAny?> setMultiple(JSAny parameters, bool allowPartial);

  // Add: create a new object instance
  external JSPromise<JSAny?> add(String objectPath, JSAny parameters);

  // Add: create multiple object instances
  external JSPromise<JSAny?> addMultiple(
      JSArray<JSAny> objects, bool allowPartial);

  // Delete: remove an object instance (JS name "delete")
  @JS('delete')
  external JSPromise<JSAny?> delete_(String path);

  // Delete: remove multiple object instances
  external JSPromise<JSAny?> deleteMultiple(
      JSArray<JSString> paths, bool allowPartial);

  // Operate: execute a USP command
  external JSPromise<JSAny?> operate(String command, JSAny args);

  // List all active OBUSPA subscriptions
  external JSPromise<JSAny?> listSubscriptions();

  external void free();
}

/// A Dart wrapper around the raw JS interop bindings, providing a standard Dart interface.
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

  Future<String?> get(String path) async {
    final result = await _client.get(path).toDart;

    // Log raw WASM response
    if (kDebugMode) {
      logger.d('[WASM]GET raw response: ${result?.toString() ?? 'null'}');
    }

    final dartified = result?.dartify();
    if (kDebugMode) {
      logger.d('[WASM]GET dartified: ${dartified?.toString() ?? 'null'}');
    }

    // Parse WASM v0.11.0 format: {success, result: {data, error?}}
    if (dartified is Map) {
      final success = dartified['success'] as bool? ?? false;
      if (success) {
        final resultData = dartified['result'] as Map? ?? {};
        final data = resultData['data'] as Map? ?? {};
        return data[path]?.toString();
      } else {
        if (kDebugMode) {
          final resultData = dartified['result'] as Map? ?? {};
          final error = resultData['error'] as Map? ?? {};
          logger.d('[WASM]GET failed for path: $path, errors: $error');
        }
        return null;
      }
    }

    return dartified?.toString();
  }

  Future<Map<String, String>> getMultiple(List<String> paths) async {
    final jsPaths = paths.map((p) => p.toJS).toList().toJS;

    JSAny? resultJs;
    try {
      resultJs = await _client.getMultiple(jsPaths).toDart;
    } catch (e) {
      // Enhanced error logging for JavaScript exceptions
      if (kDebugMode) {
        logger.e('[WASM]GET_MULTI JavaScript exception: $e');
        logger.e('[WASM]GET_MULTI Exception type: ${e.runtimeType}');
        logger.e('[WASM]GET_MULTI Requested paths: $paths');

        // Try to extract more information from the JS error
        try {
          final dynamic dynE = e;
          logger.e(
              '[WASM]GET_MULTI Dynamic error toString(): ${dynE.toString()}');

          // If this is a JSObject, try to access its properties using js_util
          if (e is JSObject) {
            logger.e(
                '[WASM]GET_MULTI This is a JSObject - attempting property access...');
            try {
              // Try accessing common JS error properties
              logger.e(
                  '[WASM]GET_MULTI JSObject toString: ${e.toString()}');
            } catch (propErr) {
              logger.e(
                  '[WASM]GET_MULTI JSObject property access failed: $propErr');
            }
          }
        } catch (inspectErr) {
          logger.e('[WASM]GET_MULTI Error inspection failed: $inspectErr');
        }
      }
      rethrow;
    }

    // Log raw WASM response
    if (kDebugMode) {
      logger
          .d('[WASM]GET_MULTI raw response: ${resultJs?.toString() ?? 'null'}');
    }

    final map = resultJs.dartify() as Map?;

    if (kDebugMode) {
      logger.d('[WASM]GET_MULTI dartified: ${jsonEncode(map)}');
    }

    if (map == null) return {};

    // Parse WASM v0.11.0 format: {success, result: {data, error?}}
    final success = map['success'] as bool? ?? false;
    final resultData = map['result'] as Map? ?? {};
    final data = resultData['data'] as Map? ?? {};

    if (kDebugMode) {
      logger
          .d('[WASM]GET_MULTI parsing WASM v0.11.0 format, success: $success');
    }

    final result = <String, String>{};
    for (final entry in data.entries) {
      final key = entry.key?.toString() ?? '';
      final value = entry.value;
      if (kDebugMode) {
        logger.d('[WASM]GET_MULTI data: $key = $value');
      }
      result[key] = value?.toString() ?? '';
    }

    return result;
  }

  /// TEMPORARY: Parse structured GET response format into flat key-value map
  /// TODO: Remove this once UspClient.get() is updated to use UspOperationResult

  /// Get multiple parameters and return WASM v0.11.0 structured result
  Future<Map<String, dynamic>> getMultipleStructured(List<String> paths) async {
    final jsPaths = paths.map((p) => p.toJS).toList().toJS;

    JSAny? resultJs;
    try {
      resultJs = await _client.getMultiple(jsPaths).toDart;
    } catch (e) {
      if (kDebugMode) {
        logger.e('[WASM]GET_STRUCTURED JavaScript exception: $e');
      }
      // Return transport error in v0.11.0 format
      return {
        'success': false,
        'result': {
          'data': <String, dynamic>{},
          'error': {
            'transport_error': {
              'errorCode': 9999,
              'errorMessage': 'Transport error: $e',
            }
          }
        }
      };
    }

    final map = _safeConvertToStringDynamicMap(resultJs?.dartify());

    if (kDebugMode) {
      logger.d('[WASM]GET_STRUCTURED response: ${jsonEncode(map)}');
    }

    if (map.isEmpty && resultJs != null) {
      return {
        'success': false,
        'result': {
          'data': <String, dynamic>{},
          'error': {
            'null_response': {
              'errorCode': 9998,
              'errorMessage': 'WASM client returned null response',
            }
          }
        }
      };
    }

    return map;
  }

  Future<void> set(String path, String value) async {
    if (kDebugMode) {
      logger.d('[WASM]SET single called: $path = $value');
    }
    try {
      final result = await _client.set(path, value).toDart;
      if (kDebugMode) {
        logger.d(
            '[WASM]SET single raw response: ${result?.toString() ?? 'null'}');
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d('[WASM]SET single exception: $e');
      }
      rethrow;
    }
  }

  /// Sets multiple parameters and returns WASM v0.11.0 structured result
  Future<Map<String, dynamic>> setMultiple(Map<String, String> parameters,
      {bool allowPartial = false}) async {
    if (kDebugMode) {
      logger.d(
          '[WASM]SET_MULTI called: ${parameters.length} params, allowPartial=$allowPartial');
      logger.d('[WASM]SET_MULTI params: ${parameters.toString()}');
    }

    final result =
        await _client.setMultiple(parameters.jsify()!, allowPartial).toDart;

    // Log raw WASM response
    if (kDebugMode) {
      logger.d('[WASM]SET_MULTI raw response: ${result?.toString() ?? 'null'}');
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

  /// Creates a new object instance at the given path with initial parameters.
  /// Returns structured operation result containing creation details.
  Future<Map<String, dynamic>> add(
      String objectPath, Map<String, String> parameters) async {
    if (kDebugMode) {
      logger
          .d('[WASM]ADD called: $objectPath with ${parameters.length} params');
      logger.d('[WASM]ADD params: ${parameters.toString()}');
    }

    final result = await _client.add(objectPath, parameters.jsify()!).toDart;

    // Log raw WASM response
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

  /// Creates multiple object instances.
  /// Each object should have `path` (String) and `parameters` (Map<String, String>).
  /// Returns structured operation result containing creation details.
  Future<Map<String, dynamic>> addMultiple(List<Map<String, dynamic>> objects,
      {bool allowPartial = false}) async {
    if (kDebugMode) {
      logger.d(
          '[WASM]ADD_MULTI called: ${objects.length} objects, allowPartial=$allowPartial');
      for (var i = 0; i < objects.length; i++) {
        logger.d('[WASM]ADD_MULTI[$i]: ${objects[i]}');
      }
    }

    final jsObjects = objects.map((obj) => obj.jsify()!).toList().toJS;
    final result = await _client.addMultiple(jsObjects, allowPartial).toDart;

    // Log raw WASM response
    if (kDebugMode) {
      logger.d('[WASM]ADD_MULTI raw response: ${result?.toString() ?? 'null'}');
    }

    if (result == null || result.isUndefinedOrNull) {
      throw StateError(
          'WASM client returned null/undefined - structured response required');
    }

    final dartResult = _safeConvertToStringDynamicMap(result.dartify());

    if (kDebugMode) {
      logger.d('[WASM]ADD_MULTI dartified: ${jsonEncode(dartResult)}');
    }

    return dartResult;
  }

  /// Deletes an object instance at the given path.
  /// Returns structured operation result containing deletion details.
  Future<Map<String, dynamic>> delete(String path) async {
    if (kDebugMode) {
      logger.d('[WASM]DELETE called: $path');
    }

    try {
      final result = await _client.delete_(path).toDart;

      // Log raw WASM response
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
      // Convert exception to structured error result
      return {
        'overallSuccess': false,
        'hasAnySuccess': false,
        'hasErrors': true,
        'results': [
          {
            'requestedPath': path,
            'success': false,
            'errorCode': -1,
            'errorMessage': e.toString(),
          }
        ],
      };
    }
  }

  /// Deletes multiple object instances.
  /// Returns structured operation result containing deletion details.
  Future<Map<String, dynamic>> deleteMultiple(List<String> paths,
      {bool allowPartial = false}) async {
    if (kDebugMode) {
      logger.d(
          '[WASM]DELETE_MULTI called: ${paths.length} paths, allowPartial=$allowPartial');
      for (var i = 0; i < paths.length; i++) {
        logger.d('[WASM]DELETE_MULTI[$i]: ${paths[i]}');
      }
    }

    try {
      final jsPaths = paths.map((p) => p.toJS).toList().toJS;
      final result = await _client.deleteMultiple(jsPaths, allowPartial).toDart;

      // Log raw WASM response
      if (kDebugMode) {
        logger.d(
            '[WASM]DELETE_MULTI raw response: ${result?.toString() ?? 'null'}');
      }

      if (result == null || result.isUndefinedOrNull) {
        throw StateError(
            'WASM client returned null/undefined - structured response required');
      }

      final map = _safeConvertToStringDynamicMap(result.dartify());

      if (kDebugMode) {
        logger.d('[WASM]DELETE_MULTI dartified: ${jsonEncode(map)}');
      }

      return map;
    } catch (e) {
      if (kDebugMode) {
        logger.d('[WASM]DELETE_MULTI exception: $e');
      }
      // Convert exception to structured error result
      return {
        'overallSuccess': false,
        'hasAnySuccess': false,
        'hasErrors': true,
        'results': paths
            .map((path) => {
                  'requestedPath': path,
                  'success': false,
                  'errorCode': -1,
                  'errorMessage': e.toString(),
                })
            .toList(),
      };
    }
  }

  /// Executes a USP Operate command.
  ///
  /// Returns a flat map containing:
  ///   - `commandKey`: UUID correlator from the USP agent (may be absent)
  ///   - all output arguments from the Operate response
  Future<Map<String, dynamic>> operate(String command,
      {Map<String, String> args = const {}}) async {
    final result = await _client.operate(command, args.jsify()!).toDart;

    // Log raw WASM response
    if (kDebugMode) {
      logger.d('[WASM]OPERATE raw response: ${result?.toString() ?? 'null'}');
    }

    if (result == null || result.isUndefinedOrNull) return {};

    final map = result.dartify() as Map?;

    if (kDebugMode) {
      logger.d('[WASM]OPERATE dartified: ${jsonEncode(map)}');
    }

    if (map == null) return {};

    final output = <String, dynamic>{};
    final commandKey = map['commandKey']?.toString();
    if (commandKey != null && commandKey.isNotEmpty) {
      output['commandKey'] = commandKey;
    }
    final rawOutputArgs = map['outputArgs'];
    if (rawOutputArgs is Map) {
      for (final entry in rawOutputArgs.entries) {
        output[entry.key.toString()] = entry.value.toString();
      }
    }
    return output;
  }

  /// Lists all active OBUSPA subscriptions on the router.
  /// Returns a list of subscription objects (maps with subscription details).
  Future<List<Map<String, dynamic>>> listSubscriptions() async {
    final result = await _client.listSubscriptions().toDart;

    // Log raw WASM response
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
