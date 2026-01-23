import 'dart:convert';

import 'package:privacy_gui/core/models/privacy_settings.dart';
export 'package:privacy_gui/core/models/privacy_settings.dart';
import 'package:privacy_gui/providers/feature_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

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
