import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/_shared/models/network_entity.dart';
import 'package:privacy_gui/page/_shared/models/wifi_connection_info.dart';

/// Connection type for client devices.
enum ConnectionType { wifi, wired }

/// Extension for connection type icons.
extension ConnectionTypeExt on ConnectionType {
  IconData get icon => switch (this) {
        ConnectionType.wifi => Icons.wifi,
        ConnectionType.wired => Icons.settings_ethernet,
      };
}

/// Network interface info for multi-interface devices.
///
/// When a device connects via multiple interfaces (e.g., WiFi + Ethernet),
/// the primary interface is stored in [ClientDevice] fields and additional
/// interfaces are stored in [ClientDevice.additionalInterfaces].
class ClientInterfaceInfo with EquatableMixin, DiagnosticNamed {
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

  /// Signal strength in dBm (from WiFi info).
  int? get signalStrength => wifi?.signalStrength;

  /// WiFi band (2.4GHz, 5GHz, 6GHz).
  String? get band => wifi?.band;

  /// SSID name.
  String? get ssidName => wifi?.ssidName;

  @override
  List<Object?> get props => [
        mac,
        ip,
        connectionType,
        isActive,
        layer1Interface,
        wifi,
      ];

  @override
  String get diagnosticName => 'ClientInterfaceInfo';

  @override
  Map<String, Object?> get namedProps => {
        'mac': mac,
        'ip': ip,
        'connectionType': connectionType,
        'isActive': isActive,
        'layer1Interface': layer1Interface,
        'wifi': wifi,
      };
}

/// Client device connected to the mesh network.
///
/// Represents end-user devices (phones, laptops, etc.) that connect to
/// mesh nodes. Implements [NetworkEntity] for unified identity handling.
final class ClientDevice extends NetworkEntity with DiagnosticNamed {
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
  ///
  /// For an [isUnattributed] device this is the raw, unresolvable ID the router
  /// claimed (or null if it claimed none) — kept for logs and diagnostics, and
  /// not rendered anywhere. Read [parentNodeName] for what to show.
  final String? parentNodeId;

  final String? _parentNodeName;

  /// Parent mesh node display name (for UI).
  ///
  /// Always null when [isUnattributed]: an orphan has no parent to name. The
  /// invariant is enforced here rather than left to callers because several
  /// surfaces key off this name instead of the flag — the device card's
  /// parent-node badge, analytics grouping, the detail view — and a name left
  /// in place makes one device assert both "unattributed" and "on <node>",
  /// which is exactly the false attribution issue #1439 is about. Note
  /// [copyWith] cannot express the invariant on its own: it merges with
  /// `?? this`, so it can never null a field.
  String? get parentNodeName => isUnattributed ? null : _parentNodeName;

  /// Whether this device's parent node could not be resolved.
  ///
  /// True only in a mesh network — one with at least one extender, so there is
  /// more than one node a client could belong to — and only for a device whose
  /// parent genuinely cannot be resolved: an *online Wi-Fi* client absent from
  /// the DataElements station map, or a client whose parent ID matches no known
  /// node. Such a device is *unattributed*: it belongs to the network but to no
  /// specific node, and must not be presented as if it were on the master.
  ///
  /// Wired and offline clients are never unattributed. They are absent from the
  /// station map by construction — DataElements lists associated Wi-Fi stations
  /// only — so a null parent ID says nothing about them, and flagging them
  /// would relabel every wired device in a mesh (issue #1439).
  ///
  /// The UI reads this flag directly rather than inferring orphan-hood from an
  /// empty [parentNodeName].
  final bool isUnattributed;

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
    String? parentNodeName,
    this.isUnattributed = false,
    this.manufacturer,
    this.modelName,
    this.operatingSystem,
    this.hostsDeviceId,
    this.additionalInterfaces = const [],
  }) : _parentNodeName = parentNodeName;

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

  /// Total throughput in kbps (uplink + downlink).
  int get totalThroughput => (downlinkRate ?? 0) + (uplinkRate ?? 0);

  /// Whether to display signal information (WiFi + online + has signal).
  bool get hasSignalDisplay => isWifi && isActive && signalStrength != null;

  /// Whether WiFi signal details should be shown in detail view.
  bool get shouldShowWifiDetails =>
      isWifi && isActive && (hasWifiData || signalStrength != null);

  /// Whether this device is interactive (can be tapped for detail).
  bool get isInteractive => isActive;

  /// Display opacity for list items (dimmed when offline).
  double get displayOpacity => isActive ? 1.0 : 0.5;

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
    bool? isUnattributed,
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
      // Carries the raw field, not the getter: a copy keeps whatever name the
      // router claimed, and [parentNodeName] goes on hiding it while the
      // device is unattributed.
      parentNodeName: parentNodeName ?? _parentNodeName,
      isUnattributed: isUnattributed ?? this.isUnattributed,
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
        isUnattributed,
        manufacturer,
        modelName,
        operatingSystem,
        hostsDeviceId,
        additionalInterfaces,
      ];

  @override
  String get diagnosticName => 'ClientDevice';

  @override
  Map<String, Object?> get namedProps => {
        'mac': mac,
        'hostName': hostName,
        'friendlyName': friendlyName,
        'isActive': isActive,
        'ip': ip,
        'ipv6Addresses': ipv6Addresses,
        'layer1Interface': layer1Interface,
        'connectionType': connectionType,
        'wifi': wifi,
        'parentNodeId': parentNodeId,
        'parentNodeName': parentNodeName,
        'isUnattributed': isUnattributed,
        'manufacturer': manufacturer,
        'modelName': modelName,
        'operatingSystem': operatingSystem,
        'hostsDeviceId': hostsDeviceId,
        'additionalInterfaces': additionalInterfaces,
      };
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
