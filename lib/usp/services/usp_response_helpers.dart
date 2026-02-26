/// Helper classes and extensions for parsing USP Get responses.
///
/// Used by v5 codegen-generated multi-instance code.
/// Example generated usage:
/// ```dart
/// final instances = response.getInstances('Device.Hosts.Host.');
/// for (final instance in instances) {
///   items.add(ConnectedDevice(
///     instancePath: instance.path,
///     macAddress: instance.getString('PhysAddress'),
///     isActive: instance.getBool('Active'),
///   ));
/// }
/// ```

/// Represents a single object instance from a USP Get response.
///
/// Groups parameters belonging to one instance (e.g., Device.Hosts.Host.1.)
/// and provides type-safe accessors.
class UspInstance {
  /// The full instance path including trailing dot
  /// (e.g., "Device.Hosts.Host.1.").
  final String path;

  /// Raw parameter values keyed by relative parameter name.
  final Map<String, dynamic> _params;

  const UspInstance({required this.path, required Map<String, dynamic> params})
      : _params = params;

  /// Get a string parameter value.
  String getString(String paramName) {
    final value = _params[paramName];
    if (value == null) return '';
    return value.toString();
  }

  /// Get a boolean parameter value.
  bool getBool(String paramName) {
    final value = _params[paramName];
    if (value is bool) return value;
    if (value == null) return false;
    final str = value.toString().toLowerCase();
    return str == 'true' || str == '1';
  }

  /// Get an integer parameter value.
  int getInt(String paramName) {
    final value = _params[paramName];
    if (value is int) return value;
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  /// Get a double parameter value.
  double getDouble(String paramName) {
    final value = _params[paramName];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value == null) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

/// Extension on USP Get response maps to extract multi-instance objects.
extension UspResponseExtension on Map<String, dynamic> {
  /// Parses a flat USP Get response into grouped [UspInstance] objects.
  ///
  /// [basePath] is the object table path with trailing dot
  /// (e.g., "Device.Hosts.Host.").
  ///
  /// Given a response like:
  /// ```
  /// {
  ///   "Device.Hosts.Host.1.PhysAddress": "AA:BB:CC:DD:EE:FF",
  ///   "Device.Hosts.Host.1.IPAddress": "192.168.1.100",
  ///   "Device.Hosts.Host.2.PhysAddress": "11:22:33:44:55:66",
  ///   "Device.Hosts.Host.2.IPAddress": "192.168.1.101",
  /// }
  /// ```
  ///
  /// Returns a list of [UspInstance] with:
  /// - instance[0].path = "Device.Hosts.Host.1."
  /// - instance[0].getString("PhysAddress") = "AA:BB:CC:DD:EE:FF"
  /// - instance[1].path = "Device.Hosts.Host.2."
  /// - instance[1].getString("PhysAddress") = "11:22:33:44:55:66"
  List<UspInstance> getInstances(String basePath) {
    final instanceMap = <String, Map<String, dynamic>>{};

    for (final entry in entries) {
      final key = entry.key;
      if (!key.startsWith(basePath)) continue;

      // Extract instance number and parameter name
      // e.g., "Device.Hosts.Host.1.PhysAddress" → suffix = "1.PhysAddress"
      final suffix = key.substring(basePath.length);
      final dotIndex = suffix.indexOf('.');
      if (dotIndex < 0) continue;

      final instanceId = suffix.substring(0, dotIndex);
      final paramName = suffix.substring(dotIndex + 1);
      final instancePath = '$basePath$instanceId.';

      instanceMap
          .putIfAbsent(instancePath, () => <String, dynamic>{})
          [paramName] = entry.value;
    }

    // Sort by instance number for consistent ordering
    final sortedKeys = instanceMap.keys.toList()..sort();
    return sortedKeys
        .map((path) => UspInstance(path: path, params: instanceMap[path]!))
        .toList();
  }
}
