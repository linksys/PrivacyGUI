import 'package:equatable/equatable.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart'
    show ruleIdentifierKey;

/// UI model for a single IPv6 port service rule.
///
/// Unlike the JNAP model which groups multiple port ranges under one rule,
/// the TR-181 model is flat: 1 rule = 1 port entry. Each [Ipv6PortServiceRule]
/// codegen instance maps to one [Ipv6PortServiceRuleUIModel].
///
/// [instancePath] is `null` for newly created (local-only) rules
/// that have not yet been saved to the device.
class Ipv6PortServiceRuleUIModel extends Equatable {
  /// TR-181 instance path, e.g. "Device.Firewall.Chain.1.Rule.26."
  /// Null for locally-created rules not yet saved.
  final String? instancePath;

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
    this.instancePath,
    required this.enabled,
    required this.description,
    required this.ipv6Address,
    required this.protocol,
    required this.startPort,
    required this.endPort,
  });

  Ipv6PortServiceRuleUIModel copyWith({
    String? instancePath,
    bool? enabled,
    String? description,
    String? ipv6Address,
    String? protocol,
    int? startPort,
    int? endPort,
  }) {
    return Ipv6PortServiceRuleUIModel(
      instancePath: instancePath ?? this.instancePath,
      enabled: enabled ?? this.enabled,
      description: description ?? this.description,
      ipv6Address: ipv6Address ?? this.ipv6Address,
      protocol: protocol ?? this.protocol,
      startPort: startPort ?? this.startPort,
      endPort: endPort ?? this.endPort,
    );
  }

  /// Human-readable port display.
  String get portDisplay {
    if (startPort == -1) return 'Any';
    if (endPort == -1 || endPort == startPort) return '$startPort';
    return '$startPort-$endPort';
  }

  /// Stable, kebab-case key for E2E `identifier` hooks (e.g.
  /// `ipv6-rule-edit-<key>`). Derived from the description ("Web Server" →
  /// "web-server"); falls back to the saved instance number, then "unnamed",
  /// so it is always non-empty. Distinct across rows only when a discriminating
  /// tier (description slug or instance number) fires — never a positional
  /// index, which would re-import the `.nth()` reorder trap.
  String get identifierKey => ruleIdentifierKey(description, instancePath);

  /// The protocol choices the rule dialog offers, as display names.
  static const protocolOptions = ['TCP', 'UDP', 'Both'];

  /// Validate rule fields. Returns a map of field key -> error message.
  static Map<String, String> validateRule({
    required String description,
    required String ipv6Address,
    required String startPort,
    required String endPort,
  }) {
    final errors = <String, String>{};

    if (description.isEmpty) {
      errors['description'] = 'Name is required';
    } else if (!NoSurroundWhitespaceRule().validate(description)) {
      errors['description'] = 'Name must not have leading or trailing spaces';
    } else if (description.length > 32) {
      errors['description'] = 'Name must be 32 characters or less';
    }

    if (ipv6Address.isEmpty) {
      errors['ipv6Address'] = 'IPv6 address is required';
    } else if (!IPv6Rule().validate(ipv6Address)) {
      errors['ipv6Address'] = 'Invalid IPv6 address format';
    } else if (!IPv6WithReservedRule().validate(ipv6Address)) {
      errors['ipv6Address'] = 'Reserved IPv6 address is not allowed';
    }

    final start = int.tryParse(startPort);
    final end = int.tryParse(endPort);

    if (startPort.isEmpty || start == null) {
      errors['startPort'] = 'Start port is required';
    } else if (start < 1 || start > 65535) {
      errors['startPort'] = 'Port must be 1-65535';
    }

    if (endPort.isEmpty || end == null) {
      errors['endPort'] = 'End port is required';
    } else if (end < 1 || end > 65535) {
      errors['endPort'] = 'Port must be 1-65535';
    }

    if (start != null && end != null && end < start) {
      errors['endPort'] = 'End port must be >= start port';
    }

    return errors;
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
