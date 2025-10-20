import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/providers/feature_state.dart';

class DHCPReservationsSettings extends Equatable {
  final List<ReservedListItem> reservations;
  final List<ReservedListItem> additionalReservations;

  const DHCPReservationsSettings({
    required this.reservations,
    required this.additionalReservations,
  });

  @override
  List<Object> get props => [reservations, additionalReservations];

  DHCPReservationsSettings copyWith({
    List<ReservedListItem>? reservations,
    List<ReservedListItem>? additionalReservations,
  }) {
    return DHCPReservationsSettings(
      reservations: reservations ?? this.reservations,
      additionalReservations:
          additionalReservations ?? this.additionalReservations,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reservations': reservations.map((x) => x.toMap()).toList(),
      'additionalReservations':
          additionalReservations.map((x) => x.toMap()).toList(),
    };
  }
}

class DHCPReservationsStatus extends Equatable {
  final List<ReservedListItem> devices;

  const DHCPReservationsStatus({required this.devices});

  @override
  List<Object> get props => [devices];

  Map<String, dynamic> toMap() {
    return {
      'devices': devices.map((x) => x.toMap()).toList(),
    };
  }
}

class DHCPReservationState
    extends FeatureState<DHCPReservationsSettings, DHCPReservationsStatus> {
  const DHCPReservationState({
    required super.settings,
    required super.status,
  });

  @override
  DHCPReservationState copyWith({
    DHCPReservationsSettings? settings,
    DHCPReservationsStatus? status,
  }) {
    return DHCPReservationState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'settings': settings.toMap(),
      'status': status.toMap(),
    };
  }
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
