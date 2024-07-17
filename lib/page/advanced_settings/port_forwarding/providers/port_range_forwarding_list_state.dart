// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/port_range_forwarding_rule.dart';

class PortRangeForwardingListState extends Equatable {
  const PortRangeForwardingListState({
    this.rules = const [],
    this.maxRules = 50,
    this.maxDescriptionLength = 32,
  });

  final List<PortRangeForwardingRule> rules;
  final int maxRules;
  final int maxDescriptionLength;

  @override
  List<Object> get props => [rules, maxRules, maxDescriptionLength];

  PortRangeForwardingListState copyWith({
    List<PortRangeForwardingRule>? rules,
    int? maxRules,
    int? maxDescriptionLength,
  }) {
    return PortRangeForwardingListState(
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

  factory PortRangeForwardingListState.fromMap(Map<String, dynamic> map) {
    return PortRangeForwardingListState(
      rules: List<PortRangeForwardingRule>.from(
        map['rules'].map<PortRangeForwardingRule>(
          (x) => PortRangeForwardingRule.fromMap(x as Map<String, dynamic>),
        ),
      ),
      maxRules: map['maxRules'] != null ? map['maxRules'] as int : 50,
      maxDescriptionLength: map['maxDescriptionLength'] != null
          ? map['maxDescriptionLength'] as int
          : 32,
    );
  }

  String toJson() => json.encode(toMap());

  factory PortRangeForwardingListState.fromJson(String source) =>
      PortRangeForwardingListState.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
