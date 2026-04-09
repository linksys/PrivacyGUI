@JS()
library usp_client;

import 'dart:js_interop';

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
    _client = UspClientJS(baseUrl);
  }

  bool get isAuthenticated => _client.isAuthenticated();

  String? get sessionToken => _client.getToken();

  Future<void> subscribe(String subscriptionId) async {
    await _client.subscribe(subscriptionId).toDart;
  }

  Future<void> unsubscribe(String subscriptionId) async {
    await _client.unsubscribe(subscriptionId).toDart;
  }

  Future<void> login(String password) async {
    await _client.login(password).toDart;
  }

  Future<void> logout() async {
    await _client.logout().toDart;
  }

  Future<void> refreshToken() async {
    await _client.refreshToken().toDart;
  }

  Future<String?> get(String path) async {
    final result = await _client.get(path).toDart;
    return result?.dartify()?.toString();
  }

  Future<Map<String, String>> getMultiple(List<String> paths) async {
    final jsPaths = paths.map((p) => p.toJS).toList().toJS;
    final resultJs = await _client.getMultiple(jsPaths).toDart;
    final map = resultJs.dartify() as Map?;
    if (map == null) return {};

    final result = <String, String>{};
    for (final entry in map.entries) {
      final key = entry.key?.toString() ?? '';
      final value = entry.value;
      if (value == null) {
        // ignore: avoid_print
        print('[WASM] null value for key: $key');
        result[key] = '';
      } else {
        result[key] = value.toString();
      }
    }
    return result;
  }

  Future<void> set(String path, String value) async {
    await _client.set(path, value).toDart;
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
    final result = await _client.setMultiple(parameters.jsify()!, allowPartial).toDart;

    if (result == null || result.isUndefinedOrNull) {
      // Fallback: assume success if no structured response (old WASM version)
      return {
        'overallSuccess': true,
        'hasAnySuccess': true,
        'hasErrors': false,
        'results': parameters.keys.map((path) => {
          'requestedPath': path,
          'success': true,
          'updatedInstances': [{
            'affectedPath': _extractInstancePath(path),
            'updatedParams': {_extractParameterName(path): parameters[path]!}
          }]
        }).toList(),
      };
    }

    final map = result.dartify() as Map?;
    if (map == null) {
      throw StateError('Invalid setMultiple response format');
    }

    return Map<String, dynamic>.from(map);
  }

  /// Extracts instance path from full parameter path
  /// e.g., "Device.WiFi.SSID.1.SSID" -> "Device.WiFi.SSID.1."
  String _extractInstancePath(String fullPath) {
    final segments = fullPath.split('.');
    if (segments.length < 2) return fullPath;
    return '${segments.sublist(0, segments.length - 1).join('.')}.';
  }

  /// Extracts parameter name from full path
  /// e.g., "Device.WiFi.SSID.1.SSID" -> "SSID"
  String _extractParameterName(String fullPath) {
    return fullPath.split('.').last;
  }

  /// Creates a new object instance at the given path with initial parameters.
  /// Returns structured operation result containing creation details.
  Future<Map<String, dynamic>> add(String objectPath, Map<String, String> parameters) async {
    final result = await _client.add(objectPath, parameters.jsify()!).toDart;

    if (result == null || result.isUndefinedOrNull) {
      // Fallback: create a failure result
      return {
        'overallSuccess': false,
        'hasAnySuccess': false,
        'hasErrors': true,
        'results': [{
          'requestedPath': objectPath,
          'success': false,
          'errorCode': -1,
          'errorMessage': 'Add operation returned null or undefined'
        }],
      };
    }

    final map = result.dartify();

    // Handle legacy response format (simple string path)
    if (map is String) {
      if (map.isNotEmpty) {
        return {
          'overallSuccess': true,
          'hasAnySuccess': true,
          'hasErrors': false,
          'results': [{
            'requestedPath': objectPath,
            'success': true,
            'createdInstances': [{
              'affectedPath': map,
              'initialParams': parameters,
            }]
          }],
        };
      } else {
        return {
          'overallSuccess': false,
          'hasAnySuccess': false,
          'hasErrors': true,
          'results': [{
            'requestedPath': objectPath,
            'success': false,
            'errorCode': -1,
            'errorMessage': 'Add operation returned empty path'
          }],
        };
      }
    }

    // Handle structured response format
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
    final jsObjects = objects.map((obj) => obj.jsify()!).toList().toJS;
    final result = await _client.addMultiple(jsObjects, allowPartial).toDart;

    if (result == null || result.isUndefinedOrNull) {
      // Fallback: create failure result
      return {
        'overallSuccess': false,
        'hasAnySuccess': false,
        'hasErrors': true,
        'results': objects.map((obj) => {
          'requestedPath': obj['path'] as String? ?? 'unknown',
          'success': false,
          'errorCode': -1,
          'errorMessage': 'AddMultiple operation returned null or undefined'
        }).toList(),
      };
    }

    final dartResult = result.dartify();

    // Handle legacy response format (List<String> of created paths)
    if (dartResult is List) {
      final pathList = dartResult.map((e) => e.toString()).toList();
      if (pathList.length == objects.length) {
        // All objects created successfully
        final results = <Map<String, dynamic>>[];
        for (var i = 0; i < objects.length; i++) {
          final obj = objects[i];
          final createdPath = pathList[i];
          results.add({
            'requestedPath': obj['path'] as String? ?? 'unknown',
            'success': createdPath.isNotEmpty,
            if (createdPath.isNotEmpty) 'createdInstances': [{
              'affectedPath': createdPath,
              'initialParams': obj['parameters'] as Map<String, String>? ?? <String, String>{},
            }],
            if (createdPath.isEmpty) ...{
              'errorCode': -1,
              'errorMessage': 'Empty path returned for object creation'
            },
          });
        }

        final successCount = results.where((r) => r['success'] == true).length;
        return {
          'overallSuccess': successCount == objects.length,
          'hasAnySuccess': successCount > 0,
          'hasErrors': successCount < objects.length,
          'results': results,
        };
      }
    }

    // Handle structured response format
    if (dartResult is Map) {
      return Map<String, dynamic>.from(dartResult);
    }

    throw StateError('Invalid addMultiple response format: ${dartResult.runtimeType}');
  }

  /// Deletes an object instance at the given path.
  /// Returns structured operation result containing deletion details.
  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final result = await _client.delete_(path).toDart;

      if (result == null || result.isUndefinedOrNull) {
        // Fallback: assume success for legacy WASM version
        return {
          'overallSuccess': true,
          'hasAnySuccess': true,
          'hasErrors': false,
          'results': [{
            'requestedPath': path,
            'success': true,
            'deletedInstances': [{
              'affectedPath': path,
            }]
          }],
        };
      }

      final map = result.dartify();

      // Handle structured response format
      if (map is Map) {
        return Map<String, dynamic>.from(map);
      }

      // Handle void/success response (legacy)
      return {
        'overallSuccess': true,
        'hasAnySuccess': true,
        'hasErrors': false,
        'results': [{
          'requestedPath': path,
          'success': true,
          'deletedInstances': [{
            'affectedPath': path,
          }]
        }],
      };
    } catch (e) {
      // Convert exception to structured error result
      return {
        'overallSuccess': false,
        'hasAnySuccess': false,
        'hasErrors': true,
        'results': [{
          'requestedPath': path,
          'success': false,
          'errorCode': -1,
          'errorMessage': e.toString(),
        }],
      };
    }
  }

  /// Deletes multiple object instances.
  /// Returns structured operation result containing deletion details.
  Future<Map<String, dynamic>> deleteMultiple(List<String> paths,
      {bool allowPartial = false}) async {
    try {
      final jsPaths = paths.map((p) => p.toJS).toList().toJS;
      final result = await _client.deleteMultiple(jsPaths, allowPartial).toDart;

      if (result == null || result.isUndefinedOrNull) {
        // Fallback: assume success for legacy WASM version
        return {
          'overallSuccess': true,
          'hasAnySuccess': true,
          'hasErrors': false,
          'results': paths.map((path) => {
            'requestedPath': path,
            'success': true,
            'deletedInstances': [{
              'affectedPath': path,
            }]
          }).toList(),
        };
      }

      final map = result.dartify();

      // Handle structured response format
      if (map is Map) {
        return Map<String, dynamic>.from(map);
      }

      // Handle void/success response (legacy)
      return {
        'overallSuccess': true,
        'hasAnySuccess': true,
        'hasErrors': false,
        'results': paths.map((path) => {
          'requestedPath': path,
          'success': true,
          'deletedInstances': [{
            'affectedPath': path,
          }]
        }).toList(),
      };
    } catch (e) {
      // Convert exception to structured error result
      return {
        'overallSuccess': false,
        'hasAnySuccess': false,
        'hasErrors': true,
        'results': paths.map((path) => {
          'requestedPath': path,
          'success': false,
          'errorCode': -1,
          'errorMessage': e.toString(),
        }).toList(),
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
    if (result == null || result.isUndefinedOrNull) return {};
    final map = result.dartify() as Map?;
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
    if (result == null || result.isUndefinedOrNull) return [];
    final list = result.dartify() as List?;
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
