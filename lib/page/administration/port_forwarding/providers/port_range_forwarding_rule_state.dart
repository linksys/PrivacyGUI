import 'package:equatable/equatable.dart';
import 'package:linksys_app/core/jnap/models/port_range_forwarding_rule.dart';
import 'package:linksys_app/page/administration/port_forwarding/providers/consts.dart';

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
}
