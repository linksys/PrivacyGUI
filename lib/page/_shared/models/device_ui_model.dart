import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';

// ---------------------------------------------------------------------------
// Additional Interface Info (for multi-interface devices)
// ---------------------------------------------------------------------------

/// Information about an additional network interface for a device.
///
/// When a device connects via multiple interfaces (e.g., WiFi + Ethernet),
/// the primary interface is stored in [DeviceUIModel] and additional
/// interfaces are stored in [DeviceUIModel.additionalInterfaces].
class DeviceInterfaceInfo extends Equatable with DiagnosticLoggable {
  final String mac;
  final String ip;
  final bool isWifi;
  final bool isActive;
  final String layer1Interface;
  final String? band;
  final String? ssidName;
  final int? signalStrength;

  const DeviceInterfaceInfo({
    required this.mac,
    required this.ip,
    required this.isWifi,
    required this.isActive,
    required this.layer1Interface,
    this.band,
    this.ssidName,
    this.signalStrength,
  });

  @override
  Map<String, Object?> get namedProps => {
        'mac': mac,
        'ip': ip,
        'isWifi': isWifi,
        'isActive': isActive,
        'layer1Interface': layer1Interface,
        'band': band,
        'ssidName': ssidName,
        'signalStrength': signalStrength,
      };
}

// ---------------------------------------------------------------------------
// Connection Type Enum
// ---------------------------------------------------------------------------

/// Connection type for UI display decisions.
enum DeviceConnectionType { wifi, wired }

/// Presentation Layer Model — aggregates codegen + enricher per-device info.
///
/// UI widgets depend only on this class, never directly on codegen Data Models.
/// Naming follows constitution Section 3.3.4 (class name ends with `UIModel`).
/// Implements [Equatable] per Article XI.
class DeviceUIModel extends Equatable with DiagnosticLoggable {
  // ─── Base info (from ConnectedDevice codegen) ───
  final String mac; // PhysAddress (uppercase, normalized)
  final String ip; // IPAddress
  final String hostName; // HostName
  final bool isActive; // Active
  final bool isWifi; // Derived from Layer1Interface

  // ─── WiFi enrichment (null if ethernet) ───
  final int? signalStrength; // RSSI dBm (from WifiClient)
  final int?
      downlinkRate; // kbps (from TR-181 LastDataDownlinkRate/LastDataUplinkRate)
  final int?
      uplinkRate; // kbps (from TR-181 LastDataDownlinkRate/LastDataUplinkRate)
  final String?
      band; // "2.4GHz" / "5GHz" / "6GHz" (from ClientConnectionDetail)
  final String? ssidName; // SSID name (from ClientConnectionDetail)

  // ─── IPv6 addresses (from ConnectedDeviceIpv6 children) ───
  final List<String> ipv6Addresses;

  // ─── Layer1 interface path (for port correlation) ───
  final String layer1Interface; // Raw TR-181 Layer1Interface path

  // ─── Mesh enrichment ───
  final String? parentNodeId; // Connected mesh node device ID
  final String? parentNodeName; // Mesh node model name (display)

  // ─── Device classification (from Hosts) ───
  final String? deviceRole; // "master" / "slave" / "client"
  final String? interfaceType; // "WiFi" / "Ethernet" / etc.
  final String? friendlyName; // User-friendly device name
  final String? manufacturer; // Device manufacturer
  final String? modelName; // Device model name
  final String? operatingSystem; // Device OS
  final String?
      hostsDeviceId; // Hosts DeviceID (UUID, last 12 chars = MAC for DataElements match)

  // ─── Multi-interface grouping (hostname-based) ───
  /// Additional interfaces for this device (when connected via multiple interfaces).
  /// Primary interface data is stored in this model's fields; this list contains
  /// secondary interfaces (e.g., if primary is WiFi, this may contain Ethernet).
  final List<DeviceInterfaceInfo> additionalInterfaces;

  const DeviceUIModel({
    required this.mac,
    required this.ip,
    required this.hostName,
    required this.isActive,
    required this.isWifi,
    this.layer1Interface = '',
    this.signalStrength,
    this.downlinkRate,
    this.uplinkRate,
    this.band,
    this.ssidName,
    this.ipv6Addresses = const [],
    this.parentNodeId,
    this.parentNodeName,
    this.deviceRole,
    this.interfaceType,
    this.friendlyName,
    this.manufacturer,
    this.modelName,
    this.operatingSystem,
    this.hostsDeviceId,
    this.additionalInterfaces = const [],
  });

  // ─── Computed getters ───

  /// Display name: friendlyName > hostName > MAC.
  String get displayName {
    if (friendlyName != null && friendlyName!.isNotEmpty) return friendlyName!;
    if (hostName.isNotEmpty) return hostName;
    return mac;
  }

  /// Signal quality: 0.0–1.0, mapped from RSSI.
  /// -30 dBm (excellent) → 1.0, -90 dBm (poor) → 0.0
  double get signalQuality {
    if (signalStrength == null) return 0;
    return ((signalStrength! + 90) / 60).clamp(0.0, 1.0);
  }

  /// Signal level: 0 (no signal) to 3 (excellent).
  /// Uses thresholds from [getWifiSignalLevel] for consistency.
  int get signalLevel {
    if (signalStrength == null) return 0;
    return switch (getWifiSignalLevel(signalStrength)) {
      NodeSignalLevel.excellent => 3,
      NodeSignalLevel.good => 2,
      NodeSignalLevel.fair => 1,
      NodeSignalLevel.poor || NodeSignalLevel.none => 0,
      NodeSignalLevel.wired => 0,
    };
  }

  /// Total throughput in bits/sec.
  int get totalThroughput => (downlinkRate ?? 0) + (uplinkRate ?? 0);

  // ─── Display computed getters ───

  /// Connection type enum (UI layer uses this for i18n lookup).
  DeviceConnectionType get connectionType =>
      isWifi ? DeviceConnectionType.wifi : DeviceConnectionType.wired;

  /// Whether to display signal strength indicator.
  /// True only for active WiFi devices with RSSI data.
  bool get hasSignalDisplay => isActive && isWifi && signalStrength != null;

  /// Whether WiFi details card should be visible.
  /// True only for active WiFi devices.
  bool get shouldShowWifiDetails => isWifi && isActive;

  /// Whether any WiFi detail data is available (signal, speed, or band/SSID).
  bool get hasWifiData =>
      signalStrength != null ||
      downlinkRate != null ||
      uplinkRate != null ||
      band != null ||
      ssidName != null;

  /// Whether the device tile should be interactive (tappable).
  /// Offline devices are not interactive.
  bool get isInteractive => isActive;

  /// Display opacity: 1.0 for active, 0.5 for offline devices.
  double get displayOpacity => isActive ? 1.0 : 0.5;

  /// Whether this is a client device (not a mesh node master/slave).
  bool get isClientDevice => deviceRole != 'master' && deviceRole != 'slave';

  /// Whether this device is a mesh node (master or slave router).
  bool get isMeshNode => deviceRole == 'master' || deviceRole == 'slave';

  /// Whether this device is the master (gateway) mesh node.
  bool get isMasterNode => deviceRole == 'master';

  /// Whether this device is a slave (extender) mesh node.
  bool get isSlaveNode => deviceRole == 'slave';

  // ─── Multi-interface getters ───

  /// Whether this device has multiple network interfaces.
  bool get hasMultipleInterfaces => additionalInterfaces.isNotEmpty;

  /// All MAC addresses for this device (primary + additional interfaces).
  List<String> get allMacAddresses =>
      [mac, ...additionalInterfaces.map((i) => i.mac)];

  /// Total number of interfaces for this device.
  int get interfaceCount => 1 + additionalInterfaces.length;

  /// Whether any interface is active (primary or additional).
  bool get hasAnyActiveInterface =>
      isActive || additionalInterfaces.any((i) => i.isActive);

  /// Signal strength display text (technical value, no i18n needed).
  /// Returns null if no signal data available.
  String? get signalDisplayText =>
      signalStrength != null ? '$signalStrength dBm' : null;

  /// Creates a copy with optional field overrides.
  DeviceUIModel copyWith({
    String? mac,
    String? ip,
    String? hostName,
    bool? isActive,
    bool? isWifi,
    String? layer1Interface,
    int? signalStrength,
    int? downlinkRate,
    int? uplinkRate,
    String? band,
    String? ssidName,
    List<String>? ipv6Addresses,
    String? parentNodeId,
    String? parentNodeName,
    String? deviceRole,
    String? interfaceType,
    String? friendlyName,
    String? manufacturer,
    String? modelName,
    String? operatingSystem,
    String? hostsDeviceId,
    List<DeviceInterfaceInfo>? additionalInterfaces,
  }) {
    return DeviceUIModel(
      mac: mac ?? this.mac,
      ip: ip ?? this.ip,
      hostName: hostName ?? this.hostName,
      isActive: isActive ?? this.isActive,
      isWifi: isWifi ?? this.isWifi,
      layer1Interface: layer1Interface ?? this.layer1Interface,
      signalStrength: signalStrength ?? this.signalStrength,
      downlinkRate: downlinkRate ?? this.downlinkRate,
      uplinkRate: uplinkRate ?? this.uplinkRate,
      band: band ?? this.band,
      ssidName: ssidName ?? this.ssidName,
      ipv6Addresses: ipv6Addresses ?? this.ipv6Addresses,
      parentNodeId: parentNodeId ?? this.parentNodeId,
      parentNodeName: parentNodeName ?? this.parentNodeName,
      deviceRole: deviceRole ?? this.deviceRole,
      interfaceType: interfaceType ?? this.interfaceType,
      friendlyName: friendlyName ?? this.friendlyName,
      manufacturer: manufacturer ?? this.manufacturer,
      modelName: modelName ?? this.modelName,
      operatingSystem: operatingSystem ?? this.operatingSystem,
      hostsDeviceId: hostsDeviceId ?? this.hostsDeviceId,
      additionalInterfaces: additionalInterfaces ?? this.additionalInterfaces,
    );
  }

  @override
  Map<String, Object?> get namedProps => {
        'mac': mac,
        'ip': ip,
        'hostName': hostName,
        'isActive': isActive,
        'isWifi': isWifi,
        'layer1Interface': layer1Interface,
        'ipv6Addresses': ipv6Addresses,
        'signalStrength': signalStrength,
        'downlinkRate': downlinkRate,
        'uplinkRate': uplinkRate,
        'band': band,
        'ssidName': ssidName,
        'parentNodeId': parentNodeId,
        'parentNodeName': parentNodeName,
        'deviceRole': deviceRole,
        'interfaceType': interfaceType,
        'friendlyName': friendlyName,
        'manufacturer': manufacturer,
        'modelName': modelName,
        'operatingSystem': operatingSystem,
        'hostsDeviceId': hostsDeviceId,
        'additionalInterfaces': additionalInterfaces,
      };
}

/// Extension methods for List<DeviceUIModel> to simplify common filtering.
extension DeviceUIModelListExt on List<DeviceUIModel> {
  /// Returns only client devices (excludes mesh nodes).
  List<DeviceUIModel> get clientDevices =>
      where((d) => d.isClientDevice).toList();

  /// Returns only mesh nodes (master and slave routers).
  List<DeviceUIModel> get meshNodes => where((d) => d.isMeshNode).toList();

  /// Returns the master (gateway) node, or null if not found.
  DeviceUIModel? get masterNode => where((d) => d.isMasterNode).firstOrNull;

  /// Returns all slave (extender) nodes.
  List<DeviceUIModel> get slaveNodes => where((d) => d.isSlaveNode).toList();
}
