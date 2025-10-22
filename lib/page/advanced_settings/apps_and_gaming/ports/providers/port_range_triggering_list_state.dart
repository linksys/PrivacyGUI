// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/port_range_triggering_rule.dart';
import 'package:privacy_gui/providers/feature_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

class PortRangeTriggeringListStatus extends Equatable {
  final int maxRules;
  final int maxDescriptionLength;

  const PortRangeTriggeringListStatus({
    this.maxRules = 50,
    this.maxDescriptionLength = 32,
  });

  @override
  List<Object> get props => [maxRules, maxDescriptionLength];

  PortRangeTriggeringListStatus copyWith({
    int? maxRules,
    int? maxDescriptionLength,
  }) {
    return PortRangeTriggeringListStatus(
      maxRules: maxRules ?? this.maxRules,
      maxDescriptionLength: maxDescriptionLength ?? this.maxDescriptionLength,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'maxRules': maxRules,
      'maxDescriptionLength': maxDescriptionLength,
    };
  }

  factory PortRangeTriggeringListStatus.fromMap(Map<String, dynamic> map) {
    return PortRangeTriggeringListStatus(
      maxRules: map['maxRules']?.toInt() ?? 50,
      maxDescriptionLength: map['maxDescriptionLength']?.toInt() ?? 32,
    );
  }

  String toJson() => json.encode(toMap());

  factory PortRangeTriggeringListStatus.fromJson(String source) =>
      PortRangeTriggeringListStatus.fromMap(
          json.decode(source) as Map<String, dynamic>);
}

class PortRangeTriggeringListState extends FeatureState<
    PortRangeTriggeringRuleList,
    PortRangeTriggeringListStatus> {
  const PortRangeTriggeringListState({
    required super.settings,
    required super.status,
  });

  @override
  PortRangeTriggeringListState copyWith({
    Preservable<PortRangeTriggeringRuleList>? settings,
    PortRangeTriggeringListStatus? status,
  }) {
    return PortRangeTriggeringListState(
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

  factory PortRangeTriggeringListState.fromMap(Map<String, dynamic> map) {
    return PortRangeTriggeringListState(
      settings: Preservable.fromMap(
        map['settings'] as Map<String, dynamic>,
        (valueMap) => PortRangeTriggeringRuleList.fromMap(
            valueMap as Map<String, dynamic>),
      ),
      status: PortRangeTriggeringListStatus.fromMap(
          map['status'] as Map<String, dynamic>),
    );
  }

  factory PortRangeTriggeringListState.fromJson(String source) =>
      PortRangeTriggeringListState.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [settings, status];
}
