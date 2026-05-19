import 'package:equatable/equatable.dart';

enum SpeedTestStep {
  idle,
  testingLatency,
  testingDownload,
  testingUpload,
  completed,
  error,
}

/// Available speed test servers
class SpeedTestServer {
  final String name;
  final String host;
  final String downloadUrl;

  const SpeedTestServer({
    required this.name,
    required this.host,
    required this.downloadUrl,
  });

  static const List<SpeedTestServer> all = [
    // Asia Pacific
    SpeedTestServer(
      name: 'Singapore',
      host: 'speedtest.singapore.linode.com',
      downloadUrl: 'http://speedtest.singapore.linode.com/100MB-singapore.bin',
    ),
    SpeedTestServer(
      name: 'Tokyo',
      host: 'speedtest.tokyo2.linode.com',
      downloadUrl: 'http://speedtest.tokyo2.linode.com/100MB-tokyo2.bin',
    ),
    // Europe
    SpeedTestServer(
      name: 'London',
      host: 'speedtest.london.linode.com',
      downloadUrl: 'http://speedtest.london.linode.com/100MB-london.bin',
    ),
    SpeedTestServer(
      name: 'Frankfurt',
      host: 'speedtest.frankfurt.linode.com',
      downloadUrl: 'http://speedtest.frankfurt.linode.com/100MB-frankfurt.bin',
    ),
    // Americas
    SpeedTestServer(
      name: 'US East (Newark)',
      host: 'speedtest.newark.linode.com',
      downloadUrl: 'http://speedtest.newark.linode.com/100MB-newark.bin',
    ),
    SpeedTestServer(
      name: 'US West (Fremont)',
      host: 'speedtest.fremont.linode.com',
      downloadUrl: 'http://speedtest.fremont.linode.com/100MB-fremont.bin',
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
  final String? errorMessage;
  final String? progressMessage;

  const SpeedTestState({
    this.step = SpeedTestStep.idle,
    this.selectedServer = const SpeedTestServer(
      name: 'Singapore',
      host: 'speedtest.singapore.linode.com',
      downloadUrl: 'http://speedtest.singapore.linode.com/100MB-singapore.bin',
    ),
    this.result,
    this.errorMessage,
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
    String? errorMessage,
    bool clearError = false,
    String? progressMessage,
    bool clearProgress = false,
  }) {
    return SpeedTestState(
      step: step ?? this.step,
      selectedServer: selectedServer ?? this.selectedServer,
      result: result ?? this.result,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      progressMessage:
          clearProgress ? null : (progressMessage ?? this.progressMessage),
    );
  }

  @override
  List<Object?> get props =>
      [step, selectedServer.host, result, errorMessage, progressMessage];
}
