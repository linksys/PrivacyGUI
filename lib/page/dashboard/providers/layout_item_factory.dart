import 'package:sliver_dashboard/sliver_dashboard.dart';

import '../models/display_mode.dart';
import '../models/dashboard_widget_specs.dart';
import '../models/height_strategy.dart';
import '../models/widget_spec.dart';

/// Factory for creating LayoutItems from DashboardWidgetSpecs.
///
/// Converts UI Kit spec constraints (minColumns, maxColumns, heightStrategy)
/// to sliver_dashboard's LayoutItem format (minW, maxW, minH, maxH).
class LayoutItemFactory {
  LayoutItemFactory._();

  /// Create a LayoutItem from a WidgetSpec with position and display mode.
  ///
  /// [spec] - The widget specification containing constraints
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
        h ?? _getHeightFromStrategy(constraints.heightStrategy);

    return LayoutItem(
      id: spec.id,
      x: x,
      y: y,
      w: preferredWidth,
      h: preferredHeight,
      minW: constraints.minColumns,
      maxW: constraints.maxColumns.toDouble(),
      minH: spec.constraints[DisplayMode.normal]?.minHeightRows ??
          1, // Use configured min height, fallback to 1
      maxH: 12.0, // Max reasonable height
    );
  }

  /// Extract height value from HeightStrategy using pattern matching.
  static int _getHeightFromStrategy(HeightStrategy strategy) {
    return switch (strategy) {
      ColumnBasedHeightStrategy(:final multiplier) => multiplier.toInt(),
      AspectRatioHeightStrategy(:final ratio) =>
        (4 / ratio).toInt().clamp(1, 8),
      IntrinsicHeightStrategy() => 2, // Default for intrinsic
    };
  }

  /// Create default layout from customWidgets specs.
  ///
  /// Uses a smart placement algorithm to position widgets.
  static List<LayoutItem> createDefaultLayout({
    DisplayMode displayMode = DisplayMode.normal,
  }) {
    final items = <LayoutItem>[];
    int currentY = 0;

    // Group 1: Row 0 - Internet Status + Master Node Info
    items.add(fromSpec(
      DashboardWidgetSpecs.internetStatusOnly,
      x: 0,
      y: currentY,
      w: 4,
      h: 2,
      displayMode: displayMode,
    ));
    items.add(fromSpec(
      DashboardWidgetSpecs.masterNodeInfo,
      x: 4,
      y: currentY,
      w: 4,
      h: 2,
      displayMode: displayMode,
    ));

    // Group 1: Quick Panel spans 2 rows
    items.add(fromSpec(
      DashboardWidgetSpecs.quickPanel,
      x: 8,
      y: currentY,
      w: 4,
      h: 4,
      displayMode: displayMode,
    ));

    currentY += 2; // Move to row 2

    // Group 2: Row 2 - Ports + Speed Test
    items.add(fromSpec(
      DashboardWidgetSpecs.ports,
      x: 0,
      y: currentY,
      w: 4,
      h: 2,
      displayMode: displayMode,
    ));
    items.add(fromSpec(
      DashboardWidgetSpecs.speedTest,
      x: 4,
      y: currentY,
      w: 4,
      h: 2,
      displayMode: displayMode,
    ));

    currentY += 2; // Move to row 4

    // Group 3: Row 4 - Network Stats + Topology
    items.add(fromSpec(
      DashboardWidgetSpecs.networkStats,
      x: 0,
      y: currentY,
      w: 4,
      h: 2,
      displayMode: displayMode,
    ));
    items.add(fromSpec(
      DashboardWidgetSpecs.topology,
      x: 4,
      y: currentY,
      w: 8,
      h: 3,
      displayMode: displayMode,
    ));

    currentY += 3; // Move to row 7

    // Group 4: Row 7 - WiFi Grid
    items.add(fromSpec(
      DashboardWidgetSpecs.wifiGrid,
      x: 0,
      y: currentY,
      w: 8,
      h: 6,
      displayMode: displayMode,
    ));

    return items;
  }

  /// Get available spec by ID for building widgets.
  static WidgetSpec? getSpecById(String id) {
    return DashboardWidgetSpecs.getById(id);
  }
}
