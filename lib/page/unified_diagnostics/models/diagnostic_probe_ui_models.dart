import 'package:privacy_gui/core/utils/wifi.dart';

// What the diagnostic probes in `UnifiedDiagnosticsService` read off the
// router, shaped for the result cards.

/// WAN status information.
class WanStatusUIModel {
  final String status;
  final String ipAddress;
  final String subnetMask;
  final String addressingType;

  const WanStatusUIModel({
    required this.status,
    required this.ipAddress,
    required this.subnetMask,
    required this.addressingType,
  });

  bool get isUp => status == 'Up';
  bool get hasIp => ipAddress.isNotEmpty;
}

/// DHCP pool usage information.
class DhcpPoolUsageUIModel {
  final bool enabled;
  final String minAddress;
  final String maxAddress;
  final int capacity;
  final int usedLeases;
  final int totalLeases;

  const DhcpPoolUsageUIModel({
    required this.enabled,
    required this.minAddress,
    required this.maxAddress,
    required this.capacity,
    required this.usedLeases,
    required this.totalLeases,
  });

  /// Fraction of pool used (0.0–1.0). Returns 0 when capacity is unknown.
  double get usageRatio => capacity > 0 ? usedLeases / capacity : 0;

  /// Pool is at or beyond capacity — new clients cannot get a lease.
  bool get isExhausted => capacity > 0 && usedLeases >= capacity;

  /// Pool is approaching capacity (>=90%).
  bool get isNearCapacity => usageRatio >= 0.9;

  /// Capacity unknown — Min/Max malformed or DHCP disabled.
  bool get capacityUnknown => capacity == 0;
}

/// WiFi radio information.
class WiFiRadioUIModel {
  final String instancePath;
  final String band;
  final int channel;
  final String channelBandwidth;
  final int transmitPower;
  final String status;
  final bool autoChannel;

  const WiFiRadioUIModel({
    required this.instancePath,
    required this.band,
    required this.channel,
    required this.channelBandwidth,
    required this.transmitPower,
    required this.status,
    required this.autoChannel,
  });

  bool get is2_4GHz => band.contains('2.4');
  bool get is5GHz => band.contains('5');
  bool get is6GHz => band.contains('6');
}

/// Connected devices summary.
class ConnectedDevicesUIModel {
  final int totalDevices;
  final int activeDevices;
  final List<String> highBandwidthDevices;

  const ConnectedDevicesUIModel({
    required this.totalDevices,
    required this.activeDevices,
    required this.highBandwidthDevices,
  });

  bool get hasManyDevices => totalDevices > 20;
  bool get hasHighBandwidthDevices => highBandwidthDevices.isNotEmpty;
}

/// Device signal information for WiFi coverage analysis.
class DeviceSignalUIModel {
  final String name;
  final String macAddress;
  final int rssiDbm;

  const DeviceSignalUIModel({
    required this.name,
    required this.macAddress,
    required this.rssiDbm,
  });

  String get signalLabel {
    if (rssiDbm >= rssiExcellent) return 'Excellent';
    if (rssiDbm >= rssiGood) return 'Good';
    if (rssiDbm >= rssiFair) return 'Fair';
    return 'Weak';
  }
}

/// WiFi coverage analysis result.
class WifiCoverageUIModel {
  final int totalWirelessDevices;
  final List<DeviceSignalUIModel> weakSignalDevices;
  final int averageSignalStrength;
  final List<WiFiRadioUIModel> radios;

  const WifiCoverageUIModel({
    required this.totalWirelessDevices,
    required this.weakSignalDevices,
    required this.averageSignalStrength,
    required this.radios,
  });

  bool get hasWeakSignalDevices => weakSignalDevices.isNotEmpty;
  bool get hasCoverageIssues =>
      weakSignalDevices.length > totalWirelessDevices * 0.3;
}

/// Aggregated RSSI / client count for a single WiFi radio.
class RadioSignalStatsUIModel {
  /// Empty when this bucket holds clients whose radio could not be resolved.
  final String instancePath;
  final String band;
  final int channel;
  final String status;
  final int clientCount;

  /// Average RSSI across active clients on this radio. 0 when no clients.
  final int averageRssi;

  /// Worst RSSI seen on this radio. 0 when no clients.
  final int minRssi;

  const RadioSignalStatsUIModel({
    required this.instancePath,
    required this.band,
    required this.channel,
    required this.status,
    required this.clientCount,
    required this.averageRssi,
    required this.minRssi,
  });

  bool get hasClients => clientCount > 0;
  bool get isResolved => instancePath.isNotEmpty;
  bool get isWeakAverage => hasClients && averageRssi < rssiGood;
}

/// Per-radio WiFi signal analysis result.
class WifiSignalPerRadioUIModel {
  final List<RadioSignalStatsUIModel> radios;

  const WifiSignalPerRadioUIModel({required this.radios});

  /// Radios with at least one active client.
  List<RadioSignalStatsUIModel> get activeRadios =>
      radios.where((r) => r.hasClients).toList();

  /// Total active wireless clients across all radios.
  int get totalClients => radios.fold<int>(0, (sum, r) => sum + r.clientCount);

  /// Weighted average RSSI across all clients (0 when no clients).
  int get weightedAverageRssi {
    int total = 0;
    int count = 0;
    for (final r in radios) {
      if (!r.hasClients) continue;
      total += r.averageRssi * r.clientCount;
      count += r.clientCount;
    }
    return count > 0 ? total ~/ count : 0;
  }

  /// True when any active radio shows weak average RSSI.
  bool get hasWeakRadio => activeRadios.any((r) => r.isWeakAverage);
}

class IntermittentUIModel {
  final int uptimeSeconds;
  final double pingSuccessRate;
  final int averageLatencyMs;
  final int jitterMs;
  final bool hasHighJitter;
  final bool hasPacketLoss;
  final bool recentReboot;

  const IntermittentUIModel({
    required this.uptimeSeconds,
    required this.pingSuccessRate,
    required this.averageLatencyMs,
    required this.jitterMs,
    required this.hasHighJitter,
    required this.hasPacketLoss,
    required this.recentReboot,
  });

  bool get hasIssues => hasHighJitter || hasPacketLoss || recentReboot;

  String get uptimeFormatted {
    final days = uptimeSeconds ~/ 86400;
    final hours = (uptimeSeconds % 86400) ~/ 3600;
    final minutes = (uptimeSeconds % 3600) ~/ 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}
