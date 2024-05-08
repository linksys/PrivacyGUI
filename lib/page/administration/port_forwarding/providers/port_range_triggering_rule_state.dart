import 'package:equatable/equatable.dart';
import 'package:linksys_app/core/jnap/models/port_range_triggering_rule.dart';
import 'package:linksys_app/page/administration/port_forwarding/providers/consts.dart';

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
}
