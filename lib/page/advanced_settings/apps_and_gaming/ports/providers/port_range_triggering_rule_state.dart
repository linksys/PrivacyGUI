// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import 'package:privacy_gui/core/jnap/models/port_range_triggering_rule.dart';

class PortRangeTriggeringRuleState extends Equatable {
  final List<PortRangeTriggeringRule> rules;
  final PortRangeTriggeringRule? rule;
  final int? editIndex;

  const PortRangeTriggeringRuleState({
    this.rules = const [],
    this.rule,
    this.editIndex,
  });

  @override
  List<Object?> get props => [rules, rule, editIndex];

  PortRangeTriggeringRuleState copyWith({
    List<PortRangeTriggeringRule>? rules,
    ValueGetter<PortRangeTriggeringRule?>? rule,
    ValueGetter<int?>? editIndex,
  }) {
    return PortRangeTriggeringRuleState(
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

  factory PortRangeTriggeringRuleState.fromMap(Map<String, dynamic> map) {
    return PortRangeTriggeringRuleState(
      rules: List<PortRangeTriggeringRule>.from(map['rules']?.map((x) => PortRangeTriggeringRule.fromMap(x))),
      rule: map['rule'] != null ? PortRangeTriggeringRule.fromMap(map['rule']) : null,
      editIndex: map['editIndex']?.toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory PortRangeTriggeringRuleState.fromJson(String source) => PortRangeTriggeringRuleState.fromMap(json.decode(source));

  @override
  bool get stringify => true;

  @override
  String toString() => 'PortRangeTriggeringRuleState(rules: $rules, rule: $rule, editIndex: $editIndex)';
}
