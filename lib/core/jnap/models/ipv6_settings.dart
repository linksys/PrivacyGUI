// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/ipv6_automatic_settings.dart';

class GetIPv6Settings extends Equatable {
  final String? wanType;
  final IPv6AutomaticSettings? ipv6AutomaticSettings;
  final String duid;

  const GetIPv6Settings({
    this.wanType,
    this.ipv6AutomaticSettings,
    required this.duid,
  });

  @override
  List<Object?> get props => [wanType, ipv6AutomaticSettings, duid];

  GetIPv6Settings copyWith({
    String? wanType,
    IPv6AutomaticSettings? ipv6AutomaticSettings,
    String? duid,
  }) {
    return GetIPv6Settings(
      wanType: wanType ?? this.wanType,
      ipv6AutomaticSettings:
          ipv6AutomaticSettings ?? this.ipv6AutomaticSettings,
      duid: duid ?? this.duid,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'wanType': wanType,
      'ipv6AutomaticSettings': ipv6AutomaticSettings?.toJson(),
      'duid': duid,
    }..removeWhere((key, value) => value == null);
  }

  factory GetIPv6Settings.fromJson(Map<String, dynamic> map) {
    return GetIPv6Settings(
      wanType: map['wanType'] as String?,
      ipv6AutomaticSettings: map['ipv6AutomaticSettings'] != null
          ? IPv6AutomaticSettings.fromJson(
              map['ipv6AutomaticSettings'] as Map<String, dynamic>)
          : null,
      duid: map['duid'] as String,
    );
  }
}

class SetIPv6Settings extends Equatable {
  final String wanType;
  final IPv6AutomaticSettings? ipv6AutomaticSettings;

  const SetIPv6Settings({
    required this.wanType,
    this.ipv6AutomaticSettings,
  });

  @override
  List<Object?> get props => [wanType, ipv6AutomaticSettings];

  SetIPv6Settings copyWith({
    String? wanType,
    IPv6AutomaticSettings? ipv6AutomaticSettings,
    String? duid,
  }) {
    return SetIPv6Settings(
      wanType: wanType ?? this.wanType,
      ipv6AutomaticSettings:
          ipv6AutomaticSettings ?? this.ipv6AutomaticSettings,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'wanType': wanType,
      'ipv6AutomaticSettings': ipv6AutomaticSettings?.toJson(),
    }..removeWhere((key, value) => value == null);
  }

  factory SetIPv6Settings.fromJson(Map<String, dynamic> map) {
    return SetIPv6Settings(
      wanType: map['wanType'] as String,
      ipv6AutomaticSettings: map['ipv6AutomaticSettings'] != null
          ? IPv6AutomaticSettings.fromJson(
              map['ipv6AutomaticSettings'] as Map<String, dynamic>)
          : null,
    );
  }
}
