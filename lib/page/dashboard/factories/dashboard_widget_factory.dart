import 'package:flutter/widgets.dart';
import '../models/dashboard_widget_specs.dart';
import '../models/display_mode.dart';
import '../models/widget_spec.dart';
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
    return switch (id) {
      'internet_status' => InternetConnectionWidget(displayMode: displayMode),
      'internet_status_only' => CustomInternetStatus(displayMode: displayMode),
      'master_node_info' => CustomMasterNodeInfo(displayMode: displayMode),
      'ports' => CustomPorts(displayMode: displayMode),
      'speed_test' => CustomSpeedTest(displayMode: displayMode),
      'network_stats' => CustomNetworkStats(displayMode: displayMode),
      'topology' => CustomTopology(displayMode: displayMode),
      'wifi_grid' => CustomWiFiGrid(displayMode: displayMode),
      'quick_panel' => CustomQuickPanel(displayMode: displayMode),
      _ => null,
    };
  }

  /// Determines if this widget should be wrapped in an AppCard.
  ///
  /// Some widgets (like WiFi Grid, VPN) manage their own card styling.
  static bool shouldWrapInCard(String id) {
    return switch (id) {
      'wifi_grid' => false,
      'vpn' => false,
      _ => true,
    };
  }

  /// Gets the widget spec (used for constraint lookup).
  static WidgetSpec? getSpec(String id) {
    return DashboardWidgetSpecs.getById(id);
  }
}
