import 'package:equatable/equatable.dart';

class RouterWANStatus extends Equatable {
  final String macAddress;
  final String detectedWANType;
  final String wanStatus;
  final String wanIPv6Status;
  final List<String> supportedWANTypes;

  const RouterWANStatus({
    required this.macAddress,
    required this.detectedWANType,
    required this.wanStatus,
    required this.wanIPv6Status,
    required this.supportedWANTypes,
  });

  RouterWANStatus copyWith({
    String? macAddress,
    String? detectedWANType,
    String? wanStatus,
    String? wanIPv6Status,
    List<String>? supportedWANTypes,
  }) {
    return RouterWANStatus(
      macAddress: macAddress ?? this.macAddress,
      detectedWANType: detectedWANType ?? this.detectedWANType,
      wanStatus: wanStatus ?? this.wanStatus,
      wanIPv6Status: wanIPv6Status ?? this.wanIPv6Status,
      supportedWANTypes: supportedWANTypes ?? this.supportedWANTypes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'macAddress': macAddress,
      'detectedWANType': detectedWANType,
      'wanStatus': wanStatus,
      'wanIPv6Status': wanIPv6Status,
      'supportedWANTypes': supportedWANTypes,
    };
  }

  factory RouterWANStatus.fromJson(Map<String, dynamic> json) {
    return RouterWANStatus(
      macAddress: json['macAddress'],
      detectedWANType: json['detectedWANType'],
      wanStatus: json['wanStatus'],
      wanIPv6Status: json['wanIPv6Status'],
      supportedWANTypes: List.from(json['supportedWANTypes']),
    );
  }

  @override
  List<Object?> get props => [
    macAddress,
    detectedWANType,
    wanIPv6Status,
    wanStatus,
    supportedWANTypes,
  ];
}