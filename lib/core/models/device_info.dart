import 'package:equatable/equatable.dart';
import 'package:privacy_gui/generated/system_info.g.dart';

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

  /// Creates a [NodeDeviceInfo] from USP [SystemInfo] codegen DTO.
  ///
  /// Field mapping:
  /// - modelName → modelNumber (different name, same semantics)
  /// - softwareVersion → firmwareVersion (different name, same semantics)
  /// - firmwareDate/description → empty string (not available in TR-181)
  factory NodeDeviceInfo.fromUsp(SystemInfo info) {
    return NodeDeviceInfo(
      manufacturer: info.manufacturer,
      modelNumber: info.modelName,
      serialNumber: info.serialNumber,
      hardwareVersion: info.hardwareVersion,
      firmwareVersion: info.softwareVersion,
      firmwareDate: '',
      description: '',
    );
  }

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
