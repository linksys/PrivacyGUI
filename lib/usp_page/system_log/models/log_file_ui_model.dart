import 'package:equatable/equatable.dart';
import 'package:privacy_gui/generated/transforms.g.dart';

/// Presentation Layer Model for a single vendor log file.
///
/// Naming follows constitution Section 3.3.4 (class name ends with `UIModel`).
class LogFileUIModel extends Equatable {
  final String instancePath;
  final String name;
  final int maximumSize; // bytes
  final bool persistent;

  const LogFileUIModel({
    required this.instancePath,
    required this.name,
    required this.maximumSize,
    required this.persistent,
  });

  /// Human-readable file size, e.g. "512 KB". Returns "Unknown" if 0.
  String get formattedSize =>
      maximumSize > 0 ? Transforms.formatBytes(maximumSize) : 'Unknown';

  @override
  List<Object?> get props => [instancePath, name, maximumSize, persistent];
}
