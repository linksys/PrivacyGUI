import 'package:equatable/equatable.dart';
import 'package:linksys_app/core/jnap/models/port_range_forwarding_rule.dart';

class PortRangeForwardingRuleState extends Equatable {
  final PortRangeForwardingRuleMode mode;
  final List<PortRangeForwardingRule> rules;
  final PortRangeForwardingRule? rule;

  const PortRangeForwardingRuleState({
    this.mode = PortRangeForwardingRuleMode.init,
    this.rules = const [],
    this.rule,
  });

  @override
  List<Object?> get props => [mode, rules, rule];

  PortRangeForwardingRuleState copyWith({
    PortRangeForwardingRuleMode? mode,
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

enum PortRangeForwardingRuleMode {
  init,
  adding,
  editing,
}
