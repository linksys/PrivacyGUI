import 'package:equatable/equatable.dart';

class BTDiscoveryData extends Equatable {
  final String name;
  final String macAddress;
  final int rssi;
  final String? modeLimit;

  @override
  List<Object?> get props => [name, macAddress, rssi, modeLimit];

  const BTDiscoveryData({
    required this.name,
    required this.macAddress,
    required this.rssi,
    this.modeLimit,
  });

  BTDiscoveryData copyWith({
    String? name,
    String? macAddress,
    int? rssi,
    String? modeLimit,
  }) {
    return BTDiscoveryData(
      name: name ?? this.name,
      macAddress: macAddress ?? this.macAddress,
      rssi: rssi ?? this.rssi,
      modeLimit: modeLimit ?? this.modeLimit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'macAddress': macAddress,
      'rssi': rssi,
      'modeLimit': modeLimit,
    }..removeWhere((key, value) => value == null);
  }

  factory BTDiscoveryData.fromJson(Map<String, dynamic> json) {
    return BTDiscoveryData(
      name: json['name'],
      macAddress: json['macAddress'],
      rssi: json['rssi'],
      modeLimit: json['modeLimit'],
    );
  }
}
