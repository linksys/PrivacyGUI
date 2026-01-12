import 'display_mode.dart';
import 'height_strategy.dart';
import 'widget_grid_constraints.dart';
import 'widget_spec.dart';

/// Dashboard 所有元件的規格定義
///
/// 定義各元件在不同 [DisplayMode] 下的 grid 約束。
/// 所有 column 數值基於 12-column 設計。
abstract class DashboardWidgetSpecs {
  DashboardWidgetSpecs._();

  // ---------------------------------------------------------------------------
  // Internet Status
  // ---------------------------------------------------------------------------
  static const internetStatus = WidgetSpec(
    id: 'internet_status',
    displayName: 'Internet Status',
    constraints: {
      DisplayMode.compact: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(2.0),
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 6,
        maxColumns: 8,
        preferredColumns: 8,
        heightStrategy: HeightStrategy.strict(4.0),
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 8,
        maxColumns: 12,
        preferredColumns: 12,
        heightStrategy: HeightStrategy.strict(4.0),
      ),
    },
  );

  // ---------------------------------------------------------------------------
  // Networks (節點狀態)
  // ---------------------------------------------------------------------------
  static const networks = WidgetSpec(
    id: 'networks',
    displayName: 'Networks',
    constraints: {
      DisplayMode.compact: WidgetGridConstraints(
        minColumns: 3,
        maxColumns: 4,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(2.0),
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 4,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(6.0),
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(8.0),
      ),
    },
  );

  // ---------------------------------------------------------------------------
  // WiFi Grid
  // ---------------------------------------------------------------------------
  static const wifiGrid = WidgetSpec(
    id: 'wifi_grid',
    displayName: 'Wi-Fi Networks',
    constraints: {
      DisplayMode.compact: WidgetGridConstraints(
        minColumns: 6,
        maxColumns: 8,
        preferredColumns: 8,
        heightStrategy: HeightStrategy.strict(2.0),
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 8,
        maxColumns: 12,
        preferredColumns: 8,
        heightStrategy:
            HeightStrategy.strict(5.0), // 2 rows of cards (176px * 2 + spacing)
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 12,
        maxColumns: 12,
        preferredColumns: 12,
        heightStrategy: HeightStrategy.strict(6.0),
      ),
    },
  );

  // ---------------------------------------------------------------------------
  // Quick Panel
  // ---------------------------------------------------------------------------
  static const quickPanel = WidgetSpec(
    id: 'quick_panel',
    displayName: 'Quick Panel',
    constraints: {
      DisplayMode.compact: WidgetGridConstraints(
        minColumns: 3,
        maxColumns: 4,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(2.0),
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 4,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(4.0),
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(4.0),
      ),
    },
  );

  // ---------------------------------------------------------------------------
  // Port and Speed
  // ---------------------------------------------------------------------------
  static const portAndSpeed = WidgetSpec(
    id: 'port_and_speed',
    displayName: 'Ports & Speed',
    constraints: {
      DisplayMode.compact: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(2.0),
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 8,
        preferredColumns: 8,
        heightStrategy: HeightStrategy.strict(4.0),
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 8,
        maxColumns: 12,
        preferredColumns: 8,
        heightStrategy: HeightStrategy.strict(4.0),
      ),
    },
  );

  // ---------------------------------------------------------------------------
  // Standard Widgets (used in Standard Layout)
  // ---------------------------------------------------------------------------
  static const List<WidgetSpec> standardWidgets = [
    internetStatus,
    networks,
    wifiGrid,
    quickPanel,
    portAndSpeed,
    vpn,
  ];

  // ---------------------------------------------------------------------------
  // Atomic Widgets (used in Custom/Bento Layout)
  // ---------------------------------------------------------------------------

  /// Internet status only (online/offline, geolocation, uptime)
  static const internetStatusOnly = WidgetSpec(
    id: 'internet_status_only',
    displayName: 'Internet Status',
    constraints: {
      DisplayMode.compact: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(1.0),
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(2.0),
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(2.0),
      ),
    },
  );

  /// Master node info (router image, model, serial, firmware)
  static const masterNodeInfo = WidgetSpec(
    id: 'master_node_info',
    displayName: 'Master Router',
    constraints: {
      DisplayMode.compact: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(2.0),
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(3.0),
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 6,
        maxColumns: 12,
        preferredColumns: 8,
        heightStrategy: HeightStrategy.strict(4.0),
      ),
    },
  );

  /// Ports status (LAN + WAN)
  static const ports = WidgetSpec(
    id: 'ports',
    displayName: 'Ports',
    constraints: {
      DisplayMode.compact: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(2.0),
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(3.0),
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 6,
        maxColumns: 12,
        preferredColumns: 8,
        heightStrategy: HeightStrategy.strict(4.0),
      ),
    },
  );

  /// Speed test results
  static const speedTest = WidgetSpec(
    id: 'speed_test',
    displayName: 'Speed Test',
    constraints: {
      DisplayMode.compact: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(2.0),
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(3.0),
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 6,
        maxColumns: 12,
        preferredColumns: 8,
        heightStrategy: HeightStrategy.strict(4.0),
      ),
    },
  );

  /// Network stats (nodes/devices count)
  static const networkStats = WidgetSpec(
    id: 'network_stats',
    displayName: 'Network Stats',
    constraints: {
      DisplayMode.compact: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(1.0),
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(2.0),
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(2.0),
      ),
    },
  );

  /// Mesh topology tree view
  static const topology = WidgetSpec(
    id: 'topology',
    displayName: 'Topology',
    constraints: {
      DisplayMode.compact: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(3.0),
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(4.0),
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 6,
        maxColumns: 12,
        preferredColumns: 8,
        heightStrategy: HeightStrategy.strict(6.0),
      ),
    },
  );

  /// Custom layout widgets (atomic components)
  static const List<WidgetSpec> customWidgets = [
    internetStatusOnly,
    masterNodeInfo,
    ports,
    speedTest,
    networkStats,
    topology,
    wifiGrid,
    quickPanel,
    vpn,
  ];

  // ---------------------------------------------------------------------------
  // 所有規格列表（用於設定 UI 迭代）
  // ---------------------------------------------------------------------------
  static const List<WidgetSpec> all = [
    internetStatus,
    networks,
    wifiGrid,
    quickPanel,
    portAndSpeed,
    vpn,
    // Atomic widgets
    internetStatusOnly,
    masterNodeInfo,
    ports,
    speedTest,
    networkStats,
    topology,
  ];

  // ---------------------------------------------------------------------------
  // VPN (if supported)
  // ---------------------------------------------------------------------------
  static const vpn = WidgetSpec(
    id: 'vpn',
    displayName: 'VPN',
    constraints: {
      DisplayMode.compact: WidgetGridConstraints(
        minColumns: 3,
        maxColumns: 4,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(2.0),
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 4,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.strict(4.0),
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(4.0),
      ),
    },
  );

  /// 根據 ID 查詢規格
  static WidgetSpec? getById(String id) {
    for (final spec in all) {
      if (spec.id == id) return spec;
    }
    return null;
  }
}
