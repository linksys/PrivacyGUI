// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/port_range_triggering_rule.dart';
import 'package:privacy_gui/page/advanced_settings/port_forwarding/providers/consts.dart';

class PortRangeTriggeringRuleState extends Equatable {
  final RuleMode mode;
  final List<PortRangeTriggeringRule> rules;
  final PortRangeTriggeringRule? rule;

  const PortRangeTriggeringRuleState({
    this.mode = RuleMode.init,
    this.rules = const [],
    this.rule,
  });

  @override
  List<Object?> get props => [mode, rules, rule];

  PortRangeTriggeringRuleState copyWith({
    RuleMode? mode,
    List<PortRangeTriggeringRule>? rules,
    PortRangeTriggeringRule? rule,
  }) {
    return PortRangeTriggeringRuleState(
      mode: mode ?? this.mode,
      rules: rules ?? this.rules,
      rule: rule ?? this.rule,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'mode': mode.name,
      'rules': rules.map((x) => x.toMap()).toList(),
      'rule': rule?.toMap(),
    };
  }

  factory PortRangeTriggeringRuleState.fromMap(Map<String, dynamic> map) {
    return PortRangeTriggeringRuleState(
      mode: map['mode'] != null ? RuleMode.reslove(map['mode']) : RuleMode.init,
      rules: List<PortRangeTriggeringRule>.from((map['rules'] as List<int>).map<PortRangeTriggeringRule>((x) => PortRangeTriggeringRule.fromMap(x as Map<String,dynamic>),),),
      rule: map['rule'] != null ? PortRangeTriggeringRule.fromMap(map['rule'] as Map<String,dynamic>) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory PortRangeTriggeringRuleState.fromJson(String source) => PortRangeTriggeringRuleState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
