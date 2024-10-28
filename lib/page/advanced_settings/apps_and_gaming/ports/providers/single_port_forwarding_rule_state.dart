// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/consts.dart';

class SinglePortForwardingRuleState extends Equatable {
  final RuleMode mode;
  final List<SinglePortForwardingRule> rules;
  final SinglePortForwardingRule? rule;

  const SinglePortForwardingRuleState({
    this.mode = RuleMode.init,
    this.rules = const [],
    this.rule,
  });

  @override
  List<Object?> get props => [mode, rules, rule];

  SinglePortForwardingRuleState copyWith({
    RuleMode? mode,
    List<SinglePortForwardingRule>? rules,
    SinglePortForwardingRule? rule,
  }) {
    return SinglePortForwardingRuleState(
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

  factory SinglePortForwardingRuleState.fromMap(Map<String, dynamic> map) {
    return SinglePortForwardingRuleState(
      mode: map['mode'] != null ? RuleMode.reslove(map['mode']) : RuleMode.init,
      rules: List<SinglePortForwardingRule>.from(
        map['rules'].map<SinglePortForwardingRule>(
          (x) => SinglePortForwardingRule.fromMap(x as Map<String, dynamic>),
        ),
      ),
      rule: map['rule'] != null
          ? SinglePortForwardingRule.fromMap(
              map['rule'] as Map<String, dynamic>)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory SinglePortForwardingRuleState.fromJson(String source) =>
      SinglePortForwardingRuleState.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
