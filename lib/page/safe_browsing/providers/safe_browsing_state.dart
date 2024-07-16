// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/lan_settings.dart';

enum SafeBrowsingType {
  off,
  fortinet,
  openDNS,
  ;

  static SafeBrowsingType reslove(String value) =>
      SafeBrowsingType.values
          .firstWhereOrNull((element) => element.name == value) ??
      SafeBrowsingType.off;
}

class SafeBrowsingState extends Equatable {
  final RouterLANSettings? lanSetting;
  final SafeBrowsingType safeBrowsingType;
  final bool hasFortinet;

  const SafeBrowsingState({
    this.lanSetting,
    this.safeBrowsingType = SafeBrowsingType.off,
    this.hasFortinet = false,
  });

  SafeBrowsingState copyWith({
    RouterLANSettings? lanSetting,
    SafeBrowsingType? safeBrowsingType,
    bool? hasFortinet,
  }) {
    return SafeBrowsingState(
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

  factory SafeBrowsingState.fromMap(Map<String, dynamic> map) {
    return SafeBrowsingState(
      lanSetting: map['lanSetting'] != null
          ? RouterLANSettings.fromMap(map['lanSetting'] as Map<String, dynamic>)
          : null,
      safeBrowsingType: map['safeBrowsingType'] != null
          ? SafeBrowsingType.reslove(map['safeBrowsingType'])
          : SafeBrowsingType.off,
      hasFortinet: map['hasFortinet'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory SafeBrowsingState.fromJson(String source) =>
      SafeBrowsingState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
