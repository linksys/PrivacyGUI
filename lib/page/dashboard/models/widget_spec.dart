import 'package:ui_kit_library/ui_kit.dart';

import 'display_mode.dart';

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

  /// The narrowest width, in pixels, at which this card renders its full form.
  ///
  /// Below it the card degrades — compact down to 200px, popup below that. See
  /// `CardDensity` and `doc/dashboard/dashboard_density_design.md` §2.1.
  ///
  /// Absent by default, and absent is a claim: *this card needs no degraded
  /// form*. It is the correct value for a card that fits at its narrowest grid
  /// realization — which #1240's measurement found to be all 18 registered cards,
  /// and #1288's found to be a different question: `device_info`, `lan_info` and
  /// `time_settings` fit and cannot be read, and are the first three specs to
  /// declare a threshold. Each carries the measurement that produced its number.
  ///
  /// Pixels, never a column count: the same column count is a different width on
  /// every screen size (§1.5), so a threshold expressed in columns does not name
  /// the quantity it is trying to constrain. It lives here rather than on
  /// `WidgetGridConstraints` because that type belongs to ui_kit_library, and
  /// this is an app-level readability decision, not a grid constraint
  /// (constitution Article XIV).
  final double? normalAbove;

  const WidgetSpec({
    required this.id,
    required this.displayName,
    required this.constraints,
    this.description,
    this.defaultConstraints,
    this.canHide = true,
    this.requirements = const [],
    this.normalAbove,
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
      other.normalAbove == normalAbove &&
      _listEquals(other.requirements, requirements);

  @override
  int get hashCode => Object.hash(
        id,
        displayName,
        canHide,
        normalAbove,
        Object.hashAll(requirements),
      );

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
