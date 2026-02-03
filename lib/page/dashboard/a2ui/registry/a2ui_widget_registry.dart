import 'package:flutter/foundation.dart';

import '../models/a2ui_widget_definition.dart';
import '../../models/widget_spec.dart';

/// Registry for A2UI widget definitions.
///
/// Manages all registered A2UI widgets and provides lookup functionality.
/// Extends ChangeNotifier for efficient rebuilds via content hash.
class A2UIWidgetRegistry extends ChangeNotifier {
  final Map<String, A2UIWidgetDefinition> _widgets = {};
  String? _contentHash;

  /// Registers an A2UI widget definition.
  void register(A2UIWidgetDefinition definition) {
    _widgets[definition.widgetId] = definition;
    _invalidateHash();
    notifyListeners(); // Notify consumers of registry changes
  }

  /// Registers an A2UI widget from JSON.
  void registerFromJson(Map<String, dynamic> json) {
    final definition = A2UIWidgetDefinition.fromJson(json);
    register(definition);
  }

  /// Registers multiple widgets from a JSON list.
  void registerAllFromJson(List<Map<String, dynamic>> jsonList) {
    for (final json in jsonList) {
      final definition = A2UIWidgetDefinition.fromJson(json);
      _widgets[definition.widgetId] = definition;
    }
    _invalidateHash();
    notifyListeners(); // Single notification after batch registration
  }

  /// Gets all registered widget specifications.
  ///
  /// Returns [WidgetSpec] objects for use with the dashboard grid.
  List<WidgetSpec> get widgetSpecs =>
      _widgets.values.map((d) => d.toWidgetSpec()).toList();

  /// Gets an A2UI widget definition by ID.
  A2UIWidgetDefinition? get(String widgetId) => _widgets[widgetId];

  /// Checks if a widget ID is registered.
  bool contains(String widgetId) => _widgets.containsKey(widgetId);

  /// Gets all registered widget IDs.
  Iterable<String> get widgetIds => _widgets.keys;

  /// Gets the count of registered widgets.
  int get length => _widgets.length;

  /// Clears all registered widgets.
  void clear() {
    _widgets.clear();
    _invalidateHash();
    notifyListeners();
  }

  /// Gets content hash for efficient rebuilds.
  ///
  /// The hash is computed based on widget IDs and their hash codes.
  /// This allows UI to rebuild only when actual content changes.
  String get contentHash {
    _contentHash ??= _computeContentHash();
    return _contentHash!;
  }

  /// Invalidates the cached content hash.
  void _invalidateHash() {
    _contentHash = null;
  }

  /// Computes content hash based on registered widgets.
  String _computeContentHash() {
    if (_widgets.isEmpty) return 'empty';

    final keys = _widgets.keys.toList()..sort();
    final content = keys.map((k) => '$k:${_widgets[k]!.hashCode}').join('|');
    return content.hashCode.toString();
  }

  @override
  void dispose() {
    _widgets.clear();
    super.dispose();
  }
}
