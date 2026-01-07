import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Configuration for port and speed widget building.
class PortAndSpeedConfig {
  /// Direction of port layout (horizontal or vertical).
  final Axis direction;

  /// Whether to show the speed test section.
  final bool showSpeedTest;

  /// Height for the ports section (null = flexible).
  final double? portsHeight;

  /// Height for the speed test section (null = flexible).
  final double? speedTestHeight;

  /// Padding for the ports section.
  final EdgeInsets portsPadding;

  const PortAndSpeedConfig({
    this.direction = Axis.horizontal,
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
  });

  /// Convenience getter for column width calculation.
  double colWidth(int columns) => context.colWidth(columns);
}
