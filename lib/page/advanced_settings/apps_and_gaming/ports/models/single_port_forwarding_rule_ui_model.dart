import 'dart:convert';

import 'package:equatable/equatable.dart';

/// UI Model for Single Port Forwarding Rule
///
/// This model is used in the Presentation and Application layers.
/// It provides a clean interface for UI components and business logic,
/// separated from the underlying JNAP data models.
class SinglePortForwardingRuleUIModel extends Equatable {
  const SinglePortForwardingRuleUIModel({
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

  SinglePortForwardingRuleUIModel copyWith({
    bool? isEnabled,
    int? externalPort,
    String? protocol,
    String? internalServerIPAddress,
    int? internalPort,
    String? description,
  }) {
    return SinglePortForwardingRuleUIModel(
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

  factory SinglePortForwardingRuleUIModel.fromMap(Map<String, dynamic> map) {
    return SinglePortForwardingRuleUIModel(
      isEnabled: map['isEnabled'] as bool,
      externalPort: map['externalPort'] as int,
      protocol: map['protocol'] as String,
      internalServerIPAddress: map['internalServerIPAddress'] as String,
      internalPort: map['internalPort'] as int,
      description: map['description'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory SinglePortForwardingRuleUIModel.fromJson(String source) =>
      SinglePortForwardingRuleUIModel.fromMap(
          json.decode(source) as Map<String, dynamic>);
}

/// UI Model for a list of Single Port Forwarding Rules
class SinglePortForwardingRuleListUIModel extends Equatable {
  const SinglePortForwardingRuleListUIModel({required this.rules});

  final List<SinglePortForwardingRuleUIModel> rules;

  @override
  List<Object> get props => [rules];

  SinglePortForwardingRuleListUIModel copyWith({
    List<SinglePortForwardingRuleUIModel>? rules,
  }) {
    return SinglePortForwardingRuleListUIModel(
      rules: rules ?? this.rules,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'rules': rules.map((x) => x.toMap()).toList(),
    };
  }

  factory SinglePortForwardingRuleListUIModel.fromMap(
      Map<String, dynamic> map) {
    return SinglePortForwardingRuleListUIModel(
      rules: List<SinglePortForwardingRuleUIModel>.from(
        map['rules']?.map<SinglePortForwardingRuleUIModel>(
              (x) => SinglePortForwardingRuleUIModel.fromMap(
                  x as Map<String, dynamic>),
            ) ??
            [],
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory SinglePortForwardingRuleListUIModel.fromJson(String source) =>
      SinglePortForwardingRuleListUIModel.fromMap(
          json.decode(source) as Map<String, dynamic>);
}
