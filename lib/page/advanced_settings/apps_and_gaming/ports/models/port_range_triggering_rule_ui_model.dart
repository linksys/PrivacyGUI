import 'dart:convert';

import 'package:equatable/equatable.dart';

/// UI Model for Port Range Triggering Rule
///
/// This model is used in the Presentation and Application layers.
/// It provides a clean interface for UI components and business logic,
/// separated from the underlying JNAP data models.
class PortRangeTriggeringRuleUIModel extends Equatable {
  const PortRangeTriggeringRuleUIModel({
    required this.isEnabled,
    required this.firstTriggerPort,
    required this.lastTriggerPort,
    required this.firstForwardedPort,
    required this.lastForwardedPort,
    required this.description,
  });

  final bool isEnabled;
  final int firstTriggerPort;
  final int lastTriggerPort;
  final int firstForwardedPort;
  final int lastForwardedPort;
  final String description;

  /// Returns true if the trigger port is a single port (not a range)
  bool get isSingleTriggerPort => firstTriggerPort == lastTriggerPort;

  /// Returns true if the forwarded port is a single port (not a range)
  bool get isSingleForwardedPort => firstForwardedPort == lastForwardedPort;

  /// Returns a formatted string for trigger port display
  /// Single port: "3074"
  /// Port range: "3074-3084"
  String get triggerPortDisplay => isSingleTriggerPort
      ? '$firstTriggerPort'
      : '$firstTriggerPort-$lastTriggerPort';

  /// Returns a formatted string for forwarded port display
  /// Single port: "3074"
  /// Port range: "3074-3084"
  String get forwardedPortDisplay => isSingleForwardedPort
      ? '$firstForwardedPort'
      : '$firstForwardedPort-$lastForwardedPort';

  @override
  List<Object> get props => [
        isEnabled,
        firstTriggerPort,
        lastTriggerPort,
        firstForwardedPort,
        lastForwardedPort,
        description,
      ];

  PortRangeTriggeringRuleUIModel copyWith({
    bool? isEnabled,
    int? firstTriggerPort,
    int? lastTriggerPort,
    int? firstForwardedPort,
    int? lastForwardedPort,
    String? description,
  }) {
    return PortRangeTriggeringRuleUIModel(
      isEnabled: isEnabled ?? this.isEnabled,
      firstTriggerPort: firstTriggerPort ?? this.firstTriggerPort,
      lastTriggerPort: lastTriggerPort ?? this.lastTriggerPort,
      firstForwardedPort: firstForwardedPort ?? this.firstForwardedPort,
      lastForwardedPort: lastForwardedPort ?? this.lastForwardedPort,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'firstTriggerPort': firstTriggerPort,
      'lastTriggerPort': lastTriggerPort,
      'firstForwardedPort': firstForwardedPort,
      'lastForwardedPort': lastForwardedPort,
      'description': description,
    };
  }

  factory PortRangeTriggeringRuleUIModel.fromMap(Map<String, dynamic> map) {
    return PortRangeTriggeringRuleUIModel(
      isEnabled: map['isEnabled'] as bool,
      firstTriggerPort: map['firstTriggerPort'] as int,
      lastTriggerPort: map['lastTriggerPort'] as int,
      firstForwardedPort: map['firstForwardedPort'] as int,
      lastForwardedPort: map['lastForwardedPort'] as int,
      description: map['description'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory PortRangeTriggeringRuleUIModel.fromJson(String source) =>
      PortRangeTriggeringRuleUIModel.fromMap(
          json.decode(source) as Map<String, dynamic>);
}

/// UI Model for a list of Port Range Triggering Rules
class PortRangeTriggeringRuleListUIModel extends Equatable {
  const PortRangeTriggeringRuleListUIModel({required this.rules});

  final List<PortRangeTriggeringRuleUIModel> rules;

  @override
  List<Object> get props => [rules];

  PortRangeTriggeringRuleListUIModel copyWith({
    List<PortRangeTriggeringRuleUIModel>? rules,
  }) {
    return PortRangeTriggeringRuleListUIModel(
      rules: rules ?? this.rules,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'rules': rules.map((x) => x.toMap()).toList(),
    };
  }

  factory PortRangeTriggeringRuleListUIModel.fromMap(
      Map<String, dynamic> map) {
    return PortRangeTriggeringRuleListUIModel(
      rules: List<PortRangeTriggeringRuleUIModel>.from(
        map['rules']?.map<PortRangeTriggeringRuleUIModel>(
              (x) => PortRangeTriggeringRuleUIModel.fromMap(
                  x as Map<String, dynamic>),
            ) ??
            [],
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory PortRangeTriggeringRuleListUIModel.fromJson(String source) =>
      PortRangeTriggeringRuleListUIModel.fromMap(
          json.decode(source) as Map<String, dynamic>);
}