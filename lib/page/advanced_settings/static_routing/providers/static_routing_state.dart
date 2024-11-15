import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';

class StaticRoutingState extends Equatable {
  final GetRoutingSettings setting;
  final String routerIp;
  final String subnetMask;

  const StaticRoutingState({
    required this.setting,
    this.routerIp = '192.168.1.1',
    this.subnetMask = '255.255.255.0',
  });

  factory StaticRoutingState.empty() => const StaticRoutingState(
        setting: GetRoutingSettings(
          isNATEnabled: false,
          isDynamicRoutingEnabled: false,
          maxStaticRouteEntries: 0,
          entries: [],
        ),
      );

  StaticRoutingState copyWith({
    GetRoutingSettings? setting,
    String? routerIp,
    String? subnetMask,
  }) {
    return StaticRoutingState(
      setting: setting ?? this.setting,
      routerIp: routerIp ?? this.routerIp,
      subnetMask: subnetMask ?? this.subnetMask,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'setting': setting.toMap(),
      'routerIp': routerIp,
      'subnetMask': subnetMask,
    };
  }

  factory StaticRoutingState.fromMap(Map<String, dynamic> map) {
    return StaticRoutingState(
      setting: GetRoutingSettings.fromMap(map['setting']),
      routerIp: map['routerIp'] ?? '',
      subnetMask: map['subnetMask'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory StaticRoutingState.fromJson(String source) =>
      StaticRoutingState.fromMap(json.decode(source));

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [setting, routerIp, subnetMask];

  @override
  String toString() =>
      'StaticRoutingState(setting: $setting, routerIp: $routerIp, subnetMask: $subnetMask)';
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
