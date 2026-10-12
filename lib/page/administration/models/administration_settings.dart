import 'package:equatable/equatable.dart';

/// User-editable settings on the Advanced Settings → Administration page.
///
/// UPnP only, for now (#1660). 1.x's page also held management access, ALG and
/// Express Forwarding; those have no FLWRT data model yet and stay in #875.
class AdministrationSettings extends Equatable {
  /// `Device.UPnP.Device.Enable`.
  final bool upnpEnabled;

  const AdministrationSettings({required this.upnpEnabled});

  const AdministrationSettings.empty() : upnpEnabled = false;

  AdministrationSettings copyWith({bool? upnpEnabled}) =>
      AdministrationSettings(upnpEnabled: upnpEnabled ?? this.upnpEnabled);

  @override
  List<Object?> get props => [upnpEnabled];
}
