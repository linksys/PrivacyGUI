import 'package:flutter/material.dart';
import 'package:privacy_gui/page/dashboard/providers/layout_item_factory.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';

import 'usp_widget_specs.dart';

/// Available dashboard layout presets.
///
/// Each preset defines a curated set of dashboard cards and a hand-crafted
/// layout optimised for its use case. Users pick a preset as a starting point
/// and can further customise via drag-drop editing.
enum UspDashboardPreset {
  essential,
  standard,
  professional,
  monitoring,
}

extension UspDashboardPresetX on UspDashboardPreset {
  String get displayName => switch (this) {
        UspDashboardPreset.essential => 'Essential',
        UspDashboardPreset.standard => 'Standard',
        UspDashboardPreset.professional => 'Professional',
        UspDashboardPreset.monitoring => 'Monitoring',
      };

  String get description => switch (this) {
        UspDashboardPreset.essential =>
          'Core network info — ideal for everyday users',
        UspDashboardPreset.standard =>
          'Common features at a glance — recommended',
        UspDashboardPreset.professional =>
          'All cards enabled — for power users',
        UspDashboardPreset.monitoring =>
          'Performance & analytics focused — for network admins',
      };

  IconData get icon => switch (this) {
        UspDashboardPreset.essential => Icons.dashboard_outlined,
        UspDashboardPreset.standard => Icons.grid_view,
        UspDashboardPreset.professional => Icons.tune,
        UspDashboardPreset.monitoring => Icons.monitor_heart,
      };

  /// Card IDs included in this preset.
  List<String> get cardIds => switch (this) {
        UspDashboardPreset.essential => const [
            'stats_panel',
            'device_info',
            'network_status',
            'lan_info',
            'connected_devices',
            'wifi_status',
          ],
        UspDashboardPreset.standard => const [
            'stats_panel',
            'device_info',
            'network_status',
            'topology',
            'lan_info',
            'ethernet_ports',
            'system_status',
            'connected_devices',
            'wifi_status',
            'time_settings',
            'traffic_analysis',
            'firewall_overview',
          ],
        UspDashboardPreset.professional => const [
            'stats_panel',
            'device_info',
            'network_status',
            'topology',
            'lan_info',
            'ethernet_ports',
            'system_status',
            'connected_devices',
            'wifi_status',
            'time_settings',
            'dhcp_reservations',
            'port_forwarding',
            'network_health',
            'firewall_overview',
            'wifi_performance',
            'traffic_analysis',
            'device_analytics',
          ],
        UspDashboardPreset.monitoring => const [
            'stats_panel',
            'network_health',
            'system_status',
            'traffic_analysis',
            'device_analytics',
            'wifi_performance',
            'firewall_overview',
            'ethernet_ports',
          ],
      };

  /// Creates a hand-crafted layout optimised for this preset's use case.
  List<LayoutItem> createLayout() => switch (this) {
        UspDashboardPreset.essential => _essentialLayout(),
        UspDashboardPreset.standard => _standardLayout(),
        UspDashboardPreset.professional => _professionalLayout(),
        UspDashboardPreset.monitoring => _monitoringLayout(),
      };
}

// Helper to shorten spec lookup + LayoutItem creation.
LayoutItem _item(String id, {required int x, required int y, int? w, int? h}) {
  return LayoutItemFactory.fromSpec(
    UspWidgetSpecs.getById(id)!,
    x: x,
    y: y,
    w: w,
    h: h,
  );
}

/// Essential: 6 cards — core network info, minimal clutter.
///
/// ```
/// y=0:  StatsPanel (12×1)
/// y=1:  DeviceInfo (6×3)          | NetworkStatus (6×3)
/// y=4:  LanInfo (6×3)             | ConnectedDevices (6×4)
/// y=8:  WiFiStatus (12×6)
/// ```
List<LayoutItem> _essentialLayout() => [
      _item('stats_panel', x: 0, y: 0, w: 12, h: 1),
      _item('device_info', x: 0, y: 1, w: 6, h: 3),
      _item('network_status', x: 6, y: 1, w: 6, h: 3),
      _item('lan_info', x: 0, y: 4, w: 6, h: 3),
      _item('connected_devices', x: 6, y: 4, w: 6, h: 4),
      _item('wifi_status', x: 0, y: 8, w: 12, h: 6),
    ];

/// Standard: 12 cards — common features at a glance.
///
/// ```
/// y=0:  StatsPanel (12×1)
/// y=1:  DeviceInfo (6×3)          | NetworkStatus (6×3)
/// y=4:  Topology (12×5)
/// y=9:  LanInfo (6×3)             | EthernetPorts (6×3)
/// y=12: SystemStatus (6×5)        | TrafficAnalysis (6×5)
/// y=17: ConnectedDevices (6×4)    | WiFiStatus (6×6)
/// y=23: TimeSettings (6×3)        | FirewallOverview (6×4)
/// ```
List<LayoutItem> _standardLayout() => [
      _item('stats_panel', x: 0, y: 0, w: 12, h: 1),
      _item('device_info', x: 0, y: 1, w: 6, h: 3),
      _item('network_status', x: 6, y: 1, w: 6, h: 3),
      _item('topology', x: 0, y: 4, w: 12, h: 5),
      _item('lan_info', x: 0, y: 9, w: 6, h: 3),
      _item('ethernet_ports', x: 6, y: 9, w: 6, h: 3),
      _item('system_status', x: 0, y: 12, w: 6, h: 5),
      _item('traffic_analysis', x: 6, y: 12, w: 6, h: 5),
      _item('connected_devices', x: 0, y: 17, w: 6, h: 4),
      _item('wifi_status', x: 6, y: 17, w: 6, h: 6),
      _item('time_settings', x: 0, y: 23, w: 6, h: 2),
      _item('firewall_overview', x: 6, y: 23, w: 6, h: 4),
    ];

/// Professional: all 17 cards — full feature set.
///
/// ```
/// y=0:  StatsPanel (12×1)
/// y=1:  DeviceInfo (6×3)          | NetworkStatus (6×3)
/// y=4:  NetworkHealth (6×4)       | SystemStatus (6×5)
/// y=9:  TrafficAnalysis (6×5)     | LanInfo (6×3)
/// y=14: EthernetPorts (6×3)       | ConnectedDevices (6×4)
/// y=18: Topology (6×5)            | DeviceAnalytics (6×5)
/// y=23: WiFiStatus (6×6)          | WiFiPerformance (6×5)
/// y=29: FirewallOverview (6×4)    | TimeSettings (6×3)
/// y=33: DhcpReservations (6×4)    | PortForwarding (6×4)
/// ```
List<LayoutItem> _professionalLayout() => [
      _item('stats_panel', x: 0, y: 0, w: 12, h: 1),
      _item('device_info', x: 0, y: 1, w: 6, h: 3),
      _item('network_status', x: 6, y: 1, w: 6, h: 3),
      _item('network_health', x: 0, y: 4, w: 6, h: 4),
      _item('system_status', x: 6, y: 4, w: 6, h: 5),
      _item('traffic_analysis', x: 0, y: 9, w: 6, h: 5),
      _item('lan_info', x: 6, y: 9, w: 6, h: 3),
      _item('ethernet_ports', x: 0, y: 14, w: 6, h: 3),
      _item('connected_devices', x: 6, y: 14, w: 6, h: 4),
      _item('topology', x: 0, y: 18, w: 6, h: 5),
      _item('device_analytics', x: 6, y: 18, w: 6, h: 5),
      _item('wifi_status', x: 0, y: 23, w: 6, h: 6),
      _item('wifi_performance', x: 6, y: 23, w: 6, h: 5),
      _item('firewall_overview', x: 0, y: 29, w: 6, h: 4),
      _item('time_settings', x: 6, y: 29, w: 6, h: 2),
      _item('dhcp_reservations', x: 0, y: 33, w: 6, h: 4),
      _item('port_forwarding', x: 6, y: 33, w: 6, h: 4),
    ];

/// Monitoring: 8 cards — performance & analytics prominent.
///
/// ```
/// y=0:  StatsPanel (12×1)
/// y=1:  TrafficAnalysis (12×5)
/// y=6:  NetworkHealth (6×4)       | SystemStatus (6×5)
/// y=11: DeviceAnalytics (6×5)     | WiFiPerformance (6×5)
/// y=16: FirewallOverview (6×4)    | EthernetPorts (6×3)
/// ```
List<LayoutItem> _monitoringLayout() => [
      _item('stats_panel', x: 0, y: 0, w: 12, h: 1),
      _item('traffic_analysis', x: 0, y: 1, w: 12, h: 5),
      _item('network_health', x: 0, y: 6, w: 6, h: 4),
      _item('system_status', x: 6, y: 6, w: 6, h: 5),
      _item('device_analytics', x: 0, y: 11, w: 6, h: 5),
      _item('wifi_performance', x: 6, y: 11, w: 6, h: 5),
      _item('firewall_overview', x: 0, y: 16, w: 6, h: 4),
      _item('ethernet_ports', x: 6, y: 16, w: 6, h: 3),
    ];
