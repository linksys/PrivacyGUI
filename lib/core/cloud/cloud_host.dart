import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_info.dart';

/// The host the cloud clients send to, or null for the cloud's own base URL.
///
/// A forced local build always goes through the router, at its local address.
/// Any other build goes through the router too, unless the phone is not on
/// one of ours ([RouterType.others]). [routerType] and [localIp] are only read
/// when the answer needs them.
String? cloudHost({
  required ForceCommand force,
  required RouterType Function() routerType,
  required String Function() localIp,
}) {
  if (force != ForceCommand.local && routerType() == RouterType.others) {
    return null;
  }
  final ip = localIp();
  return ip.startsWith('http') ? ip : 'https://$ip';
}
