@JS()
library usp_client;

import 'dart:js_interop';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:privacy_gui/core/utils/logger.dart';

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

    // Check if this is structured response format
    if (dartified is Map && dartified.containsKey('overallSuccess')) {
      if (kDebugMode) {
        logger.d('[WASM]GET parsing structured response format');
      }
      final parsedMap = _parseStructuredGetResponse(dartified);
      return parsedMap[path];
    }

    return dartified?.toString();
  }

  Future<Map<String, String>> getMultiple(List<String> paths) async {
    final jsPaths = paths.map((p) => p.toJS).toList().toJS;
    final resultJs = await _client.getMultiple(jsPaths).toDart;

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

    // TODO: This is a TEMPORARY compatibility fix for structured GET responses
    // The proper solution is to modify UspClient.get() to return UspOperationResult
    // and update all calling code to use structured responses
    if (map.containsKey('overallSuccess') && map.containsKey('results')) {
      if (kDebugMode) {
        logger
            .d('[WASM]GET_MULTI parsing structured response format (TEMP FIX)');
      }
      return _parseStructuredGetResponse(map);
    }

    // Legacy flat format
    final result = <String, String>{};
    for (final entry in map.entries) {
      final key = entry.key?.toString() ?? '';
      final value = entry.value;
      if (value == null) {
        if (kDebugMode) {
          logger.d('[WASM]GET_MULTI null value for key: $key');
        }
        result[key] = '';
      } else {
        result[key] = value.toString();
      }
    }
    return result;
  }

  /// TEMPORARY: Parse structured GET response format into flat key-value map
  /// TODO: Remove this once UspClient.get() is updated to use UspOperationResult
  Map<String, String> _parseStructuredGetResponse(Map map) {
    final result = <String, String>{};
    final results = map['results'] as List? ?? [];

    for (final resultItem in results) {
      final resultMap = resultItem as Map? ?? {};
      final requestedPath = resultMap['requestedPath'] as String? ?? '';
      final success = resultMap['success'] as bool? ?? false;

      if (success) {
        final retrievedParams = resultMap['retrievedParams'] as List? ?? [];

        if (requestedPath.contains('*')) {
          // Wildcard path - need to reconstruct instance paths
          // For now, we'll create sequential instance numbers
          for (var i = 0; i < retrievedParams.length; i++) {
            final param = retrievedParams[i];
            final paramMap = param as Map? ?? {};
            final paramValue = paramMap['value'] as String? ?? '';

            // Replace * with instance number (starting from 1)
            final fullPath = requestedPath.replaceAll('*', '${i + 1}');

            if (kDebugMode) {
              logger.d(
                  '[WASM]GET_MULTI structured wildcard: $fullPath = $paramValue');
            }

            result[fullPath] = paramValue;
          }
        } else {
          // Single parameter path
          if (retrievedParams.isNotEmpty) {
            final param = retrievedParams.first;
            final paramMap = param as Map? ?? {};
            final paramValue = paramMap['value'] as String? ?? '';

            if (kDebugMode) {
              logger.d(
                  '[WASM]GET_MULTI structured single: $requestedPath = $paramValue');
            }

            result[requestedPath] = paramValue;
          }
        }
      } else {
        // Failed request - add empty value to maintain consistency
        if (kDebugMode) {
          logger.d('[WASM]GET_MULTI structured failed: $requestedPath');
        }
        result[requestedPath] = '';
      }
    }

    return result;
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

  /// Sets multiple parameters and returns structured operation result.
  ///
  /// Returns a Map containing:
  /// - 'overallSuccess': bool - true if all operations succeeded
  /// - 'hasAnySuccess': bool - true if at least one operation succeeded
  /// - 'hasErrors': bool - true if at least one operation failed
  /// - 'results': List<Map> - detailed results per parameter
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

    final map = result.dartify() as Map?;
    if (kDebugMode) {
      logger.d('[WASM]SET dartified: ${jsonEncode(map)}');
    }

    if (map == null) {
      throw StateError('Invalid setMultiple response format');
    }

    return Map<String, dynamic>.from(map);
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

    final map = result.dartify();

    if (kDebugMode) {
      logger.d('[WASM]ADD dartified: ${jsonEncode(map)}');
    }

    if (map is Map) {
      return Map<String, dynamic>.from(map);
    }

    throw StateError('Invalid add response format: ${map.runtimeType}');
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

    final dartResult = result.dartify();

    if (kDebugMode) {
      logger.d('[WASM]ADD_MULTI dartified: ${jsonEncode(dartResult)}');
    }

    if (dartResult is Map) {
      return Map<String, dynamic>.from(dartResult);
    }

    throw StateError(
        'Invalid addMultiple response format: ${dartResult.runtimeType}');
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

      final map = result.dartify();

      if (kDebugMode) {
        logger.d('[WASM]DELETE dartified: ${jsonEncode(map)}');
      }

      if (map is Map) {
        return Map<String, dynamic>.from(map);
      }

      throw StateError('Invalid delete response format: ${map.runtimeType}');
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

      final map = result.dartify();

      if (kDebugMode) {
        logger.d('[WASM]DELETE_MULTI dartified: ${jsonEncode(map)}');
      }

      if (map is Map) {
        return Map<String, dynamic>.from(map);
      }

      throw StateError(
          'Invalid deleteMultiple response format: ${map.runtimeType}');
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
