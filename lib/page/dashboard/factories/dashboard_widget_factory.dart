import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../a2ui/registry/a2ui_widget_registry.dart';
import '../a2ui/renderer/a2ui_widget_renderer.dart';
import '../models/dashboard_widget_specs.dart';
import '../models/display_mode.dart';
import '../models/widget_spec.dart';
import '../strategies/dashboard_layout_context.dart'; // For PortAndSpeedConfig
import '../views/components/_components.dart';

/// Unified Dashboard Widget Factory
///
/// Centralized management for:
/// - Widget ID → Widget mapping
/// - AppCard wrapping rules
/// - DisplayMode handling
/// - A2UI widget support
class DashboardWidgetFactory {
  DashboardWidgetFactory._();

  /// Builds an atomic widget based on ID and DisplayMode.
  ///
  /// First tries native widgets, then falls back to A2UI widgets if [ref] is provided.
  static Widget? buildAtomicWidget(
    String id, {
    DisplayMode displayMode = DisplayMode.normal,
    A2UIWidgetRegistry? registry,
  }) {
    // 1. Try native widget first
    final nativeWidget = _buildNativeWidget(id, displayMode);
    if (nativeWidget != null) return nativeWidget;

    // 2. Try A2UI widget if registry is available
    if (registry != null) {
      if (registry.contains(id)) {
        return A2UIWidgetRenderer(widgetId: id, displayMode: displayMode);
      }
    }

    return null;
  }

  /// Builds a native (non-A2UI) widget.
  static Widget? _buildNativeWidget(String id, DisplayMode displayMode) {
    return switch (id) {
      // --- Custom Layout Widgets ---
      'internet_status_only' => CustomInternetStatus(displayMode: displayMode),
      'master_node_info' => CustomMasterNodeInfo(displayMode: displayMode),
      'ports' => CustomPorts(displayMode: displayMode),
      'speed_test' => CustomSpeedTest(displayMode: displayMode),
      'network_stats' => CustomNetworkStats(displayMode: displayMode),
      'topology' => CustomTopology(displayMode: displayMode),

      // Isolated Custom Widgets
      'wifi_grid_custom' => CustomWiFiGrid(displayMode: displayMode),
      'quick_panel_custom' => CustomQuickPanel(displayMode: displayMode),
      'vpn_custom' => CustomVPN(displayMode: displayMode),

      // --- Legacy/Standard IDs (Fallback if needed) ---
      'wifi_grid' => CustomWiFiGrid(displayMode: displayMode),
      'quick_panel' => CustomQuickPanel(displayMode: displayMode),
      'vpn' => CustomVPN(displayMode: displayMode),

      // --- Composite Widgets (Standard Layout Only) ---
      'internet_status' => InternetConnectionWidget(displayMode: displayMode),
      'port_and_speed' => DashboardHomePortAndSpeed(
          displayMode: displayMode,
          config: const PortAndSpeedConfig(
            direction: null,
            showSpeedTest: true,
          ),
        ),
      'networks' => DashboardNetworks(displayMode: displayMode),
      _ => null,
    };
  }

  /// Determines if this widget should be wrapped in an AppCard.
  ///
  /// Some widgets (like WiFi Grid, VPN) manage their own card styling.
  /// A2UI widgets always wrap in AppCard.
  static bool shouldWrapInCard(String id, {WidgetRef? ref}) {
    // Check if it's a native widget that shouldn't wrap
    final noWrap = switch (id) {
      'wifi_grid' => true,
      'wifi_grid_custom' => true,
      'vpn' => true,
      'vpn_custom' => true,
      _ => false,
    };

    if (noWrap) return false;

    // A2UI widgets and all other widgets should wrap in AppCard
    return true;
  }

  /// Gets the widget spec (used for constraint lookup).
  ///
  /// Checks native specs first, then A2UI registry if [ref] is provided.
  static WidgetSpec? getSpec(String id, {A2UIWidgetRegistry? registry}) {
    // Try native spec first
    final nativeSpec = DashboardWidgetSpecs.getById(id);
    if (nativeSpec != null) return nativeSpec;

    // Try A2UI spec
    if (registry != null) {
      final a2uiDef = registry.get(id);
      if (a2uiDef != null) {
        return a2uiDef.toWidgetSpec();
      }
    }

    return null;
  }
}
