import 'dart:convert';

import 'package:equatable/equatable.dart';

class SinglePortForwardingRule extends Equatable {
  const SinglePortForwardingRule({
    required this.isEnabled,
    required this.externalPort,
    required this.protocol,
    required this.internalServerIPAddress,
    required this.internalPort,
    required this.description,
  });

  final bool isEnabled;
  final int externalPort;
  final String protocol;
  final String internalServerIPAddress;
  final int internalPort;
  final String description;

  @override
  List<Object> get props => [
        isEnabled,
        externalPort,
        protocol,
        internalServerIPAddress,
        internalPort,
        description,
      ];

  SinglePortForwardingRule copyWith({
    bool? isEnabled,
    int? externalPort,
    String? protocol,
    String? internalServerIPAddress,
    int? internalPort,
    String? description,
  }) {
    return SinglePortForwardingRule(
      isEnabled: isEnabled ?? this.isEnabled,
      externalPort: externalPort ?? this.externalPort,
      protocol: protocol ?? this.protocol,
      internalServerIPAddress:
          internalServerIPAddress ?? this.internalServerIPAddress,
      internalPort: internalPort ?? this.internalPort,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'externalPort': externalPort,
      'protocol': protocol,
      'internalServerIPAddress': internalServerIPAddress,
      'internalPort': internalPort,
      'description': description,
    };
  }

  factory SinglePortForwardingRule.fromMap(Map<String, dynamic> json) {
    return SinglePortForwardingRule(
      isEnabled: json['isEnabled'],
      externalPort: json['externalPort'],
      protocol: json['protocol'],
      internalServerIPAddress: json['internalServerIPAddress'],
      internalPort: json['internalPort'],
      description: json['description'],
    );
  }

  String toJson() => json.encode(toMap());

  factory SinglePortForwardingRule.fromJson(String source) =>
      SinglePortForwardingRule.fromMap(
          json.decode(source) as Map<String, dynamic>);
}

class SinglePortForwardingRuleList extends Equatable {
  final List<SinglePortForwardingRule> rules;

  const SinglePortForwardingRuleList({required this.rules});

  @override
  List<Object> get props => [rules];

  SinglePortForwardingRuleList copyWith({
    List<SinglePortForwardingRule>? rules,
  }) {
    return SinglePortForwardingRuleList(
      rules: rules ?? this.rules,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'rules': rules.map((x) => x.toMap()).toList(),
    };
  }

  factory SinglePortForwardingRuleList.fromMap(Map<String, dynamic> map) {
    return SinglePortForwardingRuleList(
      rules: List<SinglePortForwardingRule>.from(
        map['rules']?.map<SinglePortForwardingRule>(
              (x) =>
                  SinglePortForwardingRule.fromMap(x as Map<String, dynamic>),
            ) ??
            [],
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory SinglePortForwardingRuleList.fromJson(String source) =>
      SinglePortForwardingRuleList.fromMap(
          json.decode(source) as Map<String, dynamic>);
}
