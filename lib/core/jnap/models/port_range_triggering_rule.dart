import 'package:equatable/equatable.dart';

/// isEnabled : true
/// externalPort : 3074
/// protocol : "TCP"
/// internalServerIPAddress : "192.168.1.150"
/// lastExternalPort : 3074
/// description : "XBox Live (TM)"

class PortRangeTriggeringRule extends Equatable {
  const PortRangeTriggeringRule({
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

  @override
  List<Object> get props => [
        isEnabled,
        firstTriggerPort,
        lastTriggerPort,
        firstForwardedPort,
        lastForwardedPort,
        description,
      ];

  PortRangeTriggeringRule copyWith({
    bool? isEnabled,
    int? firstTriggerPort,
    int? lastTriggerPort,
    int? firstForwardedPort,
    int? lastForwardedPort,
    String? description,
  }) {
    return PortRangeTriggeringRule(
      isEnabled: isEnabled ?? this.isEnabled,
      firstTriggerPort: firstTriggerPort ?? this.firstTriggerPort,
      lastTriggerPort: lastTriggerPort ?? this.lastTriggerPort,
      firstForwardedPort: firstForwardedPort ?? this.firstForwardedPort,
      lastForwardedPort: lastForwardedPort ?? this.lastForwardedPort,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'firstTriggerPort': firstTriggerPort,
      'lastTriggerPort': lastTriggerPort,
      'firstForwardedPort': firstForwardedPort,
      'lastForwardedPort': lastForwardedPort,
      'description': description,
    };
  }

  factory PortRangeTriggeringRule.fromJson(Map<String, dynamic> json) {
    return PortRangeTriggeringRule(
      isEnabled: json['isEnabled'],
      firstTriggerPort: json['firstTriggerPort'],
      lastTriggerPort: json['lastTriggerPort'],
      firstForwardedPort: json['firstForwardedPort'],
      lastForwardedPort: json['lastForwardedPort'],
      description: json['description'],
    );
  }
}
