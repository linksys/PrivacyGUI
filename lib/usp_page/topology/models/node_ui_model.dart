import 'package:equatable/equatable.dart';

/// Presentation Layer Model for a mesh node.
///
/// UI widgets depend only on this class, never directly on codegen Data Models.
/// Naming follows constitution Section 3.3.4 (class name ends with `UIModel`).
/// Implements [Equatable] per Article XI.
class NodeUIModel extends Equatable {
  final String deviceId; // MAC of the mesh node
  final String model; // ManufacturerModel (e.g., MR7500)
  final String manufacturer;
  final String serialNumber;
  final String softwareVersion;
  final int radioCount;
  final bool isMaster; // First node in DataElements = gateway
  final int connectedDeviceCount; // Devices connected to this node

  const NodeUIModel({
    required this.deviceId,
    required this.model,
    this.manufacturer = '',
    this.serialNumber = '',
    this.softwareVersion = '',
    this.radioCount = 0,
    this.isMaster = false,
    this.connectedDeviceCount = 0,
  });

  /// Display name: model if available, otherwise deviceId.
  String get displayName => model.isNotEmpty ? model : deviceId;

  /// Role label for UI display.
  String get roleLabel => isMaster ? 'Gateway' : 'Extender';

  @override
  List<Object?> get props => [
        deviceId,
        model,
        manufacturer,
        serialNumber,
        softwareVersion,
        radioCount,
        isMaster,
        connectedDeviceCount,
      ];
}
