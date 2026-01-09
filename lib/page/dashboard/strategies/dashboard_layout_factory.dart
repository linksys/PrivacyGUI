import 'package:privacy_gui/page/dashboard/models/dashboard_layout.dart';

import 'dashboard_layout_strategy.dart';
import 'mobile_layout_strategy.dart';
import 'desktop_horizontal_layout_strategy.dart';
import 'desktop_vertical_layout_strategy.dart';
import 'desktop_no_lan_ports_layout_strategy.dart';
import 'tablet_layout_strategy.dart';
import 'tablet_horizontal_layout_strategy.dart';
import 'tablet_vertical_layout_strategy.dart';

/// Factory for creating layout strategies based on variant.
///
/// Strategies are cached as const singletons since they are stateless.
/// This provides O(1) lookup with zero allocation overhead.
class DashboardLayoutFactory {
  DashboardLayoutFactory._();

  /// Map of variant to strategy singleton instances.
  static const _strategies = <DashboardLayoutVariant, DashboardLayoutStrategy>{
    DashboardLayoutVariant.mobile: MobileLayoutStrategy(),
    DashboardLayoutVariant.desktopHorizontal: DesktopHorizontalLayoutStrategy(),
    DashboardLayoutVariant.desktopVertical: DesktopVerticalLayoutStrategy(),
    DashboardLayoutVariant.desktopNoLanPorts: DesktopNoLanPortsLayoutStrategy(),
    DashboardLayoutVariant.tablet: TabletLayoutStrategy(),
    DashboardLayoutVariant.tabletHorizontal: TabletHorizontalLayoutStrategy(),
    DashboardLayoutVariant.tabletVertical: TabletVerticalLayoutStrategy(),
  };

  /// Creates (or retrieves) the strategy for the given variant.
  ///
  /// Since strategies are stateless, this always returns the same instance
  /// for a given variant.
  static DashboardLayoutStrategy create(DashboardLayoutVariant variant) {
    final strategy = _strategies[variant];
    assert(strategy != null, 'No strategy registered for variant: $variant');
    return strategy!;
  }
}
