import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
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
  // h values sized for fixed slot height: 100px per row
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
        heightStrategy: HeightStrategy.strict(3),
        minHeightRows: 2,
        maxHeightRows: 5,
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
        heightStrategy: HeightStrategy.strict(5),
        minHeightRows: 4,
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
        maxHeightRows: 5,
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

  static const deviceAnalytics = WidgetSpec(
    id: 'device_analytics',
    displayName: 'Device Analytics',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 12,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(5),
        minHeightRows: 4,
        maxHeightRows: 8,
      ),
    },
  );

  static const networkHealth = WidgetSpec(
    id: 'network_health',
    displayName: 'Network Health',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 3,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(4),
        minHeightRows: 3,
        maxHeightRows: 6,
      ),
    },
  );

  static const firewallOverview = WidgetSpec(
    id: 'firewall_overview',
    displayName: 'Firewall Overview',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 3,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(4),
        minHeightRows: 3,
        maxHeightRows: 6,
      ),
    },
  );

  static const wifiPerformance = WidgetSpec(
    id: 'wifi_performance',
    displayName: 'WiFi Performance',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(5),
        minHeightRows: 4,
        maxHeightRows: 8,
      ),
    },
  );

  static const trafficAnalysis = WidgetSpec(
    id: 'traffic_analysis',
    displayName: 'Traffic Analysis',
    constraints: {
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 12,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(5),
        minHeightRows: 4,
        maxHeightRows: 8,
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
    networkHealth,
    firewallOverview,
    wifiPerformance,
    trafficAnalysis,
    deviceAnalytics,
  ];

  static WidgetSpec? getById(String id) {
    for (final spec in all) {
      if (spec.id == id) return spec;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Layout Scaling
  // ---------------------------------------------------------------------------

  /// Proportionally scales a serialised layout from [fromCols] to [toCols].
  ///
  /// * Tablet (12→8): `w=6` → `w=4`, preserving two-column pairs.
  /// * Mobile (12→4): all items become full-width (`w=toCols`) for
  ///   single-column stacking — `compact()` then resolves y positions.
  /// * Constraints (minW / maxW) are scaled accordingly.
  static List<dynamic> scaleLayout(
    List<dynamic> layout,
    int fromCols,
    int toCols,
  ) {
    return layout.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      final x = map['x'] as int;
      final w = map['w'] as int;
      final minW = map['minW'] as int? ?? 1;
      final maxW = (map['maxW'] as num?)?.toInt() ?? fromCols;

      int newW;
      int newX;

      if (toCols <= 4) {
        // Mobile: full-width single-column
        newW = toCols;
        newX = 0;
      } else {
        // Proportional scaling
        newW = (w * toCols / fromCols).round().clamp(1, toCols);
        newX = (x * toCols / fromCols).round();
        if (newX + newW > toCols) newX = toCols - newW;
        if (newX < 0) {
          newX = 0;
          newW = toCols;
        }
      }

      final newMinW = (minW * toCols / fromCols).round().clamp(1, toCols);
      final newMaxW = (maxW * toCols / fromCols).round().clamp(newMinW, toCols);

      return {
        ...map,
        'x': newX,
        'w': newW,
        'minW': newMinW,
        'maxW': newMaxW.toDouble(),
      };
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Default Layout
  // ---------------------------------------------------------------------------

  /// Creates the default 2-column layout for the USP Dashboard.
  ///
  /// Each card uses w=6 (half of 12-column grid).
  /// h values sized for fixed slot height: 120px per row.
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
  static List<LayoutItem> createDefaultLayout() {
    return createLayoutForCards(all.map((s) => s.id).toList());
  }

  /// Creates a 2-column layout for the given [cardIds].
  ///
  /// * `stats_panel` is always placed full-width (12 cols) if present.
  /// * Remaining cards are placed in 6-col pairs, auto-calculating y.
  /// * Uses each spec's preferred height from its `HeightStrategy`.
  static List<LayoutItem> createLayoutForCards(List<String> cardIds) {
    final items = <LayoutItem>[];
    int y = 0;

    // stats_panel first (full width) if present
    if (cardIds.contains('stats_panel')) {
      final spec = getById('stats_panel')!;
      items.add(LayoutItemFactory.fromSpec(spec, x: 0, y: y, w: 12));
      y += items.last.h;
    }

    // Remaining cards in 6-col pairs
    final remaining = cardIds.where((id) => id != 'stats_panel').toList();
    for (int i = 0; i < remaining.length; i += 2) {
      final leftSpec = getById(remaining[i]);
      if (leftSpec == null) continue;
      final leftItem = LayoutItemFactory.fromSpec(leftSpec, x: 0, y: y, w: 6);
      items.add(leftItem);

      int rowHeight = leftItem.h;

      if (i + 1 < remaining.length) {
        final rightSpec = getById(remaining[i + 1]);
        if (rightSpec != null) {
          final rightItem =
              LayoutItemFactory.fromSpec(rightSpec, x: 6, y: y, w: 6);
          items.add(rightItem);
          if (rightItem.h > rowHeight) rowHeight = rightItem.h;
        }
      }

      y += rowHeight;
    }

    return items;
  }
}
