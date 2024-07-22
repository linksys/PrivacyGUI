// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/ipv6_firewall_rule.dart';

class Ipv6PortServiceListState extends Equatable {
  const Ipv6PortServiceListState({
    this.rules = const [],
    this.maxRules = 50,
    this.maxDescriptionLength = 32,
  });

  final List<IPv6FirewallRule> rules;
  final int maxRules;
  final int maxDescriptionLength;

  @override
  List<Object> get props => [rules, maxRules, maxDescriptionLength];

  Ipv6PortServiceListState copyWith({
    List<IPv6FirewallRule>? rules,
    int? maxRules,
    int? maxDescriptionLength,
  }) {
    return Ipv6PortServiceListState(
      rules: rules ?? this.rules,
      maxRules: maxRules ?? this.maxRules,
      maxDescriptionLength: maxDescriptionLength ?? this.maxDescriptionLength,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'rules': rules.map((x) => x.toMap()).toList(),
      'maxRules': maxRules,
      'maxDescriptionLength': maxDescriptionLength,
    };
  }

  factory Ipv6PortServiceListState.fromMap(Map<String, dynamic> map) {
    return Ipv6PortServiceListState(
      rules: List<IPv6FirewallRule>.from(
        map['rules'].map<IPv6FirewallRule>(
          (x) => IPv6FirewallRule.fromMap(x as Map<String, dynamic>),
        ),
      ),
      maxRules: map['maxRules'] as int? ?? 50,
      maxDescriptionLength: map['maxDescriptionLength'] as int? ?? 32,
    );
  }

  String toJson() => json.encode(toMap());

  factory Ipv6PortServiceListState.fromJson(String source) =>
      Ipv6PortServiceListState.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
