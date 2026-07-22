/// TR-181 Mock Data Loader for Demo Mode.
///
/// Loads the fixture data at RUNTIME (via HTTP) from a `data/` directory served
/// next to the app, instead of a bundled asset. This is the E6 single-source
/// design: the JSON is produced by the E2E canonical base (the one source of
/// truth) and dropped into `web/data/` at build time (CI) or by a local export
/// step — PrivacyGUI ships no fixture data of its own.
///
/// Scenario switching: the loader can layer a named scenario override on top of
/// the base (empty / disabled / wan-static / …), driven by a `?scenario=<name>`
/// URL query or by [loadScenario]. Scenario files are `data/scenario-<name>.json`
/// holding a declarative `{ omit: [...], set: {...} }` override — the same shape
/// the E2E suite uses — so demo and E2E drive identical states.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DemoUspDataLoader {
  DemoUspDataLoader._();

  static DemoUspDataLoader? _instance;
  static DemoUspDataLoader get instance => _instance ??= DemoUspDataLoader._();

  /// In-memory TR-181 data: path → string value.
  /// Mutable — `set`, `add`, `delete` operations modify this map.
  final Map<String, String> _data = {};

  /// The unmodified base map, kept so [applyScenario] can re-derive from a
  /// clean base without re-fetching.
  Map<String, String> _base = {};

  bool get isLoaded => _data.isNotEmpty;

  /// Resolve a file under the served `data/` directory relative to the app's
  /// base href (works locally under `flutter run` and on GitHub Pages under
  /// `/PrivacyGUI/demo/`).
  Uri _dataUri(String file) => Uri.base.resolve('data/$file');

  /// Load the base fixture, then apply the scenario named in the `?scenario=`
  /// URL query (if any). Safe to call once at startup.
  Future<void> load() async {
    if (_data.isNotEmpty) return;

    _base = await _fetchFlatMap(_dataUri('base.json'));
    _data
      ..clear()
      ..addAll(_base);
    debugPrint(
        '[DemoUsp] Loaded ${_data.length} TR-181 paths from data/base.json');

    final scenario = Uri.base.queryParameters['scenario'];
    if (scenario != null && scenario.isNotEmpty && scenario != 'populated') {
      await applyScenario(scenario);
    }
  }

  /// Re-derive the working set from the clean base with the given scenario
  /// override applied. Used both at startup and by an interactive picker.
  Future<void> applyScenario(String name) async {
    if (_base.isEmpty) {
      _base = await _fetchFlatMap(_dataUri('base.json'));
    }
    final next = Map<String, String>.from(_base);

    if (name != 'populated') {
      final override = await _fetchOverride(_dataUri('scenario-$name.json'));
      // omit: drop every path under any listed prefix.
      final omit = override['omit'];
      if (omit is List) {
        next.removeWhere(
            (k, _) => omit.any((p) => p is String && k.startsWith(p)));
      }
      // set: override / add exact paths.
      final set = override['set'];
      if (set is Map) {
        set.forEach((k, v) => next['$k'] = v?.toString() ?? '');
      }
    }

    _data
      ..clear()
      ..addAll(next);
    debugPrint('[DemoUsp] Applied scenario "$name" → ${_data.length} paths');
  }

  /// Fetch a flat `path → value` JSON map (the base), skipping `_`-prefixed
  /// comment keys and stringifying values.
  Future<Map<String, String>> _fetchFlatMap(Uri uri) async {
    try {
      final resp = await http.get(uri);
      if (resp.statusCode != 200) {
        debugPrint('[DemoUsp] Fetch $uri → HTTP ${resp.statusCode}');
        return {};
      }
      final raw = json.decode(resp.body) as Map<String, dynamic>;
      final out = <String, String>{};
      for (final entry in raw.entries) {
        if (entry.key.startsWith('_')) continue; // skip comments
        out[entry.key] = entry.value?.toString() ?? '';
      }
      return out;
    } catch (e) {
      debugPrint('[DemoUsp] Failed to fetch $uri: $e');
      return {};
    }
  }

  /// Fetch a declarative override document (`{ omit: [...], set: {...} }`).
  Future<Map<String, dynamic>> _fetchOverride(Uri uri) async {
    try {
      final resp = await http.get(uri);
      if (resp.statusCode != 200) {
        debugPrint('[DemoUsp] Scenario $uri → HTTP ${resp.statusCode}');
        return {};
      }
      return json.decode(resp.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[DemoUsp] Failed to fetch scenario $uri: $e');
      return {};
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
