part of 'advanced_routing_list_cubit.dart';

class AdvancedRoutingListState extends Equatable {
  const AdvancedRoutingListState({
    this.rules = const [],
    this.maxRules = 50,
    this.maxDescriptionLength = 32,
  });

  final List<AdvancedRoutingRule> rules;
  final int maxRules;
  final int maxDescriptionLength;

  @override
  List<Object> get props => [rules, maxRules, maxDescriptionLength];

  AdvancedRoutingListState copyWith({
    List<AdvancedRoutingRule>? rules,
    int? maxRules,
    int? maxDescriptionLength,
  }) {
    return AdvancedRoutingListState(
      rules: rules ?? this.rules,
      maxRules: maxRules ?? this.maxRules,
      maxDescriptionLength: maxDescriptionLength ?? this.maxDescriptionLength,
    );
  }
}
