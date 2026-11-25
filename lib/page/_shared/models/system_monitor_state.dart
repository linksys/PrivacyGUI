import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';

/// A single snapshot of CPU and memory usage at a point in time.
class SystemSnapshot extends Equatable {
  final DateTime timestamp;
  final int cpuPercent;
  final int memoryPercent;
  final int totalMemoryKb;
  final int freeMemoryKb;
  final int uptimeSeconds;

  /// The router's CPU temperature in whole °C (#1926): the
  /// `TemperatureSensor` row named `cpu-top-thermal`. Null when the router has
  /// no such row, or reports no reading for it.
  final int? cpuTemperatureCelsius;

  const SystemSnapshot({
    required this.timestamp,
    required this.cpuPercent,
    required this.memoryPercent,
    required this.totalMemoryKb,
    required this.freeMemoryKb,
    required this.uptimeSeconds,
    this.cpuTemperatureCelsius,
  });

  /// The snapshot [model] holds: the system info the session read at login or
  /// on a refresh, which the dashboard pushes before the monitor's first poll.
  /// It carries the CPU temperature, or the Device Information card would lose
  /// it until that poll (#1926).
  factory SystemSnapshot.fromSystemInfo(
    SystemInfoUIModel model, {
    required DateTime timestamp,
  }) =>
      SystemSnapshot(
        timestamp: timestamp,
        cpuPercent: model.cpuPercent,
        memoryPercent: model.memoryPercent,
        totalMemoryKb: model.totalMemory,
        freeMemoryKb: model.freeMemory,
        uptimeSeconds: model.uptime,
        cpuTemperatureCelsius: model.cpuTemperatureCelsius,
      );

  int get usedMemoryKb => totalMemoryKb - freeMemoryKb;

  /// Formatted uptime string (e.g. "2d 5h 30m").
  String get formattedUptime {
    final days = uptimeSeconds ~/ 86400;
    final hours = (uptimeSeconds % 86400) ~/ 3600;
    final minutes = (uptimeSeconds % 3600) ~/ 60;
    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0 || parts.isEmpty) parts.add('${minutes}m');
    return parts.join(' ');
  }

  @override
  List<Object?> get props => [
        timestamp,
        cpuPercent,
        memoryPercent,
        totalMemoryKb,
        freeMemoryKb,
        uptimeSeconds,
        cpuTemperatureCelsius,
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
