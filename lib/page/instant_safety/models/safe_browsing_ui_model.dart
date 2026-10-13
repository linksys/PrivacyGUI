import 'package:equatable/equatable.dart';

/// Safe browsing preset — off or OpenDNS Family Shield.
enum SafeBrowsingType { off, openDNS }

/// Presentation Layer Model for safe browsing state.
///
/// Naming follows constitution Section 3.3.4 (class name ends with `UIModel`).
/// Implements [Equatable] per Article XI.
class SafeBrowsingUIModel extends Equatable {
  final SafeBrowsingType type;

  /// Raw DNS value from the router — for display purposes only.
  final String currentDnsServers;

  const SafeBrowsingUIModel({
    required this.type,
    this.currentDnsServers = '',
  });

  bool get isEnabled => type != SafeBrowsingType.off;

  /// OpenDNS Family Shield, identical to the JNAP version (NOW-713).
  static const _openDnsDns1 = '208.67.222.222';
  static const _openDnsDns2 = '208.67.220.220';

  /// The DNS servers value that turns OpenDNS on.
  static const openDnsServers = '$_openDnsDns1,$_openDnsDns2';

  /// Returns true if the DNS servers string indicates OpenDNS is active.
  static bool isOpenDns(String dnsServers) {
    final first = dnsServers.split(',').firstOrNull?.trim() ?? '';
    return first == _openDnsDns1;
  }

  @override
  List<Object?> get props => [type, currentDnsServers];
}
