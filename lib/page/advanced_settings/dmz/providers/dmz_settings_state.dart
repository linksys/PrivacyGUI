// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:privacy_gui/core/jnap/models/dmz_settings.dart';
import 'package:privacy_gui/providers/empty_status.dart';
import 'package:privacy_gui/providers/feature_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

class DMZSettingsState extends FeatureState<DMZSettings, EmptyStatus> {
  const DMZSettingsState({
    required super.settings,
    required super.status,
  });

  @override
  DMZSettingsState copyWith({
    Preservable<DMZSettings>? settings,
    EmptyStatus? status,
  }) {
    return DMZSettingsState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'settings': settings.toMap((value) => value.toMap()),
      'status': {},
    };
  }

  factory DMZSettingsState.fromMap(Map<String, dynamic> map) {
    return DMZSettingsState(
      settings: Preservable<DMZSettings>.fromMap(
          map['settings'], (m) => DMZSettings.fromMap(m as Map<String, dynamic>)),
      status: const EmptyStatus(),
    );
  }

  factory DMZSettingsState.fromJson(String source) =>
      DMZSettingsState.fromMap(json.decode(source) as Map<String, dynamic>);
}
