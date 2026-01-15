// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

class DashboardSpeedUIModel extends Equatable {
  final String unit;
  final String value;

  const DashboardSpeedUIModel({
    required this.unit,
    required this.value,
  });

  DashboardSpeedUIModel copyWith({
    String? unit,
    String? value,
  }) {
    return DashboardSpeedUIModel(
      unit: unit ?? this.unit,
      value: value ?? this.value,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'unit': unit,
      'value': value,
    };
  }

  factory DashboardSpeedUIModel.fromMap(Map<String, dynamic> map) {
    return DashboardSpeedUIModel(
      unit: map['unit'] ?? '',
      value: map['value'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory DashboardSpeedUIModel.fromJson(String source) =>
      DashboardSpeedUIModel.fromMap(json.decode(source));

  @override
  String toString() => 'DashboardSpeedUIModel(unit: $unit, value: $value)';

  @override
  List<Object> get props => [unit, value];
}

class DashboardWiFiUIModel extends Equatable {
  final String ssid;
  final String password;
  final List<String> radios;
  final bool isGuest;
  final bool isEnabled;
  final int numOfConnectedDevices;

  const DashboardWiFiUIModel({
    required this.ssid,
    required this.password,
    required this.radios,
    required this.isGuest,
    required this.isEnabled,
    required this.numOfConnectedDevices,
  });

  DashboardWiFiUIModel copyWith({
    String? ssid,
    String? password,
    List<String>? radios,
    bool? isGuest,
    bool? isEnabled,
    int? numOfConnectedDevices,
  }) {
    return DashboardWiFiUIModel(
      ssid: ssid ?? this.ssid,
      password: password ?? this.password,
      radios: radios ?? this.radios,
      isGuest: isGuest ?? this.isGuest,
      isEnabled: isEnabled ?? this.isEnabled,
      numOfConnectedDevices:
          numOfConnectedDevices ?? this.numOfConnectedDevices,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ssid': ssid,
      'password': password,
      'radios': radios,
      'isGuest': isGuest,
      'isEnabled': isEnabled,
      'numOfConnectedDevices': numOfConnectedDevices,
    };
  }

  factory DashboardWiFiUIModel.fromMap(Map<String, dynamic> map) {
    return DashboardWiFiUIModel(
      ssid: map['ssid'] as String,
      password: map['password'] as String,
      radios: List<String>.from(map['radios']),
      isGuest: map['isGuest'] as bool,
      isEnabled: map['isEnabled'] as bool,
      numOfConnectedDevices: map['numOfConnectedDevices'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory DashboardWiFiUIModel.fromJson(String source) =>
      DashboardWiFiUIModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props {
    return [
      ssid,
      password,
      radios,
      isGuest,
      isEnabled,
      numOfConnectedDevices,
    ];
  }
}

class DashboardHomeState extends Equatable {
  final bool isFirstPolling;
  final bool isHorizontalLayout;
  final String masterIcon;
  final bool isAnyNodesOffline;
  final int? uptime;
  final String? wanPortConnection;
  final List<String> lanPortConnections;
  final List<DashboardWiFiUIModel> wifis;
  final String? wanType;
  final String? detectedWANType;
  final String? cpuLoad;
  final String? memoryLoad;

  const DashboardHomeState({
    this.isFirstPolling = false,
    this.isHorizontalLayout = false,
    this.masterIcon = '',
    this.isAnyNodesOffline = false,
    this.uptime,
    this.wanPortConnection,
    this.lanPortConnections = const [],
    this.wifis = const [],
    this.wanType,
    this.detectedWANType,
    this.cpuLoad,
    this.memoryLoad,
  });

  Map<String, dynamic> toMap() {
    return {
      'isFirstPolling': isFirstPolling,
      'isHorizontalLayout': isHorizontalLayout,
      'masterIcon': masterIcon,
      'isAnyNodesOffline': isAnyNodesOffline,
      'uptime': uptime,
      'wanPortConnection': wanPortConnection,
      'lanPortConnections': lanPortConnections,
      'wifis': wifis.map((x) => x.toMap()).toList(),
      'wanType': wanType,
      'detectedWANType': detectedWANType,
      'cpuLoad': cpuLoad,
      'memoryLoad': memoryLoad,
    };
  }

  factory DashboardHomeState.fromMap(Map<String, dynamic> map) {
    return DashboardHomeState(
      isFirstPolling: map['isFirstPolling'] ?? false,
      isHorizontalLayout: map['isHorizontalLayout'] ?? false,
      masterIcon: map['masterIcon'] ?? '',
      isAnyNodesOffline: map['isAnyNodesOffline'] ?? false,
      uptime: map['uptime']?.toInt(),
      wanPortConnection: map['wanPortConnection'],
      lanPortConnections: List<String>.from(map['lanPortConnections']),
      wifis: List<DashboardWiFiUIModel>.from(
          map['wifis']?.map((x) => DashboardWiFiUIModel.fromMap(x))),
      wanType: map['wanType'],
      detectedWANType: map['detectedWANType'],
      cpuLoad: map['cpuLoad'],
      memoryLoad: map['memoryLoad'],
    );
  }

  String toJson() => json.encode(toMap());

  factory DashboardHomeState.fromJson(String source) =>
      DashboardHomeState.fromMap(json.decode(source));

  @override
  bool get stringify => true;

  @override
  List<Object?> get props {
    return [
      isFirstPolling,
      isHorizontalLayout,
      masterIcon,
      isAnyNodesOffline,
      uptime,
      wanPortConnection,
      lanPortConnections,
      wifis,
      wanType,
      detectedWANType,
      cpuLoad,
      memoryLoad,
    ];
  }

  DashboardHomeState copyWith({
    bool? isFirstPolling,
    bool? isHorizontalLayout,
    String? masterIcon,
    bool? isAnyNodesOffline,
    ValueGetter<int?>? uptime,
    ValueGetter<String?>? wanPortConnection,
    List<String>? lanPortConnections,
    List<DashboardWiFiUIModel>? wifis,
    ValueGetter<String?>? wanType,
    ValueGetter<String?>? detectedWANType,
    ValueGetter<String?>? cpuLoad,
    ValueGetter<String?>? memoryLoad,
  }) {
    return DashboardHomeState(
      isFirstPolling: isFirstPolling ?? this.isFirstPolling,
      isHorizontalLayout: isHorizontalLayout ?? this.isHorizontalLayout,
      masterIcon: masterIcon ?? this.masterIcon,
      isAnyNodesOffline: isAnyNodesOffline ?? this.isAnyNodesOffline,
      uptime: uptime != null ? uptime() : this.uptime,
      wanPortConnection: wanPortConnection != null
          ? wanPortConnection()
          : this.wanPortConnection,
      lanPortConnections: lanPortConnections ?? this.lanPortConnections,
      wifis: wifis ?? this.wifis,
      wanType: wanType != null ? wanType() : this.wanType,
      detectedWANType:
          detectedWANType != null ? detectedWANType() : this.detectedWANType,
      cpuLoad: cpuLoad != null ? cpuLoad() : this.cpuLoad,
      memoryLoad: memoryLoad != null ? memoryLoad() : this.memoryLoad,
    );
  }

  @override
  String toString() {
    return 'DashboardHomeState(isFirstPolling: $isFirstPolling, isHorizontalLayout: $isHorizontalLayout, masterIcon: $masterIcon, isAnyNodesOffline: $isAnyNodesOffline, uptime: $uptime, wanPortConnection: $wanPortConnection, lanPortConnections: $lanPortConnections, wifis: $wifis, wanType: $wanType, detectedWANType: $detectedWANType, cpuLoad: $cpuLoad, memoryLoad: $memoryLoad)';
  }
}

extension DashboardHomeStateExt on DashboardHomeState {
  String get mainSSID => wifis.firstOrNull?.ssid ?? '';

  bool get isBridgeMode => wanType == 'Bridge' || detectedWANType == 'Bridge';
}
