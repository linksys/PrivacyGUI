import 'package:equatable/equatable.dart';

/// Presentation Layer Model for a port forwarding rule.
class PortForwardingRuleUIModel extends Equatable {
  final String instancePath; // For toggle/delete/update mutations
  final String description;
  final int externalPort;
  final int internalPort;
  final String internalClient;
  final String protocol;
  final bool enabled;

  const PortForwardingRuleUIModel({
    required this.instancePath,
    required this.description,
    required this.externalPort,
    required this.internalPort,
    required this.internalClient,
    required this.protocol,
    required this.enabled,
  });

  /// Display name: description if available, otherwise "Unnamed rule".
  String get displayName =>
      description.isNotEmpty ? description : 'Unnamed rule';

  /// Summary: "8080 → 192.168.1.100:80"
  String get portSummary =>
      '$externalPort \u2192 $internalClient:$internalPort';

  @override
  List<Object?> get props => [
        instancePath,
        description,
        externalPort,
        internalPort,
        internalClient,
        protocol,
        enabled,
      ];
}
