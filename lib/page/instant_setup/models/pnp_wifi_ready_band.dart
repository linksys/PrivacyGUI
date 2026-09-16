import 'package:equatable/equatable.dart';

/// One band's credentials, exactly as the setup-complete screen shows them.
///
/// A deliberate three-field subset of [PnpWifiBand], and the subset is the point:
/// this is the only part of the wizard's configuration that has to **outlive the
/// router reboot** a firmware update causes mid-PnP (REQ-B4). What the completion
/// screen needs is a name, an SSID and a passphrase per band; what [PnpWifiConfig]
/// also carries is TR-181 instance paths and `original*` values for dirty tracking,
/// none of which mean anything after the write they were tracking has been
/// committed.
///
/// So this is not a lossy copy of the config — it is the whole of what is being
/// shown. Carrying [PnpWifiConfig] instead would keep instance paths and dirty
/// flags alive as though the form were still open, which is the lie the narrow type
/// prevents.
///
/// No `toJson`/`fromJson`: they existed only to serialize this into
/// `FlutterSecureStorage`, and that copy is gone — see [WizardWifiReady] for the two
/// measurements that retired it.
class PnpWifiReadyBand extends Equatable {
  final String bandName;
  final String ssid;
  final String password;

  const PnpWifiReadyBand({
    required this.bandName,
    required this.ssid,
    required this.password,
  });

  @override
  List<Object?> get props => [bandName, ssid, password];
}
