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
  List<Object> get props =>
      [
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

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'firstExternalPort': firstExternalPort,
      'protocol': protocol,
      'internalServerIPAddress': internalServerIPAddress,
      'lastExternalPort': lastExternalPort,
      'description': description,
    };
  }

  factory PortRangeForwardingRule.fromJson(Map<String, dynamic> json) {
    return PortRangeForwardingRule(
      isEnabled: json['isEnabled'],
      firstExternalPort: json['firstExternalPort'],
      protocol: json['protocol'],
      internalServerIPAddress: json['internalServerIPAddress'],
      lastExternalPort: json['lastExternalPort'],
      description: json['description'],
    );
  }
}
