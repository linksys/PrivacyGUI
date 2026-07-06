import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';

/// Presentation Layer Model for a mesh node.
///
/// UI widgets depend only on this class, never directly on codegen Data Models.
/// Naming follows constitution Section 3.3.4 (class name ends with `UIModel`).
/// Implements [Equatable] per Article XI.
class NodeUIModel extends Equatable with DiagnosticLoggable {
  final String deviceId; // MAC of the mesh node (from Hosts)

  // ─── DataElements ID (may differ from deviceId) ───
  final String?
      dataElementsId; // node.id from DataElements (used in clientToNodeMap)

  // ─── Name fields (from Hosts) ───
  final String? friendlyName; // User-friendly name from Hosts
  final String? hostName; // Hostname from Hosts

  final String model; // ManufacturerModel (e.g., MR7500)
  final String manufacturer;
  final String serialNumber;
  final String softwareVersion;
  final bool isMaster; // First node in DataElements = gateway
  final int connectedDeviceCount; // Devices connected to this node

  // ─── Network addresses ───
  final String? ipAddress; // LAN IP address of the node
  final List<String> ipv6Addresses; // LAN IPv6 addresses of the node
  final String? wanIpAddress; // WAN IP address (master only)

  // ─── Backhaul info (for child nodes) ───
  final String backhaulMediaType; // "IEEE 802.11ax" / "Ethernet"
  final int backhaulPhyRate; // PHY rate in Mbps
  final int? backhaulSignalStrength; // RSSI in dBm (converted from RCPI)
  final int? backhaulUplinkRate; // kbps (from TR-181 LastDataUplinkRate)

  // ─── DataElements enrichment (Service internal use) ───
  final String? instancePath; // DataElements instance path
  final String? backhaulAlId; // Parent node's AL ID (MAC)
  final String? backhaulMacAddress; // Backhaul interface MAC

  // ─── Enhanced backhaul fields (from codegen) ───
  final String? backhaulLinkType; // "Wi-Fi" or "Ethernet"
  final int? backhaulDownlinkRate; // kbps (from TR-181 LastDataDownlinkRate)
  final String? backhaulParentDeviceId; // Parent node's Device ID
  final String? backhaulParentBssid; // Connected BSSID
  final String? lastContactTime; // ISO 8601 timestamp

  const NodeUIModel({
    required this.deviceId,
    this.dataElementsId,
    this.friendlyName,
    this.hostName,
    required this.model,
    this.manufacturer = '',
    this.serialNumber = '',
    this.softwareVersion = '',
    this.isMaster = false,
    this.connectedDeviceCount = 0,
    this.ipAddress,
    this.ipv6Addresses = const [],
    this.wanIpAddress,
    this.backhaulMediaType = '',
    this.backhaulPhyRate = 0,
    this.backhaulSignalStrength,
    this.backhaulUplinkRate,
    this.instancePath,
    this.backhaulAlId,
    this.backhaulMacAddress,
    this.backhaulLinkType,
    this.backhaulDownlinkRate,
    this.backhaulParentDeviceId,
    this.backhaulParentBssid,
    this.lastContactTime,
  });

  /// Display name priority: friendlyName > hostName > model > deviceId.
  String get displayName {
    if (friendlyName != null && friendlyName!.isNotEmpty) return friendlyName!;
    if (hostName != null && hostName!.isNotEmpty) return hostName!;
    if (model.isNotEmpty) return model;
    return deviceId;
  }

  /// Role label for UI display.
  String get roleLabel => isMaster ? 'Master' : 'Slave';

  /// Whether this node has backhaul info (i.e., it's a child node).
  bool get hasBackhaul => backhaulMediaType.isNotEmpty;

  /// Whether backhaul connection is Ethernet (wired).
  bool get isEthernetBackhaul => backhaulLinkType == 'Ethernet';

  @override
  String get diagnosticName => 'NodeUIModel';

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
        'isMaster': isMaster,
        'connectedDeviceCount': connectedDeviceCount,
        'ipAddress': ipAddress,
        'ipv6Addresses': ipv6Addresses,
        'wanIpAddress': wanIpAddress,
        'backhaulMediaType': backhaulMediaType,
        'backhaulPhyRate': backhaulPhyRate,
        'backhaulSignalStrength': backhaulSignalStrength,
        'backhaulUplinkRate': backhaulUplinkRate,
        'instancePath': instancePath,
        'backhaulAlId': backhaulAlId,
        'backhaulMacAddress': backhaulMacAddress,
        'backhaulLinkType': backhaulLinkType,
        'backhaulDownlinkRate': backhaulDownlinkRate,
        'backhaulParentDeviceId': backhaulParentDeviceId,
        'backhaulParentBssid': backhaulParentBssid,
        'lastContactTime': lastContactTime,
      };
}

/// Extension methods for List<NodeUIModel> to simplify common filtering.
extension NodeUIModelListExt on List<NodeUIModel> {
  /// Returns the master (gateway) node, or null if not found.
  NodeUIModel? get master => where((n) => n.isMaster).firstOrNull;

  /// Returns all slave (extender) nodes.
  List<NodeUIModel> get slaves => where((n) => !n.isMaster).toList();

  /// Whether this topology has mesh extenders.
  bool get hasMesh => slaves.isNotEmpty;
}
