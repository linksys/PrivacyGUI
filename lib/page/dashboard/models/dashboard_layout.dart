/// Defines the different layout variants for the dashboard.
/// Used to determine how components should arrange themselves.
enum DashboardLayoutVariant {
  /// Mobile layout - single column, all components stacked vertically
  mobile,

  /// Desktop layout with horizontal emphasis - left column expanded
  desktopHorizontal,

  /// Desktop layout with vertical emphasis - shows port info in left column
  desktopVertical,

  /// Desktop layout for devices without LAN ports
  desktopNoLanPorts,

  /// Tablet layout - optimized for mid-size screens (flexible 2-column)
  tablet,
}

/// Extension to provide utility methods for DashboardLayoutVariant
extension DashboardLayoutVariantX on DashboardLayoutVariant {
  /// Returns true if this is a desktop layout variant
  bool get isDesktop => this != DashboardLayoutVariant.mobile;

  /// Returns true if this is the mobile layout
  bool get isMobile => this == DashboardLayoutVariant.mobile;
}
