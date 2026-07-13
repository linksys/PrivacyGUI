import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/network_entity.dart';

/// Sealed class for mesh network nodes (master or slave).
///
/// Use pattern matching to distinguish between [MasterNode] and [SlaveNode]:
/// ```dart
/// switch (node) {
///   case MasterNode m: print('Gateway: ${m.wanIpAddress}');
///   case SlaveNode s: print('Extender via ${s.backhaul.linkType}');
/// }
/// ```
sealed class NodeEntity extends NetworkEntity with DiagnosticNamed {
  // ─── Identity ───
  /// Device ID (MAC address, uppercase, normalized).
  String get deviceId;

  /// DataElements ID (may differ from deviceId for matching).
  String? get dataElementsId;

  /// User-friendly name.
  String? get friendlyName;

  /// Hostname from Hosts table.
  String? get hostName;

  // ─── Device Info ───
  /// Model name (e.g., "MR7500").
  String get model;

  /// Manufacturer name.
  String get manufacturer;

  /// Serial number.
  String get serialNumber;

  /// Firmware version.
  String get softwareVersion;

  // ─── Network ───
  /// LAN IP address.
  @override
  String? get ipAddress;

  /// LAN IPv6 addresses.
  @override
  List<String> get ipv6Addresses;

  // ─── DataElements internal ───
  /// DataElements instance path.
  String? get instancePath;

  // ─── Children ───
  /// Client devices connected to this node.
  List<ClientDevice> get connectedClients;

  // ─── NetworkEntity implementation ───
  @override
  String get id => deviceId;

  @override
  String get displayName {
    if (friendlyName != null && friendlyName!.isNotEmpty) return friendlyName!;
    if (hostName != null && hostName!.isNotEmpty) return hostName!;
    if (model.isNotEmpty) return model;
    return deviceId;
  }

  @override
  bool get isOnline => true; // Nodes are always online if visible

  // ─── Computed ───
  /// Whether this is the master (gateway) node.
  bool get isMaster;

  /// Role label for UI display.
  String get roleLabel => isMaster ? 'Master' : 'Slave';

  /// Number of connected clients.
  int get connectedDeviceCount => connectedClients.length;
}

/// Master (gateway) mesh node.
///
/// The primary router that connects to the internet via WAN.
final class MasterNode extends NodeEntity {
  @override
  final String deviceId;
  @override
  final String? dataElementsId;
  @override
  final String? friendlyName;
  @override
  final String? hostName;
  @override
  final String model;
  @override
  final String manufacturer;
  @override
  final String serialNumber;
  @override
  final String softwareVersion;
  @override
  final String? ipAddress;
  @override
  final List<String> ipv6Addresses;
  @override
  final String? instancePath;
  @override
  final List<ClientDevice> connectedClients;

  /// WAN IPv4 address.
  final String? wanIpAddress;

  /// WAN IPv6 address.
  final String? wanIpv6Address;

  /// Hosts DeviceID (UUID) — used by Remote Assistance / Guardian API calls.
  final String? hostsDeviceId;

  MasterNode({
    required this.deviceId,
    this.dataElementsId,
    this.friendlyName,
    this.hostName,
    required this.model,
    this.manufacturer = '',
    this.serialNumber = '',
    this.softwareVersion = '',
    this.ipAddress,
    this.ipv6Addresses = const [],
    this.instancePath,
    this.connectedClients = const [],
    this.wanIpAddress,
    this.wanIpv6Address,
    this.hostsDeviceId,
  });

  @override
  bool get isMaster => true;

  MasterNode copyWith({
    String? deviceId,
    String? dataElementsId,
    String? friendlyName,
    String? hostName,
    String? model,
    String? manufacturer,
    String? serialNumber,
    String? softwareVersion,
    String? ipAddress,
    List<String>? ipv6Addresses,
    String? instancePath,
    List<ClientDevice>? connectedClients,
    String? wanIpAddress,
    String? wanIpv6Address,
    String? hostsDeviceId,
  }) {
    return MasterNode(
      deviceId: deviceId ?? this.deviceId,
      dataElementsId: dataElementsId ?? this.dataElementsId,
      friendlyName: friendlyName ?? this.friendlyName,
      hostName: hostName ?? this.hostName,
      model: model ?? this.model,
      manufacturer: manufacturer ?? this.manufacturer,
      serialNumber: serialNumber ?? this.serialNumber,
      softwareVersion: softwareVersion ?? this.softwareVersion,
      ipAddress: ipAddress ?? this.ipAddress,
      ipv6Addresses: ipv6Addresses ?? this.ipv6Addresses,
      instancePath: instancePath ?? this.instancePath,
      connectedClients: connectedClients ?? this.connectedClients,
      wanIpAddress: wanIpAddress ?? this.wanIpAddress,
      wanIpv6Address: wanIpv6Address ?? this.wanIpv6Address,
      hostsDeviceId: hostsDeviceId ?? this.hostsDeviceId,
    );
  }

  @override
  List<Object?> get props => [
        deviceId,
        dataElementsId,
        friendlyName,
        hostName,
        model,
        manufacturer,
        serialNumber,
        softwareVersion,
        ipAddress,
        ipv6Addresses,
        instancePath,
        connectedClients,
        wanIpAddress,
        wanIpv6Address,
        hostsDeviceId,
      ];

  @override
  String get diagnosticName => 'MasterNode';

  @override
  Map<String, Object?> get namedProps => {
        'deviceId': deviceId,
        'dataElementsId': dataElementsId,
        'friendlyName': friendlyName,
        'hostName': hostName,
        'model': model,
        'manufacturer': manufacturer,
        'serialNumber': serialNumber,
        'softwareVersion': softwareVersion,
        'ipAddress': ipAddress,
        'ipv6Addresses': ipv6Addresses,
        'instancePath': instancePath,
        'connectedClients': connectedClients,
        'wanIpAddress': wanIpAddress,
        'wanIpv6Address': wanIpv6Address,
        'hostsDeviceId': hostsDeviceId,
      };
}

/// Slave (extender) mesh node.
///
/// Extends the network via WiFi or Ethernet backhaul to the parent node.
final class SlaveNode extends NodeEntity {
  @override
  final String deviceId;
  @override
  final String? dataElementsId;
  @override
  final String? friendlyName;
  @override
  final String? hostName;
  @override
  final String model;
  @override
  final String manufacturer;
  @override
  final String serialNumber;
  @override
  final String softwareVersion;
  @override
  final String? ipAddress;
  @override
  final List<String> ipv6Addresses;
  @override
  final String? instancePath;
  @override
  final List<ClientDevice> connectedClients;

  /// Backhaul connection info to parent node.
  final BackhaulInfo backhaul;

  SlaveNode({
    required this.deviceId,
    this.dataElementsId,
    this.friendlyName,
    this.hostName,
    required this.model,
    this.manufacturer = '',
    this.serialNumber = '',
    this.softwareVersion = '',
    this.ipAddress,
    this.ipv6Addresses = const [],
    this.instancePath,
    this.connectedClients = const [],
    required this.backhaul,
  });

  @override
  bool get isMaster => false;

  /// Whether backhaul is Ethernet.
  bool get isEthernetBackhaul => backhaul.isEthernet;

  /// Whether backhaul info is available.
  bool get hasBackhaul => backhaul.hasInfo;

  SlaveNode copyWith({
    String? deviceId,
    String? dataElementsId,
    String? friendlyName,
    String? hostName,
    String? model,
    String? manufacturer,
    String? serialNumber,
    String? softwareVersion,
    String? ipAddress,
    List<String>? ipv6Addresses,
    String? instancePath,
    List<ClientDevice>? connectedClients,
    BackhaulInfo? backhaul,
  }) {
    return SlaveNode(
      deviceId: deviceId ?? this.deviceId,
      dataElementsId: dataElementsId ?? this.dataElementsId,
      friendlyName: friendlyName ?? this.friendlyName,
      hostName: hostName ?? this.hostName,
      model: model ?? this.model,
      manufacturer: manufacturer ?? this.manufacturer,
      serialNumber: serialNumber ?? this.serialNumber,
      softwareVersion: softwareVersion ?? this.softwareVersion,
      ipAddress: ipAddress ?? this.ipAddress,
      ipv6Addresses: ipv6Addresses ?? this.ipv6Addresses,
      instancePath: instancePath ?? this.instancePath,
      connectedClients: connectedClients ?? this.connectedClients,
      backhaul: backhaul ?? this.backhaul,
    );
  }

  @override
  List<Object?> get props => [
        deviceId,
        dataElementsId,
        friendlyName,
        hostName,
        model,
        manufacturer,
        serialNumber,
        softwareVersion,
        ipAddress,
        ipv6Addresses,
        instancePath,
        connectedClients,
        backhaul,
      ];

  @override
  String get diagnosticName => 'SlaveNode';

  @override
  Map<String, Object?> get namedProps => {
        'deviceId': deviceId,
        'dataElementsId': dataElementsId,
        'friendlyName': friendlyName,
        'hostName': hostName,
        'model': model,
        'manufacturer': manufacturer,
        'serialNumber': serialNumber,
        'softwareVersion': softwareVersion,
        'ipAddress': ipAddress,
        'ipv6Addresses': ipv6Addresses,
        'instancePath': instancePath,
        'connectedClients': connectedClients,
        'backhaul': backhaul,
      };
}

/// Extension methods for List<NodeEntity>.
extension NodeEntityListExt on List<NodeEntity> {
  /// Returns the master (gateway) node, or null if not found.
  MasterNode? get master {
    for (final n in this) {
      if (n is MasterNode) return n;
    }
    return null;
  }

  /// Returns all slave (extender) nodes.
  List<SlaveNode> get slaves => whereType<SlaveNode>().toList();

  /// Whether this topology has mesh extenders.
  bool get hasMesh => any((n) => n is SlaveNode);
}
