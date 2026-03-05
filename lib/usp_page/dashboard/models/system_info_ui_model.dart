import 'package:equatable/equatable.dart';

/// Presentation Layer Model for router system information.
class SystemInfoUIModel extends Equatable {
  final String manufacturer;
  final String modelName;
  final String serialNumber;
  final String hardwareVersion;
  final String softwareVersion;
  final int uptime;
  final int totalMemory;
  final int freeMemory;
  final int cpuUsage;

  const SystemInfoUIModel({
    required this.manufacturer,
    required this.modelName,
    required this.serialNumber,
    required this.hardwareVersion,
    required this.softwareVersion,
    required this.uptime,
    required this.totalMemory,
    required this.freeMemory,
    required this.cpuUsage,
  });

  /// Display name for the gateway (router model or fallback).
  String get gatewayName => modelName.isNotEmpty ? modelName : 'Router';

  /// CPU usage clamped to 0–100.
  int get cpuPercent => cpuUsage.clamp(0, 100);

  /// Memory used in KB.
  int get memoryUsedKb => (totalMemory - freeMemory).clamp(0, totalMemory);

  /// Memory usage percentage.
  int get memoryPercent =>
      totalMemory > 0 ? (memoryUsedKb / totalMemory * 100).round() : 0;

  /// Formatted uptime string (e.g. "2d 5h 30m").
  String get formattedUptime {
    final days = uptime ~/ 86400;
    final hours = (uptime % 86400) ~/ 3600;
    final minutes = (uptime % 3600) ~/ 60;
    if (days > 0) return '${days}d ${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  @override
  List<Object?> get props => [
        manufacturer,
        modelName,
        serialNumber,
        hardwareVersion,
        softwareVersion,
        uptime,
        totalMemory,
        freeMemory,
        cpuUsage,
      ];
}
