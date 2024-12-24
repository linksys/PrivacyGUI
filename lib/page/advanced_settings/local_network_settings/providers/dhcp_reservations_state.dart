import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/lan_settings.dart';

class DHCPReservationState extends Equatable {
  final List<ReservedListItem> reservations;
  final List<ReservedListItem> additionalReservations;
  final List<ReservedListItem> devices;
  const DHCPReservationState({
    required this.reservations,
    required this.additionalReservations,
    required this.devices,
  });

  DHCPReservationState copyWith({
    List<ReservedListItem>? reservations,
    List<ReservedListItem>? additionalReservations,
    List<ReservedListItem>? devices,
  }) {
    return DHCPReservationState(
      reservations: reservations ?? this.reservations,
      additionalReservations:
          additionalReservations ?? this.additionalReservations,
      devices: devices ?? this.devices,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reservations': reservations.map((x) => x.toMap()).toList(),
      'additionalReservations':
          additionalReservations.map((x) => x.toMap()).toList(),
      'devices': devices.map((x) => x.toMap()).toList(),
    };
  }

  factory DHCPReservationState.fromMap(Map<String, dynamic> map) {
    return DHCPReservationState(
      reservations: List<ReservedListItem>.from(
          map['reservations']?.map((x) => ReservedListItem.fromMap(x))),
      additionalReservations: List<ReservedListItem>.from(
          map['additionalReservations']
              ?.map((x) => ReservedListItem.fromMap(x))),
      devices: List<ReservedListItem>.from(
          map['devices']?.map((x) => ReservedListItem.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory DHCPReservationState.fromJson(String source) =>
      DHCPReservationState.fromMap(json.decode(source));

  @override
  String toString() =>
      'DHCPReservationState(reservations: $reservations, additionalReservations: $additionalReservations, devices: $devices)';

  @override
  List<Object> get props => [reservations, additionalReservations, devices];
}

class ReservedListItem extends Equatable {
  final bool reserved;
  final DHCPReservation data;
  const ReservedListItem({
    required this.reserved,
    required this.data,
  });

  ReservedListItem copyWith({
    bool? reserved,
    DHCPReservation? data,
  }) {
    return ReservedListItem(
      reserved: reserved ?? this.reserved,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reserved': reserved,
      'data': data.toMap(),
    };
  }

  factory ReservedListItem.fromMap(Map<String, dynamic> map) {
    return ReservedListItem(
      reserved: map['reserved'] ?? false,
      data: DHCPReservation.fromMap(map['data']),
    );
  }

  String toJson() => json.encode(toMap());

  factory ReservedListItem.fromJson(String source) =>
      ReservedListItem.fromMap(json.decode(source));

  @override
  String toString() => 'ReservedListItem(reserved: $reserved, data: $data)';

  @override
  List<Object> get props => [reserved, data];
}
