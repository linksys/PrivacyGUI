import 'package:equatable/equatable.dart';

class RouterDeviceInfo extends Equatable {
  const RouterDeviceInfo({
    required this.modelNumber,
    required this.firmwareVersion,
    required this.description,
    required this.firmwareDate,
    required this.manufacturer,
    required this.serialNumber,
    required this.hardwareVersion,
    required this.services,
  });

  factory RouterDeviceInfo.fromJson(Map<String, dynamic> json) {
    return RouterDeviceInfo(
      modelNumber: json['modelNumber'],
      firmwareVersion: json['firmwareVersion'],
      description: json['description'],
      firmwareDate: json['firmwareDate'],
      manufacturer: json['manufacturer'],
      serialNumber: json['serialNumber'],
      hardwareVersion: json['hardwareVersion'],
      services: List.from(json['services']),
    );
  }

  final String modelNumber;
  final String firmwareVersion;
  final String description;
  final String firmwareDate;
  final String manufacturer;
  final String serialNumber;
  final String hardwareVersion;
  final List<String> services;

  Map<String, dynamic> toJson() {
    return {
      'modelNumber': modelNumber,
      'firmwareVersion': firmwareVersion,
      'description': description,
      'firmwareDate': firmwareDate,
      'manufacturer': manufacturer,
      'serialNumber': serialNumber,
      'hardwareVersion': hardwareVersion,
      'services': services,
    }..removeWhere((key, value) => value == null);
  }

  RouterDeviceInfo copyWith({
    String? modelNumber,
    String? firmwareVersion,
    String? description,
    String? firmwareDate,
    String? manufacturer,
    String? serialNumber,
    String? hardwareVersion,
    List<String>? services,
  }) {
    return RouterDeviceInfo(
      modelNumber: modelNumber ?? this.modelNumber,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      description: description ?? this.description,
      firmwareDate: firmwareDate ?? this.firmwareDate,
      manufacturer: manufacturer ?? this.manufacturer,
      serialNumber: serialNumber ?? this.serialNumber,
      hardwareVersion: hardwareVersion ?? this.hardwareVersion,
      services: services ?? this.services,
    );
  }

  @override
  List<Object?> get props => [
    modelNumber,
    firmwareVersion,
    description,
    firmwareDate,
    manufacturer,
    serialNumber,
    hardwareVersion,
  ];
}