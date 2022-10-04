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
      services: List.from(json['service']),
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
    };
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

class MoabNetwork extends Equatable {
  const MoabNetwork({
    required this.id,
    required this.deviceInfo,
  });

  final String id;
  final RouterDeviceInfo deviceInfo;

  MoabNetwork copyWith({
    String? id,
    RouterDeviceInfo? deviceInfo,
  }) {
    return MoabNetwork(
      id: id ?? this.id,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }

  @override
  List<Object?> get props => [
        id,
        deviceInfo,
      ];
}

class NetworkState extends Equatable {
  const NetworkState({
    required this.selected,
    required this.networks,
  });

  final List<MoabNetwork> networks;
  final MoabNetwork selected;

  @override
  List<Object?> get props => [
        selected,
        networks,
      ];
}
