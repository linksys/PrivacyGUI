import 'package:flutter/widgets.dart';
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
class DashboardWidgetFactory {
  DashboardWidgetFactory._();

  /// Builds an atomic widget based on ID and DisplayMode.
  static Widget? buildAtomicWidget(
    String id, {
    DisplayMode displayMode = DisplayMode.normal,
  }) {
    // Note: Standard Widgets use the same classes as Custom Widgets for now,
    // but they are instantiated with different context in DashboardHomeView.
    // For Custom Layout (where this factory is primarily used), we map IDs to widgets.

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

      // --- Legacy/Standard IDs (Fallback if needed, or if shared logic remains) ---
      'wifi_grid' =>
        CustomWiFiGrid(displayMode: displayMode), // Keep for safety
      'quick_panel' =>
        CustomQuickPanel(displayMode: displayMode), // Keep for safety
      'vpn' => CustomVPN(displayMode: displayMode), // Keep for safety

      // --- Composite Widgets (Standard Layout Only - usually not built via this factory) ---
      'internet_status' => InternetConnectionWidget(displayMode: displayMode),
      'port_and_speed' => DashboardHomePortAndSpeed(
          displayMode: displayMode,
          config: const PortAndSpeedConfig(
            direction: null, // Auto-detect based on width
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
  static bool shouldWrapInCard(String id) {
    return switch (id) {
      'wifi_grid' => false,
      'wifi_grid_custom' => false,
      'vpn' => false,
      'vpn_custom' => false,
      _ => true,
    };
  }

  /// Gets the widget spec (used for constraint lookup).
  static WidgetSpec? getSpec(String id) {
    return DashboardWidgetSpecs.getById(id);
  }
}
