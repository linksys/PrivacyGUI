// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

/// UI Model for a single static routing rule (not JNAP model)
class StaticRoutingRuleUIModel extends Equatable {
  final String name;
  final String destinationIP;
  final int networkPrefixLength;
  final String? gateway;
  final String interface;

  const StaticRoutingRuleUIModel({
    required this.name,
    required this.destinationIP,
    required this.networkPrefixLength,
    this.gateway,
    required this.interface,
  });

  @override
  List<Object?> get props => [name, destinationIP, networkPrefixLength, gateway, interface];

  StaticRoutingRuleUIModel copyWith({
    String? name,
    String? destinationIP,
    int? networkPrefixLength,
    String? gateway,
    String? interface,
  }) {
    return StaticRoutingRuleUIModel(
      name: name ?? this.name,
      destinationIP: destinationIP ?? this.destinationIP,
      networkPrefixLength: networkPrefixLength ?? this.networkPrefixLength,
      gateway: gateway ?? this.gateway,
      interface: interface ?? this.interface,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'destinationIP': destinationIP,
      'networkPrefixLength': networkPrefixLength,
      'gateway': gateway,
      'interface': interface,
    };
  }

  factory StaticRoutingRuleUIModel.fromMap(Map<String, dynamic> map) {
    return StaticRoutingRuleUIModel(
      name: map['name'] ?? '',
      destinationIP: map['destinationIP'] ?? '',
      networkPrefixLength: map['networkPrefixLength'] ?? 24,
      gateway: map['gateway'],
      interface: map['interface'] ?? 'LAN',
    );
  }

  String toJson() => json.encode(toMap());

  factory StaticRoutingRuleUIModel.fromJson(String source) =>
      StaticRoutingRuleUIModel.fromMap(json.decode(source));
}

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
