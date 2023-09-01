import 'package:equatable/equatable.dart';
import 'package:linksys_app/core/jnap/models/port_range_triggering_rule.dart';

class PortRangeTriggeringRuleState extends Equatable {
  final PortRangeTriggeringRuleMode mode;
  final List<PortRangeTriggeringRule> rules;
  final PortRangeTriggeringRule? rule;

  const PortRangeTriggeringRuleState({
    this.mode = PortRangeTriggeringRuleMode.init,
    this.rules = const [],
    this.rule,
  });

  @override
  List<Object?> get props => [mode, rules, rule];

  PortRangeTriggeringRuleState copyWith({
    PortRangeTriggeringRuleMode? mode,
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

enum PortRangeTriggeringRuleMode {
  init,
  adding,
  editing,
}
