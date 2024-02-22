import 'package:equatable/equatable.dart';
import 'package:linksys_app/core/jnap/models/port_range_triggering_rule.dart';

class PortRangeTriggeringListState extends Equatable {
  const PortRangeTriggeringListState({
    this.rules = const [],
    this.maxRules = 50,
    this.maxDescriptionLength = 32,
  });

  final List<PortRangeTriggeringRule> rules;
  final int maxRules;
  final int maxDescriptionLength;

  @override
  List<Object> get props => [rules, maxRules, maxDescriptionLength];

  PortRangeTriggeringListState copyWith({
    List<PortRangeTriggeringRule>? rules,
    int? maxRules,
    int? maxDescriptionLength,
  }) {
    return PortRangeTriggeringListState(
      rules: rules ?? this.rules,
      maxRules: maxRules ?? this.maxRules,
      maxDescriptionLength: maxDescriptionLength ?? this.maxDescriptionLength,
    );
  }
}
