import 'package:equatable/equatable.dart';

import 'package:privacy_gui/page/unified_diagnostics/models/device_score.dart';
import 'package:privacy_gui/page/unified_diagnostics/services/unified_diagnostics_service.dart';
import 'diagnostic_state.dart';

/// Severity level of a diagnostic result.
enum DiagnosticSeverity {
  /// Everything is working correctly.
  ok,

  /// Minor issue or warning.
  warning,

  /// Critical issue that likely causes the problem.
  error,

  /// Diagnostic step was skipped or not applicable.
  skipped,
}

/// Result of a single diagnostic step UI model.
class DiagnosticStepUIModel extends Equatable {
  /// Which step this result is for.
  final DiagnosticStep step;

  /// Severity of the result.
  final DiagnosticSeverity severity;

  /// Localization key for the result title.
  final String titleKey;

  /// Localization key for the result description.
  final String descriptionKey;

  /// Raw data from the diagnostic (for debugging/display).
  final Map<String, dynamic> rawData;

  /// Timestamp when this result was recorded.
  final DateTime timestamp;

  DiagnosticStepUIModel({
    required this.step,
    required this.severity,
    required this.titleKey,
    required this.descriptionKey,
    this.rawData = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isOk => severity == DiagnosticSeverity.ok;
  bool get isWarning => severity == DiagnosticSeverity.warning;
  bool get isError => severity == DiagnosticSeverity.error;
  bool get isSkipped => severity == DiagnosticSeverity.skipped;

  @override
  List<Object?> get props => [
        step,
        severity,
        titleKey,
        descriptionKey,
        rawData,
        timestamp,
      ];
}

/// WAN status check result UI model.
class WanStatusCheckUIModel extends DiagnosticStepUIModel {
  final String status;
  final String ipAddress;
  final String addressingType;

  WanStatusCheckUIModel({
    required this.status,
    required this.ipAddress,
    required this.addressingType,
    required super.severity,
    required super.titleKey,
    required super.descriptionKey,
    super.timestamp,
  }) : super(
          step: DiagnosticStep.checkingWanStatus,
          rawData: {
            'status': status,
            'ipAddress': ipAddress,
            'addressingType': addressingType,
          },
        );

  bool get isUp => status == 'Up';
  bool get hasIp => ipAddress.isNotEmpty;
}

/// Ping check result UI model.
class PingCheckUIModel extends DiagnosticStepUIModel {
  final String host;
  final int successCount;
  final int failureCount;
  final int avgResponseTime;

  PingCheckUIModel({
    required DiagnosticStep step,
    required this.host,
    required this.successCount,
    required this.failureCount,
    required this.avgResponseTime,
    required super.severity,
    required super.titleKey,
    required super.descriptionKey,
    super.timestamp,
  }) : super(
          step: step,
          rawData: {
            'host': host,
            'successCount': successCount,
            'failureCount': failureCount,
            'avgResponseTime': avgResponseTime,
          },
        );

  int get totalCount => successCount + failureCount;
  double get successRate =>
      totalCount > 0 ? successCount / totalCount * 100 : 0;
  bool get allFailed => successCount == 0 && failureCount > 0;
  bool get allSucceeded => failureCount == 0 && successCount > 0;
}

/// WiFi signal check result UI model with per-radio breakdown.
///
/// `rssi` is the weighted average RSSI across all active wireless clients
/// (so a single number summarizes overall coverage). `radios` provides the
/// per-radio detail used by the result UI.
class WifiSignalCheckUIModel extends DiagnosticStepUIModel {
  final int rssi;
  final int channel;
  final String band;
  final int connectedDevices;
  final List<RadioSignalStatsUIModel> radios;

  WifiSignalCheckUIModel({
    required this.rssi,
    required this.channel,
    required this.band,
    required this.connectedDevices,
    this.radios = const [],
    required super.severity,
    required super.titleKey,
    required super.descriptionKey,
    super.timestamp,
  }) : super(
          step: DiagnosticStep.checkingWifiSignal,
          rawData: {
            'rssi': rssi,
            'channel': channel,
            'band': band,
            'connectedDevices': connectedDevices,
            'radios': radios
                .map((r) => {
                      'instancePath': r.instancePath,
                      'band': r.band,
                      'channel': r.channel,
                      'clientCount': r.clientCount,
                      'averageRssi': r.averageRssi,
                      'minRssi': r.minRssi,
                    })
                .toList(),
          },
        );

  bool get isWeakSignal => connectedDevices > 0 && rssi < -70;
  bool get isMediumSignal => rssi >= -70 && rssi < -50;
  bool get isStrongSignal => rssi >= -50;
  bool get hasPerRadio => radios.isNotEmpty;
}

/// DHCP pool capacity / usage check result UI model.
class DhcpPoolCheckUIModel extends DiagnosticStepUIModel {
  final bool dhcpEnabled;
  final String minAddress;
  final String maxAddress;
  final int capacity;
  final int usedLeases;
  final int totalLeases;

  DhcpPoolCheckUIModel({
    required this.dhcpEnabled,
    required this.minAddress,
    required this.maxAddress,
    required this.capacity,
    required this.usedLeases,
    required this.totalLeases,
    required super.severity,
    required super.titleKey,
    required super.descriptionKey,
    super.timestamp,
  }) : super(
          step: DiagnosticStep.checkingDhcpPool,
          rawData: {
            'dhcpEnabled': dhcpEnabled,
            'minAddress': minAddress,
            'maxAddress': maxAddress,
            'capacity': capacity,
            'usedLeases': usedLeases,
            'totalLeases': totalLeases,
          },
        );

  /// Fraction of pool used (0.0–1.0). Returns 0 when capacity is unknown.
  double get usageRatio => capacity > 0 ? usedLeases / capacity : 0;

  bool get isExhausted => capacity > 0 && usedLeases >= capacity;
  bool get isNearCapacity => usageRatio >= 0.9;
  bool get capacityUnknown => capacity == 0;
}

/// Connected devices check result UI model.
class ConnectedDevicesCheckUIModel extends DiagnosticStepUIModel {
  final int totalDevices;
  final int activeDevices;
  final List<String> highBandwidthDevices;

  ConnectedDevicesCheckUIModel({
    required this.totalDevices,
    required this.activeDevices,
    required this.highBandwidthDevices,
    required super.severity,
    required super.titleKey,
    required super.descriptionKey,
    super.timestamp,
  }) : super(
          step: DiagnosticStep.checkingConnectedDevices,
          rawData: {
            'totalDevices': totalDevices,
            'activeDevices': activeDevices,
            'highBandwidthDevices': highBandwidthDevices,
          },
        );

  bool get hasManyDevices => totalDevices > 20;
  bool get hasHighBandwidthDevices => highBandwidthDevices.isNotEmpty;
}

/// Traceroute check result UI model with hop details.
class TracerouteCheckUIModel extends DiagnosticStepUIModel {
  final List<TracerouteHopUIModel> hops;
  final String targetHost;

  TracerouteCheckUIModel({
    required this.hops,
    required this.targetHost,
    required super.severity,
    required super.titleKey,
    required super.descriptionKey,
    super.timestamp,
  }) : super(
          step: DiagnosticStep.runningTraceroute,
          rawData: {
            'hopCount': hops.length,
            'slowHopCount': hops.where((h) => h.avgRoundTrip > 200).length,
            'targetHost': targetHost,
          },
        );

  List<TracerouteHopUIModel> get slowHops =>
      hops.where((h) => h.avgRoundTrip > 200).toList();
}

/// Individual hop info UI model for traceroute display.
class TracerouteHopUIModel {
  final int hopNumber;
  final String host;
  final String hostAddress;
  final int avgRoundTrip;

  const TracerouteHopUIModel({
    required this.hopNumber,
    required this.host,
    required this.hostAddress,
    required this.avgRoundTrip,
  });

  bool get isSlow => avgRoundTrip > 200;
  bool get isUnreachable => hostAddress.isEmpty || avgRoundTrip == 0;
}

/// Device issues check result UI model (Flow 2).
class DeviceIssuesCheckUIModel extends DiagnosticStepUIModel {
  final int totalDevices;
  final int devicesWithIssues;
  final List<String> weakSignalDevices;
  final List<String> lowDataRateDevices;
  final List<DeviceScoreUIModel> deviceScores;

  DeviceIssuesCheckUIModel({
    required this.totalDevices,
    required this.devicesWithIssues,
    required this.weakSignalDevices,
    required this.lowDataRateDevices,
    required this.deviceScores,
    required super.severity,
    required super.titleKey,
    required super.descriptionKey,
    super.timestamp,
  }) : super(
          step: DiagnosticStep.checkingConnectedDevices,
          rawData: {
            'totalDevices': totalDevices,
            'devicesWithIssues': devicesWithIssues,
            'weakSignalDevices': weakSignalDevices,
            'lowDataRateDevices': lowDataRateDevices,
          },
        );

  bool get hasIssues => devicesWithIssues > 0;
}

/// WiFi coverage check result UI model (Flow 3).
class WifiCoverageCheckUIModel extends DiagnosticStepUIModel {
  final int totalWirelessDevices;
  final List<String> weakSignalDevices;
  final int averageSignalStrength;
  final List<WiFiRadioUIModel> radios;

  WifiCoverageCheckUIModel({
    required this.totalWirelessDevices,
    required this.weakSignalDevices,
    required this.averageSignalStrength,
    required this.radios,
    required super.severity,
    required super.titleKey,
    required super.descriptionKey,
    super.timestamp,
  }) : super(
          step: DiagnosticStep.checkingWifiSignal,
          rawData: {
            'totalWirelessDevices': totalWirelessDevices,
            'weakSignalDevices': weakSignalDevices,
            'averageSignalStrength': averageSignalStrength,
          },
        );

  bool get hasWeakSignalDevices => weakSignalDevices.isNotEmpty;
}

/// DNS lookup check result UI model.
class DnsLookupCheckUIModel extends DiagnosticStepUIModel {
  final String hostName;
  final List<String> resolvedIps;
  final String dnsServerUsed;
  final int responseTimeMs;
  final List<String> configuredDnsServers;

  DnsLookupCheckUIModel({
    required this.hostName,
    required this.resolvedIps,
    required this.dnsServerUsed,
    required this.responseTimeMs,
    required this.configuredDnsServers,
    required super.severity,
    required super.titleKey,
    required super.descriptionKey,
    super.timestamp,
  }) : super(
          step: DiagnosticStep.dnsLookup,
          rawData: {
            'hostName': hostName,
            'resolvedIps': resolvedIps,
            'dnsServerUsed': dnsServerUsed,
            'responseTimeMs': responseTimeMs,
            'configuredDnsServers': configuredDnsServers,
          },
        );

  bool get hasResolved => resolvedIps.isNotEmpty;
}

/// Severity bucket for a single mesh node's backhaul health.
enum MeshBackhaulSeverity {
  /// Wired backhaul, or wireless link with strong PHY rate + RSSI.
  healthy,

  /// Wireless link with marginal PHY rate or RSSI.
  weak,

  /// Wireless link with poor PHY rate or very low RSSI.
  poor,
}

/// Per-node backhaul health record.
class MeshNodeBackhaulUIModel extends Equatable {
  /// Stable node identifier (DataElements `Device.{i}.ID`, typically MAC).
  final String nodeId;

  /// Human-friendly label (manufacturer model, falls back to nodeId).
  final String label;

  /// Backhaul media type (e.g. "Wi-Fi", "Ethernet", "MoCA", "G.hn").
  final String mediaType;

  /// Negotiated PHY rate in Mbps (-1 if unknown).
  final int phyRateMbps;

  /// Last data uplink rate observed in Mbps (-1 if unknown).
  final int lastUplinkRateMbps;

  /// Backhaul RSSI in dBm (0 if unknown — wired backhaul).
  final int signalStrengthDbm;

  /// Whether this node is the controller (no backhaul of its own).
  final bool isController;

  /// Severity bucket for this node.
  final MeshBackhaulSeverity severity;

  const MeshNodeBackhaulUIModel({
    required this.nodeId,
    required this.label,
    required this.mediaType,
    required this.phyRateMbps,
    required this.lastUplinkRateMbps,
    required this.signalStrengthDbm,
    required this.isController,
    required this.severity,
  });

  bool get isWired =>
      mediaType.contains('Ethernet') ||
      mediaType.contains('MoCA') ||
      mediaType.contains('G.hn');

  @override
  List<Object?> get props => [
        nodeId,
        label,
        mediaType,
        phyRateMbps,
        lastUplinkRateMbps,
        signalStrengthDbm,
        isController,
        severity,
      ];
}

/// Mesh backhaul check result UI model (Flow: meshBackhaul).
///
/// `nodes` excludes the controller. When `nodes` is empty the deployment is a
/// single-router setup and the step is reported as [DiagnosticSeverity.skipped].
class MeshBackhaulCheckUIModel extends DiagnosticStepUIModel {
  final List<MeshNodeBackhaulUIModel> nodes;

  MeshBackhaulCheckUIModel({
    required this.nodes,
    required super.severity,
    required super.titleKey,
    required super.descriptionKey,
    super.timestamp,
  }) : super(
          step: DiagnosticStep.checkingMeshBackhaul,
          rawData: {
            'nodeCount': nodes.length,
            'poorCount': nodes
                .where((n) => n.severity == MeshBackhaulSeverity.poor)
                .length,
            'weakCount': nodes
                .where((n) => n.severity == MeshBackhaulSeverity.weak)
                .length,
          },
        );

  int get poorCount =>
      nodes.where((n) => n.severity == MeshBackhaulSeverity.poor).length;
  int get weakCount =>
      nodes.where((n) => n.severity == MeshBackhaulSeverity.weak).length;
  bool get hasIssues => poorCount > 0 || weakCount > 0;
}

/// Intermittent connection check result UI model (Flow 4).
class IntermittentCheckUIModel extends DiagnosticStepUIModel {
  final int uptimeSeconds;
  final String uptimeFormatted;
  final double pingSuccessRate;
  final int averageLatencyMs;
  final int jitterMs;
  final bool hasHighJitter;
  final bool hasPacketLoss;
  final bool recentReboot;

  IntermittentCheckUIModel({
    required this.uptimeSeconds,
    required this.uptimeFormatted,
    required this.pingSuccessRate,
    required this.averageLatencyMs,
    required this.jitterMs,
    required this.hasHighJitter,
    required this.hasPacketLoss,
    required this.recentReboot,
    required super.severity,
    required super.titleKey,
    required super.descriptionKey,
    super.timestamp,
  }) : super(
          step: DiagnosticStep.pingInternet,
          rawData: {
            'uptimeSeconds': uptimeSeconds,
            'pingSuccessRate': pingSuccessRate,
            'averageLatencyMs': averageLatencyMs,
            'jitterMs': jitterMs,
          },
        );

  bool get hasIssues => hasHighJitter || hasPacketLoss || recentReboot;
}
