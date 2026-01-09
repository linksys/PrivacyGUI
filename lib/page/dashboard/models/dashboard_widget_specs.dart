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
        heightStrategy: HeightStrategy.intrinsic(),
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 6,
        maxColumns: 8,
        preferredColumns: 8,
        heightStrategy: HeightStrategy.intrinsic(),
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 8,
        maxColumns: 12,
        preferredColumns: 12,
        heightStrategy: HeightStrategy.intrinsic(),
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
        heightStrategy: HeightStrategy.intrinsic(),
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 4,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.intrinsic(),
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.intrinsic(),
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
        heightStrategy: HeightStrategy.aspectRatio(4.0), // 橫向卡片
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 8,
        maxColumns: 12,
        preferredColumns: 8,
        heightStrategy: HeightStrategy.intrinsic(),
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 12,
        maxColumns: 12,
        preferredColumns: 12,
        heightStrategy: HeightStrategy.intrinsic(),
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
        heightStrategy: HeightStrategy.intrinsic(),
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 4,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.intrinsic(),
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.intrinsic(),
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
        heightStrategy: HeightStrategy.intrinsic(),
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 8,
        preferredColumns: 8,
        heightStrategy: HeightStrategy.intrinsic(),
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 8,
        maxColumns: 12,
        preferredColumns: 8,
        heightStrategy: HeightStrategy.intrinsic(),
      ),
    },
  );

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
        heightStrategy: HeightStrategy.intrinsic(),
      ),
      DisplayMode.normal: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 4,
        preferredColumns: 4,
        heightStrategy: HeightStrategy.intrinsic(),
      ),
      DisplayMode.expanded: WidgetGridConstraints(
        minColumns: 4,
        maxColumns: 6,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.intrinsic(),
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
