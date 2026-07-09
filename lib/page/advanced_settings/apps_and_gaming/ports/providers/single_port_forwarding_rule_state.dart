// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';

class SinglePortForwardingRuleState extends Equatable {
  final List<SinglePortForwardingRule> rules;
  final SinglePortForwardingRule? rule;
  final int? editIndex;
  final String routerIp;
  final String subnetMask;

  const SinglePortForwardingRuleState({
    this.rules = const [],
    this.rule,
    this.editIndex,
    required this.routerIp,
    required this.subnetMask,
  });

  @override
  List<Object?> get props {
    return [
      rules,
      rule,
      editIndex,
      routerIp,
      subnetMask,
    ];
  }

  SinglePortForwardingRuleState copyWith({
    List<SinglePortForwardingRule>? rules,
    ValueGetter<SinglePortForwardingRule?>? rule,
    ValueGetter<int?>? editIndex,
    String? routerIp,
    String? subnetMask,
  }) {
    return SinglePortForwardingRuleState(
      rules: rules ?? this.rules,
      rule: rule != null ? rule() : this.rule,
      editIndex: editIndex != null ? editIndex() : this.editIndex,
      routerIp: routerIp ?? this.routerIp,
      subnetMask: subnetMask ?? this.subnetMask,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rules': rules.map((x) => x.toMap()).toList(),
      'rule': rule?.toMap(),
      'editIndex': editIndex,
      'routerIp': routerIp,
      'subnetMask': subnetMask,
    };
  }

  factory SinglePortForwardingRuleState.fromMap(Map<String, dynamic> map) {
    return SinglePortForwardingRuleState(
      rules: List<SinglePortForwardingRule>.from(
          map['rules']?.map((x) => SinglePortForwardingRule.fromMap(x))),
      rule: map['rule'] != null
          ? SinglePortForwardingRule.fromMap(map['rule'])
          : null,
      editIndex: map['editIndex']?.toInt(),
      routerIp: map['routerIp'] ?? '',
      subnetMask: map['subnetMask'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory SinglePortForwardingRuleState.fromJson(String source) =>
      SinglePortForwardingRuleState.fromMap(json.decode(source));

  @override
  bool get stringify => true;

  @override
  String toString() {
    return 'SinglePortForwardingRuleState(rules: $rules, rule: $rule, editIndex: $editIndex, routerIp: $routerIp, subnetMask: $subnetMask)';
  }
}
