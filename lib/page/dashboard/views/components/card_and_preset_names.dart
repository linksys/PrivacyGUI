import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/models/usp_dashboard_preset.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';

/// A dashboard card's name in the user's language (#1312).
///
/// [WidgetSpec]s are `const`, so their [WidgetSpec.displayName] cannot be
/// translated where it is declared. The name is resolved here, at the render
/// site, by [WidgetSpec.id].
///
/// A card whose name is also its own title reuses that key, so the settings
/// list and the card read the same in every language. The other four have keys
/// of their own.
extension WidgetSpecName on WidgetSpec {
  /// The localized name of a built-in card, or [displayName] for an id with no
  /// key — a package widget, whose name comes from a remote template.
  ///
  /// A `switch` over a `String` cannot be exhaustive, so a card added to the
  /// registry without a case here would read its English [displayName] in every
  /// locale. `card_and_preset_names_test.dart` fails on that.
  String resolveName(AppLocalizations l10n) => switch (id) {
        'stats_panel' => l10n.dashboardCardStatsPanel,
        'device_info' => l10n.dashboardCardDeviceInfo,
        'network_status' => l10n.wanStatus,
        'topology' => l10n.networkTopology,
        'lan_info' => l10n.dashboardCardLanInfo,
        'ethernet_ports' => l10n.ethernetPorts,
        'system_status' => l10n.systemStatus,
        'connected_devices' => l10n.connectedDevices,
        'wifi_status' => l10n.wifiStatus,
        'wifi_networks' => l10n.wifiNetworks,
        'time_settings' => l10n.timeSettings,
        'dhcp_reservations' => l10n.dhcpReservations,
        'port_forwarding' => l10n.portForwarding,
        'device_analytics' => l10n.deviceAnalytics,
        'network_health' => l10n.networkHealth,
        'firewall_overview' => l10n.firewallOverview,
        'wifi_performance' => l10n.wifiPerformance,
        'traffic_analysis' => l10n.dashboardCardTrafficAnalysis,
        _ => displayName,
      };
}

/// A dashboard preset's name and description in the user's language (#1312).
///
/// Both switches are exhaustive, so a preset added to [UspDashboardPreset] does
/// not compile until it has keys. That includes `remote`, which no picker
/// offers: skipping it would need a case that returns English.
extension UspDashboardPresetName on UspDashboardPreset {
  /// The preset's name in [l10n]'s language, as the picker and the layout
  /// settings panel show it.
  String resolveName(AppLocalizations l10n) => switch (this) {
        UspDashboardPreset.essential => l10n.dashboardPresetEssential,
        UspDashboardPreset.standard => l10n.dashboardPresetStandard,
        UspDashboardPreset.professional => l10n.dashboardPresetProfessional,
        UspDashboardPreset.monitoring => l10n.dashboardPresetMonitoring,
        UspDashboardPreset.remote => l10n.dashboardPresetRemoteSupport,
      };

  /// The one-line description under the preset's name in the picker, in
  /// [l10n]'s language.
  String resolveDescription(AppLocalizations l10n) => switch (this) {
        UspDashboardPreset.essential => l10n.dashboardPresetEssentialDesc,
        UspDashboardPreset.standard => l10n.dashboardPresetStandardDesc,
        UspDashboardPreset.professional => l10n.dashboardPresetProfessionalDesc,
        UspDashboardPreset.monitoring => l10n.dashboardPresetMonitoringDesc,
        UspDashboardPreset.remote => l10n.dashboardPresetRemoteSupportDesc,
      };
}
