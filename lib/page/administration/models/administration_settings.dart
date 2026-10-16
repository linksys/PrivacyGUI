import 'package:equatable/equatable.dart';

/// User-editable settings on the Advanced Settings → Administration page.
///
/// UPnP (#1660), SIP ALG (#1694) and management over Wi-Fi (#1696). 1.x's page
/// also held Express Forwarding, which stays in #875.
class AdministrationSettings extends Equatable {
  /// `Device.UPnP.Device.Enable`.
  final bool upnpEnabled;

  /// `Device.Firewall.ConnectionTracking.SIP.Enable` (linksys/FWDEV#217).
  final bool sipAlgEnabled;

  /// `Enable` of the `Device.Firewall.Chain.1.Rule.{i}` whose `Description` is
  /// `RULE_MGMT_WIFI_ACCESS` (linksys/FWDEV#216): whether a Wi-Fi client can
  /// open this GUI. Null when the read succeeded and the firmware has no such
  /// rule, which hides the switch; a failed read never lands here.
  final bool? mgmtWifiEnabled;

  const AdministrationSettings({
    required this.upnpEnabled,
    required this.sipAlgEnabled,
    required this.mgmtWifiEnabled,
  });

  const AdministrationSettings.empty()
      : upnpEnabled = false,
        sipAlgEnabled = false,
        mgmtWifiEnabled = null;

  /// [mgmtWifiEnabled] can only be changed, never cleared: whether the rule
  /// exists is the firmware's, not an edit.
  AdministrationSettings copyWith({
    bool? upnpEnabled,
    bool? sipAlgEnabled,
    bool? mgmtWifiEnabled,
  }) =>
      AdministrationSettings(
        upnpEnabled: upnpEnabled ?? this.upnpEnabled,
        sipAlgEnabled: sipAlgEnabled ?? this.sipAlgEnabled,
        mgmtWifiEnabled: mgmtWifiEnabled ?? this.mgmtWifiEnabled,
      );

  @override
  List<Object?> get props => [upnpEnabled, sipAlgEnabled, mgmtWifiEnabled];
}
