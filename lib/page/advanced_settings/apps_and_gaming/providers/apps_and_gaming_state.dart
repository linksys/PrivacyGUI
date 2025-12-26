import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/models/_models.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/port_range_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/port_range_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/single_port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/providers/empty_status.dart';
import 'package:privacy_gui/providers/feature_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

class AppsAndGamingSettings extends Equatable {
  final DDNSSettingsUIModel ddnsSettings;
  final SinglePortForwardingRuleListUIModel singlePortForwardingList;
  final PortRangeForwardingRuleListUIModel portRangeForwardingList;
  final PortRangeTriggeringRuleListUIModel portRangeTriggeringList;

  const AppsAndGamingSettings({
    required this.ddnsSettings,
    required this.singlePortForwardingList,
    required this.portRangeForwardingList,
    required this.portRangeTriggeringList,
  });

  @override
  List<Object?> get props => [
        ddnsSettings,
        singlePortForwardingList,
        portRangeForwardingList,
        portRangeTriggeringList,
      ];

  AppsAndGamingSettings copyWith({
    DDNSSettingsUIModel? ddnsSettings,
    SinglePortForwardingRuleListUIModel? singlePortForwardingList,
    PortRangeForwardingRuleListUIModel? portRangeForwardingList,
    PortRangeTriggeringRuleListUIModel? portRangeTriggeringList,
  }) {
    return AppsAndGamingSettings(
      ddnsSettings: ddnsSettings ?? this.ddnsSettings,
      singlePortForwardingList:
          singlePortForwardingList ?? this.singlePortForwardingList,
      portRangeForwardingList:
          portRangeForwardingList ?? this.portRangeForwardingList,
      portRangeTriggeringList:
          portRangeTriggeringList ?? this.portRangeTriggeringList,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ddnsSettings': ddnsSettings.toMap(),
      'singlePortForwardingList': singlePortForwardingList.toMap(),
      'portRangeForwardingList': portRangeForwardingList.toMap(),
      'portRangeTriggeringList': portRangeTriggeringList.toMap(),
    };
  }

  factory AppsAndGamingSettings.fromMap(Map<String, dynamic> map) {
    return AppsAndGamingSettings(
      ddnsSettings: DDNSSettingsUIModel.fromMap(
          map['ddnsSettings'] as Map<String, dynamic>),
      singlePortForwardingList: SinglePortForwardingRuleListUIModel.fromMap(
          map['singlePortForwardingList'] as Map<String, dynamic>),
      portRangeForwardingList: PortRangeForwardingRuleListUIModel.fromMap(
          map['portRangeForwardingList'] as Map<String, dynamic>),
      portRangeTriggeringList: PortRangeTriggeringRuleListUIModel.fromMap(
          map['portRangeTriggeringList'] as Map<String, dynamic>),
    );
  }
}

class AppsAndGamingViewState
    extends FeatureState<AppsAndGamingSettings, EmptyStatus> {
  const AppsAndGamingViewState({
    required super.settings,
    required super.status,
  });

  @override
  AppsAndGamingViewState copyWith({
    Preservable<AppsAndGamingSettings>? settings,
    EmptyStatus? status,
  }) {
    return AppsAndGamingViewState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'settings': settings.toMap((s) => s.toMap()),
      'status': {},
    };
  }

  factory AppsAndGamingViewState.fromMap(Map<String, dynamic> map) {
    return AppsAndGamingViewState(
      settings: Preservable.fromMap(
        map['settings'] as Map<String, dynamic>,
        (valueMap) =>
            AppsAndGamingSettings.fromMap(valueMap as Map<String, dynamic>),
      ),
      status: EmptyStatus(),
    );
  }

  factory AppsAndGamingViewState.fromJson(String source) =>
      AppsAndGamingViewState.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [settings, status];
}
