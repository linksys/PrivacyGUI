// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

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

  @override
  List<Object?> get props => [isMACAddressCloneEnabled, macAddress];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isMACAddressCloneEnabled': isMACAddressCloneEnabled,
      'macAddress': macAddress,
    }..removeWhere((key, value) => value == null);
  }

  factory MACAddressCloneSettings.fromMap(Map<String, dynamic> map) {
    return MACAddressCloneSettings(
      isMACAddressCloneEnabled: map['isMACAddressCloneEnabled'] as bool,
      macAddress:
          map['macAddress'] != null ? map['macAddress'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory MACAddressCloneSettings.fromJson(String source) =>
      MACAddressCloneSettings.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
