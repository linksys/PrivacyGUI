import 'package:equatable/equatable.dart';

/// Presentation Layer Model — aggregates codegen + enricher per-device info.
///
/// UI widgets depend only on this class, never directly on codegen Data Models.
/// Naming follows constitution Section 3.3.4 (class name ends with `UIModel`).
/// Implements [Equatable] per Article XI.
class DeviceUIModel extends Equatable {
  // ─── Base info (from ConnectedDevice codegen) ───
  final String mac; // PhysAddress (uppercase, normalized)
  final String ip; // IPAddress
  final String hostName; // HostName
  final bool isActive; // Active
  final bool isWifi; // Derived from Layer1Interface

  // ─── WiFi enrichment (null if ethernet) ───
  final int? signalStrength; // RSSI dBm (from WifiClient)
  final int? downlinkRate; // bits/sec (from WifiClient)
  final int? uplinkRate; // bits/sec (from WifiClient)
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
  int get signalLevel {
    if (signalStrength == null) return 0;
    if (signalStrength! >= -50) return 3;
    if (signalStrength! >= -65) return 2;
    if (signalStrength! >= -80) return 1;
    return 0;
  }

  /// Total throughput in bits/sec.
  int get totalThroughput => (downlinkRate ?? 0) + (uplinkRate ?? 0);

  @override
  List<Object?> get props => [
        mac,
        ip,
        hostName,
        isActive,
        isWifi,
        layer1Interface,
        ipv6Addresses,
        signalStrength,
        downlinkRate,
        uplinkRate,
        band,
        ssidName,
        parentNodeId,
        parentNodeName,
        deviceRole,
        interfaceType,
        friendlyName,
        manufacturer,
        modelName,
        operatingSystem,
      ];
}
