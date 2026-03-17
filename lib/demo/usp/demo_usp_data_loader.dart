/// TR-181 Mock Data Loader for Demo Mode.
///
/// Loads `demo_usp_data.json` and provides wildcard-aware path lookups
/// that mirror how the real USP agent resolves TR-181 GET requests.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DemoUspDataLoader {
  DemoUspDataLoader._();

  static DemoUspDataLoader? _instance;
  static DemoUspDataLoader get instance => _instance ??= DemoUspDataLoader._();

  /// In-memory TR-181 data: path → string value.
  /// Mutable — `set`, `add`, `delete` operations modify this map.
  final Map<String, String> _data = {};

  bool get isLoaded => _data.isNotEmpty;

  /// Load mock data from asset.
  Future<void> load() async {
    if (_data.isNotEmpty) return;

    try {
      final jsonString = await rootBundle.loadString(
        'assets/resources/demo_usp_data.json',
      );
      final raw = json.decode(jsonString) as Map<String, dynamic>;
      for (final entry in raw.entries) {
        if (entry.key.startsWith('_')) continue; // skip comments
        _data[entry.key] = entry.value?.toString() ?? '';
      }
      debugPrint('[DemoUsp] Loaded ${_data.length} TR-181 paths');
    } catch (e) {
      debugPrint('[DemoUsp] Failed to load demo_usp_data.json: $e');
    }
  }

  /// Resolve a list of TR-181 paths (may contain wildcards) into a flat map.
  ///
  /// Supports three query patterns:
  /// 1. **Exact**: `Device.DeviceInfo.Manufacturer` → direct lookup
  /// 2. **Wildcard**: `Device.WiFi.Radio.*.Enable` → regex `\d+` for each `*`
  /// 3. **Prefix**: `Device.IP.Interface.1.IPv6Address.` → all children
  Map<String, String> resolve(List<String> paths) {
    final result = <String, String>{};
    for (final path in paths) {
      if (path.contains('*')) {
        _resolveWildcard(path, result);
      } else if (path.endsWith('.')) {
        _resolvePrefix(path, result);
      } else {
        final val = _data[path];
        if (val != null) result[path] = val;
      }
    }
    return result;
  }

  /// Expand embedded wildcards: `Device.WiFi.Radio.*.Enable`
  /// matches `Device.WiFi.Radio.1.Enable`, `Device.WiFi.Radio.2.Enable`, etc.
  void _resolveWildcard(String pattern, Map<String, String> out) {
    final escaped = RegExp.escape(pattern).replaceAll(r'\*', r'\d+');
    final regex = RegExp('^$escaped\$');
    for (final entry in _data.entries) {
      if (regex.hasMatch(entry.key)) {
        out[entry.key] = entry.value;
      }
    }
  }

  /// Expand prefix query: `Device.Hosts.Host.` → all paths that start with it.
  void _resolvePrefix(String prefix, Map<String, String> out) {
    for (final entry in _data.entries) {
      if (entry.key.startsWith(prefix)) {
        out[entry.key] = entry.value;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Mutation helpers (for interactive demo)
  // ---------------------------------------------------------------------------

  void setValue(String path, String value) {
    _data[path] = value;
  }

  void removeByPrefix(String prefix) {
    _data.removeWhere((key, _) => key.startsWith(prefix));
  }

  /// Returns the next available numeric instance ID for `objectPath`.
  ///
  /// Scans existing keys to find the highest ID and returns ID + 1.
  /// Example: `Device.NAT.PortMapping.` with existing .1. and .2. → returns 3.
  int nextInstanceId(String objectPath) {
    final normalized = objectPath.endsWith('.') ? objectPath : '$objectPath.';
    int maxId = 0;
    for (final key in _data.keys) {
      if (!key.startsWith(normalized)) continue;
      final rest = key.substring(normalized.length);
      final dot = rest.indexOf('.');
      if (dot <= 0) continue;
      final id = int.tryParse(rest.substring(0, dot));
      if (id != null && id > maxId) maxId = id;
    }
    return maxId + 1;
  }
}
