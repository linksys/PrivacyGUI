// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/port_range_forwarding_rule.dart';

class PortRangeForwardingListState extends Equatable {
  const PortRangeForwardingListState({
    this.rules = const [],
    this.maxRules = 50,
    this.maxDescriptionLength = 32,
    this.routerIp = '192.168.1.1',
    this.subnetMask = '255.255.255.0',
  });

  final List<PortRangeForwardingRule> rules;
  final int maxRules;
  final int maxDescriptionLength;
  final String routerIp;
  final String subnetMask;

  @override
  List<Object> get props {
    return [
      rules,
      maxRules,
      maxDescriptionLength,
      routerIp,
      subnetMask,
    ];
  }

  PortRangeForwardingListState copyWith({
    List<PortRangeForwardingRule>? rules,
    int? maxRules,
    int? maxDescriptionLength,
    String? routerIp,
    String? subnetMask,
  }) {
    return PortRangeForwardingListState(
      rules: rules ?? this.rules,
      maxRules: maxRules ?? this.maxRules,
      maxDescriptionLength: maxDescriptionLength ?? this.maxDescriptionLength,
      routerIp: routerIp ?? this.routerIp,
      subnetMask: subnetMask ?? this.subnetMask,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rules': rules.map((x) => x.toMap()).toList(),
      'maxRules': maxRules,
      'maxDescriptionLength': maxDescriptionLength,
      'routerIp': routerIp,
      'subnetMask': subnetMask,
    };
  }

  factory PortRangeForwardingListState.fromMap(Map<String, dynamic> map) {
    return PortRangeForwardingListState(
      rules: List<PortRangeForwardingRule>.from(
          map['rules']?.map((x) => PortRangeForwardingRule.fromMap(x))),
      maxRules: map['maxRules']?.toInt() ?? 0,
      maxDescriptionLength: map['maxDescriptionLength']?.toInt() ?? 0,
      routerIp: map['routerIp'] ?? '',
      subnetMask: map['subnetMask'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory PortRangeForwardingListState.fromJson(String source) =>
      PortRangeForwardingListState.fromMap(json.decode(source));

  @override
  bool get stringify => true;

  @override
  String toString() {
    return 'PortRangeForwardingListState(rules: $rules, maxRules: $maxRules, maxDescriptionLength: $maxDescriptionLength, routerIp: $routerIp, subnetMask: $subnetMask)';
  }
}
