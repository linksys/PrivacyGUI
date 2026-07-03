import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/_shared/models/network_entity.dart';
import 'package:privacy_gui/page/_shared/models/wifi_connection_info.dart';

/// Connection type for client devices.
enum ConnectionType { wifi, wired }

/// Network interface info for multi-interface devices.
///
/// When a device connects via multiple interfaces (e.g., WiFi + Ethernet),
/// the primary interface is stored in [ClientDevice] fields and additional
/// interfaces are stored in [ClientDevice.additionalInterfaces].
class ClientInterfaceInfo with EquatableMixin {
  /// MAC address of this interface.
  final String mac;

  /// IP address of this interface.
  final String ip;

  /// Connection type (WiFi or wired).
  final ConnectionType connectionType;

  /// Whether this interface is currently active.
  final bool isActive;

  /// Layer1Interface path (for port correlation).
  final String layer1Interface;

  /// WiFi connection details (null if wired).
  final WifiConnectionInfo? wifi;

  const ClientInterfaceInfo({
    required this.mac,
    required this.ip,
    required this.connectionType,
    required this.isActive,
    this.layer1Interface = '',
    this.wifi,
  });

  /// Whether this is a WiFi interface.
  bool get isWifi => connectionType == ConnectionType.wifi;

  @override
  List<Object?> get props => [
        mac,
        ip,
        connectionType,
        isActive,
        layer1Interface,
        wifi,
      ];
}

/// Client device connected to the mesh network.
///
/// Represents end-user devices (phones, laptops, etc.) that connect to
/// mesh nodes. Implements [NetworkEntity] for unified identity handling.
final class ClientDevice extends NetworkEntity {
  // ─── Identity ───
  /// MAC address (uppercase, normalized).
  final String mac;

  /// Hostname from Hosts table.
  final String hostName;

  /// User-friendly name (editable).
  final String? friendlyName;

  // ─── Status ───
  /// Whether the device is currently online.
  final bool isActive;

  // ─── Network ───
  /// IPv4 address.
  final String ip;

  /// IPv6 addresses.
  @override
  final List<String> ipv6Addresses;

  /// Layer1Interface path (for port correlation).
  final String layer1Interface;

  // ─── Connection ───
  /// Connection type (WiFi or wired).
  final ConnectionType connectionType;

  /// WiFi connection details (null if wired).
  final WifiConnectionInfo? wifi;

  /// Parent mesh node ID this device is connected to.
  final String? parentNodeId;

  /// Parent mesh node display name (for UI).
  final String? parentNodeName;

  // ─── Device Info ───
  /// Device manufacturer.
  final String? manufacturer;

  /// Device model name.
  final String? modelName;

  /// Device operating system.
  final String? operatingSystem;

  /// Hosts DeviceID (UUID, for DataElements matching).
  final String? hostsDeviceId;

  // ─── Multi-interface ───
  /// Additional network interfaces for this device.
  final List<ClientInterfaceInfo> additionalInterfaces;

  ClientDevice({
    required this.mac,
    required this.hostName,
    this.friendlyName,
    required this.isActive,
    required this.ip,
    this.ipv6Addresses = const [],
    this.layer1Interface = '',
    required this.connectionType,
    this.wifi,
    this.parentNodeId,
    this.parentNodeName,
    this.manufacturer,
    this.modelName,
    this.operatingSystem,
    this.hostsDeviceId,
    this.additionalInterfaces = const [],
  });

  // ─── NetworkEntity implementation ───

  @override
  String get id => mac;

  @override
  String get displayName {
    if (friendlyName != null && friendlyName!.isNotEmpty) return friendlyName!;
    if (hostName.isNotEmpty) return hostName;
    return mac;
  }

  @override
  bool get isOnline => isActive;

  @override
  String? get ipAddress => ip.isNotEmpty ? ip : null;

  // ─── Computed getters ───

  /// Whether this is a WiFi device.
  bool get isWifi => connectionType == ConnectionType.wifi;

  /// Signal strength in dBm (from WiFi info).
  int? get signalStrength => wifi?.signalStrength;

  /// Signal quality (0.0–1.0).
  double get signalQuality => wifi?.signalQuality ?? 0;

  /// Signal level (0–3).
  int get signalLevel => wifi?.signalLevel ?? 0;

  /// WiFi band (2.4GHz, 5GHz, 6GHz).
  String? get band => wifi?.band;

  /// SSID name.
  String? get ssidName => wifi?.ssidName;

  /// Downlink rate in kbps.
  int? get downlinkRate => wifi?.downlinkRate;

  /// Uplink rate in kbps.
  int? get uplinkRate => wifi?.uplinkRate;

  /// Whether WiFi details should be displayed.
  bool get hasWifiData => wifi?.hasData ?? false;

  /// Whether this device has multiple network interfaces.
  bool get hasMultipleInterfaces => additionalInterfaces.isNotEmpty;

  /// All MAC addresses for this device (primary + additional).
  List<String> get allMacAddresses =>
      [mac, ...additionalInterfaces.map((i) => i.mac)];

  /// Total number of interfaces.
  int get interfaceCount => 1 + additionalInterfaces.length;

  /// Whether any interface is active.
  bool get hasAnyActiveInterface =>
      isActive || additionalInterfaces.any((i) => i.isActive);

  /// Creates a copy with optional field overrides.
  ClientDevice copyWith({
    String? mac,
    String? hostName,
    String? friendlyName,
    bool? isActive,
    String? ip,
    List<String>? ipv6Addresses,
    String? layer1Interface,
    ConnectionType? connectionType,
    WifiConnectionInfo? wifi,
    String? parentNodeId,
    String? parentNodeName,
    String? manufacturer,
    String? modelName,
    String? operatingSystem,
    String? hostsDeviceId,
    List<ClientInterfaceInfo>? additionalInterfaces,
  }) {
    return ClientDevice(
      mac: mac ?? this.mac,
      hostName: hostName ?? this.hostName,
      friendlyName: friendlyName ?? this.friendlyName,
      isActive: isActive ?? this.isActive,
      ip: ip ?? this.ip,
      ipv6Addresses: ipv6Addresses ?? this.ipv6Addresses,
      layer1Interface: layer1Interface ?? this.layer1Interface,
      connectionType: connectionType ?? this.connectionType,
      wifi: wifi ?? this.wifi,
      parentNodeId: parentNodeId ?? this.parentNodeId,
      parentNodeName: parentNodeName ?? this.parentNodeName,
      manufacturer: manufacturer ?? this.manufacturer,
      modelName: modelName ?? this.modelName,
      operatingSystem: operatingSystem ?? this.operatingSystem,
      hostsDeviceId: hostsDeviceId ?? this.hostsDeviceId,
      additionalInterfaces: additionalInterfaces ?? this.additionalInterfaces,
    );
  }

  @override
  List<Object?> get props => [
        mac,
        hostName,
        friendlyName,
        isActive,
        ip,
        ipv6Addresses,
        layer1Interface,
        connectionType,
        wifi,
        parentNodeId,
        parentNodeName,
        manufacturer,
        modelName,
        operatingSystem,
        hostsDeviceId,
        additionalInterfaces,
      ];
}

/// Extension methods for List<ClientDevice>.
extension ClientDeviceListExt on List<ClientDevice> {
  /// Returns only online devices.
  List<ClientDevice> get online => where((d) => d.isOnline).toList();

  /// Returns only offline devices.
  List<ClientDevice> get offline => where((d) => !d.isOnline).toList();

  /// Returns only WiFi devices.
  List<ClientDevice> get wifiDevices => where((d) => d.isWifi).toList();

  /// Returns only wired devices.
  List<ClientDevice> get wiredDevices => where((d) => !d.isWifi).toList();
}
