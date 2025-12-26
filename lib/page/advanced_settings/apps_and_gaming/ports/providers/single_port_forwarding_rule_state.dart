// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/single_port_forwarding_rule_ui_model.dart';

class SinglePortForwardingRuleState extends Equatable {
  final List<SinglePortForwardingRuleUIModel> rules;
  final SinglePortForwardingRuleUIModel? rule;
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
    List<SinglePortForwardingRuleUIModel>? rules,
    ValueGetter<SinglePortForwardingRuleUIModel?>? rule,
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
      rules: List<SinglePortForwardingRuleUIModel>.from(
          map['rules']?.map((x) => SinglePortForwardingRuleUIModel.fromMap(x))),
      rule: map['rule'] != null
          ? SinglePortForwardingRuleUIModel.fromMap(map['rule'])
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
