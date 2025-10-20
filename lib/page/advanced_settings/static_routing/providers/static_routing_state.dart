import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';
import 'package:privacy_gui/providers/feature_state.dart';

class StaticRoutingSettings extends Equatable {
  final GetRoutingSettings setting;

  const StaticRoutingSettings({
    required this.setting,
  });

  @override
  List<Object> get props => [setting];

  Map<String, dynamic> toMap() {
    return {
      'setting': setting.toMap(),
    };
  }

  StaticRoutingSettings copyWith({
    GetRoutingSettings? setting,
  }) {
    return StaticRoutingSettings(
      setting: setting ?? this.setting,
    );
  }
}

class StaticRoutingStatus extends Equatable {
  final String routerIp;
  final String subnetMask;

  const StaticRoutingStatus({
    this.routerIp = '192.168.1.1',
    this.subnetMask = '255.255.255.0',
  });

  @override
  List<Object> get props => [routerIp, subnetMask];

  Map<String, dynamic> toMap() {
    return {
      'routerIp': routerIp,
      'subnetMask': subnetMask,
    };
  }
}

class StaticRoutingState
    extends FeatureState<StaticRoutingSettings, StaticRoutingStatus> {
  const StaticRoutingState({
    required super.settings,
    required super.status,
  });

  factory StaticRoutingState.empty() => const StaticRoutingState(
        settings: StaticRoutingSettings(
          setting: GetRoutingSettings(
            isNATEnabled: false,
            isDynamicRoutingEnabled: false,
            maxStaticRouteEntries: 0,
            entries: [],
          ),
        ),
        status: StaticRoutingStatus(),
      );

  @override
  StaticRoutingState copyWith({
    StaticRoutingSettings? settings,
    StaticRoutingStatus? status,
  }) {
    return StaticRoutingState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'settings': settings.toMap(),
      'status': status.toMap(),
    };
  }
}

enum RoutingSettingNetwork {
  nat,
  dynamicRouting;
}

enum RoutingSettingInterface {
  lan(value: 'LAN'),
  internet(value: 'Internet');

  const RoutingSettingInterface({
    required this.value,
  });

  final String value;

  static RoutingSettingInterface resolve(String? value) {
    return switch (value) {
      'LAN' => RoutingSettingInterface.lan,
      'Internet' => RoutingSettingInterface.internet,
      _ => RoutingSettingInterface.lan,
    };
  }
}
