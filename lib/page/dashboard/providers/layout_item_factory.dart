import 'package:sliver_dashboard/sliver_dashboard.dart';

import '../models/display_mode.dart';
import '../models/widget_spec.dart';

/// Factory for creating LayoutItems from WidgetSpecs.
///
/// Converts UI Kit spec constraints (minColumns, maxColumns, heightStrategy)
/// to sliver_dashboard's LayoutItem format (minW, maxW, minH, maxH).
///
/// This factory follows IoC (Inversion of Control):
/// - It does NOT resolve dynamic constraints internally
/// - Callers are responsible for providing already-resolved WidgetSpecs
class LayoutItemFactory {
  LayoutItemFactory._();

  /// Create a LayoutItem from a WidgetSpec with position and display mode.
  ///
  /// [spec] - The widget specification containing constraints (should be
  ///          pre-resolved if dynamic constraints are needed)
  /// [x] - Grid X position (column)
  /// [y] - Grid Y position (row)
  /// [w] - Initial width in grid slots (defaults to preferredColumns)
  /// [h] - Initial height in grid slots (defaults from HeightStrategy)
  /// [displayMode] - The display mode to use for constraints
  static LayoutItem fromSpec(
    WidgetSpec spec, {
    required int x,
    required int y,
    int? w,
    int? h,
    DisplayMode displayMode = DisplayMode.normal,
  }) {
    final constraints = spec.constraints[displayMode];
    if (constraints == null) {
      // Fallback to default constraints
      return LayoutItem(
        id: spec.id,
        x: x,
        y: y,
        w: w ?? 4,
        h: h ?? 2,
      );
    }

    // Calculate dimensions from spec
    final preferredWidth = w ?? constraints.preferredColumns;
    final preferredHeight =
        h ?? constraints.getPreferredHeightCells(columns: preferredWidth);

    return LayoutItem(
      id: spec.id,
      x: x,
      y: y,
      w: preferredWidth,
      h: preferredHeight,
      minW: constraints.minColumns,
      maxW: constraints.maxColumns.toDouble(),
      minH: constraints.minHeightRows,
      maxH: constraints.maxHeightRows.toDouble(),
    );
  }
}
