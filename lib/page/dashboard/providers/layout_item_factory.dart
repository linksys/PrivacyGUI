import 'package:sliver_dashboard/sliver_dashboard.dart';

import '../models/display_mode.dart';
import '../models/dashboard_widget_specs.dart';
import '../models/widget_spec.dart';

/// Function type for resolving WidgetSpecs dynamically.
///
/// Used by [LayoutItemFactory.createDefaultLayout] to allow callers to
/// provide pre-resolved specs (e.g., dynamic Ports constraints based on
/// hardware state).
typedef WidgetSpecResolver = WidgetSpec Function(WidgetSpec defaultSpec);

/// Factory for creating LayoutItems from DashboardWidgetSpecs.
///
/// Converts UI Kit spec constraints (minColumns, maxColumns, heightStrategy)
/// to sliver_dashboard's LayoutItem format (minW, maxW, minH, maxH).
///
/// This factory follows IoC (Inversion of Control):
/// - It does NOT resolve dynamic constraints internally
/// - Callers are responsible for providing already-resolved WidgetSpecs
/// - Use [specResolver] in [createDefaultLayout] for dynamic specs
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

  /// Create default layout from customWidgets specs.
  ///
  /// Uses a smart placement algorithm to position widgets.
  ///
  /// [specResolver] - Optional function to resolve dynamic specs.
  ///                  If provided, each spec will be passed through this
  ///                  resolver before creating the LayoutItem. This allows
  ///                  callers to inject dynamic constraints (e.g., Ports
  ///                  constraints based on hardware state) following IoC.
  ///                  If null, uses the default static specs.
  static List<LayoutItem> createDefaultLayout({
    DisplayMode displayMode = DisplayMode.normal,
    WidgetSpecResolver? specResolver,
  }) {
    final items = <LayoutItem>[];

    // Helper to resolve spec (uses resolver if provided, otherwise identity)
    WidgetSpec resolve(WidgetSpec spec) => specResolver?.call(spec) ?? spec;

    // Get resolved Ports spec for layout calculations
    final portsSpec = resolve(DashboardWidgetSpecs.ports);
    final portsConstraints = portsSpec.constraints[displayMode];
    final portsPreferredW = portsConstraints?.preferredColumns ?? 4;
    final portsPreferredH =
        portsConstraints?.getPreferredHeightCells(columns: portsPreferredW) ??
            6;

    // Layout based on the target screenshot:
    // ┌─────────────┬─────────────┬─────────────┐
    // │ Internet    │   Master    │ Quick Panel │ y=0
    // │  (4x2)      │   (4x6)     │   (4x3)     │
    // ├─────────────┤             ├─────────────┤ y=2
    // │             │             │ NetworkStats│
    // │   Ports     │             │   (4x2)     │ y=3
    // │   (4x6+)    ├─────────────┼─────────────┤ y=4/5
    // │             │  SpeedTest  │  Topology   │
    // │             │   (4x4)     │   (4x2)     │
    // ├─────────────┴─────────────┴─────────────┤ y=10
    // │           WiFi Grid (8x2)               │
    // └─────────────────────────────────────────┘

    // Row 0: Internet (top-left)
    items.add(fromSpec(
      resolve(DashboardWidgetSpecs.internetStatusOnly),
      x: 0,
      y: 0,
      w: 4,
      h: 2,
      displayMode: displayMode,
    ));

    // Row 0: Master Router (top-middle, spans 4 rows)
    items.add(fromSpec(
      resolve(DashboardWidgetSpecs.masterNodeInfo),
      x: 4,
      y: 0,
      w: 4,
      h: 4,
      displayMode: displayMode,
    ));

    // Row 0: Quick Panel (top-right)
    items.add(fromSpec(
      resolve(DashboardWidgetSpecs.quickPanelCustom),
      x: 8,
      y: 0,
      w: 4,
      h: 3,
      displayMode: displayMode,
    ));

    // Row 2: Ports (left side, below Internet)
    items.add(fromSpec(
      portsSpec,
      x: 0,
      y: 2,
      w: portsPreferredW,
      h: portsPreferredH,
      displayMode: displayMode,
    ));

    // Row 3: Network Stats (right side, below Quick Panel)
    items.add(fromSpec(
      resolve(DashboardWidgetSpecs.networkStats),
      x: 8,
      y: 3,
      w: 4,
      h: 2,
      displayMode: displayMode,
    ));

    // Row 5: Topology (right side, below Network Stats)
    items.add(fromSpec(
      resolve(DashboardWidgetSpecs.topology),
      x: 8,
      y: 5,
      w: 4,
      h: 4,
      displayMode: displayMode,
    ));

    // Row 6: SpeedTest (middle, below Master Router)
    final speedTestSpec = resolve(DashboardWidgetSpecs.speedTest);
    items.add(fromSpec(
      speedTestSpec,
      x: 4,
      y: 6,
      w: 4,
      h: 4,
      displayMode: displayMode,
    ));

    // Calculate bottom Y (max of Ports, SpeedTest, Topology)
    final bottomY = [
      2 + portsPreferredH, // Ports ends at y=2+h
      6 + 4, // SpeedTest ends at y=10
      5 + 2, // Topology ends at y=7
    ].reduce((a, b) => a > b ? a : b);

    // WiFi Grid (spans across bottom)
    items.add(fromSpec(
      resolve(DashboardWidgetSpecs.wifiGridCustom),
      x: 0,
      y: bottomY,
      w: 8,
      // h: removed to use preferredHeight from spec (5 in Normal mode)
      displayMode: displayMode,
    ));

    return items;
  }

  /// Get available spec by ID for building widgets.
  static WidgetSpec? getSpecById(String id) {
    return DashboardWidgetSpecs.getById(id);
  }
}
