import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import 'package:privacy_gui/core/jnap/models/ipv6_firewall_rule.dart';

class Ipv6PortServiceRuleState extends Equatable {
  final List<IPv6FirewallRule> rules;
  final IPv6FirewallRule? rule;
  final int? editIndex;

  const Ipv6PortServiceRuleState({
    this.rules = const [],
    this.rule,
    this.editIndex,
  });

  @override
  List<Object?> get props => [rules, rule, editIndex];

  Ipv6PortServiceRuleState copyWith({
    List<IPv6FirewallRule>? rules,
    ValueGetter<IPv6FirewallRule?>? rule,
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
      rules: List<IPv6FirewallRule>.from(map['rules']?.map((x) => IPv6FirewallRule.fromMap(x))),
      rule: map['rule'] != null ? IPv6FirewallRule.fromMap(map['rule']) : null,
      editIndex: map['editIndex']?.toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Ipv6PortServiceRuleState.fromJson(String source) => Ipv6PortServiceRuleState.fromMap(json.decode(source));

  @override
  String toString() => 'Ipv6PortServiceRuleState(rules: $rules, rule: $rule, editIndex: $editIndex)';
}
