import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/ipv6_firewall_rule.dart';
import 'package:privacy_gui/providers/feature_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

class Ipv6PortServiceListStatus extends Equatable {
  final int maxRules;
  final int maxDescriptionLength;

  const Ipv6PortServiceListStatus({
    this.maxRules = 50,
    this.maxDescriptionLength = 32,
  });

  @override
  List<Object> get props => [maxRules, maxDescriptionLength];

  Ipv6PortServiceListStatus copyWith({
    int? maxRules,
    int? maxDescriptionLength,
  }) {
    return Ipv6PortServiceListStatus(
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

  factory Ipv6PortServiceListStatus.fromMap(Map<String, dynamic> map) {
    return Ipv6PortServiceListStatus(
      maxRules: map['maxRules'] as int? ?? 50,
      maxDescriptionLength: map['maxDescriptionLength'] as int? ?? 32,
    );
  }

  String toJson() => json.encode(toMap());

  factory Ipv6PortServiceListStatus.fromJson(String source) =>
      Ipv6PortServiceListStatus.fromMap(
          json.decode(source) as Map<String, dynamic>);
}

class Ipv6PortServiceListState
    extends FeatureState<IPv6FirewallRuleList, Ipv6PortServiceListStatus> {
  const Ipv6PortServiceListState({
    required super.settings,
    required super.status,
  });

  @override
  Ipv6PortServiceListState copyWith({
    Preservable<IPv6FirewallRuleList>? settings,
    Ipv6PortServiceListStatus? status,
  }) {
    return Ipv6PortServiceListState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'settings': settings.toMap((rules) => rules.toMap()),
      'status': status.toMap(),
    };
  }

  factory Ipv6PortServiceListState.fromMap(Map<String, dynamic> map) {
    return Ipv6PortServiceListState(
      settings: Preservable.fromMap(
        map['settings'] as Map<String, dynamic>,
        (valueMap) => IPv6FirewallRuleList.fromMap(valueMap as Map<String, dynamic>),
      ),
      status: Ipv6PortServiceListStatus.fromMap(
          map['status'] as Map<String, dynamic>),
    );
  }

  factory Ipv6PortServiceListState.fromJson(String source) =>
      Ipv6PortServiceListState.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [settings, status];
}
