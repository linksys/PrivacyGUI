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

  /// Constraint definitions for each DisplayMode.
  ///
  /// For native widgets, this defines constraints per mode.
  /// For A2UI widgets, this may be empty or contain a single entry.
  final Map<DisplayMode, WidgetGridConstraints> constraints;

  /// Default constraints for widgets that don't use DisplayMode variants.
  ///
  /// Primarily used by A2UI widgets which have a single constraint set.
  /// When set, [getConstraints] will fall back to this if no mode-specific
  /// constraint is found.
  final WidgetGridConstraints? defaultConstraints;

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
    this.defaultConstraints,
    this.canHide = true,
    this.requirements = const [],
  });

  /// Whether this widget supports DisplayMode switching.
  ///
  /// Returns true if [constraints] has more than one entry.
  /// A2UI widgets typically return false (single constraint set).
  bool get supportsDisplayModes => constraints.length > 1;

  /// Get constraints for specified mode, with fallback logic.
  ///
  /// Order of fallback:
  /// 1. Mode-specific constraint from [constraints]
  /// 2. [defaultConstraints] (if set)
  /// 3. Normal mode constraint from [constraints]
  WidgetGridConstraints getConstraints(DisplayMode mode) {
    return constraints[mode] ??
        defaultConstraints ??
        constraints[DisplayMode.normal]!;
  }

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
