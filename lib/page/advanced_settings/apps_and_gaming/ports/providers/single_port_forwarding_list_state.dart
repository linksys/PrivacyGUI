// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/single_port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/providers/feature_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

class SinglePortForwardingListStatus extends Equatable {
  final int maxRules;
  final int maxDescriptionLength;
  final String routerIp;
  final String subnetMask;

  const SinglePortForwardingListStatus({
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

  SinglePortForwardingListStatus copyWith({
    int? maxRules,
    int? maxDescriptionLength,
    String? routerIp,
    String? subnetMask,
  }) {
    return SinglePortForwardingListStatus(
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

  factory SinglePortForwardingListStatus.fromMap(Map<String, dynamic> map) {
    return SinglePortForwardingListStatus(
      maxRules: map['maxRules']?.toInt() ?? 50,
      maxDescriptionLength: map['maxDescriptionLength']?.toInt() ?? 32,
      routerIp: map['routerIp'] ?? '192.168.1.1',
      subnetMask: map['subnetMask'] ?? '255.255.255.0',
    );
  }

  String toJson() => json.encode(toMap());

  factory SinglePortForwardingListStatus.fromJson(String source) =>
      SinglePortForwardingListStatus.fromMap(
          json.decode(source) as Map<String, dynamic>);
}

class SinglePortForwardingListState extends FeatureState<
    SinglePortForwardingRuleListUIModel, SinglePortForwardingListStatus> {
  const SinglePortForwardingListState({
    required super.settings,
    required super.status,
  });

  @override
  SinglePortForwardingListState copyWith({
    Preservable<SinglePortForwardingRuleListUIModel>? settings,
    SinglePortForwardingListStatus? status,
  }) {
    return SinglePortForwardingListState(
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

  factory SinglePortForwardingListState.fromMap(Map<String, dynamic> map) {
    return SinglePortForwardingListState(
      settings: Preservable.fromMap(
        map['settings'] as Map<String, dynamic>,
        (valueMap) => SinglePortForwardingRuleListUIModel.fromMap(
            valueMap as Map<String, dynamic>),
      ),
      status: SinglePortForwardingListStatus.fromMap(
          map['status'] as Map<String, dynamic>),
    );
  }

  factory SinglePortForwardingListState.fromJson(String source) =>
      SinglePortForwardingListState.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [settings, status];
}
