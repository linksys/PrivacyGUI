// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/jnap/models/wan_settings.dart';

// http://linksys.com/jnap/router/DualWanMode
enum DualWANModeData {
  failOver('Fail Over'),
  loadBalanced('Load Balanced');

  final String value;
  const DualWANModeData(this.value);

  static DualWANModeData fromJson(String json) =>
      values.firstWhere((e) => e.value == json);
}

// http://linksys.com/jnap/router/DualWanRatio
enum DualWANRatioData {
  oneToOne('1-1'),
  fourToOne('4-1');

  final String value;
  const DualWANRatioData(this.value);

  static DualWANRatioData fromJson(String json) =>
      values.firstWhere((e) => e.value == json);
}

// http://linksys.com/jnap/router/PrimaryWANSettings
// Naming as DualWANSettings to avoid confusion with WANSettings
class DualWANSettingsData extends Equatable {
  final String wanType;
  final PPPoESettings? pppoeSettings; // only present if wanType is PPPoE
  final TPSettings? tpSettings; // only present if wanType is PPTP or L2TP
  final StaticSettings? staticSettings; // only present if wanType is Static
  final int mtu;

  const DualWANSettingsData({
    required this.wanType,
    this.pppoeSettings,
    this.tpSettings,
    this.staticSettings,
    required this.mtu,
  });

  @override
  List<Object?> get props => [
        wanType,
        pppoeSettings,
        tpSettings,
        staticSettings,
        mtu,
      ];

  factory DualWANSettingsData.fromMap(Map<String, dynamic> map) {
    final wanType = map['wanType'] as String;
    return DualWANSettingsData(
      wanType: wanType,
      pppoeSettings: map['pppoeSettings'] != null
          ? PPPoESettings.fromMap(map['pppoeSettings'] as Map<String, dynamic>)
          : null,
      tpSettings: map['tpSettings'] != null
          ? TPSettings.fromMap(map['tpSettings'] as Map<String, dynamic>)
          : null,
      staticSettings: map['staticSettings'] != null
          ? StaticSettings.fromMap(
              map['staticSettings'] as Map<String, dynamic>)
          : null,
      mtu: map['mtu'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'wanType': wanType,
      if (pppoeSettings != null) 'pppoeSettings': pppoeSettings!.toMap(),
      if (tpSettings != null) 'tpSettings': tpSettings!.toMap(),
      if (staticSettings != null) 'staticSettings': staticSettings!.toMap(),
      'mtu': mtu,
    };
  }

  factory DualWANSettingsData.fromJson(Map<String, dynamic> json) =>
      DualWANSettingsData.fromMap(json);

  Map<String, dynamic> toJson() => toMap();
}

/// Dual WAN Settings
/// "enabled": false,
/// "mode": "Fail Over",
/// "ratio": "4-1",
/// "primaryWanSettings": {
///   "wanType": "DHCP"
/// },
/// "secondaryWanSettings": {
///   "wanType": "DHCP"
/// }
///
class RouterDualWANSettings extends Equatable {
  final bool enabled;
  final DualWANModeData mode;
  final DualWANRatioData? ratio;
  final DualWANSettingsData primaryWAN;
  final DualWANSettingsData secondaryWAN;
  const RouterDualWANSettings({
    required this.enabled,
    required this.mode,
    this.ratio,
    required this.primaryWAN,
    required this.secondaryWAN,
  });

  RouterDualWANSettings copyWith({
    bool? enabled,
    DualWANModeData? mode,
    DualWANRatioData? ratio,
    DualWANSettingsData? primaryWAN,
    DualWANSettingsData? secondaryWAN,
  }) {
    return RouterDualWANSettings(
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      ratio: ratio ?? this.ratio,
      primaryWAN: primaryWAN ?? this.primaryWAN,
      secondaryWAN: secondaryWAN ?? this.secondaryWAN,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'enabled': enabled,
      'mode': mode.value,
      'ratio': ratio?.value,
      'primaryWanSettings': primaryWAN.toMap(),
      'secondaryWanSettings': secondaryWAN.toMap(),
    }..removeWhere((key, value) => value == null);
  }

  factory RouterDualWANSettings.fromMap(Map<String, dynamic> map) {
    return RouterDualWANSettings(
      enabled: map['enabled'] as bool,
      mode: DualWANModeData.fromJson(map['mode'] as String),
      ratio: map['ratio'] != null
          ? DualWANRatioData.fromJson(map['ratio'] as String)
          : null,
      primaryWAN: DualWANSettingsData.fromMap(
          map['primaryWanSettings'] as Map<String, dynamic>),
      secondaryWAN: DualWANSettingsData.fromMap(
          map['secondaryWanSettings'] as Map<String, dynamic>),
    );
  }

  String toJson() => json.encode(toMap());

  factory RouterDualWANSettings.fromJson(String source) =>
      RouterDualWANSettings.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [enabled, mode, ratio, primaryWAN, secondaryWAN];
}
