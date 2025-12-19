// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/models/_models.dart';
import 'package:privacy_gui/providers/feature_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

/// DDNS feature state
///
/// Uses UI models only, no JNAP model dependencies per constitution Article V Section 5.3
class DDNSState extends FeatureState<DDNSSettingsUIModel, DDNSStatusUIModel> {
  const DDNSState({
    required super.settings,
    required super.status,
  });

  @override
  DDNSState copyWith({
    Preservable<DDNSSettingsUIModel>? settings,
    DDNSStatusUIModel? status,
  }) {
    return DDNSState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'settings': settings.toMap((s) => s.toMap()),
      'status': status.toMap(),
    };
  }

  factory DDNSState.fromMap(Map<String, dynamic> map) {
    return DDNSState(
      settings: Preservable.fromMap(
        map['settings'] as Map<String, dynamic>,
        (valueMap) =>
            DDNSSettingsUIModel.fromMap(valueMap as Map<String, dynamic>),
      ),
      status: DDNSStatusUIModel.fromMap(map['status'] as Map<String, dynamic>),
    );
  }

  factory DDNSState.fromJson(String source) =>
      DDNSState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [settings, status];
}
