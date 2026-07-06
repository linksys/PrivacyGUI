import 'package:equatable/equatable.dart';

/// Presentation Layer Model for a DHCP reservation.
///
/// [instancePath] is `null` for newly created (local-only) reservations
/// that have not yet been saved to the device.
class DhcpReservationUIModel extends Equatable {
  final String? instancePath;

  /// MAC address (normalized to uppercase).
  final String mac;
  final String ip;
  final bool enable;

  /// Creates a DHCP reservation UI model. MAC is normalized to uppercase.
  DhcpReservationUIModel({
    this.instancePath,
    required String mac,
    required this.ip,
    required this.enable,
  }) : mac = mac.toUpperCase();

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
  List<Object?> get props => [instancePath, mac, ip, enable];
}
