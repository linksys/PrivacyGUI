// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import 'package:privacy_gui/page/advanced_settings/static_routing/models/static_routing_rule_ui_model.dart';

class StaticRoutingRuleState extends Equatable {
  final List<StaticRoutingRuleUIModel> rules;
  final StaticRoutingRuleUIModel? rule;
  final int? editIndex;
  final String routerIp;
  final String subnetMask;

  const StaticRoutingRuleState({
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

  StaticRoutingRuleState copyWith({
    List<StaticRoutingRuleUIModel>? rules,
    ValueGetter<StaticRoutingRuleUIModel?>? rule,
    ValueGetter<int?>? editIndex,
    String? routerIp,
    String? subnetMask,
  }) {
    return StaticRoutingRuleState(
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

  factory StaticRoutingRuleState.fromMap(Map<String, dynamic> map) {
    return StaticRoutingRuleState(
      rules: List<StaticRoutingRuleUIModel>.from(
          map['rules']?.map((x) => StaticRoutingRuleUIModel.fromMap(x)) ?? []),
      rule: map['rule'] != null
          ? StaticRoutingRuleUIModel.fromMap(map['rule'])
          : null,
      editIndex: map['editIndex']?.toInt(),
      routerIp: map['routerIp'] ?? '',
      subnetMask: map['subnetMask'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory StaticRoutingRuleState.fromJson(String source) =>
      StaticRoutingRuleState.fromMap(json.decode(source));

  @override
  bool get stringify => true;

  @override
  String toString() {
    return 'StaticRoutingRuleState(rules: $rules, rule: $rule, editIndex: $editIndex, routerIp: $routerIp, subnetMask: $subnetMask)';
  }
}
