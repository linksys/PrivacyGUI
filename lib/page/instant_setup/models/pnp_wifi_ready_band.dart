import 'package:equatable/equatable.dart';

/// One band's credentials, exactly as the setup-complete screen shows them.
///
/// A deliberate three-field subset of [PnpWifiBand], and the subset is the point:
/// this is the only part of the wizard's configuration that has to **survive a
/// router reboot** (REQ-B4), and a firmware update in the middle of PnP reboots
/// once. What the completion screen needs is a name, an SSID and a passphrase per
/// band; what [PnpWifiConfig] also carries is TR-181 instance paths and
/// `original*` values for dirty tracking, none of which mean anything after the
/// write they were tracking has been committed.
///
/// So this is not a lossy copy of the config — it is the whole of what is being
/// shown. Persisting [PnpWifiConfig] instead would restore instance paths and
/// dirty flags as though the form were still open, which is the lie the narrow
/// type prevents.
class PnpWifiReadyBand extends Equatable {
  final String bandName;
  final String ssid;
  final String password;

  const PnpWifiReadyBand({
    required this.bandName,
    required this.ssid,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'bandName': bandName,
        'ssid': ssid,
        'password': password,
      };

  factory PnpWifiReadyBand.fromJson(Map<String, dynamic> json) =>
      PnpWifiReadyBand(
        bandName: json['bandName'] as String,
        ssid: json['ssid'] as String,
        password: json['password'] as String,
      );

  @override
  List<Object?> get props => [bandName, ssid, password];
}
