import 'package:privacy_gui/util/network_utils.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';
import 'package:privacy_gui/validator_rules/rules.dart';

/// Why an address is not a LAN host's IPv4, in the order the checks run.
///
/// Each value has its own message, so a form says which check failed:
/// - [format]: not a dotted-quad IPv4 address;
/// - [reserved]: in a range no host can hold (`0.0.0.0/8`, loopback,
///   multicast, broadcast);
/// - [notLanHost]: outside the router's LAN subnet, or the router's own
///   address.
enum LanHostIpv4Problem { format, reserved, notLanHost }

final _formatRule = IpAddressRule();
final _noReservedRule = IpAddressNoReservedRule();

/// The one check for an IPv4 address the app writes as a LAN host's: a DHCP
/// reservation, a port-forwarding target, the DMZ host (#1838).
///
/// Every form that takes such an address calls this, so the same address is
/// refused, or accepted, with the same message on every page.
///
/// The LAN check runs only when [lanIp] and [lanSubnetMask] describe a LAN;
/// a caller that writes to the router reads them first and does not write
/// when they cannot be read (`readLanForHostCheck`).
LanHostIpv4Problem? lanHostIpv4Problem(
  String ip, {
  String? lanIp,
  String? lanSubnetMask,
}) {
  if (!_formatRule.validate(ip)) return LanHostIpv4Problem.format;
  if (!_noReservedRule.validate(ip)) return LanHostIpv4Problem.reserved;
  if (_lanKnown(lanIp, lanSubnetMask) &&
      !IpAddressAsLocalIpValidator(lanIp!, lanSubnetMask!).validate(ip)) {
    return LanHostIpv4Problem.notLanHost;
  }
  return null;
}

/// Whether [lanIp] and [lanSubnetMask] describe a LAN, as the static routing
/// form decides it: an empty or malformed pair is no LAN, and checking
/// against it would refuse every address.
bool _lanKnown(String? lanIp, String? lanSubnetMask) =>
    lanIp != null &&
    lanSubnetMask != null &&
    _formatRule.validate(lanIp) &&
    NetworkUtils.isValidSubnetMask(lanSubnetMask);

/// Whether [ip] is an address a host can hold: IPv4, outside the reserved
/// ranges.
bool isUsableHostIpv4(String ip) => lanHostIpv4Problem(ip) == null;

/// A Hosts row's `IPAddress` as the app keeps it: the address, or `''` when
/// it is none a host can hold (#1838).
///
/// FL-WRT 2.0 has reported `0.0.0.0`, with `IPv4AddressNumberOfEntries = 0`,
/// for a wired client that held an address and for an agent's backhaul
/// station. Kept as is, that value was shown as the device's address and
/// offered for a DHCP reservation. As `''`, every consumer treats the device
/// as having no IPv4: the address slots read `NetworkUtils.noAddress`, the
/// pickers that offer devices by IP leave it out, and the device page
/// disables Reserve.
///
/// Every reader of `Device.Hosts.Host.{i}.IPAddress` goes through this:
/// `MeshNetworkBuilder` for clients and nodes, and the MAC filter service.
String hostIpv4OrEmpty(String? raw) {
  final ip = raw?.trim() ?? '';
  return isUsableHostIpv4(ip) ? ip : '';
}

/// The message each [LanHostIpv4Problem] shows, as its ARB key, for a form
/// that keeps its errors as keys. A form that builds its messages directly
/// uses `lanHostIpv4Message`, which maps to the same strings.
extension LanHostIpv4ProblemKey on LanHostIpv4Problem {
  String get messageKey => switch (this) {
        LanHostIpv4Problem.format => 'invalidIpv4Format',
        LanHostIpv4Problem.reserved => 'reservedIpNotAllowed',
        LanHostIpv4Problem.notLanHost => 'invalidIpAddress',
      };
}
