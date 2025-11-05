import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/providers/feature_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

enum MacFilterMode {
  disabled,
  allow,
  deny,
  ;

  static MacFilterMode reslove(String value) => switch (value.toLowerCase()) {
        'disabled' => MacFilterMode.disabled,
        'allow' => MacFilterMode.allow,
        'deny' => MacFilterMode.deny,
        _ => MacFilterMode.disabled,
      };
}

class InstantPrivacyStatus extends Equatable {
  final MacFilterMode mode;

  const InstantPrivacyStatus({required this.mode});

  factory InstantPrivacyStatus.init() {
    return const InstantPrivacyStatus(mode: MacFilterMode.disabled);
  }

  @override
  List<Object?> get props => [mode];

  InstantPrivacyStatus copyWith({MacFilterMode? mode}) {
    return InstantPrivacyStatus(mode: mode ?? this.mode);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'mode': mode.name,
    };
  }

  factory InstantPrivacyStatus.fromMap(Map<String, dynamic> map) {
    return InstantPrivacyStatus(
      mode: MacFilterMode.reslove(map['mode']),
    );
  }

  String toJson() => json.encode(toMap());

  factory InstantPrivacyStatus.fromJson(String source) =>
      InstantPrivacyStatus.fromMap(json.decode(source) as Map<String, dynamic>);
}

class InstantPrivacySettings extends Equatable {
  final MacFilterMode mode;
  final List<String> macAddresses;
  final List<String> denyMacAddresses;
  final int maxMacAddresses;
  final List<String> bssids;
  final String? myMac;

  @override
  List<Object?> get props => [
        mode,
        macAddresses,
        denyMacAddresses,
        maxMacAddresses,
        bssids,
        myMac,
      ];

  const InstantPrivacySettings({
    required this.mode,
    required this.macAddresses,
    required this.denyMacAddresses,
    required this.maxMacAddresses,
    this.bssids = const [],
    this.myMac,
  });

  factory InstantPrivacySettings.init() {
    return const InstantPrivacySettings(
      mode: MacFilterMode.disabled,
      macAddresses: [],
      denyMacAddresses: [],
      maxMacAddresses: 32,
    );
  }

  InstantPrivacySettings copyWith({
    MacFilterMode? mode,
    List<String>? macAddresses,
    List<String>? denyMacAddresses,
    int? maxMacAddresses,
    List<String>? bssids,
    String? myMac,
  }) {
    return InstantPrivacySettings(
      mode: mode ?? this.mode,
      macAddresses: macAddresses ?? this.macAddresses,
      denyMacAddresses: denyMacAddresses ?? this.denyMacAddresses,
      maxMacAddresses: maxMacAddresses ?? this.maxMacAddresses,
      bssids: bssids ?? this.bssids,
      myMac: myMac ?? this.myMac,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'mode': mode.name,
      'macAddresses': macAddresses,
      'denyMacAddresses': denyMacAddresses,
      'maxMacAddresses': maxMacAddresses,
      'bssids': bssids,
      'myMac': myMac,
    }..removeWhere((key, value) => value == null);
  }

  factory InstantPrivacySettings.fromMap(Map<String, dynamic> map) {
    return InstantPrivacySettings(
      mode: MacFilterMode.reslove(map['mode']),
      macAddresses: List.from(map['macAddresses']),
      denyMacAddresses: List.from(map['denyMacAddresses']),
      maxMacAddresses: map['maxMacAddresses'] as int,
      bssids: map['bssids'] == null ? [] : List.from(map['bssids']),
      myMac: map['myMac'],
    );
  }

  String toJson() => json.encode(toMap());

  factory InstantPrivacySettings.fromJson(String source) =>
      InstantPrivacySettings.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}

class InstantPrivacyState
    extends FeatureState<InstantPrivacySettings, InstantPrivacyStatus> {
  const InstantPrivacyState({
    required super.settings,
    required super.status,
  });

  factory InstantPrivacyState.init() {
    return InstantPrivacyState(
      settings: Preservable(
          original: InstantPrivacySettings.init(),
          current: InstantPrivacySettings.init()),
      status: InstantPrivacyStatus.init(),
    );
  }

  @override
  InstantPrivacyState copyWith({
    Preservable<InstantPrivacySettings>? settings,
    InstantPrivacyStatus? status,
  }) {
    return InstantPrivacyState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'status': status.mode.name,
      'settings': settings.toMap((s) => s.toMap()),
    };
  }

  factory InstantPrivacyState.fromMap(Map<String, dynamic> map) {
    return InstantPrivacyState(
      status: InstantPrivacyStatus.fromMap(map['status']),
      settings: Preservable.fromMap(
          map['settings'],
          (data) =>
              InstantPrivacySettings.fromMap(data as Map<String, dynamic>)),
    );
  }

  @override
  String toJson() => json.encode(toMap());

  factory InstantPrivacyState.fromJson(String source) =>
      InstantPrivacyState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
