import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/height_strategy.dart';
import 'package:privacy_gui/page/dashboard/models/widget_grid_constraints.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';
import 'package:privacy_gui/page/dashboard/providers/layout_item_factory.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';

/// Widget specifications for all USP Dashboard cards.
///
/// All constraints use DisplayMode.normal only (DisplayMode switching deferred).
/// Column values are based on a 12-column layout.
abstract class UspWidgetSpecs {
  UspWidgetSpecs._();

  // ---------------------------------------------------------------------------
  // Card Specs (2-column default, preferredColumns=6)
  // h values sized for slotAspectRatio: 0.5 (~184px per row)
  // ---------------------------------------------------------------------------

  static const statsPanel = WidgetSpec(
    id: 'stats_panel',
    displayName: 'Stats Panel',
    canHide: false,
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 6,
        maxColumns: 12,
        preferredColumns: 12,
        heightStrategy: HeightStrategy.strict(1),
        minHeightRows: 1,
        maxHeightRows: 2,
      ),
    },
  );

  static const deviceInfo = WidgetSpec(
    id: 'device_info',
    displayName: 'Device Info',
    canHide: false,
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 3,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(3),
        minHeightRows: 2,
        maxHeightRows: 6,
      ),
    },
  );

  static const networkStatus = WidgetSpec(
    id: 'network_status',
    displayName: 'WAN Status',
    canHide: false,
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 3,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(3),
        minHeightRows: 2,
        maxHeightRows: 6,
      ),
    },
  );

  static const topology = WidgetSpec(
    id: 'topology',
    displayName: 'Network Topology',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 12,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(5),
        minHeightRows: 3,
        maxHeightRows: 10,
      ),
    },
  );

  static const lanInfo = WidgetSpec(
    id: 'lan_info',
    displayName: 'LAN Info',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 3,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(2),
        minHeightRows: 2,
        maxHeightRows: 4,
      ),
    },
  );

  static const ethernetPorts = WidgetSpec(
    id: 'ethernet_ports',
    displayName: 'Ethernet Ports',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 3,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(3),
        minHeightRows: 2,
        maxHeightRows: 6,
      ),
    },
  );

  static const systemStatus = WidgetSpec(
    id: 'system_status',
    displayName: 'System Status',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 3,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(4),
        minHeightRows: 3,
        maxHeightRows: 8,
      ),
    },
  );

  static const connectedDevices = WidgetSpec(
    id: 'connected_devices',
    displayName: 'Connected Devices',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 3,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.intrinsic(),
        minHeightRows: 3,
        maxHeightRows: 10,
      ),
    },
  );

  static const wifiStatus = WidgetSpec(
    id: 'wifi_status',
    displayName: 'WiFi Status',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.intrinsic(),
        minHeightRows: 4,
        maxHeightRows: 12,
      ),
    },
  );

  static const timeSettings = WidgetSpec(
    id: 'time_settings',
    displayName: 'Time Settings',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 3,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(2),
        minHeightRows: 2,
        maxHeightRows: 4,
      ),
    },
  );

  static const dhcpReservations = WidgetSpec(
    id: 'dhcp_reservations',
    displayName: 'DHCP Reservations',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.intrinsic(),
        minHeightRows: 3,
        maxHeightRows: 10,
      ),
    },
  );

  static const portForwarding = WidgetSpec(
    id: 'port_forwarding',
    displayName: 'Port Forwarding',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.intrinsic(),
        minHeightRows: 3,
        maxHeightRows: 10,
      ),
    },
  );

  static const connectionStatus = WidgetSpec(
    id: 'connection_status',
    displayName: 'Connection Status',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 2,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(1),
        minHeightRows: 1,
        maxHeightRows: 3,
      ),
    },
  );

  // ---------------------------------------------------------------------------
  // Registry
  // ---------------------------------------------------------------------------

  static const List<WidgetSpec> all = [
    statsPanel,
    deviceInfo,
    networkStatus,
    topology,
    lanInfo,
    ethernetPorts,
    systemStatus,
    connectedDevices,
    wifiStatus,
    timeSettings,
    dhcpReservations,
    portForwarding,
    connectionStatus,
  ];

  static WidgetSpec? getById(String id) {
    for (final spec in all) {
      if (spec.id == id) return spec;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Default Layout
  // ---------------------------------------------------------------------------

  /// Creates the default 2-column layout for the USP Dashboard.
  ///
  /// Each card uses w=6 (half of 12-column grid).
  /// h values sized for slotAspectRatio: 0.5 (~184px per row).
  ///
  /// ```
  /// y=0:  StatsPanel (12×1)
  /// y=1:  DeviceInfo (6×3)       | NetworkStatus (6×3)
  /// y=4:  SystemStatus (6×4)     | LanInfo (6×2)
  /// y=8:  EthernetPorts (6×3)    | ConnectedDevices (6×4)
  /// y=12: WifiStatus (6×5)       | Topology (6×5)
  /// y=17: TimeSettings (6×2)     | ConnectionStatus (6×1)
  /// y=19: DhcpReservations (6×4) | PortForwarding (6×4)
  /// ```
  static List<LayoutItem> createDefaultLayout() {
    return [
      // y=0: Stats Panel (full width)
      LayoutItemFactory.fromSpec(statsPanel, x: 0, y: 0, w: 12, h: 1),

      // y=1: Device Info | Network Status
      LayoutItemFactory.fromSpec(deviceInfo, x: 0, y: 1, w: 6, h: 3),
      LayoutItemFactory.fromSpec(networkStatus, x: 6, y: 1, w: 6, h: 3),

      // y=4: System Status | LAN Info
      LayoutItemFactory.fromSpec(systemStatus, x: 0, y: 4, w: 6, h: 4),
      LayoutItemFactory.fromSpec(lanInfo, x: 6, y: 4, w: 6, h: 2),

      // y=8: Ethernet Ports | Connected Devices
      LayoutItemFactory.fromSpec(ethernetPorts, x: 0, y: 8, w: 6, h: 3),
      LayoutItemFactory.fromSpec(connectedDevices, x: 6, y: 8, w: 6, h: 4),

      // y=12: WiFi Status | Topology
      LayoutItemFactory.fromSpec(wifiStatus, x: 0, y: 12, w: 6, h: 5),
      LayoutItemFactory.fromSpec(topology, x: 6, y: 12, w: 6, h: 5),

      // y=17: Time Settings | Connection Status
      LayoutItemFactory.fromSpec(timeSettings, x: 0, y: 17, w: 6, h: 2),
      LayoutItemFactory.fromSpec(connectionStatus, x: 6, y: 17, w: 6, h: 1),

      // y=19: DHCP Reservations | Port Forwarding
      LayoutItemFactory.fromSpec(dhcpReservations, x: 0, y: 19, w: 6, h: 4),
      LayoutItemFactory.fromSpec(portForwarding, x: 6, y: 19, w: 6, h: 4),
    ];
  }
}
