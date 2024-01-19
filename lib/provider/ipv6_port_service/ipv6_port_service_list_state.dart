import 'package:equatable/equatable.dart';
import 'package:linksys_app/core/jnap/models/ipv6_firewall_rule.dart';

class Ipv6PortServiceListState extends Equatable {
  const Ipv6PortServiceListState({
    this.rules = const [],
    this.maxRules = 50,
    this.maxDescriptionLength = 32,
  });

  final List<IPv6FirewallRule> rules;
  final int maxRules;
  final int maxDescriptionLength;

  @override
  List<Object> get props => [rules, maxRules, maxDescriptionLength];

  Ipv6PortServiceListState copyWith({
    List<IPv6FirewallRule>? rules,
    int? maxRules,
    int? maxDescriptionLength,
  }) {
    return Ipv6PortServiceListState(
      rules: rules ?? this.rules,
      maxRules: maxRules ?? this.maxRules,
      maxDescriptionLength: maxDescriptionLength ?? this.maxDescriptionLength,
    );
  }
}
