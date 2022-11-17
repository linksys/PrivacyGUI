part of 'advanced_routing_rule_cubit.dart';

abstract class AdvancedRoutingRuleState extends Equatable {
  final List<AdvancedRoutingRule> rules;

  const AdvancedRoutingRuleState({required this.rules});

  @override
  List<Object?> get props => [rules];
}

class AdvancedRoutingRuleInitial extends AdvancedRoutingRuleState {
  AdvancedRoutingRuleInitial() : super(rules: []);

  @override
  List<Object?> get props => [];
}

class AddAdvancedRoutingRule extends AdvancedRoutingRuleState {
  const AddAdvancedRoutingRule({required super.rules});

  AddAdvancedRoutingRule copyWith({
    List<AdvancedRoutingRule>? rules,
  }) {
    return AddAdvancedRoutingRule(
      rules: rules ?? this.rules,
    );
  }
}

class EditAdvancedRoutingRule extends AdvancedRoutingRuleState {
  const EditAdvancedRoutingRule({required super.rules, required this.rule});

  final AdvancedRoutingRule rule;

  @override
  List<Object?> get props => [rule, rules];

  EditAdvancedRoutingRule copyWith({
    List<AdvancedRoutingRule>? rules,
    AdvancedRoutingRule? rule,
  }) {
    return EditAdvancedRoutingRule(
      rules: rules ?? this.rules,
      rule: rule ?? this.rule,
    );
  }
}
