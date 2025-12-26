import 'dart:convert';

import 'package:equatable/equatable.dart';

/// UI Model for DHCP Reservation display and manipulation
///
/// This is the presentation layer model used by both:
/// - DHCPReservationsProvider (reservation management)
/// - LocalNetworkSettingsProvider (LAN settings with reservations)
///
/// Represents a single DHCP reservation with MAC address, IP address, and description.
class DHCPReservationUIModel extends Equatable {
  final String macAddress;
  final String ipAddress;
  final String description;

  const DHCPReservationUIModel({
    required this.macAddress,
    required this.ipAddress,
    required this.description,
  });

  DHCPReservationUIModel copyWith({
    String? macAddress,
    String? ipAddress,
    String? description,
  }) {
    return DHCPReservationUIModel(
      macAddress: macAddress ?? this.macAddress,
      ipAddress: ipAddress ?? this.ipAddress,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'macAddress': macAddress,
      'ipAddress': ipAddress,
      'description': description,
    };
  }

  factory DHCPReservationUIModel.fromMap(Map<String, dynamic> map) {
    return DHCPReservationUIModel(
      macAddress: map['macAddress'] as String,
      ipAddress: map['ipAddress'] as String,
      description: map['description'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory DHCPReservationUIModel.fromJson(String source) =>
      DHCPReservationUIModel.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  List<Object> get props => [macAddress, ipAddress, description];

  @override
  bool get stringify => true;
}
