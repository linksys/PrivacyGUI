import 'package:equatable/equatable.dart';

/// Presentation Layer Model for a DHCP reservation.
class DhcpReservationUIModel extends Equatable {
  final String instancePath; // For toggle/delete mutations
  final String mac;
  final String ip;
  final bool enable;

  const DhcpReservationUIModel({
    required this.instancePath,
    required this.mac,
    required this.ip,
    required this.enable,
  });

  @override
  List<Object?> get props => [instancePath, mac, ip, enable];
}
