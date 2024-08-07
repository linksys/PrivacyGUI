import 'dart:convert';

import 'package:equatable/equatable.dart';

/// isEnabled : true
/// externalPort : 3074
/// protocol : "TCP"
/// internalServerIPAddress : "192.168.1.150"
/// internalPort : 3074
/// description : "XBox Live (TM)"

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
