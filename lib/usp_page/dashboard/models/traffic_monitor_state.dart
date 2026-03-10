import 'package:equatable/equatable.dart';

/// A single snapshot of WAN traffic rates at a point in time.
class TrafficSnapshot extends Equatable {
  final DateTime timestamp;

  /// Bytes per second — upload (sent) direction.
  final double uploadBytesPerSec;

  /// Bytes per second — download (received) direction.
  final double downloadBytesPerSec;

  /// Cumulative total bytes sent since router boot.
  final int totalBytesSent;

  /// Cumulative total bytes received since router boot.
  final int totalBytesReceived;

  const TrafficSnapshot({
    required this.timestamp,
    required this.uploadBytesPerSec,
    required this.downloadBytesPerSec,
    required this.totalBytesSent,
    required this.totalBytesReceived,
  });

  @override
  List<Object?> get props => [
        timestamp,
        uploadBytesPerSec,
        downloadBytesPerSec,
        totalBytesSent,
        totalBytesReceived,
      ];
}

/// State for the traffic monitor provider (ring buffer + timer config).
class TrafficMonitorState extends Equatable {
  final List<TrafficSnapshot> history;
  final Duration? refreshInterval;
  final bool isFetching;

  /// Previous raw counters for delta calculation.
  final int? lastBytesSent;
  final int? lastBytesReceived;
  final DateTime? lastTimestamp;

  static const int maxHistory = 60;

  const TrafficMonitorState({
    this.history = const [],
    this.refreshInterval,
    this.isFetching = false,
    this.lastBytesSent,
    this.lastBytesReceived,
    this.lastTimestamp,
  });

  TrafficSnapshot? get latest => history.isEmpty ? null : history.last;

  TrafficMonitorState copyWith({
    List<TrafficSnapshot>? history,
    Duration? Function()? refreshInterval,
    bool? isFetching,
    int? Function()? lastBytesSent,
    int? Function()? lastBytesReceived,
    DateTime? Function()? lastTimestamp,
  }) {
    return TrafficMonitorState(
      history: history ?? this.history,
      refreshInterval:
          refreshInterval != null ? refreshInterval() : this.refreshInterval,
      isFetching: isFetching ?? this.isFetching,
      lastBytesSent:
          lastBytesSent != null ? lastBytesSent() : this.lastBytesSent,
      lastBytesReceived:
          lastBytesReceived != null ? lastBytesReceived() : this.lastBytesReceived,
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
