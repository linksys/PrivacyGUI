// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:equatable/equatable.dart';

class MACAddressCloneSettings extends Equatable {
  final bool isMACAddressCloneEnabled;
  final String? macAddress;
  const MACAddressCloneSettings({
    required this.isMACAddressCloneEnabled,
    this.macAddress,
  });

  MACAddressCloneSettings copyWith({
    bool? isMACAddressCloneEnabled,
    String? macAddress,
  }) {
    return MACAddressCloneSettings(
      isMACAddressCloneEnabled:
          isMACAddressCloneEnabled ?? this.isMACAddressCloneEnabled,
      macAddress: macAddress ?? this.macAddress,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'isMACAddressCloneEnabled': isMACAddressCloneEnabled,
      'macAddress': macAddress,
    }..removeWhere((key, value) => value == null);
  }

  factory MACAddressCloneSettings.fromJson(Map<String, dynamic> map) {
    return MACAddressCloneSettings(
      isMACAddressCloneEnabled: map['isMACAddressCloneEnabled'] as bool,
      macAddress:
          map['macAddress'] != null ? map['macAddress'] as String : null,
    );
  }

  @override
  List<Object?> get props => [isMACAddressCloneEnabled, macAddress];
}
