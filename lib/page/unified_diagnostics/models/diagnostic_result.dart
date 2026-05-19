import 'package:equatable/equatable.dart';

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

/// Result of a single diagnostic step.
class DiagnosticStepResult extends Equatable {
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

  DiagnosticStepResult({
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

/// WAN status check result.
class WanStatusCheckResult extends DiagnosticStepResult {
  final String status;
  final String ipAddress;
  final String addressingType;

  WanStatusCheckResult({
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

/// Ping check result.
class PingCheckResult extends DiagnosticStepResult {
  final String host;
  final int successCount;
  final int failureCount;
  final int avgResponseTime;

  PingCheckResult({
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

/// WiFi signal check result.
class WifiSignalCheckResult extends DiagnosticStepResult {
  final int rssi;
  final int channel;
  final String band;
  final int connectedDevices;

  WifiSignalCheckResult({
    required this.rssi,
    required this.channel,
    required this.band,
    required this.connectedDevices,
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
          },
        );

  bool get isWeakSignal => rssi < -70;
  bool get isMediumSignal => rssi >= -70 && rssi < -50;
  bool get isStrongSignal => rssi >= -50;
}

/// Connected devices check result.
class ConnectedDevicesCheckResult extends DiagnosticStepResult {
  final int totalDevices;
  final int activeDevices;
  final List<String> highBandwidthDevices;

  ConnectedDevicesCheckResult({
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

/// Traceroute check result with hop details.
class TracerouteCheckResult extends DiagnosticStepResult {
  final List<TracerouteHopInfo> hops;
  final String targetHost;

  TracerouteCheckResult({
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

  List<TracerouteHopInfo> get slowHops =>
      hops.where((h) => h.avgRoundTrip > 200).toList();
}

/// Individual hop info for traceroute display.
class TracerouteHopInfo {
  final int hopNumber;
  final String host;
  final String hostAddress;
  final int avgRoundTrip;

  const TracerouteHopInfo({
    required this.hopNumber,
    required this.host,
    required this.hostAddress,
    required this.avgRoundTrip,
  });

  bool get isSlow => avgRoundTrip > 200;
  bool get isUnreachable => hostAddress.isEmpty || avgRoundTrip == 0;
}
