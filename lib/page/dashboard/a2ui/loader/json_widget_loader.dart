import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/a2ui_widget_definition.dart';

/// Enhanced A2UI widget loader with dynamic asset discovery.
///
/// Supports both static fallback and dynamic AssetManifest-based discovery
/// for A2UI widget JSON files.
class JsonWidgetLoader {
  static const _assetPath = 'assets/a2ui/widgets/';
  static const _assetManifestPath = 'AssetManifest.json';

  // Fallback list of widget files (for compatibility and when manifest fails)
  static const _fallbackWidgetFiles = [
    'device_count.json',
    'node_count.json',
    'wan_status.json',
  ];

  /// Loads all widget definitions from assets using dynamic discovery.
  ///
  /// Attempts to use AssetManifest.json for discovery, falls back to
  /// hardcoded list if manifest discovery fails.
  Future<List<A2UIWidgetDefinition>> loadAll() async {
    try {
      // First attempt: Dynamic discovery via AssetManifest
      final dynamicFiles = await _discoverWidgetFiles();
      if (dynamicFiles.isNotEmpty) {
        debugPrint('A2UI: Using dynamic asset discovery, found ${dynamicFiles.length} files');
        return await _loadWidgetFiles(dynamicFiles);
      }
    } catch (e) {
      debugPrint('A2UI: Dynamic asset discovery unavailable: $e');
    }

    // Fallback: Use hardcoded list (normal behavior)
    debugPrint('A2UI: Using fallback asset list (normal behavior in some environments)');
    return await _loadWidgetFiles(_fallbackWidgetFiles);
  }

  /// Discovers A2UI widget files dynamically via AssetManifest.json.
  Future<List<String>> _discoverWidgetFiles() async {
    try {
      // Load and parse AssetManifest.json
      final manifestContent = await rootBundle.loadString(_assetManifestPath);
      final manifest = jsonDecode(manifestContent) as Map<String, dynamic>;

      final widgetFiles = <String>[];

      // Find all files in the A2UI widgets directory
      for (final assetPath in manifest.keys) {
        if (assetPath.startsWith(_assetPath) && assetPath.endsWith('.json')) {
          // Extract just the filename from the full path
          final filename = assetPath.substring(_assetPath.length);
          widgetFiles.add(filename);
        }
      }

      // Sort files for consistent loading order
      widgetFiles.sort();

      debugPrint('A2UI: Discovered ${widgetFiles.length} widget files: $widgetFiles');
      return widgetFiles;
    } catch (e) {
      debugPrint('A2UI: AssetManifest.json not accessible: $e (fallback will be used)');
      return [];
    }
  }

  /// Loads widget definitions from a list of filenames.
  Future<List<A2UIWidgetDefinition>> _loadWidgetFiles(List<String> filenames) async {
    final widgets = <A2UIWidgetDefinition>[];
    final loadResults = <String, bool>{};

    for (final filename in filenames) {
      final path = '$_assetPath$filename';
      try {
        final content = await rootBundle.loadString(path);
        final json = jsonDecode(content) as Map<String, dynamic>;
        final widget = A2UIWidgetDefinition.fromJson(json);
        widgets.add(widget);
        loadResults[filename] = true;
        debugPrint('A2UI: Successfully loaded widget "${widget.widgetId}" from $filename');
      } catch (e) {
        loadResults[filename] = false;
        debugPrint('A2UI: Error loading widget from $filename: $e');
      }
    }

    // Report loading summary
    final successCount = loadResults.values.where((success) => success).length;
    final totalCount = loadResults.length;
    debugPrint('A2UI: Loaded $successCount/$totalCount widget files successfully');

    // Report failed files for debugging
    final failedFiles = loadResults.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();
    if (failedFiles.isNotEmpty) {
      debugPrint('A2UI: Failed to load files: $failedFiles');
    }

    return widgets;
  }

  /// Gets the list of widget files that would be loaded (for testing/debugging).
  Future<List<String>> getDiscoveredFiles() async {
    try {
      final dynamicFiles = await _discoverWidgetFiles();
      return dynamicFiles.isNotEmpty ? dynamicFiles : _fallbackWidgetFiles;
    } catch (e) {
      debugPrint('A2UI: getDiscoveredFiles unavailable, using fallback: $e');
      return _fallbackWidgetFiles;
    }
  }

  /// Validates AssetManifest availability and A2UI asset structure.
  Future<AssetDiscoveryInfo> validateAssetStructure() async {
    try {
      // Check AssetManifest availability
      bool manifestAvailable = false;
      List<String> discoveredFiles = [];

      try {
        await rootBundle.loadString(_assetManifestPath);
        manifestAvailable = true;
        discoveredFiles = await _discoverWidgetFiles();
      } catch (e) {
        debugPrint('A2UI: AssetManifest not available for validation: $e');
      }

      // Check fallback files availability
      final fallbackResults = <String, bool>{};
      for (final filename in _fallbackWidgetFiles) {
        try {
          await rootBundle.loadString('$_assetPath$filename');
          fallbackResults[filename] = true;
        } catch (e) {
          fallbackResults[filename] = false;
        }
      }

      return AssetDiscoveryInfo(
        manifestAvailable: manifestAvailable,
        discoveredFiles: discoveredFiles,
        fallbackFiles: _fallbackWidgetFiles,
        fallbackAvailability: fallbackResults,
      );
    } catch (e) {
      debugPrint('A2UI: Asset structure validation unavailable: $e');
      return AssetDiscoveryInfo(
        manifestAvailable: false,
        discoveredFiles: [],
        fallbackFiles: _fallbackWidgetFiles,
        fallbackAvailability: {},
      );
    }
  }
}

/// Information about asset discovery and availability.
class AssetDiscoveryInfo {
  final bool manifestAvailable;
  final List<String> discoveredFiles;
  final List<String> fallbackFiles;
  final Map<String, bool> fallbackAvailability;

  const AssetDiscoveryInfo({
    required this.manifestAvailable,
    required this.discoveredFiles,
    required this.fallbackFiles,
    required this.fallbackAvailability,
  });

  /// Gets total count of available widget files.
  int get availableFileCount {
    if (manifestAvailable && discoveredFiles.isNotEmpty) {
      return discoveredFiles.length;
    }
    return fallbackAvailability.values.where((available) => available).length;
  }

  /// Gets whether any widget files are available.
  bool get hasAvailableAssets {
    return availableFileCount > 0;
  }

  /// Gets a summary string for debugging.
  String get summary {
    final buffer = StringBuffer();
    buffer.writeln('AssetManifest available: $manifestAvailable');
    buffer.writeln('Discovered files: ${discoveredFiles.length}');
    buffer.writeln('Fallback files available: ${fallbackAvailability.values.where((v) => v).length}/${fallbackFiles.length}');
    buffer.write('Total available: $availableFileCount');
    return buffer.toString();
  }
}
