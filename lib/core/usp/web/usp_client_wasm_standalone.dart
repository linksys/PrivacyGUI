@JS()
library usp_client;

import 'dart:js_interop';
import 'dart:convert';
import 'package:flutter/foundation.dart';

// Bind to the UspClient class exported in usp_client.js
@JS('UspClient')
extension type UspClientJS._(JSObject _) implements JSObject {
  external factory UspClientJS(String baseUrl);

  external JSPromise<JSAny?> get(String path);
  external JSPromise<JSAny?> getMultiple(JSArray<JSString> paths);
  external bool isAuthenticated();
  external String? getToken();
  external JSPromise<JSAny?> login(String password);
  external JSPromise<JSAny?> logout();
  external JSPromise<JSAny?> refreshToken();
  external JSPromise<JSAny?> set(String path, String value);
  external JSPromise<JSAny?> setMultiple(JSAny parameters, bool allowPartial);
  external JSPromise<JSAny?> add(String objectPath, JSAny parameters);
  external JSPromise<JSAny?> addMultiple(
      JSArray<JSAny> objects, bool allowPartial);
  external JSPromise<JSAny?> delete(String path);
  external JSPromise<JSAny?> deleteMultiple(
      JSArray<JSString> paths, bool allowPartial);
  external JSPromise<JSAny?> operate(String command, JSAny args);
  external JSPromise<JSAny?> listSubscriptions();
  external JSPromise<JSAny?> subscribe(
      String subscriptionId, String path, int notificationType);
  external JSPromise<JSAny?> unsubscribe(String subscriptionId);
  external void dispose();
}

/// Standalone USP Client for Web (WASM) without project-specific dependencies
class UspClientWeb {
  late final UspClientJS _client;

  UspClientWeb(String baseUrl) {
    if (kDebugMode) {
      print('[WASM]Creating UspClientJS with baseUrl: $baseUrl');
    }
    _client = UspClientJS(baseUrl);
  }

  bool get isAuthenticated => _client.isAuthenticated();

  String? get sessionToken {
    try {
      final result = _client.getToken();
      if (kDebugMode) {
        print(
            '[WASM]getToken(): ${result?.substring(0, 20)}...(${result?.length} chars)');
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('[WASM]getToken() exception: $e');
      }
      return null;
    }
  }

  Future<void> subscribe(String subscriptionId) async {
    await _client.subscribe(subscriptionId, '', 1).toDart;
  }

  Future<void> unsubscribe(String subscriptionId) async {
    await _client.unsubscribe(subscriptionId).toDart;
  }

  Future<void> login(String password) async {
    try {
      if (kDebugMode) {
        print('[WASM]login() called with password length: ${password.length}');
      }
      final result = await _client.login(password).toDart;
      if (kDebugMode) {
        print('[WASM]login() raw response: ${result?.toString() ?? 'null'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[WASM]login() exception: $e');
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

    if (kDebugMode) {
      print('[WASM]GET raw response: ${result?.toString() ?? 'null'}');
    }

    final dartified = result?.dartify();
    if (kDebugMode) {
      print('[WASM]GET dartified: ${dartified?.toString() ?? 'null'}');
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
          print('[WASM]GET failed for path: $path, errors: $error');
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
      if (kDebugMode) {
        print('[WASM]GET_MULTI JavaScript exception: $e');
      }
      rethrow;
    }

    if (kDebugMode) {
      print('[WASM]GET_MULTI raw response: ${resultJs?.toString() ?? 'null'}');
    }

    final map = resultJs.dartify() as Map?;
    if (kDebugMode) {
      print('[WASM]GET_MULTI dartified: ${jsonEncode(map)}');
    }

    if (map == null) return {};

    // Parse WASM v0.11.0 format: {success, result: {data, error?}}
    final success = map['success'] as bool? ?? false;
    final resultData = map['result'] as Map? ?? {};
    final data = resultData['data'] as Map? ?? {};

    if (kDebugMode) {
      print('[WASM]GET_MULTI parsing WASM v0.11.0 format, success: $success');
    }

    final result = <String, String>{};
    for (final entry in data.entries) {
      final key = entry.key?.toString() ?? '';
      final value = entry.value;
      if (kDebugMode) {
        print('[WASM]GET_MULTI data: $key = $value');
      }
      result[key] = value?.toString() ?? '';
    }

    return result;
  }

  /// Get multiple parameters and return WASM v0.11.0 structured result
  Future<Map<String, dynamic>> getMultipleStructured(List<String> paths) async {
    final jsPaths = paths.map((p) => p.toJS).toList().toJS;

    JSAny? resultJs;
    try {
      resultJs = await _client.getMultiple(jsPaths).toDart;
    } catch (e) {
      if (kDebugMode) {
        print('[WASM]GET_STRUCTURED JavaScript exception: $e');
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

    final map = resultJs?.dartify() as Map?;
    if (kDebugMode) {
      print('[WASM]GET_STRUCTURED response: ${jsonEncode(map)}');
    }

    if (map == null) {
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

    return Map<String, dynamic>.from(map);
  }

  Future<void> set(String path, String value) async {
    if (kDebugMode) {
      print('[WASM]SET single called: $path = $value');
    }
    try {
      final result = await _client.set(path, value).toDart;
      if (kDebugMode) {
        print('[WASM]SET single raw response: ${result?.toString() ?? 'null'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[WASM]SET single exception: $e');
      }
      rethrow;
    }
  }

  /// Sets multiple parameters and returns WASM v0.11.0 structured result
  Future<Map<String, dynamic>> setMultiple(Map<String, String> parameters,
      {bool allowPartial = false}) async {
    if (kDebugMode) {
      print(
          '[WASM]SET_MULTI called: ${parameters.length} params, allowPartial=$allowPartial');
      print('[WASM]SET_MULTI params: ${parameters.toString()}');
    }

    final result =
        await _client.setMultiple(parameters.jsify()!, allowPartial).toDart;

    if (kDebugMode) {
      print('[WASM]SET_MULTI raw response: ${result?.toString() ?? 'null'}');
    }

    if (result == null || result.isUndefinedOrNull) {
      throw StateError(
          'WASM client returned null/undefined - structured response required');
    }

    final map = result.dartify() as Map?;
    if (kDebugMode) {
      print('[WASM]SET dartified: ${jsonEncode(map)}');
    }

    if (map == null) {
      throw StateError('Invalid setMultiple response format');
    }

    return Map<String, dynamic>.from(map);
  }

  void dispose() {
    _client.dispose();
  }
}
