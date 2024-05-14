import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_firewall_rule.dart';
import 'package:privacy_gui/page/administration/port_forwarding/providers/consts.dart';

class Ipv6PortServiceRuleState extends Equatable {
  final RuleMode mode;
  final List<IPv6FirewallRule> rules;
  final IPv6FirewallRule? rule;

  const Ipv6PortServiceRuleState({
    this.mode = RuleMode.init,
    this.rules = const [],
    this.rule,
  });

  @override
  List<Object?> get props => [mode, rules, rule];

  Ipv6PortServiceRuleState copyWith({
    RuleMode? mode,
    List<IPv6FirewallRule>? rules,
    IPv6FirewallRule? rule,
  }) {
    return Ipv6PortServiceRuleState(
      mode: mode ?? this.mode,
      rules: rules ?? this.rules,
      rule: rule ?? this.rule,
    );
  }
}
