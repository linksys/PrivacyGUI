// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/lan_settings.dart';

enum InstantSafetyType {
  off,
  fortinet,
  openDNS,
  ;

  static InstantSafetyType reslove(String value) =>
      InstantSafetyType.values
          .firstWhereOrNull((element) => element.name == value) ??
      InstantSafetyType.off;
}

class InstantSafetyState extends Equatable {
  final RouterLANSettings? lanSetting;
  final InstantSafetyType safeBrowsingType;
  final bool hasFortinet;

  const InstantSafetyState({
    this.lanSetting,
    this.safeBrowsingType = InstantSafetyType.off,
    this.hasFortinet = false,
  });

  InstantSafetyState copyWith({
    RouterLANSettings? lanSetting,
    InstantSafetyType? safeBrowsingType,
    bool? hasFortinet,
  }) {
    return InstantSafetyState(
      lanSetting: lanSetting ?? this.lanSetting,
      safeBrowsingType: safeBrowsingType ?? this.safeBrowsingType,
      hasFortinet: hasFortinet ?? this.hasFortinet,
    );
  }

  @override
  List<Object?> get props => [lanSetting, safeBrowsingType, hasFortinet];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'lanSetting': lanSetting?.toMap(),
      'safeBrowsingType': safeBrowsingType.name,
      'hasFortinet': hasFortinet,
    };
  }

  factory InstantSafetyState.fromMap(Map<String, dynamic> map) {
    return InstantSafetyState(
      lanSetting: map['lanSetting'] != null
          ? RouterLANSettings.fromMap(map['lanSetting'] as Map<String, dynamic>)
          : null,
      safeBrowsingType: map['safeBrowsingType'] != null
          ? InstantSafetyType.reslove(map['safeBrowsingType'])
          : InstantSafetyType.off,
      hasFortinet: map['hasFortinet'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory InstantSafetyState.fromJson(String source) =>
      InstantSafetyState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
