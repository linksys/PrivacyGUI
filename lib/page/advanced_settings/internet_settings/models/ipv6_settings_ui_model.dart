import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';

class Ipv6SettingsUIModel extends Equatable {
  final String ipv6ConnectionType;
  final bool isIPv6AutomaticEnabled;
  final IPv6rdTunnelMode? ipv6rdTunnelMode;
  final String? ipv6Prefix;
  final int? ipv6PrefixLength;
  final String? ipv6BorderRelay;
  final int? ipv6BorderRelayPrefixLength;

  const Ipv6SettingsUIModel({
    required this.ipv6ConnectionType,
    required this.isIPv6AutomaticEnabled,
    this.ipv6rdTunnelMode,
    this.ipv6Prefix,
    this.ipv6PrefixLength,
    this.ipv6BorderRelay,
    this.ipv6BorderRelayPrefixLength,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ipv6ConnectionType': ipv6ConnectionType,
      'isIPv6AutomaticEnabled': isIPv6AutomaticEnabled,
      'ipv6rdTunnelMode': ipv6rdTunnelMode?.value,
      'ipv6Prefix': ipv6Prefix,
      'ipv6PrefixLength': ipv6PrefixLength,
      'ipv6BorderRelay': ipv6BorderRelay,
      'ipv6BorderRelayPrefixLength': ipv6BorderRelayPrefixLength,
    }..removeWhere((key, value) => value == null);
  }

  factory Ipv6SettingsUIModel.fromMap(Map<String, dynamic> map) {
    return Ipv6SettingsUIModel(
      ipv6ConnectionType: map['ipv6ConnectionType'] as String,
      isIPv6AutomaticEnabled: map['isIPv6AutomaticEnabled'] as bool,
      ipv6rdTunnelMode: map['ipv6rdTunnelMode'] != null
          ? IPv6rdTunnelMode.resolve(map['ipv6rdTunnelMode'])
          : null,
      ipv6Prefix:
          map['ipv6Prefix'] != null ? map['ipv6Prefix'] as String : null,
      ipv6PrefixLength: map['ipv6PrefixLength'] != null
          ? map['ipv6PrefixLength'] as int
          : null,
      ipv6BorderRelay: map['ipv6BorderRelay'] != null
          ? map['ipv6BorderRelay'] as String
          : null,
      ipv6BorderRelayPrefixLength: map['ipv6BorderRelayPrefixLength'] != null
          ? map['ipv6BorderRelayPrefixLength'] as int
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Ipv6SettingsUIModel.fromJson(String source) =>
      Ipv6SettingsUIModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props {
    return [
      ipv6ConnectionType,
      isIPv6AutomaticEnabled,
      ipv6rdTunnelMode,
      ipv6Prefix,
      ipv6PrefixLength,
      ipv6BorderRelay,
      ipv6BorderRelayPrefixLength,
    ];
  }

  Ipv6SettingsUIModel copyWith({
    String? ipv6ConnectionType,
    bool? isIPv6AutomaticEnabled,
    ValueGetter<IPv6rdTunnelMode?>? ipv6rdTunnelMode,
    ValueGetter<String?>? ipv6Prefix,
    ValueGetter<int?>? ipv6PrefixLength,
    ValueGetter<String?>? ipv6BorderRelay,
    ValueGetter<int?>? ipv6BorderRelayPrefixLength,
  }) {
    return Ipv6SettingsUIModel(
      ipv6ConnectionType: ipv6ConnectionType ?? this.ipv6ConnectionType,
      isIPv6AutomaticEnabled:
          isIPv6AutomaticEnabled ?? this.isIPv6AutomaticEnabled,
      ipv6rdTunnelMode:
          ipv6rdTunnelMode != null ? ipv6rdTunnelMode() : this.ipv6rdTunnelMode,
      ipv6Prefix: ipv6Prefix != null ? ipv6Prefix() : this.ipv6Prefix,
      ipv6PrefixLength:
          ipv6PrefixLength != null ? ipv6PrefixLength() : this.ipv6PrefixLength,
      ipv6BorderRelay:
          ipv6BorderRelay != null ? ipv6BorderRelay() : this.ipv6BorderRelay,
      ipv6BorderRelayPrefixLength: ipv6BorderRelayPrefixLength != null
          ? ipv6BorderRelayPrefixLength()
          : this.ipv6BorderRelayPrefixLength,
    );
  }
}
