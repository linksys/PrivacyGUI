// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class PortRange extends Equatable {
  final String protocol;
  final int firstPort;
  final int lastPort;
  const PortRange({
    required this.protocol,
    required this.firstPort,
    required this.lastPort,
  });

  PortRange copyWith({
    String? protocol,
    int? firstPort,
    int? lastPort,
  }) {
    return PortRange(
      protocol: protocol ?? this.protocol,
      firstPort: firstPort ?? this.firstPort,
      lastPort: lastPort ?? this.lastPort,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'protocol': protocol,
      'firstPort': firstPort,
      'lastPort': lastPort,
    };
  }

  factory PortRange.fromMap(Map<String, dynamic> map) {
    return PortRange(
      protocol: map['protocol'] as String,
      firstPort: map['firstPort'] as int,
      lastPort: map['lastPort'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory PortRange.fromJson(String source) =>
      PortRange.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [protocol, firstPort, lastPort];
}

class IPv6FirewallRule extends Equatable {
  final String description;
  final String ipv6Address;
  final bool isEnabled;
  final List<PortRange> portRanges;
  const IPv6FirewallRule({
    required this.description,
    required this.ipv6Address,
    required this.isEnabled,
    required this.portRanges,
  });

  IPv6FirewallRule copyWith({
    String? description,
    String? ipv6Address,
    bool? isEnabled,
    List<PortRange>? portRanges,
  }) {
    return IPv6FirewallRule(
      description: description ?? this.description,
      ipv6Address: ipv6Address ?? this.ipv6Address,
      isEnabled: isEnabled ?? this.isEnabled,
      portRanges: portRanges ?? this.portRanges,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'description': description,
      'ipv6Address': ipv6Address,
      'isEnabled': isEnabled,
      'portRanges': portRanges.map((x) => x.toMap()).toList(),
    };
  }

  factory IPv6FirewallRule.fromMap(Map<String, dynamic> map) {
    return IPv6FirewallRule(
      description: map['description'] as String,
      ipv6Address: map['ipv6Address'] as String,
      isEnabled: map['isEnabled'] as bool,
      portRanges: List<PortRange>.from(
        map['portRanges'].map<PortRange>(
          (x) => PortRange.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory IPv6FirewallRule.fromJson(String source) =>
      IPv6FirewallRule.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [description, ipv6Address, isEnabled, portRanges];
}

class IPv6FirewallRuleList extends Equatable {
  final List<IPv6FirewallRule> rules;

  const IPv6FirewallRuleList({required this.rules});

  @override
  List<Object> get props => [rules];

  IPv6FirewallRuleList copyWith({
    List<IPv6FirewallRule>? rules,
  }) {
    return IPv6FirewallRuleList(
      rules: rules ?? this.rules,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'rules': rules.map((x) => x.toMap()).toList(),
    };
  }

  factory IPv6FirewallRuleList.fromMap(Map<String, dynamic> map) {
    return IPv6FirewallRuleList(
      rules: List<IPv6FirewallRule>.from(
        map['rules']?.map<IPv6FirewallRule>(
              (x) => IPv6FirewallRule.fromMap(x as Map<String, dynamic>),
            ) ??
            [],
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory IPv6FirewallRuleList.fromJson(String source) =>
      IPv6FirewallRuleList.fromMap(json.decode(source) as Map<String, dynamic>);
}
