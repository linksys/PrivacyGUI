// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';

class DashboardSpeedItem extends Equatable {
  final String unit;
  final String value;

  const DashboardSpeedItem({
    required this.unit,
    required this.value,
  });

  DashboardSpeedItem copyWith({
    String? unit,
    String? value,
  }) {
    return DashboardSpeedItem(
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

  factory DashboardSpeedItem.fromMap(Map<String, dynamic> map) {
    return DashboardSpeedItem(
      unit: map['unit'] ?? '',
      value: map['value'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory DashboardSpeedItem.fromJson(String source) => DashboardSpeedItem.fromMap(json.decode(source));

  @override
  String toString() => 'DasboardSpeedItem(unit: $unit, value: $value)';

  @override
  List<Object> get props => [unit, value];
}

class DashboardWiFiItem extends Equatable {
  final String ssid;
  final String password;
  final List<String> radios;
  final bool isGuest;
  final bool isEnabled;
  final int numOfConnectedDevices;

  const DashboardWiFiItem({
    required this.ssid,
    required this.password,
    required this.radios,
    required this.isGuest,
    required this.isEnabled,
    required this.numOfConnectedDevices,
  });

  factory DashboardWiFiItem.fromMainRadios(
      List<RouterRadio> radios, int connectedDevices) {
    final radio = radios.first;
    return DashboardWiFiItem(
      ssid: radio.settings.ssid,
      password: radio.settings.wpaPersonalSettings?.passphrase ?? '',
      radios: radios.map((e) => e.radioID).toList(),
      isGuest: false,
      isEnabled: radio.settings.isEnabled,
      numOfConnectedDevices: connectedDevices,
    );
  }

  factory DashboardWiFiItem.fromGuestRadios(
      List<GuestRadioInfo> radios, int connectedDevices) {
    final radio = radios.first;
    return DashboardWiFiItem(
      ssid: radio.guestSSID,
      password: radio.guestWPAPassphrase ?? '',
      radios: radios.map((e) => e.radioID).toList(),
      isGuest: true,
      isEnabled: radio.isEnabled,
      numOfConnectedDevices: connectedDevices,
    );
  }

  DashboardWiFiItem copyWith({
    String? ssid,
    String? password,
    List<String>? radios,
    bool? isGuest,
    bool? isEnabled,
    int? numOfConnectedDevices,
  }) {
    return DashboardWiFiItem(
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

  factory DashboardWiFiItem.fromMap(Map<String, dynamic> map) {
    return DashboardWiFiItem(
      ssid: map['ssid'] as String,
      password: map['password'] as String,
      radios: List<String>.from(map['radios']),
      isGuest: map['isGuest'] as bool,
      isEnabled: map['isEnabled'] as bool,
      numOfConnectedDevices: map['numOfConnectedDevices'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory DashboardWiFiItem.fromJson(String source) =>
      DashboardWiFiItem.fromMap(json.decode(source) as Map<String, dynamic>);

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
  final bool isWanConnected;
  final bool isFirstPolling;
  final bool isHorizontalLayout;
  final bool isHealthCheckSupported;
  final String masterIcon;
  final bool isAnyNodesOffline;
  final DashboardSpeedItem? uploadResult;
  final DashboardSpeedItem? downloadResult;
  final int? speedCheckTimestamp;
  final int? uptime;
  final String? wanPortConnection;
  final List<String> lanPortConnections;
  final List<DashboardWiFiItem> wifis;
  final String? wanType;
  final String? detectedWANType;

  const DashboardHomeState({
    this.isWanConnected = false,
    this.isFirstPolling = false,
    this.isHorizontalLayout = false,
    this.isHealthCheckSupported = false,
    this.masterIcon = '',
    this.isAnyNodesOffline = false,
    this.uploadResult,
    this.downloadResult,
    this.speedCheckTimestamp,
    this.uptime,
    this.wanPortConnection,
    this.lanPortConnections = const [],
    this.wifis = const [],
    this.wanType,
    this.detectedWANType,
  });

  Map<String, dynamic> toMap() {
    return {
      'isWanConnected': isWanConnected,
      'isFirstPolling': isFirstPolling,
      'isHorizontalLayout': isHorizontalLayout,
      'isHealthCheckSupported': isHealthCheckSupported,
      'masterIcon': masterIcon,
      'isAnyNodesOffline': isAnyNodesOffline,
      'uploadResult': uploadResult?.toMap(),
      'downloadResult': downloadResult?.toMap(),
      'speedCheckTimestamp': speedCheckTimestamp,
      'uptime': uptime,
      'wanPortConnection': wanPortConnection,
      'lanPortConnections': lanPortConnections,
      'wifis': wifis.map((x) => x.toMap()).toList(),
      'wanType': wanType,
      'detectedWANType': detectedWANType,
    };
  }

  factory DashboardHomeState.fromMap(Map<String, dynamic> map) {
    return DashboardHomeState(
      isWanConnected: map['isWanConnected'] ?? false,
      isFirstPolling: map['isFirstPolling'] ?? false,
      isHorizontalLayout: map['isHorizontalLayout'] ?? false,
      isHealthCheckSupported: map['isHealthCheckSupported'] ?? false,
      masterIcon: map['masterIcon'] ?? '',
      isAnyNodesOffline: map['isAnyNodesOffline'] ?? false,
      uploadResult: map['uploadResult'] != null ? DashboardSpeedItem.fromMap(map['uploadResult']) : null,
      downloadResult: map['downloadResult'] != null ? DashboardSpeedItem.fromMap(map['downloadResult']) : null,
      speedCheckTimestamp: map['speedCheckTimestamp']?.toInt(),
      uptime: map['uptime']?.toInt(),
      wanPortConnection: map['wanPortConnection'],
      lanPortConnections: List<String>.from(map['lanPortConnections']),
      wifis: List<DashboardWiFiItem>.from(map['wifis']?.map((x) => DashboardWiFiItem.fromMap(x))),
      wanType: map['wanType'],
      detectedWANType: map['detectedWANType'],
    );
  }

  String toJson() => json.encode(toMap());

  factory DashboardHomeState.fromJson(String source) => DashboardHomeState.fromMap(json.decode(source));

  @override
  bool get stringify => true;

  @override
  List<Object?> get props {
    return [
      isWanConnected,
      isFirstPolling,
      isHorizontalLayout,
      isHealthCheckSupported,
      masterIcon,
      isAnyNodesOffline,
      uploadResult,
      downloadResult,
      speedCheckTimestamp,
      uptime,
      wanPortConnection,
      lanPortConnections,
      wifis,
      wanType,
      detectedWANType,
    ];
  }

  DashboardHomeState copyWith({
    bool? isWanConnected,
    bool? isFirstPolling,
    bool? isHorizontalLayout,
    bool? isHealthCheckSupported,
    String? masterIcon,
    bool? isAnyNodesOffline,
    ValueGetter<DashboardSpeedItem?>? uploadResult,
    ValueGetter<DashboardSpeedItem?>? downloadResult,
    ValueGetter<int?>? speedCheckTimestamp,
    ValueGetter<int?>? uptime,
    ValueGetter<String?>? wanPortConnection,
    List<String>? lanPortConnections,
    List<DashboardWiFiItem>? wifis,
    ValueGetter<String?>? wanType,
    ValueGetter<String?>? detectedWANType,
  }) {
    return DashboardHomeState(
      isWanConnected: isWanConnected ?? this.isWanConnected,
      isFirstPolling: isFirstPolling ?? this.isFirstPolling,
      isHorizontalLayout: isHorizontalLayout ?? this.isHorizontalLayout,
      isHealthCheckSupported: isHealthCheckSupported ?? this.isHealthCheckSupported,
      masterIcon: masterIcon ?? this.masterIcon,
      isAnyNodesOffline: isAnyNodesOffline ?? this.isAnyNodesOffline,
      uploadResult: uploadResult != null ? uploadResult() : this.uploadResult,
      downloadResult: downloadResult != null ? downloadResult() : this.downloadResult,
      speedCheckTimestamp: speedCheckTimestamp != null ? speedCheckTimestamp() : this.speedCheckTimestamp,
      uptime: uptime != null ? uptime() : this.uptime,
      wanPortConnection: wanPortConnection != null ? wanPortConnection() : this.wanPortConnection,
      lanPortConnections: lanPortConnections ?? this.lanPortConnections,
      wifis: wifis ?? this.wifis,
      wanType: wanType != null ? wanType() : this.wanType,
      detectedWANType: detectedWANType != null ? detectedWANType() : this.detectedWANType,
    );
  }

  @override
  String toString() {
    return 'DashboardHomeState(isWanConnected: $isWanConnected, isFirstPolling: $isFirstPolling, isHorizontalLayout: $isHorizontalLayout, isHealthCheckSupported: $isHealthCheckSupported, masterIcon: $masterIcon, isAnyNodesOffline: $isAnyNodesOffline, uploadResult: $uploadResult, downloadResult: $downloadResult, speedCheckTimestamp: $speedCheckTimestamp, uptime: $uptime, wanPortConnection: $wanPortConnection, lanPortConnections: $lanPortConnections, wifis: $wifis, wanType: $wanType, detectedWANType: $detectedWANType)';
  }
}

extension DashboardHomeStateExt on DashboardHomeState {
  String get mainSSID => wifis.firstOrNull?.ssid ?? '';

  bool get isBridgeMode => wanType == 'Bridge' || detectedWANType == 'Bridge';
}
