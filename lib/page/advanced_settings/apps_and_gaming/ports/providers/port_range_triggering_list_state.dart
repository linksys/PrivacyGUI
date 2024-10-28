// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/port_range_triggering_rule.dart';

class PortRangeTriggeringListState extends Equatable {
  const PortRangeTriggeringListState({
    this.rules = const [],
    this.maxRules = 50,
    this.maxDescriptionLength = 32,
  });

  final List<PortRangeTriggeringRule> rules;
  final int maxRules;
  final int maxDescriptionLength;

  @override
  List<Object> get props => [rules, maxRules, maxDescriptionLength];

  PortRangeTriggeringListState copyWith({
    List<PortRangeTriggeringRule>? rules,
    int? maxRules,
    int? maxDescriptionLength,
  }) {
    return PortRangeTriggeringListState(
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

  factory PortRangeTriggeringListState.fromMap(Map<String, dynamic> map) {
    return PortRangeTriggeringListState(
      rules: List<PortRangeTriggeringRule>.from(
        map['rules'].map<PortRangeTriggeringRule>(
          (x) => PortRangeTriggeringRule.fromMap(x as Map<String, dynamic>),
        ),
      ),
      maxRules: map['maxRules'] != null ? map['maxRules'] as int : 50,
      maxDescriptionLength: map['maxDescriptionLength'] != null
          ? map['maxDescriptionLength'] as int
          : 32,
    );
  }

  String toJson() => json.encode(toMap());

  factory PortRangeTriggeringListState.fromJson(String source) =>
      PortRangeTriggeringListState.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
