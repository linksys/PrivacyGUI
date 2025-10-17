import 'dart:convert';

import 'package:equatable/equatable.dart';

class EthernetPortConnectionState extends Equatable {
  final bool isDualWANEnabled;
  final String primaryWAN;
  final String secondaryWAN;
  final List<String> lans;

  const EthernetPortConnectionState({
    this.isDualWANEnabled = false,
    this.primaryWAN = '',
    this.secondaryWAN = '',
    this.lans = const [],
  });

  EthernetPortConnectionState copyWith({
    bool? isDualWANEnabled,
    String? primaryWAN,
    String? secondaryWAN,
    List<String>? lans,
  }) {
    return EthernetPortConnectionState(
      isDualWANEnabled: isDualWANEnabled ?? this.isDualWANEnabled,
      primaryWAN: primaryWAN ?? this.primaryWAN,
      secondaryWAN: secondaryWAN ?? this.secondaryWAN,
      lans: lans ?? this.lans,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isDualWANEnabled': isDualWANEnabled,
      'primaryWAN': primaryWAN,
      'secondaryWAN': secondaryWAN,
      'lans': lans,
    };
  }

  factory EthernetPortConnectionState.fromMap(Map<String, dynamic> map) {
    return EthernetPortConnectionState(
      isDualWANEnabled: map['isDualWANEnabled'] ?? false,
      primaryWAN: map['primaryWAN'] ?? '',
      secondaryWAN: map['secondaryWAN'] ?? '',
      lans: map['lans'] ?? const [],
    );
  }

  String toJson() => json.encode(toMap());

  factory EthernetPortConnectionState.fromJson(String source) =>
      EthernetPortConnectionState.fromMap(json.decode(source));

  @override
  String toString() =>
      'EthernetPortConnectionState(isDualWANEnabled: $isDualWANEnabled, primaryWAN: $primaryWAN, secondaryWAN: $secondaryWAN, lans: $lans)';

  @override
  List<Object?> get props => [isDualWANEnabled, primaryWAN, secondaryWAN, lans];

  bool get hasLanPort => lans.isNotEmpty;
  bool get hasPrimaryWANConnection =>
      primaryWAN.isNotEmpty && primaryWAN != 'None';
  bool get hasSecondaryWANConnection =>
      secondaryWAN.isNotEmpty && secondaryWAN != 'None';
  bool get hasWanConnections =>
      hasPrimaryWANConnection ||
      (isDualWANEnabled && hasSecondaryWANConnection);
}
