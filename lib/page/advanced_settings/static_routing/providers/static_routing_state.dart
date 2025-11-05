import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';
import 'package:privacy_gui/providers/feature_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

class NamedStaticRouteEntryList extends Equatable {
  final List<NamedStaticRouteEntry> entries;

  const NamedStaticRouteEntryList({required this.entries});

  @override
  List<Object> get props => [entries];

  NamedStaticRouteEntryList copyWith({
    List<NamedStaticRouteEntry>? entries,
  }) {
    return NamedStaticRouteEntryList(
      entries: entries ?? this.entries,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'entries': entries.map((x) => x.toMap()).toList(),
    };
  }

  factory NamedStaticRouteEntryList.fromMap(Map<String, dynamic> map) {
    return NamedStaticRouteEntryList(
      entries: List<NamedStaticRouteEntry>.from(
        map['entries']?.map<NamedStaticRouteEntry>(
          (x) => NamedStaticRouteEntry.fromMap(x as Map<String, dynamic>),
        ) ?? [],
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory NamedStaticRouteEntryList.fromJson(String source) =>
      NamedStaticRouteEntryList.fromMap(json.decode(source) as Map<String, dynamic>);
}

class StaticRoutingSettings extends Equatable {
  final bool isNATEnabled;
  final bool isDynamicRoutingEnabled;
  final NamedStaticRouteEntryList entries;

  const StaticRoutingSettings({
    required this.isNATEnabled,
    required this.isDynamicRoutingEnabled,
    required this.entries,
  });

  @override
  List<Object?> get props => [isNATEnabled, isDynamicRoutingEnabled, entries];

  StaticRoutingSettings copyWith({
    bool? isNATEnabled,
    bool? isDynamicRoutingEnabled,
    NamedStaticRouteEntryList? entries,
  }) {
    return StaticRoutingSettings(
      isNATEnabled: isNATEnabled ?? this.isNATEnabled,
      isDynamicRoutingEnabled:
          isDynamicRoutingEnabled ?? this.isDynamicRoutingEnabled,
      entries: entries ?? this.entries,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isNATEnabled': isNATEnabled,
      'isDynamicRoutingEnabled': isDynamicRoutingEnabled,
      'entries': entries.toMap(),
    };
  }

  factory StaticRoutingSettings.fromMap(Map<String, dynamic> map) {
    return StaticRoutingSettings(
      isNATEnabled: map['isNATEnabled'] as bool,
      isDynamicRoutingEnabled: map['isDynamicRoutingEnabled'] as bool,
      entries: NamedStaticRouteEntryList.fromMap(map['entries'] as Map<String, dynamic>),
    );
  }
}

class StaticRoutingStatus extends Equatable {
  final int maxStaticRouteEntries;
  final String routerIp;
  final String subnetMask;

  const StaticRoutingStatus({
    required this.maxStaticRouteEntries,
    required this.routerIp,
    required this.subnetMask,
  });

  @override
  List<Object> get props => [maxStaticRouteEntries, routerIp, subnetMask];

  StaticRoutingStatus copyWith({
    int? maxStaticRouteEntries,
    String? routerIp,
    String? subnetMask,
  }) {
    return StaticRoutingStatus(
      maxStaticRouteEntries: maxStaticRouteEntries ?? this.maxStaticRouteEntries,
      routerIp: routerIp ?? this.routerIp,
      subnetMask: subnetMask ?? this.subnetMask,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'maxStaticRouteEntries': maxStaticRouteEntries,
      'routerIp': routerIp,
      'subnetMask': subnetMask,
    };
  }

  factory StaticRoutingStatus.fromMap(Map<String, dynamic> map) {
    return StaticRoutingStatus(
      maxStaticRouteEntries: map['maxStaticRouteEntries'] as int,
      routerIp: map['routerIp'] ?? '',
      subnetMask: map['subnetMask'] ?? '',
    );
  }
}

class StaticRoutingState extends FeatureState<
    StaticRoutingSettings,
    StaticRoutingStatus> {
  const StaticRoutingState({
    required super.settings,
    required super.status,
  });

  factory StaticRoutingState.empty() => StaticRoutingState(
        settings: Preservable(original: const StaticRoutingSettings(
          isNATEnabled: false,
          isDynamicRoutingEnabled: false,
          entries: NamedStaticRouteEntryList(entries: []), 
        ), current: const StaticRoutingSettings(
          isNATEnabled: false,
          isDynamicRoutingEnabled: false,
          entries: NamedStaticRouteEntryList(entries: []), 
        )),
        status: const StaticRoutingStatus(
          maxStaticRouteEntries: 0,
          routerIp: '192.168.1.1',
          subnetMask: '255.255.255.0',
        ),
      );

  @override
  StaticRoutingState copyWith({
    Preservable<StaticRoutingSettings>? settings,
    StaticRoutingStatus? status,
  }) {
    return StaticRoutingState(
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

  factory StaticRoutingState.fromMap(Map<String, dynamic> map) {
    return StaticRoutingState(
      settings: Preservable.fromMap(
        map['settings'] as Map<String, dynamic>,
        (valueMap) => StaticRoutingSettings.fromMap(valueMap as Map<String, dynamic>),
      ),
      status: StaticRoutingStatus.fromMap(map['status'] as Map<String, dynamic>),
    );
  }

  factory StaticRoutingState.fromJson(String source) =>
      StaticRoutingState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [settings, status];
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
