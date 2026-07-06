import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';

/// Presentation Layer Model for a DHCP reservation.
///
/// [instancePath] is `null` for newly created (local-only) reservations
/// that have not yet been saved to the device.
class DhcpReservationUIModel extends Equatable with DiagnosticLoggable {
  final String? instancePath;
  final String mac;
  final String ip;
  final bool enable;

  const DhcpReservationUIModel({
    this.instancePath,
    required this.mac,
    required this.ip,
    required this.enable,
  });

  DhcpReservationUIModel copyWith({
    String? instancePath,
    String? mac,
    String? ip,
    bool? enable,
  }) {
    return DhcpReservationUIModel(
      instancePath: instancePath ?? this.instancePath,
      mac: mac ?? this.mac,
      ip: ip ?? this.ip,
      enable: enable ?? this.enable,
    );
  }

  @override
  Map<String, Object?> get namedProps => {
        'instancePath': instancePath,
        'mac': mac,
        'ip': ip,
        'enable': enable,
      };
}
