import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:privacy_gui/page/administration/port_forwarding/providers/consts.dart';

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
}
