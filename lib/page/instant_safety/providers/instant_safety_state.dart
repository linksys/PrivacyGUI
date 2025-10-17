import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/providers/feature_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

enum InstantSafetyType {
  off,
  fortinet,
  openDNS,
  ;

  static InstantSafetyType reslove(String value) =>
      InstantSafetyType.values.firstWhere((element) => element.name == value,
          orElse: () => InstantSafetyType.off);
}

class InstantSafetySettings extends Equatable {
  final InstantSafetyType safeBrowsingType;

  const InstantSafetySettings({
    this.safeBrowsingType = InstantSafetyType.off,
  });

  @override
  List<Object?> get props => [safeBrowsingType];

  InstantSafetySettings copyWith({
    InstantSafetyType? safeBrowsingType,
  }) {
    return InstantSafetySettings(
      safeBrowsingType: safeBrowsingType ?? this.safeBrowsingType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'safeBrowsingType': safeBrowsingType.name,
    };
  }
}

class InstantSafetyStatus extends Equatable {
  final RouterLANSettings? lanSetting;
  final bool hasFortinet;

  const InstantSafetyStatus({
    this.lanSetting,
    this.hasFortinet = false,
  });

  @override
  List<Object?> get props => [lanSetting, hasFortinet];

  InstantSafetyStatus copyWith({
    RouterLANSettings? lanSetting,
    bool? hasFortinet,
  }) {
    return InstantSafetyStatus(
      lanSetting: lanSetting ?? this.lanSetting,
      hasFortinet: hasFortinet ?? this.hasFortinet,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lanSetting': lanSetting?.toMap(),
      'hasFortinet': hasFortinet,
    };
  }
}

class InstantSafetyState
    extends FeatureState<InstantSafetySettings, InstantSafetyStatus> {
  const InstantSafetyState({
    required super.settings,
    required super.status,
  });

  factory InstantSafetyState.initial() {
    return const InstantSafetyState(
      settings: Preservable(
        original: InstantSafetySettings(),
        current: InstantSafetySettings(),
      ),
      status: InstantSafetyStatus(),
    );
  }

  InstantSafetyState copyWith({
    Preservable<InstantSafetySettings>? settings,
    InstantSafetyStatus? status,
  }) {
    return InstantSafetyState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  factory InstantSafetyState.fromMap(Map<String, dynamic> map) {
    final settings = InstantSafetySettings(
      safeBrowsingType: map['safeBrowsingType'] != null
          ? InstantSafetyType.reslove(map['safeBrowsingType'])
          : InstantSafetyType.off,
    );

    final status = InstantSafetyStatus(
      lanSetting: map['lanSetting'] != null
          ? RouterLANSettings.fromMap(map['lanSetting'] as Map<String, dynamic>)
          : null,
      hasFortinet: map['hasFortinet'] as bool? ?? false,
    );

    return InstantSafetyState(
      settings: Preservable(original: settings, current: settings),
      status: status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      ...settings.current.toMap(),
      ...status.toMap(),
    };
  }

  String toJson() => json.encode(toMap());

  factory InstantSafetyState.fromJson(String source) =>
      InstantSafetyState.fromMap(json.decode(source));
}
