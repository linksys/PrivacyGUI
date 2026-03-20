import 'package:equatable/equatable.dart';

/// How the source IP restriction is configured.
enum DmzSourceType {
  /// No restriction — all source IPs are allowed (0.0.0.0/0 or empty).
  any,

  /// Restrict to a specific CIDR range (e.g. 192.168.1.0/24).
  cidr,
}

/// UI-facing representation of the DMZ configuration.
///
/// The router's TR-181 model is multi-instance (`Device.Firewall.DMZ.{i}.`)
/// but DMZ is practically a single-entry feature: either 0 or 1 entry exists.
/// This model abstracts that into a simple enable/disable + settings view.
class DmzUIModel extends Equatable {
  /// Whether the DMZ entry exists and is enabled.
  final bool isEnabled;

  /// Destination host IP address.
  final String destIp;

  /// Source restriction type.
  final DmzSourceType sourceType;

  /// CIDR string when [sourceType] is [DmzSourceType.cidr].
  final String sourcePrefix;

  const DmzUIModel({
    required this.isEnabled,
    required this.destIp,
    required this.sourceType,
    required this.sourcePrefix,
  });

  /// Default disabled state (no DMZ entry on router).
  const DmzUIModel.disabled()
      : isEnabled = false,
        destIp = '',
        sourceType = DmzSourceType.any,
        sourcePrefix = '';

  DmzUIModel copyWith({
    bool? isEnabled,
    String? destIp,
    DmzSourceType? sourceType,
    String? sourcePrefix,
  }) {
    return DmzUIModel(
      isEnabled: isEnabled ?? this.isEnabled,
      destIp: destIp ?? this.destIp,
      sourceType: sourceType ?? this.sourceType,
      sourcePrefix: sourcePrefix ?? this.sourcePrefix,
    );
  }

  @override
  List<Object?> get props => [isEnabled, destIp, sourceType, sourcePrefix];
}
