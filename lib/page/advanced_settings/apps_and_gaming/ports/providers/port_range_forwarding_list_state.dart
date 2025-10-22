// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/port_range_forwarding_rule.dart';
import 'package:privacy_gui/providers/feature_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

class PortRangeForwardingListStatus extends Equatable {
  final int maxRules;
  final int maxDescriptionLength;
  final String routerIp;
  final String subnetMask;

  const PortRangeForwardingListStatus({
    this.maxRules = 50,
    this.maxDescriptionLength = 32,
    this.routerIp = '192.168.1.1',
    this.subnetMask = '255.255.255.0',
  });

  @override
  List<Object> get props => [
        maxRules,
        maxDescriptionLength,
        routerIp,
        subnetMask,
      ];

  PortRangeForwardingListStatus copyWith({
    int? maxRules,
    int? maxDescriptionLength,
    String? routerIp,
    String? subnetMask,
  }) {
    return PortRangeForwardingListStatus(
      maxRules: maxRules ?? this.maxRules,
      maxDescriptionLength: maxDescriptionLength ?? this.maxDescriptionLength,
      routerIp: routerIp ?? this.routerIp,
      subnetMask: subnetMask ?? this.subnetMask,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'maxRules': maxRules,
      'maxDescriptionLength': maxDescriptionLength,
      'routerIp': routerIp,
      'subnetMask': subnetMask,
    };
  }

  factory PortRangeForwardingListStatus.fromMap(Map<String, dynamic> map) {
    return PortRangeForwardingListStatus(
      maxRules: map['maxRules']?.toInt() ?? 50,
      maxDescriptionLength: map['maxDescriptionLength']?.toInt() ?? 32,
      routerIp: map['routerIp'] ?? '192.168.1.1',
      subnetMask: map['subnetMask'] ?? '255.255.255.0',
    );
  }

  String toJson() => json.encode(toMap());

  factory PortRangeForwardingListStatus.fromJson(String source) =>
      PortRangeForwardingListStatus.fromMap(
          json.decode(source) as Map<String, dynamic>);
}

class PortRangeForwardingListState extends FeatureState<
    PortRangeForwardingRuleList,
    PortRangeForwardingListStatus> {
  const PortRangeForwardingListState({
    required super.settings,
    required super.status,
  });

  @override
  PortRangeForwardingListState copyWith({
    Preservable<PortRangeForwardingRuleList>? settings,
    PortRangeForwardingListStatus? status,
  }) {
    return PortRangeForwardingListState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'settings': settings.toMap((s) => s.toMap()),
      'status': status.toMap(),
    };
  }

  factory PortRangeForwardingListState.fromMap(Map<String, dynamic> map) {
    return PortRangeForwardingListState(
      settings: Preservable.fromMap(
        map['settings'] as Map<String, dynamic>,
        (valueMap) => PortRangeForwardingRuleList.fromMap(
            valueMap as Map<String, dynamic>),
      ),
      status: PortRangeForwardingListStatus.fromMap(
          map['status'] as Map<String, dynamic>),
    );
  }

  factory PortRangeForwardingListState.fromJson(String source) =>
      PortRangeForwardingListState.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [settings, status];
}
