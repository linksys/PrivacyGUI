import 'dart:convert';

import 'package:equatable/equatable.dart';

/// UI Model for Port Range Forwarding Rule
///
/// This model is used in the Presentation and Application layers.
/// It provides a clean interface for UI components and business logic,
/// separated from the underlying JNAP data models.
class PortRangeForwardingRuleUIModel extends Equatable {
  const PortRangeForwardingRuleUIModel({
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

  /// Returns true if this rule represents a single port (not a range)
  bool get isSinglePort => firstExternalPort == lastExternalPort;

  /// Returns a formatted string for display purposes
  /// Single port: "3074"
  /// Port range: "3074-3084"
  String get portRangeDisplay => isSinglePort
      ? '$firstExternalPort'
      : '$firstExternalPort-$lastExternalPort';

  @override
  List<Object> get props => [
        isEnabled,
        firstExternalPort,
        protocol,
        internalServerIPAddress,
        lastExternalPort,
        description,
      ];

  PortRangeForwardingRuleUIModel copyWith({
    bool? isEnabled,
    int? firstExternalPort,
    String? protocol,
    String? internalServerIPAddress,
    int? lastExternalPort,
    String? description,
  }) {
    return PortRangeForwardingRuleUIModel(
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

  factory PortRangeForwardingRuleUIModel.fromMap(Map<String, dynamic> map) {
    return PortRangeForwardingRuleUIModel(
      isEnabled: map['isEnabled'] as bool,
      firstExternalPort: map['firstExternalPort'] as int,
      protocol: map['protocol'] as String,
      internalServerIPAddress: map['internalServerIPAddress'] as String,
      lastExternalPort: map['lastExternalPort'] as int,
      description: map['description'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory PortRangeForwardingRuleUIModel.fromJson(String source) =>
      PortRangeForwardingRuleUIModel.fromMap(
          json.decode(source) as Map<String, dynamic>);
}

/// UI Model for a list of Port Range Forwarding Rules
class PortRangeForwardingRuleListUIModel extends Equatable {
  const PortRangeForwardingRuleListUIModel({required this.rules});

  final List<PortRangeForwardingRuleUIModel> rules;

  @override
  List<Object> get props => [rules];

  PortRangeForwardingRuleListUIModel copyWith({
    List<PortRangeForwardingRuleUIModel>? rules,
  }) {
    return PortRangeForwardingRuleListUIModel(
      rules: rules ?? this.rules,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'rules': rules.map((x) => x.toMap()).toList(),
    };
  }

  factory PortRangeForwardingRuleListUIModel.fromMap(
      Map<String, dynamic> map) {
    return PortRangeForwardingRuleListUIModel(
      rules: List<PortRangeForwardingRuleUIModel>.from(
        map['rules']?.map<PortRangeForwardingRuleUIModel>(
              (x) => PortRangeForwardingRuleUIModel.fromMap(
                  x as Map<String, dynamic>),
            ) ??
            [],
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory PortRangeForwardingRuleListUIModel.fromJson(String source) =>
      PortRangeForwardingRuleListUIModel.fromMap(
          json.decode(source) as Map<String, dynamic>);
}