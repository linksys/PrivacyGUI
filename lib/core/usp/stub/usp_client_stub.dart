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

  Future<Map<String, String>> get(List<String> paths) =>
      throw UnsupportedError('USP is only available on Web');

  Future<Map<String, dynamic>> set(Map<String, String> parameters,
          {bool allowPartial = false}) =>
      throw UnsupportedError('USP is only available on Web');

  Future<Map<String, dynamic>> add(List<Map<String, dynamic>> items,
          {bool allowPartial = false}) =>
      throw UnsupportedError('USP is only available on Web');

  Future<Map<String, dynamic>> delete(List<String> paths,
          {bool allowPartial = false}) =>
      throw UnsupportedError('USP is only available on Web');

  Future<Map<String, dynamic>> operate(String command,
          {Map<String, String> args = const {}}) =>
      throw UnsupportedError('USP is only available on Web');

  Future<List<Map<String, dynamic>>> listSubscriptions() =>
      throw UnsupportedError('USP is only available on Web');

  void dispose() {}
}
