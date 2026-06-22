import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/errors/service_error.dart';

enum SpeedTestStep {
  idle,
  testingLatency,
  testingDownload,
  testingUpload,
  completed,
  error,
}

/// Available speed test servers
class SpeedTestServer extends Equatable {
  final String name;
  final String host;
  final String downloadUrl;
  final int sizeMb;

  const SpeedTestServer({
    required this.name,
    required this.host,
    required this.downloadUrl,
    this.sizeMb = 100,
  });

  @override
  List<Object?> get props => [name, host, downloadUrl, sizeMb];

  static const List<SpeedTestServer> all = [
    // Tokyo Linode - Most reliable for East Asia
    SpeedTestServer(
      name: 'Tokyo (Linode 100MB)',
      host: 'speedtest.tokyo2.linode.com',
      downloadUrl: 'http://speedtest.tokyo2.linode.com/100MB-tokyo2.bin',
      sizeMb: 100,
    ),
    // Small file test (10MB .dat) - Use if network is very slow
    SpeedTestServer(
      name: 'Global (Online.net 10MB)',
      host: 'ping.online.net',
      downloadUrl: 'http://ping.online.net/10Mo.dat',
      sizeMb: 10,
    ),
    // Singapore nodes
    SpeedTestServer(
      name: 'Singapore (Linode 100MB)',
      host: 'speedtest.singapore.linode.com',
      downloadUrl: 'http://speedtest.singapore.linode.com/100MB-singapore.bin',
      sizeMb: 100,
    ),
    // US & EU
    SpeedTestServer(
      name: 'US East (Newark 100MB)',
      host: 'speedtest.newark.linode.com',
      downloadUrl: 'http://speedtest.newark.linode.com/100MB-newark.bin',
      sizeMb: 100,
    ),
    SpeedTestServer(
      name: 'Europe (London 100MB)',
      host: 'speedtest.london.linode.com',
      downloadUrl: 'http://speedtest.london.linode.com/100MB-london.bin',
      sizeMb: 100,
    ),
  ];
}

class SpeedTestResult extends Equatable {
  final String? serverHost;
  final int? latencyMs;
  final String? downloadStatus;
  final int? downloadBps;
  final int? downloadBytes;
  final int? downloadDurationMs;
  final String? uploadStatus;
  final int? uploadBps;
  final int? uploadBytes;
  final int? uploadDurationMs;

  const SpeedTestResult({
    this.serverHost,
    this.latencyMs,
    this.downloadStatus,
    this.downloadBps,
    this.downloadBytes,
    this.downloadDurationMs,
    this.uploadStatus,
    this.uploadBps,
    this.uploadBytes,
    this.uploadDurationMs,
  });

  double get downloadMbps => (downloadBps ?? 0) / 1000000;
  double get uploadMbps => (uploadBps ?? 0) / 1000000;
  bool get isDownloadComplete => downloadStatus == 'Complete';
  bool get isUploadComplete => uploadStatus == 'Complete';
  bool get hasUpload => uploadStatus != null && uploadStatus != 'NotSupported';
  bool get hasLatency => latencyMs != null;

  /// Whether download speed is considered slow (< 10 Mbps).
  bool get isSlowDownload => isDownloadComplete && downloadMbps < 10;

  /// Whether upload speed is considered slow (< 2 Mbps).
  bool get isSlowUpload => hasUpload && isUploadComplete && uploadMbps < 2;

  SpeedTestResult copyWith({
    String? serverHost,
    int? latencyMs,
    String? downloadStatus,
    int? downloadBps,
    int? downloadBytes,
    int? downloadDurationMs,
    String? uploadStatus,
    int? uploadBps,
    int? uploadBytes,
    int? uploadDurationMs,
  }) {
    return SpeedTestResult(
      serverHost: serverHost ?? this.serverHost,
      latencyMs: latencyMs ?? this.latencyMs,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      downloadBps: downloadBps ?? this.downloadBps,
      downloadBytes: downloadBytes ?? this.downloadBytes,
      downloadDurationMs: downloadDurationMs ?? this.downloadDurationMs,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadBps: uploadBps ?? this.uploadBps,
      uploadBytes: uploadBytes ?? this.uploadBytes,
      uploadDurationMs: uploadDurationMs ?? this.uploadDurationMs,
    );
  }

  @override
  List<Object?> get props => [
        serverHost,
        latencyMs,
        downloadStatus,
        downloadBps,
        downloadBytes,
        downloadDurationMs,
        uploadStatus,
        uploadBps,
        uploadBytes,
        uploadDurationMs,
      ];
}

class SpeedTestState extends Equatable {
  final SpeedTestStep step;
  final SpeedTestServer selectedServer;
  final SpeedTestResult? result;
  final ServiceError? error;
  final String? progressMessage;

  const SpeedTestState({
    this.step = SpeedTestStep.idle,
    this.selectedServer = const SpeedTestServer(
      name: 'Tokyo (Linode 100MB)',
      host: 'speedtest.tokyo2.linode.com',
      downloadUrl: 'http://speedtest.tokyo2.linode.com/100MB-tokyo2.bin',
      sizeMb: 100,
    ),
    this.result,
    this.error,
    this.progressMessage,
  });

  bool get isRunning =>
      step != SpeedTestStep.idle &&
      step != SpeedTestStep.completed &&
      step != SpeedTestStep.error;

  bool get hasResult => result != null && step == SpeedTestStep.completed;

  SpeedTestState copyWith({
    SpeedTestStep? step,
    SpeedTestServer? selectedServer,
    SpeedTestResult? result,
    bool clearResult = false,
    ServiceError? error,
    bool clearError = false,
    String? progressMessage,
    bool clearProgress = false,
  }) {
    return SpeedTestState(
      step: step ?? this.step,
      selectedServer: selectedServer ?? this.selectedServer,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
      progressMessage:
          clearProgress ? null : (progressMessage ?? this.progressMessage),
    );
  }

  @override
  List<Object?> get props =>
      [step, selectedServer, result, error, progressMessage];
}
