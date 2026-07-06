import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';

/// Presentation Layer Model for a port forwarding rule.
///
/// Covers both single port and port range forwarding from
/// `Device.NAT.PortMapping`. When [externalPortEndRange] is 0 or equal to
/// [externalPort] the rule is a single-port forward; otherwise it is a
/// port-range forward.
///
/// [instancePath] is `null` for newly created (local-only) rules
/// that have not yet been saved to the device.
class PortForwardingRuleUIModel extends Equatable with DiagnosticLoggable {
  final String? instancePath;
  final String description;
  final int externalPort;
  final int externalPortEndRange; // 0 = single port
  final int internalPort;
  final String internalClient;
  final String protocol;
  final bool enabled;

  const PortForwardingRuleUIModel({
    this.instancePath,
    required this.description,
    required this.externalPort,
    this.externalPortEndRange = 0,
    required this.internalPort,
    required this.internalClient,
    required this.protocol,
    required this.enabled,
  });

  PortForwardingRuleUIModel copyWith({
    String? instancePath,
    String? description,
    int? externalPort,
    int? externalPortEndRange,
    int? internalPort,
    String? internalClient,
    String? protocol,
    bool? enabled,
  }) {
    return PortForwardingRuleUIModel(
      instancePath: instancePath ?? this.instancePath,
      description: description ?? this.description,
      externalPort: externalPort ?? this.externalPort,
      externalPortEndRange: externalPortEndRange ?? this.externalPortEndRange,
      internalPort: internalPort ?? this.internalPort,
      internalClient: internalClient ?? this.internalClient,
      protocol: protocol ?? this.protocol,
      enabled: enabled ?? this.enabled,
    );
  }

  /// True when this is a single-port forward (no range).
  bool get isSinglePort =>
      externalPortEndRange == 0 || externalPortEndRange == externalPort;

  /// True when this is a port-range forward.
  bool get isPortRange => !isSinglePort;

  /// Display name: description if available, otherwise "Unnamed rule".
  String get displayName =>
      description.isNotEmpty ? description : 'Unnamed rule';

  /// External port display: "8080" or "3074-3080".
  String get portRangeDisplay =>
      isSinglePort ? '$externalPort' : '$externalPort-$externalPortEndRange';

  /// Summary: "8080 → 192.168.1.100:80" or "3074-3080 → 192.168.1.50:3074".
  String get portSummary =>
      '$portRangeDisplay \u2192 $internalClient:$internalPort';

  @override
  Map<String, Object?> get namedProps => {
        'instancePath': instancePath,
        'description': description,
        'externalPort': externalPort,
        'externalPortEndRange': externalPortEndRange,
        'internalPort': internalPort,
        'internalClient': internalClient,
        'protocol': protocol,
        'enabled': enabled,
      };
}
