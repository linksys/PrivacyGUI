// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';

import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/health_check_result.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';

class DashboardManagerState extends Equatable {
  final NodeDeviceInfo? deviceInfo;
  final List<RouterRadio> mainRadios;
  final List<GuestRadioInfo> guestRadios;
  final bool isGuestNetworkEnabled;
  final HealthCheckResult? latestSpeedTest;
  final List<String> healthCheckModules;
  final int uptimes;
  final String? wanConnection;
  final List<String> lanConnections;
  final String? skuModelNumber;
  final int localTime;
  final String? cpuLoad;
  final String? memoryLoad;

  const DashboardManagerState({
    this.deviceInfo,
    this.mainRadios = const [],
    this.guestRadios = const [],
    this.isGuestNetworkEnabled = false,
    this.latestSpeedTest,
    this.healthCheckModules = const [],
    this.uptimes = 0,
    this.wanConnection,
    this.lanConnections = const [],
    this.skuModelNumber,
    this.localTime = 0,
    this.cpuLoad,
    this.memoryLoad,
  });

  @override
  List<Object?> get props {
    return [
      deviceInfo,
      mainRadios,
      guestRadios,
      isGuestNetworkEnabled,
      latestSpeedTest,
      healthCheckModules,
      uptimes,
      wanConnection,
      lanConnections,
      skuModelNumber,
      localTime,
      cpuLoad,
      memoryLoad,
    ];
  }

  DashboardManagerState copyWith({
    NodeDeviceInfo? deviceInfo,
    List<RouterRadio>? mainRadios,
    List<GuestRadioInfo>? guestRadios,
    bool? isGuestNetworkEnabled,
    HealthCheckResult? latestSpeedTest,
    List<String>? healthCheckModules,
    int? uptimes,
    String? wanConnection,
    List<String>? lanConnections,
    String? skuModelNumber,
    int? localTime,
    String? cpuLoad,
    String? memoryLoad,
  }) {
    return DashboardManagerState(
      deviceInfo: deviceInfo ?? this.deviceInfo,
      mainRadios: mainRadios ?? this.mainRadios,
      guestRadios: guestRadios ?? this.guestRadios,
      isGuestNetworkEnabled:
          isGuestNetworkEnabled ?? this.isGuestNetworkEnabled,
      latestSpeedTest: latestSpeedTest ?? this.latestSpeedTest,
      healthCheckModules: healthCheckModules ?? this.healthCheckModules,
      uptimes: uptimes ?? this.uptimes,
      wanConnection: wanConnection ?? this.wanConnection,
      lanConnections: lanConnections ?? this.lanConnections,
      skuModelNumber: skuModelNumber ?? this.skuModelNumber,
      localTime: localTime ?? this.localTime,
      cpuLoad: cpuLoad ?? this.cpuLoad,
      memoryLoad: memoryLoad ?? this.memoryLoad,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'deviceInfo': deviceInfo?.toJson(),
      'mainRadios': mainRadios.map((x) => x.toMap()).toList(),
      'guestRadios': guestRadios.map((x) => x.toMap()).toList(),
      'isGuestNetworkEnabled': isGuestNetworkEnabled,
      'latestSpeedTest': latestSpeedTest?.toJson(),
      'healthCheckModules': healthCheckModules,
      'uptimes': uptimes,
      'wanConnection': wanConnection,
      'lanConnections': lanConnections,
      'skuModelNumber': skuModelNumber,
      'localTime': localTime,
      'cpuLoad': cpuLoad,
      'memoryLoad': memoryLoad,
    }..removeWhere((key, value) => value == null);
  }

  factory DashboardManagerState.fromMap(Map<String, dynamic> map) {
    return DashboardManagerState(
      deviceInfo: map['deviceInfo'] != null
          ? NodeDeviceInfo.fromJson(map['deviceInfo'])
          : null,
      mainRadios: map['mainRadios'] != null
          ? List<RouterRadio>.from(
              map['mainRadios'].map<RouterRadio>(
                (x) => RouterRadio.fromMap(x),
              ),
            )
          : [],
      guestRadios: map['guestRadios'] != null
          ? List<GuestRadioInfo>.from(
              map['guestRadios'].map<GuestRadioInfo>(
                (x) => GuestRadioInfo.fromMap(x),
              ),
            )
          : [],
      isGuestNetworkEnabled: map['isGuestNetworkEnabled'] as bool,
      latestSpeedTest: map['latestSpeedTest'] != null
          ? HealthCheckResult.fromJson(map['latestSpeedTest'])
          : null,
      healthCheckModules: List<String>.from(map['healthCheckModules']),
      uptimes: map['uptimes'] as int,
      wanConnection: map['wanConnection'],
      lanConnections: List<String>.from(
        map['lanConnections'],
      ),
      skuModelNumber: map['skuModelNumber'],
      localTime: map['localTime'],
      cpuLoad: map['cpuLoad'],
      memoryLoad: map['memoryLoad'],
    );
  }

  String toJson() => json.encode(toMap());

  factory DashboardManagerState.fromJson(String source) =>
      DashboardManagerState.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
