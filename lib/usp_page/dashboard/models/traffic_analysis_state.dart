import 'package:equatable/equatable.dart';

/// Identifies a network interface for multi-interface traffic analysis.
enum TrafficInterface { wan, lan }

/// Per-interface traffic rates and cumulative counters at a point in time.
class InterfaceTrafficSnapshot extends Equatable {
  final double uploadBytesPerSec;
  final double downloadBytesPerSec;
  final double uploadPacketsPerSec;
  final double downloadPacketsPerSec;
  final int totalBytesSent;
  final int totalBytesReceived;
  final int totalPacketsSent;
  final int totalPacketsReceived;

  // Error/discard rates (F-022)
  final double errorsSentPerSec;
  final double errorsReceivedPerSec;
  final double discardsSentPerSec;
  final double discardsReceivedPerSec;
  final int totalErrorsSent;
  final int totalErrorsReceived;
  final int totalDiscardsSent;
  final int totalDiscardsReceived;

  const InterfaceTrafficSnapshot({
    required this.uploadBytesPerSec,
    required this.downloadBytesPerSec,
    required this.uploadPacketsPerSec,
    required this.downloadPacketsPerSec,
    required this.totalBytesSent,
    required this.totalBytesReceived,
    required this.totalPacketsSent,
    required this.totalPacketsReceived,
    this.errorsSentPerSec = 0,
    this.errorsReceivedPerSec = 0,
    this.discardsSentPerSec = 0,
    this.discardsReceivedPerSec = 0,
    this.totalErrorsSent = 0,
    this.totalErrorsReceived = 0,
    this.totalDiscardsSent = 0,
    this.totalDiscardsReceived = 0,
  });

  double get totalBytesPerSec => uploadBytesPerSec + downloadBytesPerSec;
  double get totalPacketsPerSec => uploadPacketsPerSec + downloadPacketsPerSec;
  int get totalBytes => totalBytesSent + totalBytesReceived;

  double get totalErrorsPerSec => errorsSentPerSec + errorsReceivedPerSec;
  double get totalDiscardsPerSec => discardsSentPerSec + discardsReceivedPerSec;
  double get totalFaultsPerSec => totalErrorsPerSec + totalDiscardsPerSec;

  @override
  List<Object?> get props => [
        uploadBytesPerSec,
        downloadBytesPerSec,
        uploadPacketsPerSec,
        downloadPacketsPerSec,
        totalBytesSent,
        totalBytesReceived,
        errorsSentPerSec,
        errorsReceivedPerSec,
        discardsSentPerSec,
        discardsReceivedPerSec,
      ];
}

/// A time-stamped snapshot across all tracked interfaces.
class MultiInterfaceSnapshot extends Equatable {
  final DateTime timestamp;
  final Map<TrafficInterface, InterfaceTrafficSnapshot> interfaces;

  const MultiInterfaceSnapshot({
    required this.timestamp,
    required this.interfaces,
  });

  @override
  List<Object?> get props => [timestamp, interfaces];
}

/// Baseline counters for delta-rate computation.
class InterfaceBaseline extends Equatable {
  final int bytesSent;
  final int bytesReceived;
  final int packetsSent;
  final int packetsReceived;
  final int errorsSent;
  final int errorsReceived;
  final int discardsSent;
  final int discardsReceived;

  const InterfaceBaseline({
    required this.bytesSent,
    required this.bytesReceived,
    required this.packetsSent,
    required this.packetsReceived,
    this.errorsSent = 0,
    this.errorsReceived = 0,
    this.discardsSent = 0,
    this.discardsReceived = 0,
  });

  @override
  List<Object?> get props => [
        bytesSent,
        bytesReceived,
        packetsSent,
        packetsReceived,
        errorsSent,
        errorsReceived,
        discardsSent,
        discardsReceived,
      ];
}

/// Complete state for the multi-interface traffic analysis provider.
class TrafficAnalysisState extends Equatable {
  final List<MultiInterfaceSnapshot> history;
  final Duration? refreshInterval;
  final bool isFetching;
  final Map<TrafficInterface, InterfaceBaseline>? lastBaselines;
  final DateTime? lastTimestamp;

  static const int maxHistory = 60;

  const TrafficAnalysisState({
    this.history = const [],
    this.refreshInterval,
    this.isFetching = false,
    this.lastBaselines,
    this.lastTimestamp,
  });

  MultiInterfaceSnapshot? get latest => history.isEmpty ? null : history.last;

  TrafficAnalysisState copyWith({
    List<MultiInterfaceSnapshot>? history,
    Duration? Function()? refreshInterval,
    bool? isFetching,
    Map<TrafficInterface, InterfaceBaseline>? Function()? lastBaselines,
    DateTime? Function()? lastTimestamp,
  }) {
    return TrafficAnalysisState(
      history: history ?? this.history,
      refreshInterval:
          refreshInterval != null ? refreshInterval() : this.refreshInterval,
      isFetching: isFetching ?? this.isFetching,
      lastBaselines:
          lastBaselines != null ? lastBaselines() : this.lastBaselines,
      lastTimestamp:
          lastTimestamp != null ? lastTimestamp() : this.lastTimestamp,
    );
  }

  @override
  List<Object?> get props => [
        history.length,
        history.isEmpty ? null : history.last.timestamp,
        refreshInterval,
        isFetching,
      ];
}
