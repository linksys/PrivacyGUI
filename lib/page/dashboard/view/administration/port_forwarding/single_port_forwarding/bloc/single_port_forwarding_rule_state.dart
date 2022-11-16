part of 'single_port_forwarding_rule_cubit.dart';

abstract class SinglePortForwardingRuleState extends Equatable {
  final List<SinglePortForwardingRule> rules;

  const SinglePortForwardingRuleState({required this.rules});

  @override
  List<Object?> get props => [rules];
}

class SinglePortForwardingRuleInitial extends SinglePortForwardingRuleState {
  SinglePortForwardingRuleInitial() : super(rules: []);

  @override
  List<Object?> get props => [];
}

class AddSinglePortForwardingRule extends SinglePortForwardingRuleState {
  const AddSinglePortForwardingRule({required super.rules});

  AddSinglePortForwardingRule copyWith({
    List<SinglePortForwardingRule>? rules,
  }) {
    return AddSinglePortForwardingRule(
      rules: rules ?? this.rules,
    );
  }
}

class EditSinglePortForwardingRule extends SinglePortForwardingRuleState {
  const EditSinglePortForwardingRule({required super.rules, required this.rule});

  final SinglePortForwardingRule rule;

  @override
  List<Object?> get props => [rule, rules];

  EditSinglePortForwardingRule copyWith({
    List<SinglePortForwardingRule>? rules,
    SinglePortForwardingRule? rule,
  }) {
    return EditSinglePortForwardingRule(
      rules: rules ?? this.rules,
      rule: rule ?? this.rule,
    );
  }
}
