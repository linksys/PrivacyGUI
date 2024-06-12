// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';

import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_item.dart';

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
      password: radio.guestPassword ?? '',
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
      radios: List<String>.from((map['radios'] as List<String>)),
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
  final String masterIcon;
  final bool isAnyNodesOffline;
  final ({String value, String unit})? uploadResult;
  final ({String value, String unit})? downloadResult;
  final int? uptime;
  final String? wanPortConnection;
  final List<String> lanPortConnections;
  final List<LinksysDevice> nodes;
  final List<DashboardWiFiItem> wifis;

  const DashboardHomeState({
    this.isWanConnected = false,
    this.isFirstPolling = false,
    this.isHorizontalLayout = false,
    this.masterIcon = '',
    this.isAnyNodesOffline = false,
    this.uploadResult,
    this.downloadResult,
    this.uptime,
    this.wanPortConnection,
    this.lanPortConnections = const [],
    this.nodes = const [],
    this.wifis = const [],
  });

  DashboardHomeState copyWith({
    bool? isWanConnected,
    bool? isFirstPolling,
    bool? isHorizontalLayout,
    String? masterIcon,
    bool? isAnyNodesOffline,
    ({String value, String unit})? uploadResult,
    ({String value, String unit})? downloadResult,
    int? uptime,
    String? wanPortConnection,
    List<String>? lanPortConnections,
    List<LinksysDevice>? nodes,
    List<DashboardWiFiItem>? wifis,
  }) {
    return DashboardHomeState(
      isWanConnected: isWanConnected ?? this.isWanConnected,
      isFirstPolling: isFirstPolling ?? this.isFirstPolling,
      isHorizontalLayout: isHorizontalLayout ?? this.isHorizontalLayout,
      masterIcon: masterIcon ?? this.masterIcon,
      isAnyNodesOffline: isAnyNodesOffline ?? this.isAnyNodesOffline,
      uptime: uptime ?? this.uptime,
      wanPortConnection: wanPortConnection ?? this.wanPortConnection,
      lanPortConnections: lanPortConnections ?? this.lanPortConnections,
      nodes: nodes ?? this.nodes,
      wifis: wifis ?? this.wifis,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isWanConnected': isWanConnected,
      'isFirstPolling': isFirstPolling,
      'isHorizontalLayout': isHorizontalLayout,
      'masterIcon': masterIcon,
      'isAnyNodesOffline': isAnyNodesOffline,
      'uptimes': uptime,
      'wanPortConnection': wanPortConnection,
      'lanPortConnections': lanPortConnections,
      'nodes': nodes.map((x) => x.toMap()).toList(),
      'wifis': wifis.map((x) => x.toMap()).toList(),
    };
  }

  factory DashboardHomeState.fromMap(Map<String, dynamic> map) {
    return DashboardHomeState(
      isWanConnected: map['isWanConnected'] as bool,
      isFirstPolling: map['isFirstPolling'] as bool,
      isHorizontalLayout: map['isHorizontalLayout'] as bool,
      masterIcon: map['masterIcon'] as String,
      isAnyNodesOffline: map['isAnyNodesOffline'] as bool,
      uptime: map['uptimes'] != null ? map['uptimes'] as int : null,
      wanPortConnection: map['wanPortConnection'] as String,
      lanPortConnections:
          List<String>.from((map['lanPortConnections'] as List<String>)),
      nodes: List<LinksysDevice>.from(
        map['nodes'].map<LinksysDevice>(
          (x) => LinksysDevice.fromMap(x as Map<String, dynamic>),
        ),
      ),
      wifis: List<DashboardWiFiItem>.from(
        map['wifis'].map<WiFiItem>(
          (x) => WiFiItem.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory DashboardHomeState.fromJson(String source) =>
      DashboardHomeState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props {
    return [
      isWanConnected,
      isFirstPolling,
      isHorizontalLayout,
      masterIcon,
      isAnyNodesOffline,
      uptime,
      wanPortConnection,
      lanPortConnections,
      nodes,
      wifis,
    ];
  }
}

extension DashboardHomeStateExt on DashboardHomeState {
  String get mainSSID => wifis.firstOrNull?.ssid ?? '';
}
