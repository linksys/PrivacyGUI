import 'package:equatable/equatable.dart';

/// User-editable settings on the Advanced Settings → Administration page.
///
/// UPnP (#1660) and SIP ALG (#1694). 1.x's page also held management access and
/// Express Forwarding; those stay in #875.
class AdministrationSettings extends Equatable {
  /// `Device.UPnP.Device.Enable`.
  final bool upnpEnabled;

  /// `Device.Firewall.ConnectionTracking.SIP.Enable` (linksys/FWDEV#217).
  final bool sipAlgEnabled;

  const AdministrationSettings({
    required this.upnpEnabled,
    required this.sipAlgEnabled,
  });

  const AdministrationSettings.empty()
      : upnpEnabled = false,
        sipAlgEnabled = false;

  AdministrationSettings copyWith({bool? upnpEnabled, bool? sipAlgEnabled}) =>
      AdministrationSettings(
        upnpEnabled: upnpEnabled ?? this.upnpEnabled,
        sipAlgEnabled: sipAlgEnabled ?? this.sipAlgEnabled,
      );

  @override
  List<Object?> get props => [upnpEnabled, sipAlgEnabled];
}
