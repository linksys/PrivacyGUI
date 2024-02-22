import 'package:equatable/equatable.dart';
import 'package:linksys_app/core/jnap/models/ipv6_firewall_rule.dart';

class Ipv6PortServiceRuleState extends Equatable {
  final Ipv6PortServiceRuleMode mode;
  final List<IPv6FirewallRule> rules;
  final IPv6FirewallRule? rule;

  const Ipv6PortServiceRuleState({
    this.mode = Ipv6PortServiceRuleMode.init,
    this.rules = const [],
    this.rule,
  });

  @override
  List<Object?> get props => [mode, rules, rule];

  Ipv6PortServiceRuleState copyWith({
    Ipv6PortServiceRuleMode? mode,
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

enum Ipv6PortServiceRuleMode {
  init,
  adding,
  editing,
}
