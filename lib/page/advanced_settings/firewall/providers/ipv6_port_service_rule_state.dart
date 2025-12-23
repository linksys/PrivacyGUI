import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

/// Port range model for UI compatibility
class PortRangeUI extends Equatable {
  final String protocol;
  final int firstPort;
  final int lastPort;

  const PortRangeUI({
    required this.protocol,
    required this.firstPort,
    required this.lastPort,
  });

  PortRangeUI copyWith({
    String? protocol,
    int? firstPort,
    int? lastPort,
  }) {
    return PortRangeUI(
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

  factory PortRangeUI.fromMap(Map<String, dynamic> map) {
    return PortRangeUI(
      protocol: map['protocol'] as String,
      firstPort: map['firstPort'] as int,
      lastPort: map['lastPort'] as int,
    );
  }

  @override
  List<Object> get props => [protocol, firstPort, lastPort];
}

/// UI model for IPv6 port service rule - bridges Data layer and Presentation layer
/// This isolates the Presentation layer from JNAP protocol details.
class IPv6PortServiceRuleUI extends Equatable {
  /// Port ranges for the rule (simplified from JNAP portRanges list)
  final List<PortRangeUI> portRanges;

  /// IPv6 address of the internal device
  final String ipv6Address;

  /// Description of the rule
  final String description;

  /// Whether the rule is enabled
  final bool enabled;

  const IPv6PortServiceRuleUI({
    required this.portRanges,
    required this.ipv6Address,
    required this.description,
    required this.enabled,
  });

  /// Create a copy with optional field overrides
  IPv6PortServiceRuleUI copyWith({
    List<PortRangeUI>? portRanges,
    String? ipv6Address,
    String? description,
    bool? enabled,
  }) {
    return IPv6PortServiceRuleUI(
      portRanges: portRanges ?? this.portRanges,
      ipv6Address: ipv6Address ?? this.ipv6Address,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
    );
  }

  /// Convert to Map for serialization
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'portRanges': portRanges.map((x) => x.toMap()).toList(),
      'ipv6Address': ipv6Address,
      'description': description,
      'enabled': enabled,
    };
  }

  /// Create from Map for deserialization
  factory IPv6PortServiceRuleUI.fromMap(Map<String, dynamic> map) {
    return IPv6PortServiceRuleUI(
      portRanges: List<PortRangeUI>.from(
        map['portRanges']?.map<PortRangeUI>(
              (x) => PortRangeUI.fromMap(x as Map<String, dynamic>),
            ) ??
            [],
      ),
      ipv6Address: map['ipv6Address'] as String,
      description: map['description'] as String,
      enabled: map['enabled'] as bool,
    );
  }

  /// Convert to JSON string
  String toJson() => json.encode(toMap());

  /// Create from JSON string
  factory IPv6PortServiceRuleUI.fromJson(String source) =>
      IPv6PortServiceRuleUI.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  List<Object> get props => [portRanges, ipv6Address, description, enabled];
}

/// Wrapper for list of IPv6PortServiceRuleUI to satisfy Equatable constraint
class IPv6PortServiceRuleUIList extends Equatable {
  final List<IPv6PortServiceRuleUI> rules;

  const IPv6PortServiceRuleUIList({required this.rules});

  @override
  List<Object> get props => [rules];

  IPv6PortServiceRuleUIList copyWith({
    List<IPv6PortServiceRuleUI>? rules,
  }) {
    return IPv6PortServiceRuleUIList(
      rules: rules ?? this.rules,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'rules': rules.map((x) => x.toMap()).toList(),
    };
  }

  factory IPv6PortServiceRuleUIList.fromMap(Map<String, dynamic> map) {
    return IPv6PortServiceRuleUIList(
      rules: List<IPv6PortServiceRuleUI>.from(
        map['rules']?.map<IPv6PortServiceRuleUI>(
              (x) => IPv6PortServiceRuleUI.fromMap(x as Map<String, dynamic>),
            ) ??
            [],
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory IPv6PortServiceRuleUIList.fromJson(String source) =>
      IPv6PortServiceRuleUIList.fromMap(
          json.decode(source) as Map<String, dynamic>);
}

class Ipv6PortServiceRuleState extends Equatable {
  final List<IPv6PortServiceRuleUI> rules;
  final IPv6PortServiceRuleUI? rule;
  final int? editIndex;

  const Ipv6PortServiceRuleState({
    this.rules = const [],
    this.rule,
    this.editIndex,
  });

  @override
  List<Object?> get props => [rules, rule, editIndex];

  Ipv6PortServiceRuleState copyWith({
    List<IPv6PortServiceRuleUI>? rules,
    ValueGetter<IPv6PortServiceRuleUI?>? rule,
    ValueGetter<int?>? editIndex,
  }) {
    return Ipv6PortServiceRuleState(
      rules: rules ?? this.rules,
      rule: rule != null ? rule() : this.rule,
      editIndex: editIndex != null ? editIndex() : this.editIndex,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rules': rules.map((x) => x.toMap()).toList(),
      'rule': rule?.toMap(),
      'editIndex': editIndex,
    };
  }

  factory Ipv6PortServiceRuleState.fromMap(Map<String, dynamic> map) {
    return Ipv6PortServiceRuleState(
      rules: List<IPv6PortServiceRuleUI>.from(
          map['rules']?.map((x) => IPv6PortServiceRuleUI.fromMap(x)) ?? []),
      rule: map['rule'] != null
          ? IPv6PortServiceRuleUI.fromMap(map['rule'])
          : null,
      editIndex: map['editIndex']?.toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Ipv6PortServiceRuleState.fromJson(String source) =>
      Ipv6PortServiceRuleState.fromMap(json.decode(source));

  @override
  String toString() =>
      'Ipv6PortServiceRuleState(rules: $rules, rule: $rule, editIndex: $editIndex)';
}
