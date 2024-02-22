import 'package:equatable/equatable.dart';
import 'package:linksys_app/core/jnap/models/port_range_forwarding_rule.dart';

class PortRangeForwardingListState extends Equatable {
  const PortRangeForwardingListState({
    this.rules = const [],
    this.maxRules = 50,
    this.maxDescriptionLength = 32,
  });

  final List<PortRangeForwardingRule> rules;
  final int maxRules;
  final int maxDescriptionLength;

  @override
  List<Object> get props => [rules, maxRules, maxDescriptionLength];

  PortRangeForwardingListState copyWith({
    List<PortRangeForwardingRule>? rules,
    int? maxRules,
    int? maxDescriptionLength,
  }) {
    return PortRangeForwardingListState(
      rules: rules ?? this.rules,
      maxRules: maxRules ?? this.maxRules,
      maxDescriptionLength: maxDescriptionLength ?? this.maxDescriptionLength,
    );
  }
}
