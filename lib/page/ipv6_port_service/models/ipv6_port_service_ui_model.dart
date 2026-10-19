import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart'
    show ruleIdentifierKey;
import 'package:privacy_gui/page/_shared/models/port_overlap.dart';

/// FWDEV#204's IPv6 port service limits, which are JNAP 1.0's: FW refuses a
/// rule past them when the rule's `Target` is written (feed_usp#50).
const kMaxIpv6PortServiceRules = 15;

/// In bytes: FW checks `strlen`, so a CJK character counts three.
const kMaxIpv6RuleDescriptionBytes = 64;

/// Error keys returned by [Ipv6PortServiceRuleUIModel.validateRule].
/// The View maps them to l10n strings.
class Ipv6PortServiceErrorKeys {
  static const descriptionRequired = 'descriptionRequired';
  static const descriptionSurroundingSpaces = 'descriptionSurroundingSpaces';
  static const descriptionTooLong = 'descriptionTooLong';
  static const descriptionInUse = 'descriptionInUse';
  static const ipv6AddressRequired = 'ipv6AddressRequired';
  static const invalidIpv6Address = 'invalidIpv6Address';
  static const reservedIpv6Address = 'reservedIpv6Address';
  static const invalidPort = 'invalidPort';
  static const portRangeReversed = 'portRangeReversed';
  static const rulesOverlap = 'rulesOverlap';
}

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

  /// The bytes [description] takes as FW stores it: UTF-8, so a CJK
  /// character counts three. The dialog's counter shows this, and
  /// [validateRule] limits it, so the two cannot disagree on where 64 is.
  static int descriptionBytes(String description) =>
      utf8.encode(description).length;

  /// Validate rule fields. Returns a map of field key ->
  /// [Ipv6PortServiceErrorKeys] key.
  ///
  /// [otherRules] is every other rule on the page; leave out the rule being
  /// edited. [hiddenRuleDescriptions] is the descriptions of the firewall
  /// rules the page does not list, which FW also compares a description with.
  static Map<String, String> validateRule({
    required String description,
    required String ipv6Address,
    required String startPort,
    required String endPort,
    required String protocol,
    List<Ipv6PortServiceRuleUIModel> otherRules = const [],
    Set<String> hiddenRuleDescriptions = const {},
  }) {
    final errors = <String, String>{};

    if (description.isEmpty) {
      errors['description'] = Ipv6PortServiceErrorKeys.descriptionRequired;
    } else if (!NoSurroundWhitespaceRule().validate(description)) {
      errors['description'] =
          Ipv6PortServiceErrorKeys.descriptionSurroundingSpaces;
    } else if (descriptionBytes(description) > kMaxIpv6RuleDescriptionBytes) {
      errors['description'] = Ipv6PortServiceErrorKeys.descriptionTooLong;
    } else if (hiddenRuleDescriptions.contains(description) ||
        otherRules.any((r) => r.description == description)) {
      errors['description'] = Ipv6PortServiceErrorKeys.descriptionInUse;
    }

    if (ipv6Address.isEmpty) {
      errors['ipv6Address'] = Ipv6PortServiceErrorKeys.ipv6AddressRequired;
    } else if (!IPv6Rule().validate(ipv6Address)) {
      errors['ipv6Address'] = Ipv6PortServiceErrorKeys.invalidIpv6Address;
    } else if (!IPv6WithReservedRule().validate(ipv6Address)) {
      errors['ipv6Address'] = Ipv6PortServiceErrorKeys.reservedIpv6Address;
    }

    final start = int.tryParse(startPort);
    final end = int.tryParse(endPort);

    if (start == null || start < 1 || start > 65535) {
      errors['startPort'] = Ipv6PortServiceErrorKeys.invalidPort;
    }

    if (end == null || end < 1 || end > 65535) {
      errors['endPort'] = Ipv6PortServiceErrorKeys.invalidPort;
    }

    if (start != null && end != null && end < start) {
      errors['endPort'] = Ipv6PortServiceErrorKeys.portRangeReversed;
    }

    if (!errors.containsKey('ipv6Address') &&
        !errors.containsKey('startPort') &&
        !errors.containsKey('endPort') &&
        _overlaps(ipv6Address, start!, end!, protocol, otherRules)) {
      errors['endPort'] = Ipv6PortServiceErrorKeys.rulesOverlap;
    }

    return errors;
  }

  /// FWDEV#204's overlap, as FW checks it: the same LAN host, an overlapping
  /// port range and a shared protocol. Disabled rules count. Hosts are
  /// compared as addresses, as FW does with `inet_pton`, so the compressed and
  /// the full form of one address are one host.
  static bool _overlaps(
    String ipv6Address,
    int start,
    int end,
    String protocol,
    List<Ipv6PortServiceRuleUIModel> others,
  ) {
    final host = _hostBytes(ipv6Address);
    if (host == null) return false;
    return others.any((o) =>
        _sameHost(host, _hostBytes(o.ipv6Address)) &&
        protocolsShare(protocol, o.protocol) &&
        portRangesOverlap(start, end, o.startPort, o.endPort));
  }

  /// The 16 address bytes, without a `/prefix`; null when [address] does not
  /// parse, which FW does not count as an overlap either.
  static List<int>? _hostBytes(String address) {
    final slash = address.indexOf('/');
    try {
      return Uri.parseIPv6Address(
          slash < 0 ? address : address.substring(0, slash));
    } on FormatException {
      return null;
    }
  }

  static bool _sameHost(List<int> a, List<int>? b) {
    if (b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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
