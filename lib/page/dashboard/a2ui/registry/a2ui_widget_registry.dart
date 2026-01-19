import '../models/a2ui_widget_definition.dart';
import '../../models/widget_spec.dart';

/// Registry for A2UI widget definitions.
///
/// Manages all registered A2UI widgets and provides lookup functionality.
class A2UIWidgetRegistry {
  final Map<String, A2UIWidgetDefinition> _widgets = {};

  /// Registers an A2UI widget definition.
  void register(A2UIWidgetDefinition definition) {
    _widgets[definition.widgetId] = definition;
  }

  /// Registers an A2UI widget from JSON.
  void registerFromJson(Map<String, dynamic> json) {
    final definition = A2UIWidgetDefinition.fromJson(json);
    register(definition);
  }

  /// Registers multiple widgets from a JSON list.
  void registerAllFromJson(List<Map<String, dynamic>> jsonList) {
    for (final json in jsonList) {
      registerFromJson(json);
    }
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
  void clear() => _widgets.clear();
}
