import 'package:equatable/equatable.dart';

/// UI model for a single IPv6 port service rule.
///
/// Unlike the JNAP model which groups multiple port ranges under one rule,
/// the TR-181 model is flat: 1 rule = 1 port entry. Each [Ipv6PortServiceRule]
/// codegen instance maps to one [Ipv6PortServiceRuleUIModel].
class Ipv6PortServiceRuleUIModel extends Equatable {
  /// TR-181 instance path, e.g. "Device.Firewall.Chain.1.Rule.26."
  final String instancePath;

  /// Whether the rule is active.
  final bool enabled;

  /// User-assigned rule name.
  final String description;

  /// Destination IPv6 address.
  final String ipv6Address;

  /// Protocol display name: "TCP", "UDP", or "Both".
  final String protocol;

  /// Start port number. -1 means "Any".
  final int startPort;

  /// End port number. Same as startPort for single port. -1 means "Any".
  final int endPort;

  const Ipv6PortServiceRuleUIModel({
    required this.instancePath,
    required this.enabled,
    required this.description,
    required this.ipv6Address,
    required this.protocol,
    required this.startPort,
    required this.endPort,
  });

  /// Human-readable port display.
  String get portDisplay {
    if (startPort == -1) return 'Any';
    if (endPort == -1 || endPort == startPort) return '$startPort';
    return '$startPort-$endPort';
  }

  @override
  List<Object?> get props => [
        instancePath,
        enabled,
        description,
        ipv6Address,
        protocol,
        startPort,
        endPort,
      ];
}
