import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/providers/feature_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

class DHCPReservationsSettings extends Equatable {
  final List<ReservedListItem> reservations;

  const DHCPReservationsSettings({
    this.reservations = const [],
  });

  @override
  List<Object> get props => [reservations];

  DHCPReservationsSettings copyWith({
    List<ReservedListItem>? reservations,
  }) {
    return DHCPReservationsSettings(
      reservations: reservations ?? this.reservations,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reservations': reservations.map((x) => x.toMap()).toList(),
    };
  }

  factory DHCPReservationsSettings.fromMap(Map<String, dynamic> map) {
    return DHCPReservationsSettings(
      reservations: List<ReservedListItem>.from(
          map['reservations']?.map((x) => ReservedListItem.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory DHCPReservationsSettings.fromJson(String source) =>
      DHCPReservationsSettings.fromMap(json.decode(source));
}

class DHCPReservationsStatus extends Equatable {
  final List<ReservedListItem> additionalReservations;
  final List<ReservedListItem> devices;

  const DHCPReservationsStatus({
    this.additionalReservations = const [],
    this.devices = const [],
  });

  @override
  List<Object> get props => [additionalReservations, devices];

  DHCPReservationsStatus copyWith({
    List<ReservedListItem>? additionalReservations,
    List<ReservedListItem>? devices,
  }) {
    return DHCPReservationsStatus(
      additionalReservations:
          additionalReservations ?? this.additionalReservations,
      devices: devices ?? this.devices,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'additionalReservations':
          additionalReservations.map((x) => x.toMap()).toList(),
      'devices': devices.map((x) => x.toMap()).toList(),
    };
  }

  factory DHCPReservationsStatus.fromMap(Map<String, dynamic> map) {
    return DHCPReservationsStatus(
      additionalReservations: List<ReservedListItem>.from(
          map['additionalReservations']
              ?.map((x) => ReservedListItem.fromMap(x))),
      devices: List<ReservedListItem>.from(
          map['devices']?.map((x) => ReservedListItem.fromMap(x))),
    );
  }

  String toJson() => json.encode(toMap());

  factory DHCPReservationsStatus.fromJson(String source) =>
      DHCPReservationsStatus.fromMap(json.decode(source));
}

class DHCPReservationState
    extends FeatureState<DHCPReservationsSettings, DHCPReservationsStatus> {
  const DHCPReservationState({
    required super.settings,
    required super.status,
  });

  factory DHCPReservationState.init() {
    return DHCPReservationState(
      settings: Preservable(
        original: const DHCPReservationsSettings(),
        current: const DHCPReservationsSettings(),
      ),
      status: const DHCPReservationsStatus(),
    );
  }

  @override
  DHCPReservationState copyWith({
    Preservable<DHCPReservationsSettings>? settings,
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
      'settings': settings.toMap((value) => value.toMap()),
      'status': status.toMap(),
    };
  }

  factory DHCPReservationState.fromMap(Map<String, dynamic> map) {
    return DHCPReservationState(
      settings: Preservable.fromMap(
          map['settings'],
          (dynamic json) =>
              DHCPReservationsSettings.fromMap(json as Map<String, dynamic>)),
      status:
          DHCPReservationsStatus.fromMap(map['status'] as Map<String, dynamic>),
    );
  }

  String toJson() => json.encode(toMap());

  factory DHCPReservationState.fromJson(String source) =>
      DHCPReservationState.fromMap(json.decode(source));

  @override
  List<Object> get props => [settings, status];
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
