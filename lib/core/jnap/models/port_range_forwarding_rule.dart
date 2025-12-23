import 'dart:convert';

import 'package:equatable/equatable.dart';

/// isEnabled : true
/// externalPort : 3074
/// protocol : "TCP"
/// internalServerIPAddress : "192.168.1.150"
/// lastExternalPort : 3074
/// description : "XBox Live (TM)"

class PortRangeForwardingRule extends Equatable {
  const PortRangeForwardingRule({
    required this.isEnabled,
    required this.firstExternalPort,
    required this.protocol,
    required this.internalServerIPAddress,
    required this.lastExternalPort,
    required this.description,
  });

  final bool isEnabled;
  final int firstExternalPort;
  final String protocol;
  final String internalServerIPAddress;
  final int lastExternalPort;
  final String description;

  @override
  List<Object> get props => [
        isEnabled,
        firstExternalPort,
        protocol,
        internalServerIPAddress,
        lastExternalPort,
        description,
      ];

  PortRangeForwardingRule copyWith({
    bool? isEnabled,
    int? firstExternalPort,
    String? protocol,
    String? internalServerIPAddress,
    int? lastExternalPort,
    String? description,
  }) {
    return PortRangeForwardingRule(
      isEnabled: isEnabled ?? this.isEnabled,
      firstExternalPort: firstExternalPort ?? this.firstExternalPort,
      protocol: protocol ?? this.protocol,
      internalServerIPAddress:
          internalServerIPAddress ?? this.internalServerIPAddress,
      lastExternalPort: lastExternalPort ?? this.lastExternalPort,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'firstExternalPort': firstExternalPort,
      'protocol': protocol,
      'internalServerIPAddress': internalServerIPAddress,
      'lastExternalPort': lastExternalPort,
      'description': description,
    };
  }

  factory PortRangeForwardingRule.fromMap(Map<String, dynamic> json) {
    return PortRangeForwardingRule(
      isEnabled: json['isEnabled'],
      firstExternalPort: json['firstExternalPort'],
      protocol: json['protocol'],
      internalServerIPAddress: json['internalServerIPAddress'],
      lastExternalPort: json['lastExternalPort'],
      description: json['description'],
    );
  }

  String toJson() => json.encode(toMap());

  factory PortRangeForwardingRule.fromJson(String source) =>
      PortRangeForwardingRule.fromMap(
          json.decode(source) as Map<String, dynamic>);
}

class PortRangeForwardingRuleList extends Equatable {
  final List<PortRangeForwardingRule> rules;

  const PortRangeForwardingRuleList({required this.rules});

  @override
  List<Object> get props => [rules];

  PortRangeForwardingRuleList copyWith({
    List<PortRangeForwardingRule>? rules,
  }) {
    return PortRangeForwardingRuleList(
      rules: rules ?? this.rules,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'rules': rules.map((x) => x.toMap()).toList(),
    };
  }

  factory PortRangeForwardingRuleList.fromMap(Map<String, dynamic> map) {
    return PortRangeForwardingRuleList(
      rules: List<PortRangeForwardingRule>.from(
        map['rules']?.map<PortRangeForwardingRule>(
              (x) => PortRangeForwardingRule.fromMap(x as Map<String, dynamic>),
            ) ??
            [],
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory PortRangeForwardingRuleList.fromJson(String source) =>
      PortRangeForwardingRuleList.fromMap(
          json.decode(source) as Map<String, dynamic>);
}
