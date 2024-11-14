// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

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

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'rules': rules.map((x) => x.toMap()).toList(),
      'maxRules': maxRules,
      'maxDescriptionLength': maxDescriptionLength,
    };
  }

  factory SinglePortForwardingListState.fromMap(Map<String, dynamic> map) {
    return SinglePortForwardingListState(
      rules: List<SinglePortForwardingRule>.from(
        map['rules'].map<SinglePortForwardingRule>(
          (x) => SinglePortForwardingRule.fromMap(x as Map<String, dynamic>),
        ),
      ),
      maxRules: map['maxRules'] != null ? map['maxRules'] as int : 50,
      maxDescriptionLength: map['maxDescriptionLength'] != null
          ? map['maxDescriptionLength'] as int
          : 32,
    );
  }

  String toJson() => json.encode(toMap());

  factory SinglePortForwardingListState.fromJson(String source) =>
      SinglePortForwardingListState.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
