import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';

class SinglePortForwardingListState extends Equatable {
  const SinglePortForwardingListState({
    this.rules = const [],
    this.maxRules = 50,
    this.maxDescriptionLength = 32,
  });

  final List<SinglePortForwardingRule> rules;
  final int maxRules;
  final int maxDescriptionLength;

  @override
  List<Object> get props => [rules, maxRules, maxDescriptionLength];

  SinglePortForwardingListState copyWith({
    List<SinglePortForwardingRule>? rules,
    int? maxRules,
    int? maxDescriptionLength,
  }) {
    return SinglePortForwardingListState(
      rules: rules ?? this.rules,
      maxRules: maxRules ?? this.maxRules,
      maxDescriptionLength: maxDescriptionLength ?? this.maxDescriptionLength,
    );
  }
}
