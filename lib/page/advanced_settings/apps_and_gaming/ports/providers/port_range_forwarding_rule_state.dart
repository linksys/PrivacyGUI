// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/port_range_forwarding_rule.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/consts.dart';

class PortRangeForwardingRuleState extends Equatable {
  final RuleMode mode;
  final List<PortRangeForwardingRule> rules;
  final PortRangeForwardingRule? rule;

  const PortRangeForwardingRuleState({
    this.mode = RuleMode.init,
    this.rules = const [],
    this.rule,
  });

  @override
  List<Object?> get props => [mode, rules, rule];

  PortRangeForwardingRuleState copyWith({
    RuleMode? mode,
    List<PortRangeForwardingRule>? rules,
    PortRangeForwardingRule? rule,
  }) {
    return PortRangeForwardingRuleState(
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

  factory PortRangeForwardingRuleState.fromMap(Map<String, dynamic> map) {
    return PortRangeForwardingRuleState(
      mode: map['mode'] != null ? RuleMode.reslove(map['mode']) : RuleMode.init,
      rules: List<PortRangeForwardingRule>.from(
        map['rules'].map<PortRangeForwardingRule>(
          (x) => PortRangeForwardingRule.fromMap(x as Map<String, dynamic>),
        ),
      ),
      rule: map['rule'] != null
          ? PortRangeForwardingRule.fromMap(map['rule'] as Map<String, dynamic>)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory PortRangeForwardingRuleState.fromJson(String source) =>
      PortRangeForwardingRuleState.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
