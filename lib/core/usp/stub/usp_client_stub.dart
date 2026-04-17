/// Stub implementation of UspClientWeb for non-Web platforms (Dart VM / tests).
///
/// This file is selected by conditional import when dart.library.js_interop
/// is not available. All methods throw UnsupportedError since USP is
/// only available on Web (WASM).
class UspClientWeb {
  UspClientWeb(String baseUrl);

  bool get isAuthenticated => false;

  String? get sessionToken => null;

  Future<void> subscribe(String subscriptionId) =>
      throw UnsupportedError('USP is only available on Web');

  Future<void> unsubscribe(String subscriptionId) =>
      throw UnsupportedError('USP is only available on Web');

  Future<void> login(String password) =>
      throw UnsupportedError('USP is only available on Web');

  Future<void> logout() =>
      throw UnsupportedError('USP is only available on Web');

  Future<void> refreshToken() =>
      throw UnsupportedError('USP is only available on Web');

  Future<String?> get(String path) =>
      throw UnsupportedError('USP is only available on Web');

  Future<Map<String, String>> getMultiple(List<String> paths) =>
      throw UnsupportedError('USP is only available on Web');

  Future<Map<String, dynamic>> getMultipleStructured(List<String> paths) =>
      throw UnsupportedError('USP is only available on Web');

  Future<void> set(String path, String value) =>
      throw UnsupportedError('USP is only available on Web');

  Future<Map<String, dynamic>> setMultiple(Map<String, String> parameters,
          {bool allowPartial = false}) =>
      throw UnsupportedError('USP is only available on Web');

  Future<Map<String, dynamic>> add(
          String objectPath, Map<String, String> parameters) =>
      throw UnsupportedError('USP is only available on Web');

  Future<Map<String, dynamic>> addMultiple(List<Map<String, dynamic>> objects,
          {bool allowPartial = false}) =>
      throw UnsupportedError('USP is only available on Web');

  Future<Map<String, dynamic>> delete(String path) =>
      throw UnsupportedError('USP is only available on Web');

  Future<Map<String, dynamic>> deleteMultiple(List<String> paths,
          {bool allowPartial = false}) =>
      throw UnsupportedError('USP is only available on Web');

  Future<Map<String, dynamic>> operate(String command,
          {Map<String, String> args = const {}}) =>
      throw UnsupportedError('USP is only available on Web');

  Future<List<Map<String, dynamic>>> listSubscriptions() =>
      throw UnsupportedError('USP is only available on Web');

  void dispose() {}
}
