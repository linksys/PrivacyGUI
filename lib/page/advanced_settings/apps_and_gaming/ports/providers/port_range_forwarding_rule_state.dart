// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import 'package:privacy_gui/core/jnap/models/port_range_forwarding_rule.dart';

class PortRangeForwardingRuleState extends Equatable {
  final List<PortRangeForwardingRule> rules;
  final PortRangeForwardingRule? rule;
  final int? editIndex;
  final String routerIp;
  final String subnetMask;

  const PortRangeForwardingRuleState({
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

  PortRangeForwardingRuleState copyWith({
    List<PortRangeForwardingRule>? rules,
    ValueGetter<PortRangeForwardingRule?>? rule,
    ValueGetter<int?>? editIndex,
    String? routerIp,
    String? subnetMask,
  }) {
    return PortRangeForwardingRuleState(
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

  factory PortRangeForwardingRuleState.fromMap(Map<String, dynamic> map) {
    return PortRangeForwardingRuleState(
      rules: List<PortRangeForwardingRule>.from(map['rules']?.map((x) => PortRangeForwardingRule.fromMap(x))),
      rule: map['rule'] != null ? PortRangeForwardingRule.fromMap(map['rule']) : null,
      editIndex: map['editIndex']?.toInt(),
      routerIp: map['routerIp'] ?? '',
      subnetMask: map['subnetMask'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory PortRangeForwardingRuleState.fromJson(String source) => PortRangeForwardingRuleState.fromMap(json.decode(source));

  @override
  bool get stringify => true;

  @override
  String toString() {
    return 'PortRangeForwardingRuleState(rules: $rules, rule: $rule, editIndex: $editIndex, routerIp: $routerIp, subnetMask: $subnetMask)';
  }
}
