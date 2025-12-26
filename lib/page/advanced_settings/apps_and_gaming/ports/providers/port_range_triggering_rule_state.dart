// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/port_range_triggering_rule_ui_model.dart';

class PortRangeTriggeringRuleState extends Equatable {
  final List<PortRangeTriggeringRuleUIModel> rules;
  final PortRangeTriggeringRuleUIModel? rule;
  final int? editIndex;

  const PortRangeTriggeringRuleState({
    this.rules = const [],
    this.rule,
    this.editIndex,
  });

  @override
  List<Object?> get props => [rules, rule, editIndex];

  PortRangeTriggeringRuleState copyWith({
    List<PortRangeTriggeringRuleUIModel>? rules,
    ValueGetter<PortRangeTriggeringRuleUIModel?>? rule,
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
      rules: List<PortRangeTriggeringRuleUIModel>.from(
          map['rules']?.map((x) => PortRangeTriggeringRuleUIModel.fromMap(x))),
      rule: map['rule'] != null
          ? PortRangeTriggeringRuleUIModel.fromMap(map['rule'])
          : null,
      editIndex: map['editIndex']?.toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory PortRangeTriggeringRuleState.fromJson(String source) =>
      PortRangeTriggeringRuleState.fromMap(json.decode(source));

  @override
  bool get stringify => true;

  @override
  String toString() =>
      'PortRangeTriggeringRuleState(rules: $rules, rule: $rule, editIndex: $editIndex)';
}
