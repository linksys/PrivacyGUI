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

    return map.map((key, value) => MapEntry(key.toString(), value.toString()));
  }

  Future<void> set(String path, String value) async {
    await _client.set(path, value).toDart;
  }

  Future<void> setMultiple(Map<String, String> parameters,
      {bool allowPartial = false}) async {
    await _client.setMultiple(parameters.jsify()!, allowPartial).toDart;
  }

  /// Creates a new object instance at the given path with initial parameters.
  /// Returns the created instance path (e.g., "Device.NAT.PortMapping.3.").
  Future<String> add(String objectPath, Map<String, String> parameters) async {
    final result =
        await _client.add(objectPath, parameters.jsify()!).toDart;
    return result?.dartify()?.toString() ?? '';
  }

  /// Creates multiple object instances.
  /// Each object should have `path` (String) and `parameters` (Map<String, String>).
  /// Returns a list of created instance paths.
  Future<List<String>> addMultiple(List<Map<String, dynamic>> objects,
      {bool allowPartial = false}) async {
    final jsObjects = objects.map((obj) => obj.jsify()!).toList().toJS;
    final result =
        await _client.addMultiple(jsObjects, allowPartial).toDart;
    final list = result.dartify() as List?;
    if (list == null) return [];
    return list.map((e) => e.toString()).toList();
  }

  /// Deletes an object instance at the given path.
  Future<void> delete(String path) async {
    await _client.delete_(path).toDart;
  }

  /// Deletes multiple object instances.
  Future<void> deleteMultiple(List<String> paths,
      {bool allowPartial = false}) async {
    final jsPaths = paths.map((p) => p.toJS).toList().toJS;
    await _client.deleteMultiple(jsPaths, allowPartial).toDart;
  }

  /// Executes a USP Operate command.
  /// Returns the output arguments as a map, or empty map if no output.
  Future<Map<String, String>> operate(String command,
      {Map<String, String> args = const {}}) async {
    final result =
        await _client.operate(command, args.jsify()!).toDart;
    if (result == null || result.isUndefinedOrNull) return {};
    final map = result.dartify() as Map?;
    if (map == null) return {};
    return map.map((key, value) => MapEntry(key.toString(), value.toString()));
  }

  void dispose() {
    _client.free();
  }
}
