import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';

class StaticRoutingState extends Equatable {
  final GetRoutingSettings setting;
  const StaticRoutingState({
    required this.setting,
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
  }) {
    return StaticRoutingState(
      setting: setting ?? this.setting,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'setting': setting.toMap(),
    };
  }

  factory StaticRoutingState.fromMap(Map<String, dynamic> map) {
    return StaticRoutingState(
      setting: GetRoutingSettings.fromMap(
        map['setting'] as Map<String, dynamic>,
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory StaticRoutingState.fromJson(String source) =>
      StaticRoutingState.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [setting];
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
