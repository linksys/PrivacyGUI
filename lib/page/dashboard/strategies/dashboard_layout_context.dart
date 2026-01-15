import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../models/dashboard_widget_specs.dart';
import '../models/display_mode.dart';
import '../models/grid_widget_config.dart';
import '../models/widget_spec.dart';
import 'grid_layout_resolver.dart';

/// Configuration for port and speed widget building.
class PortAndSpeedConfig {
  /// Direction of port layout (horizontal or vertical).
  /// If null, the widget will determine direction based on available width.
  final Axis? direction;

  /// Whether to show the speed test section.
  final bool showSpeedTest;

  /// Height for the ports section (null = flexible).
  final double? portsHeight;

  /// Height for the speed test section (null = flexible).
  final double? speedTestHeight;

  /// Padding for the ports section.
  final EdgeInsets portsPadding;

  const PortAndSpeedConfig({
    this.direction,
    this.showSpeedTest = true,
    this.portsHeight,
    this.speedTestHeight,
    this.portsPadding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.xxl,
    ),
  });
}

/// Holds all pre-built widgets and context data needed by layout strategies.
///
/// This class implements IoC (Inversion of Control) - widgets are built by
/// the View and passed down to Strategies, rather than Strategies building
/// their own widgets.
class DashboardLayoutContext {
  /// The build context for layout calculations.
  final BuildContext context;

  /// Riverpod ref for accessing providers.
  final WidgetRef ref;

  /// Current dashboard home state.
  final DashboardHomeState state;

  /// Whether the device has LAN ports.
  final bool hasLanPort;

  /// Whether the port layout is horizontal.
  final bool isHorizontalLayout;

  // Pre-built atomic widgets (IoC - built by View, used by Strategy)

  /// Dashboard title widget.
  final Widget title;

  /// Internet connection status widget.
  final Widget internetWidget;

  /// Network nodes overview widget.
  final Widget networksWidget;

  /// WiFi cards grid widget.
  final Widget wifiGrid;

  /// Quick actions panel widget.
  final Widget quickPanel;

  /// VPN status tile (null if VPN not supported).
  final Widget? vpnTile;

  /// Factory function to build port and speed widget with configuration.
  ///
  /// Strategies call this with their specific configuration to get
  /// a properly configured port and speed widget.
  final Widget Function(PortAndSpeedConfig config) buildPortAndSpeed;

  // ---------------------------------------------------------------------------
  // Grid Constraint System
  // ---------------------------------------------------------------------------

  /// Widget configurations (keyed by widget ID).
  ///
  /// Used by the grid constraint system to determine widget sizing and display mode.
  final Map<String, GridWidgetConfig> widgetConfigs;

  const DashboardLayoutContext({
    required this.context,
    required this.ref,
    required this.state,
    required this.hasLanPort,
    required this.isHorizontalLayout,
    required this.title,
    required this.internetWidget,
    required this.networksWidget,
    required this.wifiGrid,
    required this.quickPanel,
    this.vpnTile,
    required this.buildPortAndSpeed,
    this.widgetConfigs = const {},
  });

  /// Convenience getter for column width calculation.
  double colWidth(int columns) => context.colWidth(columns);

  // ---------------------------------------------------------------------------
  // Grid Constraint Helpers
  // ---------------------------------------------------------------------------

  /// Creates a [GridLayoutResolver] for this context.
  GridLayoutResolver get resolver => GridLayoutResolver(context);

  /// Gets the full configuration for a widget spec.
  GridWidgetConfig getConfigFor(WidgetSpec spec) {
    return widgetConfigs[spec.id] ??
        GridWidgetConfig(widgetId: spec.id, order: 0);
  }

  /// Gets the display mode for a widget spec.
  DisplayMode getModeFor(WidgetSpec spec) => getConfigFor(spec).displayMode;

  /// Gets the resolved column count for a widget.
  int getColumnsFor(WidgetSpec spec, {int? availableColumns}) {
    final config = getConfigFor(spec);
    return resolver.resolveColumns(
      spec,
      config.displayMode,
      availableColumns: availableColumns,
      overrideColumns: config.columnSpan,
    );
  }

  /// Gets the resolved width for a widget.
  double getWidthFor(WidgetSpec spec, {int? availableColumns}) {
    final config = getConfigFor(spec);
    return resolver.resolveWidth(
      spec,
      config.displayMode,
      availableColumns: availableColumns,
      overrideColumns: config.columnSpan,
    );
  }

  /// Gets the resolved height for a widget (null = intrinsic).
  double? getHeightFor(WidgetSpec spec, {int? availableColumns}) {
    final config = getConfigFor(spec);
    return resolver.resolveHeight(
      spec,
      config.displayMode,
      availableColumns: availableColumns,
      overrideColumns: config.columnSpan,
    );
  }

  /// Wraps a widget in a standard AppCard.
  ///
  /// Used by layout strategies to provide a consistent visual container
  /// for "stripped" widgets.
  Widget wrapWithStandardCard(
    Widget child, {
    EdgeInsetsGeometry? padding,
  }) {
    return AppCard(
      padding: padding,
      child: child,
    );
  }

  /// Wraps a widget with size constraints based on its spec and user preferences.
  Widget wrapWidget(
    Widget child, {
    required WidgetSpec spec,
    int? availableColumns,
  }) {
    final config = getConfigFor(spec);

    // Force full width (stack) on mobile, ignoring user width settings
    final isMobile = context.isMobileLayout;
    // Force half width (2 columns) on tablet, ignoring user width settings
    final isTablet = context.isTabletLayout;

    final effectiveOverride = isMobile
        ? 12
        : isTablet
            ? 6
            : config.columnSpan;

    return resolver.wrapWithConstraints(
      child,
      spec: spec,
      mode: config.displayMode,
      availableColumns: availableColumns,
      overrideColumns: effectiveOverride,
    );
  }

  // ---------------------------------------------------------------------------
  // Dynamic Layout Helpers
  // ---------------------------------------------------------------------------

  /// Gets a map of all dashboard widgets keyed by their ID.
  ///
  /// For PortAndSpeed, a default configuration is used.
  Map<String, Widget> get _allWidgets => {
        DashboardWidgetSpecs.internetStatus.id: internetWidget,
        DashboardWidgetSpecs.networks.id: networksWidget,
        DashboardWidgetSpecs.wifiGrid.id: wifiGrid,
        DashboardWidgetSpecs.quickPanel.id: quickPanel,
        // Use a default config for PortAndSpeed in flexible layouts
        DashboardWidgetSpecs.portAndSpeed.id: buildPortAndSpeed(
          const PortAndSpeedConfig(
            direction: null, // Auto-detect
            showSpeedTest: true,
          ),
        ),
        if (vpnTile != null) DashboardWidgetSpecs.vpn.id: vpnTile!,
      };

  /// Get a widget by its ID.
  Widget? getWidgetById(String id) => _allWidgets[id];

  /// Get ordered list of visible widget specs.
  List<WidgetSpec> get orderedVisibleSpecs {
    final widgets = _allWidgets;

    // 1. Get ordered specs from configs
    final orderedSpecs = DashboardWidgetSpecs.standardWidgets.toList()
      ..sort((a, b) {
        final configA = getConfigFor(a);
        final configB = getConfigFor(b);
        return configA.order.compareTo(configB.order);
      });

    // 2. Filter visible
    return orderedSpecs.where((spec) {
      final config = getConfigFor(spec);
      // Only show if visible AND widget exists (e.g. VPN might be null)
      return config.visible && widgets.containsKey(spec.id);
    }).toList();
  }

  /// Gets the list of visible widgets, ordered and wrapped with constraints.
  ///
  /// This is the primary method for flexible layout strategies.
  List<Widget> get orderedVisibleWidgets {
    // 1. Get ordered specs from configs
    final orderedSpecs = DashboardWidgetSpecs.standardWidgets.toList()
      ..sort((a, b) {
        final configA = getConfigFor(a);
        final configB = getConfigFor(b);
        return configA.order.compareTo(configB.order);
      });

    // 2. Filter visible & wrap
    return orderedSpecs.where((spec) {
      final config = getConfigFor(spec);
      return config.visible;
    }).map((spec) {
      final child = _getStandardWidgetById(spec.id);
      if (child == null) return const SizedBox.shrink();

      // Wrap based on mode constraints
      // For Standard Layout, we provide a basic minHeight to ensure visibility
      // The actual height is determined by the content (Standard Layout is usually a Column/ListView)
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 120),
        child: child,
      );
    }).toList();
  }

  Widget? _getStandardWidgetById(String id) {
    if (id == DashboardWidgetSpecs.internetStatus.id) return internetWidget;
    if (id == DashboardWidgetSpecs.networks.id) return networksWidget;
    if (id == DashboardWidgetSpecs.wifiGrid.id) return wifiGrid;
    if (id == DashboardWidgetSpecs.quickPanel.id) return quickPanel;
    if (id == DashboardWidgetSpecs.vpn.id) return vpnTile;
    if (id == DashboardWidgetSpecs.portAndSpeed.id) {
      // For standard layouts in ordered list (e.g. mobile), use default config
      return buildPortAndSpeed(const PortAndSpeedConfig());
    }
    return null;
  }
}
