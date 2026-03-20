import 'package:equatable/equatable.dart';

/// A single snapshot of CPU and memory usage at a point in time.
class SystemSnapshot extends Equatable {
  final DateTime timestamp;
  final int cpuPercent;
  final int memoryPercent;
  final int totalMemoryKb;
  final int freeMemoryKb;

  const SystemSnapshot({
    required this.timestamp,
    required this.cpuPercent,
    required this.memoryPercent,
    required this.totalMemoryKb,
    required this.freeMemoryKb,
  });

  int get usedMemoryKb => totalMemoryKb - freeMemoryKb;

  @override
  List<Object?> get props => [
        timestamp,
        cpuPercent,
        memoryPercent,
        totalMemoryKb,
        freeMemoryKb,
      ];
}

/// State for the system monitor provider (ring buffer + timer config).
class SystemMonitorState extends Equatable {
  final List<SystemSnapshot> history;
  final Duration? refreshInterval;
  final bool isFetching;

  static const int maxHistory = 60;

  const SystemMonitorState({
    this.history = const [],
    this.refreshInterval,
    this.isFetching = false,
  });

  SystemSnapshot? get latest => history.isEmpty ? null : history.last;

  SystemMonitorState copyWith({
    List<SystemSnapshot>? history,
    Duration? Function()? refreshInterval,
    bool? isFetching,
  }) {
    return SystemMonitorState(
      history: history ?? this.history,
      refreshInterval:
          refreshInterval != null ? refreshInterval() : this.refreshInterval,
      isFetching: isFetching ?? this.isFetching,
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
