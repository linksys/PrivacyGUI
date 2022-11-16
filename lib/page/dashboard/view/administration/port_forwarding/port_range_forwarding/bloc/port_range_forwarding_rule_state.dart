part of 'port_range_forwarding_rule_cubit.dart';

abstract class PortRangeForwardingRuleState extends Equatable {
  final List<PortRangeForwardingRule> rules;

  const PortRangeForwardingRuleState({required this.rules});

  @override
  List<Object?> get props => [rules];
}

class PortRangeForwardingRuleInitial extends PortRangeForwardingRuleState {
  PortRangeForwardingRuleInitial() : super(rules: []);

  @override
  List<Object?> get props => [];
}

class AddPortRangeForwardingRule extends PortRangeForwardingRuleState {
  const AddPortRangeForwardingRule({required super.rules});

  AddPortRangeForwardingRule copyWith({
    List<PortRangeForwardingRule>? rules,
  }) {
    return AddPortRangeForwardingRule(
      rules: rules ?? this.rules,
    );
  }
}

class EditPortRangeForwardingRule extends PortRangeForwardingRuleState {
  const EditPortRangeForwardingRule({required super.rules, required this.rule});

  final PortRangeForwardingRule rule;

  @override
  List<Object?> get props => [rule, rules];

  EditPortRangeForwardingRule copyWith({
    List<PortRangeForwardingRule>? rules,
    PortRangeForwardingRule? rule,
  }) {
    return EditPortRangeForwardingRule(
      rules: rules ?? this.rules,
      rule: rule ?? this.rule,
    );
  }
}
