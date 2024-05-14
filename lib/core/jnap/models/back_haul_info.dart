// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class WirelessConnectionInfo extends Equatable {
  final String radioID;
  final int channel;
  final int apRSSI;
  final int stationRSSI;
  final String apBSSID;
  final String stationBSSID;
  const WirelessConnectionInfo({
    required this.radioID,
    required this.channel,
    required this.apRSSI,
    required this.stationRSSI,
    required this.apBSSID,
    required this.stationBSSID,
  });

  @override
  List<Object> get props {
    return [
      radioID,
      channel,
      apRSSI,
      stationRSSI,
      apBSSID,
      stationBSSID,
    ];
  }

  WirelessConnectionInfo copyWith({
    String? radioID,
    int? channel,
    int? apRSSI,
    int? stationRSSI,
    String? apBSSID,
    String? stationBSSID,
  }) {
    return WirelessConnectionInfo(
      radioID: radioID ?? this.radioID,
      channel: channel ?? this.channel,
      apRSSI: apRSSI ?? this.apRSSI,
      stationRSSI: stationRSSI ?? this.stationRSSI,
      apBSSID: apBSSID ?? this.apBSSID,
      stationBSSID: stationBSSID ?? this.stationBSSID,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'radioID': radioID,
      'channel': channel,
      'apRSSI': apRSSI,
      'stationRSSI': stationRSSI,
      'apBSSID': apBSSID,
      'stationBSSID': stationBSSID,
    };
  }

  factory WirelessConnectionInfo.fromMap(Map<String, dynamic> map) {
    return WirelessConnectionInfo(
      radioID: map['radioID'] as String,
      channel: map['channel'] as int,
      apRSSI: map['apRSSI'] as int,
      stationRSSI: map['stationRSSI'] as int,
      apBSSID: map['apBSSID'] as String,
      stationBSSID: map['stationBSSID'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory WirelessConnectionInfo.fromJson(String source) =>
      WirelessConnectionInfo.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}

class BackHaulInfoData extends Equatable {
  final String deviceUUID;
  final String ipAddress;
  final String parentIPAddress;
  final String connectionType;
  final WirelessConnectionInfo? wirelessConnectionInfo;
  final String speedMbps;
  final String timestamp;
  const BackHaulInfoData({
    required this.deviceUUID,
    required this.ipAddress,
    required this.parentIPAddress,
    required this.connectionType,
    required this.wirelessConnectionInfo,
    required this.speedMbps,
    required this.timestamp,
  });

  @override
  List<Object?> get props {
    return [
      deviceUUID,
      ipAddress,
      parentIPAddress,
      connectionType,
      wirelessConnectionInfo,
      speedMbps,
      timestamp,
    ];
  }

  BackHaulInfoData copyWith({
    String? deviceUUID,
    String? ipAddress,
    String? parentIPAddress,
    String? connectionType,
    WirelessConnectionInfo? wirelessConnectionInfo,
    String? speedMbps,
    String? timestamp,
  }) {
    return BackHaulInfoData(
      deviceUUID: deviceUUID ?? this.deviceUUID,
      ipAddress: ipAddress ?? this.ipAddress,
      parentIPAddress: parentIPAddress ?? this.parentIPAddress,
      connectionType: connectionType ?? this.connectionType,
      wirelessConnectionInfo:
          wirelessConnectionInfo ?? this.wirelessConnectionInfo,
      speedMbps: speedMbps ?? this.speedMbps,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'deviceUUID': deviceUUID,
      'ipAddress': ipAddress,
      'parentIPAddress': parentIPAddress,
      'connectionType': connectionType,
      'wirelessConnectionInfo': wirelessConnectionInfo?.toMap(),
      'speedMbps': speedMbps,
      'timestamp': timestamp,
    };
  }

  factory BackHaulInfoData.fromMap(Map<String, dynamic> map) {
    return BackHaulInfoData(
      deviceUUID: map['deviceUUID'] as String,
      ipAddress: map['ipAddress'] as String,
      parentIPAddress: map['parentIPAddress'] as String,
      connectionType: map['connectionType'] as String,
      wirelessConnectionInfo: map['wirelessConnectionInfo'] == null
          ? null
          : WirelessConnectionInfo.fromMap(
              map['wirelessConnectionInfo'] as Map<String, dynamic>),
      speedMbps: map['speedMbps'] as String,
      timestamp: map['timestamp'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory BackHaulInfoData.fromJson(String source) =>
      BackHaulInfoData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
