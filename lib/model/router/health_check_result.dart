import 'package:equatable/equatable.dart';

class HealthCheckResult extends Equatable {
  final int resultID;
  final String timestamp;
  final List<String> healthCheckModulesRequested;
  final SpeedTestResult? speedTestResult;

  // final ErResult? channelAnalyzerResult;
  // final ErResult? deviceScannerResult;

  const HealthCheckResult({
    required this.resultID,
    required this.timestamp,
    required this.healthCheckModulesRequested,
    this.speedTestResult,
  });

  @override
  List<Object?> get props => [
        resultID,
        timestamp,
        healthCheckModulesRequested,
        speedTestResult,
      ];

  HealthCheckResult copyWith({
    int? resultID,
    String? timestamp,
    List<String>? healthCheckModulesRequested,
    SpeedTestResult? speedTestResult,
  }) {
    return HealthCheckResult(
      resultID: resultID ?? this.resultID,
      timestamp: timestamp ?? this.timestamp,
      healthCheckModulesRequested:
          healthCheckModulesRequested ?? this.healthCheckModulesRequested,
      speedTestResult: speedTestResult ?? this.speedTestResult,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resultID': resultID,
      'timestamp': timestamp,
      'healthCheckModulesRequested': healthCheckModulesRequested,
      'speedTestResult': speedTestResult,
    };
  }

  factory HealthCheckResult.fromJson(Map<String, dynamic> json) {
    return HealthCheckResult(
      resultID: json['resultID'],
      timestamp: json['timestamp'],
      healthCheckModulesRequested:
          List.from(json['healthCheckModulesRequested']),
      speedTestResult: SpeedTestResult.fromJson(json['speedTestResult']),
    );
  }
}

class SpeedTestResult extends Equatable {
  final int resultID;
  final String exitCode;
  final String? serverID;
  final int? latency;
  final int? uploadBandwidth;
  final int? downloadBandwidth;

  const SpeedTestResult({
    required this.resultID,
    required this.exitCode,
    this.serverID,
    this.latency,
    this.uploadBandwidth,
    this.downloadBandwidth,
  });

  @override
  List<Object?> get props => [
        resultID,
        exitCode,
        serverID,
        latency,
        uploadBandwidth,
        downloadBandwidth,
      ];

  SpeedTestResult copyWith({
    int? resultID,
    String? exitCode,
    String? serverID,
    int? latency,
    int? uploadBandwidth,
    int? downloadBandwidth,
  }) {
    return SpeedTestResult(
      resultID: resultID ?? this.resultID,
      exitCode: exitCode ?? this.exitCode,
      serverID: serverID ?? this.serverID,
      latency: latency ?? this.latency,
      uploadBandwidth: uploadBandwidth ?? this.uploadBandwidth,
      downloadBandwidth: downloadBandwidth ?? this.downloadBandwidth,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resultID': resultID,
      'exitCode': exitCode,
      'serverID': serverID,
      'latency': latency,
      'uploadBandwidth': uploadBandwidth,
      'downloadBandwidth': downloadBandwidth,
    };
  }

  factory SpeedTestResult.fromJson(Map<String, dynamic> json) {
    return SpeedTestResult(
      resultID: json['resultID'],
      exitCode: json['exitCode'],
      serverID: json['serverID'],
      latency: json['latency'],
      uploadBandwidth: json['uploadBandwidth'],
      downloadBandwidth: json['downloadBandwidth'],
    );
  }
}
