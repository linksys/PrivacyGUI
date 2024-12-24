// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';

class SinglePortForwardingListState extends Equatable {
  const SinglePortForwardingListState({
    this.rules = const [],
    this.maxRules = 50,
    this.maxDescriptionLength = 32,
    this.routerIp = '192.168.1.1',
    this.subnetMask = '255.255.255.0',
  });

  final List<SinglePortForwardingRule> rules;
  final int maxRules;
  final int maxDescriptionLength;
  final String routerIp;
  final String subnetMask;

  @override
  List<Object> get props => [
        rules,
        maxRules,
        maxDescriptionLength,
        routerIp,
        subnetMask,
      ];

  SinglePortForwardingListState copyWith({
    List<SinglePortForwardingRule>? rules,
    int? maxRules,
    int? maxDescriptionLength,
    String? routerIp,
    String? subnetMask,
  }) {
    return SinglePortForwardingListState(
      rules: rules ?? this.rules,
      maxRules: maxRules ?? this.maxRules,
      maxDescriptionLength: maxDescriptionLength ?? this.maxDescriptionLength,
      routerIp: routerIp ?? this.routerIp,
      subnetMask: subnetMask ?? this.subnetMask,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'rules': rules.map((x) => x.toMap()).toList(),
      'maxRules': maxRules,
      'maxDescriptionLength': maxDescriptionLength,
      'routerIp': routerIp,
      'subnetMask': subnetMask,
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
      routerIp: map['routerIp'] ?? '192.168.1.1',
      subnetMask: map['subnetMask'] ?? '255.255.255.0',
    );
  }

  String toJson() => json.encode(toMap());

  factory SinglePortForwardingListState.fromJson(String source) =>
      SinglePortForwardingListState.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
