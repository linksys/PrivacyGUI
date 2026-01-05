import 'dart:convert';

import 'package:privacy_gui/page/advanced_settings/internet_settings/models/_models.dart';
import 'package:privacy_gui/providers/feature_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

// Export type aliases for backward compatibility
export 'package:privacy_gui/page/advanced_settings/internet_settings/models/_models.dart';

class InternetSettingsState extends FeatureState<InternetSettingsUIModel,
    InternetSettingsStatusUIModel> {
  const InternetSettingsState({
    required super.settings,
    required super.status,
  });

  factory InternetSettingsState.init() {
    return InternetSettingsState(
      settings: Preservable(
          original: InternetSettingsUIModel.init(),
          current: InternetSettingsUIModel.init()),
      status: InternetSettingsStatusUIModel.init(),
    );
  }

  factory InternetSettingsState.fromJson(String source) =>
      InternetSettingsState.fromMap(json.decode(source));

  factory InternetSettingsState.fromMap(Map<String, dynamic> map) {
    return InternetSettingsState(
      settings: Preservable.fromMap(
          map['settings'],
          (dynamic json) =>
              InternetSettingsUIModel.fromMap(json as Map<String, dynamic>)),
      status: InternetSettingsStatusUIModel.fromMap(
          map['status'] as Map<String, dynamic>),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'settings': settings.toMap((value) => value.toMap()),
      'status': status.toMap(),
    };
  }

  @override
  InternetSettingsState copyWith({
    Preservable<InternetSettingsUIModel>? settings,
    InternetSettingsStatusUIModel? status,
  }) {
    return InternetSettingsState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }
}
