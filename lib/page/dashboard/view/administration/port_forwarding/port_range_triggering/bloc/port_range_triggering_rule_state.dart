part of 'port_range_triggering_rule_cubit.dart';

abstract class PortRangeTriggeringRuleState extends Equatable {
  final List<PortRangeTriggeringRule> rules;

  const PortRangeTriggeringRuleState({required this.rules});

  @override
  List<Object?> get props => [rules];
}

class PortRangeTriggeringRuleInitial extends PortRangeTriggeringRuleState {
  PortRangeTriggeringRuleInitial() : super(rules: []);

  @override
  List<Object?> get props => [];
}

class AddPortRangeTriggeringRule extends PortRangeTriggeringRuleState {
  const AddPortRangeTriggeringRule({required super.rules});

  AddPortRangeTriggeringRule copyWith({
    List<PortRangeTriggeringRule>? rules,
  }) {
    return AddPortRangeTriggeringRule(
      rules: rules ?? this.rules,
    );
  }
}

class EditPortRangeTriggeringRule extends PortRangeTriggeringRuleState {
  const EditPortRangeTriggeringRule({required super.rules, required this.rule});

  final PortRangeTriggeringRule rule;

  @override
  List<Object?> get props => [rule, rules];

  EditPortRangeTriggeringRule copyWith({
    List<PortRangeTriggeringRule>? rules,
    PortRangeTriggeringRule? rule,
  }) {
    return EditPortRangeTriggeringRule(
      rules: rules ?? this.rules,
      rule: rule ?? this.rule,
    );
  }
}
