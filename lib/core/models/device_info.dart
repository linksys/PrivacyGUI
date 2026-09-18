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
    this.baseMacAddress,
    this.deviceUuid,
  });

  /// Creates a [NodeDeviceInfo] from USP [SystemInfo] codegen DTO.
  ///
  /// Field mapping:
  /// - modelName → modelNumber (different name, same semantics)
  /// - softwareVersion → firmwareVersion (different name, same semantics)
  /// - firmwareDate/description → empty string (not available in TR-181)
  ///
  /// [baseMacAddress] and [deviceUuid] are deliberately **not** set here —
  /// `SessionService` copies both in (PrivacyGUI#1582, PrivacyGUI#1592):
  ///
  /// - The UUID **cannot** come from this DTO: it is `Device.LocalAgent.EndpointID`,
  ///   and the `system_info` definition covers `Device.DeviceInfo.*`.
  /// - The MAC *is* on the DTO since PrivacyGUI#1572 added
  ///   `X_LINKSYS_BaseMACAddress` to the definition, and `SessionService` now reads
  ///   it from there instead of paying a second Get. It is not mapped here because
  ///   the value needs the same upper-casing Guardian requires of the UUID, and
  ///   splitting that rule across a DTO mapper and a service would leave two places
  ///   encoding it. This factory stays a pure field mapping.
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

  /// The router's own MAC, from `Device.DeviceInfo.X_LINKSYS_BaseMACAddress`.
  ///
  /// This is the MAC the Linksys cloud registered the unit under, which is what
  /// makes it the one Guardian validates. Null on a firmware that does not serve
  /// the leaf.
  final String? baseMacAddress;

  /// The cloud's device UUID, from `Device.LocalAgent.EndpointID` with its
  /// `uuid::` prefix stripped.
  ///
  /// Not a locally generated id: the same value is obuspa's MQTT topic key and
  /// the subject of the device's cloud certificate. Guardian validates it
  /// case-sensitively. Null on a firmware that does not serve the leaf.
  final String? deviceUuid;

  Map<String, dynamic> toJson() {
    return {
      'modelNumber': modelNumber,
      'firmwareVersion': firmwareVersion,
      'description': description,
      'firmwareDate': firmwareDate,
      'manufacturer': manufacturer,
      'serialNumber': serialNumber,
      'hardwareVersion': hardwareVersion,
      'baseMacAddress': baseMacAddress,
      'deviceUuid': deviceUuid,
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
    String? baseMacAddress,
    String? deviceUuid,
  }) {
    return NodeDeviceInfo(
      modelNumber: modelNumber ?? this.modelNumber,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      description: description ?? this.description,
      firmwareDate: firmwareDate ?? this.firmwareDate,
      manufacturer: manufacturer ?? this.manufacturer,
      serialNumber: serialNumber ?? this.serialNumber,
      hardwareVersion: hardwareVersion ?? this.hardwareVersion,
      baseMacAddress: baseMacAddress ?? this.baseMacAddress,
      deviceUuid: deviceUuid ?? this.deviceUuid,
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
        baseMacAddress,
        deviceUuid,
      ];
}
