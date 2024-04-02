import 'package:equatable/equatable.dart';
import 'package:linksys_app/core/jnap/models/single_port_forwarding_rule.dart';

class SinglePortForwardingRuleState extends Equatable {
  final SinglePortForwardingRuleMode mode;
  final List<SinglePortForwardingRule> rules;
  final SinglePortForwardingRule? rule;

  const SinglePortForwardingRuleState({
    this.mode = SinglePortForwardingRuleMode.init,
    this.rules = const [],
    this.rule,
  });

  @override
  List<Object?> get props => [mode, rules, rule];

  SinglePortForwardingRuleState copyWith({
    SinglePortForwardingRuleMode? mode,
    List<SinglePortForwardingRule>? rules,
    SinglePortForwardingRule? rule,
  }) {
    return SinglePortForwardingRuleState(
      mode: mode ?? this.mode,
      rules: rules ?? this.rules,
      rule: rule ?? this.rule,
    );
  }
}

enum SinglePortForwardingRuleMode {
  init,
  adding,
  editing,
}
