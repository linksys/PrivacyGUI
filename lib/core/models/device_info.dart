import 'package:equatable/equatable.dart';

/// UI layer DeviceInfo Model
///
/// This class is used to pass device information between Provider and View layers.
/// It does not contain JNAP protocol details (such as services list).
///
/// For raw JNAP response, use [JnapDeviceInfoRaw].
class NodeDeviceInfo extends Equatable {
  const NodeDeviceInfo({
    required this.modelNumber,
    required this.firmwareVersion,
    required this.description,
    required this.firmwareDate,
    required this.manufacturer,
    required this.serialNumber,
    required this.hardwareVersion,
  });

  final String modelNumber;
  final String firmwareVersion;
  final String description;
  final String firmwareDate;
  final String manufacturer;
  final String serialNumber;
  final String hardwareVersion;

  Map<String, dynamic> toJson() {
    return {
      'modelNumber': modelNumber,
      'firmwareVersion': firmwareVersion,
      'description': description,
      'firmwareDate': firmwareDate,
      'manufacturer': manufacturer,
      'serialNumber': serialNumber,
      'hardwareVersion': hardwareVersion,
    }..removeWhere((key, value) => value == null);
  }

  NodeDeviceInfo copyWith({
    String? modelNumber,
    String? firmwareVersion,
    String? description,
    String? firmwareDate,
    String? manufacturer,
    String? serialNumber,
    String? hardwareVersion,
  }) {
    return NodeDeviceInfo(
      modelNumber: modelNumber ?? this.modelNumber,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      description: description ?? this.description,
      firmwareDate: firmwareDate ?? this.firmwareDate,
      manufacturer: manufacturer ?? this.manufacturer,
      serialNumber: serialNumber ?? this.serialNumber,
      hardwareVersion: hardwareVersion ?? this.hardwareVersion,
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
