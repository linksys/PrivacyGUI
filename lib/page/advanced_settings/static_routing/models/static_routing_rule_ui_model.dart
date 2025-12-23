import 'dart:convert';

import 'package:equatable/equatable.dart';

/// UI Model for a single static routing rule (not JNAP model)
///
/// This model isolates the presentation layer from JNAP data models.
/// Used by the rule editor to display and edit individual route configurations.
class StaticRoutingRuleUIModel extends Equatable {
  /// Route name or description
  final String name;

  /// Destination IP address
  final String destinationIP;

  /// Network prefix length (CIDR notation, 0-32)
  final int networkPrefixLength;

  /// Gateway IP address (optional)
  final String? gateway;

  /// Network interface (LAN or Internet)
  final String interface;

  const StaticRoutingRuleUIModel({
    required this.name,
    required this.destinationIP,
    required this.networkPrefixLength,
    this.gateway,
    required this.interface,
  });

  @override
  List<Object?> get props =>
      [name, destinationIP, networkPrefixLength, gateway, interface];

  StaticRoutingRuleUIModel copyWith({
    String? name,
    String? destinationIP,
    int? networkPrefixLength,
    String? gateway,
    String? interface,
  }) {
    return StaticRoutingRuleUIModel(
      name: name ?? this.name,
      destinationIP: destinationIP ?? this.destinationIP,
      networkPrefixLength: networkPrefixLength ?? this.networkPrefixLength,
      gateway: gateway ?? this.gateway,
      interface: interface ?? this.interface,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'destinationIP': destinationIP,
      'networkPrefixLength': networkPrefixLength,
      'gateway': gateway,
      'interface': interface,
    };
  }

  factory StaticRoutingRuleUIModel.fromMap(Map<String, dynamic> map) {
    return StaticRoutingRuleUIModel(
      name: map['name'] ?? '',
      destinationIP: map['destinationIP'] ?? '',
      networkPrefixLength: map['networkPrefixLength'] ?? 24,
      gateway: map['gateway'],
      interface: map['interface'] ?? 'LAN',
    );
  }

  String toJson() => json.encode(toMap());

  factory StaticRoutingRuleUIModel.fromJson(String source) =>
      StaticRoutingRuleUIModel.fromMap(json.decode(source));
}
