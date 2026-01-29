import 'package:privacy_gui/core/models/device_info.dart';

/// Raw DeviceInfo response from JNAP protocol layer
///
/// This class is used to parse the raw response from JNAP GetDeviceInfo API.
/// It contains the complete JNAP response structure, including the services list.
///
/// Use [toUIModel] method to convert to [NodeDeviceInfo] for UI layer usage.
class JnapDeviceInfoRaw {
  const JnapDeviceInfoRaw({
    required this.modelNumber,
    required this.firmwareVersion,
    required this.description,
    required this.firmwareDate,
    required this.manufacturer,
    required this.serialNumber,
    required this.hardwareVersion,
    required this.services,
  });

  factory JnapDeviceInfoRaw.fromJson(Map<String, dynamic> json) {
    return JnapDeviceInfoRaw(
      modelNumber: json['modelNumber'] ?? '',
      firmwareVersion: json['firmwareVersion'] ?? '',
      description: json['description'] ?? '',
      firmwareDate: json['firmwareDate'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      serialNumber: json['serialNumber'] ?? '',
      hardwareVersion: json['hardwareVersion'] ?? '',
      services: List<String>.from(json['services'] ?? []),
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

  /// Converts to UI Model
  NodeDeviceInfo toUIModel() {
    return NodeDeviceInfo(
      modelNumber: modelNumber,
      firmwareVersion: firmwareVersion,
      description: description,
      firmwareDate: firmwareDate,
      manufacturer: manufacturer,
      serialNumber: serialNumber,
      hardwareVersion: hardwareVersion,
    );
  }

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
}
