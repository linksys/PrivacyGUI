import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/_shared/utils/usp_formatters.dart';

/// Presentation Layer Model for a firmware image partition.
class FirmwareImageUIModel extends Equatable with DiagnosticLoggable {
  final String instancePath;
  final String name;
  final String version;
  final String status;
  final bool available;
  final bool isActive;
  final bool isBootTarget;

  const FirmwareImageUIModel({
    required this.instancePath,
    required this.name,
    required this.version,
    required this.status,
    required this.available,
    this.isActive = false,
    this.isBootTarget = false,
  });

  @override
  String get diagnosticName => 'FirmwareImageUIModel';

  @override
  Map<String, Object?> get namedProps => {
        'instancePath': instancePath,
        'name': name,
        'version': version,
        'status': status,
        'available': available,
        'isActive': isActive,
        'isBootTarget': isBootTarget,
      };
}

/// Presentation Layer Model for router system information.
class SystemInfoUIModel extends Equatable with DiagnosticLoggable {
  final String manufacturer;
  final String modelName;
  final String serialNumber;
  final String hardwareVersion;
  final String softwareVersion;
  final int uptime;
  final int totalMemory;
  final int freeMemory;
  final int cpuUsage;
  final List<FirmwareImageUIModel> firmwareImages;

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
    this.firmwareImages = const [],
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

  /// Human-readable total memory (e.g. "512 MB").
  String get formattedTotalMemory =>
      UspFormatters.formatBytes(totalMemory * 1024);

  /// Human-readable free memory (e.g. "256 MB").
  String get formattedFreeMemory =>
      UspFormatters.formatBytes(freeMemory * 1024);

  /// Human-readable used memory (e.g. "256 MB").
  String get formattedUsedMemory =>
      UspFormatters.formatBytes(memoryUsedKb * 1024);

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
  String get diagnosticName => 'SystemInfoUIModel';

  @override
  Map<String, Object?> get namedProps => {
        'manufacturer': manufacturer,
        'modelName': modelName,
        'serialNumber': serialNumber,
        'hardwareVersion': hardwareVersion,
        'softwareVersion': softwareVersion,
        'uptime': uptime,
        'totalMemory': totalMemory,
        'freeMemory': freeMemory,
        'cpuUsage': cpuUsage,
        'firmwareImages': firmwareImages,
      };
}
