/// Demo Cache Data Loader
///
/// Loads and provides access to the cached JNAP responses from demo_cache_data.json.
/// This provides real device data for the demo app.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Loader for demo cache data from demo_cache_data.json asset
class DemoCacheDataLoader {
  DemoCacheDataLoader._();

  static DemoCacheDataLoader? _instance;
  static DemoCacheDataLoader get instance =>
      _instance ??= DemoCacheDataLoader._();

  /// Cache data map: action URL -> cached entry
  Map<String, dynamic>? _cacheData;

  /// Pre-built lookup map for fast access (includes version fallbacks)
  Map<String, Map<String, dynamic>>? _lookupMap;

  /// Whether the cache has been loaded
  bool get isLoaded => _cacheData != null;

  /// Load cache data from asset
  Future<void> load() async {
    if (_cacheData != null) return;

    try {
      final jsonString = await rootBundle.loadString(
        'assets/resources/demo_cache_data.json',
      );
      _cacheData = json.decode(jsonString) as Map<String, dynamic>;
      _buildLookupMap();
      debugPrint('📦 Demo: Loaded ${_cacheData!.length} cached JNAP responses');
    } catch (e) {
      debugPrint('⚠️ Demo: Failed to load cache data: $e');
      _cacheData = {};
      _lookupMap = {};
    }
  }

  /// Build lookup map with version-agnostic keys
  void _buildLookupMap() {
    _lookupMap = {};

    for (final entry in _cacheData!.entries) {
      final actionUrl = entry.key;
      final output = _extractOutput(entry.value);
      if (output == null) continue;

      // Store with original key
      _lookupMap![actionUrl] = output;

      // Also store with base name (without version suffix)
      // e.g., "GetDevices3" -> "GetDevices"
      final baseName = _stripVersionSuffix(actionUrl);
      if (baseName != actionUrl) {
        _lookupMap![baseName] = output;
      }

      // Store by simple action name (last part of URL)
      // e.g. ".../nodes/smartmode/GetDeviceMode" -> "GetDeviceMode"
      // This handles path variations (e.g. nodes/ vs non-nodes/)
      final simpleName = actionUrl.split('/').last;
      final simpleBaseName = _stripVersionSuffix(simpleName);

      // Prioritize preserving existing mappings if collision occurs,
      // but ensure at least one entry exists for the simple name.
      if (!_lookupMap!.containsKey(simpleName)) {
        _lookupMap![simpleName] = output;
      }
      if (simpleBaseName != simpleName &&
          !_lookupMap!.containsKey(simpleBaseName)) {
        _lookupMap![simpleBaseName] = output;
      }
    }

    // Debug: Print keys containing "Device"
    final deviceKeys =
        _lookupMap!.keys.where((k) => k.contains('Device')).toList();
    debugPrint('🔍 Demo: Device-related keys: $deviceKeys');
  }

  /// Strip version suffix from action URL
  /// e.g., "http://linksys.com/jnap/devicelist/GetDevices3" -> "http://linksys.com/jnap/devicelist/GetDevices"
  String _stripVersionSuffix(String actionUrl) {
    // Match trailing digits (1-9 only, not 0)
    final regex = RegExp(r'[2-9]+$');
    return actionUrl.replaceFirst(regex, '');
  }

  /// Extract output from cache entry
  Map<String, dynamic>? _extractOutput(dynamic entryValue) {
    if (entryValue is! Map) return null;

    final data = entryValue['data'];
    if (data is! Map) return null;

    final output = data['output'];
    if (output is Map<String, dynamic>) {
      return output;
    }
    if (output is Map) {
      return Map<String, dynamic>.from(output);
    }
    return null;
  }

  /// Get the output data for a given JNAP action URL
  /// Returns null if not found
  ///
  /// Lookup order:
  /// 1. Exact match
  /// 2. Base name without version suffix
  Map<String, dynamic>? getOutput(String actionUrl) {
    if (_lookupMap == null) {
      debugPrint('⚠️ Demo: Cache not loaded, call load() first');
      return {};
    }

    // Debug for GetDevices or GetLocalDevice
    final isDeviceAction =
        actionUrl.contains('GetDevices') || actionUrl.contains('GetDevice');
    if (isDeviceAction) {
      debugPrint('🔍 Demo: Looking up $actionUrl');
      debugPrint(
          '🔍 Demo: Base name would be: ${_stripVersionSuffix(actionUrl)}');
    }

    // 1. Try exact match
    var output = _lookupMap![actionUrl];
    if (output != null) {
      if (isDeviceAction) {
        debugPrint('✅ Demo: Found exact match for $actionUrl');
      }
      return output;
    }

    // 2. Try base name (strip version suffix from request)
    final baseName = _stripVersionSuffix(actionUrl);
    if (baseName != actionUrl) {
      output = _lookupMap![baseName];
      if (output != null) {
        if (actionUrl.contains('GetDevices') ||
            actionUrl.contains('GetDevice')) {
          debugPrint('✅ Demo: Found via base name $baseName');
        }
        return output;
      }
    }

    if (actionUrl.contains('GetDevices') || actionUrl.contains('GetDevice')) {
      debugPrint('❌ Demo: NOT FOUND for $actionUrl');
    }
    return null;
  }

  /// Check if an action URL exists in the cache
  bool hasAction(String actionUrl) {
    return _lookupMap?.containsKey(actionUrl) ?? false;
  }

  /// Get all cached action URLs
  List<String> get cachedActions {
    return _lookupMap?.keys.toList() ?? [];
  }
}
