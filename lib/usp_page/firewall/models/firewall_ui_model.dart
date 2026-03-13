import 'package:equatable/equatable.dart';

/// Presentation Layer Model for firewall settings.
///
/// Maps to JNAP GetFirewallSettings / SetFirewallSettings fields.
/// The underlying TR-181 data comes from Device.Firewall.Chain.1.Rule.{i}
/// where each rule's Description identifies the feature.
class FirewallUIModel extends Equatable {
  /// IPv4 SPI (Stateful Packet Inspection) firewall enabled.
  final bool isIPv4FirewallEnabled;

  /// IPv6 SPI firewall enabled.
  final bool isIPv6FirewallEnabled;

  /// Block IPSec traffic (UI shows inverted as "IPSec Passthrough").
  final bool blockIPSec;

  /// Block PPTP traffic (UI shows inverted as "PPTP Passthrough").
  final bool blockPPTP;

  /// Block L2TP traffic (UI shows inverted as "L2TP Passthrough").
  final bool blockL2TP;

  /// Block anonymous (ICMP ping) requests from WAN.
  final bool blockAnonymousRequests;

  /// Block multicast (IGMP) forwarding.
  final bool blockMulticast;

  /// Block IDENT protocol (TCP port 113).
  final bool blockIDENT;

  const FirewallUIModel({
    this.isIPv4FirewallEnabled = true,
    this.isIPv6FirewallEnabled = true,
    this.blockIPSec = false,
    this.blockPPTP = false,
    this.blockL2TP = false,
    this.blockAnonymousRequests = false,
    this.blockMulticast = false,
    this.blockIDENT = false,
  });

  FirewallUIModel copyWith({
    bool? isIPv4FirewallEnabled,
    bool? isIPv6FirewallEnabled,
    bool? blockIPSec,
    bool? blockPPTP,
    bool? blockL2TP,
    bool? blockAnonymousRequests,
    bool? blockMulticast,
    bool? blockIDENT,
  }) {
    return FirewallUIModel(
      isIPv4FirewallEnabled:
          isIPv4FirewallEnabled ?? this.isIPv4FirewallEnabled,
      isIPv6FirewallEnabled:
          isIPv6FirewallEnabled ?? this.isIPv6FirewallEnabled,
      blockIPSec: blockIPSec ?? this.blockIPSec,
      blockPPTP: blockPPTP ?? this.blockPPTP,
      blockL2TP: blockL2TP ?? this.blockL2TP,
      blockAnonymousRequests:
          blockAnonymousRequests ?? this.blockAnonymousRequests,
      blockMulticast: blockMulticast ?? this.blockMulticast,
      blockIDENT: blockIDENT ?? this.blockIDENT,
    );
  }

  @override
  List<Object?> get props => [
        isIPv4FirewallEnabled,
        isIPv6FirewallEnabled,
        blockIPSec,
        blockPPTP,
        blockL2TP,
        blockAnonymousRequests,
        blockMulticast,
        blockIDENT,
      ];
}
