import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/a2ui_widget_definition.dart';

/// Loads A2UI widget definitions from JSON files in assets.
class JsonWidgetLoader {
  static const _assetPath = 'assets/a2ui/widgets/';

  // Known list of widget files.
  // In a production app, we might use AssetManifest.json to discover these dynamically.
  static const _widgetFiles = [
    'device_count.json',
    'node_count.json',
    'wan_status.json',
  ];

  /// Loads all widget definitions from assets.
  Future<List<A2UIWidgetDefinition>> loadAll() async {
    final widgets = <A2UIWidgetDefinition>[];

    for (final filename in _widgetFiles) {
      final path = '$_assetPath$filename';
      try {
        final content = await rootBundle.loadString(path);
        final json = jsonDecode(content) as Map<String, dynamic>;
        widgets.add(A2UIWidgetDefinition.fromJson(json));
      } catch (e) {
        // Log error but continue loading other widgets
        debugPrint('Error loading A2UI widget from $filename: $e');
      }
    }

    return widgets;
  }
}
