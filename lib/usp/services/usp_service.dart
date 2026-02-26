import 'package:flutter/foundation.dart';

// Since this POC is currently strictly Web, we're directly importing and using
// the web implementation. In a full multi-platform app, this would use conditional
// imports (e.g., `import '../web/usp_client_wasm.dart' if (dart.library.io) 'native/usp_client_ffi.dart';`).
import '../web/usp_client_wasm.dart';

// Export response helpers so generated code only needs one import.
export 'usp_response_helpers.dart';

/// Platform-agnostic Service for interacting with the router via USP.
class UspService {
  late final UspClientWeb _client;

  UspService(String baseUrl) {
    if (!kIsWeb) {
      throw UnsupportedError('This POC only supports Web platforms currently.');
    }
    _client = UspClientWeb(baseUrl);
  }

  bool get isAuthenticated => _client.isAuthenticated;

  Future<void> login(String password) async {
    await _client.login(password);
  }

  Future<void> logout() async {
    await _client.logout();
  }

  Future<void> refreshToken() async {
    await _client.refreshToken();
  }

  // Legacy single getters if needed
  Future<String?> getSingle(String path) async {
    return await _client.get(path);
  }

  Future<void> setSingle(String path, String value) async {
    await _client.set(path, value);
  }

  // Codegen expected signatures
  Future<Map<String, dynamic>> get(List<String> paths) async {
    final rawMap = await _client.getMultiple(paths);

    // Debug: log raw response from JS client
    debugPrint('[UspService.get] Requested paths: $paths');
    debugPrint('[UspService.get] Raw response keys: ${rawMap.keys.toList()}');
    for (final entry in rawMap.entries) {
      debugPrint(
          '[UspService.get]   rawMap["${entry.key}"] = "${entry.value}" (${entry.value.runtimeType})');
    }

    final Map<String, dynamic> result = {};

    // Include all returned paths (may include extra child paths)
    for (final entry in rawMap.entries) {
      result[entry.key] = _coerceValue(entry.key, entry.value);
    }

    // Ensure all requested paths exist in the result to prevent Null Cast errors in Codegen
    for (final path in paths) {
      if (!result.containsKey(path)) {
        debugPrint('[UspService.get] ⚠️ MISSING path in response: "$path"');
      }
      result.putIfAbsent(path, () => null);
    }

    // Debug: log final coerced result
    debugPrint('[UspService.get] Final result:');
    for (final entry in result.entries) {
      debugPrint(
          '[UspService.get]   result["${entry.key}"] = ${entry.value} (${entry.value.runtimeType})');
    }

    return result;
  }

  /// Coerce a raw string value from USP into the appropriate Dart type.
  /// - "true" / "false" / "1" / "0" (for Enable paths) → bool
  /// - Empty or null → null
  /// - Everything else stays as String (generated code handles int parsing)
  dynamic _coerceValue(String path, String? raw) {
    if (raw == null || raw.isEmpty) return null;

    // Boolean coercion
    final lower = raw.toLowerCase();
    if (lower == 'true' || (raw == '1' && path.endsWith('Enable'))) {
      return true;
    }
    if (lower == 'false' || (raw == '0' && path.endsWith('Enable'))) {
      return false;
    }

    return raw;
  }

  Future<void> set(Map<String, dynamic> parameters,
      {bool allowPartial = false}) async {
    // Convert Map<String, dynamic> to Map<String, String> as required by the lower-level UI client
    final Map<String, String> stringParams =
        parameters.map((key, value) => MapEntry(key, value.toString()));
    await _client.setMultiple(stringParams, allowPartial: allowPartial);
  }

  // Legacy multiple getters
  Future<Map<String, String>> getMultiple(List<String> paths) async {
    return await _client.getMultiple(paths);
  }

  Future<void> setMultiple(Map<String, String> parameters,
      {bool allowPartial = false}) async {
    await _client.setMultiple(parameters, allowPartial: allowPartial);
  }

  // ===========================================================================
  // Add Operation — create new object instances
  // ===========================================================================

  /// Creates a new object instance at the given path with initial parameters.
  ///
  /// [objectPath] must end with "." (e.g., "Device.NAT.PortMapping.").
  /// [parameters] are the initial parameter values for the new instance.
  /// Returns the full path of the created instance (e.g., "Device.NAT.PortMapping.3.").
  Future<String> add(String objectPath, Map<String, String> parameters) async {
    return await _client.add(objectPath, parameters);
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
    return await _client.addMultiple(objects, allowPartial: allowPartial);
  }

  // ===========================================================================
  // Delete Operation — remove object instances
  // ===========================================================================

  /// Deletes the object instance at the given path.
  ///
  /// [path] must be a specific instance path (e.g., "Device.NAT.PortMapping.3.").
  Future<void> delete(String path) async {
    await _client.delete(path);
  }

  /// Deletes multiple object instances in a single operation.
  Future<void> deleteMultiple(List<String> paths,
      {bool allowPartial = false}) async {
    await _client.deleteMultiple(paths, allowPartial: allowPartial);
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
    return await _client.operate(command, args: args);
  }

  // ===========================================================================
  // Subscribe — real-time parameter change notifications
  // ===========================================================================

  /// Subscribes to parameter changes on the given paths.
  ///
  /// [paths] are the TR-181 paths to monitor (e.g., ["Device.Hosts.Host."]).
  /// [notifType] is the USP notification type:
  ///   - 1 = ValueChange
  ///   - 2 = ObjectCreation
  ///   - 3 = ObjectDeletion
  ///
  /// Returns a Stream that emits updated parameter maps when changes occur.
  ///
  /// TODO: Implement when JS/WASM client adds subscribe support.
  Stream<Map<String, dynamic>> subscribe(
      List<String> paths, int notifType) {
    // Stub: the JS/WASM client does not yet support USP Subscribe.
    // Return an empty stream to allow generated code to compile.
    debugPrint(
        '[UspService.subscribe] ⚠️ STUB — subscribe not yet implemented in JS client. '
        'paths=$paths, notifType=$notifType');
    return const Stream.empty();
  }

  void dispose() {
    _client.dispose();
  }
}
