import 'display_mode.dart';
import 'widget_grid_constraints.dart';

/// Component Specification Definition
///
/// Each DisplayMode corresponds to different grid constraints.
/// Runtime requirements for a widget to be available.
enum WidgetRequirement {
  none,
  vpnSupported,
}

class WidgetSpec {
  /// Unique component ID
  final String id;

  /// Display name (for Settings UI)
  final String displayName;

  /// Brief description of the widget's function.
  final String? description;

  /// Constraint definitions for each DisplayMode
  final Map<DisplayMode, WidgetGridConstraints> constraints;

  /// Whether the widget can be hidden by the user.
  ///
  /// Defaults to true. Set to false for mandatory widgets (e.g. Internet Status).
  final bool canHide;

  /// List of requirements for this widget to be available.
  final List<WidgetRequirement> requirements;

  const WidgetSpec({
    required this.id,
    required this.displayName,
    required this.constraints,
    this.description,
    this.canHide = true,
    this.requirements = const [],
  });

  /// Get constraints for specified mode, fallback to normal mode if missing
  WidgetGridConstraints getConstraints(DisplayMode mode) =>
      constraints[mode] ?? constraints[DisplayMode.normal]!;

  @override
  bool operator ==(Object other) =>
      other is WidgetSpec &&
      other.id == id &&
      other.displayName == displayName &&
      other.canHide == canHide &&
      _listEquals(other.requirements, requirements);

  @override
  int get hashCode =>
      Object.hash(id, displayName, canHide, Object.hashAll(requirements));

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
